//
//  SFMPreferenceCellView.m
//  Stockfish
//
//  Created by Daylen Yang on 12/27/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPreferenceCellView.h"

@implementation SFMPreferenceCellView

@synthesize currValue = _currValue;

- (instancetype)initWithFrame:(NSRect)frameRect {
    NSString *nibName = NSStringFromClass([self class]);
    self = [super initWithFrame:frameRect];
    if (self) {
        if ([[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil]) {
            [self.view setFrame:[self bounds]];
            [self addSubview:self.view];
        }
    }
    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [super viewWillMoveToWindow:newWindow];
    [self.textField setTarget:self];
    [self.textField setAction:@selector(textFieldDidChange:)];
    [self.slider setTarget:self];
    [self.slider setAction:@selector(sliderDidChange:)];
}

- (void)sliderDidChange:(NSSlider *)sender {
    [self.textField setIntegerValue:self.slider.integerValue];
}
- (void)textFieldDidChange:(NSTextField *)sender {
    [self.slider setIntegerValue:self.textField.integerValue];
}

- (void)setMin:(NSInteger)min {
    _min = min;
    [self.slider setMinValue:min];
    [self.numberFormatter setMinimum:[NSNumber numberWithInteger:min]];
}

- (void)setMax:(NSInteger)max {
    _max = max;
    [self.slider setMaxValue:max];
    [self.numberFormatter setMaximum:[NSNumber numberWithInteger:max]];
}

- (NSInteger)currValue {
    return self.slider.integerValue;
}

- (void)setCurrValue:(NSInteger)currValue {
    _currValue = currValue;
    [self.slider setIntegerValue:currValue];
    [self.textField setIntegerValue:currValue];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    [self.slider setEnabled:enabled];
    [self.textField setEnabled:enabled];
}

@end
