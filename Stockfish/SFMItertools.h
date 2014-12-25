//
//  SFMItertools.h
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@interface SFMItertools : NSObject

+ (NSArray* /* of NSArray */)permutations:(NSArray *)arr length:(int)r;

+ (NSArray* /* of NSArray */)combinations:(NSArray *)arr length:(int)r;

@end
