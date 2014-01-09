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
#import "../Chess/move.h"
#import "../Chess/san.h"

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
#warning parse moves and stuff
        
        
    }
    return self;
}

- (void)convertToChessMoveObjects:(NSArray *)movesAsText
{
    NSLog(@"Coverting SAN to SFMChessMove");
    
    // Convert standard algebraic notation
    startingPosition = new Position;
    currentPosition = new Position;
    
    // Some games start with custom FEN
    if ([self.tags objectForKey:@"FEN"] != nil) {
        NSLog(@"Custom FEN found: %@", self.tags[@"FEN"]);
        startingPosition->from_fen([self.tags[@"FEN"] UTF8String]);
    } else {
        startingPosition->from_fen([FEN_START_POSITION UTF8String]);
    }
    currentPosition->copy(*startingPosition);
    
    NSLog(@"Printing current position");
    currentPosition->print();
    
    
    for (NSString *moveToken in movesAsText) {
        NSLog(@"Processing %@", moveToken);
        Move m = move_from_san(*currentPosition, [moveToken UTF8String]);
        if (m == MOVE_NONE) {
            NSException *e = [NSException exceptionWithName:@"ParseErrorException" reason:@"Could not parse move" userInfo:nil];
            @throw e;
        } else {
            NSLog(@"Yay, move was not none");
            UndoInfo u;
            currentPosition->do_move(m, u);
            SFMChessMove *cm = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
            [self.moves addObject:cm];
        }
    }
    
    NSLog(@"Finished with that game.");
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
