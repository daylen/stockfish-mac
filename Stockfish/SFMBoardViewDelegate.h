//
//  SFMBoardViewDelegate.h
//  Stockfish
//
//  Created by Daylen Yang on 1/12/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "../Chess/position.h"

using namespace Chess;

@protocol SFMBoardViewDelegate <NSObject>

- (Move)doMoveFrom:(Square)fromSquare to:(Square)toSquare promotion:(PieceType)desiredPieceType;
- (Move)doMoveFrom:(Square)fromSquare to:(Square)toSquare;

@end
