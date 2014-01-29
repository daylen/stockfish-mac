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

#include "../Chess/position.h"
#include "../Chess/bitboard.h"
#include "../Chess/direction.h"
#include "../Chess/mersenne.h"
#include "../Chess/movepick.h"

@interface SFMParserTest : XCTestCase

@end

@implementation SFMParserTest

- (void)setUp
{
    [super setUp];
    init_mersenne();
    init_direction_table();
    init_bitboards();
    Position::init_zobrist();
    Position::init_piece_square_tables();
    MovePicker::init_phase_table();
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

- (void)testIsLetter
{
    XCTAssertTrue([SFMParser isLetter:'a'], @"Epic fail");
    XCTAssertTrue([SFMParser isLetter:'e'], @"Epic fail");
    XCTAssertTrue([SFMParser isLetter:'z'], @"Epic fail");
    XCTAssertTrue([SFMParser isLetter:'A'], @"Epic fail");
    XCTAssertTrue([SFMParser isLetter:'Q'], @"Epic fail");
    XCTAssertTrue([SFMParser isLetter:'Z'], @"Epic fail");
    XCTAssertFalse([SFMParser isLetter:'1'], @"Epic fail");
    XCTAssertFalse([SFMParser isLetter:'0'], @"Epic fail");
}

- (void)testParseMoves
{
    NSString *fiveMoves = @"1. e4\ne5 2.\rNf3 Nc6\r\n3. Bb5";
    NSArray *fiveMovesParsed = [SFMParser parseMoves:fiveMoves];
    NSArray *fiveMovesExpect = @[@"e4", @"e5", @"Nf3", @"Nc6", @"Bb5"];
    XCTAssertEqualObjects(fiveMovesParsed, fiveMovesExpect, @"Parse failure for 5 moves");
    
    NSString *complexFiveMoves = @"1.e4 (asdf ( ) ) e5 2.{!} Nf3 Nc6 {Na1} 3. Bb5 {Good} *";
    NSArray *complexFiveMovesParsed = [SFMParser parseMoves:complexFiveMoves];
    XCTAssertEqualObjects(complexFiveMovesParsed, fiveMovesExpect, @"Parse failure for complex 5 moves");
    
    NSString *anotherTest = @"1.e4 ({23}) e5 2. Nf3 Nc6 3.Bb5 {1123211344()}";
    NSArray *anotherTestParsed = [SFMParser parseMoves:anotherTest];
    XCTAssertEqualObjects(anotherTestParsed, fiveMovesExpect);
}

@end
