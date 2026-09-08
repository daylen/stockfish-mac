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
#include <fcntl.h>
#include <stdatomic.h>
#include <sys/sysctl.h>

typedef NS_ENUM(NSInteger, SFMCPURating) {
    SFMCPURatingX86_64_SSE41_POPCNT,
    SFMCPURatingX86_64_BMI2,
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
@property (nonatomic) NSUInteger outstandingAnalysisGroupEntries;
@property (nonatomic) BOOL engineDidTerminate;
@property (nonatomic) NSMutableData *pendingOutput;

@end

@implementation SFMUCIEngine

static _Atomic(int) instancesAnalyzing = 0;

#pragma mark - Setters

- (void)setIsAnalyzing:(BOOL)isAnalyzing {
    @synchronized (self) {
        if (_isAnalyzing == isAnalyzing) {
            return;
        }
        if (isAnalyzing && ![self enterAnalysisGroup]) {
            return;
        }
        _isAnalyzing = isAnalyzing;
    }
    self.lines = nil;

    if (isAnalyzing) {
        NSAssert(self.gameToAnalyze != nil, @"Trying to analyze but no game set");
        [self setUciOption:@"MultiPV" integerValue:self.multipv];
        [self setUciOption:@"UCI_ShowWDL" stringValue:self.showWdl ? @"true" : @"false"];
        [self sendCommandToEngine:[self.gameToAnalyze uciString]];
        [self.bookmarkUrl startAccessingSecurityScopedResource];
        [self sendCommandToEngine:@"go infinite"];
    } else {
        [self sendCommandToEngine:@"stop"];
        [self.bookmarkUrl stopAccessingSecurityScopedResource];
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
#pragma mark - Analysis group

- (BOOL)enterAnalysisGroup
{
    @synchronized (self) {
        if (self.engineDidTerminate) {
            return NO;
        }
        self.outstandingAnalysisGroupEntries += 1;
        dispatch_group_enter(_analysisGroup);
        atomic_fetch_add(&instancesAnalyzing, 1);
        return YES;
    }
}

- (void)leaveAnalysisGroupOnce
{
    @synchronized (self) {
        if (self.outstandingAnalysisGroupEntries == 0) {
            return;
        }
        self.outstandingAnalysisGroupEntries -= 1;
        dispatch_group_leave(_analysisGroup);
        atomic_fetch_sub(&instancesAnalyzing, 1);
    }
}

- (void)leaveAllAnalysisGroupEntries
{
    @synchronized (self) {
        while (self.outstandingAnalysisGroupEntries > 0) {
            [self leaveAnalysisGroupOnce];
        }
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
    if (!self.engineTask.isRunning) {
        return;
    }
    NSString *strWithNewLine = [NSString stringWithFormat:@"%@\n", string];
    @try {
        [self.writeHandle writeData:[strWithNewLine dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
        [self handleEngineTermination];
    }
}

- (void)dataIsAvailable:(NSNotification *)notification
{
    NSData *availableData = [self.readHandle availableData];
    BOOL engineClosedItsOutput = availableData.length == 0;
    if (engineClosedItsOutput) {
        [self handleEngineTermination];
        return;
    }

    [self.pendingOutput appendData:availableData];
    for (NSString *line in [self takeCompleteLines]) {
        [self processEngineOutput:line];
    }

    [self.readHandle waitForDataInBackgroundAndNotify];
}

- (NSArray<NSString *> *)takeCompleteLines
{
    NSMutableArray<NSString *> *lines = [[NSMutableArray alloc] init];
    const char newline = '\n';
    NSData *separator = [NSData dataWithBytes:&newline length:1];
    NSUInteger lineStart = 0;

    while (YES) {
        NSRange unconsumed = NSMakeRange(lineStart, self.pendingOutput.length - lineStart);
        NSRange separatorRange = [self.pendingOutput rangeOfData:separator options:0 range:unconsumed];
        if (separatorRange.location == NSNotFound) {
            break;
        }
        NSData *lineData = [self.pendingOutput subdataWithRange:NSMakeRange(lineStart, separatorRange.location - lineStart)];
        NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
        if (line != nil) {
            [lines addObject:line];
        }
        lineStart = NSMaxRange(separatorRange);
    }

    [self.pendingOutput replaceBytesInRange:NSMakeRange(0, lineStart) withBytes:NULL length:0];
    return lines;
}

- (void)handleEngineTermination
{
    @synchronized (self) {
        if (self.engineDidTerminate) {
            return;
        }
        self.engineDidTerminate = YES;
        [self leaveAllAnalysisGroupEntries];
        _isAnalyzing = NO;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleDataAvailableNotification
                                                  object:self.readHandle];
    [self.bookmarkUrl stopAccessingSecurityScopedResource];

    dispatch_async(dispatch_get_main_queue(), ^{
        id<SFMUCIEngineDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(uciEngineDidQuit:)]) {
            [delegate uciEngineDidQuit:self];
        }
    });
}

/*!
 Processes a single line of output from the engine.
 
 @param str A string that does NOT contain a new line character.
 */
- (void)processEngineOutput:(NSString *)str
{
    NSAssert([str sfm_containsString:@"\n"] == NO, @"Cannot process output with new line");
    
    NSArray *tokens = [[str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                       filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    if ([tokens count] == 0) {
        return;
    }

    NSString *messageType = [tokens firstObject];
    BOOL isInfoLine = [messageType isEqualToString:@"info"];
    BOOL isFreeFormInfoString = isInfoLine && [tokens count] > 1 && [tokens[1] isEqualToString:@"string"];
    BOOL isAnalysisInfoLine = isInfoLine && !isFreeFormInfoString;

    if (isAnalysisInfoLine && [tokens containsObject:@"currmove"]) {
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
    } else if (isAnalysisInfoLine && [tokens containsObject:@"depth"] && [tokens containsObject:@"pv"]) {
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
    } else if ([messageType isEqualToString:@"bestmove"]) {
        // Stopped analysis
        [self leaveAnalysisGroupOnce];
    } else if ([messageType isEqualToString:@"id"] && [tokens containsObject:@"name"]) {
        // Engine ID
        [self.delegate uciEngine:self didGetEngineName:[str substringFromIndex:[str rangeOfString:@"id name"].length + 1]];
    } else if ([messageType isEqualToString:@"option"] && [tokens containsObject:@"name"]) {
        // Option
        NSString *optionName = [[tokens sfm_objectsAfterObject:@"name" beforeObject:@"type"] componentsJoinedByString:@" "];
        if ([SFMUCIOption isOptionSupported:optionName]) {
            NSString *defaultValue = [tokens sfm_objectAfterObject:@"default"];
            NSString *minValue = [tokens sfm_objectAfterObject:@"min"];
            NSString *maxValue = [tokens sfm_objectAfterObject:@"max"];
            SFMUCIOption *option = [[SFMUCIOption alloc] initWithName:optionName default:defaultValue min:minValue max:maxValue];

            [self.options addObject:option];
        }
    } else if ([messageType isEqualToString:@"uciok"]) {
        // All options printed
        if ([self.delegate respondsToSelector:@selector(uciEngine:didGetOptions:)]) {
            [self.delegate uciEngine:self didGetOptions:self.options];
        }
    } else if (isFreeFormInfoString && [tokens containsObject:@"evaluation"]) {
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
        _engineTask.standardError = outPipe;
        // Set current directory so that the engine can locate the .nnue file.
        _engineTask.currentDirectoryURL = [[NSBundle mainBundle] resourceURL];
        
        _readHandle = [outPipe fileHandleForReading];
        _writeHandle = [inPipe fileHandleForWriting];
        fcntl(_writeHandle.fileDescriptor, F_SETNOSIGPIPE, 1);
        
        _isAnalyzing = NO;
        _gameToAnalyze = nil;
        _pendingOutput = [[NSMutableData alloc] init];
        _analysisGroup = dispatch_group_create();
        _options = [[NSMutableArray alloc] init];
        _multipv = 1;

        if (shouldApplyPreferences) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPreferencesToEngine:) name:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataIsAvailable:) name:NSFileHandleDataAvailableNotification object:self.readHandle];
        [_readHandle waitForDataInBackgroundAndNotify];
        
        __weak typeof(self) weakSelf = self;
        _engineTask.terminationHandler = ^(NSTask *task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleEngineTermination];
            });
        };

        [_engineTask launch];
        
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
    self.engineTask.terminationHandler = nil;
    [self leaveAllAnalysisGroupEntries];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.engineTask interrupt];
    [self.engineTask terminate]; // Just for good measure
    [self.bookmarkUrl stopAccessingSecurityScopedResource];
}

@end
