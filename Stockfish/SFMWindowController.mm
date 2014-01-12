//
//  SFMWindowController.m
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMWindowController.h"
#import "SFMBoardView.h"
#import "SFMChessGame.h"

@interface SFMWindowController ()
@property (weak) IBOutlet SFMBoardView *boardView;

@end

@implementation SFMWindowController

- (IBAction)flipBoard:(id)sender {
    self.boardView.boardIsFlipped = !self.boardView.boardIsFlipped;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Load the first game from the PGN file for now
        SFMChessGame *firstGame = self.pgnFile.games[0];
        
        self.boardView.position = firstGame.startPosition;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    

}

@end
