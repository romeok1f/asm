
Thread_Create:
	; rcx: address of Thread struct
	       push   rbx rsi rdi
		mov   rbx, rcx

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
	       call   _VirtualAlloc
		lea   rdx, [rax+4*16*64]
		mov   qword[rbx+Thread.rootPos+Pos.history], rax
		mov   qword[rbx+Thread.rootPos+Pos.counterMoves], rdx

	; allocate pawn hash
		mov   ecx, PAWN_HASH_ENTRY_COUNT*sizeof.PawnEntry
	       call   _VirtualAlloc
		mov   qword[rbx+Thread.rootPos+Pos.pawnTable], rax

	; allocate material hash
		mov   ecx, MATERIAL_HASH_ENTRY_COUNT*sizeof.MaterialEntry
	       call   _VirtualAlloc
		mov   qword[rbx+Thread.rootPos+Pos.materialTable], rax

	; init some thread data
		xor   eax, eax
		mov   byte[rbx+Thread.exit], al
		mov   byte[rbx+Thread.resetCalls], al
		mov   dword[rbx+Thread.callsCnt], eax
		lea   rax, [mainThread]
		sub   rax, rbx
		xor   edx, edx
		mov   ecx, sizeof.Thread
		div   ecx
		mov   dword[rbx+Thread.idx], eax
	     Assert   e, edx, 0, 'bad div in Thread_Create'

	; start the thread and wait for it to enter the idle loop
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexLock
		mov   byte[rbx+Thread.searching], -1
		lea   rcx, [Thread_IdleLoop]
		mov   rdx, rbx
	       call   _ThreadCreate
		jmp   .check
    .wait:	mov   rcx, qword[rbx+Thread.sleepCond2]
		lea   rdx, [rbx+Thread.mutex]
	       call   _EventWait
    .check:	mov   al, byte[rbx+Thread.searching]
	       test   al, al
		jnz   .wait
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexUnlock

		pop   rdi rsi rbx
		ret


Thread_Delete:
	; rcx: address of Thread struct
	       push   rsi rdi rbx
		mov   rbx, rcx

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

		mov   rcx, qword[rbx+Thread.sleepCond2]
	       call   _EventDestroy
		mov   rcx, qword[rbx+Thread.sleepCond]
	       call   _EventDestroy
		lea   rcx, [rbx+Thread.mutex]
	       call   _MutexDestroy

		pop   rbx rdi rsi
		ret


Thread_IdleLoop:
	; rcx: address of Thread struct
	       push   rbp
		mov   rbx, rcx
		lea   rbp, [Thread_Think]
		lea   rdx, [MainThread_Think]
		lea   rax, [mainThread]
		cmp   rcx, rax
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