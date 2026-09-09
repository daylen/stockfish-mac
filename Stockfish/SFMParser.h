//
//  SFMParser.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMNode.h"
#import "SFMPosition.h"

@interface SFMParser : NSObject

/*!
 Parses chess games from a PGN string.
 @param str The full PGN string as read from disk.
 @return A mutable array of SFMChessGame objects.
 */
+ (NSMutableArray * _Nullable)parseGamesFromString:(NSString * _Nonnull)str error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Parses the move text for a chess game from a given position and returns the top node.

 A move text that names an illegal move yields the moves before it rather than nothing,
 so that one bad move does not cost the whole game. Move text whose structure cannot be
 read at all is still rejected.

 @param moveText The move text
 @param position The position
 @param rejectedMove On return, the SAN token that stopped parsing, or nil if the whole
 move text was read. Pass NULL if not needed.
 @param error
 @return The top node of the tree, or nil if nothing could be read
 */
+ (SFMNode * _Nullable) parseMoveText:(NSString * _Nullable)moveText position:(SFMPosition * _Nonnull)position rejectedMove:(NSString * _Nullable __autoreleasing * _Nullable)rejectedMove error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 @return YES if the character is a lower or upper-case letter.
 */
+ (BOOL)isLetter:(char)c;

@end
