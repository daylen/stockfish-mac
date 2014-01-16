//
//  SFMUCIEngine.m
//  Stockfish
//
//  Created by Daylen Yang on 1/15/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMUCIEngine.h"

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
    NSLog(@"GUI TO ENGINE: %@", string);
    NSString *strWithNewLine = [NSString stringWithFormat:@"%@\n", string];
    [self.writeHandle writeData:[strWithNewLine dataUsingEncoding:NSUTF8StringEncoding]];
}
- (NSString *)outputFromEngine
{
    return [[NSString alloc] initWithData:[self.readHandle availableData]
                                 encoding:NSUTF8StringEncoding];
}
- (void)dataIsAvailable:(NSNotification *)notification
{
    NSLog(@"%@", [self outputFromEngine]);
    [self.readHandle waitForDataInBackgroundAndNotify];
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
        
        // Set properties on task
        self.engineTask.launchPath = path;
        self.engineTask.standardInput = inPipe;
        self.engineTask.standardOutput = outPipe;
        
        // More init
        self.readHandle = [outPipe fileHandleForReading];
        self.writeHandle = [inPipe fileHandleForWriting];
        
        // Set up notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataIsAvailable:) name:NSFileHandleDataAvailableNotification object:self.readHandle];
        [self.readHandle waitForDataInBackgroundAndNotify];
        
        // Launch task and discard initial output
        [self.engineTask launch];
        
        // Set options on engine
        [self automaticallySetThreadsAndHash];
        
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
        NSLog(@"Detected POPCNT");
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-sse42" ofType:@""]];
    } else {
        NSLog(@"No POPCNT");
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
- (NSString *)engineName
{
    [self sendCommandToEngine:@"uci"];
    NSString *output = [self outputFromEngine];
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSString *name = lines[0];
    NSRange toRemove = [name rangeOfString:@"id name "];
    name = [name substringFromIndex:toRemove.length];
    return name;
}

- (void)setFEN:(NSString *)fenString
{
    [self sendCommandToEngine:[NSString stringWithFormat:@"position fen %@", fenString]];
}

- (void)startInfiniteAnalysis
{
    [self sendCommandToEngine:@"go infinite"];
}

- (void)stopSearch
{
    [self sendCommandToEngine:@"stop"];
}

#pragma mark - Settings
- (NSDictionary *)engineOptions
{
    return @{}; // TODO implement
}

- (void)setValue:(NSString *)value forOption:(NSString *)key
{
    NSString *str = [NSString stringWithFormat:@"setoption name %@ value %@", key, value];
    [self sendCommandToEngine:str];
}

#define MAX_HASH_SIZE 8192

/*
 Automatically set the number of threads and hash size to be used by the engine.
 Set the number of threads to be the number of cores in the machine, including hyperthreaded cores.
 Set the hash size to be either total memory divided by 4, or 8 GB, whichever is smaller.
 (Stockfish does not support more than 8 GB hash size.)
 */
- (void)automaticallySetThreadsAndHash
{
    // Set threads
    int numThreads = (int) [[NSProcessInfo processInfo] activeProcessorCount];
    [self setValue:[NSString stringWithFormat:@"%d", numThreads] forOption:@"Threads"];
    
    // Set memory
    int totalMemory = (int) ([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024); // in MB
    int recommendedMemory = MIN(totalMemory / 4, MAX_HASH_SIZE);
    [self setValue:[NSString stringWithFormat:@"%d", recommendedMemory] forOption:@"Hash"];
    
    NSLog(@"Using %d threads and %d MB memory", numThreads, recommendedMemory);
}

#pragma mark - Teardown
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self sendCommandToEngine:@"stop"];
    [self sendCommandToEngine:@"quit"];
    
}

@end
