
ThreadPool_Create:
	       push   rdi rsi rbx
		lea   rbx, [threadPool]
		lea   rcx, [mainThread]
		mov   qword[rbx+ThreadPool.stackPointer], rcx
	       call   Thread_Create
		mov   rcx, rbx
	       call   ThreadPool_ReadOptions
		pop   rbx rsi rdi
		ret


ThreadPool_Destroy:
	       push   rsi rdi rbx
		lea   rbx, [threadPool]
		mov   rdi, qword[rbx+ThreadPool.stackPointer]
		lea   rsi, [mainThread]
.delete:	mov   rcx, rdi
		add   rdi, sizeof.Thread
	       call   Thread_Delete
		cmp   rdi, rsi
		jbe   .delete
		pop   rbx rdi rsi
		ret


ThreadPool_ReadOptions:
	       push   rbx rsi rdi
		lea   rbx, [threadPool]
		mov   rdi, qword[rbx+ThreadPool.stackPointer]
		mov   esi, dword[options.threads]
		sub   esi, 1
	       imul   esi, sizeof.Thread
		neg   rsi
		lea   rsi, [rsi+mainThread]
.CheckCreate:
		cmp   rdi, rsi
		 ja   .Create
.CheckDelete:
		cmp   rdi, rsi
		 jb   .Delete
		mov   qword[rbx+ThreadPool.stackPointer], rdi
		pop   rdi rsi rbx
		ret
.Create:
		sub   rdi, sizeof.Thread
		mov   rcx, rdi
	       call   Thread_Create
		jmp   .CheckCreate
.Delete:
		mov   rcx, rdi
		add   rdi, sizeof.Thread
	       call   Thread_Delete
		jmp   .CheckDelete


ThreadPool_NodesSearched:
		lea   rcx, [mainThread]
		xor   eax, eax
	.next_thread:
		add   rax, qword[rcx+Thread.nodes]
		sub   rcx, sizeof.Thread
		cmp   rcx, qword[threadPool.stackPointer]
		jae   .next_thread
		ret



ThreadPool_StartThinking:
	; in: rbp address of position
	;     rcx address of limits struct
	;            this will be copied to the global limits struct
	;            so that search threads can see it
	       push   rbp rbx rsi rdi r15
virtual at rsp
  .moveList rb sizeof.ExtMove*MAX_MOVES
  .lend rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))

	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize
		mov   rsi, rcx
		mov   r15, rbp

		lea   rcx, [mainThread]
	       call   Thread_WaitForSearchFinished
	     Assert   e, byte[mainThread.searching], 0, 'assertion byte[mainThread.searching]==0 failed in ThreadPool_StartThinking'

		xor   eax, eax
		mov   byte[signals.stop], al
		mov   byte[signals.stopOnPonderhit], al
		lea   rcx, [limits]
		mov   rdx, rsi
	       call   Limits_Copy

	; copy to mainThread
		mov   rbx, qword[rbp+Pos.state]
	       call   SetCheckInfo
		lea   rdi, [.moveList]
	       call   Gen_Legal

		lea   rbx, [mainThread]
		lea   rcx, [rbx+Thread.rootPos]
	       call   Position_CopyToSearch
		xor   eax, eax
		mov   dword[rbx+Thread.rootDepth], eax
		mov   qword[rbx+Thread.nodes], rax

		lea   rsi, [.moveList]
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
	       call   RootMovesVec_Clear
    .push_moves:
		cmp   rsi, rdi
		jae   .push_moves_done
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
		mov   edx, dword[rsi+ExtMove.move]
		add   rsi, sizeof.ExtMove
	       call   RootMovesVec_PushBackMove
		jmp   .push_moves
    .push_moves_done:

	; the main thread should get the position for tb move filtering
		lea   rbp, [rbx+Thread.rootPos]
		mov   rbx, qword[rbp+Pos.state]
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
	; filter moves
		mov   rcx, qword[rbp+Pos.typeBB+8*White]
		 or   rcx, qword[rbp+Pos.typeBB+8*Black]
	     popcnt   rcx, rcx, rdx
		sub   eax, ecx
		sar   eax, 31
		 or   al, byte[rbx+State.castlingRights]
		 jz   .check_tb
.check_tb_ret:

	; copy original position to workers
		mov   rbp, r15
		lea   rbx, [mainThread]
.next_thread:
		sub   rbx, sizeof.Thread
		cmp   rbx, qword[threadPool.stackPointer]
		 jb   .thread_copy_done

		lea   rcx, [rbx+Thread.rootPos]
	       call   Position_CopyToSearch
		xor   eax, eax
		mov   dword[rbx+Thread.rootDepth], eax
		mov   qword[rbx+Thread.nodes], rax

	; copy the filtered moves of main thread to worker thread
		mov   rdi, qword[rbx+Thread.rootPos.rootMovesVec.table]
		mov   rsi, qword[mainThread.rootPos.rootMovesVec.table]
.copy_moves_loop:
		cmp   rsi, qword[mainThread.rootPos.rootMovesVec.ender]
		jae   .copy_moves_done
	    vmovups   xmm0, dqword[rsi+0]    ; this should be sufficient to copy
	    vmovups   xmm1, dqword[rsi+16]   ; up to and including first move of pv
	    vmovups   dqword[rdi+0], xmm0    ;
	    vmovups   dqword[rdi+16], xmm1   ;
		add   rdi, sizeof.RootMove
		add   rsi, sizeof.RootMove
		jmp   .copy_moves_loop
.copy_moves_done:
		mov   qword[rbx+Thread.rootPos.rootMovesVec.ender], rdi

		jmp   .next_thread
.thread_copy_done:

		lea   rcx, [mainThread]
	       call   Thread_StartSearching

		add   rsp, .localsize
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

