//
//  SFMWindowController.h
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPGNFile.h"
#import "SFMBoardView.h"
#import "SFMUCIEngine.h"

@interface SFMWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, SFMBoardViewDataSource, SFMBoardViewDelegate, SFMUCIEngineDelegate>

@property SFMPGNFile *pgnFile;

@end
