//
//  SFMHardwareDetector.h
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMHardwareDetector : NSObject

+ (int)minimumSupportedThreads;
+ (int)maximumSupportedThreads;

+ (int)minimumMemoryPower;
+ (int)maximumMemoryPower;

@end
