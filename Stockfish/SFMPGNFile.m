//
//  SFMPGNFile.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPGNFile.h"
#import "SFMChessGame.h"
#import "SFMParser.h"

@implementation SFMPGNFile

#pragma mark - Init
- (instancetype)init
{
    if (self = [super init]) {
        _games = [NSMutableArray new];
        [_games addObject:[[SFMChessGame alloc] init]];
    }
    return self;
}
- (instancetype)initWithString:(NSString *)str
{
    if (self = [super init]) {
        _games = [SFMParser parseGamesFromString:str];
    }
    return self;
}


#pragma mark - Export
- (NSData *)data
{
    NSMutableString *concatString = [NSMutableString new];
    for (SFMChessGame *game in self.games) {
        [concatString appendString:[game pgnString]];
    }
    return [concatString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
