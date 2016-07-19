*************** WARNING: DO NOT READ WHAT FOLLOWS ********************
***************  AS IT IS SECRET INFORMATION !!!  ********************

******** introduction ********
Welcome to the project of converting stockfish into x86-64!
The source files can be found in the asmFish folder.
The executables can be found in the Windows folder.
For more information on this project see the asmFish/asmReadMe.txt.
Run make.bat to assemble the source for the three supported cpu capabilities
  - base: should run on any 64bit x86 cpu
  - popcnt: generate popcnt instruction
  - bmi2: use instructions introduced in haswell
  
If you observe a crash/misbehaviour in asmFish, please raise an issue here and give me the following information:
  - name of the executable that crashed/misbehaved
  - exception code and exception offset in the case of a crash
  - a log of the commands that were sent to asmFish by your gui before the crash
Simply stating that asmFish crashed in your gui is useless information by itself.
asmFish is known to have problems in the fritz15 gui, while it plays much better in the fritz11 gui.
Any help with this issue would be appreciated.


******** FAQ ********
Q: Why not just start with the compiler output and speed up the critical functions? or write critical
   function in asm and include them in cpp code?
A: With this approach the critical functions would still need to conform to the standards
   set in place by the ABI. All of the critical functions in asmFish do not conform to these
   standards. Plus, asmFish would be dependent on a compiler in this case, which introduces many
   unnecessary compilcations. Both asmFish and its compiler are around 100KB; lets keep it simple.
   Note that compiler output was used in the case of Ronald de Man's syzygy probing code, as this
   is not speed critical but cumbersome to write by hand.

Q: asmFish doesn't work in my gui, what should I do?
A: I told you not to read the introduction.

Q: Is asmFish the same as official stockfish?
A: It is extremely similar but there are some inconsequential functional differences.

Q: How are you sure that there are not tiny bugs in asmFish?
A: How are you sure that your compiler compiles cppFish correctly? Seriously though, the 37 bench positions
   have been put though asmFish with VERBOSE=2 and checked for a byte-by-byte match with cppFish by a
   "go depth 14" command. This is a match of around 100MB of data PER POSITION.

Q: What are the exact functional changes?
A: There are currently four places. With these changes, asmFish should should produce IDENTICAL output
   to cppFish in deterministic searches. To make cppFish from official stockfish,
    (1) In evaluate_scale_factor() function of evaluate.cpp, change
                Color strongSide = eg > VALUE_DRAW ? WHITE : BLACK;
        to
                Color strongSide = eg >= VALUE_DRAW ? WHITE : BLACK;

    (2) In evaluate_pieces() function of evaluate.cpp, change
                    && !ei.pi->semiopen_side(Us, file_of(ksq), file_of(s) < file_of(ksq)))
        to
                    && !ei.pi->semiopen_side(Us, file_of(ksq), file_of(s) <= file_of(ksq)))

    (3) Interpolation in evaluate() resembles a failed 'quantum' patch on fishtest.
        The change is from a division that rounds towards zero
          to a division that rounds towards the nearest integer with ties going towards 0,
          which is easy to do at the machine code level. see [1] of appendix

    (4) Piece lists have been removed. A minimaly-invasive way to enforce this functional change
        in cppFish involves sorting the piece lists and is shown in [2] of the appendix
  

******** updates ********
2016-07-17: "Gradually relax the NMP staticEval check"
  - fixed broken ponder in 07-17
  - added gui spam with current move info when not using time management for gui's that do that
  - added parsing of 'searchmoves' token, which should fix 'nexbest move' if your gui does that

2016-07-17: "Gradually relax the NMP staticEval check"
  - linux version is in the works
  - fixed bug in KRPPKRP endgames: case was mis-evaluated
  - fixed bug in easy move
  - remove dependancy on msvcrt.dll
    - resulting malloc/free in TablebaseCore.asm is a hack and will be updated in future
  - +1% implementation speed from better register useage and code arrangement in Evaluate function
  - added current move info in infinite search

2016-07-04: "Use staticEval in null prune condition"
  - fixed bug in 2016-07-02 where castling data was not copied: pointed out by Lyudmil Antonov
  - specified 1000000 byte stack reserve size in the exe
    - previous default of 64K was rounded up to 1M on >=win7 but was only rounded up to 64K on winXP
    - each recusive call to search requires 2800 bytes, so 64K is only enough for a few plies
    - threads are created with 100000 byte stack commited size which is enough for ~30 plies
  - added command line parsing
    - after the exe on the command line, put uci commands separated by ';' character
      - this doesn't work well with multiple sygyzy paths; not sure what other character is acceptable
    - behaviour is not one-shot, so put quit at the end if you want to quit
    - the following all work in Build Tester 1.4.6.0
      - bench; quit
      - bench depth 16 hash 64 threads 2; quit
      - perft 7; quit
      - position startpos moves e2e4; perft 7; quit
    - be aware that commands other than perft and bench do not wait for threads to finish
  - it seems that movegen/movedo lost a little bit of speed in single-threaded perft from numa awareness

2016-07-02:
  - add numa awareness
    - each numa node gets its own cmh table
    - see function ThreadIdxToNode in Thread.asm for thread to node allocation
    - code should also work on older windows systems with out the numa functions
    - this code is currently untested on numa systems
  - fixed bug in wdl tablebase filtering: pointed out by ma laoshi
  - added debug compile 
  - added hard exits when a critical OS function fails
  - created threads get 0.5 MB of commited stack space to combat a strange bug in XP

2016-06-25:
  - attempt to make asmFish functionally identical to c++ masterFish without piecelists
    - castling is now encoded as kingXrook
    - double pawn moves now do not have a special encoding, which affects IsPseudoLegal function
    - if piece lists were always sorted from low to high in master, then we have asmFish
    - there are three other places with VERY minor functional changes, only affecting evaluation
  - syzygy path now has no length limit
  - fix crash when thinking about a position that is mate
  - fix numerous bugs in tablebase probing code
  - fix bug in Move_Do: condition for faster update of checkersBB is working now
  - fix bugs in KNPKB and KRPKR endgames: some cases were mis-evaluated
  - fix bug in pliesFromNull: this was previously allocated only one byte of storage, which is not enough
  - fix bug in draw by 50 moves rule
  - fix bug in see: castling moves now return 0
  - prefetch main hash entry in Move_DoNull
    - according to my testing on 16, 64, and 256 MB hash sizes, prefetching has little speed effect
    - of course, pawn and material entries are still NOT prefetched
  - drop support for xboard protocol
  - tested (+6,-2,=42) against June 21 chess.ultimaiq.net/stockfish.html master
    - conditions: (tc=1min+1sec,hash=128mb,tb=5men,ponder=on,threads=1) in Arena 3.5.1

2016-06-16:
  - first stable release


******** appendix ********
  [1] To get the more accurate division in evaluate() function of evaluate.cpp, change
          Value v =  mg_value(score) * int(ei.me->game_phase())
                   + eg_value(score) * int(PHASE_MIDGAME - ei.me->game_phase()) * sf / SCALE_FACTOR_NORMAL;
          v /= int(PHASE_MIDGAME);
      to
          Value v =  mg_value(score) * int(ei.me->game_phase()) * SCALE_FACTOR_NORMAL
                   + eg_value(score) * int(PHASE_MIDGAME - ei.me->game_phase()) * sf;

          unsigned int rv = ((unsigned int)(abs(v)+PHASE_MIDGAME*SCALE_FACTOR_NORMAL/2-1))/((unsigned int)(PHASE_MIDGAME*SCALE_FACTOR_NORMAL));
          if (v>=0) {v=Value(rv);} else {v=Value(-rv);}

  [2] To functionally remove piece lists, changing the functions at the end of position.h:

    inline void Position::put_piece(Color c, PieceType pt, Square s) {
      board[s] = make_piece(c, pt);
      byTypeBB[ALL_PIECES] |= s;
      byTypeBB[pt] |= s;
      byColorBB[c] |= s;
      pieceCount[c][pt]++;
      pieceCount[c][ALL_PIECES]++;
      Bitboard b = byColorBB[c] & byTypeBB[pt];
      for (int i=0; i<pieceCount[c][pt]; i++)
        pieceList[c][pt][i] = pop_lsb(&b);
      pieceList[c][pt][pieceCount[c][pt]] = SQ_NONE;
    }

    inline void Position::remove_piece(Color c, PieceType pt, Square s) {
      byTypeBB[ALL_PIECES] ^= s;
      byTypeBB[pt] ^= s;
      byColorBB[c] ^= s;
      pieceCount[c][pt]--;
      pieceCount[c][ALL_PIECES]--;
      Bitboard b = byColorBB[c] & byTypeBB[pt];
      for (int i=0; i<pieceCount[c][pt]; i++)
        pieceList[c][pt][i] = pop_lsb(&b);
      pieceList[c][pt][pieceCount[c][pt]] = SQ_NONE;
    }

    inline void Position::move_piece(Color c, PieceType pt, Square from, Square to) {
      Bitboard from_to_bb = SquareBB[from] ^ SquareBB[to];
      byTypeBB[ALL_PIECES] ^= from_to_bb;
      byTypeBB[pt] ^= from_to_bb;
      byColorBB[c] ^= from_to_bb;
      board[from] = NO_PIECE;
      board[to] = make_piece(c, pt);
      Bitboard b = byColorBB[c] & byTypeBB[pt];
      for (int i=0; i<pieceCount[c][pt]; i++)
        pieceList[c][pt][i] = pop_lsb(&b);
      pieceList[c][pt][pieceCount[c][pt]] = SQ_NONE;
    }

