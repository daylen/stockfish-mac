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
#import "NSColor+ColorUtils.h"
#import "SFMItertools.h"
#import "SFMSquareUtils.h"
#import "SFMUserDefaults.h"

@import QuartzCore;

@interface SFMBoardView()

#pragma mark - Colors

@property NSColor *boardColor;
@property NSColor *lightSquareColor;
@property NSColor *darkSquareColor;
@property NSColor *fontColor;
@property NSColor *highlightColor;

#pragma mark - State

@property (nonatomic) NSMutableDictionary /* <NSNumber(SFMSquare), SFMPieceView> */ *pieceViews;
@property (nonatomic) NSMutableDictionary /* <SFMMove, SFMArrowView> */ *arrowViews;

@property (nonatomic) NSArray /* of NSNumber(SFMSquare) */ *highlightedSquares;

@property (assign, nonatomic) BOOL isDragging;
@property (nonatomic) SFMSquare fromSquare;
@property (nonatomic) SFMSquare toSquare;

#pragma mark - Metrics

@property (readonly, assign, nonatomic) CGFloat leftInset;
@property (readonly, assign, nonatomic) CGFloat topInset;
@property (readonly, assign, nonatomic) CGFloat squareSideLength;

@end

@implementation SFMBoardView

#pragma mark - Init
- (instancetype)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.wantsLayer = YES;
        _boardIsFlipped = NO;

        _boardColor = [NSColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1];
        _lightSquareColor = [NSColor colorWithHex:0xf6fbf8 alpha:1];
        _darkSquareColor = [self darkSquareColorFromPreferences];
        _fontColor = [NSColor whiteColor];
        _highlightColor = [NSColor colorWithSRGBRed:1 green:1 blue:0 alpha:0.7];
        
        _pieceViews = [[NSMutableDictionary alloc] init];
        _arrowViews = [[NSMutableDictionary alloc] init];
        _highlightedSquares = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPreferencesToBoard:) name:SETTINGS_HAVE_CHANGED_NOTIFICATION object:nil];
    }
    return self;
}
-(NSColor *)darkSquareColorFromPreferences {
    return [NSColor colorWithHex:[SFMUserDefaults boardColorValue] alpha:1];
}

-(void)applyPreferencesToBoard:(NSNotification *)notification {
    _darkSquareColor = [self darkSquareColorFromPreferences];
    [self setNeedsDisplay:YES];
}

#pragma mark - Setters

- (void)setBoardIsFlipped:(BOOL)boardIsFlipped {
    _boardIsFlipped = boardIsFlipped;
    [self setNeedsDisplay:YES];
    [self resizeSubviewsWithOldSize:NSMakeSize(0, 0)];
}

- (void)setPosition:(SFMPosition *)newPosition {
    SFMPosition *oldPosition = _position;
    _position = newPosition;
    
    [self magicMoveFrom:oldPosition to:newPosition];
    
}

- (void)setArrows:(NSArray *)arrows {
    _arrows = arrows;

    [self.arrowViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    [self.arrowViews removeAllObjects];
    
    for (SFMMove *move in _arrows) {
        if (move.from == move.to) {
            NSLog(@"Yikes! The from and to for this arrow is the same.");
            continue;
        }
        
        SFMArrowView *view = [[SFMArrowView alloc] initWithFrame:self.bounds];
        self.arrowViews[move] = view;
        [self addSubview:view];
    }
    
    [self resizeSubviewsWithOldSize:NSMakeSize(0, 0)];
}

#pragma mark - Drawing

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    if (!self.isDragging) {
        [self.pieceViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            SFMSquare s = ((NSNumber *)key).integerValue;
            NSView *view = obj;
            CGPoint coordinate = [self coordinatesForSquare:s
                                                 leftOffset:self.leftInset
                                                  topOffset:self.topInset
                                                 sideLength:self.squareSideLength];
            view.frame = NSMakeRect(coordinate.x, coordinate.y,
                                    self.squareSideLength, self.squareSideLength);
        }];
    }
    [self.arrowViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        SFMMove *move = key;
        SFMArrowView *view = obj;
        view.fromPoint = [self coordinatesForSquare:move.from
                                         leftOffset:self.leftInset + self.squareSideLength / 2
                                          topOffset:self.topInset + self.squareSideLength / 2
                                         sideLength:self.squareSideLength];
        view.toPoint = [self coordinatesForSquare:move.to
                                       leftOffset:self.leftInset + self.squareSideLength / 2
                                        topOffset:self.topInset + self.squareSideLength / 2
                                       sideLength:self.squareSideLength];
        view.squareSideLength = self.squareSideLength;
        [view setNeedsDisplay:YES];
    }];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    // Draw the border
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    [self.boardColor set];
    CGFloat left = (width - boardSideLength) / 2;
    CGFloat top = (height - boardSideLength) / 2;
    NSRectFill(NSMakeRect(left, top, boardSideLength, boardSideLength));
    
    // Draw 64 squares
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            if ((i + j) % 2 == 0) {
                [self.lightSquareColor set];
            } else {
                [self.darkSquareColor set];
            }
            NSRectFill(NSMakeRect(self.leftInset + i * self.squareSideLength,
                                  self.topInset + j * self.squareSideLength,
                                  self.squareSideLength, self.squareSideLength));
        }
    }
    
    // Draw coordinates
    NSString *str;
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [pStyle setAlignment:NSCenterTextAlignment];
    for (int i = 0; i < 8; i++) {
        // Down
        str = [NSString stringWithFormat:@"%d", self.boardIsFlipped ? (i + 1) : (8 - i)];
        [str drawInRect:NSMakeRect(left, self.topInset + self.squareSideLength / 2 - FONT_SIZE / 2
                                   + i * self.squareSideLength, INTERIOR_BOARD_MARGIN,
                                   self.squareSideLength)
         withAttributes:@{NSParagraphStyleAttributeName: pStyle,
                          NSForegroundColorAttributeName: self.fontColor}];
        // Across
        str = [NSString stringWithFormat:@"%c", self.boardIsFlipped ? ('h' - i) : ('a' + i)];
        [str drawInRect:NSMakeRect(self.leftInset + i * self.squareSideLength, self.topInset +
                                   8 * self.squareSideLength, self.squareSideLength,
                                   INTERIOR_BOARD_MARGIN)
         withAttributes:@{NSParagraphStyleAttributeName: pStyle,
                          NSForegroundColorAttributeName: self.fontColor}];
    }
    
    // Draw highlighted squares
    [self.highlightColor set];
    for (NSNumber *num in self.highlightedSquares) {
        SFMSquare square = num.integerValue;
        CGPoint coordinate = [self coordinatesForSquare:square
                                             leftOffset:self.leftInset
                                              topOffset:self.topInset
                                             sideLength:self.squareSideLength];
        [NSBezierPath fillRect:NSMakeRect(coordinate.x, coordinate.y,
                                          self.squareSideLength, self.squareSideLength)];
    }
    
}

#pragma mark - Getters

- (CGFloat)topInset {
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    
    return (height - boardSideLength) / 2 + INTERIOR_BOARD_MARGIN;
}

- (CGFloat)leftInset {
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    
    return (width - boardSideLength) / 2 + INTERIOR_BOARD_MARGIN;
}

- (CGFloat)squareSideLength {
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat boardSideLength = MIN(height, width) - EXTERIOR_BOARD_MARGIN * 2;
    
    return (boardSideLength - 2 * INTERIOR_BOARD_MARGIN) / 8;
}

#pragma mark - Conversions

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
    self.isDragging = NO;
    
    // Figure out which square you clicked on
    NSPoint clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    SFMSquare clickedSquare = [self squareForCoordinates:clickLocation
                                              leftOffset:self.leftInset
                                               topOffset:self.topInset
                                              sideLength:self.squareSideLength];
    
    if ([self.highlightedSquares count] == 0) {
        // You haven't selected a valid piece, since there are no highlighted squares on the board.
        if (clickedSquare != SQ_NONE) {
            self.fromSquare = clickedSquare;
            self.highlightedSquares = [self.position legalSquaresFromSquare:clickedSquare];
        }
    } else {
        // Is it possible to move to the square you clicked on?
        BOOL isValidMove = [self.highlightedSquares containsObject:
                            @(clickedSquare)];
        
        if (!isValidMove) {
            // If it's not a valid move, cancel the highlight
            self.highlightedSquares = nil;
            self.fromSquare = SQ_NONE;
        }

    }
    
    [self setNeedsDisplay:YES];
    
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    self.isDragging = YES;
    
    // Make the dragged piece follow the mouse
    NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // Center the piece
    mouseLocation.x -= self.squareSideLength / 2;
    mouseLocation.y -= self.squareSideLength / 2;
    
    NSView *draggedPiece = self.pieceViews[@(self.fromSquare)];
    [draggedPiece setFrameOrigin:mouseLocation];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Figure out which square you let go on
    NSPoint upLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    self.toSquare = [self squareForCoordinates:upLocation
                                    leftOffset:self.leftInset
                                     topOffset:self.topInset
                                    sideLength:self.squareSideLength];
    
    // Is it possible to move to the square you clicked on?
    BOOL isValidMove = [self.highlightedSquares
                        containsObject:@(_toSquare)];
    
    if (isValidMove) {
        self.isDragging = NO;
        
        // You previously selected a valid piece, and now you're trying to move it
        
        SFMPieceType pieceType = NO_PIECE_TYPE;
        
        // Handle promotions
        if ([self.position isPromotion:
             [[SFMMove alloc] initWithFrom:self.fromSquare to:self.toSquare]]) {
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
        
        self.highlightedSquares = nil;
        
        SFMMove *move;
        if (pieceType != NO_PIECE_TYPE) {
            move = [[SFMMove alloc] initWithFrom:self.fromSquare to:self.toSquare
                                       promotion:pieceType];
        } else {
            move = [[SFMMove alloc] initWithFrom:self.fromSquare to:self.toSquare];
            if (castle) {
                move.isCastle = YES;
            } else if (self.toSquare == [self.position enPassantSquare] &&
                       ([self.position pieceOnSquare:self.fromSquare] == WP ||
                        [self.position pieceOnSquare:self.fromSquare] == BP)) {
                move.isEp = YES;
            }
        }
        
        [self.delegate boardView:self userDidMove:move];
    } else if (self.isDragging) {
        // Invalid move
        self.isDragging = NO;
        self.highlightedSquares = nil;
        self.fromSquare = SQ_NONE;
        self.toSquare = SQ_NONE;
    }
    
    [self setNeedsDisplay:YES];
    [self resizeSubviewsWithOldSize:NSMakeSize(0, 0)];
    
}

#pragma mark - Animation

#define kBoardMoveAnimationDuration 0.3

- (void)magicMoveFrom:(SFMPosition *)from to:(SFMPosition *)to {
    
    // Find all the squares that differ
    
    NSMutableArray /* of NSNumber(SFMSquare) */ *changedSquares = [[NSMutableArray alloc] init];
    for (SFMSquare s = SQ_A1; s <= SQ_H8; s++) {
        if ([from pieceOnSquare:s] != [to pieceOnSquare:s]) {
            [changedSquares addObject:@(s)];
        }
    }
    
    // Build piece to square dictionaries for all changed squares
    
    NSMutableDictionary /* <NSNumber(SFMPiece), [NSNumber(SFMSquare)]> */ *fromDict =
    [[NSMutableDictionary alloc] init];
    NSMutableDictionary /* <NSNumber(SFMPiece), [NSNumber(SFMSquare)]> */ *toDict =
    [[NSMutableDictionary alloc] init];
    
    for (NSNumber *square in changedSquares) {
        SFMSquare s = square.integerValue;
        SFMPiece fromPiece = [from pieceOnSquare:s];
        SFMPiece toPiece = [to pieceOnSquare:s];
        if (fromPiece != NO_PIECE && fromPiece != EMPTY) {
            if (fromDict[@(fromPiece)]) {
                [fromDict[@(fromPiece)] addObject:@(s)];
            } else {
                fromDict[@(fromPiece)] = [[NSMutableArray alloc] initWithObjects:@(s), nil];
            }
        }
        if (toPiece != NO_PIECE && toPiece != EMPTY) {
            if (toDict[@(toPiece)]) {
                [toDict[@(toPiece)] addObject:@(s)];
            } else {
                toDict[@(toPiece)] = [[NSMutableArray alloc] initWithObjects:@(s), nil];
            }
        }
    }
    
    // Find piece types that exist between the old and new boards
    
    NSMutableSet *sharedPieces = [NSMutableSet setWithArray:[fromDict allKeys]];
    [sharedPieces intersectSet:[NSSet setWithArray:[toDict allKeys]]];
    
    // Add movements between these old and new pieces to an "all paths" dictionary
    
    NSMutableDictionary /* <NSNumber(SFMSquare), NSNumber(SFMSquare)> */ *allPaths = [[NSMutableDictionary alloc] init];

    for (NSNumber *piece in sharedPieces) {
        NSArray *pathsForThisPiece = [SFMBoardView shortestPathsFrom:fromDict[piece] to:toDict[piece]];
        
        for (SFMMove *path in pathsForThisPiece) {
            allPaths[@(path.from)] = @(path.to);
            [fromDict[piece] removeObject:@(path.from)];
            [toDict[piece] removeObject:@(path.to)];
        }
    }
    
    // Also add removals to the "all paths" dictionary as a mapping from some square to no square
    
    [fromDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSArray *squares, BOOL *stop) {
        [squares enumerateObjectsUsingBlock:^(NSNumber *square, NSUInteger idx, BOOL *stop) {
            allPaths[square] = @(SQ_NONE);
        }];
    }];
    
    // Execute movement and removal paths
    
    NSMutableDictionary *newPieceViews = [[NSMutableDictionary alloc] init];
    
    [self.pieceViews enumerateKeysAndObjectsUsingBlock:^(id key, SFMPieceView *obj, BOOL *stop) {
        if (allPaths[key]) {
            if (((NSNumber *)allPaths[key]).integerValue == SQ_NONE) {
                // Removal required
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:kBoardMoveAnimationDuration];
                
                [[obj animator] removeFromSuperview];
                
                [NSAnimationContext endGrouping];
            } else {
            
                // Movement required
                newPieceViews[allPaths[key]] = self.pieceViews[key];
                
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:kBoardMoveAnimationDuration];
                
                [[obj animator] setFrameOrigin:[self coordinatesForSquare:((NSNumber *)allPaths[key]).integerValue leftOffset:self.leftInset topOffset:self.topInset sideLength:self.squareSideLength]];
                
                [NSAnimationContext endGrouping];
            }
            
        } else {
            // No path
            newPieceViews[key] = obj;
        }
    }];
    
    // Execute addition paths
    
    [toDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSArray *squares, BOOL *stop) {
        [squares enumerateObjectsUsingBlock:^(NSNumber *square, NSUInteger idx, BOOL *stop) {
            SFMPieceView *view = [[SFMPieceView alloc] init];
            view.piece = key.integerValue;
            newPieceViews[square] = view;
            view.alphaValue = 0;
            [self addSubview:view];
            // Why not just add the view in the animation context? Because then that would animate
            // drawRect, and we don't want that.
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:kBoardMoveAnimationDuration];
            [view.animator setAlphaValue:1];
            [NSAnimationContext endGrouping];
        }];
    }];

    // Set the piece views dictionary to the new one
    
    self.pieceViews = newPieceViews;
    
}

+ (NSArray* /* of SFMMove */)shortestPathsFrom:(NSArray* /* of NSNumber(SFMSquare) */)from to:(NSArray* /* of NSNumber(SFMSquare) */)to {
    
    int size = (int) MIN([from count], [to count]);
    
    NSArray* /* of NSArray[SFMMove] */ candidates = [SFMBoardView generateConfigurationsWithSize:size from:from to:to];
    
    double minDist = DBL_MAX;
    NSArray* /* of SFMMove */ bestConfiguration;
    
    for (NSArray *cand in candidates) {
        double dist = [SFMBoardView distanceForConfiguration:cand];
        if (dist < minDist) {
            minDist = dist;
            bestConfiguration = cand;
        }
    }
    
    return bestConfiguration;
}

+ (NSArray* /* of NSArray[SFMMove] */)generateConfigurationsWithSize:(int)size from:(NSArray *)from to:(NSArray *)to {
    NSMutableArray *configs = [[NSMutableArray alloc] init];
    
    if ([from count] >= [to count]) {
        for (NSArray *x in [SFMItertools permutations:from length:(int) [to count]]) {
            NSMutableArray *moves = [[NSMutableArray alloc] init];
            for (int i = 0; i < [x count]; i++) {
                [moves addObject:[[SFMMove alloc] initWithFrom:((NSNumber *)x[i]).integerValue to:((NSNumber *)to[i]).integerValue]];
            }
            [configs addObject:moves];
        }
    } else {
        for (NSArray *x in [SFMItertools permutations:to length:(int) [from count]]) {
            NSMutableArray *moves = [[NSMutableArray alloc] init];
            for (int i = 0; i < [x count]; i++) {
                [moves addObject:[[SFMMove alloc] initWithFrom:((NSNumber *)from[i]).integerValue to:((NSNumber *)x[i]).integerValue]];
            }
            [configs addObject:moves];
        }
    }
    
    return configs;
}

+ (double)distanceForConfiguration:(NSArray* /* of SFMMove */)config {
    double dist = 0.0;
    
    for (SFMMove *move in config) {
        dist += [SFMSquareUtils distanceFrom:move.from to:move.to];
    }
    
    return dist;
}



#pragma mark - Misc

- (BOOL)isFlipped
{
    return YES;
}

@end
