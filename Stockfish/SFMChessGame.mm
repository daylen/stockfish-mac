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

- (id)initWithTags:(NSArray *)tags andMoves:(NSArray *)moves
{
    self = [super init];
    if (self) {
        self.tags = [tags mutableCopy];
        self.moves = [moves mutableCopy];
    }
    return self;
}
- (NSString *)pgnString
{
    return [self.tags description];
}

@end
