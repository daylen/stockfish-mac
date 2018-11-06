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
#import "SFMNode.h"

@interface SFMChessGame()

@property (nonatomic, readonly) SFMNode *startNode;
@property (nonatomic, readwrite) SFMNode *currentNode;
@property (nonatomic, readwrite) SFMPosition *position;
@property (nonatomic, readonly) SFMPosition *startPosition;
@property (nonatomic, copy) NSString *moveText;
@property (nonatomic) BOOL moveTextParsed;

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
        _currentNode = [[SFMNode alloc] init];
        _position = [[SFMPosition alloc] init];
        _undoManager = [[NSUndoManager alloc] init];
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
        _position = [[SFMPosition alloc] initWithFen:_tags[@"FEN"] ? _tags[@"FEN"] : FEN_START_POSITION];
        _undoManager = [[NSUndoManager alloc] init];
    }
    return self;
}

- (SFMNode *)startNode{
    SFMNode *tmp = _currentNode;
    while(tmp != nil && !tmp.isTopNode){
        tmp = tmp.parent;
    }
    return tmp;
}

- (BOOL)isInInitialState {
    return self.moveText == nil;
}

- (BOOL)parseMoveText:(NSError *__autoreleasing *)error {
    if(!_moveTextParsed){
        _currentNode = [SFMParser parseMoveText:_moveText position:[self.startPosition copy] error:error];
        if (_currentNode == nil) {
            return NO;
        }
        _moveTextParsed = YES;
    }
    return YES;
}

#pragma mark - State Modification

- (BOOL)doMove:(SFMMove *)move error:(NSError *__autoreleasing *)error {
    NSAssert(move, @"Move is nil");
    
    NSError *e = nil;
    [self.position doMove:move error:&e];
    if (e) {
        *error = e;
        return NO;
    }
    SFMNode *newMove = [[SFMNode alloc] initWithMove:move andParent:_currentNode];
    
    if (![self atEnd]) {
        [_currentNode.next.variations addObject:newMove];
        [self.undoManager registerUndoWithTarget:self selector:@selector(removeSubtreeFromNodeAndUpdateState:) object:newMove];
    }
    else{
        _currentNode.next = newMove;
        [self.undoManager registerUndoWithTarget:self selector:@selector(removeSubtreeFromNodeAndUpdateState:) object:newMove];
    }
    
    _currentNode = newMove;
    return YES;
}

- (void)addSubtreeToCurrentNode:(SFMNode *)subtree asVariation:(BOOL)asVariation
{
    [self.undoManager registerUndoWithTarget:self selector:@selector(removeSubtreeFromNodeAndUpdateState:) object:subtree];
    if(!asVariation){
        _currentNode.next = subtree;
        [self goForwardOneMove];
    }
    else{
        [_currentNode.variations addObject:subtree];
        [self goToNode:subtree];
    }
    [self.delegate chessGameStateDidChange:self];
}

- (void)removeSubtreeFromNode:(SFMNode *)node
{
    SFMNode *deletedNode;
    BOOL variation = NO;
    if([node.parent.next.nodeId isEqual:node.nodeId]){
        //the node we are removing is the main variation
        deletedNode = node;
        _currentNode = node.parent;
        _currentNode.next = nil;
    }
    else{
        //if we are removing a variation then go to the parent's next (main) move
        variation = YES;
        _currentNode = node.parent.next;
        for(int i = 0; i < [_currentNode.variations count]; i++){
            if([[_currentNode.variations[i] nodeId] isEqual:node.nodeId]){
                deletedNode = _currentNode.variations[i];
                [_currentNode.variations removeObjectAtIndex:i];
                break;
            }
        }
    }
    [[self.undoManager prepareWithInvocationTarget:self] addSubtreeToCurrentNode:deletedNode asVariation:variation];
    [self goToNode:_currentNode];
}

- (void)removeSubtreeFromNodeAndUpdateState:(SFMNode *)node
{
    [self removeSubtreeFromNode:node];
    [self.delegate chessGameStateDidChange:self];
}

- (void)removeSubtreeFromNodeId:(NSUUID *)nodeId
{
    SFMNode *nodeToRemove = [self searchNode:self.startNode forId:nodeId];
    if(nodeToRemove == nil){
        [NSException raise:@"Node with id not found." format:@"Node was not found."];
    }
    [self removeSubtreeFromNode:nodeToRemove];
}

- (void)setResult:(NSString *)result {
    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] initWithDictionary:self.tags];
    mDict[@"Result"] = result;
    self.tags = mDict;
}

#pragma mark - Navigation

- (BOOL)atBeginning
{
    return _currentNode.isTopNode;
}
- (BOOL)atEnd
{
    return _currentNode.next == nil;
}
- (void)goBackOneMove
{
    if (![self atBeginning]) {
        [self.position undoMoves:1];
        _currentNode = _currentNode.parent;
    }
}
- (void)goForwardOneMove
{
    if (![self atEnd]) {
        [self.position doMove:_currentNode.next.move error:nil];
        _currentNode = _currentNode.next;
    }
}
- (void)goToBeginning
{
    [self goToNode:self.startNode];
}
- (void)goToEnd
{
    while(![self atEnd]){
        [self goForwardOneMove];
    }
}

- (void) goToNode:(SFMNode *)node{
    self.position = [self.startPosition copy];
    for(SFMMove *mv in [node reconstructMovesFromBeginning]){
        [self.position doMove:mv error:nil];
    }
    _currentNode = node;
}

- (void)goToNodeId:(NSUUID*)nodeId{
    SFMNode *node = [self searchNode:self.startNode forId:nodeId];
    [self goToNode: node];
}

- (SFMNode *)searchNode:(SFMNode *)node forId:(NSUUID*)nid{
    
    if([node.nodeId isEqual:nid]){
        return node;
    }
    
    if(node.next != nil){
        SFMNode *mainVar = [self searchNode:node.next forId:nid];
        if(mainVar != nil){
            return mainVar;
        }
    }

    for(SFMNode *var in node.variations){
        SFMNode *result = [self searchNode:var forId:nid];
        if(result != nil){
            return result;
        }
    }
    return nil;
}

#pragma mark - Other

- (SFMPosition *)startPosition {
    return self.tags[@"FEN"] ? [[SFMPosition alloc] initWithFen:self.tags[@"FEN"]] : [[SFMPosition alloc] init];
}

#pragma mark - Export
-(int)currentPly
{
    return _currentNode.ply;
}

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
    
    [str appendString:@"\n"];
    [str appendString:[[self moveTextString] string]];
    [str appendFormat:@"%@\n\n", self.tags[@"Result"]];

    return str;
}

- (NSString *)description
{
    NSString *s = [NSString stringWithFormat:@"%@ v. %@, %@, %ld tags", self.tags[@"White"], self.tags[@"Black"], self.tags[@"Result"], [self.tags count]];
    return s;
}

- (NSAttributedString *)moveTextString {
    return [self.startPosition moveTextForNode:self.startNode withCurrentNodeId:_currentNode.nodeId];
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
        NSArray *truncatedMoves = [_currentNode reconstructMovesFromBeginning];
        [str appendFormat:@" %@", [SFMPosition uciForMovesArray:truncatedMoves]];
    }
    return [str copy];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SFMChessGame *copy = [[SFMChessGame alloc] init];
    copy.tags = [self.tags copy];
    copy.position = [self.position copy];
    copy.currentNode = [_currentNode copy];
    return copy;
}

@end
