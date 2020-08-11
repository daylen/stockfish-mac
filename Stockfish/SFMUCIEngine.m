//
//  SFMUCIEngine.m
//  Stockfish
//
//  Created by Daylen Yang on 1/15/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMUCIEngine.h"
#import "Constants.h"
#import "NSString+StringUtils.h"
#import "SFMPosition.h"
#import "SFMChessGame.h"
#import "SFMUCILine.h"
#import "NSArray+ArrayUtils.h"
#import "SFMUCIOption.h"
#import "SFMUserDefaults.h"
#include <stdatomic.h>

typedef NS_ENUM(NSInteger, SFMCPURating) {
    SFMCPURating64Bit,
    SFMCPURatingSSE42,
    SFMCPURatingBMI2
};

@interface SFMUCIEngine()

@property NSTask *engineTask;
@property NSFileHandle *readHandle;
@property NSFileHandle *writeHandle;

@property (nonatomic) NSURL *bookmarkUrl;

@property (readwrite, nonatomic) NSDictionary /* <NSNumber, SFMUCILine> */ *lines;
@property (nonatomic) NSMutableArray /* of SFMUCIOption */ *options;

@property dispatch_group_t analysisGroup;

@end

@implementation SFMUCIEngine

static _Atomic(int) instancesAnalyzing = 0;

#pragma mark - Setters

- (void)setIsAnalyzing:(BOOL)isAnalyzing {
    if (_isAnalyzing != isAnalyzing) {
        _isAnalyzing = isAnalyzing;
        self.lines = nil;
        
        if (isAnalyzing) {
            NSAssert(self.gameToAnalyze != nil, @"Trying to analyze but no game set");
            [self setUciOption:@"MultiPV" integerValue:self.multipv];
            [self sendCommandToEngine:[self.gameToAnalyze uciString]];
            dispatch_group_enter(_analysisGroup);
            atomic_fetch_add(&instancesAnalyzing, 1);
            [self.bookmarkUrl startAccessingSecurityScopedResource];
            [self sendCommandToEngine:@"go infinite"];
        } else {
            [self sendCommandToEngine:@"stop"];
            [self.bookmarkUrl stopAccessingSecurityScopedResource];
        }
    }
}

- (void)setGameToAnalyze:(SFMChessGame *)gameToAnalyze {
    if (self.isAnalyzing) {
        self.isAnalyzing = NO;
        dispatch_group_notify(_analysisGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self->_gameToAnalyze = gameToAnalyze;
            self.isAnalyzing = YES;
        });

    } else {
        _gameToAnalyze = gameToAnalyze;
    }
}

- (void)setMultipv:(NSUInteger)multipv {
    if (multipv < 1) {
        return;
    }
    if (self.isAnalyzing) {
        self.isAnalyzing = NO;
        dispatch_group_notify(_analysisGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self->_multipv = multipv;
            self.isAnalyzing = YES;
        });
    } else {
        _multipv = multipv;
    }
}

#pragma mark - Engine I/O

/*!
 Writes the string to the engine.
 
 @param string A string that does NOT contain a new line character.
 */
- (void)sendCommandToEngine:(NSString *)string
{
    NSAssert([string sfm_containsString:@"\n"] == NO, @"UCI command contains new line");
    NSString *strWithNewLine = [NSString stringWithFormat:@"%@\n", string];
    [self.writeHandle writeData:[strWithNewLine dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)dataIsAvailable:(NSNotification *)notification
{
    NSString *output = [[NSString alloc] initWithData:[self.readHandle availableData]
                                             encoding:NSUTF8StringEncoding];
    if ([output sfm_containsString:@"\n"]) {
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        for (NSString *str in lines) {
            [self processEngineOutput:str];
        }
    } else {
        [self processEngineOutput:output];
    }
    
    [self.readHandle waitForDataInBackgroundAndNotify];
}

/*!
 Processes a single line of output from the engine.
 
 @param str A string that does NOT contain a new line character.
 */
- (void)processEngineOutput:(NSString *)str
{
    NSAssert([str sfm_containsString:@"\n"] == NO, @"Cannot process output with new line");
    
    if ([str isEqualToString:@""]) {
        return;
    }
    
    NSArray *tokens = [str componentsSeparatedByString:@" "];
    
    if ([tokens containsObject:@"currmove"]) {
        // Current move update
        NSString *moveUci = [tokens sfm_objectAfterObject:@"currmove"];
        if (moveUci == nil) {
            return;
        }
        SFMMove *move = [[self.gameToAnalyze.position movesArrayForUci:@[moveUci]] firstObject];
        if (move == nil) {
            return;
        }
        NSString *moveNumber = [tokens sfm_objectAfterObject:@"currmovenumber"];
        NSString *depth = [tokens sfm_objectAfterObject:@"depth"];
        if (moveNumber == nil || depth == nil) {
            return;
        }
        
        [self.delegate uciEngine:self
            didGetNewCurrentMove:move
                          number:[moveNumber integerValue]
                           depth:[depth integerValue]];
    } else if ([tokens containsObject:@"depth"] && [tokens containsObject:@"pv"]) {
        // New line
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:self.lines];
        SFMUCILine *line = [[SFMUCILine alloc] initWithTokens:tokens position:self.gameToAnalyze.position];
        NSArray *oldMoves = ((SFMUCILine *) self.lines[@(line.variationNum)]).moves;
        if ([line.moves sfm_isPrefixOf:oldMoves]) {
            line.moves = [oldMoves copy];
        }
        newDict[@(line.variationNum)] = line;
        self.lines = newDict;
        [self.delegate uciEngine:self didGetNewLine:newDict];
    } else if ([tokens containsObject:@"bestmove"]) {
        // Stopped analysis
        dispatch_group_leave(_analysisGroup);
        atomic_fetch_sub(&instancesAnalyzing, 1);
    } else if ([tokens containsObject:@"id"] && [tokens containsObject:@"name"]) {
        // Engine ID
        [self.delegate uciEngine:self didGetEngineName:[str substringFromIndex:[str rangeOfString:@"id name"].length + 1]];
    } else if ([tokens containsObject:@"option"] && [tokens containsObject:@"name"]) {
        // Option
        NSString *optionName = [[tokens sfm_objectsAfterObject:@"name" beforeObject:@"type"] componentsJoinedByString:@" "];
        if ([SFMUCIOption isOptionSupported:optionName]) {
            NSString *defaultValue = [tokens sfm_objectAfterObject:@"default"];
            NSString *minValue = [tokens sfm_objectAfterObject:@"min"];
            NSString *maxValue = [tokens sfm_objectAfterObject:@"max"];
            SFMUCIOption *option = [[SFMUCIOption alloc] initWithName:optionName default:defaultValue min:minValue max:maxValue];

            [self.options addObject:option];
        }
    } else if ([tokens containsObject:@"uciok"]) {
        // All options printed
        if ([self.delegate respondsToSelector:@selector(uciEngine:didGetOptions:)]) {
            [self.delegate uciEngine:self didGetOptions:self.options];
        }
    } else {
        // Ignore
    }
}

#pragma mark - Init

- (instancetype)initStockfish
{
    return [self initWithPathToEngine:[SFMUCIEngine bestEnginePath] applyPreferences:YES];
}

- (instancetype)initOptionsProbe {
    return [self initWithPathToEngine:[SFMUCIEngine bestEnginePath] applyPreferences:NO];
}

+ (NSString *)bestEnginePath {
    SFMCPURating cpuRating = [SFMUCIEngine cpuRating];
    if (cpuRating == SFMCPURatingBMI2) {
        return [[NSBundle mainBundle] pathForResource:@"stockfish-bmi2" ofType:@""];
    } else if (cpuRating == SFMCPURatingSSE42) {
        return [[NSBundle mainBundle] pathForResource:@"stockfish-sse42" ofType:@""];
    } else {
        return [[NSBundle mainBundle] pathForResource:@"stockfish-64" ofType:@""];
    }
}

- (instancetype)initWithPathToEngine:(NSString *)path applyPreferences:(BOOL)shouldApplyPreferences;
{
    if (self = [super init]) {
        _engineTask = [[NSTask alloc] init];
        NSPipe *inPipe = [[NSPipe alloc] init];
        NSPipe *outPipe = [[NSPipe alloc] init];
        
        _engineTask.launchPath = path;
        _engineTask.standardInput = inPipe;
        _engineTask.standardOutput = outPipe;
        
        _readHandle = [outPipe fileHandleForReading];
        _writeHandle = [inPipe fileHandleForWriting];
        
        if (shouldApplyPreferences) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPreferencesToEngine:) name:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataIsAvailable:) name:NSFileHandleDataAvailableNotification object:self.readHandle];
        [_readHandle waitForDataInBackgroundAndNotify];
        
        [_engineTask launch];
        
        _isAnalyzing = NO;
        _gameToAnalyze = nil;
        _analysisGroup = dispatch_group_create();
        _options = [[NSMutableArray alloc] init];
        _multipv = 1;
        
        [self sendCommandToEngine:@"uci"];
        if (shouldApplyPreferences) {
            [self applyPreferencesToEngine:nil];
        }
    }
    return self;
}

/*!
 Returns the CPU rating of this computer.
 
 @return The CPU rating.
 */
+ (SFMCPURating)cpuRating
{
    NSPipe *outputPipe = [[NSPipe alloc] init];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/sysctl"];
    [task setStandardOutput:outputPipe];
    [task setArguments:@[@"-n", @"machdep.cpu"]];
    [task launch];
    [task waitUntilExit];
    NSData *data = [[outputPipe fileHandleForReading] availableData];
    NSString *cpuCapabilities = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([cpuCapabilities sfm_containsString:@"BMI2"]) {
        return SFMCPURatingBMI2;
    } else if ([cpuCapabilities sfm_containsString:@"POPCNT"]) {
        return SFMCPURatingSSE42;
    }
    return SFMCPURating64Bit;
}

#pragma mark - Instances

+ (int32_t)instancesAnalyzing {
    return instancesAnalyzing;
}

#pragma mark - Settings

- (void)setUciOption:(NSString *)option stringValue:(NSString *)value {
    [self sendCommandToEngine:[NSString stringWithFormat:@"setoption name %@ value %@", option, value]];
}

- (void)setUciOption:(NSString *)option integerValue:(NSInteger)value {
    [self setUciOption:option stringValue:[NSString stringWithFormat:@"%ld", value]];
}

- (void)applyPreferencesToEngine:(NSNotification *)notification
{
    if (self.isAnalyzing) {
        NSLog(@"Could not apply preferences because engine is analyzing");
        return;
    };
    [self setUciOption:@"Threads" integerValue:[SFMUserDefaults threadsValue]];
    [self setUciOption:@"Hash" integerValue:[SFMUserDefaults hashValue]];
    [self setUciOption:@"Contempt" integerValue:[SFMUserDefaults contemptValue]];
    [self setUciOption:@"Skill Level" integerValue:[SFMUserDefaults skillLevelValue]];
    
    // Syzygy Path
    if ([SFMUserDefaults sandboxBookmarkData]) {
        NSError *error = nil;
        BOOL dataIsStale;
        self.bookmarkUrl = [NSURL URLByResolvingBookmarkData:[SFMUserDefaults sandboxBookmarkData] options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&dataIsStale error:&error];
        [self.bookmarkUrl startAccessingSecurityScopedResource];
        if (error) {
            NSLog(@"%@", [error description]);
        } else if (dataIsStale) {
            // Need to recreate
            NSData *bookmarkData = [self.bookmarkUrl bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
            if (error) {
                NSLog(@"%@", [error description]);
            } else {
                [SFMUserDefaults setSandboxBookmarkData:bookmarkData];
            }
        } else {
            NSString *absoluteString = self.bookmarkUrl.absoluteString;
            NSString *stripped = [absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            stripped = [stripped stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
            [self setUciOption:@"SyzygyPath" stringValue:stripped];
        }
    }
}

#pragma mark - Teardown

- (void)dealloc
{
    if (self.isAnalyzing) {
        // Apparently if you don't balance out your dispatch calls, you'll get very weird crashes
        dispatch_group_leave(_analysisGroup);
        atomic_fetch_sub(&instancesAnalyzing, 1);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.engineTask interrupt];
    [self.engineTask terminate]; // Just for good measure
    [self.bookmarkUrl stopAccessingSecurityScopedResource];
}

@end
