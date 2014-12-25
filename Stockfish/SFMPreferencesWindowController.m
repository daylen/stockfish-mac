//
//  SFMPreferencesWindowController.m
//  Stockfish
//
//  Created by Daylen Yang on 1/16/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPreferencesWindowController.h"
#import "SFMHardwareDetector.h"
#import "DYUserDefaults.h"
#import "Constants.h"

@interface SFMPreferencesWindowController ()
@property (weak) IBOutlet NSPopUpButton *threadsChooser;
@property (weak) IBOutlet NSPopUpButton *memoryChooser;

@end

@implementation SFMPreferencesWindowController
- (IBAction)optimizeForMinUsage:(id)sender {
    int threads = [SFMHardwareDetector minimumSupportedThreads];
    int memory = (int) pow(2, [SFMHardwareDetector minimumMemoryPower]);
    
    [DYUserDefaults setSettingForKey:NUM_THREADS_SETTING value:@(threads)];
    [DYUserDefaults setSettingForKey:HASH_SIZE_SETTING value:@(memory)];
    
    [self updateViewFromSettings];
}
- (IBAction)optimizeForMaxPerf:(id)sender {
    int threads = [SFMHardwareDetector maximumSupportedThreads];
    int memory = (int) pow(2, [SFMHardwareDetector maximumMemoryPower]);
    
    [DYUserDefaults setSettingForKey:NUM_THREADS_SETTING value:@(threads)];
    [DYUserDefaults setSettingForKey:HASH_SIZE_SETTING value:@(memory)];
    
    [self updateViewFromSettings];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Populate the choosers
    for (int i = 1; i <= [SFMHardwareDetector maximumSupportedThreads]; i++) {
        [self.threadsChooser addItemWithTitle:[NSString stringWithFormat:@"%d", i]];
    }
    for (int i = [SFMHardwareDetector minimumMemoryPower]; i <= [SFMHardwareDetector maximumMemoryPower]; i++) {
        [self.memoryChooser addItemWithTitle:[NSString stringWithFormat:@"%d MB", (int) pow(2, i)]];
    }
    
    [self updateViewFromSettings];
    
}
- (void)updateViewFromSettings
{
    // Select the correct option
    int threads = [[DYUserDefaults getSettingForKey:NUM_THREADS_SETTING] intValue];
    int memory = [[DYUserDefaults getSettingForKey:HASH_SIZE_SETTING] intValue];
    int memoryIndex = log2(memory) - [SFMHardwareDetector minimumMemoryPower];
    
    [self.threadsChooser selectItemAtIndex:threads - 1];
    [self.memoryChooser selectItemAtIndex:memoryIndex];
    
}

- (IBAction)pickedOption:(id)sender {
    int threads = (int) [self.threadsChooser indexOfSelectedItem] + 1;
    int memoryPower = (int) [self.memoryChooser indexOfSelectedItem] + [SFMHardwareDetector minimumMemoryPower];
    int memory = (int) pow(2, memoryPower);
        
    [DYUserDefaults setSettingForKey:NUM_THREADS_SETTING value:@(threads)];
    [DYUserDefaults setSettingForKey:HASH_SIZE_SETTING value:@(memory)];
}


@end
