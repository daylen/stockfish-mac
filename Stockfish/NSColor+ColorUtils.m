//
//  NSColor+ColorUtils.m
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "NSColor+ColorUtils.h"

@implementation NSColor (ColorUtils)

+ (NSColor *)colorWithHex:(int)hex alpha:(CGFloat)alpha {
    int red = (hex >> 16) & 0xff;
    int green = (hex >> 8) & 0xff;
    int blue = hex & 0xff;
    
    return [NSColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
}

@end
