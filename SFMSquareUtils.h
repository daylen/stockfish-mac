//
//  SFMSquareUtils.h
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMSquare.h"

@interface SFMSquareUtils : NSObject

+ (NSString *)description:(SFMSquare)sq;

+ (double)distanceFrom:(SFMSquare)from to:(SFMSquare)to;

@end
