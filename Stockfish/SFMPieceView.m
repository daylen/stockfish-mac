//
//  SFMPieceView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPieceView.h"

@implementation SFMPieceView

- (void)setPiece:(SFMPiece)piece {
    _piece = piece;
    [self setImage:[NSImage imageNamed:[SFMPieceView fileNameForPiece:_piece]]];
}

+ (NSString *)fileNameForPiece:(SFMPiece)piece
{
    switch (piece) {
        case WP:
            return @"pawn_w";
        case WN:
            return @"knight_w";
        case WB:
            return @"bishop_w";
        case WR:
            return @"rook_w";
        case WQ:
            return @"queen_w";
        case WK:
            return @"king_w";
        case BP:
            return @"pawn_b";
        case BN:
            return @"knight_b";
        case BB:
            return @"bishop_b";
        case BR:
            return @"rook_b";
        case BQ:
            return @"queen_b";
        case BK:
            return @"king_b";
        default:
            return @"";
    }
}

@end
