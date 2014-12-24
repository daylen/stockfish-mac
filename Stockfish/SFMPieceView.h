//
//  SFMPieceView.h
//  Stockfish
//
//  Created by Daylen Yang on 1/11/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMSquare.h"
#import "SFMPiece.h"

@interface SFMPieceView : NSImageView

@property SFMSquare square;

- (id)initWithPiece:(SFMPiece)pieceType
           onSquare:(SFMSquare)square;
- (void)moveTo:(NSPoint)point;

@end
