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

#pragma mark - Min
+ (int)minCpuCores
{
    return 1;
}
+ (int)minMemory
{
    return 32;
}

#pragma mark - Normal
+ (int)normCpuCores
{
    return MAX(1, [self cpuCores] / 2);
}
+ (int)normMemory
{
    return MIN(8192, [self totalMemory] / 4);
}

#pragma mark - Max
+ (int)maxCpuCores
{
    return [self cpuCores];
}
+ (int)maxMemory
{
    return MIN(8192, 7 * [self totalMemory] / 8);
}

#pragma mark - Validation
+ (BOOL)isValidCpuCoreValue:(int)value
{
    return (value >= [self minCpuCores] && value <= [self maxCpuCores]);
}
+ (BOOL)isValidMemoryValue:(int)value;
{
    return (value >= [self minMemory] && value <= [self maxMemory]);
}

@end
