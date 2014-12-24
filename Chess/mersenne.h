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


#if !defined(MERSENNE_H_INCLUDED)
#define MERSENNE_H_INCLUDED

////
//// Includes
////

#include "types.h"

namespace Chess {

////
//// Prototypes
////

extern uint32_t genrand_int32(void);
extern uint64_t genrand_int64(void);
extern void init_mersenne(void);

}

#endif // !defined(MERSENNE_H_INCLUDED)
