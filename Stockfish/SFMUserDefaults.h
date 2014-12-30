//
//  SFMUserDefaults.h
//  Stockfish
//
//  Created by Daylen Yang on 12/27/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@interface SFMUserDefaults : NSObject

+ (NSInteger)threadsValue;
+ (void)setThreadsValue:(NSInteger)val;

+ (NSInteger)hashValue;
+ (void)setHashValue:(NSInteger)val;

+ (NSInteger)contemptValue;
+ (void)setContemptValue:(NSInteger)val;

+ (NSInteger)skillLevelValue;
+ (void)setSkillLevelValue:(NSInteger)val;

+ (NSData *)sandboxBookmarkData;
+ (void)setSandboxBookmarkData:(NSData *)data;

@end
