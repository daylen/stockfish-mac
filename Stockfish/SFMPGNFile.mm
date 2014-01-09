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
        self.games = [NSMutableArray new];
        
        // Parse the games
        [self parseGamesFromString:str];
    }
    return self;
}
- (void)parseGamesFromString:(NSString *)str
{
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    NSMutableDictionary *tags;
    NSMutableString *moves;
    BOOL readingTags = NO;
    
    for (NSString *line in lines) {
        if ([line length] == 0) {
            continue;
        }
        if ([line characterAtIndex:0] == '[') {
            // This is a tag
            if (!readingTags) {
                readingTags = YES;
                if (tags && moves) {
                    [self addGameWithTags:[tags copy] andMoves:[moves copy]];
                }
                tags = [NSMutableDictionary new];
                moves = [NSMutableString new];
            }
            
            NSArray *tokens = [line componentsSeparatedByString:@"\""];
            NSString *tagName = [tokens[0] substringWithRange:NSMakeRange(1, [tokens[0] length] - 2)];
            tags[tagName] = tokens[1];
        } else {
            // This must be move text
            if (readingTags) {
                readingTags = NO;
            }
            
            [moves appendString:line];
        }
    }
    // Upon reaching the end of the file we need to add the last game
    [self addGameWithTags:[tags copy] andMoves:[moves copy]];
    
    NSLog(@"Parsed %lu games.", (unsigned long)[self.games count]);
    // NSLog(@"%@", [self.games description]);
}

- (void)addGameWithTags:(NSDictionary *)tags andMoves:(NSString *)moves
{
    assert([tags count] >= 7);
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:tags andMoves:moves];
    [self.games addObject:game];
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
