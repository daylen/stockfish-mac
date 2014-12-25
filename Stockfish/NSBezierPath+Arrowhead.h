//
//  NSBezierPath+Arrowhead.h
//  Stockfish
//
//  Created by Daylen Yang on 1/26/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@interface NSBezierPath (Arrowhead)

+ (NSBezierPath *)bezierPathWithArrowFromPoint:(CGPoint)startPoint
                                       toPoint:(CGPoint)endPoint
                                     tailWidth:(CGFloat)tailWidth
                                     headWidth:(CGFloat)headWidth
                                    headLength:(CGFloat)headLength;

@end
