//
//  SFMPGNFile.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

@interface SFMPGNFile : NSObject

#pragma mark - Properties

@property NSMutableArray /* of SFMChessGame */ *games;

#pragma mark - Init

/*!
 Create a PGN with one game.
 */
- (instancetype)init;

/*!
 Create the given PGN.
 @param str
 */
- (instancetype)initWithString:(NSString *)str;

#pragma mark - Export

/*!
 Export the PGN file.
 @return The PGN file as an NSData blob.
 */
- (NSData *)data;

@end
