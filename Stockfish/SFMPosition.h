//
//  SFMPosition.h
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPiece.h"
#import "SFMSquare.h"
#import "SFMColor.h"
#import "SFMNode.h"

@class SFMMove;

@interface SFMPosition : NSObject <NSCopying>

# pragma mark - Init
- (instancetype)init;
/*!
 Initialize a position with the given FEN. Assumes that the FEN is correct. It is recommended that
 you call +isValidFen: first.
 
 @param fen
 */
- (instancetype)initWithFen:(NSString *)fen;

/*!
 @return YES if the FEN is valid.
 */
+ (BOOL)isValidFen:(NSString *)fen;

# pragma mark - State modification
/*!
 Perform the move on the current position.
 
 @param move The move.
 @param error
 */
- (BOOL)doMove:(SFMMove *)move error:(NSError * __autoreleasing *)error;

/*!
 Perform a sequence of moves on the current position
 @param moves The moves
 @param error
 */
- (BOOL)doMoves:(NSArray *)moves error:(NSError *__autoreleasing *)error;

/*!
 Undoes the number of moves on the current position.
 @param numberOfMoves The number of moves to undo
 @return A boolean value representing the success value of the operation
 */
- (BOOL)undoMoves:(int)numberOfMoves;

# pragma mark - Conversion

/*!
 Converts a string in Standard Algebraic Notation into nodes which are then appended in order to the parent node as main moves and plays the moves with respect to the current position.
 @param san A string corresponding to moves in Standard Algebraic Notation
 @param parent The node to which the subtree will be appended
 @param error An error populated if the string contains invalid moves
 @return The node corresponding to the last move in the string
 */
- (SFMNode *)nodeForSan:(NSString *)san parentNode:(SFMNode *)parent error:(NSError * __autoreleasing *)error;

/*!
 Converts the subtree rooted in a node to an attributed string in Standard Algebraic Notation
 @param node The root node
 @param nodeId The id of the current node, found in the root node's subtree
 */
- (NSAttributedString *)moveTextForNode:(SFMNode *)node withCurrentNodeId:(NSUUID *)nodeId;

/*!
 Converts an array of SFMMove objects into a string in Standard Algebraic Notation. The moves will
 be played with respect to (but will not modify) the current SFMPosition.
 
 @param movesArray An array of SFMMove objects
 @param html YES for an HTML string
 @param breakLines YES to insert line breaks after 80 characters
 @param num If using HTML, this is the move that is bolded. If not using HTML, this is the number
 used to start numbering.
 @return A string in Standard Algebraic Notation. Example: "1. e4 e5 2. Nf3 Nc6"
 */
- (NSString *)sanForMovesArray:(NSArray* /* of SFMMove */)movesArray
                          html:(BOOL)html
                    breakLines:(BOOL)breakLines
                           num:(int)num;

/*!
 Converts an array of move text in UCI format into an array of SFMMove objects. The moves will
 be played with respect to (but will not modify) the current SFMPosition.
 
 @param uci An array of strings in UCI format. Example: ["e2e4", "e7e5"]
 @return An array of SFMMove objects
 */
- (NSArray* /* of SFMMove */)movesArrayForUci:(NSArray* /* of NSString */)uci;

/*!
 Converts an array of SFMMove objects into a string in UCI format.
 
 @param movesArray An array of SFMMove objects
 @return A string in UCI format. Example: "e2e4 e7e5"
 */
+ (NSString *)uciForMovesArray:(NSArray* /* of SFMMove */)movesArray;

# pragma mark - Getters
- (SFMPiece)pieceOnSquare:(SFMSquare)square;
/*!
 Get an array of legal destination squares for the given square.
 @param square
 @return An array of legal destination squares. The type of the objects is NSNumber, which wrap
 SFMSquare enums.
 */
- (NSArray* /* of NSNumber(SFMSquare) */)legalSquaresFromSquare:(SFMSquare)square;

- (BOOL)isPromotion:(SFMMove *)move;

@property (copy, nonatomic, readonly) NSString *fen;
@property (assign, readonly) BOOL isMate;
@property (assign, readonly) BOOL isImmediateDraw;
@property (assign, readonly) SFMColor sideToMove;
@property (assign, readonly) SFMSquare enPassantSquare;
@property (assign, readonly) int numLegalMoves;

@end
