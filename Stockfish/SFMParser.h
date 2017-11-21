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
+ (NSMutableArray *)parseGamesFromString:(NSString *)str;

/*!
 Parses the move text for a chess game from a given position and returns the top node
 @param moveText The move text
 @param position The position
 @return The top node of the tree
 */
+ (SFMNode*) parseMoveText:(NSString*)moveText position:(SFMPosition*)position;

/*!
 @return YES if the character is a lower or upper-case letter.
 */
+ (BOOL)isLetter:(char)c;

@end
