ThreadIdxToNode:
; in: ecx index (n) of thread
; out: rax address of numa noda

; first do n =  n % threadPool.coreCnt
; then match n to a node using the number of cores in a node as the 'bin width'
;
; this is of course just a first attempt at node allocation and could change in the future
;
; for example if there are two nodes each with 4 cores,
;  the threads are assigned as
;  idx | node
; -----------
;   0  |  0
;   1  |  0
;   2  |  0
;   3  |  0
;   4  |  1
;   5  |  1
;   6  |  1
;   7  |  1
;   8  |  0
;   9  |  0
;  10  |  0
;  11  |  0
;  12  |  1
; ...
;
; this ensures that we take advantage of HT
;  AFTER all cores in every node have been filled with one thread

		mov   eax, ecx
		xor   edx, edx
		div   dword[threadPool.coreCnt]
		lea   rax, [threadPool.nodeTable]
	       imul   ecx, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   rcx, rax
.NextNode:	sub   edx, dword[rax+NumaNode.coreCnt]
		 js   .Return
		add   rax, sizeof.NumaNode
		cmp   rax, rcx
		 jb   .NextNode
	     Assert   e, rsp, 0, 'ThreadIdxToNode failed: unreachable code reached'
.Return:
		ret


Thread_Create:
; in: ecx index of thread

	       push   rbx rsi rdi
		sub   rsp, 8*8
		mov   esi, ecx

	; get the right node to put this thread
	       call   ThreadIdxToNode
		mov   rdi, rax

	; allocate self
		mov   ecx, sizeof.Thread
		mov   edx, dword[rdi+NumaNode.NodeNumber]
	       call   _VirtualAllocNuma
		mov   qword[threadPool.threadTable+8*rsi], rax
		mov   rbx, rax

	; init some thread data
		xor   eax, eax
		mov   byte[rbx+Thread.exit], al
		mov   byte[rbx+Thread.resetCalls], al
		mov   dword[rbx+Thread.callsCnt], eax
		mov   dword[rbx+Thread.idx], esi
		mov   qword[rbx+Thread.numaNode], rdi

	; create sync objects
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexCreate
	       call   _EventCreate
		mov   qword[rbx+Thread.sleepCond], rax
	       call   _EventCreate
		mov   qword[rbx+Thread.sleepCond2], rax

	; the states will be allocated when copying position to thread
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.state], rax
		mov   qword[rbx+Thread.rootPos+Pos.stateTable], rax
		mov   qword[rbx+Thread.rootPos+Pos.stateEnd], rax

	; create the vector of root moves
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
	       call   RootMovesVec_Create

	; allocate history and counterMoves
		mov   ecx, 4*16*64*2
		mov   edx, dword[rdi+NumaNode.NodeNumber]
	       call   _VirtualAllocNuma
		lea   rdx, [rax+4*16*64]
		mov   qword[rbx+Thread.rootPos+Pos.history], rax
		mov   qword[rbx+Thread.rootPos+Pos.counterMoves], rdx

	; allocate pawn hash
		mov   ecx, PAWN_HASH_ENTRY_COUNT*sizeof.PawnEntry
		mov   edx, dword[rdi+NumaNode.NodeNumber]
	       call   _VirtualAllocNuma
		mov   qword[rbx+Thread.rootPos+Pos.pawnTable], rax

	; allocate material hash
		mov   ecx, MATERIAL_HASH_ENTRY_COUNT*sizeof.MaterialEntry
		mov   edx, dword[rdi+NumaNode.NodeNumber]
	       call   _VirtualAllocNuma
		mov   qword[rbx+Thread.rootPos+Pos.materialTable], rax

	; use chm table from node
		mov   rax, qword[rdi+NumaNode.cmhTable]
		mov   qword[rbx+Thread.rootPos.counterMoveHistory], rax

	; start the thread and wait for it to enter the idle loop
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte[rbx+Thread.searching], -1
		lea   rcx, [Thread_IdleLoop]
		mov   rdx, rbx
		mov   r8, rdi
		add   r8, NumaNode.GroupMask
	       call   _ThreadCreate
		mov   qword[rbx+Thread.handle], rax
		jmp   .check
    .wait:	mov   rcx, qword[rbx+Thread.sleepCond2]
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
    .check:	mov   al, byte[rbx+Thread.searching]
	       test   al, al
		jnz   .wait
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock

		add   rsp, 8*8
		pop   rdi rsi rbx
		ret


Thread_Delete:
	; ecx: index of thread

	       push   rsi rdi rbx
		mov   esi, ecx
		mov   rbx, qword[threadPool.threadTable+8*rcx]

		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte [rbx+Thread.exit], -1
		mov   rcx, qword[rbx+Thread.sleepCond]
	       call   _EventSignal
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
		mov   rcx, qword[rbx+Thread.handle]
	       call   _ThreadJoin

	; free material hash
		mov   rcx, qword[rbx+Thread.rootPos+Pos.materialTable]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.materialTable], rax

	; free pawn hash
		mov   rcx, qword[rbx+Thread.rootPos+Pos.pawnTable]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.pawnTable], rax

	; free history and counterMoves
		mov   rcx, qword[rbx+Thread.rootPos+Pos.history]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.history], rax
		mov   qword[rbx+Thread.rootPos+Pos.counterMoves], rax

	; destroy the vector of root moves
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
	       call   RootMovesVec_Destroy

	; destroy the state table
		mov   rcx, qword[rbx+Thread.rootPos+Pos.stateTable]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.state], rax
		mov   qword[rbx+Thread.rootPos+Pos.stateTable], rax
		mov   qword[rbx+Thread.rootPos+Pos.stateEnd], rax

	; destroy sync objects
		mov   rcx, qword[rbx+Thread.sleepCond2]
	       call   _EventDestroy
		mov   rcx, qword[rbx+Thread.sleepCond]
	       call   _EventDestroy
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexDestroy

	; free self
		mov   rcx, qword[threadPool.threadTable+8*rsi]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[threadPool.threadTable+8*rsi], rax


		pop   rbx rdi rsi
		ret


Thread_IdleLoop:
	; rcx: address of Thread struct
	       push   rbp
if DEBUG > 0
mov qword[rcx+Thread.stackBase], rsp
mov qword[rcx+Thread.stackRecord], 0
end if
		mov   rbx, rcx
		lea   rbp, [Thread_Think]
		lea   rdx, [MainThread_Think]
		mov   eax, dword[rbx+Thread.idx]
	       test   eax, eax
	      cmove   rbp, rdx
		mov   rsi, qword[rbx+Thread.sleepCond]
		mov   rdi, qword[rbx+Thread.sleepCond2]
GD_String <db 'Thread_IdleLoop enter',10>
		mov   al, byte[rbx+Thread.exit]
	       test   al, al
		jnz   .exit
		jmp   .lock
.loop:
		mov   rcx, rbx
	       call   rbp
.lock:
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte[rbx+Thread.searching], 0
	.check_exit:
		mov   al, byte[rbx+Thread.exit]
	       test   al, al
		jnz   .unlock
		mov   rcx, rdi
	       call   _EventSignal
		mov   rcx, rsi
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
		mov   al, byte[rbx+Thread.searching]
	       test   al, al
		 jz   .check_exit
	.unlock:
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
.check_out:
		mov   al, byte[rbx+Thread.exit]
	       test   al, al
		 jz   .loop
.exit:
GD_String <db 'Thread_IdleLoop exit',10>
		xor   ecx, ecx
	       call   _ExitThread




Thread_StartSearching:
	; rcx: address of Thread struct
	       push   rbx
		mov   rbx, rcx
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte[rbx+Thread.searching], -1
.signal:
		mov   rcx, qword[rbx+Thread.sleepCond]
	       call   _EventSignal
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
		pop   rbx
		ret

Thread_StartSearching_TRUE:
	; rcx: address of Thread struct
	       push   rbx
		mov   rbx, rcx
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		jmp   Thread_StartSearching.signal


Thread_WaitForSearchFinished:
	; rcx: address of Thread struct
	       push   rsi rdi rbx
		mov   rbx, rcx
		mov   rsi, qword[rbx+Thread.sleepCond2]
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		jmp   .check
.wait:
		mov   rcx, rsi
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
.check:
		mov   al, byte[rbx+Thread.searching]
	       test   al, al
		jnz   .wait

		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
		pop   rbx rdi rsi
		ret



Thread_Wait:
	; rcx: address of Thread struct
	; rdx: address of bool
	       push   rsi rdi rbx
		mov   rbx, rcx
		mov   rdi, rdx
		mov   rsi, qword[rbx+Thread.sleepCond]
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		jmp   .check
.wait:
		mov   rcx, rsi
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
.check:
		mov   al, byte[rdi]
	       test   al, al
		 jz   .wait

		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
		pop   rbx rdi rsi
		ret