//
//  SFMBoardView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/10/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMPosition.h"
#import "SFMBoardView.h"
#import "Constants.h"
#import "SFMPieceView.h"
#import "SFMArrowView.h"
#import "SFMMove.h"

@interface SFMBoardView()

#pragma mark - Colors

@property NSColor *boardColor;
@property NSColor *lightSquareColor;
@property NSColor *darkSquareColor;
@property NSColor *fontColor;
@property NSColor *highlightColor;

#pragma mark -

@property (nonatomic) NSMutableArray /* of SFMPieceView */ *pieceViews;
@property (nonatomic) NSMutableArray /* of SFMArrowView */ *arrowViews;
@property (nonatomic) NSArray /* of NSNumber */ *highlightedSquares;
@property (assign, nonatomic) BOOL hasDragged;
@property (nonatomic) SFMSquare fromSquare;
@property (nonatomic) SFMSquare toSquare;
@property (assign, nonatomic) CGFloat leftInset;
@property (assign, nonatomic) CGFloat topInset;
@property (assign, nonatomic) CGFloat squareSideLength;

@end

@implementation SFMBoardView

#pragma mark - Setters

//- (void)updatePieceViews // and the arrow views too!
//{
//    numHighlightedSquares = 0;
//    
////    assert(self.position->is_ok());
//    
//    // Invalidate pieces array
//    self.pieces = [NSMutableArray new];
//    // Remove subviews
//    [self setSubviews:[NSArray new]];
//    
//    for (SFMSquare sq = SQ_A1; sq <= SQ_H8; sq++) {
//        SFMPiece piece = [self.position pieceOnSquare:sq];
//        if (piece != EMPTY) {
//            SFMPieceView *pieceView = [[SFMPieceView alloc] initWithPiece:piece onSquare:sq];
//            [self addSubview:pieceView];
//            [self.pieces addObject:pieceView];
//        }
//    }
//    
//    // Now for the arrows
//    [self updateArrowViews];
//    
//    [self setNeedsDisplay:YES];
//}

//- (void)updateArrowViews
//{
//    for (NSView *view in self.subviews) {
//        if ([view isKindOfClass:[SFMArrowView class]]) {
//            [view removeFromSuperview];
//        }
//    }
//    for (SFMArrowView *arrowView in self.arrows) {
//        [self addSubview:arrowView];
//        
//        arrowView.fromPoint = [self coordinatesForSquare:arrowView.fromSquare leftOffset:leftInset + squareSideLength / 2 topOffset:topInset + squareSideLength / 2 sideLength:squareSideLength];
//        arrowView.toPoint = [self coordinatesForSquare:arrowView.toSquare leftOffset:leftInset + squareSideLength / 2 topOffset:topInset + squareSideLength / 2 sideLength:squareSideLength];
//        arrowView.squareSideLength = squareSideLength;
//        
//        [arrowView setFrame:self.bounds];
//        [arrowView setNeedsDisplay:YES];
//    }
//}

- (void)setBoardIsFlipped:(BOOL)boardIsFlipped {
    _boardIsFlipped = boardIsFlipped;
    [self setNeedsDisplay:YES];
}

- (void)setPosition:(SFMPosition *)position {
    _position = position;
    [self setNeedsDisplay:YES];
}

- (void)setArrows:(NSArray *)arrows {
    _arrows = arrows;
    [self setNeedsDisplay:YES];
}

#pragma mark - Init
- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.wantsLayer = YES;
        _boardIsFlipped = NO;
        
        _boardColor = [NSColor blackColor];
        _lightSquareColor = [NSColor whiteColor];
        _darkSquareColor = [NSColor brownColor];
        _fontColor = [NSColor whiteColor];
        _highlightColor = [NSColor colorWithSRGBRed:1 green:1 blue:0 alpha:0.7];
        
        _pieceViews = [[NSMutableArray alloc] init];
        _arrowViews = [[NSMutableArray alloc] init];
        _highlightedSquares = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Draw
- (void)drawRect:(NSRect)dirtyRect {
    
    // Draw the big square
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    
    [self.boardColor set];
    
    CGFloat left = (width - boardSideLength) / 2;
    CGFloat top = (height - boardSideLength) / 2;
    
    NSRectFill(NSMakeRect(left, top, boardSideLength, boardSideLength));
    [[NSShadow new] set];
    
    _leftInset = left + INTERIOR_BOARD_MARGIN;
    _topInset = top + INTERIOR_BOARD_MARGIN;
    _squareSideLength = (boardSideLength - 2 * INTERIOR_BOARD_MARGIN) / 8;
    
    // Draw 64 squares
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            if ((i + j) % 2 == 0) {
                [self.lightSquareColor set];
            } else {
                [self.darkSquareColor set];
            }
            NSRectFill(NSMakeRect(_leftInset + i * _squareSideLength, _topInset + j * _squareSideLength, _squareSideLength, _squareSideLength));
        }
    }
    
    // Draw coordinates
    NSString *str;
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [pStyle setAlignment:NSCenterTextAlignment];
    
    for (int i = 0; i < 8; i++) {
        // Down
        str = [NSString stringWithFormat:@"%d", self.boardIsFlipped ? (i + 1) : (8 - i)];
        [str drawInRect:NSMakeRect(left, _topInset + _squareSideLength / 2 - FONT_SIZE / 2 + i * _squareSideLength, INTERIOR_BOARD_MARGIN, _squareSideLength) withAttributes:@{NSParagraphStyleAttributeName: pStyle, NSForegroundColorAttributeName: self.fontColor}];
        // Across
        str = [NSString stringWithFormat:@"%c", self.boardIsFlipped ? ('h' - i) : ('a' + i)];
        [str drawInRect:NSMakeRect(_leftInset + i * _squareSideLength, _topInset + 8 * _squareSideLength, _squareSideLength, INTERIOR_BOARD_MARGIN) withAttributes:@{NSParagraphStyleAttributeName: pStyle, NSForegroundColorAttributeName: self.fontColor}];
    }
    
    // Draw pieces
    
    // TODO pieces
    
//    for (SFMPieceView *pieceView in self.pieces) {
//        CGPoint coordinate = [self coordinatesForSquare:pieceView.square leftOffset:_leftInset topOffset:_topInset sideLength:_squareSideLength];
//        [pieceView setFrame:NSMakeRect(coordinate.x, coordinate.y, squareSideLength, _squareSideLength)];
//        [pieceView setNeedsDisplay:YES];
//        
//    }
    
    // Draw highlights
    [self.highlightColor set]; // Highlight color
    
    // TODO highlights
    
//    
//    for (int i = 0; i < numHighlightedSquares; i++) {
//        CGPoint coordinate = [self coordinatesForSquare:_highlightedSquares[i] leftOffset:_leftInset topOffset:_topInset sideLength:_squareSideLength];
//        [NSBezierPath fillRect:NSMakeRect(coordinate.x, coordinate.y, _squareSideLength, _squareSideLength)];
//    }
    
    // Draw arrows
    for (SFMArrowView *arrowView in self.arrows) {
        
        arrowView.fromPoint = [self coordinatesForSquare:arrowView.fromSquare leftOffset:_leftInset + _squareSideLength / 2 topOffset:_topInset + _squareSideLength / 2 sideLength:_squareSideLength];
        arrowView.toPoint = [self coordinatesForSquare:arrowView.toSquare leftOffset:_leftInset + _squareSideLength / 2 topOffset:_topInset + _squareSideLength / 2 sideLength:_squareSideLength];
        arrowView.squareSideLength = _squareSideLength;

        [arrowView setFrame:self.bounds];
        [arrowView setNeedsDisplay:YES];
    }
}

#pragma mark - Helper methods

- (CGPoint)coordinatesForSquare:(SFMSquare)sq
                     leftOffset:(CGFloat)left
                      topOffset:(CGFloat)top
                     sideLength:(CGFloat)sideLength
{
    int letter = sq % 8;
    int number = sq / 8;
    CGFloat l, t;
    if (self.boardIsFlipped) {
        l = left + (7 - letter) * sideLength;
        t = top + number * sideLength;
    } else {
        l = left + letter * sideLength;
        t = top + (7 - number) * sideLength;
    }
    return CGPointMake(l, t);
}
- (SFMSquare)squareForCoordinates:(NSPoint)point
                    leftOffset:(CGFloat)left
                     topOffset:(CGFloat)top
                    sideLength:(CGFloat)sideLength
{
    int letter, number;
    if (self.boardIsFlipped) {
        letter = (int) (point.x - left) / (int) sideLength;
        letter = 7 - letter;
        number = (int) (point.y - top) / (int) sideLength;
    } else {
        letter = (int) (point.x - left) / (int) sideLength;
        number = (int) (point.y - top) / (int) sideLength;
        number = 7 - number;
    }
    if (!(letter >= 0 && letter <= 7 && number >= 0 && number <= 7)) {
        return SQ_NONE;
    }
    return 8 * number + letter;
}

#pragma mark - Interaction

- (void)mouseDown:(NSEvent *)theEvent
{
    _hasDragged = NO;
    
    // Figure out which square you clicked on
    NSPoint clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    SFMSquare clickedSquare = [self squareForCoordinates:clickLocation leftOffset:_leftInset topOffset:_topInset sideLength:_squareSideLength];
    
    if ([self.highlightedSquares count] == 0) {
        // You haven't selected a valid piece, since there are no highlighted squares on the board.
        if (clickedSquare != SQ_NONE) {
            _fromSquare = clickedSquare;
            self.highlightedSquares = [self.position legalSquaresFromSquare:clickedSquare];
        }
    } else {
        // Is it possible to move to the square you clicked on?
        BOOL isValidMove = [self.highlightedSquares containsObject:[NSNumber numberWithInteger:clickedSquare]];
        
        if (!isValidMove) {
            // If it's not a valid move, cancel the highlight
            self.highlightedSquares = @[];
            _fromSquare = SQ_NONE;
        }
    }
    
    [self setNeedsDisplay:YES];
    
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    _hasDragged = YES;
    
    // Make the dragged piece follow the mouse
    NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // Center the piece
    mouseLocation.x -= _squareSideLength / 2;
    mouseLocation.y -= _squareSideLength / 2;
    
    SFMPieceView *draggedPiece = [self pieceViewOnSquare:_fromSquare];
    [draggedPiece setFrameOrigin:mouseLocation];
    [draggedPiece setNeedsDisplay:YES];
    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Figure out which square you let go on
    NSPoint upLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _toSquare = [self squareForCoordinates:upLocation leftOffset:_leftInset topOffset:_topInset sideLength:_squareSideLength];
    
    // Is it possible to move to the square you clicked on?
    BOOL isValidMove = [self.highlightedSquares containsObject:[NSNumber numberWithInteger:_toSquare]];
    
    if (isValidMove) {
        // You previously selected a valid piece, and now you're trying to move it
        
        SFMPieceType pieceType = NO_PIECE_TYPE;
        
        // Handle promotions
        if ([self.position isPromotion:[[SFMMove alloc] initWithFrom:self.fromSquare to:self.toSquare]]) {
            pieceType = [self.dataSource promotionPieceTypeForBoardView:self];
        }
        
        // HACK: Castling. The user probably tries to move the king two squares to
        // the side when castling, but Stockfish internally encodes castling moves
        // as "king captures rook". We handle this by adjusting tSq when the user
        // tries to move the king two squares to the side:
        BOOL castle = NO;
        
        if (self.fromSquare == SQ_E1 && self.toSquare == SQ_G1 &&
            [self.position pieceOnSquare:self.fromSquare] == WK) {
            self.toSquare = SQ_H1;
            castle = YES;
        } else if (self.fromSquare == SQ_E1 && self.toSquare == SQ_C1 &&
                   [self.position pieceOnSquare:self.fromSquare] == WK) {
            self.toSquare = SQ_A1;
            castle = YES;
        } else if (self.fromSquare == SQ_E8 && self.toSquare == SQ_G8 &&
                   [self.position pieceOnSquare:self.fromSquare] == BK) {
            self.toSquare = SQ_H8;
            castle = YES;
        } else if (self.fromSquare == SQ_E8 && self.toSquare == SQ_C8 &&
                   [self.position pieceOnSquare:self.fromSquare] == BK) {
            self.toSquare = SQ_A8;
            castle = YES;
        }
        
        self.highlightedSquares = @[];
        
        SFMMove *move;
        if (pieceType != NO_PIECE_TYPE) {
            move = [[SFMMove alloc] initWithFrom:self.fromSquare to:self.toSquare promotion:pieceType];
        } else {
            move = [[SFMMove alloc] initWithFrom:self.fromSquare to:self.toSquare];
        }
        
        [self.delegate boardView:self userDidMove:move];
    } else {
        // TODO don't need this?
        // Not a valid move, slide it back
        SFMPieceView *piece = [self pieceViewOnSquare:self.fromSquare];
        [piece moveTo:[self coordinatesForSquare:piece.square leftOffset:self.leftInset topOffset:self.topInset sideLength:self.squareSideLength]];
    }
    
    if (self.hasDragged) {
        self.highlightedSquares = @[];
    }
    
    [self setNeedsDisplay:YES];
    
}

- (SFMPieceView *)pieceViewOnSquare:(SFMSquare)square
{
    for (SFMPieceView *pieceView in self.pieceViews) {
        if (pieceView.square == square) {
            return pieceView;
        }
    }
    return nil;
}

// Sets the piece view's square property and executes an animated move
- (void)movePieceView:(SFMPieceView *)pieceView toSquare:(SFMSquare)square
{
    pieceView.square = square;
    [pieceView moveTo:[self coordinatesForSquare:square leftOffset:_leftInset topOffset:_topInset sideLength:_squareSideLength]];
}
//
//- (void)animatePieceOnSquare:(SFMSquare)fromSquare
//                          to:(SFMSquare)toSquare
//                   promotion:(SFMPieceType)desiredPromotionPiece
//                shouldCastle:(BOOL)shouldCastle
//{
//    
//    // Find the piece(s)
//    SFMPieceView *thePiece = [self pieceViewOnSquare:fromSquare];
//    SFMPieceView *capturedPiece = [self pieceViewOnSquare:toSquare];
//    
//    if (shouldCastle) {
//        // Castle
//        if (toSquare == SQ_H1) {
//            // White kingside
//            [self movePieceView:[self pieceViewOnSquare:SQ_H1] toSquare:SQ_F1]; // Rook
//            [self movePieceView:thePiece toSquare:SQ_G1]; // King
//            
//        } else if (toSquare == SQ_A1) {
//            // White queenside
//            [self movePieceView:[self pieceViewOnSquare:SQ_A1] toSquare:SQ_D1]; // Rook
//            [self movePieceView:thePiece toSquare:SQ_C1]; // King
//            
//        } else if (toSquare == SQ_H8) {
//            // Black kingside
//            [self movePieceView:[self pieceViewOnSquare:SQ_H8] toSquare:SQ_F8]; // Rook
//            [self movePieceView:thePiece toSquare:SQ_G8]; // King
//            
//        } else {
//            // Black queenside
//            [self movePieceView:[self pieceViewOnSquare:SQ_A8] toSquare:SQ_D8]; // Rook
//            [self movePieceView:thePiece toSquare:SQ_C8]; // King
//            
//        }
//    } else if (desiredPromotionPiece != NO_PIECE_TYPE) {
//        // Promotion
//        
//        // Remove all relevant pieces
//        [thePiece removeFromSuperview];
//        [self.pieces removeObject:thePiece];
//        
//        if (capturedPiece) {
//            // You could capture while promoting
//            [capturedPiece removeFromSuperview];
//            [self.pieces removeObject:capturedPiece];
//        }
//        
//        // Create a new piece view and add it
//        SFMPieceView *pieceView = [[SFMPieceView alloc] initWithPieceType:piece_of_color_and_type(self.position->side_to_move(), desiredPromotionPiece) onSquare:toSquare];
//        [self addSubview:pieceView];
//        [self.pieces addObject:pieceView];
//    } else if (capturedPiece) {
//        // Capture
//        
//        // Remove the captured piece
//        [capturedPiece removeFromSuperview];
//        [self.pieces removeObject:capturedPiece];
//        
//        // Do a normal move
//        [self movePieceView:thePiece toSquare:toSquare];
//    } else if (type_of_piece(self.position->piece_on(fromSquare)) == PAWN &&
//               square_file(fromSquare) != square_file(toSquare)) {
//        // En passant
//        
//        // Find the en passant square
//        Square enPassantSquare = toSquare - pawn_push(self.position->side_to_move());
//        
//        // Remove the piece on that square
//        SFMPieceView *toRemove = [self pieceViewOnSquare:enPassantSquare];
//        [toRemove removeFromSuperview];
//        [self.pieces removeObject:toRemove];
//        
//        // Do a normal move
//        [self movePieceView:thePiece toSquare:toSquare];
//    } else {
//        // Normal move
//        [self movePieceView:thePiece toSquare:toSquare];
//    }
//    
//}

//#pragma mark - Promotion
//
//// TODO move this to delegate
//
//- (SFMPieceType)getDesiredPromotionPiece
//{    
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert addButtonWithTitle:@"Queen"];
//    [alert addButtonWithTitle:@"Rook"];
//    [alert addButtonWithTitle:@"Bishop"];
//    [alert addButtonWithTitle:@"Knight"];
//    [alert setMessageText:@"Pawn Promotion"];
//    [alert setInformativeText:@"What would you like to promote your pawn to?"];
//    [alert setAlertStyle:NSWarningAlertStyle];
//    NSInteger choice = [alert runModal];
//    switch (choice) {
//        case 1000:
//            return QUEEN;
//        case 1001:
//            return ROOK;
//        case 1002:
//            return BISHOP;
//        case 1003:
//            return KNIGHT;
//        default:
//            return NO_PIECE_TYPE;
//    }
//}


#pragma mark - Misc

- (BOOL)isFlipped
{
    return YES;
}

@end
