//
//  SFMMove.m
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMMove.h"

@implementation SFMMove

- (instancetype)initWithFrom:(SFMSquare)from to:(SFMSquare)to {
    self = [super init];
    if (self) {
        self.from = from;
        self.to = to;
        self.isPromotion = NO;
        self.isCastle = NO;
        self.isEp = NO;
    }
    return self;
}

- (instancetype)initWithFrom:(SFMSquare)from to:(SFMSquare)to promotion:(SFMPieceType)promotion {
    self = [super init];
    if (self) {
        self.from = from;
        self.to = to;
        self.promotion = promotion;
        self.isPromotion = YES;
        self.isCastle = NO;
        self.isEp = NO;
    }
    return self;
}

@end
