Welcome to the project of converting stockfish into x86-64!
The source files can be found in the asmFish folder.
The executables can be found in the Windows folder.
For more information on this project see the asmFish/asmReadMe.txt.
Run make.bat to assemble the source for the three supported cpu capabilities
  - base: should run on any 64bit x86 cpu
  - popcnt: generate popcnt instruction
  - bmi2: use instructions introduced in haswell
  
If you observe a crash in asmFish, please raise an issue here and give me the following information:
  - name of the executable that crashed
  - exception code and exception offset
  - a log of the commands that were sent to asmFish by your gui before the crash
Simply stating that asmFish crashed in your gui is useless information by itself.
asmFish is known to have problems in the fritz15 gui, while it plays much better in the fritz11 gui.
Any help with this issue would be appreciated.

2016-07-04:
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
