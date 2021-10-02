//
//  SFMBoardView.h
//  Stockfish
//
//  Created by Daylen Yang on 1/10/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@class SFMArrowMove;
@class SFMPosition;
@class SFMBoardView;
@class SFMMove;

#include "SFMPiece.h"

@protocol SFMBoardViewDelegate <NSObject>

/*!
 Called when the user moves a piece in the board view.
 
 @param boardView
 @param move
 */
- (void)boardView:(SFMBoardView *)boardView userDidMove:(SFMMove *)move;

@end

@protocol SFMBoardViewDataSource <NSObject>

/*!
 Called when the user is about to perform a promotion.
 
 @param boardView
 @return The piece the user wants to promote to.
 */
- (SFMPieceType)promotionPieceTypeForBoardView:(SFMBoardView *)boardView;

@end

@interface SFMBoardView : NSView

@property (weak, nonatomic) id<SFMBoardViewDelegate> delegate;
@property (weak, nonatomic) id<SFMBoardViewDataSource> dataSource;

/*!
 YES if the board is flipped (black pieces on the bottom); NO otherwise.
 */
@property (assign, nonatomic) BOOL boardIsFlipped;

/*!
 The position to display.
 */
@property (nonatomic) SFMPosition *position;

/*!
 The arrows to display.
 */
@property (nonatomic) NSArray<SFMArrowMove *> *arrows;

@end
