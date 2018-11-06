//
//  SFMDocument.h
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SFMPGNFile;

@interface SFMDocument : NSDocument

/**
 * Only call this before creating the document window,
 * otherwise things are going to get messy.
 */
- (void)setPgnFile:(SFMPGNFile * _Nonnull)pgnFile;

@end
