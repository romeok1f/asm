/*
  Stockfish, a UCI chess playing engine derived from Glaurung 2.1
  Copyright (C) 2004-2008 Tord Romstad (Glaurung author)
  Copyright (C) 2008-2015 Marco Costalba, Joona Kiiski, Tord Romstad

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

//#include <iostream>

#include "bitboard.h"
#include "evaluate.h"
#include "position.h"
#include "search.h"
#include "thread.h"
#include "tt.h"
#include "uci.h"
#include "syzygy/tbprobe.h"




#include "misc.cpp"
#include "bitbase.cpp"
#include "bitboard.cpp"
#include "movegen.cpp"
#include "movepick.cpp"
#include "evaluate.cpp"
#include "pawns.cpp"
#include "search.cpp"
#include "position.cpp"
#include "psqt.cpp"
#include "endgame.cpp"
#include "material.cpp"
#include "tt.cpp"
#include "timeman.cpp"
#include "thread.cpp"
#include "uci.cpp"
#include "benchmark.cpp"


int main(int argc, char* argv[]) {

  MiscInit();
  PSQT::init();
  Bitboards::init();
  Position::init();
  Bitbases::init();
  Search::init();
  Eval::init();
  Pawns::init();
  Threads.init();
  Tablebases::init(Opt.SyzygyPath());
  TT.resize(Opt.Hash());

  UCI::loop(argc, argv);

  Threads.exit();
  return 0;
}
