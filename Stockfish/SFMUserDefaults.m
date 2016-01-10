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
#define UCI_BOARD_COLOR @"uci_board_color"
#define SANDBOX_BOOKMARK_DATA @"sandbox_bookmark_data"
#define ARROWS_ENABLED @"arrows_enabled"

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

+ (NSInteger)boardColorValue {
    if(![[NSUserDefaults standardUserDefaults] objectForKey:UCI_BOARD_COLOR]){
        [SFMUserDefaults setBoardColorValue:0x8bCEA3];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:UCI_BOARD_COLOR];
}

+ (void)setBoardColorValue:(NSInteger)val {
    [[NSUserDefaults standardUserDefaults] setInteger:val  forKey:UCI_BOARD_COLOR];
}

+ (NSData *)sandboxBookmarkData {
    return [[NSUserDefaults standardUserDefaults] dataForKey:SANDBOX_BOOKMARK_DATA];
}

+ (void)setSandboxBookmarkData:(NSData *)data {
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SANDBOX_BOOKMARK_DATA];
}

+ (BOOL)arrowsEnabled {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:ARROWS_ENABLED]) {
        [SFMUserDefaults setArrowsEnabled:YES];
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:ARROWS_ENABLED];
}

+ (void)setArrowsEnabled:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ARROWS_ENABLED];
}

@end
