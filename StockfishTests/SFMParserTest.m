//
//  SFMParserTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMParser.h"
#import "SFMChessGame.h"

@interface SFMParserTest : XCTestCase

@end

@implementation SFMParserTest

- (void)setUp
{
    [super setUp];
}

- (void)testParseGamesFromString
{
    NSString *fakepgn = @"[tag \"whoa\"]\r\n[another \"yay\"]\n\n1. e4\re5 2. Nf3\n\n[tag \"whoa\"]\n\n1. e4\n";
    NSMutableArray *games = [SFMParser parseGamesFromString:fakepgn];
    XCTAssertEqual([games count], 2, @"Wrong count");
    SFMChessGame *first = games[0];
    SFMChessGame *second = games[1];
    XCTAssertEqual([first.tags count], 2, @"Wrong count for game 1");
    XCTAssertEqual([second.tags count], 1, @"Wrong count for game 2");
}

- (void)testTokenizeMoveText
{
    NSString *fiveMoves = @"1. e4\ne5 2.\rNf3 Nc6\r\n3. Bb5";
    NSArray *fiveMovesParsed = [SFMParser tokenizeMoveText:fiveMoves];
    NSArray *fiveMovesExpect = @[@"e4", @"e5", @"Nf3", @"Nc6", @"Bb5"];
    XCTAssertEqualObjects(fiveMovesParsed, fiveMovesExpect, @"Parse failure for 5 moves");
    
    NSString *complexFiveMoves = @"1.e4 (asdf ( ) ) e5 2.{!} Nf3 Nc6 {Na1} 3. Bb5 {Good} *";
    NSArray *complexFiveMovesParsed = [SFMParser tokenizeMoveText:complexFiveMoves];
    XCTAssertEqualObjects(complexFiveMovesParsed, fiveMovesExpect, @"Parse failure for complex 5 moves");
    
    NSString *anotherTest = @"1.e4 ({23}) e5 2. Nf3 Nc6 3.Bb5 {1123211344()}";
    NSArray *anotherTestParsed = [SFMParser tokenizeMoveText:anotherTest];
    XCTAssertEqualObjects(anotherTestParsed, fiveMovesExpect);
}

@end
