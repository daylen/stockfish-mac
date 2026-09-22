#import <XCTest/XCTest.h>
#import "SFMUCIEngine.h"
#import "SFMChessGame.h"
#import "SFMUserDefaults.h"
#import "Constants.h"
#include <limits.h>
#include <stdlib.h>

static const NSTimeInterval SFMEngineTestTimeout = 5;
static const NSTimeInterval SFMEngineTestPollInterval = 0.01;

@interface SFMUCIEngine (SFMUCIEngineTestAccess)
- (instancetype)initWithPathToEngine:(NSString *)path applyPreferences:(BOOL)apply;
@end

@interface SFMUCIEngineTest : XCTestCase <SFMUCIEngineDelegate>
@property SFMUCIEngine *engine;
@property BOOL receivedDrainingOutput;
@property NSString *fixtureDirectory;
@property NSInteger savedThreads;
@property NSInteger savedHash;
@property NSInteger savedSkill;
@property NSData *savedBookmark;
@end

@implementation SFMUCIEngineTest

- (void)setUp
{
    [super setUp];
    self.savedThreads = [SFMUserDefaults threadsValue];
    self.savedHash = [SFMUserDefaults hashValue];
    self.savedSkill = [SFMUserDefaults skillLevelValue];
    self.savedBookmark = [SFMUserDefaults sandboxBookmarkData];
    [SFMUserDefaults setThreadsValue:1];
    [SFMUserDefaults setHashValue:8];
    [SFMUserDefaults setSkillLevelValue:20];
    [SFMUserDefaults setSandboxBookmarkData:nil];
    self.fixtureDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSError *error = nil;
    XCTAssertTrue([[NSFileManager defaultManager] createDirectoryAtPath:self.fixtureDirectory withIntermediateDirectories:YES attributes:nil error:&error], @"%@", error);
    NSString *script = [NSString stringWithFormat:
        @"#!/bin/sh\ncd '%@' || exit 1\n"
         "while IFS= read -r command; do\n"
         "  printf '%%s\\n' \"$command\" >> commands\n"
         "  case \"$command\" in\n"
         "    uci) printf 'uciok\\n' ;;\n"
         "    stop)\n"
         "      printf 'info depth 1 score cp 10 nodes 1 time 1 pv e2e4\\nid name draining\\n'\n"
         "      (\n"
         "      while [ ! -e release ] && [ ! -e terminate ]; do sleep 0.01; done\n"
         "      if [ -e terminate ]; then kill -TERM $$; exit 0; fi\n"
         "      printf 'bestmove e2e4\\n' >> commands\n"
         "      printf 'bestmove e2e4\\n' ) & ;;\n"
         "    isready) printf 'readyok\\n' ;;\n"
         "  esac\n"
         "done\n", self.fixtureDirectory];
    NSString *path = [self.fixtureDirectory stringByAppendingPathComponent:@"engine"];
    XCTAssertTrue([script writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error], @"%@", error);
    XCTAssertTrue([[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0700} ofItemAtPath:path error:&error], @"%@", error);
    self.engine = [[SFMUCIEngine alloc] initWithPathToEngine:path applyPreferences:YES];
    self.engine.delegate = self;
    self.engine.gameToAnalyze = [SFMChessGame new];
}

- (void)uciEngine:(SFMUCIEngine *)engine didGetEngineName:(NSString *)name
{
    self.receivedDrainingOutput = [name isEqualToString:@"draining"];
}

- (void)uciEngine:(SFMUCIEngine *)engine didGetInfoString:(NSString *)string {}
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewCurrentMove:(SFMMove *)move number:(NSInteger)number depth:(NSInteger)depth {}
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewLine:(NSDictionary *)lines {}

- (void)tearDown
{
    [self signal:@"release"];
    self.engine.isAnalyzing = NO;
    XCTAssertTrue([self waitUntil:^BOOL { return [SFMUCIEngine instancesAnalyzing] == 0; }]);
    self.engine = nil;
    [SFMUserDefaults setThreadsValue:self.savedThreads];
    [SFMUserDefaults setHashValue:self.savedHash];
    [SFMUserDefaults setSkillLevelValue:self.savedSkill];
    [SFMUserDefaults setSandboxBookmarkData:self.savedBookmark];
    [super tearDown];
}

- (BOOL)waitUntil:(BOOL (^)(void))condition
{
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:SFMEngineTestTimeout];
    while (!condition() && deadline.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:SFMEngineTestPollInterval]];
    }
    return condition();
}

- (NSArray<NSString *> *)commands
{
    NSString *transcript = [NSString stringWithContentsOfFile:[self.fixtureDirectory stringByAppendingPathComponent:@"commands"] encoding:NSUTF8StringEncoding error:nil];
    return [transcript componentsSeparatedByString:@"\n"] ?: @[];
}

- (NSUInteger)countCommand:(NSString *)command
{
    return [[self.commands filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", command]] count];
}

- (void)signal:(NSString *)name
{
    XCTAssertTrue([[NSData data] writeToFile:[self.fixtureDirectory stringByAppendingPathComponent:name] atomically:YES]);
}

- (void)notifyPreferences
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
}

- (void)testPreferencesWaitForSearchEndAndResumeOnceWithLatestSettingsAndPosition
{
    self.engine.isAnalyzing = YES;
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"go infinite"] == 1; }]);
    [SFMUserDefaults setThreadsValue:3];
    [self notifyPreferences];
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"stop"] == 1; }]);
    XCTAssertTrue(self.engine.isAnalyzing);
    XCTAssertTrue([self waitUntil:^BOOL { return self.receivedDrainingOutput; }]);
    XCTAssertNil(self.engine.lines);
    NSUInteger stoppedCommandCount = self.commands.count;
    [SFMUserDefaults setThreadsValue:4];
    [SFMUserDefaults setHashValue:64];
    [SFMUserDefaults setSkillLevelValue:7];
    NSError *bookmarkError = nil;
    NSURL *tablebaseURL = [[NSURL fileURLWithPath:self.fixtureDirectory isDirectory:YES] URLByResolvingSymlinksInPath];
    NSData *bookmark = [tablebaseURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&bookmarkError];
    XCTAssertNotNil(bookmark, @"%@", bookmarkError);
    char resolvedPath[PATH_MAX];
    XCTAssertNotEqual(realpath(self.fixtureDirectory.fileSystemRepresentation, resolvedPath), NULL);
    NSString *expectedTablebasePath = [NSString stringWithUTF8String:resolvedPath];
    [SFMUserDefaults setSandboxBookmarkData:bookmark];
    [self notifyPreferences];
    self.engine.gameToAnalyze = [[SFMChessGame alloc] initWithFen:@"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1"];
    SFMChessGame *latestGame = [SFMChessGame new];
    self.engine.gameToAnalyze = latestGame;
    self.engine.multipv = 2;
    self.engine.multipv = 3;
    self.engine.multipv = 0;
    self.engine.showWdl = YES;
    XCTAssertEqual(self.commands.count, stoppedCommandCount);
    [self signal:@"release"];
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"go infinite"] == 2; }]);
    NSArray *commands = self.commands;
    NSUInteger stop = [commands indexOfObject:@"stop"];
    NSArray *resumedCommands = [commands subarrayWithRange:NSMakeRange(stop + 1, commands.count - stop - 1)];
    NSArray *expected = @[@"bestmove e2e4", @"setoption name Threads value 4", @"setoption name Hash value 64", @"setoption name Skill Level value 7", [@"setoption name SyzygyPath value " stringByAppendingString:[expectedTablebasePath stringByAppendingString:@"/"]], @"setoption name MultiPV value 3", @"setoption name UCI_ShowWDL value true", latestGame.uciString, @"go infinite", @""];
    XCTAssertEqualObjects(resumedCommands, expected);
    XCTAssertEqual(self.engine.gameToAnalyze, latestGame);
    XCTAssertEqual([SFMUCIEngine instancesAnalyzing], 1);
}

- (void)testUserStopDuringPreferenceUpdateAppliesSettingsWithoutRestart
{
    self.engine.isAnalyzing = YES;
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"go infinite"] == 1; }]);
    [SFMUserDefaults setHashValue:32];
    [self notifyPreferences];
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"stop"] == 1; }]);
    self.engine.isAnalyzing = NO;
    [self signal:@"release"];
    XCTAssertTrue([self waitUntil:^BOOL { return [self.commands containsObject:@"setoption name Hash value 32"]; }]);
    XCTAssertFalse(self.engine.isAnalyzing);
    XCTAssertEqual([self countCommand:@"go infinite"], 1);
    XCTAssertEqual([self countCommand:@"stop"], 1);
    XCTAssertEqual([SFMUCIEngine instancesAnalyzing], 0);
}

- (void)testPreferencesWhileIdleApplyWithoutStartingAnalysis
{
    [SFMUserDefaults setHashValue:16];
    [self notifyPreferences];
    XCTAssertTrue([self waitUntil:^BOOL { return [self.commands containsObject:@"setoption name Hash value 16"]; }]);
    XCTAssertFalse(self.engine.isAnalyzing);
    XCTAssertEqual([self countCommand:@"go infinite"], 0);
    XCTAssertEqual([self countCommand:@"stop"], 0);
}

- (void)testStopThenStartWhileDrainingWaitsForBestmoveBeforeApplyingPreferences
{
    self.engine.isAnalyzing = YES;
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"go infinite"] == 1; }]);
    self.engine.isAnalyzing = NO;
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"stop"] == 1; }]);
    [SFMUserDefaults setHashValue:128];
    [self notifyPreferences];
    self.engine.isAnalyzing = YES;
    [self signal:@"release"];
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"go infinite"] == 2; }]);
    NSArray *commands = self.commands;
    XCTAssertLessThan([commands indexOfObject:@"bestmove e2e4"], [commands indexOfObject:@"setoption name Hash value 128"]);
    XCTAssertEqual([self countCommand:@"stop"], 1);
    XCTAssertEqual([SFMUCIEngine instancesAnalyzing], 1);
    XCTAssertTrue(self.engine.isAnalyzing);
}

- (void)testEngineTerminationCancelsPendingPreferenceRestart
{
    self.engine.isAnalyzing = YES;
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"go infinite"] == 1; }]);
    [self notifyPreferences];
    XCTAssertTrue([self waitUntil:^BOOL { return [self countCommand:@"stop"] == 1; }]);
    [self signal:@"terminate"];
    XCTAssertTrue([self waitUntil:^BOOL { return !self.engine.isAnalyzing && [SFMUCIEngine instancesAnalyzing] == 0; }]);
    self.engine.isAnalyzing = YES;
    [self notifyPreferences];
    XCTAssertFalse(self.engine.isAnalyzing);
    XCTAssertEqual([self countCommand:@"go infinite"], 1);
}
@end
