; Search::clear() resets search state to zero, to obtain reproducible results
Search_Clear:
	       push   rbx rsi rdi

	       call   MainHash_Clear
		mov   byte[mainHash.date],0

		lea   rdi, [CounterMoveHistory]
		mov   ecx, 16*64*16*64
		xor   eax, eax
	  rep stosd

		mov   edx, VALUE_INFINITE
		xor   esi, esi
.nexthread:
		mov   rbx, qword[threadPool.table+8*rsi]

		mov   rdi, qword[rbx+Thread.rootPos+Pos.history]
		mov   ecx, 4*16*64
		xor   eax, eax
	  rep stosb

		mov   rdi, qword[rbx+Thread.rootPos+Pos.counterMoves]
		mov   ecx, 4*16*64
		xor   eax, eax
	  rep stosb

	; mainThread.previousScore is used in the time management part of idloop
	;  +VALUE_INFINITE causes us to think alot on the first move
		mov   dword[rbx+Thread.previousScore], edx

		add   esi, 1
		cmp   esi, dword[threadPool.size]
		 jb   .nexthread

		pop   rdi rsi rbx
		ret