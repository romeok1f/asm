

XboardLoop:
	       push   rbp rsi rdi r12 r13 r14 r15
virtual at rsp
  .th1 Thread
  .th2 Thread
  .states rb 2*sizeof.State
  .limits Limits
  .comp_side rd 1
  .localend   rb 0
end virtual
.localsize = ((.localend-rsp+15) and (-16))
		sub   rsp, XboardLoop.localsize
		mov   rbx, rcx

		lea   rcx, [DisplayInfo_Xboard]
		lea   rdx, [DisplayMove_Xboard]
		mov   qword[options.displayInfoFxn], rcx
		mov   qword[options.displayMoveFxn], rdx

		lea   rcx, [XboardLoop.states]
		lea   rdx, [rcx+2*sizeof.State]
		mov   qword[XboardLoop.th2.rootPos.state], rcx
		mov   qword[XboardLoop.th2.rootPos.stateTable], rcx
		mov   qword[XboardLoop.th2.rootPos.stateEnd], rdx

		xor   eax, eax
		lea   rbp, [XboardLoop.th1.rootPos]
		mov   qword[XboardLoop.th1.rootPos.state], rax
		mov   qword[XboardLoop.th1.rootPos.stateTable], rax
		mov   qword[XboardLoop.th1.rootPos.stateEnd], rax
		lea   rsi, [szStartFEN]
		xor   ecx, ecx			; chess950 = false
	       call   Position_ParseFEN

		jmp   .Observing

.Quit:
		lea   rcx, [mainThread]
		mov   byte[signals.stop], -1
	       call   Thread_StartSearching_TRUE
		lea   rcx, [mainThread]
	       call   Thread_WaitForSearchFinished
		mov   rcx, qword[XboardLoop.th1.rootPos.stateTable]
	       call   _VirtualFree
		mov   eax, r15d
		add   rsp, XboardLoop.localsize
		pop   r15 r14 r13 r12 rdi rsi rbp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.Observing:
	       call   _ReadIn
		cmp   byte[rsi], ' '
		 jb   .Observing
	    stdcall   CmpString, 'time'
	       test   eax, eax
		jnz   .Time
	    stdcall   CmpString, 'otim'
	       test   eax, eax
		jnz   .OTime
	    stdcall   CmpString, 'go'
	       test   eax, eax
		jnz   .Go
	    stdcall   CmpString, 'force'
	       test   eax, eax
		jnz   .Force
	    stdcall   CmpString, 'post'
	       test   eax, eax
		jnz   .Post
	    stdcall   CmpString, 'nopost'
	       test   eax, eax
		jnz   .NoPost
	    stdcall   CmpString, 'white'
	       test   eax, eax
		jnz   .White
	    stdcall   CmpString, 'black'
	       test   eax, eax
		jnz   .Black
	    stdcall   CmpString, 'new'
	       test   eax, eax
		jnz   .New
	    stdcall   CmpString, 'quit'
		xor   r15d, r15d
	       test   eax, eax
		jnz   .Quit
	    stdcall   CmpString, 'uci'
		 or   r15d, -1
	       test   eax, eax
		jnz   .Quit
	       call   ParseUciMove
		mov   edi, eax
	       test   eax, eax
		jnz   .usermove

.Unknown:
		lea   rdi, [Output]
	    stdcall   PrintString, 'error: unknown command '
		mov   ecx, 64
	       call   _ParseToken
		mov   al, 10
	      stosb
	       call   _WriteOut_Output
		jmp   .Observing
.Time:
		jmp   .Observing
.OTime:
		jmp   .Observing
.Force:
		mov   dword[.comp_side], 0
		jmp   .Observing
.White:
		mov   dword[.comp_side], 1
		jmp   .Observing
.Black:
		mov   dword[.comp_side], 2
		jmp   .Observing
.Post:
		lea   rcx, [DisplayInfo_Xboard]
		mov   qword[options.displayInfoFxn], rcx
		jmp   .Observing
.NoPost:
		lea   rcx, [DisplayInfo_None]
		mov   qword[options.displayInfoFxn], rcx
		jmp   .Observing
.New:
		mov   dword[.comp_side], 2
		lea   rbp, [XboardLoop.th1.rootPos]
		lea   rsi, [szStartFEN]
		xor   ecx, ecx			; chess950 = false
	       call   Position_ParseFEN
		jmp   .Observing
.Go:
		mov   eax, dword[rbp+Pos.sideToMove]
		add   eax, 1
		mov   dword[.comp_side], eax
.calculate:
		lea   rcx, [.limits]
	       call   Limits_Init
		lea   rcx, [.limits]
		mov   dword[rcx+Limits.time+4*0], 100000
		mov   dword[rcx+Limits.time+4*1], 100000
		mov   dword[rcx+Limits.incr+4*0], 4000
		mov   dword[rcx+Limits.incr+4*1], 4000

		mov   dword[XBoardMove], 0
	       call   Limits_Set
		lea   rcx, [.limits]
	       call   ThreadPool_StartThinking
		lea   rcx, [mainThread]
	       call   Thread_WaitForSearchFinished

	; the main search thread will print the move
	; we just need to update our board with the move
		mov   edi, dword[XBoardMove]
		mov   rbx, qword[rbp+Pos.state]
		mov   rax, rbx
		sub   rax, qword[rbp+Pos.stateTable]
		xor   edx, edx
		mov   ecx, sizeof.State
		div   ecx
	     Assert   e, edx, 0, 'weird remainder in UciParseMoves'
		lea   ecx, [rax+8]
		shr   ecx, 2
		add   ecx, eax
	       call   Position_SetExtraCapacity
		mov   rbx, qword[rbp+Pos.state]
		mov   ecx, edi
		mov   word[rbx+State.move+sizeof.State], cx
	       call   Move_GivesCheck
	      movzx   ecx, word[rbx+State.move+sizeof.State]
		mov   edx, eax
	       call   Move_Do__UciParseMoves
		mov   qword[rbp+Pos.state], rbx
	       call   SetCheckInfo
		jmp   .Observing

.usermove:
	; edi: move
		mov   rbx, qword[rbp+Pos.state]
		mov   rax, rbx
		sub   rax, qword[rbp+Pos.stateTable]
		xor   edx, edx
		mov   ecx, sizeof.State
		div   ecx
	     Assert   e, edx, 0, 'weird remainder in UciParseMoves'
		lea   ecx, [rax+8]
		shr   ecx, 2
		add   ecx, eax
	       call   Position_SetExtraCapacity
		mov   rbx, qword[rbp+Pos.state]
		mov   ecx, edi
		mov   word[rbx+State.move+sizeof.State], cx
	       call   Move_GivesCheck
	      movzx   ecx, word[rbx+State.move+sizeof.State]
		mov   edx, eax
	       call   Move_Do__UciParseMoves
		mov   qword[rbp+Pos.state], rbx
	       call   SetCheckInfo


		mov   eax, dword[rbp+Pos.sideToMove]
		add   eax, 1
	       test   eax, dword[.comp_side]
		jnz   .calculate

		jmp   .Observing


;;;;;;;;;;;;;;;;;;;;;;