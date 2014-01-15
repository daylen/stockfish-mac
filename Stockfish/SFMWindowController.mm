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
@property (weak) IBOutlet NSSplitView *mainSplitView;
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
    
    // Decide whether to show or hide the game sidebar
    if ([self.pgnFile.games count] > 1) {
        [self.gameListView setDelegate:self];
        [self.gameListView setDataSource:self];
        [self.gameListView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    } else {
        [self.mainSplitView.subviews[0] removeFromSuperview];
    }
    
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
    Move m = [self.currentGame doMoveFrom:fromSquare to:toSquare promotion:desiredPieceType];
    [self checkIfGameOver];
    return m;
}

- (void)checkIfGameOver
{
    if (self.currentGame.currPosition->is_mate()) {
        NSString *resultText = (self.currentGame.currPosition->side_to_move() == WHITE) ? @"0-1" : @"1-0";
        NSAlert *alert = [NSAlert alertWithMessageText:@"Game over!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:(self.currentGame.currPosition->side_to_move() == WHITE) ? @"Black wins." : @"White wins."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        self.currentGame.tags[@"Result"] = resultText;
    } else if (self.currentGame.currPosition->is_immediate_draw()) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Game over!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"It's a draw."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        self.currentGame.tags[@"Result"] = @"1/2-1/2";
    }
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
    
    SFMChessGame *game = (SFMChessGame *) self.pgnFile.games[row];
    
    // Poke around in the view
    NSTextField *white = (NSTextField *) view.subviews[0];
    NSTextField *black = (NSTextField *) view.subviews[1];
    NSTextField *result = (NSTextField *) view.subviews[2];
    
    white.stringValue = [NSString stringWithFormat:@"White: %@", game.tags[@"White"]];
    black.stringValue = [NSString stringWithFormat:@"Black: %@", game.tags[@"Black"]];
    result.stringValue = [NSString stringWithFormat:@"Result: %@", game.tags[@"Result"]];
    return view;
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self loadGameAtIndex:(int) self.gameListView.selectedRow];
}

@end
