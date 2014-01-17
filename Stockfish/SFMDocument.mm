//
//  SFMDocument.m
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMDocument.h"
#import "SFMWindowController.h"
#import "SFMPGNFile.h"
#import "SFMPreferencesWindowController.h"

#include "../Chess/position.h"
#include "../Chess/bitboard.h"
#include "../Chess/direction.h"
#include "../Chess/mersenne.h"
#include "../Chess/movepick.h"

using namespace Chess;

@interface SFMDocument()

@property SFMPGNFile *pgnFile;
@property SFMPreferencesWindowController *prefWinController;

@end

@implementation SFMDocument

- (id)init
{
    self = [super init];
    if (self) {
        // We have to call all these init methods, or else Chess::Position
        // might crash
        
        init_mersenne();
        init_direction_table();
        init_bitboards();
        Position::init_zobrist();
        Position::init_piece_square_tables();
        MovePicker::init_phase_table();
    }
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self = [self init];
    if (self) {
        self.pgnFile = [[SFMPGNFile alloc] init];
    }
    return self;
}

- (void)makeWindowControllers
{
    SFMWindowController *windowController = [[SFMWindowController alloc] initWithWindowNibName:@"SFMDocument"];
    windowController.pgnFile = self.pgnFile;
    [self addWindowController:windowController];
}
- (IBAction)displayPreferencesWindow:(id)sender
{
    self.prefWinController = [[SFMPreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
    [self.prefWinController.window makeKeyAndOrderFront:nil];
}
+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [self.pgnFile data];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    BOOL readSuccess = NO;
    NSString *fileContents = [NSString stringWithContentsOfURL:url usedEncoding:nil error:outError];
    
    if (fileContents) {
        readSuccess = YES;
        self.pgnFile = [[SFMPGNFile alloc] initWithString:fileContents];
    }
    return readSuccess;
    
}

@end
