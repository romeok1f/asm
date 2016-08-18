******** introduction ********
Welcome to the project of converting stockfish into x86-64!
The executables can be found in the Windows folder.
The source files can be found in the asmFish folder.
  - run fasm on asmFishW_base[_popcnt,_bmi2].asm to produce executables for windows
  - run fasm on asmFish_base[_popcnt,_bmi2].asm to produce executables for linux
For more information on this project see the asmFish/asmReadMe.txt.
Run make.bat to automatically assemble the windows/linux sources for the three capabilities
  - base: should run on any 64bit x86 cpu
  - popcnt: generate popcnt instruction
  - bmi2: use instructions introduced in haswell
Besides the three cpu capabilities, this project now comes in two flavours
  - asmFish: trim off the cruft in official stockfish and make a lean and mean chess engine
  - pedantFish: match bench signature of official stockfish to catch search/eval bugs more easily
More flavors are planned for the future, including mateFish and hybridFish.
  
If you observe a crash/misbehaviour in asmFish, please raise an issue here and give me the following information:
  - name of the executable that crashed/misbehaved
  - exception code and exception offset in the case of a crash
  - a log of the commands that were sent to asmFish by your gui before the crash
Simply stating that asmFish crashed in your gui is useless information by itself.
asmFish is known to have problems in the fritz15 gui, while it plays much better in the fritz11 gui.
Any help with this issue would be appreciated.


******** FAQ ********
Q: Why not just start with the compiler output and speed up the critical functions?
   or write critical functions in asm and include them in cpp code?
A: With this approach the critical functions would still need to conform to the standards
   set in place by the ABI. All of the critical functions in asmFish do not conform to these
   standards. Plus, asmFish would be dependent on a compiler in this case, which introduces many
   unnecessary compilcations. Both asmFish and its compiler are around 100KB; lets keep it simple.
   Note that compiler output was used in the case of Ronald de Man's syzygy probing code, as this
   is not speed critical but cumbersome to write by hand.

Q: Is asmFish the same as official stockfish?
A: It is 99.9% official stockfish as there are some inconsequential functional differences in 
   official that were deemed too silly to put into asmFish. Piece lists are the prime offender here.
   You can get 100% official stockfish in deterministic searches by setting PEDANTIC equ 1 compile option.
   The changes can be viewed at https://github.com/tthsqe12/asm/search?q=PEDANTIC
   

******** updates ********
2016-08-17: "Use predicted depth for history pruning"
  - fixed some silly bugs in Linux version. futexes are trickey

2016-08-12: "Simplify space formula"
  - removed colon from info strings
  - added PEDANTIC compile option, which makes asmFish match official stockfish in deterministic searches
    Here are some search speeds in Mnps from
        Build Tester: 1.4.6.0
        Windows 8.1 (Version 6.3, Build 0, 64-bit Edition)
        Intel(R) Core(TM) i7-4771 CPU @ 3.50GHz
    Note that the first entry is not comparable to the last two because it is searching a different tree,
    or in the case of perft the same tree in a different order.The last entry is http://abrok.eu/stockfish/builds/8abb98455f6fa78092f650b8bae9c166f1b5a315/win64bmi2/stockfish_16081012_x64_bmi2.exe
                                 perft 7        bench 128 1 17   bench 128 1 18
    asmFish_bmi2                 306.3+-0.098   2.731+-0.002     2.722+-0.003
    pedanticFish_bmi2            299.7+-0.095   2.727+-0.003     2.741+-0.003   <--- these two have
    stockfish_16081012_x64_bmi2  239.5+-0.087   2.194+-0.001     2.205+-0.001   <--- matching signatures
    
2016-08-08: "Use Color-From-To history stats to help sort moves"
  - the 07-25 version changed the default value of SlowMover from 80 to 89
    which probably accounts for some of the larger-than-expect Elo gain on http://spcc.beepworld.de/

2016-07-25: "Allow null pruning at depth 1"
  - several structures have been modified to accomodate the linux port
  - on start, asmfish now displays node information on numa systems

2016-07-18: "Gradually relax the NMP staticEval check"
  - fixed broken ponder in 07-17
  - added gui spam with current move info when not using time management for gui's that do that
  - added parsing of 'searchmoves' token, which should fix 'nextbest move' if your gui does that

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
