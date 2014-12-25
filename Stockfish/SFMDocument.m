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

@interface SFMDocument()

@property SFMPGNFile *pgnFile;

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
    BOOL readSuccess = NO;
    NSString *fileContents = [NSString stringWithContentsOfURL:url usedEncoding:nil error:outError];
    
    if (fileContents) {
        readSuccess = YES;
        self.pgnFile = [[SFMPGNFile alloc] initWithString:fileContents];
    }
    return readSuccess;
    
}

@end
