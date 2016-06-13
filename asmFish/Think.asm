Thread_Think:
	; in: rcx address of Thread struct

	       push   rbp rbx rsi rdi r13 r14 r15
virtual at rsp
 .completedDepth rd 1
 .alpha      rd 1
 .beta	     rd 1
 .delta      rd 1
 .bestValue  rd 1
 .easyMove   rd 1
 .multiPV    rd 1
 .lend	     rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

		lea   rbp, [rcx+Thread.rootPos]
		mov   rbx, qword[rbp+Pos.state]
VerboseDisplay	 <db 'Thread_Think',10>

		mov   dword[.easyMove], 0
		mov   dword[.alpha], -VALUE_INFINITE
		mov   dword[.beta], +VALUE_INFINITE
		mov   dword[.delta], -VALUE_INFINITE
		mov   dword[.bestValue], -VALUE_INFINITE
		mov   dword[.completedDepth], 0

	; clear the search stack
		lea   rdx, [rbx-5*sizeof.State]
		lea   r8, [rbx+3*sizeof.State]
.clear_stack:
		xor   eax, eax
		lea   rdi, [rdx+State._stack_start]
		mov   ecx, State._stack_end-State._stack_start
	  rep stosb
		add   rdx, sizeof.State
		cmp   rdx, r8
		 jb   .clear_stack


	; resets for main thread
		cmp   rbp, mainThread.rootPos
		jne   .skip_easymove
		mov   rcx, qword[rbx+State.key]
	       call   EasyMoveMng_Get
		mov   dword[.easyMove], eax
	       call   EasyMoveMng_Clear
		xor   eax, eax
		mov   byte[rbp-Thread.rootPos+Thread.easyMovePlayed], al
		mov   byte[rbp-Thread.rootPos+Thread.failedLow], al
		mov   qword[rbp-Thread.rootPos+Thread.bestMoveChanges], rax
.skip_easymove:

	; set multiPV
		lea   rcx, [rbp+Pos.rootMovesVec]
	       call   RootMovesVec_Size
		mov   ecx, dword[options.multiPV]
		cmp   eax, ecx
	      cmova   eax, ecx
		mov   dword[.multiPV], eax

	; id loop
		mov   r15d, dword[rbp-Thread.rootPos+Thread.rootDepth]	 ; this should be set to 0 by ThreadPool_StartThinking
.id_loop:
		mov   al, byte[signals.stop]
		mov   ecx, dword[limits.depth]
		sub   ecx, 1
		cmp   r15d, ecx
		 ja   .id_loop_done
		add   r15d, 1
		mov   dword[rbp-Thread.rootPos+Thread.rootDepth], r15d
		cmp   r15d, MAX_PLY
		jge   .id_loop_done
	       test   al, al
		jnz   .id_loop_done

	; skip depths for helper threads
		mov   eax, dword[rbp-Thread.rootPos+Thread.idx]
		mov   ecx, HalfDensitySize
		sub   eax, 1
		 jc   .age_out
		xor   edx, edx
		div   ecx
		mov   r8d, dword[HalfDensityRows+8*rdx+4*0]
		mov   r9d, dword[HalfDensityRows+8*rdx+4*1]
		mov   eax, dword[rbp+Pos.gamePly]
		add   eax, r15d
		xor   edx, edx
		div   r8d
		 bt   r9d, edx
		 jc   .id_loop
		jmp   .save_prev_score
.age_out:
	; Age out PV variability metric
	     vmovsd   xmm0, qword[rbp-Thread.rootPos+Thread.bestMoveChanges]
	     vmulsd   xmm0, xmm0, qword[constd.0p505]
		mov   byte[rbp-Thread.rootPos+Thread.failedLow], 0
	     vmovsd   qword[rbp-Thread.rootPos+Thread.bestMoveChanges], xmm0

.save_prev_score:
	; Save the last iteration's scores before first PV line is searched and all the move scores except the (new) PV are set to -VALUE_INFINITE.
		mov   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
    .save_next:
		mov   eax, dword[rcx+RootMove.score]
		mov   dword[rcx+RootMove.prevScore], eax
		add   rcx, sizeof.RootMove
		cmp   rcx, rdx
		 jb   .save_next

	; MultiPV loop. We perform a full root search for each PV line
		 or   r14d, -1
.multipv_loop:
		add   r14d, 1
		mov   al, byte[signals.stop]
		mov   dword[rbp-Thread.rootPos+Thread.PVIdx], r14d
		cmp   r14d, dword[.multiPV]
		jae   .multipv_done
	       test   al, al
		jnz   .multipv_done

VerboseDisplay	db 'Thread.PVIdx: '
VerboseDisplayInt r14

	; Reset aspiration window starting size
	       imul   r8d, r14d, sizeof.RootMove
		mov   edx, 18
		add   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		cmp   r15d, 5
		 jl   .reset_window_done
		mov   eax, dword[r8+RootMove.prevScore]
		mov   ecx, -VALUE_INFINITE
		sub   eax, edx
		cmp   eax, ecx
	      cmovl   eax, ecx
		mov   dword[.alpha], eax
		mov   eax, dword[r8+RootMove.prevScore]
		mov   ecx, VALUE_INFINITE
		add   eax, edx
		cmp   eax, ecx
	      cmovg   eax, ecx
		mov   dword[.beta], eax
		mov   dword[.delta], edx
    .reset_window_done:

	; Start with a small aspiration window and, in the case of a fail high/low, re-search with a bigger window until we're not failing high/low anymore.
.search_loop:

VerboseDisplay	db 'alpha:  '
VerboseDisplayInt qword[.alpha]
VerboseDisplay	db 'beta:   '
VerboseDisplayInt qword[.beta]


		mov   ecx, dword[.alpha]
		mov   edx, dword[.beta]
		mov   r8d, r15d
		xor   r9d, r9d
	       call   Search_Root ; rootPos is in rbp, ss is in rbx
		mov   r12d, eax
		mov   dword[.bestValue], eax


VerboseDisplay <db 'Search_Root returned '>
VerboseDisplayInt rax


	       imul   ecx, r14d, sizeof.RootMove
		add   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
	       call   RootMovesVec_StableSort

match =1, VERBOSE {
		lea   rdi, [Output]
	       call   RootMovesVec_Print
		lea   rcx, [Output]
	       call   _WriteOut
}
	; Write PV back to the transposition table in case the relevant entries have been overwritten during the search.
		mov   esi, r14d
	.insert_next:
	       imul   ecx, esi, sizeof.RootMove
		add   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
	       call   RootMove_InsertPVInTT
		sub   esi, 1
		jns   .insert_next

	; If search has been stopped, break immediately. Sorting and writing PV back to TT is safe because RootMoves is still valid, although it refers to the previous iteration.
		mov   al, byte[signals.stop]
	       test   al, al
		jnz   .search_done

	; When failing high/low give some update before a re-search.
		cmp   rbp, mainThread.rootPos
		jne   .dont_print_pv
		mov   eax, dword[.multiPV]
		cmp   eax, 1
		jne   .dont_print_pv
		cmp   r12d, dword[.alpha]
		jle   @f
		cmp   r12d, dword[.beta]
		 jl   .dont_print_pv
	@@:    call   _GetTime
		sub   rax, qword[time.startTime]
match =0, VERBOSE {
		cmp   rax, 3000
		jbe   .dont_print_pv
}
		mov   ecx, r15d
		mov   edx, dword[.alpha]
		mov   r8d, dword[.beta]
		mov   r9, rax
		mov   r10d, dword[.multiPV]
	       call   qword[options.displayInfoFxn]
	.dont_print_pv:

	; In case of failing low/high increase aspiration window and re-search, otherwise exit the loop.
		mov   r8d, dword[.alpha]
		mov   r9d, dword[.beta]
		mov   eax, dword[.delta]
		mov   r10d, eax
		cdq
		and   edx, 3
		add   eax, edx
		sar   eax, 2
		lea   r10d, [r10+rax+5]
	; r10d = delta + delta / 4 + 5
		lea   eax, [r8+r9]
		cdq
		sub   eax, edx
		sar   eax, 1
	; eax = (alpha + beta) / 2
		mov   edx, r12d
		cmp   r12d, r8d
		jle   .fail_low
		cmp   r12d, r9d
		 jl   .search_done
    .fail_high:
		add   edx, dword[.delta]
		mov   ecx, VALUE_INFINITE
		cmp   edx, ecx
	      cmovg   edx, ecx
		mov   dword[.alpha], eax
		mov   dword[.beta], edx
		mov   dword[.delta], r10d
		jmp   .search_loop
    .fail_low:
		sub   edx, dword[.delta]
		mov   ecx, -VALUE_INFINITE
		cmp   edx, ecx
	      cmovl   edx, ecx
		mov   dword[.alpha], edx
		mov   dword[.beta], eax
		mov   dword[.delta], r10d
		cmp   rbp, mainThread.rootPos
		jne   .search_loop
		mov   byte[rbp-Thread.rootPos+Thread.failedLow], -1
		mov   byte[signals.stopOnPonderhit], 0
		jmp   .search_loop
.search_done:

	; Sort the PV lines searched so far and update the GUI
	       imul   edx, r14d, sizeof.RootMove
		mov   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		lea   rdx, [rcx+rdx+sizeof.RootMove]
	       call   RootMovesVec_StableSort

		cmp   rbp, mainThread.rootPos
		jne   .multipv_loop

	       call   _GetTime
		mov   r9, rax
		sub   r9, qword[time.startTime]
		lea   eax, [r14+1]
		cmp   eax, dword[.multiPV]
		 je   @f
match =0, VERBOSE {
		cmp   r9, 3000
		jbe   .multipv_loop
}
	@@:	
		mov   ecx, r15d
		mov   edx, dword[.alpha]
		mov   r8d, dword[.beta]
		mov   r10d, dword[.multiPV]
	       call   qword[options.displayInfoFxn]

		jmp   .multipv_loop

.multipv_done:
		mov   al, byte[signals.stop]
	       test   al, al
		jnz   @f
		mov   dword[rbp-Thread.rootPos+Thread.completedDepth], r15d
	@@:
		cmp   rbp, mainThread.rootPos
		jne   .id_loop

	; If skill level is enabled and time is up, pick a sub-optimal best move
		; not implemented


	; Have we found a "mate in x"

	; r12d = bestValue  remember

		mov   al, byte[limits.useTimeMgmt]
	       test   al, al
		 jz   .id_loop

		mov   al, byte[signals.stop]
		 or   al, byte[signals.stopOnPonderhit]
		jnz   .handle_easymove

	       call   _GetTime
		sub   rax, qword[time.startTime]
		mov   r11, rax
	; r11 = Time.elapsed()

		xor   eax, eax
		cmp   al, byte[rbp-Thread.rootPos+Thread.failedLow]
	      setne   al
	       imul   eax, 119
		add   eax, 357
		mov   ecx, r12d
		sub   ecx, dword[rbp-Thread.rootPos+Thread.previousScore]
	       imul   ecx, 6
		sub   eax, ecx
		mov   edx, 229
		cmp   eax, edx
	      cmovl   eax, edx
		mov   edx, 715
		cmp   eax, edx
	      cmovg   eax, edx
	  vcvtsi2sd   xmm3, xmm3, eax
	; xmm3 = improvingFactor

		mov   eax, dword[time.optimumTime]
		mov   ecx, 5
		mul   ecx
		mov   ecx, 42
		div   ecx
	; eax = Time.optimum() * 5 / 42
		mov   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[r8+RootMove.pv+4*0]

	     vmovsd   xmm0, qword[rbp-Thread.rootPos+Thread.bestMoveChanges]
	     vmovsd   xmm2, qword[constd.1p0]
	     vaddsd   xmm2, xmm2, xmm0
	; xmm2 = unstablePvFactor

		xor   r9d, r9d
		cmp   r11d, eax
		jbe   @f
		cmp   ecx, dword[.easyMove]
		jne   @f
	    vcomisd   xmm0, qword[constd.0p03]
		sbb   r9d, r9d
		@@:
	; r9d = doEasyMove

	     vmulsd   xmm2, xmm2, xmm3
	  vcvtsi2sd   xmm0, xmm0, r11d
	     vmulsd   xmm0, xmm0, qword[constd.628p0]
	  vcvtsi2sd   xmm1, xmm1, dword[time.optimumTime]
	     vmulsd   xmm1, xmm1, xmm2
		add   r8, sizeof.RootMove
		cmp   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		 je   .set_stop
	    vcomisd   xmm0, xmm1
		 ja   .set_stop
		mov   byte[rbp-Thread.rootPos+Thread.easyMovePlayed], r9l
	       test   r9d, r9d
		 jz   .handle_easymove
    .set_stop:
		 or   ecx, -1
		mov   al, byte[limits.ponder]
	       test   al, al
		jnz   @f
		mov   byte[signals.stop], cl
		jmp   .handle_easymove
	@@:	mov   byte[signals.stopOnPonderhit], cl


    .handle_easymove:
		mov   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   eax, dword[rcx+RootMove.pvSize]
		cmp   eax, 3
		 jb   @f
	       call   EasyMoveMng_Update
		jmp   .id_loop
	@@:    call   EasyMoveMng_Clear
		jmp   .id_loop


.id_loop_done:
		cmp   rbp, mainThread.rootPos
		jne   .done

.done:

     VerboseDisplay   <db 'Thread_Think returning',10>


		add   rsp, .localsize
		pop   r15 r14 r13 rdi rsi rbx rbp
		ret













MainThread_Think:
	; in: rcx address of Thread struct   should be mainThread

	       push   rbp rbx rsi rdi r15
		lea   rbp, [rcx+Thread.rootPos]
		mov   rbx, qword[rbp+Pos.state]

     VerboseDisplay   <db 'MainThread_Think',10>
		mov   ecx, dword[rbp+Pos.sideToMove]
		mov   edx, dword[rbp+Pos.gamePly]
	       call   TimeMng_Init

		mov   eax, dword[rbp+Pos.sideToMove]
		mov   ecx, VALUE_DRAW
		sub   ecx, dword[options.contempt]
		mov   dword[DrawValue+4*rax], ecx
		xor   eax, 1
		mov   ecx, VALUE_DRAW
		add   ecx, dword[options.contempt]
		mov   dword[DrawValue+4*rax], ecx
		add   byte[mainHash.date], 4

	; when weakness is not 0, set multipv and change maximumTime
		mov   ecx, dword[options.weakness]
	       test   ecx, ecx
		 jz   .no_weakness
		shr   ecx, 4
		add   ecx, 2
		mov   dword[options.multiPV], ecx
		lea   eax, [rcx-1]
		mul   dword[time.optimumTime]
		add   eax, dword[time.maximumTime]
		div   ecx
		mov   dword[time.maximumTime], eax
.no_weakness:

	; Skip TB probing when no TB found
		xor   eax, eax
		mov   dl, byte[options.syzygy50MoveRule]
		mov   qword[Tablebase_Hits], rax
		mov   byte[Tablebase_RootInTB], al
		mov   byte[Tablebase_UseRule50], dl
		mov   eax, dword[options.syzygyProbeLimit]
		mov   ecx, dword[options.syzygyProbeDepth]
		xor   edx, edx
		cmp   eax, dword[Tablebase_MaxCardinality]
	      cmovg   eax, dword[Tablebase_MaxCardinality]
	      cmovg   ecx, edx
		mov   dword[Tablebase_Cardinality], eax
		mov   dword[Tablebase_ProbeDepth], ecx

	; check for mate
		mov   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		cmp   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		 je   .mate

	; check tb
		mov   rcx, qword[rbp+Pos.typeBB+8*White]
		 or   rcx, qword[rbp+Pos.typeBB+8*Black]
	     popcnt   rcx, rcx, rdx
		sub   eax, ecx
		sar   eax, 31
		 or   al, byte[rbx+State.castlingRights]
		 jz   .check_tb
.check_tb_ret:

	; start workers
		lea   rsi, [rbp-Thread.rootPos]
    .next_worker:
		sub   rsi, sizeof.Thread
		cmp   rsi, qword[threadPool.stackPointer]
		 jb   .workers_done
		mov   rcx, rsi
	       call   Thread_StartSearching
		jmp   .next_worker
    .workers_done:

	; start searching
		lea   rcx, [rbp-Thread.rootPos]
	       call   Thread_Think

.search_done:

	; check for wait
		mov   al, byte[signals.stop]
	       test   al, al
		jnz   .dont_wait
		mov   al, byte[limits.ponder]
		 or   al, byte[limits.infinite]
		 jz   .dont_wait
		mov   byte[signals.stopOnPonderhit], al
		lea   rcx, [rbp-Thread.rootPos]
		lea   rdx, [signals.stop]
	       call   Thread_Wait
.dont_wait:
		 or   eax, -1
		mov   byte[signals.stop], al

	; wait for workers
		lea   rsi, [rbp-Thread.rootPos]
	.next_worker2:
		sub   rsi, sizeof.Thread
		cmp   rsi, qword[threadPool.stackPointer]
		 jb   .workers_done2
		mov   rcx, rsi
	       call   Thread_WaitForSearchFinished
		jmp   .next_worker2
	.workers_done2:


		mov   ecx, dword[options.weakness]
	       test   ecx, ecx
		jnz   .pick_weak_move

	; find best thread  rsi
		lea   rsi, [rbp-Thread.rootPos]
		mov   eax, dword[options.multiPV]
		sub   eax, 1
		 or   eax, dword[limits.depth]
		 or   al, byte[rbp-Thread.rootPos+Thread.easyMovePlayed]
		jne   .best_done
		mov   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.pv+4*0]
	       test   ecx, ecx
		 jz   .best_done
		mov   rdi, rsi
		mov   r8d, dword[rsi+Thread.completedDepth]
		mov   r9, qword[rsi+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   r9d, dword[r9+0*sizeof.RootMove+RootMove.score]
	.next_worker3:
		sub   rdi, sizeof.Thread
		cmp   rdi, qword[threadPool.stackPointer]
		 jb   .workers_done3
		mov   eax, dword[rdi+Thread.completedDepth]
		mov   rcx, qword[rdi+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.score]
		cmp   eax, r8d
		jle   .next_worker3
		cmp   ecx, r9d
		jle   .next_worker3
		mov   r8d, eax
		mov   r9d, ecx
		mov   rsi, rdi
		jmp   .next_worker3
	.workers_done3:
.best_done:
		mov   dword[rbp-Thread.rootPos+Thread.previousScore], r9d

.display_move:
		mov   rcx, rsi
	       call   qword[options.displayMoveFxn]

      VerboseDisplay  <db 'MainThread_Think returning',10>
		pop   r15 rdi rsi rbx rbp
		ret




.check_tb:
	       call   Tablebase_RootProbe
		mov   byte[Tablebase_RootInTB], al
		xor   edx, edx
	       test   eax, eax
		jnz   .root_in
	       call   Tablebase_RootProbeWDL
		mov   byte[Tablebase_RootInTB], al
		xor   edx, edx
		cmp   edx, dword[Tablebase_Score]
	      cmovg   edx, dword[Tablebase_Cardinality]
	.root_in:
		lea   rcx, [rbp+Pos.rootMovesVec]
		mov   dword[Tablebase_Cardinality], edx
	       call   RootMovesVec_Size
		mov   dword[Tablebase_Hits], eax
		mov   dl, byte[Tablebase_UseRule50]
		mov   eax, dword[Tablebase_Score]
	       test   dl, dl
		jnz   .check_tb_ret
		mov   ecx, VALUE_MATE - MAX_PLY - 1
		cmp   eax, 0
	      cmovg   eax, ecx
		neg   ecx
		cmp   eax, 0
	      cmovl   eax, ecx
		mov   dword[Tablebase_Score], eax
		jmp   .check_tb_ret

.pick_weak_move:
	       call   Weakness_PickMove
		lea   rsi, [mainThread]
		jmp   .display_move




.mate:
		lea   rdi, [Output]
		mov   rax, 'info dep'
	      stosq
		mov   rax, 'th 0 sco'
	      stosq
		mov   eax, 're '
	      stosd
		sub   rdi, 1
		mov   rax, qword[rbx+Thread.rootPos+Pos.state]
		cmp   qword[rax+State.checkersBB], 1
		sbb   ecx, ecx
		and   ecx, VALUE_DRAW+VALUE_MATE
		sub   ecx, VALUE_MATE
	       call   PrintScore_Uci
		mov   al, 10
	      stosb
		lea   rcx, [Output]
	       call   _WriteOut
		jmp   .search_done




DisplayMove_Uci:
	; in: rcx address of best thread
virtual at rsp
  .output rb 32
  .lend rb 0
end virtual
.lsize = ((.lend-rsp+15) and (-16))
	       push   rsi rdi r15
		sub   rsp, .lsize
		mov   rsi, rcx

	; print best move and ponder move
		lea   rdi, [.output]
		mov   rax, 'bestmove'
	      stosq
		mov   al, ' '
	      stosb
		mov   rcx, qword[rsi+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.pv+4*0]
	      movzx   edx, byte[rsi+Thread.rootPos+Pos.chess960]
		mov   dword[XBoardMove], ecx
	       call   PrintUciMove

		mov   rcx, qword[rsi+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   eax, dword[rcx+0*sizeof.RootMove+RootMove.pvSize]
		cmp   eax, 2
		 jb   .get_ponder_from_tt
.have_ponder_from_tt:
		mov   rax, ' ponder '
	      stosq
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.pv+4*1]
	      movzx   edx, byte[rsi+Thread.rootPos+Pos.chess960]
	       call   PrintUciMove
.skip_ponder:
		lea   rcx, [.output]
		mov   eax, 10
	      stosb
	       call   _WriteOut
.return:
		add   rsp, .lsize
		pop   r15 rdi rsi
		ret

.get_ponder_from_tt:
		lea   rcx, [rsi+Thread.rootPos]
	       call   ExtractPonderFromTT
		mov   rcx, qword[rsi+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
	       test   eax, eax
		jnz   .have_ponder_from_tt
		jmp   .skip_ponder


ExtractPonderFromTT:
	; in: rcx address of position
	       push   rbp rbx rsi rdi r15
virtual at rsp
 .movelist rb sizeof.ExtMove*MAX_MOVES
 .lend	   rb 0
end virtual
.localsize = .lend-rsp
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

		mov   r15, qword[rcx+Pos.rootMovesVec+RootMovesVec.table]

		mov   rbp, rcx
		mov   rbx, qword[rcx+Pos.state]
	       call   SetCheckInfo
		mov   ecx, dword[r15+RootMove.pv+4*0]
	       call   Move_GivesCheck
		mov   ecx, dword[r15+RootMove.pv+4*0]
		mov   edx, eax
		add   qword[rbp-Thread.rootPos+Thread.nodes], 1
	       call   Move_Do__ExtractPonderFromTT
		mov   rcx, qword[rbx+State.key]
	       call   MainHash_Probe
		mov   esi, ecx
		shr   esi, 16
		mov   edi, edx
		mov   ecx, dword[r15+RootMove.pv+4*0]
	       call   Move_Undo
		xor   eax, eax
	       test   edi, edi
		 jz   .done

		lea   rdi, [.movelist]
	       call   Gen_Legal
		lea   rdx, [.movelist]
	.loop:
		xor   eax, eax
		cmp   rdx, rdi
		jae   .done
		add   rdx, sizeof.ExtMove
		cmp   esi, dword[rdx+ExtMove.move]
		jne   .loop

		 or   eax, -1
		mov   ecx, 2
		mov   dword[r15+RootMove.pv+4*1], esi
		mov   dword[r15+RootMove.pvSize], ecx
.done:
		add   rsp, .localsize
		pop   r15 rdi rsi rbx rbp
		ret



DisplayMove_Xboard:
	; in: rcx address of best thread
virtual at rsp
  .output rb 32
  .localend rb 0
end virtual
.localsize = ((.localend-rsp+15) and (-16))
	       push   rsi rdi r15
		sub   rsp, .localsize
		mov   rsi, rcx
		lea   rdi, [.output]
		mov   eax, 'move'
	      stosd
		mov   al, ' '
	      stosb
		mov   rcx, qword[rsi+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.pv+4*0]
	      movzx   edx, byte[rsi+Thread.rootPos+Pos.chess960]
		mov   dword[XBoardMove], ecx
	       call   PrintUciMove
		lea   rcx, [.output]
		mov   eax, 10
	      stosb
	       call   _WriteOut
		add   rsp, .localsize
		pop   r15 rdi rsi
DisplayMove_None:
		ret




DisplayInfo_Uci:
	; in: rbp thread pos
	;     ecx depth
	;     edx alpha
	;     r8d beta
	;     r9 elapsed
	;     r10d multipv

	       push   rbx rsi rdi r12 r13 r14 r15
virtual at rsp
 .elapsed    rq 1
 .nodes      rq 1
 .nps	     rq 1
 .depth      rd 1
 .alpha      rd 1
 .beta	     rd 1
 .multiPV    rd 1
 .output     rb 8*MAX_PLY
 .lend rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize
		mov   dword[.depth], ecx
		mov   dword[.alpha], edx
		mov   dword[.beta], r8d
		mov   qword[.elapsed], r9
		mov   dword[.multiPV], r10d

	     Assert   ne, r10d, 0, 'assertion dword[.multiPV]!=0 in Position_WriteOutUciInfo failed'

	       call   ThreadPool_NodesSearched
		mov   qword[.nodes], rax
		mov   edx, 1000
		mul   rdx
		mov   rcx, qword[.elapsed]
		cmp   rcx, 1
		adc   rcx, 0
		div   rcx
		mov   qword[.nps], rax


		xor   r15d, r15d
.multipv_loop:
		xor   eax, eax
		cmp   r15d, dword[rbp-Thread.rootPos+Thread.PVIdx]
	      setbe   al

		mov   ecx, dword[.depth]
		sub   ecx, 1
		mov   edx, eax
		 or   edx, ecx
		 jz   .multipv_cont
		add   ecx, eax

		lea   rdi, [.output]

	       imul   esi, r15d, sizeof.RootMove
		add   rsi, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   r12d, dword[rsi+4*rax]

		mov   rax, 'info dep'
	      stosq
		mov   eax, 'th '
	      stosd
		sub   rdi, 1
		mov   eax, ecx
	       call   PrintUnsignedInteger

		mov   al, ' '
	      stosb
		mov   rax, 'multipv '
	      stosq
		lea   eax, [r15+1]
	       call   PrintUnsignedInteger

match =0, VERBOSE {
		mov   rax, ' time '
	      stosq
		sub   rdi, 2
		mov   rax, qword[.elapsed]
	       call   PrintUnsignedInteger

		mov   rax, ' nps '
	      stosq
		sub   rdi, 3
		mov   rax, qword[.nps]
	       call   PrintUnsignedInteger
}

	      movsx   r13d, byte[Tablebase_RootInTB]
		mov   eax, r12d
		cdq
		xor   eax, edx
		sub   eax, edx
		sub   eax, VALUE_MATE - MAX_PLY
		sar   eax, 31
		and   r13d, eax
	     cmovnz   r12d, dword[Tablebase_Score]

		mov   rax, ' score '
	      stosq
		sub   rdi, 1
		mov   ecx, r12d
	       call   PrintScore_Uci

		mov   ecx, 'und'
	       test   r13d, r13d
		jnz   .no_bound
		cmp   r15d, dword[rbp-Thread.rootPos+Thread.PVIdx]
		jne   .no_bound
		mov   rax, ' lowerbo'
		cmp   r12d, dword[.beta]
		jge   .yes_bound
		mov   rax, ' upperbo'
		cmp   r12d, dword[.alpha]
		 jg   .no_bound
	.yes_bound:
	      stosq
		mov   eax, ecx
	      stosd
		sub   rdi, 1
	.no_bound:

		mov   rax, ' nodes '
	      stosq
		sub   rdi, 1
		mov   rax, qword[.nodes]
	       call   PrintUnsignedInteger

		mov   rax, ' tbhits '
	      stosq
		mov   rax, qword[Tablebase_Hits]
	       call   PrintUnsignedInteger

		mov   eax, ' pv'
	      stosd
		sub   rdi, 1

		mov   r13d, dword[rsi+RootMove.pvSize]
		lea   r12, [rsi+RootMove.pv]
		lea   r13, [r12+4*r13]
	.next_move:
		mov   al, ' '
		cmp   r12, r13
		jae   .moves_done
	      stosb
		mov   ecx, dword[r12]
	      movzx   edx, byte[rbp+Pos.chess960]
	       call   PrintUciMove
		add   r12, 4
		jmp   .next_move
	.moves_done:

		mov   al, 10
	      stosb
		lea   rcx, [.output]
	       call   _WriteOut

.multipv_cont:
		add   r15d, 1
		cmp   r15d, dword[.multiPV]
		 jb   .multipv_loop


		add   rsp, .localsize
		pop   r15 r14 r13 r12 rdi rsi rbx


DisplayInfo_None:
		ret



DisplayInfo_Xboard:
	; in: rbp thread pos
	;     ecx depth
	;     edx alpha
	;     r8d beta
	;     r9 elapsed
	;     r10d multipv


;1 0 0 23 d7d5
;2 -35 0 116 d7d5 b1c3
;3 -5 0 1316 d7d5 f1b5 c8d7 b5d3
;4 -35 0 6461 e7e5 b1c3 b8c6 g1f3
;5 -13 3 41331 e7e5 d2d4 e5d4 d1d4 g8f6
;6 -30 30 346575 d7d5 e4d5 d8d5 b1c3 d5e6 g1e2 b8c6
;7 -18 248 2882251 e7e5 g1f3 g8f6 b1c3 b8c6 d2d4 d7d6
	       push   rbx rsi rdi r12 r13 r14 r15
virtual at rsp
 .elapsed    rq 1
 .nodes      rq 1
 .nps	     rq 1
 .depth      rd 1
 .alpha      rd 1
 .beta	     rd 1
 .multiPV    rd 1
 .output     rb 8*MAX_PLY
 .lend rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize
		mov   dword[.depth], ecx
		mov   dword[.alpha], edx
		mov   dword[.beta], r8d
		mov   qword[.elapsed], r9
		mov   dword[.multiPV], r10d

	     Assert   ne, r10d, 0, 'assertion dword[.multiPV]!=0 in Position_WriteOutUciInfo failed'

	       call   ThreadPool_NodesSearched
		mov   qword[.nodes], rax
		mov   edx, 1000
		mul   rdx
		mov   rcx, qword[.elapsed]
		cmp   rcx, 1
		adc   rcx, 0
		div   rcx
		mov   qword[.nps], rax

	; xboard wants time in centiseconds
		mov   rax, qword[.elapsed]
		xor   edx, edx
		lea   ecx, [rdx+10]
		div   rcx
		mov   qword[.elapsed], rax


		xor   r15d, r15d
.multipv_loop:
		xor   eax, eax
		cmp   r15d, dword[rbp-Thread.rootPos+Thread.PVIdx]
	      setbe   al

		mov   ecx, dword[.depth]
		sub   ecx, 1
		mov   edx, eax
		 or   edx, ecx
		 jz   .multipv_cont
		add   ecx, eax

		lea   rdi, [.output]

	       imul   esi, r15d, sizeof.RootMove
		add   rsi, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   r12d, dword[rsi+4*rax]

	; ply
		mov   eax, ecx
	       call   PrintUnsignedInteger

	; score
		mov   al, ' '
	      stosb
		mov   ecx, r12d
	       call   PrintScore_Xboard

	; time
		mov   al, ' '
	      stosb
		mov   rax, qword[.elapsed]
	       call   PrintUnsignedInteger

	; nodes
		mov   al, ' '
	      stosb
		mov   rax, qword[.nodes]
	       call   PrintUnsignedInteger

	; pv
		mov   r13d, dword[rsi+RootMove.pvSize]
		lea   r12, [rsi+RootMove.pv]
		lea   r13, [r12+4*r13]
	.next_move:
		mov   al, ' '
		cmp   r12, r13
		jae   .moves_done
	      stosb
		mov   ecx, dword[r12]
	      movzx   edx, byte[rbp+Pos.chess960]
	       call   PrintUciMove
		add   r12, 4
		jmp   .next_move
	.moves_done:

		mov   al, 10
	      stosb
		lea   rcx, [.output]
	       call   _WriteOut

.multipv_cont:
		add   r15d, 1
		cmp   r15d, dword[.multiPV]
		 jb   .multipv_loop


		add   rsp, .localsize
		pop   r15 r14 r13 r12 rdi rsi rbx
		ret















