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
@property NSPipe *inPipe;
@property NSPipe *outPipe;

@end

@implementation SFMUCIEngine

#pragma mark - Convenience methods
- (void)sendCommandToEngine:(NSString *)string
{
    [[self.inPipe fileHandleForWriting] writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}
- (NSString *)outputFromEngine
{
    return [[NSString alloc] initWithData:[[self.outPipe fileHandleForReading] availableData]
                                 encoding:NSUTF8StringEncoding];
}

#pragma mark - Init

- (id)initWithPathToEngine:(NSString *)path
{
    self = [super init];
    if (self) {
        
        // Init stuff
        self.engineTask = [[NSTask alloc] init];
        self.inPipe = [[NSPipe alloc] init];
        self.outPipe = [[NSPipe alloc] init];
        
        // Set properties on task
        self.engineTask.launchPath = path;
        self.engineTask.standardInput = self.inPipe;
        self.engineTask.standardOutput = self.outPipe;
        
        // Launch task and discard initial output
        [self.engineTask launch];
        [[self.outPipe fileHandleForReading] availableData];
        
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
    NSPipe *outputPipe = [[NSPipe alloc] init];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/sysctl"];
    [task setStandardOutput:outputPipe];
    [task setArguments:@[@"-n", @"machdep.cpu.features"]];
    [task launch];
    [task waitUntilExit];
    NSData *data = [[outputPipe fileHandleForReading] availableData];
    NSString *cpuCapabilities = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([cpuCapabilities rangeOfString:@"POPCNT"].location == NSNotFound) {
        // Just load 64-bit
        NSLog(@"No POPCNT");
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-64" ofType:@""]];
    } else {
        // Load 64-bit with SSE4.2
        NSLog(@"Detected POPCNT");
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-sse42" ofType:@""]];
    }
    
}
#pragma mark - Using the engine
- (NSString *)engineName
{
    [self sendCommandToEngine:@"uci\n"];
    NSString *output = [self outputFromEngine];
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSString *name = lines[0];
    NSRange toRemove = [name rangeOfString:@"id name "];
    name = [name substringFromIndex:toRemove.length];
    return name;
}

#pragma mark - Settings
- (NSDictionary *)engineOptions
{
    return @{}; // TODO implement
}

- (void)setValue:(NSString *)value forOption:(NSString *)key
{
    NSString *str = [NSString stringWithFormat:@"setoption name %@ value %@\n", key, value];
    [self sendCommandToEngine:str];
}

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
    NSLog(@"Using %d threads", numThreads);
    [self setValue:[NSString stringWithFormat:@"%d", numThreads] forOption:@"Threads"];
    
    // Set memory
    int totalMemory = (int) ([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024); // in MB
    int recommendedMemory = MIN(totalMemory / 4, 8192);
    NSLog(@"Using %d MB memory", recommendedMemory);
    [self setValue:[NSString stringWithFormat:@"%d", recommendedMemory] forOption:@"Hash"];
}

#pragma mark - Teardown
- (void)dealloc
{
    NSLog(@"Terminating engine");
    [self.engineTask terminate];
    self.engineTask = nil;
}

@end
