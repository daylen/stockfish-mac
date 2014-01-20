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
    
    // Machines running OS X 10.9 require at least 2 GB of RAM
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:2 * 1024]), 1024);
    
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:3 * 1024]), 2048);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:4 * 1024]), 2048);
    
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:5 * 1024]), 4096);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:6 * 1024]), 4096);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:7 * 1024]), 4096);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:8 * 1024]), 4096);
    
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:9 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:10 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:11 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:12 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:13 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:14 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:15 * 1024]), 8192);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:16 * 1024]), 8192);
    
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:17 * 1024]), 16384);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:32 * 1024]), 16384);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:48 * 1024]), 16384);
    XCTAssertEqual((int) pow(2, [SFMHardwareDetector maximumMemoryPower:64 * 1024]), 16384);
}

@end
