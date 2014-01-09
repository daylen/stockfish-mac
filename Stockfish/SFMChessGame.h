//
//  SFMChessGame.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFMPlayer.h"

@interface SFMChessGame : NSObject

#pragma mark - Properties
@property NSMutableDictionary *tags;
@property NSMutableArray *moves;

#pragma mark - Init
- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2;
- (id)initWithTags:(NSDictionary *)tags andMoves:(NSString *)moves; // Load a game

#pragma mark - Export
- (NSString *)pgnString; // PGN string for this game

@end
