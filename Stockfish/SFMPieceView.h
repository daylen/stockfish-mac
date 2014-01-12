//
//  SFMPieceView.h
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SFMBoardView.h"

#include "../Chess/position.h"
#include "../Chess/square.h"

using namespace Chess;

@interface SFMPieceView : NSImageView

@property Square square;

- (id)initWithPieceType:(Piece)pieceType
               onSquare:(Square)square
              boardView:(SFMBoardView *)boardView;
- (void)moveTo:(NSPoint)point;

@end
