//
//  SFMChessGame.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMChessGame.h"
#import "Constants.h"
#import "SFMParser.h"

@interface SFMChessGame()

@property (nonatomic) NSMutableArray /* of SFMMove */ *moves;
@property (nonatomic, readwrite) SFMPosition *position;
@property (nonatomic, readonly) SFMPosition *startPosition;
@property (nonatomic, copy) NSString *moveText;
@property (readwrite) NSUInteger currentMoveIndex;

@end

@implementation SFMChessGame

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear|kCFCalendarUnitDay|kCFCalendarUnitMonth fromDate:[NSDate new]];
        NSString *dateStr = [NSString stringWithFormat:@"%ld.%02ld.%02ld", (long)dateComponents.year, (long)dateComponents.month, (long)dateComponents.day];
        _tags = @{@"Event": @"?",
                  @"Site": @"Earth",
                  @"Date": dateStr,
                  @"Round": @"1",
                  @"White": @"?",
                  @"Black": @"?",
                  @"Result": @"*"};
        _moves = [[NSMutableArray alloc] init];
        _currentMoveIndex = 0;
        _position = [[SFMPosition alloc] init];
    }
    return self;
}

- (instancetype)initWithFen:(NSString *)fen {
    if (self = [self init]) {
        NSMutableDictionary *mTags = [[NSMutableDictionary alloc] initWithDictionary:_tags];
        mTags[@"FEN"] = fen;
        _tags = mTags;
        _position = [[SFMPosition alloc] initWithFen:fen];
    }
    return self;
}

- (instancetype)initWithTags:(NSDictionary *)tags moveText:(NSString *)moveText {
    if (self = [super init]) {
        _tags = tags;
        _moveText = moveText;
        _currentMoveIndex = 0;
        _position = [[SFMPosition alloc] initWithFen:_tags[@"FEN"] ? _tags[@"FEN"] : FEN_START_POSITION];
    }
    return self;
}

- (void)parseMoveText:(NSError *__autoreleasing *)error {
    if (_moves == nil) {
        _moves = [[NSMutableArray alloc] init];
        
        NSArray *moveTokens = [SFMParser tokenizeMoveText:_moveText];
        
        NSError *e = nil;
        NSArray *moves = [self.startPosition movesArrayForSan:moveTokens error:&e];
        
        if (e) {
            *error = e;
        } else {
            _moves = [moves mutableCopy];
            _moveText = nil;
        }
    }
}

#pragma mark - State Modification

- (BOOL)doMove:(SFMMove *)move error:(NSError *__autoreleasing *)error {
    
    if (![self atEnd]) {
        *error = [NSError errorWithDomain:GAME_ERROR_DOMAIN code:NOT_AT_END_CODE userInfo:nil];
        return NO;
    }
    
    NSError *e = nil;
    [self.position doMove:move error:&e];
    if (e) {
        *error = e;
        return NO;
    }
    
    self.currentMoveIndex++;
    [self.moves addObject:move];
    return YES;
}

- (BOOL)doMoves:(NSArray *)moves error:(NSError *__autoreleasing *)error {
    NSError *e = nil;
    for (SFMMove *move in moves) {
        [self doMove:move error:&e];
        if (e) {
            *error = e;
            return NO;
        }
    }
    return YES;
}

- (NSArray *)deleteMovesFromPly:(NSInteger)index {
    NSArray *toDelete = [self.moves subarrayWithRange:NSMakeRange(index, [self.moves count] - index)];
    [self.moves removeObjectsInRange:NSMakeRange(index, [self.moves count] - index)];
    [self goToEnd];
    return toDelete;
}

- (void)setResult:(NSString *)result {
    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] initWithDictionary:self.tags];
    mDict[@"Result"] = result;
    self.tags = mDict;
}

#pragma mark - Navigation

- (BOOL)atBeginning
{
    return self.currentMoveIndex == 0;
}
- (BOOL)atEnd
{
    return self.currentMoveIndex == [self.moves count];
}
- (void)goBackOneMove
{
    if (![self atBeginning]) {
        [self goToPly:self.currentMoveIndex - 1];
    }
}
- (void)goForwardOneMove
{
    if (![self atEnd]) {
        [self goToPly:self.currentMoveIndex + 1];
    }
}
- (void)goToBeginning
{
    [self goToPly:0];
}
- (void)goToEnd
{
    [self goToPly:[self.moves count]];
}
- (void)goToPly:(NSUInteger)ply
{
    self.currentMoveIndex = ply;
    
    // Replay moves up to current ply
    self.position = [self.startPosition copy];
    for (NSUInteger i = 0; i < ply; i++) {
        [self.position doMove:self.moves[i] error:nil];
    }
}

#pragma mark - Other

- (SFMPosition *)startPosition {
    return self.tags[@"FEN"] ? [[SFMPosition alloc] initWithFen:self.tags[@"FEN"]] : [[SFMPosition alloc] init];
}

#pragma mark - Export

- (NSString *)pgnString
{
    NSMutableString *str = [NSMutableString new];
    for (NSString *tagName in [self.tags allKeys]) {
        [str appendString:@"["];
        [str appendString:tagName];
        [str appendString:@" \""];
        [str appendString:self.tags[tagName]];
        [str appendString:@"\"]\n"];
    }
    
    if (self.moveText) {
        // Original move text was not modified
        [str appendString:self.moveText];
    } else {
        [str appendString:@"\n"];
        [str appendString:[self moveTextString:NO num:1]];
        [str appendFormat:@"%@\n\n", self.tags[@"Result"]];
    }
    
    return str;
}

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:@"%@ v. %@, %@, %ld tags", self.tags[@"White"], self.tags[@"Black"], self.tags[@"Result"], [self.tags count]];
    return s;
}

- (NSString *)moveTextString:(BOOL)html num:(int)num {
    return [self.startPosition sanForMovesArray:self.moves html:html breakLines:NO num:num];
}

- (NSString *)uciString
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@"position "];
    if (self.tags[@"FEN"]) {
        [str appendFormat:@"fen %@", self.tags[@"FEN"]];
    } else {
        [str appendString:@"startpos"];
    }
    if (![self atBeginning]) {
        [str appendString:@" moves"];
        NSArray *truncatedMoves = [self.moves subarrayWithRange:NSMakeRange(0, self.currentMoveIndex)];
        [str appendFormat:@" %@", [SFMPosition uciForMovesArray:truncatedMoves]];
    }
    return [str copy];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SFMChessGame *copy = [[SFMChessGame alloc] init];
    copy.tags = [self.tags copy];
    copy.position = [self.position copy];
    copy.currentMoveIndex = self.currentMoveIndex;
    copy.moves = [self.moves mutableCopy];
    return copy;
}

@end
