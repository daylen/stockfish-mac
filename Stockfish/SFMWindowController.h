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
#import "SFMChessGame.h"

@interface SFMWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, NSTextViewDelegate, SFMBoardViewDataSource, SFMBoardViewDelegate, SFMUCIEngineDelegate, SFMChessGameDelegate>

@property SFMPGNFile *pgnFile;

- (void)handlePGNFile;

@end
