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
 Parses the move text for a chess game from a given position and returns the top node
 @param moveText The move text
 @param position The position
 @return The top node of the tree
 */
+ (SFMNode * _Nullable) parseMoveText:(NSString * _Nullable)moveText position:(SFMPosition * _Nonnull)position error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 @return YES if the character is a lower or upper-case letter.
 */
+ (BOOL)isLetter:(char)c;

@end
