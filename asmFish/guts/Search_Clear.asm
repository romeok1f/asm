; Search::clear() resets search state to zero, to obtain reproducible results
Search_Clear:
	       push   rbx rsi rdi

	       call   MainHash_Clear
		mov   byte[mainHash.date],0

		lea   rbx, [threadPool.nodeTable]
	       imul   esi, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   rsi, rax
.NextNumaNode:
		mov   rdi, qword[rbx+NumaNode.cmhTable]
		mov   ecx, (sizeof.CounterMoveHistoryStats)/4
		xor   eax, eax
	  rep stosd
		add   rbx, sizeof.NumaNode
		cmp   rbx, rsi
		 jb   .NextNumaNode


		xor   esi, esi
.nexthread:
		mov   rbx, qword[threadPool.threadTable+8*rsi]

		mov   rdi, qword[rbx+Thread.rootPos+Pos.fromTo]
		mov   ecx, (sizeof.FromToStats + sizeof.HistoryStats + sizeof.MoveStats)/4
		xor   eax, eax
	  rep stosd

	; mainThread.previousScore is used in the time management part of idloop
	;  +VALUE_INFINITE causes us to think alot on the first move
		mov   dword[rbx+Thread.previousScore], VALUE_INFINITE

		add   esi, 1
		cmp   esi, dword[threadPool.size]
		 jb   .nexthread

		pop   rdi rsi rbx
		ret