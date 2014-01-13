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
@property int currentGameIndex;
@property SFMChessGame *currentGame;

@end

@implementation SFMWindowController

#pragma mark - Interactions
- (IBAction)flipBoard:(id)sender {
    self.boardView.boardIsFlipped = !self.boardView.boardIsFlipped;
}
- (IBAction)previousMove:(id)sender {
    [self.currentGame goBackOneMove];
    self.boardView.position->copy(*self.currentGame.currPosition);
    [self.boardView updatePieceViews];
}
- (IBAction)nextMove:(id)sender {
    [self.currentGame goForwardOneMove];
    self.boardView.position->copy(*self.currentGame.currPosition);
    [self.boardView updatePieceViews];
}
- (IBAction)previousGame:(id)sender {
    int smallerIndex = MAX(0, self.currentGameIndex - 1);
    if (smallerIndex != self.currentGameIndex) {
        [self loadGameAtIndex:smallerIndex];
    }
}
- (IBAction)nextGame:(id)sender {
    int biggerIndex = MIN(self.currentGameIndex + 1, (int) [self.pgnFile.games count] - 1);
    if (biggerIndex != self.currentGameIndex) {
        [self loadGameAtIndex:biggerIndex];
    }
}

#pragma mark - Init
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
    [self.boardView setDelegate:self];
    [self loadGameAtIndex:0];
}

- (void)loadGameAtIndex:(int)index
{
    self.currentGameIndex = index;
    self.currentGame = self.pgnFile.games[index];
    [self.currentGame populateMovesFromMoveText];
    
    self.boardView.position->copy(*self.currentGame.startPosition);
    [self.boardView updatePieceViews];
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
