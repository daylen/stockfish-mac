//
//  SFMFormatter.h
//  Stockfish
//
//  Created by Daylen Yang on 1/17/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@interface SFMFormatter : NSObject

+ (NSString *)scoreAsText:(int)score
                   isMate:(BOOL)isMate
            isWhiteToMove:(BOOL)whiteToMove
             isLowerBound:(BOOL)isLowerBound
             isUpperBound:(BOOL)isUpperBound;

+ (NSString *)nodesAsText:(NSString *)nodes;

+ (NSString *)millisecondsToClock:(unsigned long long)milliseconds; // 0:00:00

@end
