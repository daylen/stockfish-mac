//
//  SFMHardwareDetector.h
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMHardwareDetector : NSObject

+ (int)cpuCores;
+ (int)totalMemory; // in MB

+ (int)minCpuCores;
+ (int)minMemory;

+ (int)maxCpuCores;
+ (int)maxMemory;

+ (BOOL)isValidCpuCoreValue:(int)value;
+ (BOOL)isValidMemoryValue:(int)value;

@end
