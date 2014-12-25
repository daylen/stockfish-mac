//
//  SFMMove.m
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMMove.h"
#import "SFMSquareUtils.h"

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

- (id)copyWithZone:(NSZone *)zone {
    SFMMove *new = [[SFMMove alloc] init];
    new.from = self.from;
    new.to = self.to;
    new.promotion = self.promotion;
    new.isPromotion = self.isPromotion;
    new.isCastle = self.isCastle;
    new.isEp = self.isEp;
    return new;
}

- (NSUInteger)hash {
    return self.from ^ self.to ^ self.promotion;
}

- (BOOL)isEqual:(id)object {
    SFMMove *m2 = object;
    return self.from == m2.from && self.to == m2.to && self.promotion == m2.promotion && self.isPromotion == m2.isPromotion && self.isCastle == m2.isCastle && self.isEp == m2.isEp;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@->%@", [SFMSquareUtils description:self.from], [SFMSquareUtils description:self.to]];
}



@end
