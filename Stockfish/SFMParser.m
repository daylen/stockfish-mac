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

+ (SFMNode *)parseMoveText:(NSString *)moveText position:(SFMPosition *)position{
    SFMNode *head = [[SFMNode alloc] init];
    NSMutableCharacterSet *charactersToTrim = [[NSMutableCharacterSet alloc] init];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"*"]];
    return [self parseString:[moveText stringByTrimmingCharactersInSet:charactersToTrim] fromNode:head position:position];
}

+ (SFMNode *)parseString:(NSString *)str fromNode:(SFMNode *)node position:(SFMPosition *)position
{
    NSArray *tokens = [self tokenizeString:str];
    SFMNode *currentNode = node;
    for(NSString *token in tokens){
        currentNode = [self parseToken:token fromNode:currentNode position:position];
    }
    return node;
}

+ (SFMNode *)parseToken:(NSString *)token fromNode:(SFMNode *)node position:(SFMPosition *)position
{
    SFMNode *currentNode = node;
    if([token characterAtIndex:0] == '{'){ //comment
        [node setComment:[token substringWithRange:NSMakeRange(1, [token length] - 2)]];
    }
    else if([token characterAtIndex:0] == '('){ //variation
        [position undoMoves:1];
        SFMNode *dummy = [[SFMNode alloc] initWithPly:currentNode.ply - 1];
        [SFMParser parseString:[token substringWithRange:NSMakeRange(1, [token length] - 2)] fromNode:dummy position:[position copy]];
        [dummy.next setParent:currentNode.parent];
        [currentNode.variations addObject:dummy.next];
        [position doMove:node.move error:nil];
    }
    else{ //plain moves
        NSError *e = nil;
        currentNode = [position nodeForSan:token parentNode:currentNode error:&e];
        if(e){
            // TODO: handle
        }
    }
    return currentNode;
}

/*!
 Splits the string into tokens at the same depth. A token can be: move sequence, variation or comment
 */
+ (NSArray *)tokenizeString:(NSString*)str
{
    if ([[str stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    {
        return [NSArray new];
    }
    
    NSMutableArray *tokens = [NSMutableArray new];
    NSMutableArray *stack = [NSMutableArray new];
    char ch;
    
    int tokenStartIndex = 0;
    for (int i = 0; i < [str length]; i++) {
        ch = [str characterAtIndex:i];
        
        if(ch == '(' || ch == '{'){
            if([stack count] == 0 && i - tokenStartIndex > 0){
                [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, i-tokenStartIndex)]];
                tokenStartIndex = i;
            }
            [stack addObject:[NSString stringWithFormat:@"%c", ch == '(' ? ')' : '}']];
        }
        else if(ch == ')' || ch == '}'){
            if([stack count] == 0 || ![[stack lastObject] isEqualToString:[NSString stringWithFormat:@"%c", ch]]){
                [NSException raise:@"Invalid move text" format:@"Move text is invalid." arguments:nil];
            }
            [stack removeLastObject];
            if([stack count] == 0){
                [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, i-tokenStartIndex + 1)]];
                tokenStartIndex = i + 1;
            }
        }
    }
    
    if(tokenStartIndex < [str length]){
        [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, [str length] - tokenStartIndex)]];
    }
    
    return tokens;
}

+ (BOOL)isLetter:(char)c
{
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

@end
