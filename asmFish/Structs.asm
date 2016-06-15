; these are all of the structs used
;
; _VirtualAlloc is called only for:
; (1) MainHash.table
; (2) the following elements of the Pos struct
;    Pos.state
;    Pos.history
;    Pos.counterMoves
;    Pos.materialTable
;    Pos.pawnTable
;    Pos.rootMovesVec.table
;   these all are allocated for each of the search threads
;   the GUI thread only has Pos.state allocated on its two pos1 and pos2 structs
;     GUI thread has two Pos structs in case the engine is sent an illegal position
;
; _VirtualAlloc is always called only from the GUI thread


;;;;;;;;;;;;;;;;;;;;;;;;;
; evaluation structures
;;;;;;;;;;;;;;;;;;;;;;;;;

; this struct sits on the stack for the whole duration of evaluation
struct EvalInfo
 attackedBy   rq 16
 pinnedPieces rq 2
 mobilityArea rq 2
 kingRing     rq 2
 kingAttackersCount rd 2
 kingAttackersWeight rd 2
 kingAdjacentZoneAttacksCount rd 2
 ksq  rd 2
 me   rq 1
 pi   rq 1
 mobility rd 2
 score	  rd 1
	  rd 1
ends

struct EndgameMapEntry
 key	rq 1
 entry	rb 1
	rb 7 ; assumed to be zeros
ends


;;;;;;;;;;;;;;;;;;;;
; hash table structures
;;;;;;;;;;;;;;;;;;;;


struct MainHash
 table	rq 1
 mask	rq 1
	rq 1
 sizeMB rd 1
 date	rb 1
	rb 3
ends

struct MainHashEntry	; 8 bytes
 genBound  rb 1  ;
 depth	   rb 1  ;
 move	   rw 1  ;
 eval	   rw 1  ;
 value	   rw 1  ; this order is fixed
ends


struct MaterialEntry	; 16 bytes
 key		    rq 1
 scalingFunction    rb 2   ; these are 1 byte endgame structures
 evaluationFunction rb 1   ; they store the EndgameEntry.entry member
 gamePhase	    rb 1
 factor 	    rb 2
 value		    rw 1
ends


struct PawnEntry	; 80 bytes
 passedPawns	 rq 2
 pawnAttacks	 rq 2
 pawnAttacksSpan rq 2
 key		rq 1
 kingSafety	rd 2
 score		rd 1
 kingSquares	rb 2  ; [0,63] each
 semiopenFiles	rb 2
 pawnsOnSquares rb 4  ; [0,4] each
 pawnSpan	rb 2  ; [0,7] each
 asymmetry	rb 1  ; [0,8]
 castlingRights rb 1
ends


;;;;;;;;;;;;;;;;;;;;
; move structures
;;;;;;;;;;;;;;;;;;;;

struct ExtMove	 ; holds moves for gen/pick
 move	rd 1
 score	rd 1
ends


struct Pick
 cur		 rq 1	  ;0
 endMoves	 rq 1	  ;8
 endBadCaptures  rq 1	  ;16
 stage		 rq 1	  ;24
 ttMove 	  rd 1	  ;32
 threshold	  rd 1
 countermove	  rd 1	  ;40
 followupmoves	  rd 1
 recaptureSquare  rd 1	  ;48
 depth		  rd 1
 killers    rb sizeof.ExtMove*3  ;56
 moves	    rb sizeof.ExtMove*MAX_MOVES ;80
ends					;1872


struct RootMovesVec
 table	rq 1
 ender	rq 1
ends


struct RootMove   ; holds root moves
 prevScore rd 1 ; this order is used in PrintUciInfo
 score	   rd 1 ;
 pvSize    rd 1
	   rd 1
 pv	   rd MAX_PLY
ends


;;;;;;;;;;;;;;;;;;
; position structures
;;;;;;;;;;;;;;;;;;

struct Pos
 typeBB      rq 8
 board	     rb 64
 sideToMove  rd 1
	     rd 1
 gamePly     rd 1
 chess960    rd 1
 _copy_size rb 0

match =1, DEBUG {
 debugPointer	rq 1
 debugMove	rd 1
		rd 1
}

 state		rq 1 ; the current state struct
 stateTable	rq 1 ; the beginning of the state of State structs
 stateEnd	rq 1 ; the end of
 history	rq 1		 ; these structs hold addresses
 counterMoves	rq 1		 ; of tables used by the search
 materialTable	rq 1		 ;
 pawnTable	rq 1		 ;
 rootMovesVec	RootMovesVec	 ;
ends



; Since the original State struct is used in a stack like fasion
;  with the Stack struct, these are combined into one struct
; Also, the CheckInfo struct can be harmlessly moved here too

struct State
; State struct
 key		rq 1
 pawnKey	rq 1
 materialKey	rq 1
 psq		rw 2
 npMaterial	rw 2
 rule50 	rb 1  ; these should be together
 pliesFromNull	rb 1  ;
 castlingRights rb 1
 epSquare	rb 1
 move		rw 1  ; currently only used for undo cmd in global pos structure
 capturedPiece	rb 1
; CheckInfo struct
 ksq		rb 1
 checkersBB	rq 1   ; this is actually not part of checkinfo
 dcCandidates	rq 1
 pinned 	rq 1
 checkSq	rq 8
; Stack struct
_stack_start rb 0
 pv		rq 1
 counterMoves	rq 1
 currentMove	rd 1
 excludedMove	rd 1
 killers	rd 2
 moveCount	rd 1
 staticEval	rd 1
 ply		rd 1
 skipEarlyPruning rb 1
		  rb 3
_stack_end rb 0
ends



;;;;;;;;;;;;;;;;;;;;
; search structures
;;;;;;;;;;;;;;;;;;;;


struct Limits
 nodes	     rq 1
 startTime   rq 1
 time	     rd 2
 incr	     rd 2
 movestogo   rd 1
 depth	     rd 1
 movetime    rd 1
 mate	     rd 1
 multiPV     rd 1
	     rd 1
 infinite    rb 1
 ponder      rb 1
 useTimeMgmt rb 1
	     rb 1
	     rb 4
ends


struct Options
 displayInfoFxn rq 1	  ; function for printing pv
 displayMoveFxn rq 1
 hash		rd 1
 multiPV	rd 1
 threads       rd 1
 weakness      rd 1
 chess960      rd 1
 contempt      rd 1
 minThinkTime	rd 1
 slowMover	rd 1
 moveOverhead	rd 1
 ponder 	rb 1
		rb 3
 syzygy50MoveRule rb 1	    ; bool 0 or -1
		  rb 7
 syzygyProbeDepth rd 1
 syzygyProbeLimit rd 1
 syzygyPath	rb 64
ends


struct EasyMoveMng
 expectedPosKey rq 1
 pv		rd 4
 stableCnt	rd 1
		rd 3
ends


struct Signals
 stop		 rb 1
 stopOnPonderhit rb 1
		 rb 14
ends


struct Time
 startTime   rq 1
 optimumTime rq 1
 maximumTime rq 1
	     rq 1
ends




;;;;;;;;;;;;;;;;;;;;
; thread structures
;;;;;;;;;;;;;;;;;;;;

struct Thread
 mutex		 rq 5
 sleepCond	 rq 1
 sleepCond2	 rq 1
 handle 	 rq 1
 bestMoveChanges rq 1
 nodes		 rq 1
 idx		 rd 1
 rootDepth	 rd 1
 PVIdx		 rd 1
 previousScore	 rd 1
 completedDepth  rd 1
 callsCnt	 rd 1
 searching	 rb 1
 exit		 rb 1
 failedLow	 rb 1
 easyMovePlayed  rb 1
 resetCalls	 rb 1
		 rb 1
		 rb 1
		 rb 1
 rootPos	 Pos
ends


struct ThreadPool
 stackPointer	rq 1 ; address of last worker Thread stuct
		rq 1
ends




; some assumptions are made on the size of structers

if sizeof.ExtMove <> 8
 err
end if












