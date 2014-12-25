//
//  SFMSquareUtils.m
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMSquareUtils.h"

@implementation SFMSquareUtils

+ (NSString *)description:(SFMSquare)sq {
    int letter = sq % 8;
    int number = sq / 8;
    return [NSString stringWithFormat:@"%c%d", 65 + letter, number + 1];
}

+ (double)distanceFrom:(SFMSquare)from to:(SFMSquare)to {
    int x1 = from % 8;
    int x2 = to % 8;
    int y1 = from / 8;
    int y2 = to / 8;
    
    int dx = x1 - x2;
    int dy = y1 - y2;
    
    return sqrt(pow(dx, 2) + pow(dy, 2));
}

@end
