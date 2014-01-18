//
//  SFMFormatter.h
//  Stockfish
//
//  Created by Daylen Yang on 1/17/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFMFormatter : NSObject

+ (NSString *)scoreAsText:(int)score isMate:(BOOL)isMate isWhiteToMove:(BOOL)whiteToMove;
+ (NSString *)nodesAsText:(NSString *)nodes;

@end
