//
//  SFMParser.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMParser.h"
#import "SFMChessGame.h"

@implementation SFMParser

+ (NSMutableArray *)parseGamesFromString:(NSString *)str
{
    NSMutableArray *games = [[NSMutableArray alloc] init];
    
    NSArray *lines = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableDictionary *tags;
    NSMutableString *moves;
    BOOL readingTags = NO;
    
    for (NSString *line in lines) {
        if ([line length] == 0) {
            continue;
        }
        if ([line characterAtIndex:0] == '[' && [line characterAtIndex:[line length] - 1] == ']') {
            // This is a tag
            if (!readingTags) {
                readingTags = YES;
                if (tags && moves) {
                    [games addObject:[[SFMChessGame alloc] initWithTags:[tags copy] moveText:[moves copy]]];
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
            
            [moves appendFormat:@"%@ ", line];
        }
    }
    // Upon reaching the end of the file we need to add the last game
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:[tags copy] moveText:[moves copy]];
    [games addObject:game];
    return games;
    
}

+ (NSArray *)tokenizeMoveText:(NSString *)moveText
{
// Strip the period, space, and new line characters
    NSMutableCharacterSet *cSet = [[NSMutableCharacterSet alloc] init];
    [cSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [cSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
    NSArray *allTokens = [moveText componentsSeparatedByCharactersInSet:cSet];
    
    // Eliminate all non-move tokens, such as move numbers, annotations, and variations
    int depth = 0;
    NSMutableArray *moveTokens = [NSMutableArray new];
    for (NSString *token in allTokens) {
        if ([token length] == 0) {
            continue;
        }
        int delta = [SFMParser depthDeltaForString:token];
        depth += delta;
        
        if (depth < 0) {
            @throw [NSException exceptionWithName:@"ParseException" reason:@"A set of parentheses or brackets in the move text don't match." userInfo:nil];
        }
        
        if (depth == 0 && [self isLetter:[token characterAtIndex:0]] && delta == 0) {
            [moveTokens addObject:token];
        }
    }
    
    return [moveTokens copy];
    
}

# pragma mark - Private

/*!
 Get the "depth delta" by counting parentheses.
 */
+ (int)depthDeltaForString:(NSString *)string
{
    int delta = 0;
    char ch;
    for (int i = 0; i < [string length]; i++) {
        ch = [string characterAtIndex:i];
        delta += (ch == '{');
        delta += (ch == '(');
        delta -= (ch == ')');
        delta -= (ch == '}');
    }
    return delta;
}


/*!
 @return YES if the character is a lower or upper-case letter.
 */
+ (BOOL)isLetter:(char)c
{
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

@end
