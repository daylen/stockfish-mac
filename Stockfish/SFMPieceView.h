//
//  SFMPieceView.h
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "../Chess/position.h"
#include "../Chess/square.h"

using namespace Chess;

@interface SFMPieceView : NSImageView

@property Square square;

- (id)initWithFrame:(NSRect)frameRect pieceType:(Piece)pieceType;

@end
