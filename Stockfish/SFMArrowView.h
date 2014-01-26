//
//  SFMArrowView.h
//  Stockfish
//
//  Created by Daylen Yang on 1/26/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "../Chess/square.h"

using namespace Chess;

@interface SFMArrowView : NSView

@property Square fromSquare;
@property Square toSquare;

@property CGPoint fromPoint;
@property CGPoint toPoint;
@property CGFloat squareSideLength;

@end
