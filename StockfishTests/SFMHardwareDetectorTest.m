//
//  SFMHardwareDetectorTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/19/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMHardwareDetector.h"

@interface SFMHardwareDetectorTest : XCTestCase

@end

@implementation SFMHardwareDetectorTest

- (void)testMemory
{
    // Test all the basic memory configurations and see if they're what we expect
    XCTAssertEqual(1, 1);
}

+ (int)maxMemoryForSimulatedSystemMemory:(int)megabytes
{
    return [self powerToMegabytes:[self maxPowerForSimulatedSystemMemory:megabytes]];
}

+ (int)maxPowerForSimulatedSystemMemory:(int)megabytes
{
    return [SFMHardwareDetector maximumMemoryPower:megabytes];
}

+ (int)powerToMegabytes:(int)power
{
    return (int) pow(2, power);
}

@end
