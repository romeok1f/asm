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

SD_String db 'us:'
SD_Move rcx
SD_String db '|'



SD_String db 'qct'
SD_Int r9
SD_String db '|'

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

SD_String db 'pm:'
SD_Move rax
SD_String db '|'


		and   eax, 63
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
SD_String db 'mc'
SD_Int rax
SD_String db '|'

		cmp   eax, 1
		jne   .done
		mov   al, byte[rbx+State.capturedPiece]
	       test   al, al
		jnz   .done

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
