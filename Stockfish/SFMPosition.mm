//
//  SFMPosition.m
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPosition.h"
#import "Constants.h"
#import "SFMMove.h"
#import "SFMParser.h"

#include "../Chess/position.h"
#include "../Chess/bitboard.h"
#include "../Chess/direction.h"
#include "../Chess/mersenne.h"
#include "../Chess/movepick.h"
#include "../Chess/san.h"

using namespace Chess;

@interface SFMPosition()

@property (assign, nonatomic) Position *position;
@property (readonly, nonatomic) NSMutableArray *moves;
@property (readonly, nonatomic) NSMutableArray *undoInfos;

@end

NSString* const moveRegex =
@"("
"[BRQNK][a-h][1-8]|" // Piece moves (Ba8)
"[BRQNK]x[a-h][1-8]|" // Captures (Qxe6)
"[BRQN][a-h][a-h][1-8]|" // Ambiguous column moves (Rae1)
"[BRQN][a-h]x[a-h][1-8]|" // Ambiguous column captures (Raxd1)
"[BRQN][1-8][a-h][1-8]|" // Ambiguous row moves (R1e2)
"[BRQN][1-8]x[a-h][1-8]|" // Ambiguous row captures (R3xa4)
"[a-h][2-7]|" // Pawn moves (e4)
"[a-h]x[a-h][2-7]|" // Pawn captures (exd5)
"[a-h][18]=[BRQN]|" // Promotions (c8=Q)
"[a-h]x[a-h][18]=[BRQN]|" // Capture and promotion (bxa8=Q)
"O-O-O|" // Long castle
"O-O|" // Short castle
")"
"[\\+#]?" // Check / mate
"([!?]{0,2})" // Move annotation (!?, ??, ?)
;

@implementation SFMPosition
@synthesize position = _position;


# pragma mark - Class

+ (void)initialize {
    if (self == [SFMPosition class]) {
        init_mersenne();
        init_direction_table();
        init_bitboards();
        Position::init_zobrist();
        Position::init_piece_square_tables();
        MovePicker::init_phase_table();
    }
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[SFMPosition alloc] initWithFen:[self fen] moves:[_moves copy] undoInfos:[_undoInfos copy]];
}

- (void)dealloc {
    delete _position;
}

#pragma mark - Init

- (instancetype)init {
    return [self initWithFen:FEN_START_POSITION];
}

- (instancetype)initWithFen:(NSString *)fen {
    return [self initWithFen:fen moves:[[NSMutableArray alloc] init] undoInfos:[[NSMutableArray alloc] init]];
}

- (instancetype)initWithFen:(NSString *)fen moves:(NSArray*)moves undoInfos:(NSArray*)undoInfos {
    self = [super init];
    if(self){
        _position = new Position([fen UTF8String]);
        _moves = [[NSMutableArray alloc] initWithArray:moves];
        _undoInfos = [[NSMutableArray alloc] initWithArray:undoInfos];
    }
    return self;
}

+ (BOOL)isValidFen:(NSString *)fen {
    return Position::is_valid_fen([fen UTF8String]);
}

# pragma mark - State modification

- (BOOL)doMove:(SFMMove *)move error:(NSError *__autoreleasing *)error {
    Move m = [[self class] libMoveFromMoveObj:move];
    
    Move mlist[500];
    int numLegalMoves = self.position->all_legal_moves(mlist);
    
    BOOL foundLegalMove = NO;
    
    for (int i = 0; i < numLegalMoves; i++) {
        if (mlist[i] == m) {
            foundLegalMove = YES;
            UndoInfo u;
            self.position->do_move(m, u);
            [self recordMove:m undoInfo:u];
        }
    }
    
    if (!foundLegalMove) {
        if (error != NULL) *error = [NSError errorWithDomain:POSITION_ERROR_DOMAIN
                                                        code:ILLEGAL_MOVE_CODE userInfo:nil];
    }
    return foundLegalMove;
}

- (BOOL)undoMoves:(int)numberOfMoves
{
    if(numberOfMoves > [_moves count]){
        return NO;
    }
    while(numberOfMoves){
        Move m; UndoInfo u;
        [[_moves lastObject] getValue:&m];
        [[_undoInfos lastObject] getValue:&u];
        self.position->undo_move(m, u);
        [_moves removeLastObject];
        [_undoInfos removeLastObject];
        numberOfMoves--;
    }
    return YES;
}

- (BOOL)doMoves:(NSArray *)moves error:(NSError *__autoreleasing *)error
{
    for(SFMMove *move in moves){
        BOOL ok = [self doMove:move error:error];
        if (!ok) {
            return NO;
        }
    }
    return YES;
}

/*!
 Adds a move and its undo info to the stack so it can be undone
 @param move The move
 @param undoInfo The undo info
 */
- (void)recordMove:(Move)move undoInfo:(UndoInfo)undoInfo
{
    NSValue *m = [NSValue value: &move withObjCType:@encode(Move)];
    NSValue *u = [NSValue value: &undoInfo withObjCType:@encode(UndoInfo)];
    [_moves addObject:m];
    [_undoInfos addObject:u];
}

# pragma mark - Conversion

- (SFMNode *)nodeForSan:(NSString *)san parentNode:(SFMNode *)parent error:(NSError * __autoreleasing *)error
{
    SFMNode *currentNode = parent;
    // Strip the period, space, and new line characters
    NSMutableCharacterSet *cSet = [[NSMutableCharacterSet alloc] init];
    [cSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [cSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
    NSArray *tokens = [san componentsSeparatedByCharactersInSet:cSet];
    for(NSString *tok in tokens){
        if([tok length] > 0 && [SFMParser isLetter:[tok characterAtIndex:0]]){
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:moveRegex options:0 error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:tok options:0 range:NSMakeRange(0, tok.length)];
            NSString *moveString = [tok substringWithRange:[match rangeAtIndex:1]];
            NSString *moveAnnotation = [tok substringWithRange:[match rangeAtIndex:2]];
            Move m = move_from_san(*self.position, [moveString UTF8String]);
            if (m == MOVE_NONE) {
                // Error
                if (error != NULL) *error = [NSError errorWithDomain:POSITION_ERROR_DOMAIN
                                                                code:PARSE_ERROR_CODE userInfo:nil];
                return nil;
            } else {
                SFMMove *move = [[self class] moveObjFromLibMove:m];
                currentNode.next = [[SFMNode alloc] initWithMove:move annotation:moveAnnotation andParent:currentNode];
                currentNode = currentNode.next;
                BOOL ok = [self doMove:move error:error];
                if (!ok) {
                    return nil;
                }
            }
        }
    }
    return currentNode;
}

- (NSAttributedString *)moveTextForNode:(SFMNode *)node withCurrentNodeId:(NSUUID *)nodeId
{
    NSMutableAttributedString *san = [self moveTextForNode:node andPosition:[self copy] depth:0];
    [self setFontAttributes:san currentMoveNodeId:nodeId];
    return san;
}

/*!
 Generates a mutable attributed string in Standard Algebraic Notation corresponding to the subtree rooted in node
 @param node: The node
 @param position: The position the node subtree is played from
 @param depth: The depth of the recursion
 */
- (NSMutableAttributedString *)moveTextForNode:(SFMNode *)node andPosition:(SFMPosition *)position depth:(int)depth
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    SFMNode *currentNode = node;
    NSAttributedString *flatLine = [self longestFlatLineFrom:node position:position];
    [result appendAttributedString:flatLine];
    // move to node at the end of the flat line
    while(currentNode != nil && [currentNode.variations count] == 0 && currentNode.comment == nil){
        currentNode = currentNode.next;
    }
    
    if(currentNode != nil){
        SFMPosition *currentPosition = [position copy];
        // Make the moves up to the parent node
        int movesToParent = currentNode.ply - node.ply;
        if(node.isTopNode){
            movesToParent--;
        }
        NSArray *movesDelta = [currentNode.parent reconstructMoves:movesToParent];
        [currentPosition doMoves:movesDelta error:nil];
        // Only add first level variations on new lines
        if(depth == 0 && [currentNode.variations count] > 0){
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
        
        for(SFMNode *variation in currentNode.variations){
            SFMPosition *copy = [currentPosition copy];
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"( " attributes:[self variationStringAttributes]]];
            NSMutableAttributedString *variationString = [self moveTextForNode:variation andPosition:copy depth:depth + 1];
            [variationString addAttributes:[self variationStringAttributes] range:NSMakeRange(0, variationString.length)];
            [result appendAttributedString:variationString];
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@") " attributes:[self variationStringAttributes]]];
            if(depth == 0){
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
        }
        
        [currentPosition doMove:currentNode.move error:nil];
        // recurse for the rest of the moves
        if(currentNode.next != nil){
            [result appendAttributedString:[self moveTextForNode:currentNode.next andPosition:currentPosition depth:depth]];
        }
    }
    
    return result;
}

/*!
 Converts the longest flat line (without variations or comments) starting from a node to an attributed string
 */
- (NSAttributedString *)longestFlatLineFrom:(SFMNode *)node position:(SFMPosition *)position
{
    NSMutableArray *moves = [NSMutableArray new];
    NSMutableArray *nodes = [NSMutableArray new];
    int ply = node.ply - 1;
    while(node != nil && [node.variations count] == 0 && node.comment == nil){
        if(node.move != nil){
            [moves addObject:node.move];
            [nodes addObject:node];
        }
        node = node.next;
    }
    
    if(node != nil && node.move != nil) { // got to a node with variations or comment, add it
        [moves addObject:node.move];
        [nodes addObject:node];
    }
    Move line[800];
    int i = 0;
    
    for (SFMMove *move in moves) {
        line[i++] = [[self class] libMoveFromMoveObj:move];
    }
    
    line[i] = MOVE_NONE;
    
    NSString *lineSan = @(line_to_san(*position.position, line, 0, NO, ply / 2 + 1).c_str());
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:lineSan attributes:@{NSForegroundColorAttributeName: [NSColor labelColor]}];
    [self setMoveAttributes:attributedString nodes:nodes];
    if(node.comment != nil){
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[node.comment stringByAppendingString:@" "] attributes:@{NSLinkAttributeName: self.commentIdentifier}]];
    }
    
    return attributedString;
}

/*!
 Sets the attributes for the string
 @param string The move text
 @param nodes The nodes for which the move text was generated
 */
- (void)setMoveAttributes:(NSMutableAttributedString*)attributedString nodes:(NSArray *)nodes
{
    NSError *error = nil;
    NSRegularExpression *moveNumberRegex = [NSRegularExpression regularExpressionWithPattern:@"\\s*\\d+\\.{1,3}\\s*" options:0 error:&error];
    int plyCount = 0;
    NSRange range, nextRange;
    NSString *str = [attributedString string];
    
    range = [moveNumberRegex rangeOfFirstMatchInString:str options:0 range:NSMakeRange(0, str.length)];

    while(range.location != NSNotFound){
        nextRange = [moveNumberRegex rangeOfFirstMatchInString:str options:0 range:NSMakeRange(range.location + range.length, str.length - range.location - range.length)];
        if(nextRange.location == NSNotFound){
            nextRange = NSMakeRange(attributedString.length - 1, 0);
        }
        
        unsigned long start = range.location + range.length;
        unsigned long len = nextRange.location - start;
        
        NSRange firstMove, secondMove, remaining;
        [self splitStringMoves:str inRange:NSMakeRange(start, len) firstMove:&firstMove secondMove:&secondMove];
        [self addMoveAnnotationAndLink:attributedString node:[nodes objectAtIndex:plyCount++] range:firstMove];
        
        if(secondMove.location != NSNotFound){
            secondMove.location += [[[nodes objectAtIndex:plyCount - 1] annotation] length];
            [self addMoveAnnotationAndLink:attributedString node:[nodes objectAtIndex:plyCount++] range:secondMove];
            remaining = NSMakeRange(secondMove.location + secondMove.length, attributedString.length - (secondMove.location + secondMove.length));
        }
        else {
            if(nextRange.length == 0){
                break;
            }
            else{
                // We can have strings like 2... g5 3. Qd2 where the absence of a second move does not indicate that we are done
                remaining = NSMakeRange(firstMove.location + firstMove.length, attributedString.length - (firstMove.location + firstMove.length));
            }
        }
        
        str = [attributedString string];
        range = [moveNumberRegex rangeOfFirstMatchInString:str options:0 range:remaining];
    }
}

- (void)addMoveAnnotationAndLink:(NSMutableAttributedString*)string node:(SFMNode*)node range:(NSRange)range
{
    if(node.annotation != nil && [node.annotation length] > 0){
        [string insertAttributedString:[[NSAttributedString new] initWithString:node.annotation]  atIndex:range.location + range.length];
        range.length += [node.annotation length];
    }
    
    [self addLinkAttribute:string withValue:node.nodeId range:range];
}

- (void)addLinkAttribute:(NSMutableAttributedString*)string withValue:(NSUUID *)value range:(NSRange)range
{
    [string addAttribute:NSLinkAttributeName value:value range:range];
}

- (void)setFontAttributes:(NSMutableAttributedString *)san currentMoveNodeId:(NSUUID *)currentMoveId
{
    [san enumerateAttributesInRange:NSMakeRange(0, san.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> *attrs, NSRange range, BOOL *stop){
        BOOL isVariation = [[attrs objectForKey:NSForegroundColorAttributeName] isEqual: self.variationForegroundColor];
        BOOL isCurrentMove = [[attrs objectForKey:NSLinkAttributeName] isEqual: currentMoveId];
        BOOL isComment = [[attrs objectForKey:NSLinkAttributeName] isEqual: self.commentIdentifier];
        CGFloat fontSize = [NSFont systemFontSize] + 1;
        if(isVariation){
            fontSize--;
        }
        NSFont *font = [NSFont systemFontOfSize:fontSize];
        if(isCurrentMove){
            [san addAttributes:self.currentMoveStringAttributes range:range];
        }
        if(isComment){
            font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSItalicFontMask];
            [san removeAttribute:NSLinkAttributeName range:range];
            [san addAttribute:NSForegroundColorAttributeName value: self.commentForegroundColor range:range];
        }
        [san addAttribute:NSFontAttributeName value:font range:range];
    }];
}

- (NSDictionary<NSAttributedStringKey, id> *) variationStringAttributes
{
    return @{
             NSForegroundColorAttributeName: self.variationForegroundColor
             };
}

- (NSDictionary<NSAttributedStringKey, id> *) currentMoveStringAttributes
{
    return @{
             NSForegroundColorAttributeName: self.currentMoveForegroundColor,
             NSBackgroundColorAttributeName: self.currentMoveBackgroundColor
             };
}

- (NSString*) commentIdentifier
{
    return @"comment";
}

- (NSColor*) currentMoveForegroundColor{
    return [NSColor whiteColor];
}

- (NSColor*) currentMoveBackgroundColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor selectedContentBackgroundColor];
    } else {
        return [NSColor darkGrayColor];
    }
}

- (NSColor*)variationForegroundColor{
    return [NSColor secondaryLabelColor];
}

- (NSColor*)commentForegroundColor{
    return [NSColor secondaryLabelColor];
}

/*!
 Splits a string into one or two ranges, each corresponding to a move
 @param str The string
 @param range The range in the string
 @param first The range of the first move (output)
 @param second The range of the second move (output)
 */
- (void)splitStringMoves:(NSString*)str inRange:(NSRange)range firstMove:(NSRange*)first secondMove:(NSRange*)second
{
    NSRange moveSeparator = [str rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:0 range:range];
    
    if(moveSeparator.location != NSNotFound){
        *first = NSMakeRange(range.location, moveSeparator.location - range.location);
        unsigned long start = moveSeparator.location + moveSeparator.length;
        *second = NSMakeRange(start, range.location + range.length - start);
    }
    else {
        *first = range;
        *second = NSMakeRange(NSNotFound, 0);
    }
}

- (NSString *)sanForMovesArray:(NSArray* /* of SFMMove */)movesArray
                          html:(BOOL)html
                    breakLines:(BOOL)breakLines
                           num:(int)num {
    Move line[800];
    int i = 0;
    
    for (SFMMove *move in movesArray) {
        line[i++] = [[self class] libMoveFromMoveObj:move];
    }
    line[i] = MOVE_NONE;
    
    SFMPosition *copy = [self copy];
    
    if (html) {
        return @(line_to_html(*copy.position, line, num, false).c_str());
    } else {
        return @(line_to_san(*copy.position, line, 0, breakLines, num).c_str());
    }
    
}

- (NSArray* /* of SFMMove */)movesArrayForUci:(NSArray* /* of NSString */)uci {
    
    SFMPosition *current = [self copy];
    NSMutableArray /* of SFMMove */ *moves = [[NSMutableArray alloc] init];
    
    for (NSString *text in uci) {
        Move m = move_from_string(*current.position, [text UTF8String]);
        [moves addObject:[[self class] moveObjFromLibMove:m]];
        [current doMove:[moves lastObject] error:nil];
    }
    
    return moves;
}

+ (NSString *)uciForMovesArray:(NSArray* /* of SFMMove */)movesArray {
    NSMutableString *uci = [[NSMutableString alloc] init];
    
    for (SFMMove *move in movesArray) {
        Move m = [[self class] libMoveFromMoveObj:move];
        [uci appendFormat:@"%@ ", @(move_to_string(m).c_str())];
    }
    
    return uci;
}

# pragma mark - Private

+ (Move)libMoveFromMoveObj:(SFMMove *)moveObj {
    if (moveObj.isPromotion) {
        return make_promotion_move(Square(moveObj.from), Square(moveObj.to),
                                   PieceType(moveObj.promotion));
    } else if (moveObj.isCastle) {
        return make_castle_move(Square(moveObj.from), Square(moveObj.to));
    } else if (moveObj.isEp) {
        return make_ep_move(Square(moveObj.from), Square(moveObj.to));
    } else {
        return make_move(Square(moveObj.from), Square(moveObj.to));
    }
}

+ (SFMMove *)moveObjFromLibMove:(Move)m {
    SFMMove *move = [[SFMMove alloc] initWithFrom:SFMSquare(move_from(m)) to:SFMSquare(move_to(m))];
    
    if (move_promotion(m) != PieceType::NO_PIECE_TYPE) {
        move.isPromotion = YES;
        move.promotion = SFMPieceType(move_promotion(m));
    }
    
    if (move_is_castle(m)) {
        move.isCastle = YES;
    }
    
    if (move_is_ep(m)) {
        move.isEp = YES;
    }
    
    return move;
}

# pragma mark - Getters

- (SFMPiece)pieceOnSquare:(SFMSquare)square {
    return SFMPiece(_position->piece_on(Square(square)));
}

- (NSArray* /* of NSNumber(SFMSquare) */)legalSquaresFromSquare:(SFMSquare)square {
    Move mlist[32];
    Square s = Square(square);
    int total = self.position->moves_from(s, mlist);
    
    NSMutableArray *legalSquares = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < total; i++) {
        // Only include non-promotions and queen promotions, in order to avoid
        // having the same destination squares multiple times in the array.

        if (!move_promotion(mlist[i]) || move_promotion(mlist[i]) == PieceType::QUEEN) {
            // For castling moves, adjust the destination square so that it displays
            // correctly when squares are highlighted in the GUI.
            SFMSquare s;
            if (move_is_long_castle(mlist[i]))
                s = SFMSquare(move_to(mlist[i]) + 2);
            else if (move_is_short_castle(mlist[i]))
                s = SFMSquare(move_to(mlist[i]) - 1);
            else
                s = SFMSquare(move_to(mlist[i]));
            [legalSquares addObject:@(s)];
        }
    }
    
    return legalSquares;
}

- (BOOL)isPromotion:(SFMMove *)move {
    Move mlist[32];
    Square s = Square(move.from);
    int total = self.position->moves_from(s, mlist);
    
    // It is a promotion if there are multiple instances of the destination square
    
    int count = 0;
    
    for (int i = 0; i < total; i++) {
        if (move_to(mlist[i]) == Square(move.to)) {
            count++;
        }
    }
    
    return count > 1;
}

- (NSString *)fen {
    return @(_position->to_fen().c_str());
}

- (BOOL)isMate {
    return _position->is_mate();
}

- (BOOL)isImmediateDraw {
    return _position->is_immediate_draw() != NOT_DRAW;
}

- (SFMColor)sideToMove {
    return SFMColor(_position->side_to_move());
}

- (SFMSquare)enPassantSquare {
    return SFMSquare(self.position->ep_square());
}

- (int)numLegalMoves {
    Move mlist[500];
    return self.position->all_legal_moves(mlist);
}

@end
