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
@property (weak) IBOutlet NSTextField *threadsTextField;
@property (weak) IBOutlet NSTextField *hashSizeTextField;

@end

@implementation SFMPreferencesWindowController
- (IBAction)optimizeForMinUsage:(id)sender {
    int threads = [SFMHardwareDetector minCpuCores];
    int memory = [SFMHardwareDetector minMemory];
    [DYUserDefaults setSettingForKey:NUM_THREADS_SETTING value:[NSNumber numberWithInt:threads]];
    [DYUserDefaults setSettingForKey:HASH_SIZE_SETTING value:[NSNumber numberWithInt:memory]];
    self.threadsTextField.stringValue = [NSString stringWithFormat:@"%d", threads];
    self.hashSizeTextField.stringValue = [NSString stringWithFormat:@"%d", memory];
}
- (IBAction)optimizeForMaxPerf:(id)sender {
    int threads = [SFMHardwareDetector maxCpuCores];
    int memory = [SFMHardwareDetector maxMemory];
    [DYUserDefaults setSettingForKey:NUM_THREADS_SETTING value:[NSNumber numberWithInt:threads]];
    [DYUserDefaults setSettingForKey:HASH_SIZE_SETTING value:[NSNumber numberWithInt:memory]];
    self.threadsTextField.stringValue = [NSString stringWithFormat:@"%d", threads];
    self.hashSizeTextField.stringValue = [NSString stringWithFormat:@"%d", memory];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.threadsTextField.stringValue = [[DYUserDefaults getSettingForKey:NUM_THREADS_SETTING] description];
    self.hashSizeTextField.stringValue = [[DYUserDefaults getSettingForKey:HASH_SIZE_SETTING] description];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    int threads = [[formatter numberFromString:self.threadsTextField.stringValue] intValue];
    int memory = [[formatter numberFromString:self.hashSizeTextField.stringValue] intValue];
    if ([SFMHardwareDetector isValidCpuCoreValue:threads]) {
        [DYUserDefaults setSettingForKey:NUM_THREADS_SETTING value:[NSNumber numberWithInt:threads]];
    }
    if ([SFMHardwareDetector isValidMemoryValue:memory]) {
        [DYUserDefaults setSettingForKey:HASH_SIZE_SETTING value:[NSNumber numberWithInt:memory]];
    }
}

@end
