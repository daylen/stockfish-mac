//
//  SFMHardwareDetector.m
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMHardwareDetector.h"

@implementation SFMHardwareDetector

+ (int)maxThreads
{
    return (int) [[NSProcessInfo processInfo] activeProcessorCount];
}
+ (long)maxMemory
{
    return (long) ([[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024);
}

@end
