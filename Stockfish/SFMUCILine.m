//
//  SFMUCILine.m
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMUCILine.h"
#import "NSArray+ArrayUtils.h"
#import "SFMPosition.h"

@implementation SFMUCILine

- (instancetype)initWithTokens:(NSArray *)tokens position:(SFMPosition *)position {
    if (self = [super init]) {
        _depth = [[tokens sfm_objectAfterObject:@"depth"] integerValue];
        _selectiveDepth = [[tokens sfm_objectAfterObject:@"seldepth"] integerValue];
        _variationNum = [[tokens sfm_objectAfterObject:@"multipv"] integerValue];
        if ([tokens containsObject:@"cp"]) {
            _score = [[tokens sfm_objectAfterObject:@"cp"] integerValue];
            _scoreIsMateDistance = NO;
        } else {
            _score = [[tokens sfm_objectAfterObject:@"mate"] integerValue];
            _scoreIsMateDistance = YES;
        }
        _scoreIsLowerBound = [tokens containsObject:@"lowerbound"];
        _scoreIsUpperBound = [tokens containsObject:@"upperbound"];
        _nodes = [tokens sfm_objectAfterObject:@"nodes"];
        _nodesPerSecond = [tokens sfm_objectAfterObject:@"nps"];
        _tbHits = [[tokens sfm_objectAfterObject:@"tbhits"] integerValue];
        _time = [[tokens sfm_objectAfterObject:@"time"] longLongValue];
        _moves = [position movesArrayForUci:[tokens sfm_objectsAfterObject:@"pv"]];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"depth=%ld/%ld score=%ld nodes=%ld time=%ld pv=%@", (long)self.depth, (long)self.selectiveDepth, (long)self.score, (long)self.nodes, (long)self.time, [self.moves description] ];
}

@end
