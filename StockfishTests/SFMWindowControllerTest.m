#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "SFMWindowController.h"
#import "SFMPreferencesWindowController.h"
#import "SFMPreferenceCellView.h"

static const NSTimeInterval SFMModalDismissInterval = 0.01;
static const NSInteger SFMGameListColumn = 0;
static const NSUInteger SFMGameResultSubviewIndex = 2;

@interface SFMWindowController (SFMWindowControllerTestAccess)
@property (readonly) NSTableView *gameListView;
@property (readonly) SFMBoardView *boardView;
@property (readonly) NSTextView *notationView;
@property (readonly) SFMChessGame *currentGame;
@property (readonly) SFMUCIEngine *engine;
- (void)lastMove:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
@end

@interface SFMPreferencesWindowController (SFMWindowControllerTestAccess)
@property (readonly) SFMPreferenceCellView *threadsCell;
@property (readonly) SFMPreferenceCellView *hashCell;
@property (readonly) SFMPreferenceCellView *skillCell;
@property (readonly) NSButton *chooseButton;
@property (readonly) NSButton *recommendedSettingsButton;
@property (readonly) SFMUCIEngine *optionsProbe;
@end

@interface SFMWindowControllerTest : XCTestCase
@end

@implementation SFMWindowControllerTest

- (void)testPreferencesRemainAvailableDuringActiveAnalysis
{
    const NSTimeInterval engineResponseTimeout = 10;
    NSString *fixturePath = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSString *fixture = @"#!/bin/sh\n"
        "while IFS= read -r command; do\n"
        "  case \"$command\" in\n"
        "    uci) printf 'option name Threads type spin default 1 min 1 max 1024\\noption name Hash type spin default 16 min 1 max 33554432\\noption name Skill Level type spin default 20 min 0 max 20\\nuciok\\n' ;;\n"
        "    stop) printf 'bestmove e2e4\\n' ;;\n"
        "  esac\n"
        "done\n";
    NSError *error = nil;
    XCTAssertTrue([fixture writeToFile:fixturePath atomically:YES encoding:NSUTF8StringEncoding error:&error], @"%@", error);
    XCTAssertTrue([[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0700} ofItemAtPath:fixturePath error:&error], @"%@", error);
    Method enginePathMethod = class_getClassMethod([SFMUCIEngine class], NSSelectorFromString(@"bestEnginePath"));
    IMP fixturePathImplementation = imp_implementationWithBlock(^NSString *(id engineClass) { return fixturePath; });
    IMP originalPathImplementation = method_setImplementation(enginePathMethod, fixturePathImplementation);
    SFMUCIEngine *engine = nil;
    SFMPreferencesWindowController *controller = nil;
    @try {
        engine = [[SFMUCIEngine alloc] initStockfish];
        engine.gameToAnalyze = [[SFMChessGame alloc] init];
        engine.isAnalyzing = YES;
        XCTAssertTrue(engine.isAnalyzing);
        XCTAssertGreaterThan([SFMUCIEngine instancesAnalyzing], 0);

        controller = [[SFMPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
        [controller showWindow:nil];
        XCTAssertNotNil(controller.optionsProbe);
        NSPredicate *optionsLoaded = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return !controller.chooseButton.hidden && !controller.threadsCell.hidden &&
                !controller.hashCell.hidden && !controller.skillCell.hidden;
        }];
        [self expectationForPredicate:optionsLoaded evaluatedWithObject:controller handler:nil];
        [self waitForExpectationsWithTimeout:engineResponseTimeout handler:nil];
        [controller.window displayIfNeeded];
        XCTAssertNil(controller.window.attachedSheet);
        for (SFMPreferenceCellView *cell in @[controller.threadsCell, controller.hashCell, controller.skillCell]) {
            XCTAssertTrue(cell.slider.enabled);
            XCTAssertTrue(cell.textField.enabled);
            XCTAssertGreaterThanOrEqual(cell.max, cell.min);
        }
        XCTAssertTrue(controller.chooseButton.enabled);
        XCTAssertTrue(controller.recommendedSettingsButton.enabled);
        XCTAssertFalse(controller.recommendedSettingsButton.hidden);
        XCTAssertTrue(engine.isAnalyzing);
    } @finally {
        method_setImplementation(enginePathMethod, originalPathImplementation);
        imp_removeBlock(fixturePathImplementation);
        engine.isAnalyzing = NO;
        if (controller.window.attachedSheet != nil) {
            [controller.window endSheet:controller.window.attachedSheet];
        }
        [controller close];
    }
}

- (void)testSelectingUnreadableGameSynchronizesViewsAndEngineSnapshotAndRecoversOnNextGame {
    NSError *error = nil;
    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:
        @"[Event \"Before\"]\n\n1. e4 *\n\n"
         "[Event \"Unreadable\"]\n\n1. e4 () *\n\n"
         "[Event \"After\"]\n\n1. d4 *\n" error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    SFMWindowController *controller = [[SFMWindowController alloc] initWithWindowNibName:@"SFMDocument"];
    controller.pgnFile = file;
    XCTAssertNotNil(controller.window);
    [controller lastMove:nil];
    XCTAssertFalse([controller.boardView.position.fen isEqualToString:((SFMChessGame *)file.games[1]).position.fen]);
    XCTAssertFalse(controller.engine.isAnalyzing);

    NSTimer *dismissAlert = [NSTimer timerWithTimeInterval:SFMModalDismissInterval repeats:YES block:^(NSTimer *timer) {
        if (NSApp.modalWindow != nil) {
            [NSApp abortModal];
            [timer invalidate];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:dismissAlert forMode:NSModalPanelRunLoopMode];
    [controller.gameListView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [dismissAlert invalidate];

    NSTableCellView *unreadableCell = [controller.gameListView viewAtColumn:SFMGameListColumn row:1 makeIfNecessary:YES];
    XCTAssertNotNil(unreadableCell);
    NSTextField *unreadableResult = unreadableCell.subviews[SFMGameResultSubviewIndex];
    XCTAssertTrue([unreadableResult.stringValue containsString:@"(unreadable)"]);
    XCTAssertEqual(controller.currentGame, file.games[1]);
    XCTAssertNil(controller.currentGame.currentNode);
    XCTAssertEqualObjects(controller.boardView.position.fen, controller.currentGame.position.fen);
    XCTAssertEqualObjects(controller.notationView.string, @"");
    for (NSString *actionName in @[@"firstMove:", @"previousMove:", @"nextMove:", @"lastMove:", @"doBestMove:", @"doBestLine:"]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:actionName action:NSSelectorFromString(actionName) keyEquivalent:@""];
        XCTAssertFalse([controller validateMenuItem:item], @"%@ must be disabled without a move tree", actionName);
    }
    XCTAssertEqualObjects(controller.engine.gameToAnalyze.tags, controller.currentGame.tags);
    XCTAssertEqualObjects(controller.engine.gameToAnalyze.position.fen, controller.currentGame.position.fen);

    [controller.gameListView selectRowIndexes:[NSIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    XCTAssertEqual(controller.currentGame, file.games[2]);
    XCTAssertNotNil(controller.currentGame.currentNode);
    NSMenuItem *next = [[NSMenuItem alloc] initWithTitle:@"Next" action:NSSelectorFromString(@"nextMove:") keyEquivalent:@""];
    XCTAssertTrue([controller validateMenuItem:next]);
    XCTAssertEqualObjects(controller.engine.gameToAnalyze.tags, controller.currentGame.tags);
    XCTAssertEqualObjects(controller.engine.gameToAnalyze.position.fen, controller.currentGame.position.fen);
    [controller lastMove:nil];
    XCTAssertEqualObjects(controller.boardView.position.fen, controller.currentGame.position.fen);
    XCTAssertTrue([controller.notationView.string containsString:@"d4"]);
    [controller close];
}

- (void)testCachedGameListCellTracksIncompleteStateThroughBoardEditUndoAndRedo
{
    NSError *error = nil;
    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:
        @"[Event \"Before\"]\n\n1. d4 *\n\n"
         "[Event \"Partial\"]\n\n1. e4 e5 2. Kd3 *\n" error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    SFMWindowController *controller = [[SFMWindowController alloc] initWithWindowNibName:@"SFMDocument"];
    controller.pgnFile = file;
    XCTAssertNotNil(controller.window);
    [controller showWindow:nil];
    [controller.window displayIfNeeded];
    NSTimer *dismissAlert = [NSTimer timerWithTimeInterval:SFMModalDismissInterval repeats:YES block:^(NSTimer *timer) {
        if (NSApp.modalWindow != nil) {
            [NSApp abortModal];
            [timer invalidate];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:dismissAlert forMode:NSModalPanelRunLoopMode];
    [controller.gameListView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [dismissAlert invalidate];
    [controller lastMove:nil];
    [controller.window displayIfNeeded];
    NSTableCellView *cell = [controller.gameListView viewAtColumn:SFMGameListColumn row:1 makeIfNecessary:YES];
    XCTAssertNotNil(cell);
    NSTextField *result = cell.subviews[SFMGameResultSubviewIndex];
    XCTAssertTrue([result.stringValue containsString:@"(incomplete)"]);

    NSUndoManager *undoManager = controller.currentGame.undoManager;
    undoManager.groupsByEvent = NO;
    [undoManager beginUndoGrouping];
    [controller boardView:controller.boardView userDidMove:[[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3]];
    [undoManager endUndoGrouping];
    XCTAssertFalse(controller.currentGame.hasUnreadMoveText);
    XCTAssertEqualObjects(controller.currentGame.currentNode.move, [[SFMMove alloc] initWithFrom:SQ_G1 to:SQ_F3]);
    [controller.window displayIfNeeded];
    cell = [controller.gameListView viewAtColumn:SFMGameListColumn row:1 makeIfNecessary:NO];
    XCTAssertNotNil(cell);
    result = cell.subviews[SFMGameResultSubviewIndex];
    XCTAssertFalse([result.stringValue containsString:@"(incomplete)"]);

    [undoManager undo];
    XCTAssertTrue(controller.currentGame.hasUnreadMoveText);
    [controller.window displayIfNeeded];
    cell = [controller.gameListView viewAtColumn:SFMGameListColumn row:1 makeIfNecessary:NO];
    XCTAssertNotNil(cell);
    result = cell.subviews[SFMGameResultSubviewIndex];
    XCTAssertTrue([result.stringValue containsString:@"(incomplete)"]);

    [undoManager redo];
    XCTAssertFalse(controller.currentGame.hasUnreadMoveText);
    [controller.window displayIfNeeded];
    cell = [controller.gameListView viewAtColumn:SFMGameListColumn row:1 makeIfNecessary:NO];
    XCTAssertNotNil(cell);
    result = cell.subviews[SFMGameResultSubviewIndex];
    XCTAssertFalse([result.stringValue containsString:@"(incomplete)"]);
    [controller close];
}

@end
