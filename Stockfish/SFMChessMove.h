//
//  SFMChessMove.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "../Chess/position.h"

using namespace Chess;

@interface SFMChessMove : NSObject

@property Move move;
@property UndoInfo undoInfo;

- (id)initWithMove:(Move)move undoInfo:(UndoInfo)undoInfo;

@end
