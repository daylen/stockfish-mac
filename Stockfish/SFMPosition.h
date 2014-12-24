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
 Perform the move on the current position. Undo is NOT supported.
 
 @param move The move.
 @param error
 */
- (void)doMove:(SFMMove *)move error:(NSError * __autoreleasing *)error;

# pragma mark - Conversion

/*!
 Converts an array of move text in Standard Algebraic Notation into an array of SFMMove objects.
 The moves will be played with respect to (but will not modify) the current SFMPosition.
 
 @param san An array of strings in Standard Algebraic Notation. Example: ["e4", "e5", "Nf3", "Nc6"]
 @param error If the move cannot be parsed, this method will return nil and populate this error.
 @return An array of SFMMove objects
 */
- (NSArray* /* of SFMMove */)movesArrayForSan:(NSArray* /* of NSString */)san
                                        error:(NSError * __autoreleasing *)error;

/*!
 Converts an array of SFMMove objects into a string in Standard Algebraic Notation. The moves will
 be played with respect to (but will not modify) the current SFMPosition.
 
 @param movesArray An array of SFMMove objects
 @param html YES for an HTML string
 @param breakLines YES to insert line breaks after 80 characters
 @param startNum An integer specifying which number to start at
 @return A string in Standard Algebraic Notation. Example: "1. e4 e5 2. Nf3 Nc6"
 */
- (NSString *)sanForMovesArray:(NSArray* /* of SFMMove */)movesArray
                          html:(BOOL)html
                    breakLines:(BOOL)breakLines
                      startNum:(int)startNum;

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
- (NSArray* /* of NSNumber */)legalSquaresFromSquare:(SFMSquare)square;

- (BOOL)isPromotion:(SFMMove *)move;

@property (copy, nonatomic, readonly) NSString *fen;
@property (assign, readonly) BOOL isMate;
@property (assign, readonly) BOOL isImmediateDraw;
@property (assign, readonly) SFMColor sideToMove;
@property (assign, readonly) int numLegalMoves;

@end
