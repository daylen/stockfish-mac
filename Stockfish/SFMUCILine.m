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
        
        NSArray *wdl = [tokens sfm_objectsAfterObject:@"wdl" beforeObject:@"nodes"];
        if (wdl != nil) {
            _wdlWin = [[wdl objectAtIndex:0] integerValue];
            _wdlDraw = [[wdl objectAtIndex:1] integerValue];
            _wdlLoss = [[wdl objectAtIndex:2] integerValue];
        }
        _nodes = [tokens sfm_objectAfterObject:@"nodes"];
        _nodesPerSecond = [tokens sfm_objectAfterObject:@"nps"];
        _tbHits = [[tokens sfm_objectAfterObject:@"tbhits"] integerValue];
        _time = [[tokens sfm_objectAfterObject:@"time"] longLongValue];
        _moves = [position movesArrayForUci:[tokens sfm_objectsAfterObject:@"pv"]];
        
        NSAssert(_depth != 0, @"failed to init uci line");
    }
    return self;
}

- (NSString *)description {
    if (_wdlWin != 0 || _wdlDraw != 0 || _wdlLoss != 0) {
        return [NSString stringWithFormat:@"depth=%ld/%ld score=%ld nodes=%ld win=%ld draw=%ld loss=%ld time=%ld pv=%@", (long)self.depth, (long)self.selectiveDepth, (long)self.score, (long)self.wdlWin, (long)self.wdlDraw, (long)self.wdlLoss,  (long)self.nodes, (long)self.time, [self.moves description] ];
    }
    return [NSString stringWithFormat:@"depth=%ld/%ld score=%ld nodes=%ld time=%ld pv=%@", (long)self.depth, (long)self.selectiveDepth, (long)self.score, (long)self.nodes, (long)self.time, [self.moves description] ];
}

@end
