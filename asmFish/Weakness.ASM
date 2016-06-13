
Weakness_PickMove:
	; in: rbp address of position
	;     ecx weakness in average cp loss
	;     edx multipv
	; out: the root moves vector will have the top move swapped with a lower one

virtual at rsp
  .weights rq MAX_MOVES
  .localend    rb 0
end virtual
.localsize = ((.localend-rsp+15) and (-16))

	       push   rbx rsi rdi r14 r15
		sub   rsp, .localsize

	  vcvtsi2sd   xmm4, xmm4, ecx
	; xmm4 = target cp loss

		lea   rcx, [rbp+Pos.rootMovesVec]
	       call   RootMovesVec_Size
		mov   ecx, dword[options.multiPV]
		cmp   eax, ecx
	      cmova   eax, ecx
	       imul   ebx, eax, sizeof.RootMove
		add   rbx, qword[rbp+Pos.rootMovesVec.table]
	; rbx = end of moves to consider


	; assign weights to the scores based on our target cp loss
	;  and accumulate them into xmm3
		lea   rdx, [.weights]
		mov   rsi, qword[rbp+Pos.rootMovesVec.table]
	     vmovsd   xmm5, qword[.a]
	     vmovsd   xmm6, qword[.b]
	     vmovsd   xmm7, qword[.c]
	     vxorps   xmm3, xmm3, xmm3
.WeightLoop:
		mov   eax, dword[rsi+RootMove.score]
		cmp   eax, -VALUE_INFINITE
	      cmove   eax, dword[rsi+RootMove.prevScore]
match =1, DEBUG {
cmp eax, -VALUE_INFINITE
jne  @f
DebugDisplay 'both scores are -infinity in Weakness_PickMove'
@@:
}
	; convert from internal score to something reasonable
	;               x
	;  ----------------------------
	;  (2.58 + a*x^2) * (1 + b*x^2)
	  vcvtsi2sd   xmm0, xmm0, eax
	     vmulsd   xmm1, xmm0, xmm0
	   vfmaddsd   xmm2, xmm1, xmm5, qword[.pawn_value]
	   vfmaddsd   xmm1, xmm1, xmm6, qword[constd.1p0]
	     vmulsd   xmm1, xmm1, xmm2
	     vdivsd   xmm0, xmm0, xmm1
		cmp   rsi, qword[rbp+Pos.rootMovesVec.table]
		jne   .not_top
	     vsubsd   xmm4, xmm4, xmm0
	     ; xmm5 = - target score   (   target score = top score - target cp loss)
	.not_top:
	     vaddsd   xmm0, xmm0, xmm4
	; xmm0 = difference
	;   now compute weight
	;     c
	; ---------
	;  c + x^2
	     vmulsd   xmm0, xmm0, xmm0
	     vaddsd   xmm0, xmm0, xmm7
	     vdivsd   xmm1, xmm7, xmm0
	     vaddsd   xmm3, xmm3, xmm1
	     vmovsd   qword[rdx], xmm3
		add   rsi, sizeof.RootMove
		add   rdx, 8
		cmp   rsi, rbx
		 jb   .WeightLoop

	; get a random number in [0,xmm3)
	       call   _GetTime
		xor   rax, rdx
		lea   rcx, [prng]
		xor   qword[rcx], rax
	       call   Math_Rand_d
	     vmulsd   xmm0, xmm0, xmm3

	; find the move corresponding to xmm0
		lea   rdx, [.weights]
		mov   rsi, qword[rbp+Pos.rootMovesVec.table]
.FindMoveLoop:
	     comisd   xmm0, qword[rdx]
		jbe   .Found
		add   rsi, sizeof.RootMove
		add   rdx, 8
		cmp   rsi, rbx
		 jb   .FindMoveLoop
DebugDisplay 'did not find a move in Weakness_PickMove'
		jmp   .Return

.Found:
	; swap that move with the top move
		mov   ecx, (sizeof.RootMove/4) - 1
		mov   rdi, qword[rbp+Pos.rootMovesVec.table]
.SwapLoop:
		mov   eax, dword[rsi+4*rcx]
		mov   edx, dword[rdi+4*rcx]
		mov   dword[rdi+4*rcx], eax
		mov   dword[rsi+4*rcx], edx
		sub   ecx, 1
		jns   .SwapLoop
.Return:
		add   rsp, .localsize
		pop   r15 r14 rdi rsi rbx
		ret

align 8
.a dq 2.5e-9
.b dq -9.0e-10
.c dq 200.0
.pawn_value dq 2.58