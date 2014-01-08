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

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self = [super init];
    if (self) {
        NSLog(@"Creating new file");
        self.pgnFile = [SFMPGNFile new];
    }
    return self;
}

- (void)makeWindowControllers
{
    SFMWindowController *windowController = [[SFMWindowController alloc] initWithWindowNibName:@"SFMDocument"];
    [self addWindowController:windowController];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSLog(@"Saving file to disk.");
    return [self.pgnFile data];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    @try {
        self.pgnFile = [self.pgnFile initWithData:data];
    }
    @catch (NSException *exception) {
        NSLog(@"Problem reading file.");
        return NO;
    }
    NSLog(@"File successfully read.");
    return YES;
}

@end
