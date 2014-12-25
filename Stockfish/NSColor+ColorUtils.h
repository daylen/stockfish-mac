//
//  NSColor+ColorUtils.h
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (ColorUtils)

+ (NSColor *)colorWithHex:(int)hex alpha:(CGFloat)alpha;

@end
