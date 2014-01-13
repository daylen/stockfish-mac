//
//  SFMPGNFile.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPGNFile.h"
#import "SFMChessGame.h"
#import "SFMPlayer.h"
#import "SFMParser.h"

@implementation SFMPGNFile

#pragma mark - Init
- (id)init
{
    self = [super init];
    if (self) {
        self.games = [NSMutableArray new];
        
        // Create a new game
        SFMPlayer *white = [SFMPlayer new];
        SFMPlayer *black = [SFMPlayer new];
        SFMChessGame *game = [[SFMChessGame alloc] initWithWhite:white andBlack:black];
        [self.games addObject:game];
    }
    return self;
}
- (id)initWithString:(NSString *)str
{
    self = [super init];
    if (self) {
        self.games = [SFMParser parseGamesFromString:str];
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
