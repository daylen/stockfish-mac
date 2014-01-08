//
//  SFMPGNFile.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMPGNFile : NSObject

#pragma mark - Properties
@property NSMutableArray *games;

#pragma mark - Init
- (id)init; // Init a blank PGN
- (id)initWithData:(NSData *)data; // Init with given PGN data

#pragma mark - Export
- (NSData *)data; // Returns the PGN

@end
