VERSION_OS	 fix 'L'
VERSION_PRE	 fix 'asmFish'
VERSION_POST	 fix 'bmi2'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; cpu options 0 or 1
CPU_HAS_POPCNT	 equ 1	;  popcnt                       very nice function
CPU_HAS_BMI1	 equ 1	;  andn                         why not use it if we can
CPU_HAS_BMI2	 equ 1	;  pext + pdep                  nice for move generation, but not much faster than magics
CPU_HAS_AVX1	 equ 0	;  256 bit floating point       probably only used for memory copy if used at all
CPU_HAS_AVX2	 equ 0	;  256 bit integer + fmadd      probably not used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; compile options 0=off, 1=on  or sometimes 2 or 3
PEDANTIC	 equ 0	;  follow official stockfish exactly so that bench signature matches
DEBUG		 equ 0	;  turns on the asserts    detecting critical bugs: should be no functional change
VERBOSE 	 equ 0	;  LOTS of print           find subtle bugs:  0=off, 1=general debug, 2=search debug, 3=eval debug
PROFILE 	 equ 0	;  counts in the code      view these with profile command after running bench
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
include 'guts/asmFish.asm'