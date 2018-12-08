//
//  Constants.h
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#ifndef Stockfish_Constants_h
#define Stockfish_Constants_h

#define FEN_START_POSITION @"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

// Errors
#define POSITION_ERROR_DOMAIN @"SFMPositionErrorDomain"
#define PARSE_ERROR_CODE 0
#define ILLEGAL_MOVE_CODE 1

#define GAME_ERROR_DOMAIN @"SFMGameErrorDomain"
#define NOT_AT_END_CODE 0
#define GAME_PARSE_ERROR_CODE 1

// For the board view
#define EXTERIOR_BOARD_MARGIN 40
#define INTERIOR_BOARD_MARGIN 20
#define FONT_SIZE 12

// Notifications
#define SETTINGS_HAVE_CHANGED_NOTIFICATION @"SettingsChanged"

#endif
