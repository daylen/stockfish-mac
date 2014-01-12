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
        // Nothing
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    SFMChessGame *firstGame = self.pgnFile.games[0];
    
    self.boardView.position = firstGame.startPosition;
    [self.boardView setDelegate:self];

}

#pragma mark - Delegate methods

- (Move)doMoveFrom:(Chess::Square)fromSquare to:(Chess::Square)toSquare
{
    return [self doMoveFrom:fromSquare to:toSquare promotion:NO_PIECE_TYPE];
}

- (Chess::Move)doMoveFrom:(Chess::Square)fromSquare to:(Chess::Square)toSquare promotion:(Chess::PieceType)desiredPieceType
{
    // TODO just the first game
    return [self.pgnFile.games[0] doMoveFrom:fromSquare to:toSquare promotion:desiredPieceType];
}

@end
