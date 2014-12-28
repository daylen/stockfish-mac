//
//  SFMPreferenceCellView.h
//  Stockfish
//
//  Created by Daylen Yang on 12/27/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SFMPreferenceCellView : NSView

@property (nonatomic, strong) IBOutlet NSView *view;

@property (weak) IBOutlet NSTextField *label;
@property (weak) IBOutlet NSSlider *slider;
@property (weak) IBOutlet NSTextField *textField;
@property (weak) IBOutlet NSNumberFormatter *numberFormatter;

@property (assign, nonatomic) NSInteger min;
@property (assign, nonatomic) NSInteger max;
@property (assign, nonatomic) NSInteger currValue;
@property (assign, nonatomic) BOOL enabled;

@end
