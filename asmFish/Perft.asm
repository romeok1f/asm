

Perft_Root:
	       push   rbx rsi rdi r14 r15
virtual at rsp
 .time	   dq ?
 .movelist rb sizeof.ExtMove*MAX_MOVES
 .lend	   db ?
end virtual
.localsize = .lend-rsp
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

		mov   rbx, qword[rbp+Pos.state]
		mov   r15d, ecx
		xor   r14, r14

	       call   _GetTime
		mov   qword[.time], rax

	       call   SetCheckInfo

		lea   rdi, [.movelist]
		mov   rsi, rdi
	       call   Gen_Legal
		xor   eax, eax
		mov   dword[rdi], eax
.MoveLoop:
		mov   ecx, dword[rsi]
	       test   ecx, ecx
		 jz   .MoveLoopDone
		mov   ecx, dword[rsi]
	       call   Move_GivesCheck
		mov   ecx, dword[rsi]
	       call   Move_Do__PerftGen_Root
		mov   eax, 1
		lea   ecx, [r15-1]
		cmp   r15d, 1
		jbe   @f
	       call   Perft_Branch
	@@:	add   r14, rax
	       push   rax
		mov   ecx, dword[rsi]
	       call   Move_Undo

		lea   rdi, [Output]
		mov   ecx, dword[rsi]
		mov   edx, dword[rbp+Pos.chess960]
	       call   PrintUciMove
		mov   eax, ' :  '
	      stosd
		pop   rax
	       call   PrintUnsignedInteger
		mov   al, 10
	      stosb
	       call   _WriteOut_Output

		add   rsi, sizeof.ExtMove
		jmp   .MoveLoop

.MoveLoopDone:
	       call   _GetTime
		sub   rax, qword[.time]
		cmp   rax, 1
		adc   rax, 0
		mov   qword[.time], rax

		lea   rdi, [Output]
		mov   rax, 'total: '
	      stosq
		sub   rdi, 1
		mov   rax, r14
	       call   PrintUnsignedInteger
		mov   eax,'  ( '
	      stosd
		mov   rax, qword[.time]
	       call   PrintUnsignedInteger
		mov   rax,' ms  '
	      stosq
		sub   rdi, 3
		mov   eax, 1000
		mul   r14
		div   qword[.time]
	       call   PrintUnsignedInteger
		mov   rax,' nps ) ' + (10 shl 56)
	      stosq
	       call   _WriteOut_Output
.Done:
		add   rsp, .localsize
		pop   r15 r14 rdi rsi rbx
		ret




	      align  16
Perft_Branch:
	       push   rsi r14 r15
virtual at rsp
.movelist  rb sizeof.ExtMove*MAX_MOVES
.lend	   rb 0
end virtual
.localsize = .lend-rsp
		sub   rsp, .localsize

		lea   r15d, [rcx-1]
		xor   r14, r14
		lea   rdi, [.movelist]
		mov   rsi, rdi
		cmp   ecx, 1
		 ja   .DepthN
.Depth1:
	       call   SetPinned
	       call   Gen_Legal
		mov   rax, rdi
		sub   rax, rsi
		shr   rax, 3	      ; assume sizeof.ExtMove = 8
		add   rsp, .localsize
		pop   r15 r14 rsi
		ret


	      align   8
.DepthN:
	       call   SetCheckInfo
	       call   Gen_Legal
		xor   eax, eax
		mov   dword[rdi], eax

		mov   ecx, dword[rsi]
	       test   ecx, ecx
		 jz   .DepthNDone
.DepthNLoop:
	       call   Move_GivesCheck
		mov   edx, eax
		mov   ecx, dword[rsi]
	       call   Move_Do__PerftGen_Branch
		mov   ecx, r15d
	       call   Perft_Branch
		add   r14, rax
		mov   ecx, dword[rsi]
		add   rsi, sizeof.ExtMove
	       call   Move_Undo
		mov   ecx, dword[rsi]
	       test   ecx, ecx
		jnz   .DepthNLoop
.DepthNDone:
		mov   rax, r14
		add   rsp, .localsize
		pop   r15 r14 rsi
		ret








