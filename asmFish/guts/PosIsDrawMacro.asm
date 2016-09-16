macro PosIsDrawCheck50 isdraw_target, t {
local ..CheckKeys, ..CheckPrev, ..NoDraw

	; should preserve rcx, rdx

		mov   rax, qword[rbx+State.checkersBB]
	       test   rax, rax
		 jz   isdraw_target
	       push   rcx rdx rsi rdi
		sub   rsp, MAX_MOVES*sizeof.ExtMove
		mov   rdi, rsp
	       call   Gen_Legal
		cmp   rdi, rsp
		lea   rsp, [rsp+MAX_MOVES*sizeof.ExtMove]
		pop   rdi rsi rdx rcx
		 je   isdraw_target

	      movzx   eax, word[rbx+State.rule50]
	      movzx   t#d, word[rbx+State.pliesFromNull]
		cmp   eax, t#d
	      cmova   eax, t#d
		mov   t, qword[rbx+State.key]
		shr   eax, 1
		 jz   ..NoDraw
	       imul   rax, -2*sizeof.State
..CheckPrev:
		cmp   t, qword[rbx+rax+State.key]
		 je   isdraw_target
		add   rax, 2*sizeof.State
		jnz   ..CheckPrev
..NoDraw:
}