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
        startingPosition = new Position;
        currentPosition = new Position;
        startingPosition->from_fen([FEN_START_POSITION UTF8String]);
        currentPosition->copy(*startingPosition);
    }
    return self;
}

- (id)initWithTags:(NSMutableDictionary *)tags andMoves:(NSString *)moves
{
    self = [super init];
    if (self) {
        self.tags = [tags mutableCopy];
        self.moves = [NSMutableArray new];
        NSArray *tokenizedMoves = [SFMParser parseMoves:moves];
        [self convertToChessMoveObjects:tokenizedMoves];
        
    }
    return self;
}

- (void)convertToChessMoveObjects:(NSArray *)movesAsText
{
    NSLog(@"Processing Game: %@", [self description]);
    
    // Convert standard algebraic notation
    startingPosition = new Position;
    currentPosition = new Position;
    
    // Some games start with custom FEN
    if ([self.tags objectForKey:@"FEN"] != nil) {
        startingPosition->from_fen([self.tags[@"FEN"] UTF8String]);
    } else {
        startingPosition->from_fen([FEN_START_POSITION UTF8String]);
    }
    currentPosition->copy(*startingPosition);
    
    for (NSString *moveToken in movesAsText) {
        Move m = move_from_san(*currentPosition, [moveToken UTF8String]);
        if (m == MOVE_NONE) {
            NSException *e = [NSException exceptionWithName:@"ParseErrorException" reason:@"Could not parse move" userInfo:nil];
            @throw e;
        } else {
            UndoInfo u;
            currentPosition->do_move(m, u);
            SFMChessMove *cm = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
            [self.moves addObject:cm];
        }
    }
    NSLog(@"Finished processing game.");
    NSLog(@"%lu moves", (unsigned long)[self.moves count]);
    
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
    return str;
}

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:@"%@ vs. %@, Result %@, %ld tags", self.tags[@"White"], self.tags[@"Black"], self.tags[@"Result"], [self.tags count]];
    return s;
}

@end
