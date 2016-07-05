


Tablebase_probe_ab:
	; in: rbp address of position
	;     rbx address of state
	;     ecx  alpha
	;     edx  beta
	;     r8  address of success
	; out: eax v

	       push   rsi rdi r13 r14 r15
virtual at rsp
  .stack rb 64*sizeof.ExtMove
  .lend rb 0
end virtual
.lsize = ((.lend-rsp+15) and (-16))
		sub   rsp, .lsize
		mov   rax, qword[rbx+State.checkersBB]
		mov   r14d, ecx
		mov   r15d, edx
		mov   r13, r8
		lea   rdi, [.stack]
	       test   rax, rax
		jnz   .InCheck
.NotInCheck:
	       call   Gen_Captures
		lea   rsi, [rdi-8]
		mov   rdx, rdi
.NextMove:	add   rsi, 8
		mov   ecx, dword[rsi+ExtMove.move]
		mov   eax, ecx
		and   eax, 63
	      movzx   eax, byte[rbp+Pos.board+rax]
		cmp   rsi, rdx
		jae   .GenDone
		cmp   ecx, (MOVE_TYPE_PROM+3) shl 12
		 jb   .NextMove
		cmp   ecx, (MOVE_TYPE_PROM+4) shl 12
		jae   .NextMove
	       test   eax, eax
		 jz   .NextMove
		sub   eax, 1 shl 12
	      stosq
		sub   eax, 1 shl 12
	      stosq
		sub   eax, 1 shl 12
	      stosq
		jmp   .NextMove
.InCheck:
	       call   Gen_Captures
.GenDone:
	       call   SetCheckInfo
		lea   rsi, [.stack-8]
.MoveLoop:
		add   rsi, 8
		mov   ecx, dword[rsi+ExtMove.move]
		mov   eax, ecx
		and   eax, 63
	      movzx   eax, byte[rbp+Pos.board+rax]
		cmp   rsi, rdi
		jae   .MovesDone
		cmp   ecx, MOVE_TYPE_CASTLE shl 12
		jae   .MoveLoop
	       test   eax, eax
		 jz   .MoveLoop
	       call   Move_IsLegal
		mov   ecx, dword[rsi+ExtMove.move]
	       test   eax, eax
		 jz   .MoveLoop
	       call   Move_GivesCheck
		mov   ecx, dword[rsi+ExtMove.move]
		mov   edx, eax
	       call   Move_Do
		mov   ecx, r15d
		mov   edx, r14d
		neg   ecx
		neg   edx
		mov   r8, r13
	       call   Tablebase_probe_ab
		neg   eax
	       push   rax
		mov   ecx, dword[rsi+ExtMove.move]
	       call   Move_Undo
		pop   rax
		xor   edx, edx
		cmp   edx, dword[r13]
	      cmove   eax, edx
		 je   .Return	     ; failed
		lea   edx, [rdx+2]
		cmp   eax, r14d
		jle   .MoveLoop
		cmp   eax, r15d
		jge   .Return
		mov   r14d, eax
		jmp   .MoveLoop
.MovesDone:
		mov   rcx, rbp
		mov   rdx, r13
	       call   _ZN13TablebaseCore15probe_dtz_tableER8PositioniPi
		xor   edx, edx
		cmp   edx, dword[r13]
	      cmove   eax, edx
		 je   .Return	     ; failed
		lea   edx, [rdx+1]
		cmp   r14d, eax
		 jl   .Return
		sub   r14d, 1
		sar   r14d, 31
		sub   edx, r14d
.Return:
		mov   dword[r13], edx
		pop   r15 r14 r13 rsi rdi
		ret




Tablebase_probe_wdl:
	; in: rbp address of position
	;     rbx address of state
	;     rcx  address of success
	; out: eax v

	       int3
		ret



probe_dtz_no_ep:
	; in: rbp address of position
	;     rbx address of state
	;     rcx  address of success
	; out: eax best

	       int3
		ret



Tablebase_probe_dtz:
	; in: rbp address of position
	;     rbx address of state
	;     rcx  address of success
	; out: eax v

	       int3
		ret


Tablebase_root_probe:
	; in: rbp address of position
	;     rbx address of state
	;     rcx  address of score
	; out: eax bool
	       int3
		ret


Tablebase_root_probe_wdl:
	; in: rbp address of position
	;     rbx address of state
	;     rcx  address of score
	; out: eax bool

	       int3
		ret















