//
//  SFMParser.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMParser.h"
#import "Constants.h"
#import "SFMChessGame.h"

@implementation SFMParser

+ (NSMutableArray * _Nullable)parseGamesFromString:(NSString * _Nonnull)str error:(NSError * _Nullable __autoreleasing * _Nullable)error
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

            if (moves == nil) {
                moves = [NSMutableString new];
            }
            
            [moves appendFormat:@"%@ ", line];
        }
    }
    // Upon reaching the end of the file we need to add the last game
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:[tags copy] moveText:[moves copy]];
    [games addObject:game];

    for (SFMChessGame *game in games) {
        NSError *err = nil;
        BOOL ok = [game parseMoveText:&err];
        if (!ok) {
            return nil;
        }
    }

    return games;
}

+ (SFMNode * _Nullable)parseMoveText:(NSString * _Nullable)moveText position:(SFMPosition * _Nonnull)position error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    SFMNode *head = [[SFMNode alloc] init];
    if (moveText == nil || [moveText isEqualToString:@""]) {
        return head;
    }
    NSMutableCharacterSet *charactersToTrim = [[NSMutableCharacterSet alloc] init];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"*"]];
    return [self parseString:[moveText stringByTrimmingCharactersInSet:charactersToTrim] fromNode:head position:position error:error];
}

+ (SFMNode * _Nullable)parseString:(NSString * _Nonnull)str fromNode:(SFMNode * _Nonnull)node position:(SFMPosition * _Nonnull)position error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSArray *tokens = [self tokenizeString:str];
    if (tokens.count == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:GAME_ERROR_DOMAIN code:GAME_PARSE_ERROR_CODE userInfo:nil];
        }
        return nil;
    }
    SFMNode *currentNode = node;
    for(NSString *token in tokens){
        currentNode = [self parseToken:token fromNode:currentNode position:position error:error];
        if (currentNode == nil) {
            if (error != NULL && *error == nil) {
                *error = [NSError errorWithDomain:GAME_ERROR_DOMAIN code:GAME_PARSE_ERROR_CODE userInfo:nil];
            }
            return nil;
        }
    }
    return node;
}

+ (SFMNode * _Nullable)parseToken:(NSString * _Nonnull)token fromNode:(SFMNode * _Nonnull)node position:(SFMPosition * _Nonnull)position error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    SFMNode *currentNode = node;
    if([token characterAtIndex:0] == '{'){ //comment
        [node setComment:[token substringWithRange:NSMakeRange(1, [token length] - 2)]];
    }
    else if([token characterAtIndex:0] == '('){ //variation
        [position undoMoves:1];
        SFMNode *dummy = [[SFMNode alloc] initWithPly:currentNode.ply - 1];
        SFMNode * parsedNode = [SFMParser parseString:[token substringWithRange:NSMakeRange(1, [token length] - 2)] fromNode:dummy position:[position copy] error:error];
        if (parsedNode == nil) {
            return nil;
        }
        [dummy.next setParent:currentNode.parent];
        [currentNode.variations addObject:dummy.next];
        [position doMove:node.move error:error];
        if (error != NULL && *error != nil) {
            return nil;
        }
    }
    else{ //plain moves
        currentNode = [position nodeForSan:token parentNode:currentNode error:error];
        if (currentNode == nil) {
            return nil;
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
        bool currentlyInComment = [[stack lastObject] isEqualToString:[NSString stringWithFormat:@"%c", '}']];
        
        if ((ch == '(' || ch == '{') && !currentlyInComment) {
            if ([stack count] == 0 && i - tokenStartIndex > 0) {
                [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, i-tokenStartIndex)]];
                tokenStartIndex = i;
            }
            [stack addObject:[NSString stringWithFormat:@"%c", ch == '(' ? ')' : '}']];
        } else if (ch == ')' || ch == '}') {
            if (ch == ')' && currentlyInComment) continue;
            if ([stack count] == 0 || ![[stack lastObject] isEqualToString:[NSString stringWithFormat:@"%c", ch]]) {
                // TODO: Should bubble up the specific error.
                return [NSArray new];
            }
            [stack removeLastObject];
            if ([stack count] == 0) {
                [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, i-tokenStartIndex + 1)]];
                tokenStartIndex = i + 1;
            }
        }
    }
    
    if (tokenStartIndex < [str length]) {
        [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, [str length] - tokenStartIndex)]];
    }
    
    return tokens;
}

+ (BOOL)isLetter:(char)c
{
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

@end
