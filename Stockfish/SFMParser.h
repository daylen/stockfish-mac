//
//  SFMParser.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMParser : NSObject

+ (NSMutableArray *)parseGamesFromString:(NSString *)str;
+ (NSArray *)parseMoves:(NSString *)moves;
+ (BOOL)isLetter:(char)c;

@end
