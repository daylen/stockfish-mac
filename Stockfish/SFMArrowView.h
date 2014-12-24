//
//  SFMArrowView.h
//  Stockfish
//
//  Created by Daylen Yang on 1/26/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMSquare.h"

@interface SFMArrowView : NSView

@property SFMSquare fromSquare;
@property SFMSquare toSquare;

@property CGPoint fromPoint;
@property CGPoint toPoint;
@property CGFloat squareSideLength;

@end
