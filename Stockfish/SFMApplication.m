//
//  SFMApplication.m
//  Stockfish
//
//  Created by Daylen Yang on 1/18/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMApplication.h"
#import "SFMDocument.h"
#import "SFMPGNFile.h"
#import "SFMPreferencesWindowController.h"

@interface SFMApplication()

@property SFMPreferencesWindowController *prefWinController;

@end

@implementation SFMApplication

- (IBAction)newFromClipboard:(id)sender
{
    NSDocumentController *dc = NSDocumentController.sharedDocumentController;
    NSPasteboard *pb = NSPasteboard.generalPasteboard;
    NSString *str = [pb stringForType:NSPasteboardTypeString];
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSError *err = nil;
    SFMPGNFile *game = [SFMPGNFile gameFromPgnOrFen:str error:&err];
    if (game == nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Could not understand clipboard"];
        [alert addButtonWithTitle:@"OK"];
        [alert setInformativeText:@"The text on the clipboard was not understood.  Check that the clipboard contains a valid PGN or FEN and try again."];
        [alert runModal];
        return;
    }

    SFMDocument *doc = (SFMDocument *)[dc openUntitledDocumentAndDisplay:NO error:&err];
    doc.pgnFile = game;
    [doc makeWindowControllers];
    [doc showWindows];
}

- (void)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://stockfishchess.org/mac-help/"]];
}
- (IBAction)displayPreferencesWindow:(id)sender
{
    self.prefWinController = [[SFMPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
    [self.prefWinController.window makeKeyAndOrderFront:nil];
}

@end
