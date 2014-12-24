//
//  SFMPiece.h
//  Stockfish
//
//  Created by Daylen Yang on 12/23/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#ifndef Stockfish_SFMPiece_h
#define Stockfish_SFMPiece_h

// Defined in piece.h
typedef NS_ENUM(NSInteger, SFMPiece) {
    NO_PIECE = 0, WP = 1, WN = 2, WB = 3, WR = 4, WQ = 5, WK = 6,
    BP = 9, BN = 10, BB = 11, BR = 12, BQ = 13, BK = 14,
    EMPTY = 16, OUTSIDE = 17
};

// Defined in piece.h
typedef NS_ENUM(NSInteger, SFMPieceType) {
    NO_PIECE_TYPE = 0,
    PAWN = 1, KNIGHT = 2, BISHOP = 3, ROOK = 4, QUEEN = 5, KING = 6
};

#endif
