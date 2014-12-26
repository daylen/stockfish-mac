//
//  SFMUCIEngine.h
//  Stockfish
//
//  Created by Daylen Yang on 1/15/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@class SFMMove;
@class SFMUCIEngine;
@class SFMUCILine;
@class SFMChessGame;

@protocol SFMUCIEngineDelegate <NSObject>

- (void)uciEngine:(SFMUCIEngine *)engine didGetEngineName:(NSString *)name;
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewCurrentMove:(SFMMove *)move number:(NSInteger)moveNumber depth:(NSInteger)depth;
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewLine:(SFMUCILine *)line;

@end

@interface SFMUCIEngine : NSObject

@property (weak, nonatomic) id<SFMUCIEngineDelegate> delegate;

@property (nonatomic) BOOL isAnalyzing;
@property (nonatomic) SFMChessGame *gameToAnalyze;

@property (readonly, nonatomic) SFMUCILine *latestLine;

// TODO uci options

- (instancetype)initStockfish;

@end
