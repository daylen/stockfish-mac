//
//  NSArray+ArrayUtils.m
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "NSArray+ArrayUtils.h"

@implementation NSArray (ArrayUtils)

- (id)sfm_objectAfterObject:(id)object {
    NSInteger index = [self indexOfObject:object];
    if (index == NSNotFound || index + 1 == [self count]) {
        return nil;
    }
    return self[index + 1];
}

- (NSArray *)sfm_objectsAfterObject:(id)object {
    NSInteger index = [self indexOfObject:object];
    if (index == NSNotFound) {
        return nil;
    }
    return [self subarrayWithRange:NSMakeRange(index + 1, [self count] - (index + 1))];
}

- (NSArray *)sfm_objectsAfterObject:(id)a beforeObject:(id)b {
    NSInteger idxA = [self indexOfObject:a];
    NSInteger idxB = [self indexOfObject:b];
    if (idxA == NSNotFound || idxB == NSNotFound) {
        return nil;
    }
    return [self subarrayWithRange:NSMakeRange(idxA + 1, idxB - idxA - 1)];
}

- (BOOL)sfm_isPrefixOf:(NSArray *)b {
    if (self.count > b.count) {
        return NO;
    }
    for (int i = 0; i < self.count; i++) {
        if (![self[i] isEqual:b[i]]) {
            return NO;
        }
    }
    return YES;
}

@end
