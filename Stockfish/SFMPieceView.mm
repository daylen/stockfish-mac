//
//  SFMPieceView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPieceView.h"

#define PIECE_SHADOW_BLUR_RADIUS 5

@implementation SFMPieceView

- (id)initWithFrame:(NSRect)frameRect pieceType:(Chess::Piece)pieceType
{
    self = [super initWithFrame:frameRect];
    if (self) {
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowBlurRadius:PIECE_SHADOW_BLUR_RADIUS];
        [shadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.5]]; // Gray
        [self setShadow:shadow];

        NSString *name = [SFMPieceView fileNameForPieceType:pieceType];
        [self setImage:[NSImage imageNamed:name]];
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

- (void)mouseUp:(NSEvent *)theEvent
{
    int letter = self.square % 8;
    int number = self.square / 8;
    NSLog(@"Clicked a piece on square: %c%d", 'a'+letter, number+1);
}

@end
