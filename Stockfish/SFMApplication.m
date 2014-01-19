//
//  SFMApplication.m
//  Stockfish
//
//  Created by Daylen Yang on 1/18/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMApplication.h"

@implementation SFMApplication

- (void)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://stockfishchess.org/mac/"]];
}

@end
