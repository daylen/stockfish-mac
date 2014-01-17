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
#import "SFMUCIEngine.h"
#import "Constants.h"
#import "SFMChessMove.h"

#include "../Chess/san.h"

@interface SFMWindowController ()

@property (weak) IBOutlet NSSplitView *mainSplitView;
@property (weak) IBOutlet NSTableView *gameListView;
@property (weak) IBOutlet SFMBoardView *boardView;

@property (weak) IBOutlet NSTextField *engineTextField;
@property (weak) IBOutlet NSTextField *engineStatusTextField;
@property (unsafe_unretained) IBOutlet NSTextView *lineTextView;
@property (weak) IBOutlet NSButton *goStopButton;

@property int currentGameIndex;
@property SFMChessGame *currentGame;
@property SFMUCIEngine *engine;
@property BOOL wantsAnalysis;

@end

using namespace Chess;

@implementation SFMWindowController

#pragma mark - Target/Action
- (IBAction)flipBoard:(id)sender {
    self.boardView.boardIsFlipped = !self.boardView.boardIsFlipped;
}
- (IBAction)previousMove:(id)sender {
    [self.currentGame goBackOneMove];
    [self syncModelWithView];
}
- (IBAction)nextMove:(id)sender {
    [self.currentGame goForwardOneMove];
    [self syncModelWithView];
}
- (IBAction)firstMove:(id)sender
{
    [self.currentGame goToBeginning];
    [self syncModelWithView];
}
- (IBAction)lastMove:(id)sender
{
    [self.currentGame goToEnd];
    [self syncModelWithView];
}
- (IBAction)toggleInfiniteAnalysis:(id)sender {
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
    } else {
        [self sendPositionToEngine];
    }
}
#pragma mark - Helper methods
- (void)syncModelWithView
{
    self.boardView.position->copy(*self.currentGame.currPosition);
    [self.boardView updatePieceViews];
    if (self.engine.isAnalyzing) {
        [self sendPositionToEngine];
    }
}
- (void)sendPositionToEngine
{
    self.lineTextView.string = @"";
    [self.engine stopSearch];
    [self.engine sendCommandToEngine:self.currentGame.uciPositionString];
    [self.engine startInfiniteAnalysis];
    self.goStopButton.title = @"Stop";
}
- (void)stopAnalysis
{
    self.wantsAnalysis = NO;
    self.goStopButton.title = @"Go";
    [self.engine stopSearch];
}
- (NSString *)movesArrayAsString:(NSArray *)movesArray
{
    Move line[800];
    int i = 0;
    
    for (SFMChessMove *move in movesArray) {
        line[i++] = move.move;
    }
    line[i] = MOVE_NONE;
    
    return [NSString stringWithUTF8String:line_to_san(*self.currentGame.currPosition, line, 0, false, self.currentGame.currentMoveIndex / 2 + 1).c_str()];
}
/*
 Check if the current position is a checkmate or a draw, and display an alert if so.
 */
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

#pragma mark - Init
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
    
    // Subscribe to notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:ENGINE_NAME_AVAILABLE_NOTIFICATION object:self.engine queue:nil usingBlock:^(NSNotification *note) {
        self.engineTextField.stringValue = self.engine.engineName;
    }];
    [self subscribeToNotifications:YES];
    self.wantsAnalysis = NO;
    self.engine = [[SFMUCIEngine alloc] initStockfish];
    
}

- (void)subscribeToNotifications:(BOOL)shouldSubscribe
{
    if (shouldSubscribe) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAnalysisLine:) name:ENGINE_NEW_LINE_AVAILABLE_NOTIFICATION object:self.engine];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEngineStatus:) name:ENGINE_CURRENT_MOVE_CHANGED_NOTIFICATION object:self.engine];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedBestMove:) name:ENGINE_BEST_MOVE_AVAILABLE_NOTIFICATION object:self.engine];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)loadGameAtIndex:(int)index
{
    self.currentGameIndex = index;
    self.currentGame = self.pgnFile.games[index];
    [self.currentGame populateMovesFromMoveText];
    [self syncModelWithView];
}

#pragma mark - Menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(toggleInfiniteAnalysis:)) {
        if (self.engine.isAnalyzing) {
            [menuItem setTitle:@"Stop Infinite Analysis"];
        } else {
            [menuItem setTitle:@"Start Infinite Analysis"];
        }
    }
    return YES;
}

#pragma mark - Notifications
- (void)updateEngineStatus:(NSNotification *)notification
{
    NSLog(@"Updating engine status");
    //self.engineStatusTextField.value = self.engine.currentInfo[@"currmove"];
}

- (void)addAnalysisLine:(NSNotification *)notification
{
    if (!self.engine.isAnalyzing) {
        return;
    }
    NSDictionary *data = [self.engine.lineHistory lastObject];
    NSString *currentlyBeingShown = self.lineTextView.string;
    NSArray *pvFromToText = [data[@"pv"] componentsSeparatedByString:@" "];
    NSMutableArray *pvMacMoveObjects = [NSMutableArray new];
    
    Position *tmpPos = new Position;
    tmpPos->copy(*self.currentGame.currPosition);
    
    for (NSString *fromTo in pvFromToText) {
        if ([fromTo length] < 4) {
            NSLog(@"%@ is not a move!", fromTo);
            return;
        }
        Move m = move_from_string(*tmpPos, [fromTo UTF8String]);
        UndoInfo u;
        SFMChessMove *moveObject = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
        tmpPos->do_move(m, u);
        [pvMacMoveObjects addObject:moveObject];
    }
    
    NSString *niceOutput = [self movesArrayAsString:pvMacMoveObjects];
    
    self.lineTextView.string = [NSString stringWithFormat:@"%@\n%@", currentlyBeingShown, niceOutput];
    [self.lineTextView scrollToEndOfDocument:self];
}

- (void)receivedBestMove:(NSNotification *)notification
{
    if (self.wantsAnalysis) {
        [self sendPositionToEngine];
    }
}

#pragma mark - SFMBoardViewDelegate

- (Move)doMoveFrom:(Chess::Square)fromSquare to:(Chess::Square)toSquare
{
    return [self doMoveFrom:fromSquare to:toSquare promotion:NO_PIECE_TYPE];
}

- (Chess::Move)doMoveFrom:(Chess::Square)fromSquare to:(Chess::Square)toSquare promotion:(Chess::PieceType)desiredPieceType
{
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
    }
    Move m = [self.currentGame doMoveFrom:fromSquare to:toSquare promotion:desiredPieceType];
    [self checkIfGameOver];
    return m;
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
