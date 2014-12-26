//
//  SFMMove.h
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPiece.h"
#import "SFMSquare.h"

@interface SFMMove : NSObject <NSCopying>

@property SFMSquare from;
@property SFMSquare to;
@property SFMPieceType promotion;

@property BOOL isPromotion;
@property BOOL isCastle;
@property BOOL isEp;

- (instancetype)initWithFrom:(SFMSquare)from to:(SFMSquare)to;
- (instancetype)initWithFrom:(SFMSquare)from to:(SFMSquare)to promotion:(SFMPieceType)promotion;

@end
