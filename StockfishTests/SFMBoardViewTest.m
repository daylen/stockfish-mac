//
//  SFMBoardViewTest.m
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "SFMBoardView.h"
#import "SFMSquare.h"
#import "SFMMove.h"

@interface SFMBoardView()

+ (NSArray* /* of SFMMove */)shortestPathsFrom:(NSArray* /* of NSNumber(SFMSquare) */)from to:(NSArray* /* of NSNumber(SFMSquare) */)to;

@end

@interface SFMBoardViewTest : XCTestCase

@end

@implementation SFMBoardViewTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testShortestPaths {
    NSArray *paths = [SFMBoardView shortestPathsFrom:@[@(SQ_E2)] to:@[@(SQ_E4)]];
    XCTAssertEqualObjects(paths, @[[[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4]]);
}

@end
