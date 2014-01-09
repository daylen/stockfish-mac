//
//  SFMChessGame.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMChessGame.h"

@implementation SFMChessGame

- (id)initWithWhite:(SFMPlayer *)p1 andBlack:(SFMPlayer *)p2
{
    self = [super init];
    if (self) {
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitMonth fromDate:[NSDate new]];
        NSString *dateStr = [NSString stringWithFormat:@"%ld.%02ld.%02ld", (long)dateComponents.year, (long)dateComponents.month, (long)dateComponents.day];
        NSDictionary *defaultTags = @{@"Event": @"Casual Game",
                                      @"Site": @"Earth",
                                      @"Date": dateStr,
                                      @"Round": @"1",
                                      @"White": [p1 description],
                                      @"Black": [p2 description],
                                      @"Result": @"*"};
        self.tags = [defaultTags mutableCopy];
        self.moves = [NSMutableArray new];
    }
    return self;
}

- (id)initWithTags:(NSMutableDictionary *)tags andMoves:(NSString *)moves
{
    self = [super init];
    if (self) {
        self.tags = [tags mutableCopy];
        NSLog(@"Creating a Game object with moves:");
        NSLog(moves);
    }
    return self;
}
- (NSString *)pgnString
{
    NSMutableString *str = [NSMutableString new];
    for (NSString *tagName in [self.tags allKeys]) {
        [str appendString:@"["];
        [str appendString:tagName];
        [str appendString:@" \""];
        [str appendString:self.tags[tagName]];
        [str appendString:@"\"]\n"];
    }
    return str;
}

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:@"%@ vs. %@, Result %@, %ld tags", self.tags[@"White"], self.tags[@"Black"], self.tags[@"Result"], [self.tags count]];
    return s;
}

@end
