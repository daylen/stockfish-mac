//
//  SFMItertoolsTest.m
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "SFMItertools.h"

@interface SFMItertoolsTest : XCTestCase

@end

@implementation SFMItertoolsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPermutations {
    NSArray *permus = [SFMItertools permutations:@[@"a", @"b", @"c", @"d"] length:2];
    XCTAssertEqual([permus count], 12);
}

- (void)testCombinations {
    NSArray *combos = [SFMItertools combinations:@[@"a", @"b", @"c", @"d", @"e"] length:3];
    XCTAssert([combos count] == 10);
    combos = [SFMItertools combinations:@[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j"] length:4];
    XCTAssertEqual([combos count], 210);
}

@end
