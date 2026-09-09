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

@property (weak, nonatomic) id<SFMChessGameDelegate> delegate;

@property (nonatomic) NSDictionary *tags;
@property (nonatomic, readonly) SFMPosition *position;
@property (readonly) SFMNode *currentNode;
@property (nonatomic) NSUndoManager *undoManager;

@property (nonatomic, readonly) BOOL isInInitialState;

/*!
 The SAN token that stopped the move text being read, or nil if the whole game was read
 or if nothing in it could be read at all.
 */
@property (nonatomic, readonly) NSString *rejectedMove;

/*!
 YES while this game holds move text that was never fully read, so the text on disk says
 more than the move tree does. Such a game is written back out as it came in, and stops
 being one the moment it is edited: from then on the tree is what the game means.
 */
@property (nonatomic, readonly) BOOL hasUnreadMoveText;

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
- (BOOL)parseMoveText:(NSError * __autoreleasing *)error;

#pragma mark - State Modification

/*!
 @param move
 @param error
 @return YES if the move was done.
 */
- (BOOL)doMove:(SFMMove *)move error:(NSError *__autoreleasing *)error;

/*!
 Set the result of the game.
 @param result
 */
- (void)setResult:(NSString *)result;

/*!
 Removes the subtree from the node and sets the current node as the removed node's parent
 */
- (void)removeSubtreeFromNode:(SFMNode *)node;

/*!
 Calls removeSubtreeFromNode and updates the state of the game
 */
- (void)removeSubtreeFromNodeAndUpdateState:(SFMNode *)node;

#pragma mark - Navigation
@property (nonatomic, readonly) BOOL atBeginning;
@property (nonatomic, readonly) BOOL atEnd;
- (void)goBackOneMove;
- (void)goForwardOneMove;
- (void)goToBeginning;
- (void)goToEnd;
- (void)goToNode:(SFMNode*)node;
- (void)goToNodeId:(NSUUID*)nodeId;

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
- (NSAttributedString *)moveTextString;

/*!
 @return The moves in the game in UCI format.
 */
@property (nonatomic, readonly, copy) NSString *uciString;

@end
