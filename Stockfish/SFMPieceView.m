//
//  SFMPieceView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "Constants.h"
#import "SFMPieceView.h"
#import <QuartzCore/CAMediaTimingFunction.h>

@implementation SFMPieceView

- (id)initWithPiece:(SFMPiece)piece
               onSquare:(SFMSquare)square
{
    self = [super initWithFrame:NSMakeRect(0, 0, 0, 0)];
    if (self) {
        NSString *name = [SFMPieceView fileNameForPiece:piece];
        [self setImage:[NSImage imageNamed:name]];
        
        self.square = square;
        
    }
    return self;
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

- (void)moveTo:(NSPoint)point
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.23 :1 :0.32 :1]];
    [[self animator] setFrameOrigin:point];
    [NSAnimationContext endGrouping];
}

@end
