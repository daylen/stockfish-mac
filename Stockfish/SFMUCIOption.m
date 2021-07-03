//
//  SFMUCIOption.m
//  Stockfish
//
//  Created by Daylen Yang on 12/27/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMUCIOption.h"
#import "NSString+StringUtils.h"

@implementation SFMUCIOption

- (instancetype)initWithName:(NSString *)name default:(NSString *)defaultValue min:(NSString *)min max:(NSString *)max {
    if (self = [super init]) {
        self.name = name;
        
        if ([name isEqualToString:@"Threads"]) {
            self.type = SFMUCIOptionTypeThreads;
        } else if ([name isEqualToString:@"Hash"]) {
            self.type = SFMUCIOptionTypeHash;
        } else if ([[name lowercaseString] sfm_containsString:@"path"]) {
            self.type = SFMUCIOptionTypePath;
        } else {
            self.type = SFMUCIOptionTypeNumber;
        }
        
        if (defaultValue)
            self.defaultValue = [defaultValue integerValue];
        if (min)
            self.minValue = [min integerValue];
        if (max)
            self.maxValue = [max integerValue];
    }
    return self;
}

+ (BOOL)isOptionSupported:(NSString *)name {
    NSArray *supported = @[@"Threads", @"Hash", @"MultiPV", @"Skill Level", @"SyzygyPath"];
    return [supported containsObject:name];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %ld %ld %ld", self.name, self.defaultValue, self.minValue, self.maxValue];
}

@end
