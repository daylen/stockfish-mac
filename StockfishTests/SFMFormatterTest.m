//
//  SFMFormatterTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/17/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMFormatter.h"

@interface SFMFormatterTest : XCTestCase

@end

@implementation SFMFormatterTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testScore
{
    XCTAssertEqualObjects([SFMFormatter scoreAsText:23 isMate:NO isWhiteToMove:YES isLowerBound:NO isUpperBound:NO], @"+ (0.23)");
    XCTAssertEqualObjects([SFMFormatter scoreAsText:-5 isMate:YES isWhiteToMove:YES isLowerBound:NO isUpperBound:NO], @"- (#5)");
    XCTAssertEqualObjects([SFMFormatter scoreAsText:10327 isMate:NO isWhiteToMove:NO isLowerBound:NO isUpperBound:NO], @"- (103.27)");
    XCTAssertEqualObjects([SFMFormatter scoreAsText:502 isMate:NO isWhiteToMove:NO isLowerBound:YES isUpperBound:NO], @"- (5.02++)");
}

- (void)testNodes
{
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"1"], @"1 N");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"10"], @"10 N");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"100"], @"100 N");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"1000"], @"1000 N");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"10000"], @"10 kN");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"100000"], @"100 kN");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"1000000"], @"1000 kN");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"10000000"], @"10 MN");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"100000000"], @"100 MN");
    XCTAssertEqualObjects([SFMFormatter nodesAsText:@"1000000000"], @"1000 MN");

    
}

@end
