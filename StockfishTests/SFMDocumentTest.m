#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "SFMDocument.h"
#import "SFMPGNFile.h"
#import "SFMChessGame.h"

@interface SFMDocumentTest : XCTestCase
@property NSURL *directoryURL;
@end

@implementation SFMDocumentTest

- (void)setUp
{
    [super setUp];
    self.directoryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
        URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
    NSError *error = nil;
    XCTAssertTrue([[NSFileManager defaultManager] createDirectoryAtURL:self.directoryURL
        withIntermediateDirectories:YES attributes:nil error:&error], @"%@", error);
}

- (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtURL:self.directoryURL error:nil];
    [super tearDown];
}

- (void)testOpenPGNThroughDocumentController
{
    NSURL *url = [self.directoryURL URLByAppendingPathComponent:@"New Game.pgn"];
    NSString *pgn = @"[Event \"Document opening\"]\n\n1. e4 e5 2. Nf3 *\n";
    NSError *error = nil;
    XCTAssertTrue([pgn writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error], @"%@", error);

    NSDocumentController *controller = NSDocumentController.sharedDocumentController;
    NSString *type = [controller typeForContentsOfURL:url error:&error];
    XCTAssertNotNil(type, @"%@", error);
    XCTAssertEqual([controller documentClassForType:type], SFMDocument.class);

    XCTestExpectation *opened = [self expectationWithDescription:@"PGN opened"];
    [controller openDocumentWithContentsOfURL:url display:NO completionHandler:^(NSDocument *document, BOOL alreadyOpen, NSError *openError) {
        XCTAssertNotNil(document, @"%@", openError);
        XCTAssertNil(openError);
        XCTAssertFalse(alreadyOpen);
        if (document != nil) {
            SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:
                [[NSString alloc] initWithData:[document dataOfType:type error:nil] encoding:NSUTF8StringEncoding] error:nil];
            XCTAssertEqual(file.games.count, 1);
            SFMChessGame *game = file.games.firstObject;
            XCTAssertEqualObjects(game.tags[@"Event"], @"Document opening");
            [game goToEnd];
            XCTAssertEqualObjects(game.uciString, @"position startpos moves e2e4 e7e5 g1f3 ");
            [document close];
        }
        [opened fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testSaveAndReopenPGNForCurrentAndLegacyTypes
{
    NSDocumentController *controller = NSDocumentController.sharedDocumentController;
    for (NSString *type in @[@"public.pgn", @"com.apple.chess.pgn"]) {
        NSError *error = nil;
        SFMDocument *document = [controller makeUntitledDocumentOfType:type error:&error];
        XCTAssertNotNil(document, @"%@", error);
        XCTAssertNil(error);
        if (document == nil) {
            continue;
        }
        document.pgnFile = [[SFMPGNFile alloc] initWithString:
            @"[Event \"Saved game\"]\n\n1. d4 d5 *\n\n[Event \"Second game\"]\n\n1. e4 *\n" error:&error];
        XCTAssertNil(error);
        NSURL *url = [self.directoryURL URLByAppendingPathComponent:[type stringByAppendingPathExtension:@"pgn"]];

        XCTestExpectation *savedAndReopened = [self expectationWithDescription:type];
        [document saveToURL:url ofType:type forSaveOperation:NSSaveAsOperation completionHandler:^(NSError *saveError) {
            XCTAssertNil(saveError);
            [document close];
            [controller openDocumentWithContentsOfURL:url display:NO completionHandler:^(NSDocument *reopened, BOOL alreadyOpen, NSError *openError) {
                XCTAssertNotNil(reopened, @"%@", openError);
                XCTAssertNil(openError);
                XCTAssertFalse(alreadyOpen);
                if (reopened != nil) {
                    SFMPGNFile *file = [[SFMPGNFile alloc] initWithString:
                        [[NSString alloc] initWithData:[reopened dataOfType:reopened.fileType error:nil] encoding:NSUTF8StringEncoding] error:nil];
                    XCTAssertEqual(file.games.count, 2);
                    SFMChessGame *first = file.games.firstObject;
                    SFMChessGame *second = file.games.lastObject;
                    XCTAssertEqualObjects(first.tags[@"Event"], @"Saved game");
                    XCTAssertEqualObjects(second.tags[@"Event"], @"Second game");
                    [first goToEnd];
                    [second goToEnd];
                    XCTAssertEqualObjects(first.uciString, @"position startpos moves d2d4 d7d5 ");
                    XCTAssertEqualObjects(second.uciString, @"position startpos moves e2e4 ");
                    [reopened close];
                }
                [savedAndReopened fulfill];
            }];
        }];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }
}

@end
