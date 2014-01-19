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

// For the board view
#define EXTERIOR_BOARD_MARGIN 40
#define INTERIOR_BOARD_MARGIN 20
#define BOARD_SHADOW_BLUR_RADIUS 30
#define FONT_SIZE 12

// For the piece view
#define PIECE_SHADOW_BLUR_RADIUS 5

// Notifications
#define ENGINE_NAME_AVAILABLE_NOTIFICATION @"EngNameAvail"
#define ENGINE_NEW_LINE_AVAILABLE_NOTIFICATION @"EngNewLineAvail"
#define ENGINE_CURRENT_MOVE_CHANGED_NOTIFICATION @"EngineCurrMoveChanged"
#define SETTINGS_HAVE_CHANGED_NOTIFICATION @"SettingsChanged"
#define ENGINE_BEST_MOVE_AVAILABLE_NOTIFICATION @"EngBestMoveAvail"

// For the settings
#define ENGINE_SETTINGS_KEY @"Engine Settings"
#define NUM_THREADS_SETTING @"Threads2"
#define HASH_SIZE_SETTING @"Memory2"

#endif
