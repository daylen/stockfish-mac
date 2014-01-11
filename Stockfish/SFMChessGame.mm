//
//  SFMChessGame.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMChessGame.h"
#import "Constants.h"
#import "SFMChessMove.h"
#import "SFMParser.h"

#include "../Chess/move.h"
#include "../Chess/san.h"

@implementation SFMChessGame

#pragma mark - Init
- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2
{
    self = [super init];
    if (self) {
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitMonth fromDate:[NSDate new]];
        NSString *dateStr = [NSString stringWithFormat:@"%ld.%02ld.%02ld", (long)dateComponents.year, (long)dateComponents.month, (long)dateComponents.day];
        NSDictionary *defaultTags = @{@"Event": @"Casual Game",
                                      @"Site": @"Earth",
                                      @"Date": dateStr,
                                      @"Round": @"1",
                                      @"White": [p1 description],
                                      @"Black": [p2 description],
                                      @"Result": @"*"};
        self.tags = [defaultTags mutableCopy];
        self.moves = [NSMutableArray new];
        self.moveText = nil;
        // TODO init Position?
    }
    return self;
}

- (id)initWithTags:(NSMutableDictionary *)tags andMoves:(NSString *)moves
{
    self = [super init];
    if (self) {
        self.tags = [tags mutableCopy];
        self.moves = [NSMutableArray new];
        self.moveText = moves;
        //[self populateMovesFromMoveText]; // TODO remove
    }
    return self;
}

#pragma mark - Interaction
- (void)populateMovesFromMoveText
{
    [self convertToChessMoveObjects:[SFMParser parseMoves:self.moveText]];
    self.moveText = nil;
}

- (void)convertToChessMoveObjects:(NSArray *)movesAsText
{
    if (!movesAsText) {
        NSLog(@"Called convert but no moves to convert!");
        return;
    }
    
    // Convert standard algebraic notation
    startPosition = new Position;
    currPosition = new Position;
    
    // Some games start with custom FEN
    if ([self.tags objectForKey:@"FEN"] != nil) {
        startPosition->from_fen([self.tags[@"FEN"] UTF8String]);
    } else {
        startPosition->from_fen([FEN_START_POSITION UTF8String]);
    }
    currPosition->copy(*startPosition);
    
    for (NSString *moveToken in movesAsText) {
        Move m = move_from_san(*currPosition, [moveToken UTF8String]);
        if (m == MOVE_NONE) {
            NSException *e = [NSException exceptionWithName:@"ParseErrorException" reason:@"Could not parse move" userInfo:nil];
            @throw e;
        } else {
            UndoInfo u;
            currPosition->do_move(m, u);
            SFMChessMove *cm = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
            [self.moves addObject:cm];
        }
    }
    
    
}

#pragma mark - Export

- (NSString *)pgnString
{
    NSMutableString *str = [NSMutableString new];
    for (NSString *tagName in [self.tags allKeys]) {
        [str appendString:@"["];
        [str appendString:tagName];
        [str appendString:@" \""];
        [str appendString:self.tags[tagName]];
        [str appendString:@"\"]\n"];
    }
    
    if (self.moveText) {
        // Original move text was not modified
        [str appendString:self.moveText];
    } else {
        [str appendString:@"\n"];
        [str appendString:[self movesArrayAsString]];
        [str appendFormat:@"%@\n\n", self.tags[@"Result"]];
    }
    
    return str;
}

- (NSString *)movesArrayAsString
{
    Move line[800];
    int i = 0;
    
    for (SFMChessMove *move in self.moves) {
        line[i++] = move.move;
    }
    line[i] = MOVE_NONE;
    
    return [NSString stringWithUTF8String:line_to_san(*startPosition, line, 0, true, 1).c_str()];
}

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:@"%@ v. %@, %@, %ld tags", self.tags[@"White"], self.tags[@"Black"], self.tags[@"Result"], [self.tags count]];
    return s;
}

#pragma mark - Teardown
- (void)dealloc
{
    delete startPosition;
    delete currPosition;
}

@end
