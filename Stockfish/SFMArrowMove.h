//
//  SFMArrowMove.h
//  Stockfish
//
//  Created by Peter Ryszkiewicz on 8/28/21.
//  Copyright © 2021 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SFMMove;

@interface SFMArrowMove : NSObject <NSCopying>

@property (readonly) SFMMove *move;

/// Describes relative thickness of arrow in [0, 1]
@property (readonly, assign) CGFloat weight;

- (instancetype)initWithMove:(SFMMove *)move weight:(CGFloat)arrowWeight;

@end

NS_ASSUME_NONNULL_END
