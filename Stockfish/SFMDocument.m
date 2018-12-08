//
//  SFMDocument.m
//  Stockfish
//
//  Created by Daylen Yang on 1/7/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMDocument.h"
#import "Constants.h"
#import "SFMWindowController.h"
#import "SFMPGNFile.h"

@interface SFMDocument()

@property (nonatomic) SFMPGNFile *pgnFile;

@end

@implementation SFMDocument

- (instancetype)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
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

+ (BOOL)autosavesInPlace
{
    return YES;
}
- (NSString *)defaultDraftName
{
    return @"New Game";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [self.pgnFile data];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSString *fileContents = [NSString stringWithContentsOfURL:url usedEncoding:nil error:outError];
    
    if (fileContents) {
        self.pgnFile = [[SFMPGNFile alloc] initWithString:fileContents error:outError];
        if (self.pgnFile) {
            return YES;
        }
    }

    if (outError != NULL && *outError == nil) {
        *outError = [NSError errorWithDomain:GAME_ERROR_DOMAIN code:GAME_PARSE_ERROR_CODE userInfo:nil];
    }
    return NO;
    
}

- (void)setPgnFile:(SFMPGNFile * _Nonnull)pgnFile
{
    _pgnFile = pgnFile;

    for (SFMWindowController * win in self.windowControllers) {
        win.pgnFile = pgnFile;
        [win handlePGNFile];
    }
}

- (BOOL)isInInitialState
{
    for (SFMChessGame * game in self.pgnFile.games) {
        if (!game.isInInitialState) {
            return NO;
        }
    }
    return YES;
}

@end
