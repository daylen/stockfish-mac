//
//  SFMUCILine.h
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@class SFMPosition;

@interface SFMUCILine : NSObject

@property (nonatomic) NSInteger depth;
@property (nonatomic) NSInteger selectiveDepth;
@property (nonatomic) NSInteger variationNum;
@property (nonatomic) NSInteger score;
@property (nonatomic) BOOL scoreIsMateDistance;
@property (nonatomic) BOOL scoreIsLowerBound;
@property (nonatomic) BOOL scoreIsUpperBound;
@property (nonatomic) NSString *nodes;
@property (nonatomic) NSString *nodesPerSecond;
@property (nonatomic) NSInteger tbHits;
@property (nonatomic) long long time; // milliseconds
@property (nonatomic) NSArray *moves;
@property (nonatomic) NSInteger wdlWin;
@property (nonatomic) NSInteger wdlDraw;
@property (nonatomic) NSInteger wdlLoss;
- (instancetype)initWithTokens:(NSArray *)tokens position:(SFMPosition *)position;

@end
