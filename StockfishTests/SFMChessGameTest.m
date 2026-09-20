//
//  SFMChessGameTest.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFMChessGame.h"
#import "SFMParser.h"
#import "Constants.h"

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

- (void)testPgnStringAlwaysWritesGameTerminationMarker
{
    NSArray *tagsAndExpectedMarker = @[
                                       @[@{@"Event": @"A"}, @"*"],
                                       @[@{@"Event": @"A", @"Result": @""}, @"*"],
                                       @[@{@"Event": @"A", @"Result": @"1-0"}, @"1-0"],
                                       ];
    for (NSArray *testCase in tagsAndExpectedMarker) {
        NSDictionary *tags = testCase[0];
        NSString *expectedMarker = testCase[1];
        SFMChessGame *game = [[SFMChessGame alloc] initWithTags:tags moveText:@"1. e4 e5"];
        [game parseMoveText:nil];
        NSString *pgn = [game pgnString];
        XCTAssertEqual([pgn rangeOfString:@"(null)"].location, (NSUInteger)NSNotFound);
        XCTAssertTrue([pgn hasSuffix:[expectedMarker stringByAppendingString:@"\n\n"]],
                      @"Expected termination marker %@ for tags %@, got: %@", expectedMarker, tags, pgn);
    }
}

- (void)testUciStringOutput
{
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{} moveText:@"1. e4 e5"];
    [game parseMoveText:nil];
    [game goToEnd];
    NSString *uci = [game uciString];
    XCTAssertEqualObjects(uci, @"position startpos moves e2e4 e7e5 ");
}

- (void)testConsecutiveCommentsSurviveExportAndReopening
{
    NSArray<NSDictionary *> *cases = @[
        @{@"moves": @"1. e4 {[%clk 01:30:15]} {[%emt 00:00:44]} (1. d4 {first} {second} d5) e5 *",
          @"main": @"[%clk 01:30:15] [%emt 00:00:44]", @"variation": @"first second"},
        @{@"moves": @"1. e4 {first} {second} (1. d4 {[%clk 01:30:15]} {[%emt 00:00:44]} d5) e5 *",
          @"main": @"first second", @"variation": @"[%clk 01:30:15] [%emt 00:00:44]"},
        @{@"moves": @"1. e4 {} {second} {} (1. d4 {first} {} {third} d5) e5 *",
          @"main": @" second ", @"variation": @"first  third"},
    ];
    for (NSDictionary *testCase in cases) {
        SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{@"Result": @"*"}
                                                   moveText:testCase[@"moves"]];
        NSError *error = nil;
        XCTAssertTrue([game parseMoveText:&error], @"%@", testCase[@"moves"]);
        XCTAssertNil(error);
        XCTAssertFalse(game.hasUnreadMoveText);
        NSString *exported = game.pgnString;
        NSArray<SFMChessGame *> *reopened = [SFMParser parseGamesFromString:exported error:&error];
        XCTAssertNil(error);
        XCTAssertEqual(reopened.count, 1u);
        if (reopened.count != 1) {
            continue;
        }
        for (SFMChessGame *candidate in @[game, reopened.firstObject]) {
            XCTAssertFalse(candidate.hasUnreadMoveText);
            XCTAssertNil(candidate.rejectedMove);
            [candidate goToBeginning];
            [candidate goForwardOneMove];
            XCTAssertEqualObjects(candidate.currentNode.comment, testCase[@"main"]);
            XCTAssertEqual(candidate.currentNode.variations.count, 1u);
            SFMNode *variation = candidate.currentNode.variations.firstObject;
            XCTAssertEqualObjects(variation.comment, testCase[@"variation"]);
            XCTAssertNotNil(variation.next.move);
            [candidate goToEnd];
            XCTAssertEqualObjects(candidate.uciString, @"position startpos moves e2e4 e7e5 ");
            XCTAssertEqualObjects(candidate.pgnString, exported);
        }
    }
}

- (void)testConsecutiveCommentsSurviveEditingRecoveredGameAndUndoRedo
{
    NSString *moveText = @"1. e4 {[%clk 01:30:15]} {[%emt 00:00:44]} e5 2. Bh6 Nc6 *";
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{@"Result": @"*"} moveText:moveText];
    NSError *error = nil;
    XCTAssertTrue([game parseMoveText:&error]);
    XCTAssertNil(error);
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.rejectedMove, @"Bh6");
    NSString *originalPGN = game.pgnString;
    XCTAssertTrue([originalPGN containsString:moveText]);
    [game goToEnd];

    [game.undoManager beginUndoGrouping];
    XCTAssertTrue([game doMove:[[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3] error:&error]);
    [game.undoManager endUndoGrouping];
    XCTAssertNil(error);
    XCTAssertFalse(game.hasUnreadMoveText);
    XCTAssertNil(game.rejectedMove);
    NSString *editedPGN = game.pgnString;
    XCTAssertTrue([editedPGN containsString:@"{[%clk 01:30:15] [%emt 00:00:44]}"]);
    XCTAssertFalse([editedPGN containsString:@"Bh6"]);
    XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 g1f3 ");

    NSArray<SFMChessGame *> *reopened = [SFMParser parseGamesFromString:editedPGN error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(reopened.count, 1u);
    XCTAssertFalse(reopened.firstObject.hasUnreadMoveText);
    [reopened.firstObject goToEnd];
    XCTAssertEqualObjects(reopened.firstObject.uciString, game.uciString);
    XCTAssertEqualObjects(reopened.firstObject.pgnString, editedPGN);

    [game.undoManager undo];
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.rejectedMove, @"Bh6");
    XCTAssertEqualObjects(game.pgnString, originalPGN);
    XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 ");

    [game.undoManager redo];
    XCTAssertFalse(game.hasUnreadMoveText);
    XCTAssertNil(game.rejectedMove);
    XCTAssertEqualObjects(game.pgnString, editedPGN);
    XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 g1f3 ");
}


- (void)testUndoRestoresUnreadMoveTextAndRedoRestoresTheEdit
{
    NSString *moveText = @"1. e4 e5 2. Bh6 Nc6 *";
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{@"Result": @"*"} moveText:moveText];
    XCTAssertTrue([game parseMoveText:NULL]);
    XCTAssertTrue(game.hasUnreadMoveText);
    NSString *originalPGN = game.pgnString;
    [game goToEnd];

    [game.undoManager beginUndoGrouping];
    NSError *error = nil;
    XCTAssertTrue([game doMove:[[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3] error:&error]);
    [game.undoManager endUndoGrouping];
    XCTAssertNil(error);
    XCTAssertFalse(game.hasUnreadMoveText);
    XCTAssertNil(game.rejectedMove);
    NSString *editedPGN = game.pgnString;
    XCTAssertEqualObjects(game.moveTextString.string, @"1. e4 e5 2. Nf3 ");
    XCTAssertNotEqualObjects(editedPGN, originalPGN);

    [game.undoManager undo];
    XCTAssertEqualObjects(game.pgnString, originalPGN);
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.rejectedMove, @"Bh6");

    [game.undoManager redo];
    XCTAssertEqualObjects(game.pgnString, editedPGN);
    XCTAssertFalse(game.hasUnreadMoveText);
    XCTAssertNil(game.rejectedMove);

    [game.undoManager undo];
    XCTAssertEqualObjects(game.pgnString, originalPGN);
    XCTAssertEqualObjects(game.rejectedMove, @"Bh6");
}

- (void)testUnreadableGameRejectsMovesWithoutChangingItsState
{
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{@"Result": @"*"}
                                               moveText:@"1. e4 ({no moves here}) *"];
    NSError *parseError = nil;
    XCTAssertFalse([game parseMoveText:&parseError]);
    XCTAssertNotNil(parseError);
    XCTAssertNil(game.currentNode);
    XCTAssertTrue(game.hasUnreadMoveText);
    NSString *originalPGN = game.pgnString;
    NSString *originalFEN = game.position.fen;
    SFMMove *move = [[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4];

    NSError *moveError = nil;
    XCTAssertFalse([game doMove:move error:&moveError]);
    XCTAssertEqualObjects(moveError.domain, GAME_ERROR_DOMAIN);
    XCTAssertEqual(moveError.code, GAME_PARSE_ERROR_CODE);
    XCTAssertEqualObjects(game.position.fen, originalFEN);
    XCTAssertEqualObjects(game.pgnString, originalPGN);
    XCTAssertNil(game.currentNode);
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertFalse(game.undoManager.canUndo);
    XCTAssertFalse([game doMove:move error:NULL]);
    XCTAssertEqualObjects(game.pgnString, originalPGN);
}

@end
