//
//  SFMWindowController.m
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMWindowController.h"
#import "SFMChessGame.h"
#import "Constants.h"
#import "SFMFormatter.h"
#import "SFMMove.h"
#import "SFMUCILine.h"
#import "SFMPosition.h"

@interface SFMWindowController ()

@property (weak) IBOutlet NSSplitView *mainSplitView;
@property (weak) IBOutlet NSTableView *gameListView;
@property (weak) IBOutlet SFMBoardView *boardView;

// Engine
@property (weak) IBOutlet NSTextField *engineTextField;
@property (weak) IBOutlet NSTextField *engineStatusTextField;
@property (unsafe_unretained) IBOutlet NSTextView *lineTextView;
@property (weak) IBOutlet NSButton *goStopButton;

@property (unsafe_unretained) IBOutlet NSTextView *notationView;

@property int currentGameIndex;
@property SFMChessGame *currentGame;
@property SFMUCIEngine *engine;

@end

@implementation SFMWindowController

#pragma mark - Target/Action
- (IBAction)copyFenString:(id)sender
{
    NSMutableString *fen = [self.currentGame.position.fen mutableCopy];
    [fen appendFormat:@" %lu %lu", (unsigned long)self.currentGame.currentMoveIndex, self.currentGame.currentMoveIndex / 2 + 1];
    [[NSPasteboard generalPasteboard] declareTypes:@[NSPasteboardTypeString] owner:nil];
    [[NSPasteboard generalPasteboard] setString:[fen copy] forType:NSPasteboardTypeString];
    
}
- (IBAction)pasteFenString:(id)sender
{
    // Don't want to deal with multi-game PGN
    if ([self.pgnFile.games count] > 1) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not paste FEN" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please create a new game first."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return;
    }
    
    // Fetch from clipboard
    NSString *fen = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
    fen = [fen stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Validate the FEN string and throw a modal if invalid
    if (![SFMPosition isValidFen:fen]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not paste FEN" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The FEN string is not valid. Edit your FEN string and try again."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return;
    }

    // Insert a new game and reload
    [self.pgnFile.games removeAllObjects];
    [self.pgnFile.games addObject:[[SFMChessGame alloc] initWithFen:fen]];
    self.currentGame = nil;
    [self loadGameAtIndex:0];
    
}
- (IBAction)flipBoard:(id)sender {
    self.boardView.boardIsFlipped = !self.boardView.boardIsFlipped;
}
- (IBAction)previousMove:(id)sender {
    [self.currentGame goBackOneMove];
    [self syncToViewsAndEngine];
}
- (IBAction)nextMove:(id)sender {
    [self.currentGame goForwardOneMove];
    [self syncToViewsAndEngine];
}
- (IBAction)firstMove:(id)sender {
    [self.currentGame goToBeginning];
    [self syncToViewsAndEngine];
}
- (IBAction)lastMove:(id)sender {
    [self.currentGame goToEnd];
    [self syncToViewsAndEngine];
}
- (IBAction)undoLastMove:(id)sender {
    // TODO real undo support
}
- (IBAction)toggleInfiniteAnalysis:(id)sender {
    if (self.engine.isAnalyzing) {
        self.engine.isAnalyzing = NO;
        self.goStopButton.title = @"Go";
    } else {
        self.lineTextView.string = @"";
        [self syncToViewsAndEngine];
        self.engine.isAnalyzing = YES;
        self.goStopButton.title = @"Stop";
    }
}
- (IBAction)doBestMove:(id)sender
{
    if (self.engine.isAnalyzing) {
        [self doMoveWithOverwritePrompt:[self.engine.latestLine.moves firstObject]];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Cannot do best move" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Start Infinite Analysis and then try again."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
    }
}
#pragma mark - Helper methods
- (void)syncToViewsAndEngine
{
    self.boardView.position = [self.currentGame.position copy];
    self.boardView.arrows = nil;

    self.engine.gameToAnalyze = [self.currentGame copy];

    [self updateNotationView];
}

/*!
 Check if the current position is a checkmate or a draw, and display an alert if so.
 */
- (void)checkIfGameOver
{
    if ([self.currentGame.position isMate]) {
        BOOL isWhite = [self.currentGame.position sideToMove] == WHITE;
        NSString *resultText = isWhite ? @"0-1" : @"1-0";
        NSAlert *alert = [NSAlert alertWithMessageText:@"Game over!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat: isWhite ? @"Black wins." : @"White wins."];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [self.currentGame setResult:resultText];
    } else if ([self.currentGame.position isImmediateDraw]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Game over!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"It's a draw."];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [self.currentGame setResult:@"1/2-1/2"];
    }
}
- (void)updateNotationView
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithHTML:[[self.currentGame moveTextString:YES num:(int) self.currentGame.currentMoveIndex] dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
    [str enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, str.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        NSFont *currFont = (NSFont *) value;
        if ([[currFont fontDescriptor] symbolicTraits] & NSFontBoldTrait) {
            [str setAttributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]]} range:range];
        } else {
            [str setAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]]} range:range];

        }
    }];
    [self.notationView.textStorage setAttributedString:[str copy]];
}

#pragma mark - Init
- (void)windowDidLoad
{
    [super windowDidLoad];
    self.boardView.delegate = self;
    self.boardView.dataSource = self;
    
    self.engine = [[SFMUCIEngine alloc] initStockfish];
    self.engine.delegate = self;
    
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
    NSError *error = nil;
    [self.currentGame parseMoveText:&error];
    if (error) {
        [self close];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not open game" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", [error description]];
        [alert runModal];
    }
    
    [self syncToViewsAndEngine];
    
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


#pragma mark - SFMUCIEngineDelegate

- (void)uciEngine:(SFMUCIEngine *)engine didGetEngineName:(NSString *)name {
    self.engineTextField.stringValue = name;
}

- (void)uciEngine:(SFMUCIEngine *)engine didGetNewCurrentMove:(SFMMove *)move number:(NSInteger)moveNumber depth:(NSInteger)depth {
    
    NSMutableArray /* of NSString */ *statusComponents = [[NSMutableArray alloc] init];
    
    // 1. Score
    [statusComponents addObject:[SFMFormatter scoreAsText:(int) engine.latestLine.score isMate:engine.latestLine.scoreIsMateDistance isWhiteToMove:engine.gameToAnalyze.position.sideToMove == WHITE isLowerBound:engine.latestLine.scoreIsLowerBound isUpperBound:engine.latestLine.scoreIsUpperBound]];
    
    // 2. Depth
    [statusComponents addObject:[NSString stringWithFormat:@"Depth=%lu/%lu", engine.latestLine.depth, engine.latestLine.selectiveDepth]];
    
    // 3. Curr Move
    if (move) {
        NSString *san = [engine.gameToAnalyze.position sanForMovesArray:@[move] html:NO breakLines:NO num:(int) engine.gameToAnalyze.currentMoveIndex / 2 + 1];
        [statusComponents addObject:[NSString stringWithFormat:@"%@(%lu/%d)", san, moveNumber, engine.gameToAnalyze.position.numLegalMoves]];
    }
    
    // 4. Speed
    [statusComponents addObject:[NSString stringWithFormat:@"%@/s", [SFMFormatter nodesAsText:engine.latestLine.nodesPerSecond]]];
    
    self.engineStatusTextField.stringValue = [statusComponents componentsJoinedByString:@"    "];
    
}

- (void)uciEngine:(SFMUCIEngine *)engine didGetNewLine:(SFMUCILine *)line {
    // Update the status text
    [self uciEngine:engine didGetNewCurrentMove:nil number:0 depth:line.depth];
    
    // Draw an arrow
    self.boardView.arrows = @[[line.moves firstObject]];
    
    // First line
    NSAttributedString *boldPv  = [[NSAttributedString alloc] initWithString:[engine.gameToAnalyze.position sanForMovesArray:line.moves html:NO breakLines:NO num:(int) engine.gameToAnalyze.currentMoveIndex / 2 + 1] attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]]}];
    
    // Second line
    NSMutableArray /* of NSString */ *statusComponents = [[NSMutableArray alloc] init];
    
    // 1. Score
    [statusComponents addObject:[SFMFormatter scoreAsText:(int) engine.latestLine.score isMate:engine.latestLine.scoreIsMateDistance isWhiteToMove:engine.gameToAnalyze.position.sideToMove == WHITE isLowerBound:engine.latestLine.scoreIsLowerBound isUpperBound:engine.latestLine.scoreIsUpperBound]];
    
    // 2. Depth
    [statusComponents addObject:[NSString stringWithFormat:@"Depth=%lu/%lu", engine.latestLine.depth, engine.latestLine.selectiveDepth]];

    // 3. TB
    if (engine.latestLine.tbHits) {
        [statusComponents addObject:[NSString stringWithFormat:@"TB=%lu", engine.latestLine.tbHits]];
    }
    
    // 4. Time
    [statusComponents addObject:[SFMFormatter millisecondsToClock:engine.latestLine.time]];
    
    // 5. Nodes
    [statusComponents addObject:[SFMFormatter nodesAsText:engine.latestLine.nodes]];
    
    NSAttributedString *secondLine = [[NSAttributedString alloc] initWithString:[statusComponents componentsJoinedByString:@"    "] attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]]}];
    
    NSMutableAttributedString *combined = [[NSMutableAttributedString alloc] init];
    [combined appendAttributedString:boldPv];
    [combined appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [combined appendAttributedString:secondLine];
    
    [self.lineTextView.textStorage setAttributedString:combined];
    
}

#pragma mark - Notifications


- (NSString *)prettyPV:(NSString *)pv
{
    NSArray *tokens = [pv componentsSeparatedByString:@" "];

    return [self.currentGame.position sanForMovesArray:[self.currentGame.position movesArrayForUci:tokens] html:NO breakLines:NO num:(int) self.currentGame.currentMoveIndex / 2 + 1];
}

- (SFMMove *)firstMoveFromPV:(NSString *)pv
{
    return [[self.currentGame.position movesArrayForUci:[pv componentsSeparatedByString:@" "]] firstObject];
}

#pragma mark - SFMBoardViewDelegate

- (void)boardView:(SFMBoardView *)boardView userDidMove:(SFMMove *)move {
    [self doMoveWithOverwritePrompt:move];
    
}

- (void)doMoveWithOverwritePrompt:(SFMMove *)move {
    if (![self.currentGame atEnd]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Overwrite game history?" defaultButton:@"Overwrite" alternateButton:@"Cancel" otherButton:@"Duplicate" informativeTextWithFormat:@"You are not at the end of the game. Click Overwrite to replace the remaining game history with this move.\n\nClick Duplicate to make a copy of this game."];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case 1:
                    // Overwrite
                    [self.currentGame deleteMovesFromPly:self.currentGame.currentMoveIndex];
                    [self doMoveForced:move];
                    break;
                case 0:
                    // Cancel
                    break;
                case -1:
                    // Duplicate
                    [self.document duplicateDocument:nil];
                    break;
            }
        }];
    } else {
        [self doMoveForced:move];
    }
}

- (void)doMoveForced:(SFMMove *)move {
    NSError *error = nil;

    [self.currentGame doMove:move error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return;
    }
    
    [self checkIfGameOver];
    [self.document updateChangeCount:NSChangeDone];
    [self syncToViewsAndEngine];
}

#pragma mark - SFMBoardViewDataSource

- (SFMPieceType)promotionPieceTypeForBoardView:(SFMBoardView *)boardView
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Queen"];
    [alert addButtonWithTitle:@"Rook"];
    [alert addButtonWithTitle:@"Bishop"];
    [alert addButtonWithTitle:@"Knight"];
    [alert setMessageText:@"Pawn Promotion"];
    [alert setInformativeText:@"What would you like to promote your pawn to?"];
    [alert setAlertStyle:NSWarningAlertStyle];
    NSInteger choice = [alert runModal];
    switch (choice) {
        case 1000:
            return QUEEN;
        case 1001:
            return ROOK;
        case 1002:
            return BISHOP;
        case 1003:
            return KNIGHT;
        default:
            return NO_PIECE_TYPE;
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
