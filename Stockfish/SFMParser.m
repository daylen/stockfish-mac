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

static NSRange SFMCommentRangeAtIndex(NSString *text, NSUInteger index)
{
    unichar character = [text characterAtIndex:index];
    if (character == '{') {
        NSRange close = [text rangeOfString:@"}" options:0 range:NSMakeRange(index + 1, text.length - index - 1)];
        NSUInteger end = close.location == NSNotFound ? text.length : NSMaxRange(close);
        return NSMakeRange(index, end - index);
    }
    BOOL startsLine = index == 0 || [text characterAtIndex:index - 1] == '\n'
        || [text characterAtIndex:index - 1] == '\r';
    if (character == ';' || (character == '%' && startsLine)) {
        NSUInteger contentsEnd;
        [text getLineStart:NULL end:NULL contentsEnd:&contentsEnd forRange:NSMakeRange(index, 0)];
        return NSMakeRange(index, contentsEnd - index);
    }
    return NSMakeRange(NSNotFound, 0);
}

static BOOL SFMContainsMoveText(NSString *text)
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSUInteger index = 0; index < text.length; index++) {
        NSRange comment = SFMCommentRangeAtIndex(text, index);
        if (comment.location != NSNotFound) {
            index = NSMaxRange(comment) - 1;
        } else if (![whitespace characterIsMember:[text characterAtIndex:index]]) {
            return YES;
        }
    }
    return NO;
}

@implementation SFMParser

+ (NSMutableArray * _Nullable)parseGamesFromString:(NSString * _Nonnull)str error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSMutableArray *everyGameTheFileHolds = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *tags;
    NSMutableString *moves;
    BOOL readingTags = NO;
    
    NSRegularExpression *tagPattern = [NSRegularExpression regularExpressionWithPattern:
        @"^[ \t]*\\[[ \t]*([A-Za-z0-9][A-Za-z0-9_]*)[ \t]*\"((?:[^\"\\\\\\r\\n]|\\\\[\"\\\\])*)\"[ \t]*\\][ \t]*$"
        options:0 error:NULL];
    NSUInteger commentEnd = 0;
    NSUInteger offset = 0;
    while (offset < str.length) {
        NSUInteger lineStart = offset;
        NSUInteger lineEnd;
        NSUInteger contentsEnd;
        [str getLineStart:NULL end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(offset, 0)];
        NSString *line = [str substringWithRange:NSMakeRange(offset, contentsEnd - offset)];
        NSString *originalLine = [str substringWithRange:NSMakeRange(offset, lineEnd - offset)];
        offset = lineEnd;
        if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
            if (!readingTags || moves.length > 0) {
                [moves appendString:originalLine];
            }
            continue;
        }
        BOOL insideComment = lineStart < commentEnd;
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        BOOL looksLikeTag = !insideComment && [trimmedLine hasPrefix:@"["];
        NSTextCheckingResult *tag = looksLikeTag
            ? [tagPattern firstMatchInString:line options:0 range:NSMakeRange(0, line.length)] : nil;
        if (tag != nil) {
            if (!readingTags) {
                readingTags = YES;
                if (moves != nil && (tags != nil || SFMContainsMoveText(moves))) {
                    [everyGameTheFileHolds addObject:[[SFMChessGame alloc] initWithTags:[tags copy] moveText:[moves copy]]];
                    moves = nil;
                }
                tags = [NSMutableDictionary new];
                if (moves == nil) {
                    moves = [NSMutableString new];
                }
            }
            
            NSString *tagName = [line substringWithRange:[tag rangeAtIndex:1]];
            tags[tagName] = [line substringWithRange:[tag rangeAtIndex:2]];
        } else {
            if (!looksLikeTag) {
                readingTags = NO;
            }

            if (moves == nil) {
                moves = [NSMutableString new];
            }
            
            [moves appendString:originalLine];
            if (!looksLikeTag) {
                for (NSUInteger index = MAX(lineStart, commentEnd); index < contentsEnd; index++) {
                    NSRange comment = SFMCommentRangeAtIndex(str, index);
                    if (comment.location != NSNotFound) {
                        commentEnd = NSMaxRange(comment);
                        index = commentEnd - 1;
                    }
                }
            }
        }
    }
    // Upon reaching the end of the file we need to add the last game
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:[tags copy] moveText:[moves copy]];
    [everyGameTheFileHolds addObject:game];

    NSUInteger readableGameCount = 0;
    for (SFMChessGame *game in everyGameTheFileHolds) {
        NSError *err = nil;
        if ([game parseMoveText:&err]) {
            readableGameCount++;
        }
    }

    BOOL nothingIsReadable = (readableGameCount == 0);
    if (nothingIsReadable) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:GAME_ERROR_DOMAIN code:GAME_PARSE_ERROR_CODE userInfo:nil];
        }
        return nil;
    }

    return everyGameTheFileHolds;
}

+ (SFMNode * _Nullable)parseMoveText:(NSString * _Nullable)moveText position:(SFMPosition * _Nonnull)position rejectedMove:(NSString * _Nullable __autoreleasing * _Nullable)rejectedMove error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (rejectedMove != NULL) {
        *rejectedMove = nil;
    }
    SFMNode *head = [[SFMNode alloc] init];
    if (moveText == nil) {
        return head;
    }
    NSMutableCharacterSet *charactersToTrim = [[NSMutableCharacterSet alloc] init];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"*"]];
    NSString *moves = [moveText stringByTrimmingCharactersInSet:charactersToTrim];
    if ([moves length] == 0) {
        return head;
    }
    return [self parseString:moveText fromNode:head position:position rejectedMove:rejectedMove error:error];
}

+ (SFMNode * _Nullable)parseString:(NSString * _Nonnull)str fromNode:(SFMNode * _Nonnull)node position:(SFMPosition * _Nonnull)position rejectedMove:(NSString * _Nullable __autoreleasing * _Nullable)rejectedMove error:(NSError * _Nullable __autoreleasing * _Nullable)error
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
        NSError *tokenError = nil;
        SFMNode *parsedNode = [self parseToken:token fromNode:currentNode position:position rejectedMove:rejectedMove error:&tokenError];
        if (parsedNode == nil) {
            NSString *illegalMove = [self illegalMoveFromError:tokenError];
            BOOL moveTextIsUnreadable = (illegalMove == nil);
            if (moveTextIsUnreadable) {
                if (error != NULL) {
                    *error = tokenError ?: [NSError errorWithDomain:GAME_ERROR_DOMAIN code:GAME_PARSE_ERROR_CODE userInfo:nil];
                }
                return nil;
            }
            if (rejectedMove != NULL && *rejectedMove == nil) {
                *rejectedMove = illegalMove;
            }
            return node;
        }
        currentNode = parsedNode;
    }
    return node;
}

+ (NSString * _Nullable)illegalMoveFromError:(NSError * _Nullable)error
{
    BOOL reportsAnIllegalMove = [[error domain] isEqualToString:POSITION_ERROR_DOMAIN]
        && [error code] == ILLEGAL_MOVE_CODE;
    if (!reportsAnIllegalMove) {
        return nil;
    }
    return [error userInfo][REJECTED_MOVE_KEY];
}

+ (SFMNode * _Nullable)parseToken:(NSString * _Nonnull)token fromNode:(SFMNode * _Nonnull)node position:(SFMPosition * _Nonnull)position rejectedMove:(NSString * _Nullable __autoreleasing * _Nullable)rejectedMove error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    SFMNode *currentNode = node;
    BOOL braceComment = [token hasPrefix:@"{"];
    if (braceComment || [token hasPrefix:@";"]) {
        NSUInteger commentEnd = braceComment ? token.length - 1 : token.length;
        NSString *comment = [token substringWithRange:NSMakeRange(1, commentEnd - 1)];
        NSString *separator = braceComment ? @" " : @"\n";
        node.comment = node.comment == nil ? comment : [node.comment stringByAppendingFormat:@"%@%@", separator, comment];
    }
    else if([token characterAtIndex:0] == '('){ //variation
        [position undoMoves:1];
        SFMNode *dummy = [[SFMNode alloc] initWithPly:currentNode.ply - 1];
        NSString *variationRejectedMove = nil;
        SFMNode * parsedNode = [SFMParser parseString:[token substringWithRange:NSMakeRange(1, [token length] - 2)] fromNode:dummy position:[position copy] rejectedMove:&variationRejectedMove error:error];
        if (parsedNode == nil) {
            return nil;
        }
        BOOL variationHasNoMoves = dummy.next == nil;
        if (variationHasNoMoves && variationRejectedMove == nil) {
            return nil;
        }
        if (rejectedMove != NULL && *rejectedMove == nil) {
            *rejectedMove = variationRejectedMove;
        }
        if (!variationHasNoMoves) {
            [dummy.next setParent:currentNode.parent];
            [currentNode.variations addObject:dummy.next];
        }
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

+ (BOOL)isValidToken:(NSString*)token
{
    return token != nil && ![@"(null)" isEqualToString:token];
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
    NSUInteger variationDepth = 0;
    NSUInteger tokenStartIndex = 0;
    for (NSUInteger index = 0; index < str.length; index++) {
        unichar character = [str characterAtIndex:index];
        NSRange comment = SFMCommentRangeAtIndex(str, index);
        if (comment.location != NSNotFound) {
            NSUInteger end = NSMaxRange(comment);
            if (character == '{' && [str characterAtIndex:end - 1] != '}') {
                return @[];
            }
            if (variationDepth == 0) {
                if (index > tokenStartIndex) {
                    [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, index - tokenStartIndex)]];
                }
                if (character != '%') {
                    [tokens addObject:[str substringWithRange:comment]];
                }
                tokenStartIndex = end;
            }
            index = end - 1;
        } else if (character == '(') {
            if (variationDepth == 0) {
                if (index > tokenStartIndex) {
                    [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, index - tokenStartIndex)]];
                }
                tokenStartIndex = index;
            }
            variationDepth++;
        } else if (character == ')') {
            if (variationDepth == 0) {
                return @[];
            }
            variationDepth--;
            if (variationDepth == 0) {
                [tokens addObject:[str substringWithRange:NSMakeRange(tokenStartIndex, index - tokenStartIndex + 1)]];
                tokenStartIndex = index + 1;
            }
        } else if (character == '}' || character == '[' || character == ']') {
            return @[];
        }
    }
    if (variationDepth > 0) {
        return @[];
    }
    if (tokenStartIndex < str.length) {
        [tokens addObject:[str substringFromIndex:tokenStartIndex]];
    }

    return [tokens objectsAtIndexes:[tokens indexesOfObjectsPassingTest:^BOOL(id token, NSUInteger idx, BOOL * stop) {
        return [SFMParser isValidToken:token];
    }]];
}

+ (BOOL)isLetter:(char)c
{
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

@end
