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

@property (nonatomic, readonly) BOOL isInInitialState;

/**
 * This will update the document window, if one has been
 * created already.
 */
- (void)setPgnFile:(SFMPGNFile * _Nonnull)pgnFile;

@end
