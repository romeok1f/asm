; this is the source for unix  see asmsfw.asm for windows
; THIS FILE IS UNDER CONSTRUCTION
; WILL NOT GENERATE UNIX PROGRAM

OS_IS_WINDOWS	 fix 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; compile options 0 or 1
CPU_HAS_POPCNT	 equ 1	;  popcnt                       very nice function
CPU_HAS_AVX1	 equ 1	;  256 bit floating point       probably only used for memory copy
CPU_HAS_AVX2	 equ 0	;  256 bit integer + fmadd      probably not used
CPU_HAS_BMI1	 equ 0	;  andn                         why not use it if we can
CPU_HAS_BMI2	 equ 0	;  pext + pdep                  nice for move generation, but not much faster than magics
DEBUG		 equ 0	;  turns on the asserts         asserts are agressive but should be NO functional change
VERBOSE 	 equ 1	;  lots of printing             caution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


format PE64 console
entry Start

include 'win64a.inc'
include 'Def.asm'
include 'BasicMacros.asm'
include 'Structs.asm'
include 'Debug.asm'



section '.data' data readable writeable


match =1, DEBUG {
 trace.Material  dd 0
 trace.Imbalance dd 0
 trace.Pawn	 dd 0
 trace.Knight	 dd 0,0,0
 trace.Bishop	 dd 0,0,0
 trace.Rook	 dd 0,0,0
 trace.Queen	 dd 0,0,0
 trace.Mobility  dd 0,0,0
 trace.King	 dd 0,0,0
 trace.Threats	 dd 0,0,0
 trace.PassedPawns  dd 0,0,0
 trace.Space	 dd 0,0,0
 trace.Total	 dd 0
}

match =1, VERBOSE {
align 16
  VerboseOutput  rq 1024
  VerboseTime1 rq 2
  VerboseTime2 rq 2
}

match =1, DEBUG {
align 16
  DebugOutput  rq 1024
  DebugBalance rd 1
}


align 16
RazorMargin dd 483, 570, 603, 554
CaptureOrPromotion_or  db 0,0,1,1,1,1,0,1
CaptureOrPromotion_and db 1,0,1,1,1,1,0,1

align 16
constd:
.0p01	 dq 0.01
.0p03	 dq 0.03
.0p505	 dq 0.505
.1p0	 dq 1.0
.634	 dq 634.0
.min	 dq 0x0010000000000000

?_2726: 						; oword
	dq 0FFFFFFFFFFFFFFF7H				; 1A90 _ FFFFFFFFFFFFFFF7 
	dq 0000000000000007H				; 1A98 _ 0000000000000007 

?_2727: dq 8181818181818181H				; 1AA0 _ 8181818181818181 
?_2728: dq 0FF000000000000FFH				; 1AA8 _ FF000000000000FF
?_2729: dq 3FE0000000000000H				; 1AB0 _ 0.5
?_2730: dq 3FE999999999999AH				; 1AB8 _ 0.8
?_2731: dq 3FFCCCCCCCCCCCCDH				; 1AC0 _ 1.8
?_2732: dq 3FE8BC6A7EF9DB23H				; 1AC8 _ 0.773
?_2733: dq 4003333333333333H				; 1AD0 _ 2.4
?_2734: dq 3FDF5C28F5C28F5CH				; 1AD8 _ 0.49
?_2735: dq 3FF0B851EB851EB8H				; 1AE0 _ 1.045
?_2736: dq 4007333333333333H				; 1AE8 _ 2.9
?_2737: dq 4059000000000000H				; 1AF0 _ 100.0
?_2738: dq 401C5C28F5C28F5CH				; 1AF8 _ 7.09
?_2739: dq 3FD6666666666666H				; 1B00 _ 0.35
?_2740: dq 404D333333333333H				; 1B08 _ 58.4
?_2741: dq 401E8F5C28F5C28FH				; 1B10 _ 7.64
?_2742: dq 0BFC76C8B43958106H				; 1B18 _ -0.183
?_2748: dq 0000FFFFFF000000H				; 1B48 _ 0000FFFFFF000000


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
 XBoardMove dd 0
 XBoardMode db 0


 szGreeting	  db 'stockfish '
 szDate:	  create_build_time DAY, MONTH, YEAR
 szCPUTarget:
match =1, DEBUG {	    db ' DEBUG'     }
match =1, CPU_HAS_POPCNT {  db ' POPCNT'    }
match =1, CPU_HAS_AVX1 {    db ' AVX1'	    }
match =1, CPU_HAS_AVX2 {    db ' AVX2'	    }
match =1, CPU_HAS_BMI1 {    db ' BMI1'	    }
match =1, CPU_HAS_BMI2 {    db ' BMI2'	    }
		  db 10,0

 szUCIresponse	  db 'id name stockfish '
		  create_build_time DAY, MONTH, YEAR
		  db 10
		  db 'id author fasm',10
		  db 'option name Hash type spin min 1 max 65536 default 16',10
		  db 'option name MultiPV type spin min 1 max 64 default 1',10
		  db 'option name Ponder type check default false',10
		  db 'option name Threads type spin min 1 max 8 default 1',10
		  db 'option name Weakness type spin min 0 max 1000 default 0',10
		  db 'uciok',10,0
 szCPUError	  db 'Error: processor does not support',0
   .POPCNT	  db ' POPCNT',0
   .AVX1	  db ' AVX1',0
   .AVX2	  db ' AVX2',0
   .BMI1	  db ' BMI1',0
   .BMI2	  db ' BMI2',0
 szReadyOK	  db 'readyok',10,0
 szOK		  db 'ok',10,0
 szError	  db 'error',10,0
 szParseError	  db 'command parsing error',10,0
 szStartPosition  db 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',0
 PieceToChar	  db '.?PNBRQK??pnbrqk'
 ToLowerCase:	  ; use assembler to make table for case conversion
		  db   0
repeat 127
	if (% >= 'A') & ( % <='Z')
		  db   % +('a'-'A')
	else
		  db   %
	end if
end repeat



align 8
 Frequency   dq ?
 Period      dq ?
match =1, OS_IS_WINDOWS {
 hStdOut     dq ?
 hStdIn      dq ?
 hStdError   dq ?
 __imp_MessageBoxA rq 1
}
 InputBuffer	  dq ?	   ; input buffer has dynamic allocation
 InputBufferSizeB dq ?
 Output 	  rq 1024  ; output buffer has static allocation






section '.rdata' data readable writeable

align 16
 workThreads	rb sizeof.Thread*(MAX_THREADS-1)
 mainThread	Thread
 threadPool	ThreadPool
 mainHash	MainHash
 pos1		Pos
 pos2		Pos
 options	Options
 time		Time
 signals	Signals
 limits 	Limits
 easyMoveMng	EasyMoveMng


align 64
 CounterMoveHistory rd 16*64*16*64







; this section is only read from after initialization
; the castling data is filled in when parsing the fen
; castling data should be moved to position struct
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

 castling_rightsMask rb 64
 castling_rfrom      rb 4
 castling_rto	     rb 4
 castling_path	     rq 4
 castling_ksqpath    rb 4*8
 castling_knights    rq 4
 castling_kingpawns  rq 4
 castling_movgen     rd 4

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
Doubled rd 8
Lever rd 8
ShelterWeakness rd 4*8
StormDanger:
StormDanger_NoFriendlyPawn rd 4*8
StormDanger_Unblocked rd 4*8
StormDanger_BlockedByPawn rd 4*8
StormDanger_BlockedByKing rd 4*8
ThreatBySafePawn rd 16
Threat_Minor rd 16
Threat_Rook rd 16
PassedRank rd 8
PassedFile rd 8





;;;;;;;;;;;;;; data for endgames ;;;;;;;;;;;;;;
align 64

EndgameEval_Map 	rb 2*ENDGAME_EVAL_MAX_INDEX*sizeof.EndgameMapEntry
EndgameScale_Map	rb 2*ENDGAME_SCALE_MAX_INDEX*sizeof.EndgameMapEntry
EndgameEval_FxnTable	rd ENDGAME_EVAL_MAX_INDEX
EndgameScale_FxnTable	rd ENDGAME_SCALE_MAX_INDEX
KPKEndgameTable   rq 48*64 ; bit table for lookup



;;;;;;;;;;;;;;;;; old junk ;;;;;;;;;;;;;;;;;;;;;;
;WhitePassedPawns  rq 64    ; bitboards
;BlackPassedPawns  rq 64    ; bitboards
;IsolatedPawns     rq 64    ; bitboards
;WhiteDoubledPawns rq 64
;BlackDoubledPawns rq 64









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

include 'Endgame.asm'

include 'CheckTime.asm'
include 'DoNullMove.asm'
include 'Evaluate.asm'
include 'MainHash_Probe.asm'
include 'QSearch.asm'
include 'Search.asm'
include 'UpdateStats.asm'

include 'AttackersTo.asm'
include 'SetCheckInfo.asm'
include 'SetPinned.asm'
include 'DoMove.asm'
include 'GivesCheck.asm'
include 'UndoMove.asm'
include 'Gen_NonEvasions.asm'
include 'Gen_Legal.asm'
include 'Gen_Evasions.asm'

include 'Castling.asm'
include 'PerftGen.asm'

include 'Gen_Quiets.asm'
include 'Gen_QuietChecks.asm'
include 'Gen_Captures.asm'

include 'IsMoveLegal.asm'
include 'IsMovePseudoLegal.asm'
include 'MovePick.asm'
include 'See.asm'
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

include 'PrintParse.asm'
include 'Math.asm'

include 'OsWindows.asm'

Start:
	       push   rbp


VerboseDisplayScore rax

	       call   _SetStdHandles
	       call   _SetFrequency
	       call   _CheckCPU

match =1, VERBOSE {
	       call   _GetTime
		mov   qword[VerboseTime1+8*0], rdx
		mov   qword[VerboseTime1+8*1], rax  }

	; init input buffer
		mov   ecx, 4096
		mov   qword[InputBufferSizeB], rcx
	       call   _VirtualAlloc
		mov   qword[InputBuffer], rax

	; init the engine
	       call   Options_Init
	       call   BitBoard_Init
	       call   MoveGen_Init
	       call   Position_Init
	       call   BitTable_Init
	       call   Search_Init
	       call   Evaluate_Init
	       call   Pawn_Init
	       call   Endgame_Init

	; set up threads and hash
		mov   ecx, dword[options.hash]
	       call   MainHash_Allocate
	       call   ThreadPool_Create

	; command line could contain settings for threads and hash
	       call   ParseCommandLine

	; write engine name
match =1, VERBOSE {
		lea   rdi, [Output]
		mov   rax, 'response'
	      stosq
		mov   rax, ' time:  '
	      stosq
	       call   _GetTime
		sub   rdx, qword[VerboseTime1+8*0]
		sbb   rax, qword[VerboseTime1+8*1]
		mov   r8, rdx
		mov   ecx, 1000
		mul   rcx
	       xchg   rax, r8
		mul   rcx
		lea   rax, [r8+rdx]
	       call   PrintUnsignedInteger
		mov   eax, ' us' + (10 shl 24)
	      stosd
	       call   _WriteOut_Output	    ; display how much time was taken for init
}
		lea   rdi, [Output]
		lea   rcx, [szGreeting]
	       call   PrintString
	       call   _WriteOut_Output

	; enter uci loop by default

	       call   _ReadIn
match =1, VERBOSE {
	       call   _GetTime
		mov   qword[VerboseTime1+8*0], rdx
		mov   qword[VerboseTime1+8*1], rax
}
	    stdcall   CmpStringCaseLess, 'quit'
	       test   eax, eax
		jnz   @f
	    stdcall   CmpStringCaseLess, 'xboard'
		lea   rcx, [UciLoop]
		lea   rdx, [XBoardLoop]
	       test   eax, eax
	     cmovnz   rcx, rdx
	       call   rcx
	@@:

	; clean up threads and hash
	       call   ThreadPool_Destroy
	       call   MainHash_Free

	; clean up input buffer
		mov   rcx, qword[InputBuffer]
	       call   _VirtualFree
		xor   ecx, ecx
		mov   qword[InputBuffer], rcx
		mov   qword[InputBufferSizeB], rcx

	     Assert   e, dword[DebugBalance], 0, 'assertion dword[DebugBalance]==0 failed'
	       call   _ExitProcess

include 'XBoard.asm'
include 'ParseCommandLine.asm'
include 'Search_InitClear.asm'
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
	__imp_CloseHandle,'CloseHandle',\
	__imp_CreateEvent,'CreateEventA',\
	__imp_CreateThread,'CreateThread',\
	__imp_DeleteCriticalSection,'DeleteCriticalSection',\
	__imp_EnterCriticalSection,'EnterCriticalSection',\
	__imp_ExitProcess,'ExitProcess',\
	__imp_ExitThread,'ExitThread',\
	__imp_GetCommandLine,'GetCommandLineA',\
	__imp_GetCurrentProcess,'GetCurrentProcess',\
	__imp_GetProcAddress,'GetProcAddress',\
	__imp_GetProcessAffinityMask,'GetProcessAffinityMask',\
	__imp_GetStdHandle,'GetStdHandle',\
	__imp_InitializeCriticalSection,'InitializeCriticalSection',\
	__imp_LeaveCriticalSection,'LeaveCriticalSection',\
	__imp_LoadLibrary,'LoadLibraryA',\
	__imp_QueryPerformanceCounter,'QueryPerformanceCounter',\
	__imp_QueryPerformanceFrequency,'QueryPerformanceFrequency',\
	__imp_ReadFile,'ReadFile',\
	__imp_SetEvent,'SetEvent',\
	__imp_SetThreadAffinityMask,'SetThreadAffinityMask',\
	__imp_Sleep,'Sleep',\
	__imp_VirtualAlloc,'VirtualAlloc',\
	__imp_VirtualFree,'VirtualFree',\
	__imp_WaitForSingleObject,'WaitForSingleObject',\
	__imp_WriteFile,'WriteFile'

