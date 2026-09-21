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
#import "SFMNode.h"

#include "Constants.h"

@interface SFMPositionTest : XCTestCase

@end

@implementation SFMPositionTest

- (NSArray<SFMMove *> *)repeatedKnightMovesWithPlyCount:(NSUInteger)plyCount
{
    NSArray<SFMMove *> *cycle = @[
        [[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3],
        [[SFMMove alloc] initWithFrom:SQ_G8 to:SQ_F6],
        [[SFMMove alloc] initWithFrom:SQ_F3 to:SQ_G1],
        [[SFMMove alloc] initWithFrom:SQ_F6 to:SQ_G8]
    ];
    NSMutableArray<SFMMove *> *moves = [NSMutableArray new];
    for (NSUInteger ply = 0; ply < plyCount; ply++) {
        [moves addObject:cycle[ply % cycle.count]];
    }
    return moves;
}

- (void)assertLongSANConversionWithHTML:(BOOL)html
{
    const NSUInteger cycleCount = 201;
    const NSUInteger pliesPerCycle = 4;
    NSUInteger plyCount = cycleCount * pliesPerCycle;
    SFMPosition *position = [[SFMPosition alloc] init];
    NSString *initialFen = position.fen;
    NSMutableString *expected = [NSMutableString new];
    for (NSUInteger cycle = 0; cycle < cycleCount; cycle++) {
        [expected appendFormat:@"%lu. Nf3 Nf6 %lu. Ng1 Ng8 ",
         (unsigned long)(cycle * 2 + 1), (unsigned long)(cycle * 2 + 2)];
    }
    NSString *converted = [position sanForMovesArray:[self repeatedKnightMovesWithPlyCount:plyCount]
                                               html:html breakLines:NO num:html ? (int)plyCount : 1];
    XCTAssertNotNil(converted);
    if (html) {
        NSString *lastPlyAnchor = [NSString stringWithFormat:@"id=\"ply%lu\"", (unsigned long)(plyCount - 1)];
        XCTAssertTrue([converted containsString:lastPlyAnchor]);
        XCTAssertTrue([converted containsString:@"<strong>Ng8</strong>"]);
        NSRegularExpression *tags = [NSRegularExpression regularExpressionWithPattern:@"<[^>]*>" options:0 error:NULL];
        converted = [tags stringByReplacingMatchesInString:converted options:0 range:NSMakeRange(0, converted.length) withTemplate:@""];
    }
    XCTAssertEqualObjects(converted, expected);
    XCTAssertEqualObjects(position.fen, initialFen);
}

- (void)testPlainSANConversionBeyondFormerMoveArrayLimit
{
    [self assertLongSANConversionWithHTML:NO];
}

- (void)testHTMLSANConversionBeyondFormerMoveArrayLimit
{
    [self assertLongSANConversionWithHTML:YES];
}

- (void)testCopiedPositionCanUndoAndBranchAcrossFormerHistoryLimit
{
    const NSUInteger pliesBeforeCopy = 599;
    const int undoToCycleBoundary = 3;
    const int branchPlies = 8;
    SFMPosition *position = [[SFMPosition alloc] init];
    NSString *initialFen = position.fen;
    NSError *error = nil;
    XCTAssertTrue([position doMoves:[self repeatedKnightMovesWithPlyCount:pliesBeforeCopy] error:&error]);
    XCTAssertNil(error);
    NSString *originalFen = position.fen;
    SFMPosition *copy = [position copy];
    XCTAssertEqualObjects(copy.fen, originalFen);
    XCTAssertTrue([copy undoMoves:undoToCycleBoundary]);
    XCTAssertEqualObjects(copy.fen, initialFen);
    NSArray<SFMMove *> *branch = @[
        [[SFMMove alloc] initWithFrom:SQ_B1 to:SQ_C3],
        [[SFMMove alloc] initWithFrom:SQ_B8 to:SQ_C6],
        [[SFMMove alloc] initWithFrom:SQ_C3 to:SQ_B1],
        [[SFMMove alloc] initWithFrom:SQ_C6 to:SQ_B8]
    ];
    for (int ply = 0; ply < branchPlies; ply++) {
        XCTAssertTrue([copy doMove:branch[ply % branch.count] error:&error]);
        XCTAssertNil(error);
    }
    XCTAssertEqualObjects(copy.fen, initialFen);
    XCTAssertEqualObjects(position.fen, originalFen);
    XCTAssertTrue([copy undoMoves:branchPlies + (int)pliesBeforeCopy - undoToCycleBoundary]);
    XCTAssertEqualObjects(copy.fen, initialFen);
    XCTAssertFalse([copy undoMoves:1]);
    XCTAssertEqualObjects(position.fen, originalFen);
}

- (void)testMalformedSanTokensStopBeforeChangingThePosition
{
    for (NSString *token in @[@"hello", @"e4garbage", @"Nf3junk", @"Q", @"O-O-O-O"]) {
        SFMPosition *position = [[SFMPosition alloc] init];
        NSString *startingFen = position.fen;
        SFMNode *root = [[SFMNode alloc] init];
        NSError *error = nil;
        XCTAssertNil([position nodeForSan:token parentNode:root error:&error], @"%@", token);
        XCTAssertEqualObjects(error.domain, POSITION_ERROR_DOMAIN, @"%@", token);
        XCTAssertEqual(error.code, ILLEGAL_MOVE_CODE, @"%@", token);
        XCTAssertEqualObjects(error.userInfo[REJECTED_MOVE_KEY], token);
        XCTAssertNil(root.next);
        XCTAssertEqualObjects(position.fen, startingFen);
    }
}

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
