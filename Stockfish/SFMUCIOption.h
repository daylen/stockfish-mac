//
//  SFMUCIOption.h
//  Stockfish
//
//  Created by Daylen Yang on 12/27/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

typedef NS_ENUM(NSInteger, SFMUCIOptionType) {
    SFMUCIOptionTypeNumber,
    SFMUCIOptionTypeThreads,
    SFMUCIOptionTypeHash,
    SFMUCIOptionTypePath
};

@interface SFMUCIOption : NSObject

@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) SFMUCIOptionType type;
@property (assign, nonatomic) NSInteger defaultValue;
@property (assign, nonatomic) NSInteger minValue;
@property (assign, nonatomic) NSInteger maxValue;

- (instancetype)initWithName:(NSString *)name default:(NSString *)defaultValue min:(NSString *)min max:(NSString *)max;

/*!
 @return YES if the GUI supports the UCI option.
 */
+ (BOOL)isOptionSupported:(NSString *)name;

@end
