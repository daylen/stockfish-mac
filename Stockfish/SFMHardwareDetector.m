//
//  SFMHardwareDetector.m
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMHardwareDetector.h"
#import "Constants.h"

@implementation SFMHardwareDetector

#pragma mark - Private
+ (int)cpuCores
{
    return (int) [[NSProcessInfo processInfo] activeProcessorCount];
}
+ (int)totalMemory
{
    return (int) ([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024);
}
+ (int)maximumMemoryPower:(int)totalMemory
{
    return (int) log2(totalMemory / 2);
}

#pragma mark - Public

+ (int)minimumSupportedThreads
{
    return MIN_SUPPORTED_THREADS;
}
+ (int)minimumMemoryPower
{
    return MIN_MEMORY_POWER;
}

+ (int)maximumSupportedThreads
{
    return [self cpuCores];
}

+ (int)maximumMemoryPower
{
    return [self maximumMemoryPower:[self totalMemory]];
}

@end
