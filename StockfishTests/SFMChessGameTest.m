//
//  SFMChessGameTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMChessGame.h"

@interface SFMChessGameTest : XCTestCase

@end

@implementation SFMChessGameTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testSimpleGame
{
    SFMChessGame *game = [[SFMChessGame alloc] init];
    XCTAssertTrue([game atBeginning]);
    XCTAssertTrue([game atEnd]);
    [game doMove:[[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4] error:nil];
    [game doMove:[[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5] error:nil];
    XCTAssertTrue([game atEnd]);
    XCTAssertEqualObjects([[game moveTextString] string], @"1. e4 e5 ");
}
- (void)testLoadedGame
{
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{} moveText:@"1. e4 e5 2. Nf3 Nc6"];
    NSError *error = nil;
    [game parseMoveText:&error];
    XCTAssertNil(error);
    XCTAssertTrue([game atBeginning]);
    [game goToEnd];
    XCTAssertTrue([game atEnd]);
    [game doMove:[[SFMMove alloc] initWithFrom:SQ_F1 to:SQ_B5] error:&error];
    XCTAssertNil(error);
    [game doMove:[[SFMMove alloc] initWithFrom:SQ_A7 to:SQ_A6] error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([game atEnd]);
    XCTAssertEqualObjects([[game moveTextString] string], @"1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 ");
}

- (void)testUciStringOutput
{
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{} moveText:@"1. e4 e5"];
    [game parseMoveText:nil];
    [game goToEnd];
    NSString *uci = [game uciString];
    XCTAssertEqualObjects(uci, @"position startpos moves e2e4 e7e5 ");
}

@end
