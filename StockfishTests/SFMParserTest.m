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
#import "SFMPGNFile.h"
#import "Constants.h"

@interface SFMParserTest : XCTestCase

@end

@implementation SFMParserTest

- (void)testLiteralBackslashesInTagValuesSurviveSavingAndReopening
{
    const NSUInteger roundTripCount = 2;
    for (NSString *value in @[@"C:\\Games\\club.pgn", @"O\\x27Kelly", @"C:\\",
                              @"quoted \\\"name\\\"", @"two\\\\slashes"]) {
        NSString *pgn = [NSString stringWithFormat:@"[Site \"%@\"]\n\n1. e4 {kept} e5 *\n", value];
        NSData *firstSave = nil;
        for (NSUInteger pass = 0; pass < roundTripCount; pass++) {
            NSError *error = nil;
            SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
            XCTAssertNotNil(file, @"%@ pass %lu", value, (unsigned long)pass);
            XCTAssertNil(error);
            XCTAssertEqual(file.games.count, 1u);
            SFMChessGame *game = file.games.firstObject;
            XCTAssertEqualObjects(game.tags[@"Site"], value);
            XCTAssertFalse(game.hasUnreadMoveText);
            XCTAssertNil(game.rejectedMove);
            XCTAssertEqualObjects(game.currentNode.next.comment, @"kept");
            [game goToEnd];
            XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 ");
            if (pass == 0) {
                firstSave = file.data;
            } else {
                XCTAssertEqualObjects(file.data, firstSave);
            }
            pgn = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
            NSString *expectedHeader = [NSString stringWithFormat:@"[Site \"%@\"]", value];
            XCTAssertTrue([pgn containsString:expectedHeader]);
            if (file == nil) {
                break;
            }
        }
    }
}

- (void)testPercentEscapesRecognizeEveryFoundationLineBoundary
{
    const NSUInteger roundTripCount = 2;
    for (NSString *lineEnding in @[@"\n", @"\r", @"\r\n", [NSString stringWithFormat:@"%C", (unichar)0x0085], @"\u2028", @"\u2029"]) {
        NSString *pgn = [@"[Event \"A\"]\n\n1. e4 {kept}\n% [Event \"ignored\"] { (\ne5 *\n"
                         stringByReplacingOccurrencesOfString:@"\n" withString:lineEnding];
        NSData *firstSave = nil;
        for (NSUInteger pass = 0; pass < roundTripCount; pass++) {
            NSError *error = nil;
            SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
            XCTAssertNotNil(file, @"separator U+%04X pass %lu", [lineEnding characterAtIndex:0], (unsigned long)pass);
            XCTAssertNil(error);
            XCTAssertEqual(file.games.count, 1u);
            SFMChessGame *game = file.games.firstObject;
            XCTAssertEqualObjects(game.tags[@"Event"], @"A");
            XCTAssertFalse(game.hasUnreadMoveText);
            XCTAssertNil(game.rejectedMove);
            XCTAssertEqualObjects(game.currentNode.next.comment, @"kept");
            [game goToEnd];
            XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 ");
            if (pass == 0) {
                firstSave = file.data;
            } else {
                XCTAssertEqualObjects(file.data, firstSave);
            }
            pgn = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
            if (file == nil) {
                break;
            }
        }
    }
}

- (void)testEscapeOnlyMoveTextIsReadableWithOrWithoutFinalNewline
{
    const NSUInteger roundTripCount = 2;
    for (NSString *moves in @[@"%", @"% note", @"% note\n", @"% one\n% two"]) {
        NSString *pgn = [@"[Event \"A\"]\n\n" stringByAppendingString:moves];
        NSString *expectedExport = @"[Event \"A\"]\n\n*\n\n";
        for (NSUInteger pass = 0; pass < roundTripCount; pass++) {
            NSError *error = nil;
            SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
            XCTAssertNotNil(file, @"%@ pass %lu", moves, (unsigned long)pass);
            XCTAssertNil(error);
            XCTAssertEqual(file.games.count, 1u);
            SFMChessGame *game = file.games.firstObject;
            XCTAssertEqualObjects(game.tags[@"Event"], @"A");
            XCTAssertFalse(game.hasUnreadMoveText);
            XCTAssertNotNil(game.currentNode);
            XCTAssertNil(game.currentNode.next);
            XCTAssertEqualObjects(game.uciString, @"position startpos");
            pgn = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
            XCTAssertEqualObjects(pgn, expectedExport);
            if (file == nil) {
                break;
            }
        }
    }
}

- (void)testLenientHeadersAndEmptyEscapesDoNotHideStructuralErrors
{
    for (NSString *pgn in @[@"[Site \"C:\\Games]\n\n1. e4 *",
                            @"[Site \"C:\\Games\" extra]\n\n1. e4 *",
                            @"[Event \"A\"]\n\n% ignored\n{unfinished",
                            @"[Event \"A\"]\n\n% ignored\n1. e4 () *",
                            @"[Event \"A\"]\n\n% ignored\n1. e4 (\n% note\n) *",
                            @"[Event \"A\"]\n\n(null)"]) {
        NSError *error = nil;
        SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
        XCTAssertNil(file, @"%@", pgn);
        XCTAssertEqualObjects(error.domain, GAME_ERROR_DOMAIN);
        XCTAssertEqual(error.code, GAME_PARSE_ERROR_CODE);
    }
    NSError *error = nil;
    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:@"[Event \"A\"]\n\n% ignored\n{kept}" error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    SFMChessGame *game = file.games.firstObject;
    XCTAssertFalse(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.currentNode.comment, @"kept");
    NSString *saved = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
    SFMPGNFile *reopened = [[SFMPGNFile alloc] initWithString:saved error:&error];
    XCTAssertNotNil(reopened);
    XCTAssertNil(error);
    XCTAssertEqualObjects([(SFMChessGame *)reopened.games.firstObject currentNode].comment, @"kept");
    XCTAssertEqualObjects(reopened.data, file.data);
}

- (void)testUnterminatedDelimitersReturnParseErrors
{
    for (NSString *moveText in @[@"{", @"(", @"1. e4 {", @"1. e4 (",
                                 @"1. e4 {unfinished", @"1. e4 (1. d4"]) {
        NSError *error = nil;
        SFMNode *root = nil;
        XCTAssertNoThrow(root = [SFMParser parseMoveText:moveText
                                               position:[[SFMPosition alloc] init]
                                           rejectedMove:NULL error:&error], @"%@", moveText);
        XCTAssertNil(root, @"%@", moveText);
        XCTAssertEqualObjects(error.domain, GAME_ERROR_DOMAIN, @"%@", moveText);
        XCTAssertEqual(error.code, GAME_PARSE_ERROR_CODE, @"%@", moveText);
    }
}

- (void)testUnterminatedGameSurvivesBesideReadableGame
{
    for (NSString *suffix in @[@"{", @"(", @"{unfinished", @"(1. d4"]) {
        NSString *brokenMoves = [@"1. e4 " stringByAppendingString:suffix];
        NSString *pgn = [NSString stringWithFormat:@"[Event \"Readable\"]\n\n1. d4 *\n\n"
                         "[Event \"Unterminated\"]\n\n%@", brokenMoves];
        NSError *error = nil;
        SFMPGNFile *file = nil;
        XCTAssertNoThrow(file = [[SFMPGNFile alloc] initWithString:pgn error:&error]);
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 2);
        SFMChessGame *broken = file.games.lastObject;
        XCTAssertTrue(broken.hasUnreadMoveText);
        XCTAssertNil(broken.currentNode);
        NSString *saved = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
        XCTAssertTrue([saved containsString:brokenMoves]);
        SFMPGNFile *reopened = nil;
        XCTAssertNoThrow(reopened = [[SFMPGNFile alloc] initWithString:saved error:&error]);
        XCTAssertNotNil(reopened);
        XCTAssertNil(error);
        XCTAssertEqual(reopened.games.count, 2);
        XCTAssertTrue([(SFMChessGame *)reopened.games.lastObject hasUnreadMoveText]);
        XCTAssertEqualObjects([(SFMChessGame *)reopened.games.firstObject tags][@"Event"], @"Readable");
    }
}

- (void)setUp
{
    [super setUp];
}

- (void)testHeaderTextInsideCommentsDoesNotSplitGames
{
    NSArray<NSString *> *comments = @[
        @"{ [%eval 0.3]\n[%clk 0:03:00]\n}",
        @"{first line\n[Event \"Inside comment\"]\nlast line}",
        @"{first\n} {second\n[Event \"Still inside comment\"]\n}",
        @"{literal { and ( inside\n[%clk 0:03:00]\n}",
    ];
    for (NSString *comment in comments) {
        NSString *pgn = [NSString stringWithFormat:@"[Event \"Actual game\"]\n\n1. e4 %@ e5 *\n", comment];
        NSError *error = nil;
        SFMPGNFile *file = nil;
        XCTAssertNoThrow(file = [[SFMPGNFile alloc] initWithString:pgn error:&error]);
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 1);
        SFMChessGame *game = file.games.firstObject;
        XCTAssertEqualObjects(game.tags[@"Event"], @"Actual game");
        XCTAssertFalse(game.hasUnreadMoveText);
        XCTAssertNotNil(game.currentNode.next.comment);
        NSString *parsedComment = game.currentNode.next.comment;
        [game goToEnd];
        XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 ");
        SFMPGNFile *reopened = nil;
        XCTAssertNoThrow(reopened = [[SFMPGNFile alloc] initWithString:game.pgnString error:&error]);
        XCTAssertNotNil(reopened);
        XCTAssertNil(error);
        XCTAssertEqual(reopened.games.count, 1);
        SFMChessGame *reopenedGame = reopened.games.firstObject;
        XCTAssertFalse(reopenedGame.hasUnreadMoveText);
        XCTAssertEqualObjects(reopenedGame.currentNode.next.comment, parsedComment);
        [reopenedGame goToEnd];
        XCTAssertEqualObjects(reopenedGame.uciString, game.uciString);
    }
}

- (void)testMalformedHeadersAreRejectedAndPreservedWithTheirNeighbour
{
    for (NSString *header in @[@"[Event]", @"[]", @"[Event \"unterminated]", @"[Event \"A\" extra]"]) {
        NSString *broken = [NSString stringWithFormat:@"%@\n\n1. e4 *\n\n", header];
        NSError *error = nil;
        SFMPGNFile *unreadable = nil;
        XCTAssertNoThrow(unreadable = [[SFMPGNFile alloc] initWithString:broken error:&error]);
        XCTAssertNil(unreadable);
        XCTAssertEqualObjects(error.domain, GAME_ERROR_DOMAIN);
        XCTAssertEqual(error.code, GAME_PARSE_ERROR_CODE);

        NSString *pgn = [broken stringByAppendingString:@"[Event \"Readable\"]\n\n1. d4 *\n"];
        error = nil;
        SFMPGNFile *file = nil;
        XCTAssertNoThrow(file = [[SFMPGNFile alloc] initWithString:pgn error:&error]);
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 2);
        XCTAssertTrue([(SFMChessGame *)file.games.firstObject hasUnreadMoveText]);
        XCTAssertEqualObjects([(SFMChessGame *)file.games.lastObject tags][@"Event"], @"Readable");
        NSString *saved = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
        XCTAssertTrue([saved containsString:broken]);
        SFMPGNFile *reopened = nil;
        XCTAssertNoThrow(reopened = [[SFMPGNFile alloc] initWithString:saved error:&error]);
        XCTAssertNotNil(reopened);
        XCTAssertNil(error);
        XCTAssertEqual(reopened.games.count, 2);
        XCTAssertTrue([(SFMChessGame *)reopened.games.firstObject hasUnreadMoveText]);
        XCTAssertTrue([[(SFMChessGame *)reopened.games.firstObject pgnString] containsString:broken]);
    }
}

- (void)testMalformedLaterHeadersPreserveReadableNeighboursAndFollowingTags
{
    NSString *firstGame = @"[Event \"First\"]\n\n1. d4 *\n\n";
    NSString *lastGame = @"[Event \"Last\"]\n\n1. c4 *\n";
    NSUInteger roundTripCount = 2;
    for (NSString *header in @[@"[Event]", @"[]", @"[Event \"unterminated]", @"[Event \"A\" extra]"]) {
        for (NSString *followingTag in @[@"", @"[Site \"Preserved\"]\n"]) {
            for (NSString *followingGame in @[@"", lastGame]) {
                NSString *pgn = [NSString stringWithFormat:@"%@%@\n%@\n1. e4 *\n\n%@",
                                 firstGame, header, followingTag, followingGame];
                NSUInteger expectedGameCount = followingGame.length == 0 ? 2 : 3;
                for (NSUInteger pass = 0; pass < roundTripCount; pass++) {
                    NSError *error = nil;
                    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
                    XCTAssertNotNil(file, @"%@ pass %lu", header, (unsigned long)pass);
                    XCTAssertNil(error);
                    XCTAssertEqual(file.games.count, expectedGameCount);
                    if (file.games.count != expectedGameCount) {
                        break;
                    }
                    SFMChessGame *first = file.games.firstObject;
                    XCTAssertFalse(first.hasUnreadMoveText);
                    XCTAssertEqualObjects(first.tags[@"Event"], @"First");
                    [first goToEnd];
                    XCTAssertEqualObjects(first.uciString, @"position startpos moves d2d4 ");

                    SFMChessGame *broken = file.games[1];
                    XCTAssertTrue(broken.hasUnreadMoveText);
                    XCTAssertNil(broken.currentNode);
                    XCTAssertTrue([broken.pgnString containsString:header]);
                    XCTAssertTrue([broken.pgnString containsString:@"1. e4 *"]);
                    if (followingTag.length > 0) {
                        XCTAssertEqualObjects(broken.tags[@"Site"], @"Preserved");
                    }
                    if (followingGame.length > 0) {
                        SFMChessGame *last = file.games.lastObject;
                        XCTAssertFalse(last.hasUnreadMoveText);
                        XCTAssertEqualObjects(last.tags[@"Event"], @"Last");
                        [last goToEnd];
                        XCTAssertEqualObjects(last.uciString, @"position startpos moves c2c4 ");
                    }
                    NSString *saved = [[NSString alloc] initWithData:file.data encoding:NSUTF8StringEncoding];
                    if (pass > 0) {
                        XCTAssertEqualObjects(saved, pgn);
                    }
                    pgn = saved;
                }
            }
        }
    }
}

- (void)testTaglessFragmentSurvivesBeforeTaggedGame
{
    NSString *pgn = @"1.e4 c6 2.d4 d5 3.e5 Bf5 4.h4\n\n[Event \"Next\"]\n\n1. d4 *\n";
    NSError *error = nil;
    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    XCTAssertEqual(file.games.count, 2);
    SFMChessGame *fragment = file.games.firstObject;
    XCTAssertFalse(fragment.hasUnreadMoveText);
    [fragment goToEnd];
    XCTAssertEqualObjects(fragment.uciString, @"position startpos moves e2e4 c7c6 d2d4 d7d5 e4e5 c8f5 h2h4 ");
    XCTAssertEqualObjects([(SFMChessGame *)file.games.lastObject tags][@"Event"], @"Next");
}

- (void)testAdjacentPgnTokensDoNotBecomePartOfSan
{
    NSArray<NSDictionary *> *cases = @[
        @{@"moves": @"1. e4$1 e5 *", @"uci": @"position startpos moves e2e4 e7e5 "},
        @{@"moves": @"1. e4*", @"uci": @"position startpos moves e2e4 "},
        @{@"moves": @"1. e4!?$1 e5*", @"uci": @"position startpos moves e2e4 e7e5 "},
    ];
    for (NSDictionary *testCase in cases) {
        NSError *error = nil;
        SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:testCase[@"moves"] error:&error];
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 1);
        SFMChessGame *game = file.games.firstObject;
        XCTAssertFalse(game.hasUnreadMoveText);
        XCTAssertNil(game.rejectedMove);
        [game goToEnd];
        XCTAssertEqualObjects(game.uciString, testCase[@"uci"]);
    }
}

- (void)testLineCommentsDoNotOpenBraceCommentsOrVariations
{
    for (NSString *lineEnding in @[@"\n", @"\r\n", @"\r"]) {
        NSString *pgn = [@"[Event \"First\"]\n\n1. e4 ; literal { ( and [Event]\n"
                         "% { ignored escape line\n"
                         "e5 *\n[Event \"Next\"]\n\n1. d4 *\n"
                         stringByReplacingOccurrencesOfString:@"\n" withString:lineEnding];
        NSError *error = nil;
        SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 2);
        SFMChessGame *game = file.games.firstObject;
        XCTAssertFalse(game.hasUnreadMoveText);
        XCTAssertEqualObjects(game.currentNode.next.comment, @" literal { ( and [Event]");
        [game goToEnd];
        XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 ");
        XCTAssertEqualObjects([(SFMChessGame *)file.games.lastObject tags][@"Event"], @"Next");
    }
}

- (void)testParseGamesFromString
{
    NSString *fakepgn = @"[tag \"whoa\"]\r\n[another \"yay\"]\n\n1. e4\re5 2. Nf3\n\n[tag \"whoa\"]\n\n1. e4\n";
    NSError *err = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:fakepgn error:&err];
    XCTAssertNotNil(games);
    XCTAssertNil(err);
    XCTAssertEqual([games count], 2, @"Wrong count");
    SFMChessGame *first = games[0];
    SFMChessGame *second = games[1];
    XCTAssertEqual([first.tags count], 2, @"Wrong count for game 1");
    XCTAssertEqual([second.tags count], 1, @"Wrong count for game 2");
}

- (void)testCommentDelimitersAndTrailingTextSurviveReopening
{
    NSArray<NSDictionary *> *cases = @[
        @{@"moves": @"1. e4 ; keep *", @"comment": @" keep *", @"uci": @"position startpos moves e2e4 "},
        @{@"moves": @"1. e4 ; keep  \n", @"comment": @" keep  ", @"uci": @"position startpos moves e2e4 "},
        @{@"moves": @"1. e4 ; text } more\ne5 *", @"comment": @" text } more", @"uci": @"position startpos moves e2e4 e7e5 "},
        @{@"moves": @"1. e4 {first\nsecond} ; third }\ne5 *", @"comment": @"first\nsecond\n third }", @"uci": @"position startpos moves e2e4 e7e5 "},
    ];
    for (NSDictionary *testCase in cases) {
        NSString *pgn = testCase[@"moves"];
        for (NSUInteger pass = 0; pass < 2; pass++) {
            NSError *error = nil;
            SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
            XCTAssertNotNil(file, @"%@ pass %lu", testCase, (unsigned long)pass);
            XCTAssertNil(error);
            XCTAssertEqual(file.games.count, 1);
            SFMChessGame *game = file.games.firstObject;
            XCTAssertFalse(game.hasUnreadMoveText);
            XCTAssertEqualObjects(game.currentNode.next.comment, testCase[@"comment"]);
            [game goToEnd];
            XCTAssertEqualObjects(game.uciString, testCase[@"uci"]);
            pgn = game.pgnString;
        }
    }
}

- (void)testPreambleDoesNotCreateAnExtraGame
{
    for (NSString *preamble in @[@"% generated by exporter\n", @"{file preamble}\n"]) {
        NSError *error = nil;
        NSString *pgn = [preamble stringByAppendingString:@"[Event \"A\"]\n\n1. e4 *\n"];
        SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 1);
        SFMChessGame *game = file.games.firstObject;
        XCTAssertEqualObjects(game.tags[@"Event"], @"A");
        XCTAssertFalse(game.hasUnreadMoveText);
        if ([preamble hasPrefix:@"{"]) {
            XCTAssertEqualObjects(game.currentNode.comment, @"file preamble");
            XCTAssertTrue([game.pgnString containsString:@"{file preamble}"]);
        }
        [game goToEnd];
        XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 ");
    }
}

- (void)testParseMoveTextPlainMoves
{
    SFMPosition *initialPosition = [[SFMPosition alloc] init];
    NSString *moveText = @"1. e4\ne5 2.\rNf3 Nc6\r\n3. Bb5";
    NSError *err = nil;
    SFMNode *parsedNode = [SFMParser parseMoveText:moveText position:initialPosition rejectedMove:NULL error:&err];
    XCTAssertNotNil(parsedNode);
    XCTAssertNil(err);
    NSArray *moves = @[
                       [[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4],
                       [[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5],
                       [[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3],
                       [[SFMMove alloc] initWithFrom:SQ_B8 to:SQ_C6],
                       [[SFMMove alloc] initWithFrom:SQ_F1 to:SQ_B5],
                       ];
    SFMNode *expectedNode = [[SFMNode alloc] init];
    expectedNode.next = [self buildNodeFromMoveArray:moves parent:expectedNode];
    [self verifyNodeSubtree:parsedNode against:expectedNode];
}

- (void)testParseMoveTextWithVariationAndCommentary
{
    SFMPosition *initialPosition = [[SFMPosition alloc] init];
    NSString *moveText = @"1.e4 (1.c4 c5 {Wow} 2.g3) e5 2.Nf3 Nc6 3. Bb5";
    
    NSError *err = nil;
    SFMNode *parsed = [SFMParser parseMoveText:moveText position:initialPosition rejectedMove:NULL error:&err];
    XCTAssertNotNil(parsed);
    XCTAssertNil(err);
    NSArray *mainMoves = @[
                       [[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4],
                       [[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5],
                       [[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3],
                       [[SFMMove alloc] initWithFrom:SQ_B8 to:SQ_C6],
                       [[SFMMove alloc] initWithFrom:SQ_F1 to:SQ_B5]
                       ];
    
    NSArray *variationMoves = @[
                           [[SFMMove alloc] initWithFrom:SQ_C2 to:SQ_C4],
                           [[SFMMove alloc] initWithFrom:SQ_C7 to:SQ_C5],
                           [[SFMMove alloc] initWithFrom:SQ_G2 to:SQ_G3]
                           ];
    SFMNode *expected = [[SFMNode alloc] init];
    expected.next = [self buildNodeFromMoveArray:mainMoves parent:expected];
    SFMNode *variation = [self buildNodeFromMoveArray:variationMoves parent:expected];
    [variation.next setComment:@"Wow"];
    [expected.next.variations addObject:variation];

    [self verifyNodeSubtree:parsed against:expected];
}

- (void)testExportedGameWithoutResultTagKeepsGameBoundary
{
    NSString *pgn = @"[Event \"A\"]\n[White \"First game\"]\n\n1/2-1/2\n\n[Event \"B\"]\n[White \"Second game\"]\n[Result \"*\"]\n\n1. e4 *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertNil(error);
    XCTAssertEqual([games count], 2, @"Fixture should load as two games");

    NSMutableString *exported = [NSMutableString new];
    for (SFMChessGame *game in games) {
        [exported appendString:[game pgnString]];
    }

    NSError *reimportError = nil;
    NSMutableArray *reimported = [SFMParser parseGamesFromString:exported error:&reimportError];
    XCTAssertNil(reimportError);
    XCTAssertEqual([reimported count], 2, @"Round trip lost a game");
    XCTAssertEqualObjects([(SFMChessGame *)reimported[0] tags][@"Event"], @"A");
    XCTAssertEqualObjects([(SFMChessGame *)reimported[1] tags][@"Event"], @"B");
}

- (void)testMovelessGameWithTerminationMarkerParses
{
    NSString *pgn = @"[Event \"A\"]\n\n*\n\n[Event \"B\"]\n\n1. e4 *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertNil(error);
    XCTAssertEqual([games count], 2);
    XCTAssertEqualObjects([[(SFMChessGame *)games[0] moveTextString] string], @"");
    XCTAssertEqualObjects([[(SFMChessGame *)games[1] moveTextString] string], @"1. e4 ");
}

- (void)testVariationWithoutMovesIsRejectedInsteadOfThrowing
{
    NSArray *malformedMoveTexts = @[@"1. e4 ( (null) ) *",
                                    @"1. e4 ({comment}(null)) *",
                                    @"1. e4 ({no moves here}) *"];
    for (NSString *moveText in malformedMoveTexts) {
        NSError *error = nil;
        __block SFMNode *parsed = nil;
        XCTAssertNoThrow(parsed = [SFMParser parseMoveText:moveText
                                                  position:[[SFMPosition alloc] init]
                                              rejectedMove:NULL
                                                     error:&error], @"Threw on %@", moveText);
        XCTAssertNil(parsed, @"Accepted %@", moveText);
        XCTAssertNotNil(error, @"No error reported for %@", moveText);
    }
}

- (SFMNode*)buildNodeFromMoveArray:(NSArray*)moves parent:(SFMNode*)parent
{
    SFMNode *head = [[SFMNode alloc] initWithMove:[moves firstObject] andParent:parent];
    SFMNode *current = head;
    for(SFMMove *move in [moves subarrayWithRange:NSMakeRange(1, [moves count] - 1)]){
        current.next = [[SFMNode alloc] initWithMove:move andParent:current];
        current = current.next;
    }
    return head;
}

-(void) verifyNodeSubtree:(SFMNode*)actual against:(SFMNode*)expected
{
    while(actual != nil && expected != nil){
        XCTAssertEqualObjects(actual.move, expected.move, @"Move mismatch.");
        XCTAssertEqualObjects(actual.comment, expected.comment, @"Comment mismatch.");
        for(int i = 0; i < [actual.variations count]; i++){
            [self verifyNodeSubtree:[actual.variations objectAtIndex:i] against:[expected.variations objectAtIndex:i]];
        }
        actual = actual.next;
        expected = expected.next;
    }
}


- (void)testIllegalMoveKeepsRemainingGamesInFile
{
    NSString *pgn = @"[Event \"Rejected\"]\n[White \"Bad\"]\n\n1. e4 e5 2. Kd3 *\n\n"
                     "[Event \"Complete\"]\n[White \"Good\"]\n\n1. e4 e5 2. Nf3 *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];

    XCTAssertNotNil(games, @"One illegal move discarded the whole file");
    XCTAssertNil(error);
    XCTAssertEqual([games count], 2, @"Lost a game to its neighbour's illegal move");
    XCTAssertEqualObjects([(SFMChessGame *)games[0] tags][@"Event"], @"Rejected");
    XCTAssertEqualObjects([(SFMChessGame *)games[1] tags][@"Event"], @"Complete");
}

- (void)testGameWithIllegalMoveKeepsTheMovesBeforeIt
{
    NSString *pgn = @"[Event \"Rejected\"]\n\n1. e4 e5 2. Kd3 *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertEqual([games count], 1);

    SFMChessGame *game = games[0];
    XCTAssertEqualObjects(game.rejectedMove, @"Kd3", @"Game not marked with the move that stopped it");

    NSString *moveText = [[game moveTextString] string];
    XCTAssertTrue([moveText containsString:@"e4"], @"Dropped the moves before the illegal one");
    XCTAssertTrue([moveText containsString:@"e5"], @"Dropped the moves before the illegal one");
    XCTAssertFalse([moveText containsString:@"Kd3"], @"Kept the illegal move");
}

- (void)testCompleteGameIsNotMarkedAsRejected
{
    NSString *pgn = @"[Event \"Complete\"]\n\n1. e4 e5 2. Nf3 *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertEqual([games count], 1);
    XCTAssertNil([(SFMChessGame *)games[0] rejectedMove], @"Marked a complete game as incomplete");
}

- (void)testFileWhereEveryGameFailsStructurallyIsRejected
{
    NSString *pgn = @"[Event \"A\"]\n\n1. e4 ({no moves here}) *\n\n"
                     "[Event \"B\"]\n\n1. e4 ({no moves here}) *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];

    XCTAssertNil(games, @"Accepted a file with nothing usable in it");
    XCTAssertNotNil(error, @"Reported no error for an unusable file");
}

- (void)testStructurallyBrokenGameDoesNotDiscardItsNeighbour
{
    NSString *pgn = @"[Event \"Broken\"]\n\n1. e4 ({no moves here}) *\n\n"
                     "[Event \"Complete\"]\n\n1. e4 e5 2. Nf3 *\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];

    XCTAssertNotNil(games);
    XCTAssertEqual([games count], 2, @"An unreadable game must stay in the file so a save cannot delete it");
    XCTAssertEqualObjects([(SFMChessGame *)games[0] tags][@"Event"], @"Broken");
    XCTAssertEqualObjects([(SFMChessGame *)games[1] tags][@"Event"], @"Complete");
    XCTAssertTrue([(SFMChessGame *)games[0] hasUnreadMoveText],
                  @"The unreadable game must be written back from its original text");
}


- (void)testExportingAnIncompleteGamePreservesItsOriginalMoveText
{
    NSString *moveText = @"1. e4 e5 2. Kd3 e6 3. Nf3 Nc6 1-0";
    NSString *pgn = [NSString stringWithFormat:@"[Event \"Rejected\"]\n[Result \"1-0\"]\n\n%@\n", moveText];
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertEqual([games count], 1);

    SFMChessGame *game = games[0];
    XCTAssertEqualObjects(game.rejectedMove, @"Kd3", @"Fixture no longer exercises a rejected move");

    NSString *exported = [game pgnString];
    XCTAssertTrue([exported containsString:@"Kd3"], @"Saving dropped the moves it could not read");
    XCTAssertTrue([exported containsString:@"Nc6"], @"Saving dropped the moves after the rejected one");

    NSError *reimportError = nil;
    NSMutableArray *reimported = [SFMParser parseGamesFromString:exported error:&reimportError];
    XCTAssertEqual([reimported count], 1, @"Export no longer reads back as one game");
    XCTAssertEqualObjects([(SFMChessGame *)reimported[0] rejectedMove], @"Kd3",
                          @"Round trip lost the truncation");
}


- (void)testIllegalMoveInsideAVariationMarksTheGameIncomplete
{
    NSString *pgn = @"[Event \"Var\"]\n[Result \"1-0\"]\n\n1. e4 (1. d4 d5 2. Kd3) e5 1-0\n";
    NSError *error = nil;
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertEqual([games count], 1);

    SFMChessGame *game = games[0];
    XCTAssertEqualObjects(game.rejectedMove, @"Kd3",
                          @"An illegal move inside a variation left the game looking complete");
    XCTAssertTrue([[game pgnString] containsString:@"Kd3"],
                  @"Saving dropped the variation move that could not be read");
}

- (void)testEditingAnIncompleteGameSavesTheEdit
{
    NSString *pgn = @"[Event \"Edit\"]\n[Result \"*\"]\n\n1. e4 e5 2. Kd3 *\n";
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:nil];
    SFMChessGame *game = games[0];
    XCTAssertEqualObjects(game.rejectedMove, @"Kd3", @"Fixture no longer exercises a rejected move");

    NSError *moveError = nil;
    XCTAssertTrue([game doMove:[[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3] error:&moveError]);
    XCTAssertNil(moveError);

    XCTAssertTrue([[game pgnString] containsString:@"Nf3"],
                  @"Saving an edited game discarded the move just played");
}

- (void)testAnUnreadableGameSurvivesASaveOfItsNeighbour
{
    NSString *pgn = @"[Event \"Broken\"]\n\n1. e4 ({no moves here}) *\n\n"
                     "[Event \"Fine\"]\n\n1. e4 e5 *\n";
    NSMutableArray *games = [SFMParser parseGamesFromString:pgn error:nil];

    NSMutableString *exported = [NSMutableString new];
    for (SFMChessGame *game in games) {
        [exported appendString:[game pgnString]];
    }

    XCTAssertTrue([exported containsString:@"Broken"],
                  @"Saving deleted a game that could not be read");
}


- (void)testSavingUnreadMoveTextPreservesSemicolonCommentBoundaries
{
    NSString *moveText = @"1. e4 e5 2. Kd3 ; rejected move\n3. Nf3 Nc6 *";
    NSString *pgn = [NSString stringWithFormat:@"[Event \"Unread\"]\n\n%@\n", moveText];
    NSError *error = nil;
    NSArray<SFMChessGame *> *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(games.count, 1);
    SFMChessGame *game = games.firstObject;
    XCTAssertTrue(game.hasUnreadMoveText);
    XCTAssertEqualObjects(game.rejectedMove, @"Kd3");
    XCTAssertTrue([game.pgnString containsString:moveText]);

    NSArray<SFMChessGame *> *reopened = [SFMParser parseGamesFromString:game.pgnString error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(reopened.count, 1);
    XCTAssertTrue([reopened.firstObject.pgnString containsString:moveText]);
}

- (void)testIllegalFirstVariationMoveRecoversWithOptionalRejectedMoveOutput
{
    NSArray<NSString *> *moveTexts = @[@"1. e4 (1. Kd3) e5 *",
                                       @"1. e4 (1. d4 (1. Kd3) d5) e5 *"];
    for (NSString *moveText in moveTexts) {
        for (NSNumber *requestsRejectedMove in @[@YES, @NO]) {
            NSError *error = nil;
            NSString *rejectedMove = nil;
            SFMNode *root = [SFMParser parseMoveText:moveText
                                          position:[[SFMPosition alloc] init]
                                      rejectedMove:requestsRejectedMove.boolValue ? &rejectedMove : NULL
                                             error:&error];
            XCTAssertNotNil(root, @"%@ output=%@", moveText, requestsRejectedMove);
            XCTAssertNil(error);
            XCTAssertEqualObjects(root.next.move, [[SFMMove alloc] initWithFrom:SQ_E2 to:SQ_E4]);
            XCTAssertEqualObjects(root.next.next.move, [[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5]);
            XCTAssertNil(root.next.next.next);
            if (requestsRejectedMove.boolValue) {
                XCTAssertEqualObjects(rejectedMove, @"Kd3");
            }
        }
    }
}

- (void)testEarlierRejectedMoveDoesNotMakeAnEmptyVariationReadable
{
    NSString *moveText = @"1. e4 (1. d4 d5 2. Kd3) ({comment}) e5 *";
    for (NSNumber *requestsRejectedMove in @[@YES, @NO]) {
        NSError *error = nil;
        NSString *rejectedMove = nil;
        SFMNode *root = [SFMParser parseMoveText:moveText
                                      position:[[SFMPosition alloc] init]
                                  rejectedMove:requestsRejectedMove.boolValue ? &rejectedMove : NULL
                                         error:&error];
        XCTAssertNil(root);
        XCTAssertNotNil(error);
    }
}

- (void)testFirstRejectedMoveSurvivesLaterVariationAndMainlineFailures
{
    NSArray<NSString *> *moveTexts = @[
        @"1. e4 (1. d4 d5 2. Kd3) (1. c4 c5 2. Ke3) (1. Nf3 d5) e5 *",
        @"1. e4 (1. d4 d5 2. Kd3) (1. c4 c5 2. Ke3) (1. Nf3 d5) e5 2. Ke3 *"
    ];
    for (NSString *moveText in moveTexts) {
        NSError *error = nil;
        NSString *rejectedMove = nil;
        SFMNode *root = [SFMParser parseMoveText:moveText
                                      position:[[SFMPosition alloc] init]
                                  rejectedMove:&rejectedMove
                                         error:&error];
        XCTAssertNotNil(root);
        XCTAssertNil(error);
        XCTAssertEqualObjects(rejectedMove, @"Kd3");
        XCTAssertEqualObjects(root.next.next.move, [[SFMMove alloc] initWithFrom:SQ_E7 to:SQ_E5]);
        XCTAssertNil(root.next.next.next);
        XCTAssertEqual(root.next.variations.count, 3);
        SFMNode *lastVariation = root.next.variations.lastObject;
        XCTAssertEqualObjects(lastVariation.move, [[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3]);
        XCTAssertEqualObjects(lastVariation.next.move, [[SFMMove alloc] initWithFrom:SQ_D7 to:SQ_D5]);
    }
}

- (void)testUnreadMoveTextPreservesCRLFAndBlankLinesBetweenGames
{
    NSString *moveText = @"1. e4 e5 2. Kd3 ; rejected move\r\n\r\n3. Nf3 Nc6 *\r\n\r\n";
    NSString *pgn = [NSString stringWithFormat:@"[Event \"Unread\"]\r\n\r\n%@[Event \"Next\"]\r\n\r\n1. d4 *\r\n", moveText];
    NSError *error = nil;
    NSArray<SFMChessGame *> *games = [SFMParser parseGamesFromString:pgn error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(games.count, 2);
    XCTAssertEqualObjects(games.firstObject.rejectedMove, @"Kd3");
    XCTAssertTrue([games.firstObject.pgnString containsString:moveText]);
    NSMutableString *exported = [NSMutableString new];
    for (SFMChessGame *game in games) {
        [exported appendString:game.pgnString];
    }
    NSArray<SFMChessGame *> *reopened = [SFMParser parseGamesFromString:exported error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(reopened.count, 2);
    XCTAssertEqualObjects(reopened.lastObject.tags[@"Event"], @"Next");
    XCTAssertTrue([reopened.firstObject.pgnString containsString:moveText]);
}

- (void)testSavingUnreadPGNIsIdempotentAcrossLineEndings
{
    for (NSString *lineEnding in @[@"\n", @"\r\n"]) {
        NSString *moveText = [@"1. e4 e5 2. Kd3 ; rejected move\n\n3. Nf3 Nc6 *\n\n"
            stringByReplacingOccurrencesOfString:@"\n" withString:lineEnding];
        NSString *pgn = [NSString stringWithFormat:@"[Event \"Unread\"]%@%@%@[Event \"Next\"]%@%@1. d4 *%@",
                         lineEnding, lineEnding, moveText, lineEnding, lineEnding, lineEnding];
        NSError *error = nil;
        SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:pgn error:&error];
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        XCTAssertEqual(file.games.count, 2);
        NSData *firstSave = file.data;
        NSString *firstExport = [[NSString alloc] initWithData:firstSave encoding:NSUTF8StringEncoding];
        XCTAssertTrue([firstExport containsString:moveText]);
        SFMPGNFile *reopened = [[SFMPGNFile alloc] initWithString:firstExport error:&error];
        XCTAssertNotNil(reopened);
        XCTAssertNil(error);
        XCTAssertEqual(reopened.games.count, 2);
        XCTAssertEqualObjects(reopened.data, firstSave);
    }
}

@end
