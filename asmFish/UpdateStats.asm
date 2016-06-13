;struct Stats {
;  static const Value Max = Value(1 << 28);
;  const T* operator[](Piece pc) const { return table[pc]; }
;  T* operator[](Piece pc) { return table[pc]; }
;  void clear() { std::memset(table, 0, sizeof(table)); }
;  void update(Piece pc, Square to, Move m) { table[pc][to] = m; }
;  void update(Piece pc, Square to, Value v) {
;    if (abs(int(v)) >= 324)
;        return;
;    table[pc][to] -= table[pc][to] * abs(int(v)) / (CM ? 936 : 324);
;    table[pc][to] += int(v) * 32;
;  }
;private:
;  T table[PIECE_NB][SQUARE_NB];
;};
;typedef Stats<Move> MoveStats;
;typedef Stats<Value, false> HistoryStats;
;typedef Stats<Value,  true> CounterMoveStats;
;typedef Stats<CounterMoveStats> CounterMoveHistoryStats;

UpdateStats:
	; in: rbp pos
	;     rbx state
	;     ecx move
	;     edx depth   this should be >0
	;     r8  quiets  could be NULL
	;     r9d quietsCnt

virtual at rsp
  .quiets    rq 1
  .moveoff   rq 1
  .prevoff   rq 1
  .quietsCnt rd 1
  .depth     rd 1
  .move      rd 1
  .bonus     rd 1
  .absbonus  rd 1
  .bonus32   rd 1
  .lend rb 0
end virtual
.lsize = (((.lend-rsp+15) and (-16))+8)

	       push   rsi rdi r12 r13 r14 r15
		sub   rsp, .lsize

		mov   dword[.move], ecx
		mov   dword[.depth], edx
		mov   qword[.quiets], r8
		mov   dword[.quietsCnt], r9d


match =1, VERBOSE {
lea rdi, [VerboseOutput]
szcall PrintString, 'updating stats for '
mov ecx, dword[.move]
xor  edx, edx
call PrintUciMove
mov al, 10
stosb
szcall PrintString, 'depth: '
movsxd rax, dword[.depth]
call PrintSignedInteger
mov al, 10
stosb
szcall PrintString, 'ss->killers[0]: '
mov ecx, dword[rbx+State.killers+4*0]
xor  edx, edx
call PrintUciMove
mov al, 10
stosb
szcall PrintString, 'ss->killers[1]: '
mov ecx, dword[rbx+State.killers+4*1]
xor  edx, edx
call PrintUciMove
mov al, 10
stosb
szcall PrintString, 'cmh:  '
mov rcx, qword[rbx-1*sizeof.State+State.counterMoves]
call PrintAddress
mov al, 10
stosb
szcall PrintString, 'fmh:  '
mov rcx, qword[rbx-2*sizeof.State+State.counterMoves]
call PrintAddress
mov al, 10
stosb
szcall PrintString, 'fmh2: '
mov rcx, qword[rbx-4*sizeof.State+State.counterMoves]
call PrintAddress
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
mov   ecx, dword[.move]
mov   edx, dword[.depth]
mov   r8, qword[.quiets]
mov   r9d, dword[.quietsCnt]
}



		mov   eax, edx
	       imul   eax, edx
		lea   eax, [rax+2*rdx-2]
		mov   dword[.bonus], eax

		mov   eax, dword[rbx+State.killers+4*0]
		cmp   eax, ecx
		 je   @f
		mov   dword[rbx+State.killers+4*1], eax
		mov   dword[rbx+State.killers+4*0], ecx
	@@:

		mov   eax, dword[.move]
		mov   ecx, eax
		and   ecx, 63
		shr   eax, 6
		and   eax, 63
	      movzx   eax, byte[rbp+Pos.board+rax]
		shl   eax, 6
		add   eax, ecx
		shl   eax, 2
		mov   qword[.moveoff], rax

		mov   eax, dword[rbx-1*sizeof.State+State.currentMove]
		and   eax, 63
VerboseDisplay db 'prevSq: '
VerboseDisplayInt rax


	      movzx   ecx, byte[rbp+Pos.board+rax]
		shl   ecx, 6
		add   eax, ecx
		shl   eax, 2
		mov   qword[.prevoff], rax

		mov   eax, dword[.bonus]
		shl   eax, 5
		mov   dword[.bonus32], eax
		mov   eax, dword[.bonus]
	      ;  cdq                      bonus is already positive
	      ;  xor   eax, edx
	      ;  sub   eax, edx
		mov   dword[.absbonus], eax
		cmp   eax, 324
		jae   .bonus_too_big



		mov   rsi, qword[rbp+Pos.history]
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 324

		mov   rsi, qword[rbx-1*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
		mov   rsi, qword[rbp+Pos.counterMoves]
		add   rsi, qword[.prevoff]
		mov   eax, dword[.move]
		mov   dword[rsi], eax
	@@:

		mov   rsi, qword[rbx-2*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:

		mov   rsi, qword[rbx-4*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:


	; Decrease all the other played quiet moves
		neg   dword[.bonus32]

		xor   edi, edi
		mov   r15, qword[.quiets]
.next_quiet:
		cmp   edi, dword[.quietsCnt]
		jae   .quiets_done



match =1, VERBOSE {
push r12 rdi
mov r12d, dword[r15+4*rdi]
lea rdi, [VerboseOutput]
szcall PrintString, 'decreasing quiet '
mov ecx, r12d
xor  edx, edx
call PrintUciMove
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop rdi r12
}


		mov   eax, dword[r15+4*rdi]
		mov   ecx, eax
		and   ecx, 63
		shr   eax, 6
		and   eax, 63
	      movzx   eax, byte[rbp+Pos.board+rax]
		shl   eax, 6
		add   eax, ecx
		shl   eax, 2
		mov   dword[.moveoff], eax

		mov   rsi, qword[rbp+Pos.history]
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 324

		mov   rsi, qword[rbx-1*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:
		mov   rsi, qword[rbx-2*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:
		mov   rsi, qword[rbx-4*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.moveoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:

		add   edi, 1
		jmp   .next_quiet
.quiets_done:



		mov   eax, dword[rbx-1*sizeof.State+State.moveCount]
		cmp   eax, 1
		jne   .done
		mov   al, byte[rbx+State.capturedPiece]
	       test   al, al
		jnz   .done

VerboseDisplay <db 'extra penalty',10>

		mov   eax, dword[.depth]
		mov   ecx, dword[.absbonus]
		lea   ecx, [rcx+2*(rax+1)+1]
		mov   dword[.absbonus], ecx
		cmp   ecx, 324
		jae   .done
		shl   ecx, 5
		neg   ecx
		mov   dword[.bonus32], ecx

		mov   rsi, qword[rbx-2*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.prevoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:
		mov   rsi, qword[rbx-3*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.prevoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:
		mov   rsi, qword[rbx-5*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   @f
		add   rsi, qword[.prevoff]
	apply_bonus   rsi, dword[.bonus32], dword[.absbonus], 936
	@@:




.done:
		add   rsp, .lsize
		pop   r15 r14 r13 r12 rdi rsi
		ret



.bonus_too_big:
		mov   rsi, qword[rbx-1*sizeof.State+State.counterMoves]
	       test   rsi, rsi
		 jz   .done
		mov   rsi, qword[rbp+Pos.counterMoves]
		add   rsi, qword[.prevoff]
		mov   eax, dword[.move]
		mov   dword[rsi], eax
		jmp   .done











if 0
	align	8

;  void update_stats(const Position& pos, Stack* ss, Move move,
;                    Depth depth, Move* quiets, int quietsCnt) {
_ZN12_GLOBAL__N_112update_statsERK8PositionPN6Search5StackE4Move5DepthPS6_i:; Local function
	push	r15					; AF30 _ 41: 57
	push	r14					; AF32 _ 41: 56
	push	r13					; AF34 _ 41: 55
	push	r12					; AF36 _ 41: 54
	push	rbp					; AF38 _ 55
	push	rdi					; AF39 _ 57
	push	rsi					; AF3A _ 56
	push	rbx					; AF3B _ 53
	sub	rsp, 56 				; AF3C _ 48: 83. EC, 38
	mov	eax, dword [rdx+14H]			; AF40 _ 8B. 42, 14
	cmp	eax, r8d				; AF43 _ 44: 39. C0
	mov	rdi, rdx				; AF46 _ 48: 89. D7
	mov	dword [rsp+98H], r9d			; AF49 _ 44: 89. 8C 24, 00000098
	jz	?_2161					; AF51 _ 74, 07
	mov	dword [rdx+18H], eax			; AF53 _ 89. 42, 18
	mov	dword [rdx+14H], r8d			; AF56 _ 44: 89. 42, 14
?_2161: mov	r10d, dword [rdi-44H]			; AF5A _ 44: 8B. 57, BC
	lea	r11, [CounterMoveHistory]; AF5E _ 4C: 8D. 1D, 0001D480(rel)
	mov	esi, dword [rdi-1CH]			; AF65 _ 8B. 77, E4
	mov	edx, dword [rsp+98H]			; AF68 _ 8B. 94 24, 00000098
	mov	ebx, dword [rsp+98H]			; AF6F _ 8B. 9C 24, 00000098
	mov	ebp, r10d				; AF76 _ 44: 89. D5
	and	ebp, 3FH				; AF79 _ 83. E5, 3F
	mov	r13d, esi				; AF7C _ 41: 89. F5
	mov	r15d, dword [rcx+rbp*4] 		; AF7F _ 44: 8B. 3C A9
	and	r13d, 3FH				; AF83 _ 41: 83. E5, 3F
	imul	edx, edx				; AF87 _ 0F AF. D2
	mov	rax, rbp				; AF8A _ 48: 89. E8
	mov	r9d, dword [rcx+r13*4]			; AF8D _ 46: 8B. 0C A9
	shl	rax, 12 				; AF91 _ 48: C1. E0, 0C
	mov	r12, r13				; AF95 _ 4D: 89. EC
	shl	r12, 12 				; AF98 _ 49: C1. E4, 0C
	lea	r14d, [rbx+rdx-1H]			; AF9C _ 44: 8D. 74 13, FF
	mov	rdx, qword [rcx+3B0H]			; AFA1 _ 48: 8B. 91, 000003B0
	mov	ebx, r8d				; AFA8 _ 44: 89. C3
	shl	r15, 18 				; AFAB _ 49: C1. E7, 12
	and	ebx, 3FH				; AFAF _ 83. E3, 3F
	add	r15, r11				; AFB2 _ 4D: 01. DF
	mov	qword [rsp+20H], r9			; AFB5 _ 4C: 89. 4C 24, 20
	shl	r9, 18					; AFBA _ 49: C1. E1, 12
	add	r15, rax				; AFBE _ 49: 01. C7
	add	r9, r11 				; AFC1 _ 4D: 01. D9
	mov	qword [rsp+10H], r15			; AFC4 _ 4C: 89. 7C 24, 10
	mov	r15d, r14d				; AFC9 _ 45: 89. F7
	add	r9, r12 				; AFCC _ 4D: 01. E1
	sar	r15d, 31				; AFCF _ 41: C1. FF, 1F
	mov	qword [rsp+8H], r9			; AFD3 _ 4C: 89. 4C 24, 08
	mov	r9d, r8d				; AFD8 _ 45: 89. C1
	mov	r11d, r15d				; AFDB _ 45: 89. FB
	sar	r9d, 6					; AFDE _ 41: C1. F9, 06
	mov	qword [rsp+18H], rdx			; AFE2 _ 48: 89. 54 24, 18
	xor	r11d, r14d				; AFE7 _ 45: 31. F3
	and	r9d, 3FH				; AFEA _ 41: 83. E1, 3F
	sub	r11d, r15d				; AFEE _ 45: 29. FB
	mov	r9d, dword [rcx+r9*4]			; AFF1 _ 46: 8B. 0C 89
	cmp	r11d, 323				; AFF5 _ 41: 81. FB, 00000143
	jg	?_2162					; AFFC _ 7F, 40
	mov	eax, r9d				; AFFE _ 44: 89. C8
	shl	rax, 8					; B001 _ 48: C1. E0, 08
	lea	rdx, [rdx+rax+4DCH]			; B005 _ 48: 8D. 94 02, 000004DC
	lea	r15, [rdx+rbx*4]			; B00D _ 4C: 8D. 3C 9A
	mov	edx, 424194301				; B011 _ BA, 1948B0FD
	mov	r12d, dword [r15]			; B016 _ 45: 8B. 27
	imul	r12d, r11d				; B019 _ 45: 0F AF. E3
	mov	eax, r12d				; B01D _ 44: 89. E0
	sar	r12d, 31				; B020 _ 41: C1. FC, 1F
	imul	edx					; B024 _ F7. EA
	mov	eax, r14d				; B026 _ 44: 89. F0
	shl	eax, 5					; B029 _ C1. E0, 05
	sar	edx, 5					; B02C _ C1. FA, 05
	sub	edx, r12d				; B02F _ 44: 29. E2
	mov	r12d, dword [r15]			; B032 _ 45: 8B. 27
	sub	r12d, edx				; B035 _ 41: 29. D4
	add	r12d, eax				; B038 _ 41: 01. C4
	mov	dword [r15], r12d			; B03B _ 45: 89. 27
?_2162: sar	esi, 6					; B03E _ C1. FE, 06
	and	esi, 3FH				; B041 _ 83. E6, 3F
	cmp	r13, rsi				; B044 _ 49: 39. F5
	je	?_2172					; B047 _ 0F 84, 000002D3
	mov	r15, qword [rsp+20H]			; B04D _ 4C: 8B. 7C 24, 20
	mov	rsi, qword [rsp+18H]			; B052 _ 48: 8B. 74 24, 18
	shl	r15, 8					; B057 _ 49: C1. E7, 08
	lea	rdx, [rsi+r15+14DCH]			; B05B _ 4A: 8D. 94 3E, 000014DC
	lea	r12, [rdx+r13*4]			; B063 _ 4E: 8D. 24 AA
	cmp	r8d, dword [r12]			; B067 _ 45: 3B. 04 24
	jz	?_2163					; B06B _ 74, 0E
	mov	dword [r12], r8d			; B06D _ 45: 89. 04 24
	mov	r10d, dword [rdi-44H]			; B071 _ 44: 8B. 57, BC
	mov	ebp, r10d				; B075 _ 44: 89. D5
	and	ebp, 3FH				; B078 _ 83. E5, 3F
?_2163: cmp	r11d, 323				; B07B _ 41: 81. FB, 00000143
	jg	Unnamed_4_2EC1				; B082 _ 0F 8F, 00002EC1(rel)
	mov	rax, r9 				; B088 _ 4C: 89. C8
	shl	rbx, 2					; B08B _ 48: C1. E3, 02
	mov	edx, r11d				; B08F _ 44: 89. DA
	shl	rax, 8					; B092 _ 48: C1. E0, 08
	add	rax, qword [rsp+8H]			; B096 _ 48: 03. 44 24, 08
	mov	r12d, r14d				; B09B _ 45: 89. F4
	shl	r12d, 6 				; B09E _ 41: C1. E4, 06
	add	rax, rbx				; B0A2 _ 48: 01. D8
	mov	r15d, dword [rax]			; B0A5 _ 44: 8B. 38
	imul	edx, r15d				; B0A8 _ 41: 0F AF. D7
	lea	r8d, [rdx+1FFH] 			; B0AC _ 44: 8D. 82, 000001FF
	test	edx, edx				; B0B3 _ 85. D2
	cmovns	r8d, edx				; B0B5 _ 44: 0F 49. C2
	sar	r10d, 6 				; B0B9 _ 41: C1. FA, 06
	and	r10d, 3FH				; B0BD _ 41: 83. E2, 3F
	sar	r8d, 9					; B0C1 _ 41: C1. F8, 09
	sub	r15d, r8d				; B0C5 _ 45: 29. C7
	add	r15d, r12d				; B0C8 _ 45: 01. E7
	cmp	r10, rbp				; B0CB _ 49: 39. EA
	mov	dword [rax], r15d			; B0CE _ 44: 89. 38
	mov	eax, 3					; B0D1 _ B8, 00000003
	je	?_2171					; B0D6 _ 0F 84, 00000236
?_2164: shl	r9, 8					; B0DC _ 49: C1. E1, 08
	add	r9, qword [rsp+10H]			; B0E0 _ 4C: 03. 4C 24, 10
	mov	r8d, 2					; B0E5 _ 41: B8, 00000002
	add	rbx, r9 				; B0EB _ 4C: 01. CB
	mov	r9d, dword [rbx]			; B0EE _ 44: 8B. 0B
	imul	r11d, r9d				; B0F1 _ 45: 0F AF. D9
	lea	r10d, [r11+1FFH]			; B0F5 _ 45: 8D. 93, 000001FF
	test	r11d, r11d				; B0FC _ 45: 85. DB
	cmovs	r11d, r10d				; B0FF _ 45: 0F 48. DA
	sar	r11d, 9 				; B103 _ 41: C1. FB, 09
	sub	r9d, r11d				; B107 _ 45: 29. D9
	add	r9d, r12d				; B10A _ 45: 01. E1
	mov	dword [rbx], r9d			; B10D _ 44: 89. 0B
?_2165: mov	ebx, dword [rsp+0A8H]			; B110 _ 8B. 9C 24, 000000A8
	test	ebx, ebx				; B117 _ 85. DB
	jg	?_2168					; B119 _ 7F, 25

text.hot0B11BH:
	test	r8d, r8d				; B11B _ 45: 85. C0
	jz	?_2167					; B11E _ 74, 0A
?_2166: cmp	dword [rdi-4H], 1			; B120 _ 83. 7F, FC, 01
	je	?_2170					; B124 _ 0F 84, 00000156
?_2167: add	rsp, 56 				; B12A _ 48: 83. C4, 38
	pop	rbx					; B12E _ 5B
	pop	rsi					; B12F _ 5E
	pop	rdi					; B130 _ 5F
	pop	rbp					; B131 _ 5D
	pop	r12					; B132 _ 41: 5C
	pop	r13					; B134 _ 41: 5D
	pop	r14					; B136 _ 41: 5E
	pop	r15					; B138 _ 41: 5F
	ret						; B13A _ C3

; Filling space: 5H
; Filler type: Multi-byte NOP
;       db 0FH, 1FH, 44H, 00H, 00H

ALIGN	8
?_2168: mov	r11d, r14d				; B140 _ 45: 89. F3
	neg	r11d					; B143 _ 41: F7. DB
	mov	edx, r11d				; B146 _ 44: 89. DA
	mov	esi, r11d				; B149 _ 44: 89. DE
	sar	edx, 31 				; B14C _ C1. FA, 1F
	mov	r15d, edx				; B14F _ 41: 89. D7
	xor	r15d, r11d				; B152 _ 45: 31. DF
	sub	r15d, edx				; B155 _ 41: 29. D7
	cmp	r15d, 323				; B158 _ 41: 81. FF, 00000143
	setg	r10b					; B15F _ 41: 0F 9F. C2
	test	r8d, r8d				; B163 _ 45: 85. C0
	sete	r9b					; B166 _ 41: 0F 94. C1
	and	eax, 01H				; B16A _ 83. E0, 01
	shl	esi, 5					; B16D _ C1. E6, 05
	xor	eax, 01H				; B170 _ 83. F0, 01
	shl	r11d, 6 				; B173 _ 41: C1. E3, 06
	or	r9d, r10d				; B177 _ 45: 09. D1
	mov	dword [rsp+2CH], esi			; B17A _ 89. 74 24, 2C
	or	eax, r10d				; B17E _ 44: 09. D0
	test	r10b, r10b				; B181 _ 45: 84. D2
	mov	r12d, r11d				; B184 _ 45: 89. DC
	jne	Unnamed_4_2F6F				; B187 _ 0F 85, 00002F6F(rel)
	test	r9b, r9b				; B18D _ 45: 84. C9
	jne	Unnamed_4_2FD2				; B190 _ 0F 85, 00002FD2(rel)
	test	al, al					; B196 _ 84. C0
	jne	Unnamed_4_2ED0				; B198 _ 0F 85, 00002ED0(rel)
	mov	rbx, qword [rsp+18H]			; B19E _ 48: 8B. 5C 24, 18
	xor	esi, esi				; B1A3 _ 31. F6
	add	rbx, 1244				; B1A5 _ 48: 81. C3, 000004DC
	mov	qword [rsp+18H], rbx			; B1AC _ 48: 89. 5C 24, 18
?_2169: mov	r9, qword [rsp+0A0H]			; B1B1 _ 4C: 8B. 8C 24, 000000A0
	mov	rax, qword [rsp+18H]			; B1B9 _ 48: 8B. 44 24, 18
	mov	r9d, dword [r9+rsi*4]			; B1BE _ 45: 8B. 0C B1
	mov	r8d, r9d				; B1C2 _ 45: 89. C8
	and	r9d, 3FH				; B1C5 _ 41: 83. E1, 3F
	sar	r8d, 6					; B1C9 _ 41: C1. F8, 06
	shl	r9, 2					; B1CD _ 49: C1. E1, 02
	and	r8d, 3FH				; B1D1 _ 41: 83. E0, 3F
	mov	r8d, dword [rcx+r8*4]			; B1D5 _ 46: 8B. 04 81
	shl	r8, 8					; B1D9 _ 49: C1. E0, 08
	lea	r11, [rax+r8]				; B1DD _ 4E: 8D. 1C 00
	mov	eax, 424194301				; B1E1 _ B8, 1948B0FD
	add	r11, r9 				; B1E6 _ 4D: 01. CB
	mov	r10d, dword [r11]			; B1E9 _ 45: 8B. 13
	mov	ebx, r10d				; B1EC _ 44: 89. D3
	imul	ebx, r15d				; B1EF _ 41: 0F AF. DF
	imul	ebx					; B1F3 _ F7. EB
	sar	ebx, 31 				; B1F5 _ C1. FB, 1F
	sar	edx, 5					; B1F8 _ C1. FA, 05
	sub	edx, ebx				; B1FB _ 29. DA
	sub	r10d, edx				; B1FD _ 41: 29. D2
	add	r10d, dword [rsp+2CH]			; B200 _ 44: 03. 54 24, 2C
	mov	dword [r11], r10d			; B205 _ 45: 89. 13
	mov	r11, qword [rsp+8H]			; B208 _ 4C: 8B. 5C 24, 08
	lea	r10, [r11+r8]				; B20D _ 4F: 8D. 14 03
	add	r10, r9 				; B211 _ 4D: 01. CA
	mov	ebx, dword [r10]			; B214 _ 41: 8B. 1A
	mov	eax, ebx				; B217 _ 89. D8
	imul	eax, r15d				; B219 _ 41: 0F AF. C7
	lea	edx, [rax+1FFH] 			; B21D _ 8D. 90, 000001FF
	test	eax, eax				; B223 _ 85. C0
	cmovns	edx, eax				; B225 _ 0F 49. D0
	add	r8, qword [rsp+10H]			; B228 _ 4C: 03. 44 24, 10
	sar	edx, 9					; B22D _ C1. FA, 09
	sub	ebx, edx				; B230 _ 29. D3
	add	r9, r8					; B232 _ 4D: 01. C1
	add	ebx, r12d				; B235 _ 44: 01. E3
	mov	dword [r10], ebx			; B238 _ 41: 89. 1A
	mov	r11d, dword [r9]			; B23B _ 45: 8B. 19
	mov	r8d, r11d				; B23E _ 45: 89. D8
	imul	r8d, r15d				; B241 _ 45: 0F AF. C7
	lea	r10d, [r8+1FFH] 			; B245 _ 45: 8D. 90, 000001FF
	test	r8d, r8d				; B24C _ 45: 85. C0
	cmovns	r10d, r8d				; B24F _ 45: 0F 49. D0
	add	rsi, 1					; B253 _ 48: 83. C6, 01
	sar	r10d, 9 				; B257 _ 41: C1. FA, 09
	sub	r11d, r10d				; B25B _ 45: 29. D3
	add	r11d, r12d				; B25E _ 45: 01. E3
	cmp	dword [rsp+0A8H], esi			; B261 _ 39. B4 24, 000000A8
	mov	dword [r9], r11d			; B268 _ 45: 89. 19
	jle	?_2166					; B26B _ 0F 8E, FFFFFEAF
	jmp	?_2169					; B271 _ E9, FFFFFF3B

; Filling space: 0AH
; Filler type: Multi-byte NOP
;       db 66H, 2EH, 0FH, 1FH, 84H, 00H, 00H, 00H
;       db 00H, 00H

	align	16
?_2170: mov	r15, qword [rcx+3B8H]			; B280 _ 4C: 8B. B9, 000003B8
	mov	r12d, dword [r15+40H]			; B287 _ 45: 8B. 67, 40
	test	r12d, r12d				; B28B _ 45: 85. E4
	jne	?_2167					; B28E _ 0F 85, FFFFFE96
	mov	ecx, dword [rcx+rbp*4]			; B294 _ 8B. 0C A9
	neg	r14d					; B297 _ 41: F7. DE
	shl	rbp, 12 				; B29A _ 48: C1. E5, 0C
	mov	esi, dword [rsp+98H]			; B29E _ 8B. B4 24, 00000098
	lea	rdi, [CounterMoveHistory]; B2A5 _ 48: 8D. 3D, 0001D480(rel)
	shl	rcx, 18 				; B2AC _ 48: C1. E1, 12
	lea	r9d, [rsi+rsi+2H]			; B2B0 _ 44: 8D. 4C 36, 02
	add	rcx, rdi				; B2B5 _ 48: 01. F9
	sub	r14d, r9d				; B2B8 _ 45: 29. CE
	add	rbp, rcx				; B2BB _ 48: 01. CD
	mov	ebx, r14d				; B2BE _ 44: 89. F3
	sar	ebx, 31 				; B2C1 _ C1. FB, 1F
	mov	eax, ebx				; B2C4 _ 89. D8
	xor	eax, r14d				; B2C6 _ 44: 31. F0
	sub	eax, ebx				; B2C9 _ 29. D8
	cmp	eax, 323				; B2CB _ 3D, 00000143
	jg	?_2167					; B2D0 _ 0F 8F, FFFFFE54
	mov	rdx, qword [rsp+20H]			; B2D6 _ 48: 8B. 54 24, 20
	shl	rdx, 8					; B2DB _ 48: C1. E2, 08
	add	rbp, rdx				; B2DF _ 48: 01. D5
	lea	rbp, [rbp+r13*4]			; B2E2 _ 4A: 8D. 6C AD, 00
	mov	r13d, dword [rbp]			; B2E7 _ 44: 8B. 6D, 00
	imul	eax, r13d				; B2EB _ 41: 0F AF. C5
	lea	r11d, [rax+1FFH]			; B2EF _ 44: 8D. 98, 000001FF
	test	eax, eax				; B2F6 _ 85. C0
	cmovs	eax, r11d				; B2F8 _ 41: 0F 48. C3
	shl	r14d, 6 				; B2FC _ 41: C1. E6, 06
	sar	eax, 9					; B300 _ C1. F8, 09
	sub	r13d, eax				; B303 _ 41: 29. C5
	add	r13d, r14d				; B306 _ 45: 01. F5
	mov	dword [rbp], r13d			; B309 _ 44: 89. 6D, 00
	jmp	?_2167					; B30D _ E9, FFFFFE18

?_2171: xor	r8d, r8d				; B312 _ 45: 31. C0
	mov	al, 1					; B315 _ B0, 01
	jmp	?_2165					; B317 _ E9, FFFFFDF4

; Filling space: 4H
; Filler type: Multi-byte NOP
;       db 0FH, 1FH, 40H, 00H

ALIGN	8
?_2172: mov	eax, 2					; B320 _ B8, 00000002
	xor	esi, esi				; B325 _ 31. F6

text.hot.0B327H:
	sar	r10d, 6 				; B327 _ 41: C1. FA, 06
	and	r10d, 3FH				; B32B _ 41: 83. E2, 3F
	cmp	r10, rbp				; B32F _ 49: 39. EA
	jz	?_2173					; B332 _ 74, 1D
	cmp	r11d, 323				; B334 _ 41: 81. FB, 00000143
	jg	_ZN12_GLOBAL__N_112update_statsERK8PositionPN6Search5StackE4Move5DepthPS6_i.cold.573; B33B _ 0F 8F, 00002EB6(rel)
	mov	r12d, r14d				; B341 _ 45: 89. F4
	shl	rbx, 2					; B344 _ 48: C1. E3, 02
	shl	r12d, 6 				; B348 _ 41: C1. E4, 06
	jmp	?_2164					; B34C _ E9, FFFFFD8B

?_2173: ; Local function
	mov	eax, esi				; B351 _ 89. F0
	xor	r8d, r8d				; B353 _ 45: 31. C0
	jmp	?_2165					; B356 _ E9, FFFFFDB5

	nop						; B35B _ 90
; Filling space: 4H
; Filler type: Multi-byte NOP
;       db 0FH, 1FH, 40H, 00H



_ZN12_GLOBAL__N_112update_statsERK8PositionPN6Search5StackE4Move5DepthPS6_i.cold.573:; Local function
	mov	r8d, 2					; 2EB6 _ 41: B8, 00000002
	jmp	?_2165					; 2EBC _ E9, 0000B110(rel)
Unnamed_4_2EC1:
	mov	eax, 3					; 2EC1 _ B8, 00000003
	mov	esi, 1					; 2EC6 _ BE, 00000001
	jmp	text.hot.0B327H 		       ; 2ECB _ E9, 0000B327(rel)
Unnamed_4_2ED0:
	mov	rsi, qword [rsp+18H]			; 2ED0 _ 48: 8B. 74 24, 18
	xor	ebx, ebx				; 2ED5 _ 31. DB
	lea	rsi, [rsi+4DCH] 			; 2ED7 _ 48: 8D. B6, 000004DC
?_1096: mov	r10, qword [rsp+0A0H]			; 2EDE _ 4C: 8B. 94 24, 000000A0
	mov	r11d, 324				; 2EE6 _ 41: BB, 00000144
	mov	r9d, dword [r10+rbx*4]			; 2EEC _ 45: 8B. 0C 9A
	add	rbx, 1					; 2EF0 _ 48: 83. C3, 01
	mov	r8d, r9d				; 2EF4 _ 45: 89. C8
	and	r9d, 3FH				; 2EF7 _ 41: 83. E1, 3F
	lea	r9, [r9*4]				; 2EFB _ 4E: 8D. 0C 8D, 00000000
	sar	r8d, 6					; 2F03 _ 41: C1. F8, 06
	and	r8d, 3FH				; 2F07 _ 41: 83. E0, 3F
	mov	r8d, dword [rcx+r8*4]			; 2F0B _ 46: 8B. 04 81
	shl	r8, 8					; 2F0F _ 49: C1. E0, 08
	lea	r10, [rsi+r8]				; 2F13 _ 4E: 8D. 14 06
	add	r8, qword [rsp+10H]			; 2F17 _ 4C: 03. 44 24, 10
	add	r10, r9 				; 2F1C _ 4D: 01. CA
	mov	eax, dword [r10]			; 2F1F _ 41: 8B. 02
	add	r9, r8					; 2F22 _ 4D: 01. C1
	imul	eax, r15d				; 2F25 _ 41: 0F AF. C7
	cdq						; 2F29 _ 99
	idiv	r11d					; 2F2A _ 41: F7. FB
	mov	r11d, dword [r10]			; 2F2D _ 45: 8B. 1A
	sub	r11d, eax				; 2F30 _ 41: 29. C3
	mov	eax, dword [rsp+2CH]			; 2F33 _ 8B. 44 24, 2C
	add	eax, r11d				; 2F37 _ 44: 01. D8
	mov	dword [r10], eax			; 2F3A _ 41: 89. 02
	mov	r8d, dword [r9] 			; 2F3D _ 45: 8B. 01
	mov	r10d, 512				; 2F40 _ 41: BA, 00000200
	mov	eax, r8d				; 2F46 _ 44: 89. C0
	imul	eax, r15d				; 2F49 _ 41: 0F AF. C7
	cdq						; 2F4D _ 99
	idiv	r10d					; 2F4E _ 41: F7. FA
	sub	r8d, eax				; 2F51 _ 41: 29. C0
	mov	r11d, r8d				; 2F54 _ 45: 89. C3
	add	r11d, r12d				; 2F57 _ 45: 01. E3
	cmp	dword [rsp+0A8H], ebx			; 2F5A _ 39. 9C 24, 000000A8
	mov	dword [r9], r11d			; 2F61 _ 45: 89. 19
	jg	?_1096					; 2F64 _ 0F 8F, FFFFFF74
	jmp	?_2166					; 2F6A _ E9, 0000B120(rel)
Unnamed_4_2F6F:
	test	r9b, r9b				; 2F6F _ 45: 84. C9
	jne	text.hot0B11BH			      ; 2F72 _ 0F 85, 0000B11B(rel)
	xor	ebx, ebx				; 2F78 _ 31. DB
	mov	r11d, 512				; 2F7A _ 41: BB, 00000200
?_1097: mov	r8, qword [rsp+0A0H]			; 2F80 _ 4C: 8B. 84 24, 000000A0
	mov	edx, dword [r8+rbx*4]			; 2F88 _ 41: 8B. 14 98
	add	rbx, 1					; 2F8C _ 48: 83. C3, 01
	mov	eax, edx				; 2F90 _ 89. D0
	and	edx, 3FH				; 2F92 _ 83. E2, 3F
	sar	eax, 6					; 2F95 _ C1. F8, 06
	and	eax, 3FH				; 2F98 _ 83. E0, 3F
	mov	r10d, dword [rcx+rax*4] 		; 2F9B _ 44: 8B. 14 81
	shl	r10, 8					; 2F9F _ 49: C1. E2, 08
	add	r10, qword [rsp+10H]			; 2FA3 _ 4C: 03. 54 24, 10
	lea	r9, [r10+rdx*4] 			; 2FA8 _ 4D: 8D. 0C 92
	mov	esi, dword [r9] 			; 2FAC _ 41: 8B. 31
	mov	eax, esi				; 2FAF _ 89. F0
	imul	eax, r15d				; 2FB1 _ 41: 0F AF. C7
	cdq						; 2FB5 _ 99
	idiv	r11d					; 2FB6 _ 41: F7. FB
	sub	esi, eax				; 2FB9 _ 29. C6
	mov	r8d, esi				; 2FBB _ 41: 89. F0
	add	r8d, r12d				; 2FBE _ 45: 01. E0
	cmp	dword [rsp+0A8H], ebx			; 2FC1 _ 39. 9C 24, 000000A8
	mov	dword [r9], r8d 			; 2FC8 _ 45: 89. 01
	jg	?_1097					; 2FCB _ 7F, B3
	jmp	?_2166					; 2FCD _ E9, 0000B120(rel)
Unnamed_4_2FD2:
	test	al, al					; 2FD2 _ 84. C0
	jne	?_1099					; 2FD4 _ 0F 85, 000000A2
	mov	r11, qword [rsp+18H]			; 2FDA _ 4C: 8B. 5C 24, 18
	xor	esi, esi				; 2FDF _ 31. F6
	mov	dword [rsp+10H], r8d			; 2FE1 _ 44: 89. 44 24, 10
	lea	rbx, [r11+4DCH] 			; 2FE6 _ 49: 8D. 9B, 000004DC
?_1098: mov	r10, qword [rsp+0A0H]			; 2FED _ 4C: 8B. 94 24, 000000A0
	mov	r8d, 324				; 2FF5 _ 41: B8, 00000144
	mov	eax, dword [r10+rsi*4]			; 2FFB _ 41: 8B. 04 B2
	add	rsi, 1					; 2FFF _ 48: 83. C6, 01
	mov	edx, eax				; 3003 _ 89. C2
	and	eax, 3FH				; 3005 _ 83. E0, 3F
	lea	r10, [rax*4]				; 3008 _ 4C: 8D. 14 85, 00000000
	sar	edx, 6					; 3010 _ C1. FA, 06
	and	edx, 3FH				; 3013 _ 83. E2, 3F
	mov	r9d, dword [rcx+rdx*4]			; 3016 _ 44: 8B. 0C 91
	shl	r9, 8					; 301A _ 49: C1. E1, 08
	lea	r11, [rbx+r9]				; 301E _ 4E: 8D. 1C 0B
	add	r9, qword [rsp+8H]			; 3022 _ 4C: 03. 4C 24, 08
	add	r11, r10				; 3027 _ 4D: 01. D3
	mov	eax, dword [r11]			; 302A _ 41: 8B. 03
	add	r10, r9 				; 302D _ 4D: 01. CA
	imul	eax, r15d				; 3030 _ 41: 0F AF. C7
	cdq						; 3034 _ 99
	idiv	r8d					; 3035 _ 41: F7. F8
	mov	edx, dword [r11]			; 3038 _ 41: 8B. 13
; Note: Length-changing prefix causes delay on Intel processors
	mov	r8w, 512				; 303B _ 66 41: B8, 0200
	sub	edx, eax				; 3040 _ 29. C2
	mov	eax, dword [rsp+2CH]			; 3042 _ 8B. 44 24, 2C
	add	eax, edx				; 3046 _ 01. D0
	mov	dword [r11], eax			; 3048 _ 41: 89. 03
	mov	r9d, dword [r10]			; 304B _ 45: 8B. 0A
	mov	eax, r9d				; 304E _ 44: 89. C8
	imul	eax, r15d				; 3051 _ 41: 0F AF. C7
	cdq						; 3055 _ 99
	idiv	r8d					; 3056 _ 41: F7. F8
	sub	r9d, eax				; 3059 _ 41: 29. C1
	mov	r11d, r9d				; 305C _ 45: 89. CB
	add	r11d, r12d				; 305F _ 45: 01. E3
	cmp	dword [rsp+0A8H], esi			; 3062 _ 39. B4 24, 000000A8
	mov	dword [r10], r11d			; 3069 _ 45: 89. 1A
	jg	?_1098					; 306C _ 0F 8F, FFFFFF7B
	mov	r8d, dword [rsp+10H]			; 3072 _ 44: 8B. 44 24, 10
	jmp	text.hot0B11BH			      ; 3077 _ E9, 0000B11B(rel)

?_1099: ; Local function
	mov	rbx, qword [rsp+18H]			; 307C _ 48: 8B. 5C 24, 18
	xor	r12d, r12d				; 3081 _ 45: 31. E4
	mov	esi, 324				; 3084 _ BE, 00000144
	lea	r11, [rbx+4DCH] 			; 3089 _ 4C: 8D. 9B, 000004DC
?_1100: mov	r10, qword [rsp+0A0H]			; 3090 _ 4C: 8B. 94 24, 000000A0
	mov	r9d, dword [r10+r12*4]			; 3098 _ 47: 8B. 0C A2
	add	r12, 1					; 309C _ 49: 83. C4, 01
	mov	eax, r9d				; 30A0 _ 44: 89. C8
	and	r9d, 3FH				; 30A3 _ 41: 83. E1, 3F
	sar	eax, 6					; 30A7 _ C1. F8, 06
	and	eax, 3FH				; 30AA _ 83. E0, 3F
	mov	edx, dword [rcx+rax*4]			; 30AD _ 8B. 14 81
	shl	rdx, 8					; 30B0 _ 48: C1. E2, 08
	add	rdx, r11				; 30B4 _ 4C: 01. DA
	lea	rbx, [rdx+r9*4] 			; 30B7 _ 4A: 8D. 1C 8A
	mov	r9d, dword [rsp+2CH]			; 30BB _ 44: 8B. 4C 24, 2C
	mov	r10d, dword [rbx]			; 30C0 _ 44: 8B. 13
	mov	eax, r10d				; 30C3 _ 44: 89. D0
	imul	eax, r15d				; 30C6 _ 41: 0F AF. C7
	cdq						; 30CA _ 99
	idiv	esi					; 30CB _ F7. FE
	sub	r10d, eax				; 30CD _ 41: 29. C2
	add	r9d, r10d				; 30D0 _ 45: 01. D1
	cmp	dword [rsp+0A8H], r12d			; 30D3 _ 44: 39. A4 24, 000000A8
	mov	dword [rbx], r9d			; 30DB _ 44: 89. 0B
	jg	?_1100					; 30DE _ 7F, B0
	jmp	text.hot0B11BH			      ; 30E0 _ E9, 0000B11B(rel)

end if