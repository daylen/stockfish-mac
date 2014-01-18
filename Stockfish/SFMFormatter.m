//
//  SFMFormatter.m
//  Stockfish
//
//  Created by Daylen Yang on 1/17/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMFormatter.h"

@implementation SFMFormatter

+ (NSString *)scoreAsText:(int)score isMate:(BOOL)isMate isWhiteToMove:(BOOL)whiteToMove
{
    NSMutableString *str = [NSMutableString new];
    
    // Determine the sign
    if (score > 0) {
        if (whiteToMove) {
            // white is winning
            [str appendString:@"+"];
        } else {
            // black is winning
            [str appendString:@"-"];
        }
    } else if (score < 0) {
        if (whiteToMove) {
            // black is winning
            [str appendString:@"-"];
        } else {
            // white is winning
            [str appendString:@"+"];
        }
    } else {
        [str appendString:@"="];
    }
    [str appendString:@" ("];
    if (isMate) {
        [str appendFormat:@"#%d)", ABS(score)];
    } else {
        [str appendFormat:@"%.2f)", ABS(score) / 100.0];
    }
    
    return [str copy];
}
+ (NSString *)nodesAsText:(NSString *)nodes
{
    if ([nodes length] <= 4) {
        // Just nodes
        return [NSString stringWithFormat:@"%@ N", nodes];
    } else if ([nodes length] <= 7) {
        // Kilonodes
        return [NSString stringWithFormat:@"%@ kN", [nodes substringToIndex:[nodes length] - 3]];
    } else {
        // Meganodes
        return [NSString stringWithFormat:@"%@ MN", [nodes substringToIndex:[nodes length] - 6]];
    }
}

@end
