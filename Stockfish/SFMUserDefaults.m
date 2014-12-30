//
//  SFMUserDefaults.m
//  Stockfish
//
//  Created by Daylen Yang on 12/27/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMUserDefaults.h"

#define UCI_THREADS @"uci_threads"
#define UCI_HASH @"uci_hash"
#define UCI_CONTEMPT @"uci_contempt"
#define UCI_SKILL_LEVEL @"uci_skill_level"
#define SANDBOX_BOOKMARK_DATA @"sandbox_bookmark_data"

@implementation SFMUserDefaults

+ (NSInteger)threadsValue {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:UCI_THREADS]) {
        [SFMUserDefaults setThreadsValue:1];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:UCI_THREADS];
}
+ (void)setThreadsValue:(NSInteger)val {
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:UCI_THREADS];
}
+ (NSInteger)hashValue {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:UCI_HASH]) {
        [SFMUserDefaults setHashValue:128];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:UCI_HASH];
}
+ (void)setHashValue:(NSInteger)val {
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:UCI_HASH];
}
+ (NSInteger)contemptValue {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:UCI_CONTEMPT]) {
        [SFMUserDefaults setContemptValue:0];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:UCI_CONTEMPT];
}
+ (void)setContemptValue:(NSInteger)val {
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:UCI_CONTEMPT];
}
+ (NSInteger)skillLevelValue {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:UCI_SKILL_LEVEL]) {
        [SFMUserDefaults setSkillLevelValue:20];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:UCI_SKILL_LEVEL];
}
+ (void)setSkillLevelValue:(NSInteger)val {
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:UCI_SKILL_LEVEL];
}
+ (NSData *)sandboxBookmarkData {
    return [[NSUserDefaults standardUserDefaults] dataForKey:SANDBOX_BOOKMARK_DATA];
}

+ (void)setSandboxBookmarkData:(NSData *)data {
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SANDBOX_BOOKMARK_DATA];
}

@end
