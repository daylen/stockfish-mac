//
//  SFMArrowMove.m
//  Stockfish
//
//  Created by Peter Ryszkiewicz on 8/28/21.
//  Copyright © 2021 Daylen Yang. All rights reserved.
//

#import "SFMArrowMove.h"

@implementation SFMArrowMove

- (instancetype)initWithMove:(SFMMove *)move weight:(CGFloat)weight
{
    self = [super init];
    if (self) {
        _move = move;
        _weight = weight;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[SFMArrowMove alloc]
            initWithMove:self.move
            weight:self.weight];
}

@end
