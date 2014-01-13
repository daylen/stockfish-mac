//
//  SFMBoardView.m
//  Stockfish
//
//  Created by Daylen Yang on 1/10/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMBoardView.h"
#import "Constants.h"
#import "SFMPieceView.h"

#include "../Chess/square.h"

@interface SFMBoardView()

@property NSColor *feltBackground;
@property NSColor *boardColor;
@property NSColor *lightSquareColor;
@property NSColor *darkSquareColor;
@property NSColor *fontColor;
@property NSColor *highlightColor;
@property NSShadow *boardShadow;
@property NSMutableArray *pieces;

@end

@implementation SFMBoardView

#pragma mark - Constants
#define EXTERIOR_BOARD_MARGIN 40
#define INTERIOR_BOARD_MARGIN 20
#define BOARD_SHADOW_BLUR_RADIUS 30
#define FONT_SIZE 12

#pragma mark - Instance Variables
Square highlightedSquares[32];
int numHighlightedSquares;
Square selectedSquare;
CGFloat leftInset;
CGFloat topInset;
CGFloat squareSideLength;

#pragma mark - Setters

- (void)setPosition:(Chess::Position *)position
{
    _position = position;
    
    assert(position->is_ok());
    
    // Invalidate pieces array
    self.pieces = [NSMutableArray new];
    // Remove subviews
    [self setSubviews:[NSArray new]];
    
    for (Square sq = SQ_A1; sq <= SQ_H8; sq++) {
        Piece piece = _position->piece_on(sq);
        if (piece != EMPTY) {
            SFMPieceView *pieceView = [[SFMPieceView alloc] initWithPieceType:piece onSquare:sq boardView:self];
            [self addSubview:pieceView];
            [self.pieces addObject:pieceView];
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)setBoardIsFlipped:(BOOL)boardIsFlipped
{
    _boardIsFlipped = boardIsFlipped;
    [self setNeedsDisplay:YES];
}

#pragma mark - Init
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        
        self.boardIsFlipped = NO;
        
        self.feltBackground = [NSColor colorWithPatternImage:[NSImage imageNamed:@"Felt"]];
        
        self.boardColor = [NSColor blackColor];
        self.lightSquareColor = [NSColor whiteColor];
        self.darkSquareColor = [NSColor brownColor];
        self.fontColor = [NSColor whiteColor];
        self.highlightColor = [NSColor colorWithRed:1 green:1 blue:0 alpha:0.7];
        
        self.boardShadow = [NSShadow new];
        [self.boardShadow setShadowBlurRadius:BOARD_SHADOW_BLUR_RADIUS];
        [self.boardShadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.75]]; // Gray
        
        self.position = new Position([FEN_START_POSITION UTF8String]);
        
    }
    return self;
}

#pragma mark - Draw
- (void)drawRect:(NSRect)dirtyRect
{
    // Draw a felt background
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [self.feltBackground set];
    NSRectFill([self bounds]);
    [context restoreGraphicsState];
    
    // Draw the big square
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    
    [self.boardColor set];
    [self.boardShadow set];
    
    CGFloat left = (width - boardSideLength) / 2;
    CGFloat top = (height - boardSideLength) / 2;
    
    NSRectFill(NSMakeRect(left, top, boardSideLength, boardSideLength));
    [[NSShadow new] set];
    
    leftInset = left + INTERIOR_BOARD_MARGIN;
    topInset = top + INTERIOR_BOARD_MARGIN;
    squareSideLength = (boardSideLength - 2 * INTERIOR_BOARD_MARGIN) / 8;
    
    // Draw 64 squares
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            if ((i + j) % 2 == 0) {
                [self.lightSquareColor set];
            } else {
                [self.darkSquareColor set];
            }
            NSRectFill(NSMakeRect(leftInset + i * squareSideLength, topInset + j * squareSideLength, squareSideLength, squareSideLength));
        }
    }
    
    // Draw coordinates
    NSString *str = [NSString new];
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [pStyle setAlignment:NSCenterTextAlignment];
    
    for (int i = 0; i < 8; i++) {
        // Down
        str = [NSString stringWithFormat:@"%d", self.boardIsFlipped ? (i + 1) : (8 - i)];
        [str drawInRect:NSMakeRect(left, topInset + squareSideLength / 2 - FONT_SIZE / 2 + i * squareSideLength, INTERIOR_BOARD_MARGIN, squareSideLength) withAttributes:@{NSParagraphStyleAttributeName: pStyle, NSForegroundColorAttributeName: self.fontColor}];
        // Across
        str = [NSString stringWithFormat:@"%c", self.boardIsFlipped ? ('h' - i) : ('a' + i)];
        [str drawInRect:NSMakeRect(leftInset + i * squareSideLength, topInset + 8 * squareSideLength, squareSideLength, INTERIOR_BOARD_MARGIN) withAttributes:@{NSParagraphStyleAttributeName: pStyle, NSForegroundColorAttributeName: self.fontColor}];
    }
    
    // Draw pieces
    for (SFMPieceView *pieceView in self.pieces) {
        CGPoint coordinate = [self coordinatesForSquare:pieceView.square leftOffset:leftInset topOffset:topInset sideLength:squareSideLength];
        [pieceView setFrame:NSMakeRect(coordinate.x, coordinate.y, squareSideLength, squareSideLength)];
        [pieceView setNeedsDisplay:YES];
        
    }
    
    // Draw highlights
    for (int i = 0; i < numHighlightedSquares; i++) {
        [self.highlightColor set];
        CGPoint coordinate = [self coordinatesForSquare:highlightedSquares[i] leftOffset:leftInset topOffset:topInset sideLength:squareSideLength];
        [NSBezierPath fillRect:NSMakeRect(coordinate.x, coordinate.y, squareSideLength, squareSideLength)];
    }
    
}

#pragma mark - Helper methods

- (CGPoint)coordinatesForSquare:(Square)sq
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
- (Square)squareForCoordinates:(NSPoint)point
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
    return static_cast<Square>(8 * number + letter);
}

#pragma mark - Interaction

- (void)mouseUp:(NSEvent *)theEvent
{
    // Figure out which square you clicked on
    NSPoint clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    Square clickedSquare = [self squareForCoordinates:clickLocation leftOffset:leftInset topOffset:topInset sideLength:squareSideLength];
    
    if (numHighlightedSquares == 0) {
        // You haven't selected a valid piece, since there are no highlighted
        // squares on the board.
        
        [self displayPossibleMoveHighlightsForPieceOnSquare:clickedSquare];
        
    } else {
        // You previously selected a valid piece, and now you're trying to move it
        
        if (clickedSquare != SQ_NONE) {
            
            // Is it possible to move to the square you clicked on?
            BOOL isValidMove = NO;
            for (int i = 0; i < numHighlightedSquares; i++) {
                if (highlightedSquares[i] == clickedSquare) {
                    isValidMove = YES;
                    break;
                }
            }
            
            if (isValidMove) {
                /* TODO
                 - castling
                 - en passant
                 - promotion
                 */
                Move theMove = [self.delegate doMoveFrom:selectedSquare to:clickedSquare];
                UndoInfo u;
                self.position->do_move(theMove, u);
                [self animatePieceOnSquare:selectedSquare to:clickedSquare];
            }
            
        }
        numHighlightedSquares = 0;
    }
    
    [self setNeedsDisplay:YES];
    
}

- (void)animatePieceOnSquare:(Square)fromSquare to:(Square)toSquare
{
    [self animatePieceOnSquare:fromSquare to:toSquare promotion:NO_PIECE_TYPE];
}

- (void)animatePieceOnSquare:(Square)fromSquare to:(Square)toSquare promotion:(PieceType)desiredPromotionPiece
{
    // TODO handle promotion, castling, en passant, etc.
    SFMPieceView *thePiece;
    SFMPieceView *capturedPiece;
    for (SFMPieceView *pieceView in self.pieces) {
        if (pieceView.square == fromSquare) {
            thePiece = pieceView;
        }
        if (pieceView.square == toSquare) {
            capturedPiece = pieceView;
        }
    }
    
    if (capturedPiece) {
        [capturedPiece removeFromSuperview];
        [self.pieces removeObject:capturedPiece];
    }
    thePiece.square = toSquare;
    [thePiece moveTo:[self coordinatesForSquare:toSquare leftOffset:leftInset topOffset:topInset sideLength:squareSideLength]];
    
    
}

- (void)displayPossibleMoveHighlightsForPieceOnSquare:(Chess::Square)sq
{
    selectedSquare = sq;
    numHighlightedSquares = [self destinationSquaresFrom:sq saveInArray:highlightedSquares];
    [self setNeedsDisplay:YES];
}

#pragma mark - Logic
/// destinationSquaresFrom:saveInArray takes a square and a C array of squares
/// as input, finds all squares the piece on the given square can move to,
/// and stores these possible destination squares in the array. This is used
/// in the GUI in order to highlight the squares a piece can move to.

- (int)destinationSquaresFrom:(Square)sq saveInArray:(Square *)sqs {
    int i, j, n;
    Move mlist[32];
    
    assert(square_is_ok(sq));
    assert(sqs != NULL);
    
    
    n = [self movesFrom: sq saveInArray: mlist];
    for (i = 0, j = 0; i < n; i++)
        // Only include non-promotions and queen promotions, in order to avoid
        // having the same destination squares multiple times in the array.
        if (!move_promotion(mlist[i]) || move_promotion(mlist[i]) == QUEEN) {
            // For castling moves, adjust the destination square so that it displays
            // correctly when squares are highlighted in the GUI.
            if (move_is_long_castle(mlist[i]))
                sqs[j] = move_to(mlist[i]) + 2;
            else if (move_is_short_castle(mlist[i]))
                sqs[j] = move_to(mlist[i]) - 1;
            else
                sqs[j] = move_to(mlist[i]);
            j++;
        }
    sqs[j] = SQ_NONE;
    return j;
}
- (int)movesFrom:(Square)sq saveInArray:(Move *)mlist {
    assert(square_is_ok(sq));
    assert(mlist != NULL);
    
    int numPossible = self.position->moves_from(sq, mlist);
    return numPossible;
}

#pragma mark - Misc

- (void)dealloc
{
    delete self.position;
}

- (BOOL)isFlipped
{
    return YES;
}

@end
