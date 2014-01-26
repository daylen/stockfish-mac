//
//  SFMArrowView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/26/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMArrowView.h"

@interface SFMArrowView()

@end

@implementation SFMArrowView

#define ARROW_LINE_WIDTH_AS_PERCENT_OF_SQUARE_WIDTH 0.2;

- (void)drawRect:(NSRect)dirtyRect
{
    // TODO color
    [[NSColor redColor] set];
    
    CGFloat arrowLineWidth = self.squareSideLength * ARROW_LINE_WIDTH_AS_PERCENT_OF_SQUARE_WIDTH;
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    
    // The from point is pretty simple
    [path moveToPoint:NSMakePoint(self.fromPoint.x - 0.5 * arrowLineWidth, self.fromPoint.y)];
    [path lineToPoint:NSMakePoint(self.fromPoint.x + 0.5 * arrowLineWidth, self.fromPoint.y)];
    
    // TODO bug: horizontal lines are invisible
    // TODO bug: bring to front
    // TODO add arrow tip
    [path lineToPoint:NSMakePoint(self.toPoint.x + 0.5 * arrowLineWidth, self.toPoint.y)];
    [path lineToPoint:NSMakePoint(self.toPoint.x - 0.5 * arrowLineWidth, self.toPoint.y)];
    [path closePath];
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
