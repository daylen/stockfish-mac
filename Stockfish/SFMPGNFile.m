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
- (instancetype)initWithString:(NSString *)str error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    if (self = [super init]) {
        _games = [SFMParser parseGamesFromString:str error:error];
        return _games == nil ? nil : self;
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

+ (SFMPGNFile * _Nullable)gameFromPgnOrFen:(NSString * _Nonnull)str error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    // If this is a FEN, paste it as a position into a new game.
    // Otherwise, treat it as a PGN.
    if ([SFMPosition isValidFen:str]) {
        SFMPGNFile *pgnFile = [[SFMPGNFile alloc] init];
        [pgnFile.games removeAllObjects];
        [pgnFile.games addObject:[[SFMChessGame alloc] initWithFen:str]];
        return pgnFile;
    }
    else {
        return [[SFMPGNFile alloc] initWithString:str error:error];
    }
}

@end
