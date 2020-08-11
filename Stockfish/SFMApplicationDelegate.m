//
//  SFMApplicationDelegate.m
//  Stockfish
//
//  Created by Daylen Yang on 1/1/18.
//  Copyright © 2018 Daylen Yang. All rights reserved.
//

#import "SFMApplicationDelegate.h"

@implementation SFMApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"Started app");
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
}

@end
