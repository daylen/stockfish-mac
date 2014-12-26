//
//  NSString+StringUtils.m
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "NSString+StringUtils.h"

@implementation NSString (StringUtils)

- (BOOL)sfm_containsString:(NSString *)aString {
    return [self rangeOfString:aString].location != NSNotFound;
}

@end
