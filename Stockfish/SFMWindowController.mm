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
#import "SFMFormatter.h"

#include "../Chess/san.h"
#include "../Chess/position.h"

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

using namespace Chess;

@implementation SFMWindowController

#pragma mark - Target/Action
- (IBAction)copyFenString:(id)sender
{
    NSMutableString *fen = [[NSString stringWithCString:self.currentGame.currPosition->to_fen().c_str() encoding:NSUTF8StringEncoding] mutableCopy];
    [fen appendFormat:@" %d %d", self.currentGame.currentMoveIndex, self.currentGame.currentMoveIndex / 2 + 1];
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

    // Validate the FEN string and throw a modal if invalid
    if (!Position::is_valid_fen([fen UTF8String])) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not paste FEN" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The FEN string is not valid."];
        [alert runModal];
        return;
    }

    // Basically insert a new game and reload
    [self.pgnFile.games removeAllObjects];
    [self.pgnFile.games addObject:[[SFMChessGame alloc] initWithWhite:[SFMPlayer new] andBlack:[SFMPlayer new] andFen:fen]];
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
        // Get the best move
        NSString *pv = [self.engine.lineHistory lastObject][@"pv"];
        Move m = [self firstMoveFromPV:pv];
        [self doMove:m];
        // This only updates the model. Also need update the view
        [self syncModelWithView];
        
    } else {
        NSLog(@"Engine is not analyzing!");
    }
}
#pragma mark - Helper methods
- (void)syncModelWithView
{
    if (self.currentGame.currPosition == NULL) {
        @throw [NSException exceptionWithName:@"NullPositionException" reason:@"Position is null." userInfo:nil];
    }
    self.boardView.position->copy(*self.currentGame.currPosition);
    [self.boardView updatePieceViews];
    [self.boardView clearArrows];
    [self updateNotationView];
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

// TODO move to formatter
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
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        self.currentGame.tags[@"Result"] = resultText;
    } else if (self.currentGame.currPosition->is_immediate_draw()) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Game over!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"It's a draw."];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        self.currentGame.tags[@"Result"] = @"1/2-1/2";
    }
}
- (void)updateNotationView
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithHTML:[[self.currentGame movesArrayAsHtmlString] dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
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
    @try {
        [self.currentGame populateMovesFromMoveText];
        [self syncModelWithView];
    }
    @catch (NSException *exception) {
        [self close];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not open game" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", exception.reason];
        [alert runModal];
    }
    
    
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
    if ([self.engine.currentInfo objectForKey:@"depth"]) {
        [statusText appendFormat:@"%d", [self.engine.currentInfo[@"depth"] intValue]];
    } else {
        [statusText appendFormat:@"%d", [latestPV[@"depth"] intValue]];
    }
    // The selective depth
    [statusText appendFormat:@"/%d    ", [latestPV[@"seldepth"] intValue]];
    
    // The current move
    if ([self.engine.currentInfo objectForKey:@"currmove"]) {
        Position *tmpPos = new Position;
        tmpPos->copy(*self.currentGame.currPosition);
        Move mlist[500];
        int numLegalMoves = tmpPos->all_legal_moves(mlist);
        
        Move m = move_from_string(*tmpPos, [self.engine.currentInfo[@"currmove"] UTF8String]);
        UndoInfo u;
        SFMChessMove *moveObject = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
        NSString *niceOutput = [self movesArrayAsString:@[moveObject]];
        
        [statusText appendFormat:@"%@(%@/%d)    ", niceOutput, self.engine.currentInfo[@"currmovenumber"], numLegalMoves];
    }
    
    // The speed
    [statusText appendFormat:@"%@/s", [SFMFormatter nodesAsText:latestPV[@"nps"]]];
    
    self.engineStatusTextField.stringValue = [statusText copy];
}

- (NSString *)scoreForPV:(NSDictionary *)pv
{
    BOOL isLowerBound = [pv objectForKey:@"lowerbound"] != nil;
    BOOL isUpperBound = [pv objectForKey:@"upperbound"] != nil;
    
    // The score
    if ([pv objectForKey:@"cp"]) {
        int score = [pv[@"cp"] intValue];
        
        NSString *theScore = [SFMFormatter scoreAsText:score isMate:NO isWhiteToMove:self.currentGame.currPosition->side_to_move() == WHITE isLowerBound:isLowerBound isUpperBound:isUpperBound];
        
        return theScore;
        
    } else if ([pv objectForKey:@"mate"]) {
        int score = [pv[@"mate"] intValue];
        
        NSString *theScore = [SFMFormatter scoreAsText:score isMate:YES isWhiteToMove:self.currentGame.currPosition->side_to_move() == WHITE isLowerBound:isLowerBound isUpperBound:isUpperBound];
        
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
    
    NSAttributedString *pvBold;
    
    // Use a try catch since there might be an exception
    @try {
       pvBold = [[NSAttributedString alloc] initWithString:[self prettyPV:data[@"pv"]] attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]]}];
    }
    @catch (NSException *exception) {
        return;
    }
    [viewText appendAttributedString:pvBold];
    [viewText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
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


// TODO move to formatter
/*
 Input: something like "d2d4 d7d5 g1f3 g8f6 b1c3"
 Output: something like "1. d4 d5 2. Nf3 Nf6 3. Nc3"
 */
- (NSString *)prettyPV:(NSString *)pvAsText
{
    NSArray *pvFromToText = [pvAsText componentsSeparatedByString:@" "];
    NSMutableArray *pvMacMoveObjects = [NSMutableArray new];
    
    Position *tmpPos = new Position;
    tmpPos->copy(*self.currentGame.currPosition);
    
    for (NSString *fromTo in pvFromToText) {
        if ([fromTo length] == 0) {
            continue;
        }
        if ([fromTo length] < 4) {
            // This should not even happen, but sometimes it does. Weird.
            NSString *reason = [NSString stringWithFormat:@"The move %@ is invalid.", fromTo];
            @throw [NSException exceptionWithName:@"BadMoveException" reason:reason userInfo:nil];
        }
        Move m = move_from_string(*tmpPos, [fromTo UTF8String]);
        UndoInfo u;
        SFMChessMove *moveObject = [[SFMChessMove alloc] initWithMove:m undoInfo:u];
        tmpPos->do_move(m, u);
        [pvMacMoveObjects addObject:moveObject];
    }
    
    // And now, we add the arrow to the board
    Move firstMove = ((SFMChessMove *) pvMacMoveObjects[0]).move;
    [self.boardView clearArrows];
    [self.boardView addArrowFrom:move_from(firstMove) to:move_to(firstMove)];
    
    return [self movesArrayAsString:pvMacMoveObjects];

}

- (Move)firstMoveFromPV:(NSString *)pvAsText
{
    NSArray *pvFromToText = [pvAsText componentsSeparatedByString:@" "];
    Position *tmpPos = new Position;
    tmpPos->copy(*self.currentGame.currPosition);
    for (NSString *fromTo in pvFromToText) {
        if ([fromTo length] == 0) {
            continue;
        }
        if ([fromTo length] < 4) {
            // This should not even happen, but sometimes it does. Weird.
            NSString *reason = [NSString stringWithFormat:@"The move %@ is invalid.", fromTo];
            @throw [NSException exceptionWithName:@"BadMoveException" reason:reason userInfo:nil];
        }
        Move m = move_from_string(*tmpPos, [fromTo UTF8String]);
        return m;
    }
    return MOVE_NONE;
    
}



#pragma mark - SFMBoardViewDelegate

- (void)doMove:(Chess::Move)move
{
    [self doMoveFrom:move_from(move) to:move_to(move) promotion:move_promotion(move)];
    
}
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
    [self.document updateChangeCount:NSChangeDone];
    [self updateNotationView];
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

#pragma mark - Teardown
- (void)windowWillClose:(NSNotification *)notification
{
    [self subscribeToNotifications:NO];
}
- (void)dealloc
{
    //NSLog(@"Deallocating controller");
    self.engine = nil;
}

@end
