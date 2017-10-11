//
//  SFMNode.h
//  Stockfish
//
//  Created by Adrian Buzea on 07/09/2017.
//  Copyright © 2017 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFMMove.h"

/*!
 SFMNode represents a node of a chess game tree
 */
@interface SFMNode : NSObject <NSCopying>

#pragma mark - Properties

/*!
 The ply of the node
 &*/
@property (readonly) int ply;

/*!
 Uniquely identifies a node
 */
@property (readonly) NSUUID* nodeId;

/*!
 Is the node at the top of the tree
 */
@property (readonly) BOOL isTopNode;

/*!
 The chess move that gets from the parent node to this one
 */
@property (readonly) SFMMove* move;

/*!
 An optional move annotation like !!, !?, ??
 */
@property (readonly) NSString* annotation;

/*!
 The parent node
 */
@property SFMNode* parent;

/*!
 A comment for the move
 */
@property NSString* comment;

/*!
 Pointer to the main variation
 */
@property SFMNode* next;

/*!
 Other possible variations from this node
 */
@property (readonly) NSMutableArray* /* of SFMNode */ variations;

#pragma mark - Init

/*!
 Creates a root node
 */
- (instancetype)init;

/*!
 Creates a root node with the specified ply
 */
- (instancetype)initWithPly:(int)ply;

/*!
 Creates a node which is the result of making a move in another node
 */
- (instancetype)initWithMove:(SFMMove*)move andParent:(SFMNode*)parent;

/*!
 Creates a node which is the result of making a move in another node
 */
- (instancetype)initWithMove:(SFMMove*)move annotation:(NSString *)annotation andParent:(SFMNode*)parent;

/*!
 Returns an array containing the last number of moves 
 */
- (NSMutableArray *)reconstructMoves:(int)numberOfMoves;

/*!
 Reconstructs the move sequence from the start of the game to this point
 */
- (NSMutableArray*)reconstructMovesFromBeginning;

/*!
 Returns a pointer to an existing variation for this node, or nil if one is not found
 */
- (SFMNode *)existingVariationForMove:(SFMMove *)move;

@end
