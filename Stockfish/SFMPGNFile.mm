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

@implementation SFMPGNFile

#pragma mark - Init
- (id)init
{
    self = [super init];
    if (self) {
        self.games = [NSMutableArray new];
        SFMPlayer *white = [SFMPlayer new];
        SFMPlayer *black = [SFMPlayer new];
        SFMChessGame *game = [[SFMChessGame alloc] initWithWhite:white andBlack:black];
        [self.games addObject:game];
    }
    return self;
}
- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        // TODO read the data
    }
    return self;
}

#pragma mark - Export
- (NSData *)data
{
    NSMutableString *concatString = [NSMutableString new];
    NSLog(@"Concatenating %lu games", (unsigned long)[self.games count]);
    for (SFMChessGame *game in self.games) {
        [concatString appendString:[game pgnString]];
    }
    return [concatString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
