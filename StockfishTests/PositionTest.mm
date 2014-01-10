//
//  PositionTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "Constants.h"
#include "../Chess/position.h"

using namespace Chess;

@interface PositionTest : XCTestCase

@end

@implementation PositionTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPositionClass
{
    Position *p = new Position;
    p->from_fen([FEN_START_POSITION UTF8String]);
    XCTAssertTrue(p->is_ok(), @"You probably didn't do chess init");
}

@end
