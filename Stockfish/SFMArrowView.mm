//
//  SFMArrowView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/26/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMArrowView.h"
#import "NSBezierPath+Arrowhead.h"

@interface SFMArrowView()

@end

@implementation SFMArrowView

#define ARROW_LINE_WIDTH_AS_PERCENT_OF_SQUARE_WIDTH 0.2;

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.fromSquare == self.toSquare) {
        return;
    }
    
    [[NSColor colorWithSRGBRed:1 green:0 blue:0 alpha:0.5] set];
    
    CGFloat arrowLineWidth = self.squareSideLength * ARROW_LINE_WIDTH_AS_PERCENT_OF_SQUARE_WIDTH;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithArrowFromPoint:self.fromPoint toPoint:self.toPoint tailWidth:arrowLineWidth headWidth:2.5 * arrowLineWidth headLength:2.5 * arrowLineWidth];
    
    [path fill];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    return nil;
}

- (BOOL)isFlipped
{
    return YES;
}

@end
