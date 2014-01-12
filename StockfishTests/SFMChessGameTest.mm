//
//  SFMChessGameTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMChessGame.h"

#include "../Chess/position.h"
#include "../Chess/bitboard.h"
#include "../Chess/direction.h"
#include "../Chess/mersenne.h"
#include "../Chess/movepick.h"

using namespace Chess;

@interface SFMChessGameTest : XCTestCase

@end

@implementation SFMChessGameTest

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

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSimpleGame
{
    SFMChessGame *game = [[SFMChessGame alloc] initWithWhite:[SFMPlayer new] andBlack:[SFMPlayer new]];
    XCTAssertEqual([game.moves count], 0);
    XCTAssertEqual(game.currentMoveIndex, 0);
    [game doMoveFrom:SQ_E2 to:SQ_E4];
    [game doMoveFrom:SQ_E7 to:SQ_E5];
    XCTAssertEqual([game.moves count], 2);
    XCTAssertEqual(game.currentMoveIndex, 2);
}
- (void)testLoadedGame
{
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{} andMoves:@"1. e4 e5 2. Nf3 Nc6"];
    [game populateMovesFromMoveText];
    XCTAssertEqual([game.moves count], 4);
    XCTAssertEqual(game.currentMoveIndex, 0);
    game.currentMoveIndex = 4;
    [game doMoveFrom:SQ_F1 to:SQ_B5];
    [game doMoveFrom:SQ_A7 to:SQ_A6];
    XCTAssertEqual([game.moves count], 6);
    XCTAssertEqual(game.currentMoveIndex, 6);
}

@end
