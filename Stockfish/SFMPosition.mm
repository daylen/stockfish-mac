//
//  SFMPosition.m
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPosition.h"
#import "Constants.h"

#include "../Chess/position.h"
#include "../Chess/bitboard.h"
#include "../Chess/direction.h"
#include "../Chess/mersenne.h"
#include "../Chess/movepick.h"
#include "../Chess/san.h"

using namespace Chess;

@interface SFMPosition()

@property (assign, nonatomic) Position *position;

@end

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
    return [[SFMPosition alloc] initWithFen:[self fen]];
}

- (void)dealloc {
    delete _position;
}

#pragma mark - Init

- (instancetype)init {
    return [self initWithFen:FEN_START_POSITION];
}

- (instancetype)initWithFen:(NSString *)fen {
    self = [super init];
    if (self) {
        _position = new Position([fen UTF8String]);
    }
    return self;
}

+ (BOOL)isValidFen:(NSString *)fen {
    return Position::is_valid_fen([fen UTF8String]);
}

# pragma mark - State modification

- (void)doMove:(SFMMove *)move error:(NSError *__autoreleasing *)error {
    Move m = [[self class] libMoveFromMoveObj:move];
    
    Move mlist[500];
    int numLegalMoves = self.position->all_legal_moves(mlist);
    
    BOOL foundLegalMove = NO;
    
    for (int i = 0; i < numLegalMoves; i++) {
        if (mlist[i] == m) {
            foundLegalMove = YES;
            UndoInfo u;
            self.position->do_move(m, u);
        }
    }
    
    if (!foundLegalMove) {
        *error = [NSError errorWithDomain:POSITION_ERROR_DOMAIN code:ILLEGAL_MOVE_CODE userInfo:nil];
    }
}

# pragma mark - Conversion

- (NSArray* /* of SFMMove */)movesArrayForSan:(NSArray* /* of NSString */)san
                                        error:(NSError * __autoreleasing *)error {
    SFMPosition *current = [self copy];
    NSMutableArray /* of SFMMove */ *moves = [[NSMutableArray alloc] init];
    
    for (NSString *text in san) {
        Move m = move_from_san(*current.position, [text UTF8String]);
        if (m == MOVE_NONE) {
            // Error
            *error = [NSError errorWithDomain:POSITION_ERROR_DOMAIN code:PARSE_ERROR_CODE userInfo:nil];
            return nil;
        } else {
            [moves addObject:[[self class] moveObjFromLibMove:m]];
            [current doMove:[moves lastObject] error:nil];
        }
    }
    
    return moves;
}

- (NSString *)sanForMovesArray:(NSArray* /* of SFMMove */)movesArray
                          html:(BOOL)html
                    breakLines:(BOOL)breakLines
                      startNum:(int)startNum {
    Move line[800];
    int i = 0;
    
    for (SFMMove *move in movesArray) {
        line[i++] = [[self class] libMoveFromMoveObj:move];
    }
    line[i] = MOVE_NONE;
    
    SFMPosition *copy = [self copy];
    
    if (html) {
        return [NSString stringWithUTF8String:line_to_html(*copy.position, line, startNum, false).c_str()];
    } else {
        return [NSString stringWithUTF8String:line_to_san(*copy.position, line, 0, breakLines, startNum).c_str()];
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
        [uci appendFormat:@"%@ ", [NSString stringWithUTF8String:move_to_string(m).c_str()]];
    }
    
    return uci;
}

# pragma mark - Private

+ (Move)libMoveFromMoveObj:(SFMMove *)moveObj {
    if (moveObj.isPromotion) {
        return make_promotion_move(Square(moveObj.from), Square(moveObj.to), PieceType(moveObj.promotion));
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

- (NSString *)fen {
    return [NSString stringWithUTF8String:_position->to_fen().c_str()];
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

- (int)numLegalMoves {
    Move mlist[500];
    return self.position->all_legal_moves(mlist);
}

@end
