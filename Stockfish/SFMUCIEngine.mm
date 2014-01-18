//
//  SFMUCIEngine.m
//  Stockfish
//
//  Created by Daylen Yang on 1/15/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMUCIEngine.h"
#import "Constants.h"
#import "DYUserDefaults.h"

@interface SFMUCIEngine()

@property NSTask *engineTask;
@property NSFileHandle *readHandle;
@property NSFileHandle *writeHandle;

@end

@implementation SFMUCIEngine

#pragma mark - Engine communication
- (void)sendCommandToEngine:(NSString *)string
{
    assert([string rangeOfString:@"\n"].location == NSNotFound);
    NSString *strWithNewLine = [NSString stringWithFormat:@"%@\n", string];
    [self.writeHandle writeData:[strWithNewLine dataUsingEncoding:NSUTF8StringEncoding]];
}
- (NSString *)outputFromEngine
{
    return [[NSString alloc] initWithData:[self.readHandle availableData]
                                 encoding:NSUTF8StringEncoding];
}

#pragma mark - Handling notifications

- (void)dataIsAvailable:(NSNotification *)notification
{
    NSString *output = [self outputFromEngine];
    //NSLog(@"%@", output);
    if ([output rangeOfString:@"\n"].location != NSNotFound) {
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        for (NSString *str in lines) {
            [self processEngineOutput:str];
        }
    } else {
        [self processEngineOutput:output];
    }
    
    [self.readHandle waitForDataInBackgroundAndNotify];
}

/*
 Updates the properties on the class based on the output from the engine.
 */
- (void)processEngineOutput:(NSString *)str
{
    // What we want to look for
    NSArray *statusKeywords = @[@"depth", @"currmove", @"currmovenumber"];
    NSArray *lineKeywords = @[@"depth", @"seldepth", @"nps", @"cp", @"mate", @"time", @"nodes"];
    
    // Tokenize the string
    NSArray *tokens = [str componentsSeparatedByString:@" "];
    
    if ([str rangeOfString:@"currmovenumber"].location != NSNotFound) {
        // Process status update
        for (int i = 0; i < [tokens count]; i++) {
            for (NSString *keyword in statusKeywords) {
                if ([tokens[i] isEqualToString:keyword]) {
                    self.currentInfo[keyword] = tokens[++i];
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ENGINE_CURRENT_MOVE_CHANGED_NOTIFICATION object:self];
    } else if ([str rangeOfString:@"multipv"].location != NSNotFound) {
        // Process a line of analysis
        NSMutableDictionary *line = [[NSMutableDictionary alloc] init];
        for (int i = 0; i < [tokens count]; i++) {
            if ([tokens[i] isEqualToString:@"multipv"]) {
                break;
            }
            for (NSString *keyword in lineKeywords) {
                if ([tokens[i] isEqualToString:keyword]) {
                    line[keyword] = tokens[++i];
                }
            }
        }
        
        // Process the PV
        NSRange range = [str rangeOfString:@"multipv 1 pv"];
        if (range.location == NSNotFound) {
            //NSLog(@"Somehow this is a multipv without a pv");
            return;
        }
        line[@"pv"] = [str substringFromIndex:range.location + range.length + 1];
        
        // Check for upper/lower bounds
        range = [str rangeOfString:@"upperbound"];
        if (range.location != NSNotFound) {
            line[@"upperbound"] = [NSNumber numberWithBool:YES];
        }
        range = [str rangeOfString:@"lowerbound"];
        if (range.location != NSNotFound) {
            line[@"lowerbound"] = [NSNumber numberWithBool:YES];
        }
        
        // Add the line to the line history
        [self.lineHistory addObject:[line copy]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ENGINE_NEW_LINE_AVAILABLE_NOTIFICATION object:self];
    } else if ([str rangeOfString:@"bestmove"].location != NSNotFound) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ENGINE_BEST_MOVE_AVAILABLE_NOTIFICATION object:self];
    } else if ([str rangeOfString:@"id name"].location != NSNotFound) {
        // Process name
        NSRange range = [str rangeOfString:@"id name"];
        self.engineName = [str substringFromIndex:range.length + 1];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ENGINE_NAME_AVAILABLE_NOTIFICATION object:self];
    }
}

#pragma mark - Init

- (id)initWithPathToEngine:(NSString *)path
{
    self = [super init];
    if (self) {
        // Init stuff
        self.engineTask = [[NSTask alloc] init];
        NSPipe *inPipe = [[NSPipe alloc] init];
        NSPipe *outPipe = [[NSPipe alloc] init];
        self.currentInfo = [[NSMutableDictionary alloc] init];
        self.lineHistory = [[NSMutableArray alloc] init];
        self.isAnalyzing = NO;
        
        // Set properties on task
        self.engineTask.launchPath = path;
        self.engineTask.standardInput = inPipe;
        self.engineTask.standardOutput = outPipe;
        
        // More init
        self.readHandle = [outPipe fileHandleForReading];
        self.writeHandle = [inPipe fileHandleForWriting];
        
        // Set up notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setThreadsAndHashFromPrefs:) name:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataIsAvailable:) name:NSFileHandleDataAvailableNotification object:self.readHandle];
        [self.readHandle waitForDataInBackgroundAndNotify];
        
        // Launch task
        [self.engineTask launch];
        
        // Set options on engine
        [self sendCommandToEngine:@"uci"];
        [self setThreadsAndHashFromPrefs:nil];
        
    }
    return self;
}

/*
 Detects whether the CPU supports POPCNT and loads the appropriate version
 of Stockfish.
 */
- (id)initStockfish
{
    if ([self hasAdvancedCPU]) {
        //NSLog(@"Detected POPCNT");
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-sse42" ofType:@""]];
    } else {
        //NSLog(@"No POPCNT");
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-64" ofType:@""]];
    }
}

/*
 Returns true if the CPU supports POPCNT.
 */
- (BOOL)hasAdvancedCPU
{
    NSPipe *outputPipe = [[NSPipe alloc] init];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/sysctl"];
    [task setStandardOutput:outputPipe];
    [task setArguments:@[@"-n", @"machdep.cpu.features"]];
    [task launch];
    [task waitUntilExit];
    NSData *data = [[outputPipe fileHandleForReading] availableData];
    NSString *cpuCapabilities = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [cpuCapabilities rangeOfString:@"POPCNT"].location != NSNotFound;
}

#pragma mark - Using the engine

- (void)startInfiniteAnalysis
{
    self.isAnalyzing = YES;
    self.currentInfo = [NSMutableDictionary new];
    self.lineHistory = [NSMutableArray new];
    [self sendCommandToEngine:@"go infinite"];
}

- (void)stopSearch
{
    self.isAnalyzing = NO;
    [self sendCommandToEngine:@"stop"];
}

#pragma mark - Settings

- (void)setValue:(NSString *)value forOption:(NSString *)key
{
    NSString *str = [NSString stringWithFormat:@"setoption name %@ value %@", key, value];
    [self sendCommandToEngine:str];
}
- (void)setThreadsAndHashFromPrefs:(NSNotification *)notification
{
    if (self.isAnalyzing) {
        return;
    }
    [self setValue:[NSString stringWithFormat:@"%d", [(NSNumber *) [DYUserDefaults getSettingForKey:NUM_THREADS_SETTING] intValue]] forOption:@"Threads"];
    [self setValue:[NSString stringWithFormat:@"%d", [(NSNumber *) [DYUserDefaults getSettingForKey:HASH_SIZE_SETTING] intValue]] forOption:@"Hash"];
}

#pragma mark - Teardown

- (void)dealloc
{
    //NSLog(@"Deallocating engine");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopSearch];
    [self sendCommandToEngine:@"quit"];

}

@end
