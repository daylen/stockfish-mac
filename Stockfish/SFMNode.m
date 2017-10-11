//
//  SFMNode.m
//  Stockfish
//
//  Created by Adrian Buzea on 07/09/2017.
//  Copyright © 2017 Daylen Yang. All rights reserved.
//

#import "SFMNode.h"

@implementation SFMNode

- (instancetype)init{
    return [self initWithPly:0];
}

- (instancetype)initWithPly:(int)ply{
    return [self initWithMove:nil annotation:nil parent:nil topNode:true ply:ply];
}

- (instancetype)initWithMove:(SFMMove *)move andParent:(SFMNode *)parent{
    return [self initWithMove:move annotation:nil parent:parent topNode:NO ply:parent.ply + 1];
}

- (instancetype)initWithMove:(SFMMove *)move annotation:(NSString *)annotation andParent:(SFMNode *)parent{
    return [self initWithMove:move annotation:annotation parent:parent topNode:NO ply:parent.ply + 1];
}

- (instancetype)initWithMove:(SFMMove*)move annotation:(NSString *)annotation parent:(SFMNode*)parent topNode:(BOOL)topNode ply:(int)ply{
    if(self = [super init]){
        _nodeId = [[NSUUID alloc] init];
        _isTopNode = topNode;
        _move = move;
        _annotation = annotation;
        _parent = parent;
        _variations = [[NSMutableArray alloc] init];
        _ply = ply;
    }
    return self;
}

-(NSMutableArray *)reconstructMoves:(int)numberOfMoves{
    if(numberOfMoves < 1){
        return [[NSMutableArray alloc] init];
    }
    NSMutableArray *moves = [_parent reconstructMoves:numberOfMoves - 1];
    [moves addObject:_move];
    return moves;
}

- (NSMutableArray*)reconstructMovesFromBeginning{
    if ([_parent isTopNode]) {
        return [[NSMutableArray alloc] initWithObjects:_move, nil];
    }
    NSMutableArray *movesSoFar = [_parent reconstructMovesFromBeginning];
    [movesSoFar addObject:_move];
    return movesSoFar;
}

- (SFMNode *)existingVariationForMove:(SFMMove *)move{
    if([_move isEqual:move]){
        return self;
    }
    for(SFMNode *variation in _variations){
        if([variation.move isEqual:move]){
            return variation;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone{
    return [[SFMNode alloc] initWithMove:_move annotation:_annotation parent:_parent topNode:_isTopNode ply:_ply];
}

@end
