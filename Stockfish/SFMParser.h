//
//  SFMParser.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMParser : NSObject

/*!
 Parses chess games from a PGN string.
 @param str The full PGN string as read from disk.
 @return A mutable array of SFMChessGame objects.
 */
+ (NSMutableArray *)parseGamesFromString:(NSString *)str;

/*!
 Tokenizes move text.
 @param moves A string such as: "1. e4 e5 2. Nf3 Nc6" and so on
 @return A tokenized array such as: "["e4", "e5", "Nf3", "Nc6"] and so on
 */
+ (NSArray *)tokenizeMoveText:(NSString *)moveText;

@end
