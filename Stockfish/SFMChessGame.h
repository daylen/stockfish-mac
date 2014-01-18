//
//  SFMChessGame.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFMPlayer.h"

#include "../Chess/position.h"

using namespace Chess;

@interface SFMChessGame : NSObject

#pragma mark - Properties
@property NSMutableDictionary *tags;
@property NSMutableArray *moves; // Lazy
@property NSString *moveText;
@property Position *startPosition;
@property Position *currPosition;
@property (readonly) int currentMoveIndex;

#pragma mark - Init and Set Up
- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2;
- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2 andFen:(NSString *)fen;
- (id)initWithTags:(NSDictionary *)tags andMoves:(NSString *)moves; // Saves the tags and move text
- (void)populateMovesFromMoveText; // Actually load the game

#pragma mark - Doing Moves
- (Move)doMoveFrom:(Square)fromSquare to:(Square)toSquare promotion:(PieceType)desiredPieceType;
- (void)doMoveFrom:(Square)fromSquare to:(Square)toSquare;

#pragma mark - Navigation
- (BOOL)atBeginning;
- (BOOL)atEnd;
- (void)goBackOneMove;
- (void)goForwardOneMove;
- (void)goToBeginning;
- (void)goToEnd;
- (void)goToPly:(int)ply;

#pragma mark - Export
- (NSString *)pgnString; // PGN string for this game
- (NSString *)movesArrayAsString; // Just the move text
- (NSString *)uciPositionString;

@end
