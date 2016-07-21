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
		lea   rcx, [rbx+Thread.sleep1]
	       call   _EventCreate
		lea   rcx, [rbx+Thread.sleep2]
	       call   _EventCreate

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
		lea   r8, [rdi+NumaNode.GroupMask]
		lea   r9, [rbx+Thread.threadHandle]
	       call   _ThreadCreate
GD_String db '_ThreadCreate done'
GD_NewLine

		jmp   .check
    .wait:
GD_String db 'calling _EventWait2 '
GD_Hex rbx
GD_NewLine
		lea   rcx, [rbx+Thread.sleep2]
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
GD_String db '_EventWait done'
GD_NewLine
    .check:	mov   al, byte[rbx+Thread.searching]
	       test   al, al
		jnz   .wait
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock

GD_String db '_MutexUnlock done'
GD_NewLine


.done:
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
		mov   byte[rbx+Thread.exit], -1
		lea   rcx, [rbx+Thread.sleep1]
	       call   _EventSignal
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
		lea   rcx, [rbx+Thread.threadHandle]
	       call   _ThreadJoin

	; free material hash
		mov   rcx, qword[rbx+Thread.rootPos+Pos.materialTable]
		mov   edx, MATERIAL_HASH_ENTRY_COUNT*sizeof.MaterialEntry
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.materialTable], rax

	; free pawn hash
		mov   rcx, qword[rbx+Thread.rootPos+Pos.pawnTable]
		mov   edx, PAWN_HASH_ENTRY_COUNT*sizeof.PawnEntry
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.pawnTable], rax

	; free history and counterMoves
		mov   rcx, qword[rbx+Thread.rootPos+Pos.history]
		mov   edx, 4*16*64*2
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.history], rax
		mov   qword[rbx+Thread.rootPos+Pos.counterMoves], rax

	; destroy the vector of root moves
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
	       call   RootMovesVec_Destroy

	; destroy the state table
		mov   rcx, qword[rbx+Thread.rootPos+Pos.stateTable]
		mov   rdx, qword[rbx+Thread.rootPos+Pos.stateEnd]
		sub   rdx, rcx
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rbx+Thread.rootPos+Pos.state], rax
		mov   qword[rbx+Thread.rootPos+Pos.stateTable], rax
		mov   qword[rbx+Thread.rootPos+Pos.stateEnd], rax

	; destroy sync objects
		lea   rcx, [rbx+Thread.sleep2]
	       call   _EventDestroy
		lea   rcx, [rbx+Thread.sleep1]
	       call   _EventDestroy
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexDestroy

	; free self
		mov   rcx, qword[threadPool.threadTable+8*rsi]
		mov   edx, sizeof.Thread
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[threadPool.threadTable+8*rsi], rax

		pop   rbx rdi rsi
		ret


Thread_IdleLoop:
	; in: rcx address of Thread struct
	       push   rbx rsi rdi
if DEBUG > 0
mov qword[rcx+Thread.stackBase], rsp
mov qword[rcx+Thread.stackRecord], 0
end if

GD_String db '...Thread_IdleLoop enter'
GD_NewLine

		mov   rbx, rcx
		lea   rdi, [Thread_Think]
		lea   rdx, [MainThread_Think]
		mov   eax, dword[rbx+Thread.idx]
	       test   eax, eax
	      cmovz   rdi, rdx

GD_String db '... rbx:'
GD_Hex rbx
GD_NewLine

		jmp   .lock
.loop:
		mov   rcx, rbx
	       call   rdi
.lock:
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte[rbx+Thread.searching], 0
GD_String db '..._MutexLock returned'
GD_NewLine

    .check_exit:
		mov   al, byte[rbx+Thread.exit]
	       test   al, al
		jnz   .unlock
GD_String db '...calling _EventSignal2 '
GD_Hex rbx
GD_NewLine
		lea   rcx, [rbx+Thread.sleep2]
	       call   _EventSignal
		lea   rcx, [rbx+Thread.sleep1]
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
GD_String db '..._EventWait returned'
GD_NewLine
		mov   al, byte[rbx+Thread.searching]
	       test   al, al
		 jz   .check_exit
    .unlock:
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock

GD_String db '..._MutexUnlock returned'
GD_NewLine

.check_out:
		mov   al, byte[rbx+Thread.exit]
	       test   al, al
		 jz   .loop
.exit:

GD_String db '...Thread_IdleLoop exit'
GD_NewLine

if OS_IS_WINDOWS
		xor   ecx, ecx
	       call   _ExitThread
else
		pop   rdi rsi rbx
		ret
end if



Thread_StartSearching:
	; rcx: address of Thread struct
	       push   rbx
		mov   rbx, rcx
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte[rbx+Thread.searching], -1
.signal:	lea   rcx, [rbx+Thread.sleep1]
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
		cmp   al, byte[rbx]
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		jmp   .check
.wait:		lea   rcx, [rbx+Thread.sleep2]
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
.check: 	mov   al, byte[rbx+Thread.searching]
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
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		jmp   .check
.wait:		lea   rcx, [rbx+Thread.sleep1]
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
.check: 	mov   al, byte[rdi]
	       test   al, al
		 jz   .wait
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock
		pop   rbx rdi rsi
		ret