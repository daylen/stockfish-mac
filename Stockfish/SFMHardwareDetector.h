//
//  SFMHardwareDetector.h
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

// TODO deprecate this class

@interface SFMHardwareDetector : NSObject

// Minimum
+ (int)minimumSupportedThreads;
+ (int)minimumMemoryPower;

// Maximum
+ (int)maximumSupportedThreads;
+ (int)maximumMemoryPower;

// Testing only
+ (int)maximumMemoryPower:(int)totalMemory;

@end
