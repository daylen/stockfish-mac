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

- (void)testParseMoveTextPlainMoves
{
    SFMPosition *initialPosition = [[SFMPosition alloc] init];
    NSString *moveText = @"1. e4\ne5 2.\rNf3 Nc6\r\n3. Bb5";
    NSError *err = nil;
    SFMNode *parsedNode = [SFMParser parseMoveText:moveText position:initialPosition error:&err];
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
    SFMNode *parsed = [SFMParser parseMoveText:moveText position:initialPosition error:&err];
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

@end
