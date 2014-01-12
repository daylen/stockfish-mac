//
//  SFMBoardView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/10/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMBoardView.h"
#import "Constants.h"
#import "SFMPieceView.h"

#include "../Chess/square.h"

@interface SFMBoardView()

@property NSColor *feltBackground;
@property NSColor *boardColor;
@property NSColor *lightSquareColor;
@property NSColor *darkSquareColor;
@property NSColor *fontColor;
@property NSShadow *boardShadow;

@end

@implementation SFMBoardView

#define EXTERIOR_BOARD_MARGIN 40
#define INTERIOR_BOARD_MARGIN 20
#define BOARD_SHADOW_BLUR_RADIUS 30
#define FONT_SIZE 12

- (void)setPosition:(Chess::Position *)position
{
    _position = position;
    
    
    [self setNeedsDisplay:YES];
}

- (void)setBoardIsFlipped:(BOOL)boardIsFlipped
{
    _boardIsFlipped = boardIsFlipped;
    [self setNeedsDisplay:YES];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        
        self.boardIsFlipped = NO;
        
        self.feltBackground = [NSColor colorWithPatternImage:[NSImage imageNamed:@"Felt"]];
        
        self.boardColor = [NSColor blackColor];
        self.lightSquareColor = [NSColor whiteColor];
        self.darkSquareColor = [NSColor brownColor];
        self.fontColor = [NSColor whiteColor];
        
        self.boardShadow = [NSShadow new];
        [self.boardShadow setShadowBlurRadius:BOARD_SHADOW_BLUR_RADIUS];
        [self.boardShadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.75]]; // Gray
        
        // TODO REMOVE:
        self.position = new Position([FEN_START_POSITION UTF8String]);
    }
    return self;
}



- (void)drawPiecesWithLeft:(CGFloat)left top:(CGFloat)top side:(CGFloat)sideLength
{
    if (self.position) {
        for (Square sq = SQ_A1; sq <= SQ_H8; sq++) {
            //Square s = self.boardIsFlipped ? Square(SQ_H8 - sq) : sq;
            Piece p = self.position->piece_on(sq);
            if (p != EMPTY) {
                int letter = sq % 8;
                int number = sq / 8;
                CGFloat l, t;
                if (self.boardIsFlipped) {
                    l = left + (7 - letter) * sideLength;
                    t = top + number * sideLength;
                } else {
                    l = left + letter * sideLength;
                    t = top + (7 - number) * sideLength;
                }
                
                
                
                SFMPieceView *pieceView = [[SFMPieceView alloc] initWithFrame:NSMakeRect(l, t, sideLength, sideLength) pieceType:p];
                pieceView.square = sq;
                
                [self addSubview:pieceView];
            }
        }
    }
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Remove subviews
    [self setSubviews:[NSArray new]];
    
    // Draw a felt background
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [self.feltBackground set];
    NSRectFill([self bounds]);
    [context restoreGraphicsState];
    
    // Draw the big square
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    
    [self.boardColor set];
    [self.boardShadow set];
    
    CGFloat left = (width - boardSideLength) / 2;
    CGFloat top = (height - boardSideLength) / 2;
    
    NSRectFill(NSMakeRect(left, top, boardSideLength, boardSideLength));
    [[NSShadow new] set];
    
    CGFloat leftInset = left + INTERIOR_BOARD_MARGIN;
    CGFloat topInset = top + INTERIOR_BOARD_MARGIN;
    CGFloat squareSideLength = (boardSideLength - 2 * INTERIOR_BOARD_MARGIN) / 8;
    
    // Draw 64 squares
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            if ((i + j) % 2 == 0) {
                [self.lightSquareColor set];
            } else {
                [self.darkSquareColor set];
            }
            NSRectFill(NSMakeRect(leftInset + i * squareSideLength, topInset + j * squareSideLength, squareSideLength, squareSideLength));
        }
    }
    
    // Draw coordinates
    NSString *str = [NSString new];
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [pStyle setAlignment:NSCenterTextAlignment];
    
    for (int i = 0; i < 8; i++) {
        // Down
        str = [NSString stringWithFormat:@"%d", self.boardIsFlipped ? (i + 1) : (8 - i)];
        [str drawInRect:NSMakeRect(left, topInset + squareSideLength / 2 - FONT_SIZE / 2 + i * squareSideLength, INTERIOR_BOARD_MARGIN, squareSideLength) withAttributes:@{NSParagraphStyleAttributeName: pStyle, NSForegroundColorAttributeName: self.fontColor}];
        // Across
        str = [NSString stringWithFormat:@"%c", self.boardIsFlipped ? ('h' - i) : ('a' + i)];
        [str drawInRect:NSMakeRect(leftInset + i * squareSideLength, topInset + 8 * squareSideLength, squareSideLength, INTERIOR_BOARD_MARGIN) withAttributes:@{NSParagraphStyleAttributeName: pStyle, NSForegroundColorAttributeName: self.fontColor}];
    }
    
    [self drawPiecesWithLeft:leftInset top:topInset side:squareSideLength];
    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSLog(@"Clicked the board");
}

- (void)dealloc
{
    delete self.position;
}

- (BOOL)isFlipped
{
    return YES;
}

@end
