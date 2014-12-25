//
//  SFMWindowController.m
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMWindowController.h"
#import "SFMChessGame.h"
#import "SFMUCIEngine.h"
#import "Constants.h"
#import "SFMFormatter.h"
#import "SFMMove.h"

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
@property BOOL wantsAnalysis;

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
        [alert runModal];
        return;
    }
    
    // Fetch from clipboard
    NSString *fen = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
    fen = [fen stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Validate the FEN string and throw a modal if invalid
    if (![SFMPosition isValidFen:fen]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not paste FEN" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The FEN string is not valid."];
        [alert runModal];
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
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
    }
    [self.currentGame goBackOneMove];
    [self syncModelWithView];
}
- (IBAction)nextMove:(id)sender {
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
    }
    [self.currentGame goForwardOneMove];
    [self syncModelWithView];
}
- (IBAction)firstMove:(id)sender
{
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
    }
    [self.currentGame goToBeginning];
    [self syncModelWithView];
}
- (IBAction)lastMove:(id)sender
{
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
    }
    [self.currentGame goToEnd];
    [self syncModelWithView];
}
- (IBAction)undoLastMove:(id)sender {
    // TODO real undo support
}
- (IBAction)toggleInfiniteAnalysis:(id)sender {
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
    } else {
        [self sendPositionToEngine];
    }
}
- (IBAction)doBestMove:(id)sender
{
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
        NSString *pv = [self.engine.lineHistory lastObject][@"pv"];
        SFMMove *m = [self firstMoveFromPV:pv];
        [self.currentGame doMove:m error:nil];
        [self checkIfGameOver];
        [self syncModelWithView];
    }
}
#pragma mark - Helper methods
- (void)syncModelWithView
{
    self.boardView.position = [self.currentGame.position copy];
    self.boardView.arrows = nil;
    [self updateNotationView];
}
- (void)sendPositionToEngine
{
    self.lineTextView.string = @"";
    [self.engine stopSearch];
    [self.engine sendCommandToEngine:self.currentGame.uciString];
    [self.engine startInfiniteAnalysis];
    self.goStopButton.title = @"Stop";
}
- (void)stopAnalysis
{
    self.wantsAnalysis = NO;
    self.goStopButton.title = @"Go";
    [self.engine stopSearch];
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEngineName:) name:ENGINE_NAME_AVAILABLE_NOTIFICATION object:self.engine];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)loadGameAtIndex:(int)index
{
    [self stopAnalysis];
    self.currentGameIndex = index;
    self.currentGame = self.pgnFile.games[index];
    NSError *error = nil;
    [self.currentGame parseMoveText:&error];
    if (error) {
        [self close];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not open game" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", [error description]];
        [alert runModal];
    }
    
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
- (void)updateEngineName:(NSNotification *)notification
{
    if (self.engine.engineName != nil && [self.engine.engineName length] > 0) {
        self.engineTextField.stringValue = self.engine.engineName;
    }
}
- (void)updateEngineStatus:(NSNotification *)notification
{
    if (!self.engine.isAnalyzing) {
        return;
    }
    NSMutableString *statusText = [NSMutableString new];
    NSDictionary *latestPV = [self.engine.lineHistory lastObject];
    
    [statusText appendString:[self scoreForPV:latestPV]];
    
    [statusText appendString:@"    Depth="];
    
    // The depth
    if ((self.engine.currentInfo)[@"depth"]) {
        [statusText appendFormat:@"%d", [self.engine.currentInfo[@"depth"] intValue]];
    } else {
        [statusText appendFormat:@"%d", [latestPV[@"depth"] intValue]];
    }
    // The selective depth
    [statusText appendFormat:@"/%d    ", [latestPV[@"seldepth"] intValue]];
    
    // The current move
    if (self.engine.currentInfo[@"currmove"]) {
        int numLegalMoves = self.currentGame.position.numLegalMoves;
        
        NSError *error = nil;
        NSArray *moves = [self.currentGame.position movesArrayForUci:@[self.engine.currentInfo[@"currmove"]]];
        
        if (error) {
            NSLog(@"%@", [error description]);
            return;
        }
        
        [statusText appendFormat:@"%@(%@/%d)    ", [self.currentGame.position sanForMovesArray:moves html:NO breakLines:NO num:(int) self.currentGame.currentMoveIndex / 2 + 1], self.engine.currentInfo[@"currmovenumber"], numLegalMoves];
    }
    
    // The speed
    [statusText appendFormat:@"%@/s", [SFMFormatter nodesAsText:latestPV[@"nps"]]];
    
    self.engineStatusTextField.stringValue = [statusText copy];
}

- (NSString *)scoreForPV:(NSDictionary *)pv
{
    BOOL isLowerBound = pv[@"lowerbound"] != nil;
    BOOL isUpperBound = pv[@"upperbound"] != nil;
    
    // The score
    if (pv[@"cp"]) {
        int score = [pv[@"cp"] intValue];
        
        NSString *theScore = [SFMFormatter scoreAsText:score isMate:NO isWhiteToMove:self.currentGame.position.sideToMove == WHITE isLowerBound:isLowerBound isUpperBound:isUpperBound];
        
        return theScore;
        
    } else if (pv[@"mate"]) {
        int score = [pv[@"mate"] intValue];
        
        NSString *theScore = [SFMFormatter scoreAsText:score isMate:YES isWhiteToMove:self.currentGame.position.sideToMove == WHITE isLowerBound:isLowerBound isUpperBound:isUpperBound];
        
        return theScore;
    } else {
        return @""; // this shouldn't be reached anyway
    }
}

/*
 Adds an analysis line to the text view. Specifically, adds the PV as SAN and search info.
 */
- (void)addAnalysisLine:(NSNotification *)notification
{
    if (!self.engine.isAnalyzing) {
        // The engine isn't analyzing, so the view shouldn't be updated
        return;
    }
    // Also update the status text
    [self updateEngineStatus:nil];
    
    NSDictionary *data = [self.engine.lineHistory lastObject];
    
    // Get the attributed string out of the view
    NSMutableAttributedString *viewText = [self.lineTextView.attributedString mutableCopy];
    [viewText addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, viewText.length)];
    
    NSAttributedString *pvBold = [[NSAttributedString alloc] initWithString:[self prettyPV:data[@"pv"]] attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]]}];
    
    [viewText appendAttributedString:pvBold];
    [viewText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    // Also we want to add an arrow to the board
    self.boardView.arrows = @[[self firstMoveFromPV:data[@"pv"]]];
    
    // Second line of text
    NSString *score = [self scoreForPV:data];
    NSString *depth = [NSString stringWithFormat:@"%d/%d", [data[@"depth"] intValue], [data[@"seldepth"] intValue]];
    NSString *time = [SFMFormatter millisecondsToClock:[data[@"time"] longLongValue]];
    NSString *nodes = [SFMFormatter nodesAsText:data[@"nodes"]];
    NSString *secondLine = [NSString stringWithFormat:@"    %@    Depth: %@    %@    %@\n\n",
                             score,
                             depth,
                             time,
                             nodes];
    NSAttributedString *secondLineFormatted = [[NSAttributedString alloc] initWithString:secondLine attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]]}];
    [viewText appendAttributedString:secondLineFormatted];
    
    [self.lineTextView.textStorage setAttributedString:[viewText copy]];
    
    [self.lineTextView scrollToEndOfDocument:self];
}

- (void)receivedBestMove:(NSNotification *)notification
{
    if (self.wantsAnalysis) {
        [self sendPositionToEngine];
    }
}


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
    if (self.engine.isAnalyzing) {
        [self stopAnalysis];
        self.wantsAnalysis = YES;
    }
    
    NSError *error = nil;
    [self.currentGame doMove:move error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return;
    }
    
    self.boardView.position = [self.currentGame.position copy];
    [self checkIfGameOver];
    [self.document updateChangeCount:NSChangeDone];
    [self updateNotationView];
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

#pragma mark - Teardown
- (void)windowWillClose:(NSNotification *)notification
{
    [self subscribeToNotifications:NO];
}
- (void)dealloc
{
    self.engine = nil;
}

@end
