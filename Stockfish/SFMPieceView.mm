//
//  SFMPieceView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPieceView.h"
#import <QuartzCore/CAMediaTimingFunction.h>

@interface SFMPieceView()

@property SFMBoardView* boardView;

@end

#define PIECE_SHADOW_BLUR_RADIUS 5

@implementation SFMPieceView

- (id)initWithPieceType:(Chess::Piece)pieceType
               onSquare:(Chess::Square)square
              boardView:(SFMBoardView *)boardView
{
    self = [super initWithFrame:NSMakeRect(0, 0, 0, 0)];
    if (self) {
        NSString *name = [SFMPieceView fileNameForPieceType:pieceType];
        [self setImage:[NSImage imageNamed:name]];
        
        self.square = square;
        self.boardView = boardView;
        
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowBlurRadius:PIECE_SHADOW_BLUR_RADIUS];
        [shadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.5]]; // Gray
        [self setShadow:shadow];
    }
    return self;
}

+ (NSString *)fileNameForPieceType:(Chess::Piece)pieceType
{
    static NSDictionary *names = @{[NSNumber numberWithInt:WP]: @"pawn_w",
                                   [NSNumber numberWithInt:WN]: @"knight_w",
                                   [NSNumber numberWithInt:WB]: @"bishop_w",
                                   [NSNumber numberWithInt:WR]: @"rook_w",
                                   [NSNumber numberWithInt:WQ]: @"queen_w",
                                   [NSNumber numberWithInt:WK]: @"king_w",
                                   [NSNumber numberWithInt:BP]: @"pawn_b",
                                   [NSNumber numberWithInt:BN]: @"knight_b",
                                   [NSNumber numberWithInt:BB]: @"bishop_b",
                                   [NSNumber numberWithInt:BR]: @"rook_b",
                                   [NSNumber numberWithInt:BQ]: @"queen_b",
                                   [NSNumber numberWithInt:BK]: @"king_b"};
    return names[[NSNumber numberWithInt:pieceType]];
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
