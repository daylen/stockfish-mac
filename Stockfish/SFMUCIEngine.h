//
//  SFMUCIEngine.h
//  Stockfish
//
//  Created by Daylen Yang on 1/15/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMUCIEngine : NSObject

#pragma mark - Init
- (id)initWithPathToEngine:(NSString *)path;
- (id)initStockfish; // Special init for Stockfish

#pragma mark - Using the engine
- (NSString *)engineName;

#pragma mark - Settings
- (NSDictionary *)engineOptions;
- (void)setValue:(NSString *)value forOption:(NSString *)key;
- (void)automaticallySetThreadsAndHash;


@end
