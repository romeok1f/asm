; this is the source for windows  see asmFish.asm for unix
; this is included in asmFishW_popcnt.asm asmFishW_base.asm and asmFishW_bmi2.asm

; sanity check on compile options
if (not CPU_HAS_POPCNT) and (CPU_HAS_AVX1 or CPU_HAS_AVX2 or CPU_HAS_BMI1 or CPU_HAS_BMI2)
	  display 'WARNING: if cpu does not have POPCNT, it probably does not have higher capabilities'
	  display 13,10
end if

if (not CPU_HAS_AVX1) and CPU_HAS_AVX2
	  display 'ERROR: if cpu does not have AVX1, it definitely does not have AVX2'
	  display 13,10
	  err
end if

if (not CPU_HAS_BMI1) and CPU_HAS_BMI2
	  display 'ERROR: if cpu does not have BMI1, it definitely does not have BMI2'
	  display 13,10
	  err
end if



include 'Def.asm'

format PE64 console
stack THREAD_STACK_SIZE
entry Start

include 'myWin64a.asm'


include 'BasicMacros.asm'
include 'Structs.asm'
include 'Debug.asm'

section '.data' data readable writeable

match =1, PROFILE {
  align 16
  profile:
   .cjmpcounts rq 2*60
   .moveDo     dq 0
   .moveUnpack dq 0
   .moveStore  dq 0
   .moveRetrieve dq 0
   .ender rb 0
}


if VERBOSE > 0
  align 16
  VerboseOutput rq 1024
  VerboseTime1 rq 2
  VerboseTime2 rq 2
  Verbr15 rq 1
end if


if DEBUG > 0
  align 16
  DebugBalance rq 1
  DebugOutput  rq 1024
end if

align 16
RazorMargin dd 483, 570, 603, 554
CaptureOrPromotion_or  db  0,-1,-1,-1,-1,0,-1,0
CaptureOrPromotion_and db -1,-1,-1,-1,-1,0,-1,0

align 16
constd:
.0p01	 dq 0.01
.0p03	 dq 0.03
.0p505	 dq 0.505
.1p0	 dq 1.0
.628p0	 dq 628.0
.min	 dq 0x0010000000000000

align 16
HalfDensitySize = 20
HalfDensityRows:
	dd 2, 000000010b
	dd 2, 000000001b
	dd 4, 000001100b
	dd 4, 000000110b
	dd 4, 000000011b
	dd 4, 000001001b
	dd 6, 000111000b
	dd 6, 000011100b
	dd 6, 000001110b
	dd 6, 000000111b
	dd 6, 000100011b
	dd 6, 000110001b
	dd 8, 011110000b
	dd 8, 001111000b
	dd 8, 000111100b
	dd 8, 000011110b
	dd 8, 000001111b
	dd 8, 010000111b
	dd 8, 011000011b
	dd 8, 011100001b


match =0, CPU_HAS_POPCNT {
 Mask55    dq 0x5555555555555555
 Mask33    dq 0x3333333333333333
 Mask0F    dq 0x0F0F0F0F0F0F0F0F
 Mask01    dq 0x0101010101010101
 Mask11    dq 0x1111111111111111
}



align 8
prng rq 1



align 4
wdl_to_Value5:
  dd  -VALUE_MATE + MAX_PLY + 1
  dd VALUE_DRAW - 2
  dd VALUE_DRAW
  dd VALUE_DRAW + 2
  dd VALUE_MATE - MAX_PLY - 1

WDLtoDTZ db -1,-101,0,101,1

rsquare_lookup:  db SQ_F1, SQ_D1, SQ_F8, SQ_D8
ksquare_lookup:  db SQ_G1, SQ_C1, SQ_G8, SQ_C8


szUciResponse:	db 'id name '
szGreeting:
		db 'asmFishW_'
		create_build_time DAY, MONTH, YEAR
		db '_'
		db CPU_VERSION
		db 13,10
szGreetingEnd:
		db 'id author TypingALot',13,10
		db 'option name Contempt type spin default 0 min -100 max 100',13,10
		db 'option name Threads type spin default 1 min 1 max 256',13,10
		db 'option name Hash type spin default 16 min 1 max 1048576',13,10
		db 'option name MultiPV type spin default 1 min 1 max 224',13,10
if CPU_VERSION eq 'base'
		db 'option name Weakness type spin default 0 min 0 max 200',13,10
end if
		db 'option name MoveOverhead type spin default 30 min 0 max 5000',13,10
		db 'option name MinThinkTime type spin default 20 min 0 max 5000',13,10
		db 'option name SlowMover type spin default 80 min 10 max 1000',13,10
		db 'option name SyzygyProbeDepth type spin default 1 min 1 max 100',13,10
		db 'option name Syzygy50MoveRule type check default true',13,10
		db 'option name SyzygyProbeLimit type spin default 6 min 0 max 6',13,10
		db 'option name SyzygyPath type string default <empty>',13,10
		db 'option name ClearHash type button',13,10
		db 'option name Ponder type check default false',13,10
		db 'option name UCI_Chess960 type check default false',13,10
		db 'uciok'
sz_NewLine:
		db 13,10
sz_NewLineEnd:
szUciResponseEnd:

szCPUError	db 'Error: processor does not support',0
   .POPCNT	db ' POPCNT',0
   .AVX1	db ' AVX1',0
   .AVX2	db ' AVX2',0
   .BMI1	db ' BMI1',0
   .BMI2	db ' BMI2',0
szStartFEN	db 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',0
PieceToChar	db '.?PNBRQK??pnbrqk'

sz_error_think	db 'error: setoption called while thinking',0
sz_error_value	db 'error: setoption has no value',0
sz_error_name	db 'error: setoption has no name',0

sz_position		db 'position',0
sz_go			db 'go',0
sz_stop 		db 'stop',0
sz_isready		db 'isready',0
sz_ponderhit		db 'ponderhit',0
sz_ucinewgame		db 'ucinewgame',0
sz_uci			db 'uci',0
sz_setoption		db 'setoption',0
sz_quit 		db 'quit',0
sz_perft		db 'perft',0
sz_bench		db 'bench',0
sz_wtime		db 'wtime',0
sz_btime		db 'btime',0
sz_winc 		db 'winc',0
sz_binc 		db 'binc',0
sz_fen			db 'fen',0
sz_realtime		db 'realtime',0
sz_startpos		db 'startpos',0
sz_searchmoves		db 'searchmoves',0
sz_infinite		db 'infinite',0
sz_movestogo		db 'movestogo',0
sz_nodes		db 'nodes',0
sz_movetime		db 'movetime',0
sz_depth		db 'depth',0
sz_mate 		db 'mate',0
sz_name 		db 'name',0
sz_hash 		db 'hash',0
sz_value		db 'value',0
sz_ponder		db 'ponder',0
sz_threads		db 'threads',0
sz_contempt		db 'contempt',0
sz_clearhash		db 'clearhash',0
sz_multipv		db 'multipv',0
sz_weakness		db 'weakness',0
sz_moveoverhead 	db 'moveoverhead',0
sz_minthinktime 	db 'minthinktime',0
sz_slowmover		db 'slowmover',0
sz_uci_chess960 	db 'uci_chess960',0
sz_syzygypath		db 'syzygypath',0
sz_syzygyprobedepth	db 'syzygyprobedepth',0
sz_syzygy50moverule	db 'syzygy50moverule',0
sz_syzygyprobelimit	db 'syzygyprobelimit',0
sz_Info 		db 'info string processed cmd line command: ',0

BenchFens: ;fens must be separated by one or more space char
.bench_fen00 db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",' '
.bench_fen01 db "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 10",' '
.bench_fen02 db "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 11",' '
.bench_fen03 db "4rrk1/pp1n3p/3q2pQ/2p1pb2/2PP4/2P3N1/P2B2PP/4RRK1 b - - 7 19",' '
.bench_fen04 db "rq3rk1/ppp2ppp/1bnpb3/3N2B1/3NP3/7P/PPPQ1PP1/2KR3R w - - 7 14",' '
.bench_fen05 db "r1bq1r1k/1pp1n1pp/1p1p4/4p2Q/4Pp2/1BNP4/PPP2PPP/3R1RK1 w - - 2 14",' '
.bench_fen06 db "r3r1k1/2p2ppp/p1p1bn2/8/1q2P3/2NPQN2/PPP3PP/R4RK1 b - - 2 15",' '
.bench_fen07 db "r1bbk1nr/pp3p1p/2n5/1N4p1/2Np1B2/8/PPP2PPP/2KR1B1R w kq - 0 13",' '
.bench_fen08 db "r1bq1rk1/ppp1nppp/4n3/3p3Q/3P4/1BP1B3/PP1N2PP/R4RK1 w - - 1 16",' '
.bench_fen09 db "4r1k1/r1q2ppp/ppp2n2/4P3/5Rb1/1N1BQ3/PPP3PP/R5K1 w - - 1 17",' '
.bench_fen10 db "2rqkb1r/ppp2p2/2npb1p1/1N1Nn2p/2P1PP2/8/PP2B1PP/R1BQK2R b KQ - 0 11",' '
.bench_fen11 db "r1bq1r1k/b1p1npp1/p2p3p/1p6/3PP3/1B2NN2/PP3PPP/R2Q1RK1 w - - 1 16",' '
.bench_fen12 db "3r1rk1/p5pp/bpp1pp2/8/q1PP1P2/b3P3/P2NQRPP/1R2B1K1 b - - 6 22",' '
.bench_fen13 db "r1q2rk1/2p1bppp/2Pp4/p6b/Q1PNp3/4B3/PP1R1PPP/2K4R w - - 2 18",' '
.bench_fen14 db "4k2r/1pb2ppp/1p2p3/1R1p4/3P4/2r1PN2/P4PPP/1R4K1 b - - 3 22",' '
.bench_fen15 db "3q2k1/pb3p1p/4pbp1/2r5/PpN2N2/1P2P2P/5PP1/Q2R2K1 b - - 4 26",' '
.bench_fen16 db "6k1/6p1/6Pp/ppp5/3pn2P/1P3K2/1PP2P2/3N4 b - - 0 1",' '
.bench_fen17 db "3b4/5kp1/1p1p1p1p/pP1PpP1P/P1P1P3/3KN3/8/8 w - - 0 1",' '
.bench_fen18 db "2K5/p7/7P/5pR1/8/5k2/r7/8 w - - 0 1",' '
.bench_fen19 db "8/6pk/1p6/8/PP3p1p/5P2/4KP1q/3Q4 w - - 0 1",' '
.bench_fen20 db "7k/3p2pp/4q3/8/4Q3/5Kp1/P6b/8 w - - 0 1",' '
.bench_fen21 db "8/2p5/8/2kPKp1p/2p4P/2P5/3P4/8 w - - 0 1",' '
.bench_fen22 db "8/1p3pp1/7p/5P1P/2k3P1/8/2K2P2/8 w - - 0 1",' '
.bench_fen23 db "8/pp2r1k1/2p1p3/3pP2p/1P1P1P1P/P5KR/8/8 w - - 0 1",' '
.bench_fen24 db "8/3p4/p1bk3p/Pp6/1Kp1PpPp/2P2P1P/2P5/5B2 b - - 0 1",' '
.bench_fen25 db "5k2/7R/4P2p/5K2/p1r2P1p/8/8/8 b - - 0 1",' '
.bench_fen26 db "6k1/6p1/P6p/r1N5/5p2/7P/1b3PP1/4R1K1 w - - 0 1",' '
.bench_fen27 db "1r3k2/4q3/2Pp3b/3Bp3/2Q2p2/1p1P2P1/1P2KP2/3N4 w - - 0 1",' '
.bench_fen28 db "6k1/4pp1p/3p2p1/P1pPb3/R7/1r2P1PP/3B1P2/6K1 w - - 0 1",' '
.bench_fen29 db "8/3p3B/5p2/5P2/p7/PP5b/k7/6K1 w - - 0 1",' '
  ; 5-man positions
.bench_fen30 db "8/8/8/8/5kp1/P7/8/1K1N4 w - - 0 1",' '     ; Kc2 - mate
.bench_fen31 db "8/8/8/5N2/8/p7/8/2NK3k w - - 0 1",' '	    ; Na2 - mate
.bench_fen32 db "8/3k4/8/8/8/4B3/4KB2/2B5 w - - 0 1",' '    ; draw
  ; 6-man positions
.bench_fen33 db "8/8/1P6/5pr1/8/4R3/7k/2K5 w - - 0 1",' '   ; Re5 - mate
.bench_fen34 db "8/2p4P/8/kr6/6R1/8/8/1K6 w - - 0 1",' '    ; Ka2 - mate
.bench_fen35 db "8/8/3P3k/8/1p6/8/1P6/1K3n2 b - - 0 1",' '  ; Nd2 - draw
  ; 7-man positions
.bench_fen36 db "8/R7/2q5/8/6k1/8/1P5p/K6R w - - 0 124"  ; Draw
BenchFensEnd: db 0


sz_kernel32 db 'kernel32',0
sz_VirtualAllocExNuma db 'VirtualAllocExNuma',0
sz_SetThreadGroupAffinity db 'SetThreadGroupAffinity',0
sz_GetLogicalProcessorInformationEx db 'GetLogicalProcessorInformationEx',0

align 8
 Frequency   dq ?
 Period      dq ?
 hProcess    dq ?
 hStdOut     dq ?
 hStdIn      dq ?
 hStdError   dq ?
 __imp_MessageBoxA dq ?
 __imp_VirtualAllocExNuma dq ?
 __imp_SetThreadGroupAffinity dq ?
 __imp_GetLogicalProcessorInformationEx dq ?
 CmdLineStart	  dq ?
 InputBuffer	  dq ?	   ; input buffer has dynamic allocation
 InputBufferSizeB dq ?
 Output 	  rb 1024  ; output buffer has static allocation






section '.rdata' data readable writeable

align 16
 options	Options
 time		Time
 signals	Signals
 limits 	Limits
 easyMoveMng	EasyMoveMng
align 16
 mainHash	MainHash
align 16
 threadPool	ThreadPool



; this section is only read from after initialization
; the castling data is filled in when parsing the fen
; castling data should be moved to Pos struct in future versions
section '.bss' data readable writeable

;;;;;;;;;;;;;;;;;;;;;;;; data for move generation  ;;;;;;;;;;;;;;;;;;;;;;;;;;

align 64
 SlidingAttackMasks  rb 212*1024*4
 BishopAttacksPEXT   rq 64     ; bitboards
 BishopAttacksMOFF   rd 64     ; addresses, only 32 bits needed
 BishopAttacksPDEP   rq 64     ; bitboards
 RookAttacksPEXT     rq 64     ; bitboards
 RookAttacksMOFF     rd 64     ; addresses, only 32 bits needed
 RookAttacksPDEP     rq 64     ; bitboards
match =0, CPU_HAS_BMI2 {
 BishopAttacksIMUL   rq 64
 RookAttacksIMUL     rq 64
 BishopAttacksSHIFT  rb 64
 RookAttacksSHIFT    rb 64
}

; VAttacks       rq 64*64
; VAttacksPEXT   rq 64
; HAttacksPEXT   rq 64
; HAttacks       rq 64*64

PawnAttacks:
 WhitePawnAttacks    rq 64     ; bitboards
 BlackPawnAttacks    rq 64     ; bitboards
 KnightAttacks	     rq 64     ; bitboards
 KingAttacks	     rq 64     ; bitboards


;;;;;;;;;;;;;;;;;;; bitboards ;;;;;;;;;;;;;;;;;;;;;
 SquareDistance  rb 64*64
 BetweenBB	   rq 64*64
 LineBB 	   rq 64*64
 DistanceRingBB    rq 8*64
 ForwardBB	   rq 2*64
 PawnAttackSpan    rq 2*64
 PassedPawnMask    rq 2*64
 InFrontBB	   rq 2*8
 AdjacentFilesBB   rq 8
 FileBB 	   rq 8
 RankBB 	   rq 8

;;;;;;;;;;;;;;;;;;;; DoMove data ;;;;;;;;;;;;;;;;;;;;;;;;

align 64
Scores_Pieces:	   rq 16*64
Zobrist_Pieces:    rq 16*64
Zobrist_Castling:  rq 16
Zobrist_Ep:	   rq 8
Zobrist_side:	   rq 1
Zobrist_exclusion: rq 1
PieceValue_MG:	  rd 16
PieceValue_EG:	  rd 16

IsNotPawnMasks:   rb 16
IsNotPieceMasks:  rb 16
IsPawnMasks:	  rb 16


;;;;;;;;;;;;;;;;;;;; data for search ;;;;;;;;;;;;;;;;;;;;;;;

align 64
Reductions	   rd 2*2*64*64
FutilityMoveCounts rd 16*2
DrawValue	   rd 2


;;;;;;;;;; data for evaluation ;;;;;;;;;;;;;;;;;;;;
align 64
MobilityBonus_Knight rd 16
MobilityBonus_Bishop rd 16
MobilityBonus_Rook   rd 16
MobilityBonus_Queen  rd 32

KingDanger rd 512
Connected rd 2*2*2*8
Lever rd 8
ShelterWeakness rd 4*8
StormDanger:
StormDanger_NoFriendlyPawn rd 4*8
StormDanger_Unblocked rd 4*8
StormDanger_BlockedByPawn rd 4*8
StormDanger_BlockedByKing rd 4*8
KingFlank rq 2*8
ThreatBySafePawn rd 16
Threat_Minor rd 16
Threat_Rook rd 16
PassedRank rd 8
PassedFile rd 8

DoMaterialEval_Data:
.Linear:
	rd 8
.QuadraticOurs:
	rd 8
	rd 8
	rd 8
	rd 8
	rd 8
	rd 8
.QuadraticTheirs:
	rd 8
	rd 8
	rd 8
	rd 8
	rd 8
	rd 8



;;;;;;;;;;;;;; data for endgames ;;;;;;;;;;;;;;
align 64
EndgameEval_Map        rb 2*ENDGAME_EVAL_MAX_INDEX*sizeof.EndgameMapEntry
EndgameScale_Map       rb 2*ENDGAME_SCALE_MAX_INDEX*sizeof.EndgameMapEntry
EndgameEval_FxnTable   rd ENDGAME_EVAL_MAX_INDEX
EndgameScale_FxnTable  rd ENDGAME_SCALE_MAX_INDEX
KPKEndgameTable   rq 48*64
PushToEdges   rb 64
PushToCorners rb 64
PushClose     rb 8
PushAway      rb 8

;;;;;;;;;;;;;;;;;;;;; data for tablebase ;;;;;;;;;;;;;;
align 16
Tablebase_Hits rq 1
Tablebase_Cardinality rd 1
Tablebase_MaxCardinality rd 1
Tablebase_ProbeDepth  rd 1
Tablebase_Score  rd 1
Tablebase_RootInTB  rb 1    ; boole 0 or -1
Tablebase_UseRule50 rb 1    ; boole 0 or -1





;;;; make a section for tb   todo: this should be merged with previous two sections
section '.tb' data readable writeable

include 'TablebaseData.asm'



section '.code' code readable executable

include 'AvxMacros.asm'
include 'AttackMacros.asm'
include 'GenMacros.asm'
include 'MovePickMacros.asm'
include 'SearchMacros.asm'
include 'QSearchMacros.asm'
include 'MainHashMacros.asm'
include 'PosIsDrawMacro.asm'
include 'Pawn.asm'



include 'TablebaseCore.asm'
include 'Tablebase.asm'
include 'Endgame.asm'
include 'Evaluate.asm'

include 'MainHash_Probe.asm'

include 'Move_IsPseudoLegal.asm'
include 'SetCheckInfo.asm'
include 'Move_GivesCheck.asm'


include 'UpdateStats.asm'

include 'Gen_Captures.asm'
include 'Gen_Quiets.asm'
include 'Gen_QuietChecks.asm'
include 'Gen_Evasions.asm'
include 'MovePick.asm'

include 'Move_IsLegal.asm'
include 'Move_Do.asm'
include 'Move_Undo.asm'
include 'AttackersTo.asm'

	      align   16
QSearch_NonPv_NoCheck:
	    QSearch   _NONPV_NODE, 0
	      align   16
QSearch_NonPv_InCheck:
	    QSearch   _NONPV_NODE, 1
	      align   16
QSearch_Pv_InCheck:
	    QSearch   _PV_NODE, 1
	      align   16
QSearch_Pv_NoCheck:
	    QSearch   _PV_NODE, 0
	      align   16
Search_NonPv:
	    search   _NONPV_NODE


include 'See.asm'
include 'Move_DoNull.asm'
include 'CheckTime.asm'


include 'Castling.asm'

	     align   16
Search_Pv:
	    search   _PV_NODE
	     align   16
Search_Root:
	    search   _ROOT_NODE


include 'Gen_NonEvasions.asm'
include 'Gen_Legal.asm'
include 'Perft.asm'
include 'SetPinned.asm'


include 'EasyMoveMng.asm'
include 'Think.asm'
include 'TimeMng.asm'


include 'Position.asm'
include 'MainHash.asm'

include 'RootMoves.asm'
include 'Limits.asm'

include 'Thread.asm'
include 'ThreadPool.asm'
include 'Uci.asm'
include 'Search_Clear.asm'

include 'PrintParse.asm'
include 'Math.asm'

include 'OsWindows.asm'

if CPU_VERSION eq 'base'
 include 'Weakness.asm'
end if

Start:
	       push   rbp

	       call   _SetStdHandles
	       call   _SetFrequency
	       call   _CheckCPU

GD_String ' *** General Verbosity ON !! ***'
GD_NewLine
GD_NewLine

match =1, VERBOSE {
call _GetTime
mov qword[VerboseTime1+8*0], rdx
mov qword[VerboseTime1+8*1], rax
}

	; init the engine
	       call   Options_Init
	       call   MoveGen_Init
	       call   BitBoard_Init
	       call   Position_Init
	       call   BitTable_Init
	       call   Search_Init
	       call   Evaluate_Init
	       call   Pawn_Init
	       call   Endgame_Init

	; write engine name
match =0, VERBOSE {
		lea   rdi, [szGreetingEnd]
		lea   rcx, [szGreeting]
	       call   _WriteOut
}

	; set up threads, hash, and tablebases
		mov   ecx, dword[options.hash]
	       call   MainHash_Allocate
	       call   ThreadPool_Create
		lea   rcx, [?_345]     ; this is the <empty> string
	       call   TableBase_Init

	; command line could contain commands
	; this function also initializes InputBuffer
	; which contains the commands we should process first
	       call   ParseCommandLine

	; display how much time was taken for init
match =1, VERBOSE {
lea rdi, [VerboseOutput]
mov rax, 'response'
stosq
mov rax, ' time:  '
stosq
call _GetTime
sub rdx, qword[VerboseTime1+8*0]
sbb rax, qword[VerboseTime1+8*1]
mov r8, rdx
mov ecx, 1000
mul rcx
xchg rax, r8
mul rcx
lea rax, [r8+rdx]
call PrintUnsignedInteger
mov eax, ' us' + (10 shl 24)
stosd
lea rcx, [VerboseOutput]
call _WriteOut
}


	; enter the main loop
	       call   UciLoop

	; clean up threads, hash, and tablebases
		lea   rcx, [?_345]
	       call   TableBase_Init
	       call   ThreadPool_Destroy
	       call   MainHash_Free

	; clean up input buffer
		mov   rcx, qword[InputBuffer]
		mov   rdx, qword[InputBufferSizeB]
	       call   _VirtualFree
		xor   ecx, ecx
		mov   qword[InputBuffer], rcx
		mov   qword[InputBufferSizeB], rcx

match =1, DEBUG {
GD_String 'DebugBalance: '
GD_Int qword[DebugBalance]
GD_NewLine
}
	     Assert   e, qword[DebugBalance], 0, 'assertion DebugBalance=0 failed'

	       call   _ExitProcess

include 'ParseCommandLine.asm'
include 'Search_Init.asm'
include 'Position_Init.asm'
include 'MoveGen_Init.asm'
include 'BitBoard_Init.asm'
include 'BitTable_Init.asm'
include 'Evaluate_Init.asm'
include 'Pawn_Init.asm'
include 'Endgame_Init.asm'






section '.idata' import data readable writeable

 library kernel,'KERNEL32.DLL'

import kernel,\
	__imp_CreateFileA,'CreateFileA',\
	__imp_CreateMutexA,'CreateMutexA',\
	__imp_CloseHandle,'CloseHandle',\
	__imp_CreateEvent,'CreateEventA',\
	__imp_CreateFileMappingA,'CreateFileMappingA',\
	__imp_CreateThread,'CreateThread',\
	__imp_DeleteCriticalSection,'DeleteCriticalSection',\
	__imp_EnterCriticalSection,'EnterCriticalSection',\
	__imp_ExitProcess,'ExitProcess',\
	__imp_ExitThread,'ExitThread',\
	__imp_GetCommandLine,'GetCommandLineA',\
	__imp_GetCurrentProcess,'GetCurrentProcess',\
	__imp_GetFileSize,'GetFileSize',\
	__imp_GetLastError,'GetLastError',\
	__imp_GetModuleHandle,'GetModuleHandleA',\
	__imp_GetProcAddress,'GetProcAddress',\
	__imp_GetStdHandle,'GetStdHandle',\
	__imp_InitializeCriticalSection,'InitializeCriticalSection',\
	__imp_LeaveCriticalSection,'LeaveCriticalSection',\
	__imp_LoadLibrary,'LoadLibraryA',\
	__imp_MapViewOfFile,'MapViewOfFile',\
	__imp_QueryPerformanceCounter,'QueryPerformanceCounter',\
	__imp_QueryPerformanceFrequency,'QueryPerformanceFrequency',\
	__imp_ReadFile,'ReadFile',\
	__imp_ReleaseMutex,'ReleaseMutex',\
	__imp_ResumeThread,'ResumeThread',\
	__imp_SetEvent,'SetEvent',\
	__imp_SetPriorityClass,'SetPriorityClass',\
	__imp_Sleep,'Sleep',\
	__imp_UnmapViewOfFile, 'UnmapViewOfFile',\
	__imp_VirtualAlloc,'VirtualAlloc',\
	__imp_VirtualFree,'VirtualFree',\
	__imp_WaitForSingleObject,'WaitForSingleObject',\
	__imp_WriteFile,'WriteFile'

