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
#import "SFMPGNFile.h"
#import "Constants.h"

@interface SFMChessGameTest : XCTestCase

@end

@implementation SFMChessGameTest

- (void)testCopiedVariationRetainsComments
{
    NSError *error = nil;
    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:@"1. e4 ({before d4} 1. d4 {after d4} d5) e5 *" error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    SFMChessGame *game = file.games.firstObject;
    SFMNode *variation = game.currentNode.next.variations.firstObject;
    XCTAssertNotNil(variation);
    XCTAssertEqualObjects(variation.commentBeforeMove, @"before d4");
    XCTAssertEqualObjects(variation.comment, @"after d4");
    NSMutableString *beforeMove = [variation.commentBeforeMove mutableCopy];
    NSMutableString *afterMove = [variation.comment mutableCopy];
    variation.commentBeforeMove = beforeMove;
    variation.comment = afterMove;
    SFMNode *copy = [variation copy];
    XCTAssertEqualObjects(copy.commentBeforeMove, @"before d4");
    XCTAssertEqualObjects(copy.comment, @"after d4");
    [beforeMove appendString:@" changed"];
    [afterMove appendString:@" changed"];
    XCTAssertEqualObjects(variation.commentBeforeMove, @"before d4");
    XCTAssertEqualObjects(copy.commentBeforeMove, @"before d4");
    XCTAssertEqualObjects(copy.comment, @"after d4");
}


- (void)testVariationLeadingCommentsSurviveSavingAndReopening
{
    NSArray<NSDictionary *> *cases = @[
        @{@"moves": @"{game introduction} 1. e4 {main} ({outer} {first} 1. d4 {after d4} ({inner} 1. c4 e5) d5) e5 *",
          @"variationPly": @1,
          @"fragments": @[@"{game introduction}", @"e4 {main}", @"( {outer first} 1. d4 {after d4}", @"( {inner} 1. c4 e5"]},
        @{@"moves": @"1. e4 e5 ({black alternative} 1... c5 {after c5}) 2. Nf3 *",
          @"variationPly": @2,
          @"fragments": @[@"( {black alternative} 1... c5 {after c5}"]},
        @{@"moves": @"1. e4 (;literal }\u2028;second line\n1. d4 d5) e5 *",
          @"variationPly": @1,
          @"fragments": @[@"( ;literal }\n;second line\n1. d4 d5"]}
    ];
    const NSUInteger roundTripCount = 3;
    for (NSDictionary *testCase in cases) {
        NSString *pgn = testCase[@"moves"];
        NSData *firstSave = nil;
        for (NSUInteger pass = 0; pass < roundTripCount; pass++) {
            NSError *error = nil;
            SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
            XCTAssertNotNil(file);
            XCTAssertNil(error);
            XCTAssertEqual(file.games.count, 1u);
            SFMChessGame *game = file.games.firstObject;
            XCTAssertFalse(game.hasUnreadMoveText);
            XCTAssertNil(game.rejectedMove);
            SFMNode *mainLineNode = game.currentNode;
            NSUInteger variationPly = [testCase[@"variationPly"] unsignedIntegerValue];
            for (NSUInteger ply = 0; ply < variationPly; ply++) {
                mainLineNode = mainLineNode.next;
            }
            XCTAssertEqual(mainLineNode.variations.count, 1u);
            SFMNode *variation = mainLineNode.variations.firstObject;
            XCTAssertNotNil(variation);
            XCTAssertEqual(variation.ply, variationPly);
            NSData *saved = file.data;
            NSString *serialized = [[NSString alloc] initWithData:saved encoding:NSUTF8StringEncoding];
            for (NSString *fragment in testCase[@"fragments"]) {
                XCTAssertTrue([serialized containsString:fragment], @"Missing %@ in %@ on pass %lu", fragment, serialized, (unsigned long)pass);
            }
            if (pass == 0) {
                firstSave = saved;
            } else {
                XCTAssertEqualObjects(saved, firstSave);
            }
            pgn = serialized;
        }
    }
}

- (void)testVariationLeadingCommentSurvivesRecoveredGameEditAndUndoRedo
{
    NSString *moves = @"1. e4 ({before d4} 1. d4 {after d4} d5) e5 2. Bh6 *";
    NSError *error = nil;
    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:moves error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    SFMChessGame *game = file.games.firstObject;
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.rejectedMove, @"Bh6");
    NSString *original = game.pgnString;
    [game goToEnd];
    [game.undoManager beginUndoGrouping];
    XCTAssertTrue([game doMove:[[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3] error:&error]);
    [game.undoManager endUndoGrouping];
    XCTAssertNil(error);
    XCTAssertFalse(game.hasUnreadMoveText);
    NSString *edited = game.pgnString;
    NSString *variation = @"( {before d4} 1. d4 {after d4} 1... d5";
    XCTAssertTrue([edited containsString:variation], @"%@", edited);
    [game.undoManager undo];
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.pgnString, original);
    [game.undoManager redo];
    XCTAssertFalse(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.pgnString, edited);
    SFMPGNFile *reopened = [[SFMPGNFile alloc] initWithString:edited error:&error];
    XCTAssertNotNil(reopened);
    XCTAssertNil(error);
    XCTAssertTrue([[[NSString alloc] initWithData:reopened.data encoding:NSUTF8StringEncoding] containsString:variation]);
    SFMChessGame *savedGame = reopened.games.firstObject;
    [savedGame goToEnd];
    XCTAssertEqualObjects(savedGame.uciString, @"position startpos moves e2e4 e7e5 g1f3 ");
}


- (void)assertLongGameRoundTripWithPlyCount:(NSUInteger)plyCount
{
    NSArray<NSString *> *sanCycle = @[@"Nf3", @"Nf6", @"Ng1", @"Ng8"];
    NSArray<NSString *> *uciCycle = @[@"g1f3", @"g8f6", @"f3g1", @"f6g8"];
    NSMutableString *moves = [NSMutableString new];
    NSMutableString *expectedUCI = [@"position startpos moves " mutableCopy];
    for (NSUInteger ply = 0; ply < plyCount; ply++) {
        [moves appendFormat:@"%@ ", sanCycle[ply % sanCycle.count]];
        [expectedUCI appendFormat:@"%@ ", uciCycle[ply % uciCycle.count]];
    }
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{@"Result": @"*"} moveText:moves];
    NSError *error = nil;
    XCTAssertTrue([game parseMoveText:&error]);
    XCTAssertNil(error);
    XCTAssertFalse(game.hasUnreadMoveText);
    [game goToEnd];
    XCTAssertEqual(game.currentNode.ply, plyCount);
    XCTAssertEqualObjects(game.uciString, expectedUCI);
    NSString *saved = game.pgnString;
    NSArray<SFMChessGame *> *reopened = [SFMParser parseGamesFromString:saved error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(reopened.count, 1u);
    SFMChessGame *restored = reopened.firstObject;
    XCTAssertFalse(restored.hasUnreadMoveText);
    [restored goToEnd];
    XCTAssertEqual(restored.currentNode.ply, plyCount);
    XCTAssertEqualObjects(restored.uciString, expectedUCI);
    XCTAssertEqualObjects(restored.pgnString, saved);
}

- (void)testGameRoundTripBeyondFormerHistoryLimit
{
    const NSUInteger firstPlyBeyondFormerHistoryLimit = 601;
    [self assertLongGameRoundTripWithPlyCount:firstPlyBeyondFormerHistoryLimit];
}

- (void)testGameRoundTripBeyondFormerSerializationLimit
{
    const NSUInteger pliesBeyondFormerSerializationLimit = 804;
    [self assertLongGameRoundTripWithPlyCount:pliesBeyondFormerSerializationLimit];
}

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

- (void)testSemicolonCommentExportPreservesEveryLineBoundary
{
    NSArray<NSString *> *lineSeparators = @[@"\n", @"\r", @"\r\n",
        [NSString stringWithFormat:@"%C", (unichar)0x0085], @"\u2028", @"\u2029"];
    for (NSString *separator in lineSeparators) {
        for (NSString *commentText in @[@"e5", @"notSAN"]) {
            NSString *moveText = [NSString stringWithFormat:@"1. e4 {%@%@%@%@tail} ;closing }\n;\ne5 *",
                                  separator, commentText, separator, separator];
            SFMChessGame *game = [[SFMChessGame alloc] initWithTags:@{@"Result": @"*"} moveText:moveText];
            NSError *error = nil;
            XCTAssertTrue([game parseMoveText:&error]);
            XCTAssertNil(error);
            XCTAssertFalse(game.hasUnreadMoveText);
            [game goToEnd];
            NSString *expectedMoves = @"position startpos moves e2e4 e7e5 ";
            XCTAssertEqualObjects(game.uciString, expectedMoves);

            NSString *exported = game.pgnString;
            NSArray<SFMChessGame *> *reopened = [SFMParser parseGamesFromString:exported error:&error];
            XCTAssertNil(error);
            XCTAssertEqual(reopened.count, 1u);
            SFMChessGame *roundTrip = reopened.firstObject;
            XCTAssertFalse(roundTrip.hasUnreadMoveText);
            XCTAssertNil(roundTrip.rejectedMove);
            [roundTrip goToEnd];
            XCTAssertEqualObjects(roundTrip.uciString, expectedMoves);
            [roundTrip goToBeginning];
            [roundTrip goForwardOneMove];
            NSString *expectedComment = [NSString stringWithFormat:@"\n%@\n\ntail\nclosing }\n", commentText];
            XCTAssertEqualObjects(roundTrip.currentNode.comment, expectedComment);
            XCTAssertEqualObjects(roundTrip.pgnString, exported);
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
