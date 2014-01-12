//
//  SFMWindowController.h
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SFMPGNFile.h"
#import "SFMBoardViewDelegate.h"

@interface SFMWindowController : NSWindowController <SFMBoardViewDelegate>

@property SFMPGNFile *pgnFile;

@end
