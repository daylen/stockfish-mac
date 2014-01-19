//
//  SFMHardwareDetector.m
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMHardwareDetector.h"

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

#pragma mark - Public
+ (int)minimumSupportedThreads
{
    return 1;
}
+ (int)maximumSupportedThreads
{
    return [self cpuCores];
}

+ (int)minimumMemoryPower
{
    return 5; // 2^5 = 32
}
+ (int)maximumMemoryPower
{
    return (int) log2([self totalMemory] / 2);
}

@end
