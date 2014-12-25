//
//  SFMItertools.m
//  Stockfish
//
//  Created by Daylen Yang on 12/24/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMItertools.h"

@implementation SFMItertools

+ (NSArray* /* of NSArray */)permutations:(NSArray *)arr length:(int)r {
    // https://docs.python.org/2/library/itertools.html#itertools.combinations

    NSMutableArray *permutations = [[NSMutableArray alloc] init];
    
    if (r > [arr count]) {
        return nil;
    }
    NSMutableArray *indices = [[NSMutableArray alloc] init];
    for (int i = 0; i < [arr count]; i++) {
        [indices addObject:@(i)];
    }
    NSMutableArray *cycles = [[NSMutableArray alloc] init];
    for (int i = (int) [arr count]; i > [arr count] - r; i--) {
        [cycles addObject:@(i)];
    }
    [permutations addObject:[SFMItertools selectIndices:[indices subarrayWithRange:NSMakeRange(0, r)] fromArray:arr]];
    while ([arr count]) {
        BOOL shouldReturn = YES;
        for (int i = r - 1; i >= 0; i--) {
            cycles[i] = @(((NSNumber *)cycles[i]).integerValue - 1);
            if (((NSNumber *)cycles[i]).integerValue == 0) {
                NSMutableArray *tmp = [[indices subarrayWithRange:NSMakeRange(i + 1, [indices count] - (i + 1))] mutableCopy];
                [tmp addObject:indices[i]];
                [indices replaceObjectsInRange:NSMakeRange(i, [indices count] - i) withObjectsFromArray:tmp];
                cycles[i] = @([arr count] - i);
            } else {
                NSInteger j = ((NSNumber *)cycles[i]).integerValue;
                id tmp = indices[[indices count] - j];
                indices[[indices count] - j] = indices[i];
                indices[i] = tmp;
                [permutations addObject:[SFMItertools selectIndices:[indices subarrayWithRange:NSMakeRange(0, r)] fromArray:arr]];
                shouldReturn = NO;
                break;
            }
        }
        if (shouldReturn) {
            return permutations;
        }
    }
    
    return permutations;
}

+ (NSArray* /* of NSArray */)combinations:(NSArray *)arr length:(int)r {
    // https://docs.python.org/2/library/itertools.html#itertools.combinations
    
    NSMutableArray *combinations = [[NSMutableArray alloc] init];
    if (r > [arr count]) {
        return nil;
    }
    NSMutableArray *indices = [[NSMutableArray alloc] init];
    for (int i = 0; i < r; i++) {
        [indices addObject:@(i)];
    }
    [combinations addObject:[SFMItertools selectIndices:indices fromArray:arr]];
    while (YES) {
        int i;
        BOOL shouldReturn = YES;
        for (i = r - 1; i >= 0; i--) {
            if (((NSNumber *)indices[i]).integerValue != i + [arr count] - r) {
                shouldReturn = NO;
                break;
            }
        }
        if (shouldReturn) {
            return combinations;
        }
        indices[i] = @(((NSNumber *)indices[i]).integerValue + 1);
        for (int j = i + 1; j < r; j++) {
            indices[j] = @(((NSNumber *)indices[j-1]).integerValue + 1);
        }
        [combinations addObject:[SFMItertools selectIndices:indices fromArray:arr]];
    }
    
    return combinations;
}

+ (NSArray *)selectIndices:(NSArray *)indices fromArray:(NSArray *)arr {
    NSMutableArray *filtered = [[NSMutableArray alloc] init];
    
    for (NSNumber *idx in indices) {
        [filtered addObject:arr[idx.integerValue]];
    }
    
    return filtered;
}

@end
