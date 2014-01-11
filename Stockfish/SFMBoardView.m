//
//  SFMBoardView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/10/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMBoardView.h"

@interface SFMBoardView()

@property NSColor *feltBackground;
@property NSColor *boardColor;
@property NSColor *lightSquareColor;
@property NSColor *darkSquareColor;
@property NSShadow *boardShadow;

@end

@implementation SFMBoardView

#define EXTERIOR_BOARD_MARGIN 40
#define INTERIOR_BOARD_MARGIN 20
#define SHADOW_BLUR_RADIUS 30

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        
        self.feltBackground = [NSColor colorWithPatternImage:[NSImage imageNamed:@"Felt"]];
        
        self.boardColor = [NSColor blackColor];
        self.lightSquareColor = [NSColor whiteColor];
        self.darkSquareColor = [NSColor brownColor];
        
        self.boardShadow = [NSShadow new];
        [self.boardShadow setShadowBlurRadius:SHADOW_BLUR_RADIUS];
        [self.boardShadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.75]]; // Gray
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect
{
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
}

- (BOOL)isFlipped
{
    return YES;
}

@end
