//
//  SFMArrowView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/26/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMArrowView.h"
#import "NSBezierPath+Arrowhead.h"

@implementation SFMArrowView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithSRGBRed:1 green:0 blue:0 alpha:0.5] set];
    
    CGFloat arrowLineWidth = self.squareSideLength * 0.2 * self.weight;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithArrowFromPoint:self.fromPoint
                                                            toPoint:self.toPoint
                                                          tailWidth:arrowLineWidth
                                                          headWidth:2.5 * arrowLineWidth
                                                         headLength:2.5 * arrowLineWidth];
    
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
