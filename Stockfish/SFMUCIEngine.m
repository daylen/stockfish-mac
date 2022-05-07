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
#include <sys/sysctl.h>

typedef NS_ENUM(NSInteger, SFMCPURating) {
    SFMCPURatingX86_64_SSE41_POPCNT,
    SFMCPURatingX86_64_BMI2,
    SFMCPURatingX86_64_AVX512_VNNI,
    SFMCPURatingArm64
};

@interface SFMUCIEngine()

@property NSTask *engineTask;
@property NSFileHandle *readHandle;
@property NSFileHandle *writeHandle;

@property (nonatomic) NSURL *bookmarkUrl;

@property (readwrite, nonatomic) NSDictionary /* <NSNumber, SFMUCILine> */ *lines;
@property (readwrite, nonatomic) NSString *nnueInfo;
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
            [self setUciOption:@"Use NNUE" stringValue:self.useNnue ? @"true" : @"false"];
            [self setUciOption:@"UCI_ShowWDL" stringValue:self.showWdl ? @"true" : @"false"];
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

- (void)setUseNnue:(BOOL)useNnue {
    if (self.isAnalyzing) {
        self.isAnalyzing = NO;
        dispatch_group_notify(_analysisGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self->_useNnue = useNnue;
            self.isAnalyzing = YES;
        });
    } else {
        _useNnue = useNnue;
    }
}

- (void)setShowWdl:(BOOL)showWdl {
    if (self.isAnalyzing) {
        self.isAnalyzing = NO;
        dispatch_group_notify(_analysisGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self->_showWdl = showWdl;
            self.isAnalyzing = YES;
        });
    } else {
        _showWdl = showWdl;
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
    } else if ([tokens containsObject:@"string"] && [tokens containsObject:@"evaluation"]) {
        if ([tokens containsObject:@"NNUE"]) {
            for (NSString *token in tokens) {
                if ([token containsString:@".nnue"]) {
                    self.nnueInfo = token;
                }
            }
            [self.delegate uciEngine:self didGetInfoString:_nnueInfo];
        } else {
            self.nnueInfo = @"";
            [self.delegate uciEngine:self didGetInfoString:_nnueInfo];
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
    if (cpuRating == SFMCPURatingArm64)
        return [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"stockfish-arm64"];

    // VNNI 256 is faster than VNNI 512: https://github.com/official-stockfish/Stockfish/pull/3038#issuecomment-679002949
    if (cpuRating == SFMCPURatingX86_64_AVX512_VNNI)
        return [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"stockfish-x86-64-vnni256"];
    if (cpuRating == SFMCPURatingX86_64_BMI2)
        return [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"stockfish-x86-64-bmi2"];

    return [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"stockfish-x86-64-sse41-popcnt"];
}

- (instancetype)initWithPathToEngine:(NSString *)path applyPreferences:(BOOL)shouldApplyPreferences;
{
    NSLog(@"Launching engine with path %@", path);
    if (self = [super init]) {
        _engineTask = [[NSTask alloc] init];
        NSPipe *inPipe = [[NSPipe alloc] init];
        NSPipe *outPipe = [[NSPipe alloc] init];
        
        _engineTask.launchPath = path;
        _engineTask.standardInput = inPipe;
        _engineTask.standardOutput = outPipe;
        // Set current directory so that the engine can locate the .nnue file.
        _engineTask.currentDirectoryURL = [[NSBundle mainBundle] resourceURL];
        
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
    int ret = 0;
    size_t size = sizeof(ret);
    
    sysctlbyname("hw.optional.arm64", &ret, &size, NULL, 0);
    if (ret) return SFMCPURatingArm64;
    
    // IFMA implies VNNI.
    sysctlbyname("hw.optional.avx512ifma", &ret, &size, NULL, 0);
    if (ret) return SFMCPURatingX86_64_AVX512_VNNI;
    
    // 2019 Mac Pro uses Cascade Lake Xeon W which doesn't support IFMA but does support VNNI.
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    BOOL isMacProWithVnni = NO;
    if (len) {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        if (strcmp(model, "MacPro7,1") == 0) isMacProWithVnni = YES;
        free(model);
    }
    if (isMacProWithVnni) return SFMCPURatingX86_64_AVX512_VNNI;
    
    sysctlbyname("hw.optional.bmi2", &ret, &size, NULL, 0);
    if (ret) return SFMCPURatingX86_64_BMI2;
    
    // All Macs running Mojave (10.14) or later support SSE4.1 and POPCNT.
    return SFMCPURatingX86_64_SSE41_POPCNT;
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
