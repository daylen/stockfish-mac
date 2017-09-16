//
//  SFMPositionTest.m
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMPosition.h"
#import "SFMMove.h"

#include "Constants.h"

@interface SFMPositionTest : XCTestCase

@end

@implementation SFMPositionTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInit {
    SFMPosition *p = [[SFMPosition alloc] init];
    XCTAssert(p.isMate == NO);
    XCTAssert(p.isImmediateDraw == NO);
    XCTAssert(p.numLegalMoves == 20);
    XCTAssert(p.sideToMove == WHITE);
}

- (void)testInitWithFen {
    SFMPosition *p = [[SFMPosition alloc] initWithFen:@"8/4r1p1/6kp/2N5/p4P1P/B4P2/3K4/8 b - - 0 53"];
    XCTAssert(p.numLegalMoves == 18);
    XCTAssert(p.sideToMove == BLACK);
}

- (void)testIsValidFen {
    XCTAssertTrue([SFMPosition isValidFen:@"8/4r1p1/6kp/2N5/p4P1P/B4P2/3K4/8 b - - 0 53"]);
}

- (void)testDoMove {
    SFMPosition *p = [[SFMPosition alloc] init];
    NSError *error = nil;
    
    [p doMove:[[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4] error:&error];
    XCTAssertNil(error);
    XCTAssert(p.sideToMove == BLACK);
    XCTAssertEqualObjects(p.fen, @"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -");
    
    [p doMove:[[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5] error:&error];
    XCTAssertNil(error);
    XCTAssert(p.sideToMove == WHITE);
    XCTAssertEqualObjects(p.fen, @"rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -");
    
    [p doMove:[[SFMMove alloc] initWithFrom:SQ_E4 to:SQ_E8] error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, POSITION_ERROR_DOMAIN);
    XCTAssert(error.code == ILLEGAL_MOVE_CODE);
}

- (void)testSanForMovesArray {
    SFMPosition *p = [[SFMPosition alloc] init];
    SFMMove *m1 = [[SFMMove alloc] initWithFrom:SQ_D2 to:SQ_D4];
    SFMMove *m2 = [[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5];
    SFMMove *m3 = [[SFMMove alloc] initWithFrom:SQ_D4 to:SQ_E5];
    NSString *san = [p sanForMovesArray:@[m1, m2, m3] html:NO breakLines:NO num:1];
    XCTAssertEqualObjects(san, @"1. d4 e5 2. dxe5 ");
}

- (void)testMovesArrayForUci {
    SFMPosition *p = [[SFMPosition alloc] init];
    NSArray *movesArr = [p movesArrayForUci:@[@"e2e4", @"e7e5"]];
    XCTAssert([movesArr count] == 2);
}

- (void)testUciForMovesArray {
    SFMMove *m1 = [[SFMMove alloc] initWithFrom:SQ_D2 to:SQ_D4];
    SFMMove *m2 = [[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5];
    SFMMove *m3 = [[SFMMove alloc] initWithFrom:SQ_D4 to:SQ_E5];
    NSString *uci = [SFMPosition uciForMovesArray:@[m1, m2, m3]];
    XCTAssertEqualObjects(uci, @"d2d4 e7e5 d4e5 ");
}

- (void)testPieceOnSquare {
    SFMPosition *p = [[SFMPosition alloc] init];
    XCTAssert([p pieceOnSquare:SQ_E2] == PAWN);
}

- (void)testLegalSquaresFromSquare {
    SFMPosition *p = [[SFMPosition alloc] init];
    NSArray *legalSquares = [p legalSquaresFromSquare:SQ_E2];
    XCTAssert([legalSquares count] == 2);
    legalSquares = [p legalSquaresFromSquare:SQ_G1];
    XCTAssert([legalSquares count] == 2);
}

@end
