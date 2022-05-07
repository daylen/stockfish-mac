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
#import "SFMArrowMove.h"
#import "SFMFormatter.h"
#import "SFMMove.h"
#import "SFMUCILine.h"
#import "SFMPosition.h"
#import "SFMUserDefaults.h"

const CGFloat kMinWeight = 0.25;
const CGFloat kMaxWeight = 1;

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

@property (nonatomic) BOOL isUndoRedoing;

@end

@implementation SFMWindowController

#pragma mark - Target/Action

- (IBAction)copyFenString:(id)sender
{
    NSString *fen = [self.currentGame.position.fen copy];
    [[NSPasteboard generalPasteboard] declareTypes:@[NSPasteboardTypeString] owner:nil];
    [[NSPasteboard generalPasteboard] setString:fen forType:NSPasteboardTypeString];
}
- (IBAction)pasteFenString:(id)sender
{
    // Don't want to deal with multi-game PGN
    if ([self.pgnFile.games count] > 1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not paste FEN"];
        [alert addButtonWithTitle:@"OK"];
        [alert setInformativeText:@"Please create a new game first."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return;
    }
    
    // Fetch from clipboard
    NSString *fen = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
    fen = [fen stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Validate the FEN string and throw a modal if invalid
    if (![SFMPosition isValidFen:fen]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not paste FEN"];
        [alert addButtonWithTitle:@"OK"];
        [alert setInformativeText:@"The FEN string is not valid. Edit your FEN string and try again."];
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
    if (self.engine.isAnalyzing && self.engine.lines) {
        [self doMove:[((SFMUCILine *)self.engine.lines[@(1)]).moves firstObject]];
    }
}
- (IBAction)doBestLine:(id)sender
{
    if (self.engine.isAnalyzing) {
        [self doMoves:((SFMUCILine *)self.engine.lines[@(1)]).moves positionAtStart:YES];
    }
}
- (IBAction)increaseVariations:(id)sender {
    self.engine.multipv++;
}
- (IBAction)decreaseVariations:(id)sender {
    self.engine.multipv--;
}
- (IBAction)toggleShowArrows:(id)sender {
    [SFMUserDefaults setArrowsEnabled:![SFMUserDefaults arrowsEnabled]];
    if (![SFMUserDefaults arrowsEnabled]) {
        self.boardView.arrows = nil;
    }
}
- (IBAction)toggleUseNnue:(id)sender {
    [SFMUserDefaults setUseNnue:![SFMUserDefaults useNnue]];
    self.engine.useNnue = [SFMUserDefaults useNnue];
}
- (IBAction)toggleShowWdl:(id)sender {
    [SFMUserDefaults setShowWDL:![SFMUserDefaults showWdl]];
    self.engine.showWdl = [SFMUserDefaults showWdl];

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
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Game over!"];
        [alert addButtonWithTitle:@"OK"];
        [alert setInformativeText:isWhite ? @"Black wins." : @"White wins."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        [self.currentGame setResult:resultText];
    } else if ([self.currentGame.position isImmediateDraw]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Game over!"];
        [alert addButtonWithTitle:@"OK"];
        [alert setInformativeText:@"It's a draw."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        [self.currentGame setResult:@"1/2-1/2"];
    }
    
}

- (void)updateNotationView
{
    NSAttributedString *currentGameString = [self.currentGame moveTextString];
    [self.notationView.textStorage setAttributedString:[currentGameString copy]];
    NSRange currentRange = [self currentNodeRange:currentGameString];
    if(currentRange.location != NSNotFound){
        [self.notationView scrollRangeToVisible:currentRange];
    }
}

- (NSRange)currentNodeRange:(NSAttributedString *)moveText
{
    __block NSRange currentNodeRange = NSMakeRange(NSNotFound, 0);
    [moveText enumerateAttribute:NSLinkAttributeName inRange:NSMakeRange(0, moveText.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
        if([value isEqual:self.currentGame.currentNode.nodeId]){
            currentNodeRange = range;
        }
    }];
    return currentNodeRange;
}

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
    [self.currentGame goToNodeId:link];
    [self syncToViewsAndEngine];
    return YES;
}

/**
 Maps scores from [weakestScore, strongestScore] to [kMinWeight, kMaxWeight].
 Agnostic about Black vs White scores; Black's strongest score is more negative, whereas White's strongest score is more positive, etc.
 */
- (CGFloat)weightFromScore:(const CGFloat)score weakestScore:(const CGFloat)weakestScore strongestScore:(const CGFloat)strongestScore {
    if(strongestScore == weakestScore) {
        return kMaxWeight;
    }
    
    const CGFloat scoreProportion = (score - weakestScore) / (strongestScore - weakestScore); // maps [weakestScore, strongestScore] -> [0, 1]
    const CGFloat weight = (kMaxWeight - kMinWeight) * scoreProportion + kMinWeight; // [0, 1] -> [minWeight, maxWeight]
    
    return weight;
}

- (NSArray<SFMUCILine *> *)sortedLinesByScore:(NSDictionary<NSNumber *, SFMUCILine *> *const)linesDict {
    if(linesDict.count <= 1) {
        return linesDict.allValues;
    }
    
    const CGFloat maybeStrongestScore = linesDict[@(1)].score;
    const CGFloat maybeWeakestScore = linesDict[@(linesDict.count)].score;
    
    NSComparisonResult strongestScoreComparisonResult;
    NSComparisonResult notStrongestScoreComparisonResult;
    
    // White's favor
    if(maybeStrongestScore > maybeWeakestScore) {
        strongestScoreComparisonResult = NSOrderedAscending;
        notStrongestScoreComparisonResult = NSOrderedDescending;
    } else { // Black's favor
        strongestScoreComparisonResult = NSOrderedDescending;
        notStrongestScoreComparisonResult = NSOrderedAscending;
    }
    
    return [linesDict.allValues sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(SFMUCILine *_Nonnull obj1, SFMUCILine *_Nonnull obj2) {
        return obj1.score == obj2.score ? NSOrderedSame :
        obj1.score > obj2.score ? strongestScoreComparisonResult : notStrongestScoreComparisonResult;
    }];
}

- (void)updateArrowsFromLines:(NSDictionary<NSNumber *, SFMUCILine *> *const)linesDict {
    if(![SFMUserDefaults arrowsEnabled]) {
        return;
    }
    
    NSArray<SFMUCILine *> *const sortedLines = [self sortedLinesByScore:linesDict];
    const CGFloat strongestScore = sortedLines.firstObject.score;
    const CGFloat weakestScore = sortedLines.lastObject.score;
    NSMutableArray<SFMArrowMove *> *const arrowMoves = [NSMutableArray new];
    
    for (SFMUCILine *const line in sortedLines) {
        if(line.moves.count) {
            const CGFloat weight = [self weightFromScore:line.score
                                            weakestScore:weakestScore
                                          strongestScore:strongestScore];
            SFMArrowMove *const arrowMove = [[SFMArrowMove alloc]
                                             initWithMove:[line.moves firstObject]
                                             weight:weight];
            [arrowMoves addObject: arrowMove];
        }
    }
    
    self.boardView.arrows = arrowMoves;
}

#pragma mark - Init
- (void)windowDidLoad
{
    [super windowDidLoad];
    self.notationView.delegate = self;
    NSDictionary *linkAttributes = @{
        NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
        NSCursorAttributeName:[NSCursor pointingHandCursor]
    };
    [self.notationView setLinkTextAttributes:linkAttributes];

    self.boardView.delegate = self;
    self.boardView.dataSource = self;
    
    [self.gameListView setDelegate:self];
    [self.gameListView setDataSource:self];
    [self.gameListView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];

    self.engine = [[SFMUCIEngine alloc] initStockfish];
    self.engine.delegate = self;
    self.engine.useNnue = [SFMUserDefaults useNnue];
    self.engine.showWdl = [SFMUserDefaults showWdl];
    [self handlePGNFile];
}

- (void)handlePGNFile
{
    [self loadGameAtIndex:0];
    
    // Decide whether to show or hide the game sidebar
    BOOL showSidebar = (self.pgnFile.games.count > 1);
    self.mainSplitView.subviews[0].hidden = !showSidebar;

    self.isUndoRedoing = NO;

    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc addObserver:self
           selector:@selector(beginUndoRedo:)
               name:NSUndoManagerWillUndoChangeNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(endUndoRedo:)
               name:NSUndoManagerDidUndoChangeNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(beginUndoRedo:)
               name:NSUndoManagerWillRedoChangeNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(endUndoRedo:)
               name:NSUndoManagerDidRedoChangeNotification
             object:nil];
}

- (void)dealloc
{
    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc removeObserver:self];
}

- (void)loadGameAtIndex:(int)index
{
    self.currentGameIndex = index;
    self.currentGame = self.pgnFile.games[index];
    self.currentGame.delegate = self;
    NSError *error = nil;
    [self.currentGame parseMoveText:&error];
    if (error) {
        [self close];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not open game"];
        [alert addButtonWithTitle:@"OK"];
        [alert setInformativeText:@"Stockfish could not parse the move text. Edit your PGN file and try again."];
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
    } else if ([menuItem action] == @selector(doBestMove:) || [menuItem action] == @selector(doBestLine:)) {
        return self.engine.isAnalyzing;
    } else if ([menuItem action] == @selector(firstMove:) || [menuItem action] == @selector(previousMove:)) {
        return ![self.currentGame atBeginning];
    } else if ([menuItem action] == @selector(lastMove:) || [menuItem action] == @selector(nextMove:)) {
        return ![self.currentGame atEnd];
    } else if ([menuItem action] == @selector(decreaseVariations:)) {
        return self.engine.multipv != 1;
    } else if ([menuItem action] == @selector(toggleShowArrows:)) {
        [menuItem setState:[SFMUserDefaults arrowsEnabled] ? NSControlStateValueOn : NSControlStateValueOff];
    } else if ([menuItem action] == @selector(toggleUseNnue:)) {
        [menuItem setState:[SFMUserDefaults useNnue] ? NSControlStateValueOn : NSControlStateValueOff];
    } else if ([menuItem action] == @selector(toggleShowWdl:)) {
        [menuItem setState:[SFMUserDefaults showWdl] ? NSControlStateValueOn : NSControlStateValueOff];
    }
    return YES;
}


#pragma mark - SFMUCIEngineDelegate

- (void)uciEngine:(SFMUCIEngine *)engine didGetEngineName:(NSString *)name {
    self.engineTextField.stringValue = name;
}

- (void)uciEngine:(id)engine didGetInfoString:(NSString *)string {
    // no op
}

- (void)uciEngine:(SFMUCIEngine *)engine didGetNewCurrentMove:(SFMMove *)move number:(NSInteger)moveNumber depth:(NSInteger)depth {
    
    NSMutableArray /* of NSString */ *statusComponents = [[NSMutableArray alloc] init];
    SFMUCILine *pv = engine.lines[@(1)];
    
    // 1. Score
    [statusComponents addObject:[SFMFormatter scoreAsText:(int) pv.score isMate:pv.scoreIsMateDistance isWhiteToMove:engine.gameToAnalyze.position.sideToMove == WHITE isLowerBound:pv.scoreIsLowerBound isUpperBound:pv.scoreIsUpperBound]];
    
    // 2. Depth
    [statusComponents addObject:[NSString stringWithFormat:@"Depth=%lu/%lu", pv.depth, pv.selectiveDepth]];
    
    // 3. Curr Move
    if (move) {
        NSString *san = [engine.gameToAnalyze.position sanForMovesArray:@[move] html:NO breakLines:NO num:(int) engine.gameToAnalyze.currentNode.ply / 2 + 1];
        [statusComponents addObject:[NSString stringWithFormat:@"%@(%lu/%d)", san, moveNumber, engine.gameToAnalyze.position.numLegalMoves]];
    }
    
    // 4. Speed
    [statusComponents addObject:[NSString stringWithFormat:@"%@/s", [SFMFormatter nodesAsText:pv.nodesPerSecond]]];
    
    // 5. MultiPV
    if (self.engine.multipv != 1) {
        [statusComponents addObject:[NSString stringWithFormat:@"MultiPV=%lu", self.engine.multipv]];
    }
    
    // 6. NNUE info
    [statusComponents addObject:self.engine.nnueInfo];
    
    self.engineStatusTextField.stringValue = [statusComponents componentsJoinedByString:@"    "];
    
}

- (void)uciEngine:(SFMUCIEngine *)engine didGetNewLine:(NSDictionary *)lines {
    SFMUCILine *pv = lines[@(1)];
    
    if (pv) {
        // Update the status text
        [self uciEngine:engine didGetNewCurrentMove:nil number:0 depth:pv.depth];
    }
    
    [self updateArrowsFromLines:lines];
    
    NSMutableAttributedString *combined = [[NSMutableAttributedString alloc] init];
    
    NSArray *keys = [[lines allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return obj1.integerValue > obj2.integerValue;
    }];
    
    for (NSNumber *pvNum in keys) {
        SFMUCILine *line = lines[pvNum];
        
        // First line
        NSAttributedString *boldPv  = [[NSAttributedString alloc] initWithString:[engine.gameToAnalyze.position sanForMovesArray:line.moves html:NO breakLines:NO num:(int) engine.gameToAnalyze.currentNode.ply / 2 + 1] attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSForegroundColorAttributeName: [NSColor labelColor]}];
        
        // Second line
        NSMutableArray /* of NSString */ *statusComponents = [[NSMutableArray alloc] init];
        
        // 1. Score
        [statusComponents addObject:[SFMFormatter scoreAsText:(int) line.score isMate:line.scoreIsMateDistance isWhiteToMove:engine.gameToAnalyze.position.sideToMove == WHITE isLowerBound:line.scoreIsLowerBound isUpperBound:line.scoreIsUpperBound]];
        
        // 2. Depth
        [statusComponents addObject:[NSString stringWithFormat:@"Depth=%lu/%lu", line.depth, line.selectiveDepth]];
        
        // 3. TB
        if (line.tbHits) {
            [statusComponents addObject:[NSString stringWithFormat:@"TB=%lu", line.tbHits]];
        }

        // 4. Time
        [statusComponents addObject:[SFMFormatter millisecondsToClock:line.time]];
        
        // 5. Nodes
        [statusComponents addObject:[SFMFormatter nodesAsText:line.nodes]];

        // 6. WDL
        if (engine.showWdl) {
            [statusComponents addObject:[NSString stringWithFormat:@"\n   Win=%1.1f%% Draw=%1.1f%% Loss=%1.1f%%", (float)line.wdlWin/10, (float)line.wdlDraw/10, (float)line.wdlLoss/10 ]];
        }
        
        NSAttributedString *secondLine = [[NSAttributedString alloc] initWithString:[statusComponents componentsJoinedByString:@"    "] attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]], NSForegroundColorAttributeName: [NSColor labelColor]}];
        
        
        [combined appendAttributedString:boldPv];
        [combined appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        [combined appendAttributedString:secondLine];
        [combined appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
    }
    
    [self.lineTextView.textStorage setAttributedString:combined];
    
}

#pragma mark - Notifications


- (NSString *)prettyPV:(NSString *)pv
{
    NSArray *tokens = [pv componentsSeparatedByString:@" "];

    return [self.currentGame.position sanForMovesArray:[self.currentGame.position movesArrayForUci:tokens] html:NO breakLines:NO num:(int) self.currentGame.currentNode.ply / 2 + 1];
}

- (SFMMove *)firstMoveFromPV:(NSString *)pv
{
    return [[self.currentGame.position movesArrayForUci:[pv componentsSeparatedByString:@" "]] firstObject];
}

#pragma mark - SFMChessGameDelegate

- (void)chessGameStateDidChange:(SFMChessGame *)chessGame {
    // When we are undoing, we must only do one syncToViewsAndEngine
    // call, at the end of the batch.  Otherwise, we'll send multiple
    // board changes to the engine back-to-back, and it gets out of sync.
    // This isn't an issue for most commands because they are single
    // changes anyway, but Do Best Line can insert multiple moves at once.
    if (!self.isUndoRedoing) {
        [self syncToViewsAndEngine];
    }
}

#pragma mark - Undo / redo handling

- (void)beginUndoRedo:(id)sender
{
    self.isUndoRedoing = true;
}

- (void)endUndoRedo:(id)sender
{
    self.isUndoRedoing = false;
    [self syncToViewsAndEngine];
}

#pragma mark - NSWindowDelegate

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.currentGame.undoManager;
}

#pragma mark - SFMBoardViewDelegate

- (void)boardView:(SFMBoardView *)boardView userDidMove:(SFMMove *)move {
    [self doMove:move];
}

- (void)doMove:(SFMMove *)move {
    [self doMoves:@[move] positionAtStart:NO];
}

- (void)doMoves:(NSArray<SFMMove *> *)moves positionAtStart:(BOOL)positionAtStart {
    [self doMoves:moves fromIndex:0 positionAtStart:positionAtStart];
}

/*!
 * Re-sync, now that we have handled the batch of moves.
 */
- (void)doMovesComplete {
    [self syncToViewsAndEngine];
}

/*!
 * Do as many moves as possible from the given array, starting at the given
 * index.  We may need to prompt the user to create a new variation, in
 * which case that is done asynchronously and we will come back here to
 * finish the job.
 */
- (void)doMoves:(NSArray<SFMMove *> *)moves fromIndex:(NSUInteger)fromIndex positionAtStart:(BOOL)positionAtStart {
    NSUInteger index = fromIndex;
    while (index < moves.count) {
        SFMMove * move = moves[index];

        if(![self.currentGame atEnd]){
            SFMNode *existingVariation = [self.currentGame.currentNode.next existingVariationForMove:move];
            if(existingVariation){
                [self.currentGame goToNode:existingVariation];
            }
            else{
                typeof(self) __weak weakSelf = self;
                [self doMoveWithOverwritePrompt:move onCompletion:^(BOOL wasCancelled) {
                    if (wasCancelled) {
                        [weakSelf doMovesComplete];
                    }
                    else {
                        [weakSelf doMoves:moves fromIndex:(index + 1) positionAtStart:positionAtStart];
                    }
                }];
                return;
            }
        }
        else{
            [self doMoveForced:move];
        }
        index++;
    }
    if (positionAtStart && fromIndex < moves.count) {
        [self goBackNMoves:moves.count - fromIndex];
    }
    [self doMovesComplete];
}

-(void)goBackNMoves:(NSUInteger)n {
    for (int i = 0; i < n; i++) {
        [self.currentGame goBackOneMove];
    }
}

- (void)doMoveWithOverwritePrompt:(SFMMove *)move onCompletion:(void(^)(BOOL wasCancelled))onCompletion {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Overwrite game history?"];
    [alert addButtonWithTitle:@"Create variation"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Overwrite"];
    [alert setInformativeText:@"You are not at the end of the game. Do you want to create a variation or overwrite the current move ?"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                // Create variation
                [self doMoveForced:move];
                onCompletion(NO);
                break;
            case NSAlertSecondButtonReturn:
                // Cancel
                onCompletion(YES);
                break;
            case NSAlertThirdButtonReturn:
                // Overwrite
                [self.currentGame removeSubtreeFromNode:self.currentGame.currentNode.next];
                [self doMoveForced:move];
                onCompletion(NO);
                break;
        }
    }];
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
    [alert setAlertStyle:NSAlertStyleWarning];
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
