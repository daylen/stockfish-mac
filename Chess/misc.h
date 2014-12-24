/*
  Stockfish, a chess program for iOS.
  Copyright (C) 2004-2014 Tord Romstad, Marco Costalba, Joona Kiiski.

  Stockfish is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Stockfish is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#if !defined(MISC_H_INCLUDED)
#define MISC_H_INCLUDED


////
//// Includes
////

#include <string>

namespace Chess {

////
//// Constants
////


/// Version number.  If this is left empty, the current date (in the format
/// YYMMDD) is used as a version number.

const std::string EngineVersion = "";


////
//// Macros
////

#define Min(x, y) (((x) < (y))? (x) : (y))
#define Max(x, y) (((x) < (y))? (y) : (x))


////
//// Prototypes
////

extern const std::string engine_name();
extern int get_system_time();
extern int cpu_count();
extern int Bioskey();

}

#endif // !defined(MISC_H_INCLUDED)
