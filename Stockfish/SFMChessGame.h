//
//  SFMChessGame.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPosition.h"
#import "SFMMove.h"

@class SFMChessGame;

@protocol SFMChessGameDelegate <NSObject>

- (void)chessGameStateDidChange:(SFMChessGame *)chessGame;

@end

/*!
 SFMChessGame contains PGN metadata and move history for a game.
 */
@interface SFMChessGame : NSObject <NSCopying>

#pragma mark - Properties

@property (nonatomic) id<SFMChessGameDelegate> delegate;

@property (nonatomic) NSDictionary *tags;
@property (nonatomic, readonly) SFMPosition *position;
@property (readonly) NSUInteger currentMoveIndex;
@property (nonatomic) NSUndoManager *undoManager;

#pragma mark - Init

/*!
 Creates a game from the starting position.
 */
- (instancetype)init;

/*!
 Creates a game from the specified FEN.
 @param fen
 */
- (instancetype)initWithFen:(NSString *)fen;

/*!
 Creates a game from the given PGN tags and move text.
 */
- (instancetype)initWithTags:(NSDictionary *)tags moveText:(NSString *)moveText;

/*!
 If the game was created using move text, call this before calling any other methods.
 @param error
 */
- (void)parseMoveText:(NSError * __autoreleasing *)error;

#pragma mark - State Modification

/*!
 @param move
 @param error
 @return YES if the move was done.
 */
- (BOOL)doMove:(SFMMove *)move error:(NSError *__autoreleasing *)error;

/*!
 @param moves Array of moves.
 @param error
 @return YES if the moves were done.
 */
- (BOOL)doMoves:(NSArray *)moves error:(NSError *__autoreleasing *)error;

/*!
 @param index
 @return An array of deleted moves.
 */
- (NSArray *)deleteMovesFromPly:(NSNumber *)index;

/*!
 Set the result of the game.
 @param result
 */
- (void)setResult:(NSString *)result;

#pragma mark - Navigation
@property (nonatomic, readonly) BOOL atBeginning;
@property (nonatomic, readonly) BOOL atEnd;
- (void)goBackOneMove;
- (void)goForwardOneMove;
- (void)goToBeginning;
- (void)goToEnd;
- (void)goToPly:(NSUInteger)ply;

#pragma mark - Export
/*!
 @return A string containing the PGN tags and move text.
 */
@property (nonatomic, readonly, copy) NSString *pgnString;

/*!
 @param html YES to return HTML.
 @param num
 @return A string containing the move text.
 */
- (NSString *)moveTextString:(BOOL)html num:(int)num;

/*!
 @return The moves in the game in UCI format.
 */
@property (nonatomic, readonly, copy) NSString *uciString;

@end
