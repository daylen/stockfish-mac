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
 @return Every game in input order, including unreadable games, or nil if no game
 can be read. Games with unread move text retain it for saving without data loss.
 */
+ (NSMutableArray * _Nullable)parseGamesFromString:(NSString * _Nonnull)str error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Parses the move text for a chess game from a given position and returns the top node.

 An illegal move stops its line at the preceding legal move. Other variations and
 the main line remain readable. Move text with unreadable structure is rejected.

 @param moveText The move text
 @param position The position
 @param rejectedMove On success, the first rejected SAN token in input order, or nil
 if the whole move text was read. Pass NULL if not needed; recovery is unchanged.
 @param error
 @return The top node of the tree, or nil if nothing could be read
 */
+ (SFMNode * _Nullable) parseMoveText:(NSString * _Nullable)moveText position:(SFMPosition * _Nonnull)position rejectedMove:(NSString * _Nullable __autoreleasing * _Nullable)rejectedMove error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 @return YES if the character is a lower or upper-case letter.
 */
+ (BOOL)isLetter:(char)c;

@end
