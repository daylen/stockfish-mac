//
//  SFMHardwareDetector.m
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMHardwareDetector.h"

@implementation SFMHardwareDetector

+ (int)cpuCores
{
    return (int) [[NSProcessInfo processInfo] activeProcessorCount];
}
+ (int)totalMemory
{
    return (int) ([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024);
}

+ (int)minCpuCores
{
    return 1;
}
+ (int)minMemory
{
    int minMemory = 0.125 * [self totalMemory];
    if (minMemory < 32) {
        minMemory = 32;
    }
    return minMemory;
}

+ (int)maxCpuCores
{
    return [self cpuCores];
}
+ (int)maxMemory
{
    return MIN(8192, 0.625 * [self totalMemory]);
}

+ (BOOL)isValidCpuCoreValue:(int)value
{
    return (value >= 1 && value <= [self cpuCores]);
}
+ (BOOL)isValidMemoryValue:(int)value;
{
    return (value >= 32 && value <= 8192);
}

@end
