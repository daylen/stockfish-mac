//
//  SFMPreferencesWindowController.m
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPreferencesWindowController.h"
#import "SFMHardwareDetector.h"
#import "SFMUserDefaults.h"
#import "Constants.h"
#import "SFMUCIEngine.h"
#import "SFMPreferenceCellView.h"
#import "SFMUCIOption.h"

@interface SFMPreferencesWindowController ()

@property (weak) IBOutlet SFMPreferenceCellView *threadsCell;
@property (weak) IBOutlet SFMPreferenceCellView *hashCell;
@property (weak) IBOutlet SFMPreferenceCellView *contemptCell;
@property (weak) IBOutlet SFMPreferenceCellView *skillCell;
@property (weak) IBOutlet NSButton *chooseButton;
@property (weak) IBOutlet NSButton *recommendedSettingsButton;
@property (weak) IBOutlet NSPopUpButton *boardColorPopUpButton;

@property (nonatomic) SFMUCIEngine *optionsProbe;

@end

@implementation SFMPreferencesWindowController

- (void)awakeFromNib {
    self.threadsCell.label.stringValue = @"Threads";
    self.hashCell.label.stringValue = @"Hash (MB)";
    self.contemptCell.label.stringValue = @"Contempt";
    self.skillCell.label.stringValue = @"Skill Level";
    
    // Hidden because we haven't set the slider limits yet
    self.threadsCell.hidden = YES;
    self.hashCell.hidden = YES;
    self.contemptCell.hidden = YES;
    self.skillCell.hidden = YES;
    self.chooseButton.hidden = YES;
    self.recommendedSettingsButton.hidden = YES;
}

- (NSDictionary *)boardColors {
    return @ {
        @"Blue": @0x4B7399,
        @"Green":@0x8bCEA3,
        @"Gray": @0x999999,
        @"Orange": @0xD08B18,
        @"Violet": @0x8877B8,
        @"Red": @0xBA5546
    };

}
- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    [self.boardColorPopUpButton addItemsWithTitles:[self.boardColors allKeys]];
    NSNumber *color  =  [NSNumber numberWithInteger:[SFMUserDefaults boardColorValue]];
    self.boardColorPopUpButton.title = [self.boardColors allKeysForObject:color][0];
    // Check if infinite analysis is on
    if ([SFMUCIEngine instancesAnalyzing] != 0) {
        self.threadsCell.enabled = NO;
        self.hashCell.enabled = NO;
        self.contemptCell.enabled = NO;
        self.skillCell.enabled = NO;
        self.chooseButton.enabled = NO;
        self.recommendedSettingsButton.enabled = NO;
        NSAlert *alert = [NSAlert alertWithMessageText:@"Cannot change preferences" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Preferences cannot be changed while the engine is analyzing. Stop infinite analysis and try again."];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
    }
    
    self.optionsProbe = [[SFMUCIEngine alloc] initOptionsProbe];
    self.optionsProbe.delegate = self;
}

- (void)windowWillClose:(NSNotification *)notification {
    // Save the preferences
    [SFMUserDefaults setThreadsValue:self.threadsCell.currValue];
    [SFMUserDefaults setHashValue:self.hashCell.currValue];
    [SFMUserDefaults setContemptValue:self.contemptCell.currValue];
    [SFMUserDefaults setSkillLevelValue:self.skillCell.currValue];
    [SFMUserDefaults setBoardColorValue:[self.boardColors[self.boardColorPopUpButton.title] intValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
}

- (IBAction)boardColorItemSelected:(id)sender{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    [SFMUserDefaults setBoardColorValue:[self.boardColors[btn.title] intValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
}

- (IBAction)clickedChooseFolder:(NSButton *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *url = [openPanel URL];
            NSError *error = nil;
            NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSAlert alertWithMessageText:@"Uh-oh" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", [error description]] beginSheetModalForWindow:self.window completionHandler:nil];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSAlert alertWithMessageText:@"Saved!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Selected path to Syzygy tablebases was saved."] beginSheetModalForWindow:self.window completionHandler:nil];
                });
                [SFMUserDefaults setSandboxBookmarkData:bookmarkData];
                [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
            }
        }
    }];
}

- (IBAction)clickedUseRecommended:(NSButton *)sender {
    self.threadsCell.currValue = self.threadsCell.max / 2;
    self.hashCell.currValue = self.hashCell.max / 2;
    self.contemptCell.currValue = 0;
    self.skillCell.currValue = self.skillCell.max;
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
}

- (void)applyLimits:(SFMUCIOption *)option toSlider:(SFMPreferenceCellView *)view currValue:(NSInteger)currValue {
    view.min = option.minValue;
    if (option.type == SFMUCIOptionTypeThreads) {
        view.max = MIN(option.maxValue, [SFMHardwareDetector maxThreads]);
        view.slider.numberOfTickMarks = view.max - view.min + 1;
        view.slider.allowsTickMarkValuesOnly = YES;
    } else if (option.type == SFMUCIOptionTypeHash) {
        view.max = MIN(option.maxValue, [SFMHardwareDetector maxMemory]);
    } else {
        view.max = option.maxValue;
    }
    view.currValue = currValue;
    view.hidden = NO;
}

#pragma mark - SFMUCIEngineDelegate

- (void)uciEngine:(SFMUCIEngine *)engine didGetEngineName:(NSString *)name {
    // no op
}
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewCurrentMove:(SFMMove *)move
           number:(NSInteger)moveNumber depth:(NSInteger)depth {
    // no op
}
- (void)uciEngine:(SFMUCIEngine *)engine didGetNewLine:(SFMUCILine *)line {
    // no op
}
- (void)uciEngine:(SFMUCIEngine *)engine didGetOptions:(NSArray* /* of SFMUCIOption */)options {
    for (SFMUCIOption *option in options) {
        if (option.type == SFMUCIOptionTypeThreads) {
            [self applyLimits:option toSlider:self.threadsCell currValue:[SFMUserDefaults threadsValue]];
        } else if (option.type == SFMUCIOptionTypeHash) {
            [self applyLimits:option toSlider:self.hashCell currValue:[SFMUserDefaults hashValue]];
        } else if (option.type == SFMUCIOptionTypeNumber) {
            if ([option.name isEqualToString:@"Contempt"]) {
                [self applyLimits:option toSlider:self.contemptCell currValue:[SFMUserDefaults contemptValue]];
            } else if ([option.name isEqualToString:@"Skill Level"]) {
                [self applyLimits:option toSlider:self.skillCell currValue:[SFMUserDefaults skillLevelValue]];
            }
        }
    }
    self.chooseButton.hidden = NO;
    self.recommendedSettingsButton.hidden = NO;
}


@end
