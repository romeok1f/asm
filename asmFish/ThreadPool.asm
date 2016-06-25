
ThreadPool_Create:
	       push   rdi rsi rbx
		mov   dword[threadPool.size], 0
		mov   ecx, sizeof.Thread
	       call   _VirtualAlloc
		mov   qword[threadPool.table+8*0], rax
		mov   rcx, rax
	       call   Thread_Create
		mov   dword[threadPool.size], 1
		mov   rcx, rbx
	       call   ThreadPool_ReadOptions
		pop   rbx rsi rdi
		ret


ThreadPool_Destroy:
	       push   rsi rdi rbx
		mov   edi, dword[threadPool.size]
		sub   edi, 1
.delete:
		mov   rcx, qword[threadPool.table+8*rdi]
	       call   Thread_Delete
		mov   rcx, qword[threadPool.table+8*rdi]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[threadPool.table+8*rdi], rax
		sub   edi, 1
		jns   .delete

		mov   dword[threadPool.size], 0
		pop   rbx rdi rsi
		ret


ThreadPool_ReadOptions:
	       push   rbx rsi rdi
		mov   esi, dword[options.threads]
		mov   edi, dword[threadPool.size]
.CheckCreate:
		cmp   rdi, rsi
		 jb   .Create
.CheckDelete:
		cmp   rdi, rsi
		 ja   .Delete
		pop   rdi rsi rbx
		ret
.Create:
		mov   ecx, sizeof.Thread
	       call   _VirtualAlloc
		mov   qword[threadPool.table+8*rdi], rax
		mov   rcx, rax
	       call   Thread_Create
		add   edi, 1
		mov   dword[threadPool.size], edi
		jmp   .CheckCreate
.Delete:
		sub   edi, 1
		mov   rcx, qword[threadPool.table+8*rdi]
	       call   Thread_Delete
		mov   rcx, qword[threadPool.table+8*rdi]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[threadPool.table+8*rdi], rax
		mov   dword[threadPool.size], edi
		jmp   .CheckDelete


ThreadPool_NodesSearched:
		xor   ecx, ecx
		xor   eax, eax
	.next_thread:
		mov   rdx, qword[threadPool.table+8*rcx]
		add   rax, qword[rdx+Thread.nodes]
		add   ecx, 1
		cmp   ecx, dword[threadPool.size]
		 jb   .next_thread
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

		mov   rcx, qword[threadPool.table+8*0]
	       call   Thread_WaitForSearchFinished
;             Assert   e, byte[mainThread.searching], 0, 'assertion byte[mainThread.searching]==0 failed in ThreadPool_StartThinking'

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

		mov   rbx, qword[threadPool.table+8*0]
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
		 or   al, byte[rbx+State._castlingRights]
		 jz   .check_tb
.check_tb_ret:

	; filtering moves may have incremented nodes count
		mov   qword[rbx+Thread.nodes], rax


	; copy original position to workers
		xor   eax, eax
		mov   rbp, r15
		mov   rsi, qword[threadPool.table+8*0]
		mov   qword[rsi+Thread.nodes], rax  ;filtering moves may have incremented mainThread.nodes
		xor   edi, edi
.next_thread:
		add   edi,1
		cmp   edi, dword[threadPool.size]
		jae   .thread_copy_done
		mov   rbx, qword[threadPool.table+8*rdi]

		lea   rcx, [rbx+Thread.rootPos]
	       call   Position_CopyToSearch
		xor   eax, eax
		mov   dword[rbx+Thread.rootDepth], eax
		mov   qword[rbx+Thread.nodes], rax

	; copy the filtered moves of main thread to worker thread
		mov   rax, qword[rbx+Thread.rootPos.rootMovesVec.table]
		mov   rdx, qword[rsi+Thread.rootPos.rootMovesVec.table]
.copy_moves_loop:
		cmp   rdx, qword[rsi+Thread.rootPos.rootMovesVec.ender]
		jae   .copy_moves_done
	    vmovups   xmm0, dqword[rdx+0]    ; this should be sufficient to copy
	    vmovups   xmm1, dqword[rdx+16]   ; up to and including first move of pv
	    vmovups   dqword[rax+0], xmm0    ;
	    vmovups   dqword[rax+16], xmm1   ;
		add   rax, sizeof.RootMove
		add   rdx, sizeof.RootMove
		jmp   .copy_moves_loop
.copy_moves_done:
		mov   qword[rbx+Thread.rootPos.rootMovesVec.ender], rax

		jmp   .next_thread
.thread_copy_done:

		mov   rcx, qword[threadPool.table+8*0]
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

