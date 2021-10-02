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
- (void)uciEngine:(SFMUCIEngine *)engine didGetInfoString:(NSString *)string;
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewCurrentMove:(SFMMove *)move
           number:(NSInteger)moveNumber depth:(NSInteger)depth;
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewLine:(NSDictionary *)lines;

@optional
- (void)uciEngine:(SFMUCIEngine *)engine didGetOptions:(NSArray* /* of SFMUCIOption */)options;

@end

@interface SFMUCIEngine : NSObject

@property (weak, nonatomic) id<SFMUCIEngineDelegate> delegate;

@property (nonatomic) BOOL isAnalyzing;
@property (nonatomic) SFMChessGame *gameToAnalyze;
@property (nonatomic) NSUInteger multipv;
@property (nonatomic) BOOL useNnue;
@property (nonatomic) BOOL showWdl;
@property (readonly, nonatomic) NSDictionary /* <NSNumber, SFMUCILine> */ *lines;
@property (readonly, nonatomic) NSString *nnueInfo;

- (instancetype)initStockfish;
- (instancetype)initOptionsProbe;

+ (int32_t)instancesAnalyzing;

@end
