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

@end

@implementation SFMUCIEngine

#pragma mark - Init

- (id)initWithPathToEngine:(NSString *)path
{
    self = [super init];
    if (self) {
        self.engineTask = [[NSTask alloc] init];
        self.engineTask.launchPath = path;
        [self.engineTask launch];
    }
    return self;
}

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
    
    if ([cpuCapabilities rangeOfString:@"SSE4.2"].location == NSNotFound) {
        // Just load 64-bit
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-64" ofType:@""]];
    } else {
        // Load 64-bit with SSE4.2
        return [self initWithPathToEngine:[[NSBundle mainBundle]
                                           pathForResource:@"stockfish-sse42" ofType:@""]];
    }
    
}

#pragma mark - Settings
- (NSDictionary *)engineOptions
{
    // TODO
    return @{};
}
- (BOOL)setValue:(NSString *)value forOption:(NSString *)key
{
    // TODO
    return NO;
}
- (void)automaticallySetThreadsAndHash
{
    // TODO
}

#pragma mark - Teardown
- (void)dealloc
{
    [self.engineTask terminate];
    self.engineTask = nil;
}

@end
