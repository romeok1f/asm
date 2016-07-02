1. about asmFish:
- it is a rewrite of stockfish into x86-64
- assemble with fasm (www.flatassembler.net)
  - fasm.exe is included in the asmFish directory
- there are tiny inconsequential functional difference with the real stockfish; see 4.

2. assembling:
- main source is asmFishW.asm for windows asmFish.asm for unix
  - source is divided up into many files becuase ordering of these files in asmFish.asm can effect performance
- asmFish is written for haswell with macros used to simulate instructions on lower cpu's
  - even without popcnt, performance only drops a few %
- CPU_HAS_... (most important) indicates available instructions
  - program does a runtime check to see if these really are avaiable
- DEBUG turns on some printing and asserts
- VERBOSE turns on lots of printing and should only be used when searching for bugs

3. commands:
- uci
  - Weakness: set this to n>0 so that the engine tries to lose n cp on average per move
- uci extra:
  - moves x..	  makes the moves x.. from the current pos. if illegal move appears in list, parsing stops there
  - show	  displays the current board
  - eval	  displays the output of Evaluate on current position
  - perft d	  usual perft to depth d
  - bench	  use like this: 'bench depth 20 threads 1 hash 128'. These are the default settings.

4. about the code so far:
- there are three functional changes from the real stockfish
  - no piece lists!
    - move ordering in movegen is different as a result
    - the piece lists are maintain in Pos structure simply by bitboards
- there are three kinds of threads
  - the gui thread reads from stdin and uses the th1 and th2 structs on its stack
  - the main search thread
  - n-1 worker threads
- the move generation and picking function have been rewritten
- the CheckInfo structure has been merged into the State structure
- the SearchStack structure has been merged into the State structure
- the sequence of states is stored as a vector as opposed to a linked list
  - the size of this container should expand and shrink automatically in the gui thread
  - the size of vector of states used in search threads is fixed on thread creation
    - we only need 100+MAX_PLY entries for a search thread
- Move_Do does no prefetching

5. asm notes:
- if you see popcnt with three operands, don't panic, its just a macro that needs a temp for non-popcnt cpu's BasicMacros.asm
- register conventions:
  - follows MS x64 calling convention for the most part
  - uses rdi/rsi for strings were appropriate, rdi for writing to, rsi for reading from
  - rbp is very much used to hold the Pos structure
    - above rbp is the position structure
    - below rbp is the thread struct
    - this register doesn't need to change while a thread is thinking
  - rbx is used to hold the current State structure
  - rsi is generally used in the search function to hold the Pick structure

6. os:
- syzygy uses malloc and free from the standard library
- windows uses only window kernel functions for now
- linux port should be easy, as it should involve only a rewrite of OsWindows.asm and minimal changes to asmFishW.asm

7. notes about fasm:
- mov x, y	is a definition that actually executes in your program (zeroth)
- cmp x, y	is a condition that actually executes in your program (zeroth)
- x = y 	is a definition/condition that is handled by the assembler (first)
- x eq y	is a condition that is handled by the parser (second)
- match =x,y	is a condition that is handled by the preprocessor (third)
- x equ y	is a definition of x that is handled by the preprocessor (third)
- x fix y	is a definition of x that is handled by prepreprocessor (fourth)


