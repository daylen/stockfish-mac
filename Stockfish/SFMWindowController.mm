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
@property (weak) IBOutlet NSTableView *gameListView;
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
    [self.gameListView setDelegate:self];
    [self.gameListView setDataSource:self];
    [self.gameListView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    [self loadGameAtIndex:0];
    [self.gameListView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)loadGameAtIndex:(int)index
{
    self.currentGameIndex = index;
    self.currentGame = self.pgnFile.games[index];
    [self.currentGame populateMovesFromMoveText];
    
    self.boardView.position->copy(*self.currentGame.startPosition);
    [self.boardView updatePieceViews];
}

#pragma mark - SFMBoardViewDelegate

- (Move)doMoveFrom:(Chess::Square)fromSquare to:(Chess::Square)toSquare
{
    return [self doMoveFrom:fromSquare to:toSquare promotion:NO_PIECE_TYPE];
}

- (Chess::Move)doMoveFrom:(Chess::Square)fromSquare to:(Chess::Square)toSquare promotion:(Chess::PieceType)desiredPieceType
{
    // TODO just the first game
    return [self.pgnFile.games[0] doMoveFrom:fromSquare to:toSquare promotion:desiredPieceType];
}

#pragma mark - Table View Delegate Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.pgnFile.games count];
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString* const rowIdentifier = @"CellView";
    NSTableCellView *view = [self.gameListView makeViewWithIdentifier:rowIdentifier owner:self];
    assert(view != nil);
    
    // Poke around in the view to get the label
    id firstSubview = view.subviews[0];
    
    if ([firstSubview isKindOfClass:[NSTextField class]]) {
        // Form what we want to display
        SFMChessGame *game = (SFMChessGame *) self.pgnFile.games[row];
        NSString *toDisplay = [NSString stringWithFormat:@"%@ vs. %@ (Result: %@)", game.tags[@"White"], game.tags[@"Black"], game.tags[@"Result"]];
        
        NSTextField *textField = (NSTextField *) firstSubview;
        [textField setStringValue:toDisplay];
    }
    
    return view;
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self loadGameAtIndex:(int) self.gameListView.selectedRow];
}

@end
