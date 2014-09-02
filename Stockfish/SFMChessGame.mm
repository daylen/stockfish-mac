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

@interface SFMChessGame()

@property (readwrite) int currentMoveIndex;

@end

@implementation SFMChessGame

#pragma mark - Init and Set Up
- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2
{
    self = [super init];
    if (self) {
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear|kCFCalendarUnitDay|kCFCalendarUnitMonth fromDate:[NSDate new]];
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
        self.currentMoveIndex = 0;
        
        self.startPosition = new Position;
        self.currPosition = new Position;
        self.startPosition->from_fen([FEN_START_POSITION UTF8String]);
        self.currPosition->from_fen([FEN_START_POSITION UTF8String]);
        assert(self.startPosition->is_ok());
        assert(self.currPosition->is_ok());
    }
    return self;
}

- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2 andFen:(NSString *)fen
{
    self = [self initWithWhite:p1 andBlack:p2];
    if (self) {
        self.tags[@"FEN"] = fen;
        self.startPosition = new Position;
        self.currPosition = new Position;
        self.startPosition->from_fen([fen UTF8String]);
        self.currPosition->from_fen([fen UTF8String]);
        assert(self.startPosition->is_ok());
        assert(self.currPosition->is_ok());
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
        self.currentMoveIndex = 0;
    }
    return self;
}

- (void)populateMovesFromMoveText
{
    [self convertToChessMoveObjects:[SFMParser parseMoves:self.moveText]];
    self.moveText = nil;
}

- (void)convertToChessMoveObjects:(NSArray *)movesAsText
{
    if (!movesAsText || [movesAsText count] == 0) {
        return;
    }
    
    // Convert standard algebraic notation
    self.startPosition = new Position;
    self.currPosition = new Position;
    
    // Some games start with custom FEN
    if ([self.tags objectForKey:@"FEN"] != nil) {
        self.startPosition->from_fen([self.tags[@"FEN"] UTF8String]);
    } else {
        self.startPosition->from_fen([FEN_START_POSITION UTF8String]);
    }
    self.currPosition->copy(*self.startPosition);
    
    for (NSString *moveToken in movesAsText) {
        Move m = move_from_san(*self.currPosition, [moveToken UTF8String]);
        if (m == MOVE_NONE) {
            NSString *reason = [NSString stringWithFormat:@"The move %@ is invalid.", moveToken];
            @throw [NSException exceptionWithName:@"BadMoveException" reason:reason userInfo:nil];
        } else {
            UndoInfo u;
            //NSLog(@"Calling do_move from SFMChessGame convertToChessMoveObjects");
            self.currPosition->do_move(m, u);
            SFMChessMove *cm = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
            [self.moves addObject:cm];
        }
    }
    
    // Set current position back to starting position
    self.currPosition->copy(*self.startPosition);
    
    
}

#pragma mark - Doing Moves

- (Move)doMoveFrom:(Square)fromSquare to:(Square)toSquare promotion:(PieceType)desiredPieceType
{
    assert(self.currPosition->is_ok());
    assert(square_is_ok(fromSquare));
    assert(square_is_ok(toSquare));
    assert(desiredPieceType == NO_PIECE_TYPE ||
           (desiredPieceType >= KNIGHT && desiredPieceType <= QUEEN));
    
    // Find the matching move
    Move mlist[32], move = MOVE_NONE;
    int n, i, matches;
    n = self.currPosition->moves_from(fromSquare, mlist);
    for (i = 0, matches = 0; i < n; i++)
        if (move_to(mlist[i]) == toSquare && move_promotion(mlist[i]) == desiredPieceType) {
            move = mlist[i];
            matches++;
        }
    assert(matches == 1);
    
    // Update position
    UndoInfo u;
    //NSLog(@"Calling do_move from SFMChessGame doMoveFrom:to:promotion:");
    self.currPosition->do_move(move, u);
    
    // Update move list
    SFMChessMove *chessMove = [[SFMChessMove alloc] initWithMove:move undoInfo:u];
    if (![self atEnd]) {
        // We are not at the end of the game. We don't want to mess with
        // multiple variations, so we just remove all moves at the end of the move list.
        [self.moves removeObjectsInRange:
         NSMakeRange(self.currentMoveIndex, [self.moves count] - self.currentMoveIndex)];
    }
    [self.moves addObject:chessMove];
    self.currentMoveIndex++;
    
    assert([self atEnd]);
    return move;
    
}
- (void)doMoveFrom:(Square)fromSquare to:(Square)toSquare
{
    [self doMoveFrom:fromSquare to:toSquare promotion:NO_PIECE_TYPE];
}
- (void)doMove:(Chess::Move)move
{
    [self doMoveFrom:move_from(move) to:move_to(move) promotion:move_promotion(move)];
}

#pragma mark - Navigation

- (BOOL)atBeginning
{
    return self.currentMoveIndex == 0;
}
- (BOOL)atEnd
{
    return self.currentMoveIndex == [self.moves count];
}
- (void)goBackOneMove
{
    if (![self atBeginning]) {
        self.currentMoveIndex--;
        SFMChessMove *chessMove = self.moves[self.currentMoveIndex];
        Move move = chessMove.move;
        UndoInfo undoInfo = chessMove.undoInfo;
        self.currPosition->undo_move(move, undoInfo);
    }
}
- (void)goForwardOneMove
{
    if (![self atEnd]) {
        SFMChessMove *chessMove = self.moves[self.currentMoveIndex];
        Move move = chessMove.move;
        UndoInfo undoInfo = chessMove.undoInfo;
        //NSLog(@"Calling do_move from SFMChessGame goForwardOneMove");
        self.currPosition->do_move(move, undoInfo);
        self.currentMoveIndex++;
    }
}
- (void)goToBeginning
{
    while (![self atBeginning]) {
        [self goBackOneMove];
    }
}
- (void)goToEnd
{
    while (![self atEnd]) {
        [self goForwardOneMove];
    }
}
- (void)goToPly:(int)ply
{
    [self goToBeginning];
    for (int i = 0; i < ply && ![self atEnd]; i++) {
        [self goForwardOneMove];
    }
}
- (void)undoLastMove
{
    if ([self.moves lastObject]) {
        [self goToEnd];
        SFMChessMove *chessMove = [self.moves lastObject];
        Move move = chessMove.move;
        UndoInfo undoInfo = chessMove.undoInfo;
        self.currPosition->undo_move(move, undoInfo);
        self.currentMoveIndex = (int)[self.moves count] - 1;
        [self.moves removeLastObject];
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
        [str appendString:[self movesArrayAsString:YES]];
        [str appendFormat:@"%@\n\n", self.tags[@"Result"]];
    }
    
    return str;
}

- (NSString *)movesArrayAsString:(BOOL)breakLines
{
    Move line[800];
    int i = 0;
    
    for (SFMChessMove *move in self.moves) {
        line[i++] = move.move;
    }
    line[i] = MOVE_NONE;
    
    assert(self.startPosition->is_ok());
    
    return [NSString stringWithUTF8String:line_to_san(*self.startPosition, line, 0, breakLines, 1).c_str()];
}

- (NSString *)movesArrayAsHtmlString
{
    if ([self.moves count] == 0) {
        return @"Make a move!";
    }
    
    Move line[800];
    int i = 0;
    
    for (SFMChessMove *move in self.moves) {
        line[i++] = move.move;
    }
    line[i] = MOVE_NONE;
    
    assert(self.startPosition->is_ok());
    
    return [NSString stringWithUTF8String:line_to_html(*self.startPosition, line, self.currentMoveIndex, false).c_str()];

}

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:@"%@ v. %@, %@, %ld tags", self.tags[@"White"], self.tags[@"Black"], self.tags[@"Result"], [self.tags count]];
    return s;
}

- (NSString *)uciPositionString
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@"position "];
    if ([self.tags objectForKey:@"FEN"] == nil) {
        [str appendString:@"startpos"];
    } else {
        [str appendFormat:@"fen %@", self.tags[@"FEN"]];
    }
    if (![self atBeginning]) {
        Move m;
        [str appendString:@" moves"];
        for (int i = 0; i < self.currentMoveIndex; i++) {
            m = ((SFMChessMove *) self.moves[i]).move;
            [str appendFormat:@" %s", move_to_string(m).c_str()];
        }
    }
    return [str copy];
}

#pragma mark - Teardown
- (void)dealloc
{
    //NSLog(@"Deallocating this SFMChessGame");
    delete self.startPosition;
    delete self.currPosition;
}

@end
