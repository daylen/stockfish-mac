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


#if !defined(SAN_H_INCLUDED)
#define SAN_H_INCLUDED

////
//// Includes
////

#include <string>

#include "move.h"
#include "position.h"
#include "value.h"

namespace Chess {

////
//// Prototypes
////

extern const std::string move_to_san(Position &pos, Move m, bool figurine = false);
extern Move move_from_san(Position &pos, const std::string &str);
extern const std::string line_to_san(const Position &pos, Move line[],
                                     int startColumn, bool breakLines,
                                     int moveNumbers);
void san_move_list(const Position &pos, Move line[], std::string list[]);
extern const std::string pretty_pv(const Position &pos, int time, int depth,
                                   uint64_t nodes, Value score, Move pv[]);
extern const std::string line_to_html(const Position &pos, Move line[], int currentPly, bool figurine);

}

#endif // !defined(SAN_H_INCLUDED)
