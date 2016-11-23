//
//  NSArray+ArrayUtils.h
//  Stockfish
//
//  Created by Daylen Yang on 12/25/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@interface NSArray (ArrayUtils)

- (id)sfm_objectAfterObject:(id)object;

- (NSArray *)sfm_objectsAfterObject:(id)object;

- (NSArray *)sfm_objectsAfterObject:(id)a beforeObject:(id)b;

- (BOOL)sfm_isPrefixOf:(NSArray *)b;

@end
