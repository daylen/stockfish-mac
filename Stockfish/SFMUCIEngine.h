//
//  SFMUCIEngine.h
//  Stockfish
//
//  Created by Daylen Yang on 1/15/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMUCIEngine : NSObject

#pragma mark - Properties
@property NSString *engineName; // e.g. "Stockfish DD 64 SSE4.2"
@property NSMutableDictionary *currentInfo;
@property NSMutableArray *lineHistory;

#pragma mark - Init
- (id)initWithPathToEngine:(NSString *)path;
- (id)initStockfish; // Special init for Stockfish

#pragma mark - Using the engine
- (void)startInfiniteAnalysis;
- (void)stopSearch;

#pragma mark - Engine communication
- (void)sendCommandToEngine:(NSString *)string;

#pragma mark - Settings
- (void)setValue:(NSString *)value forOption:(NSString *)key;
- (void)setThreadsAndHashFromPrefs;

@end
