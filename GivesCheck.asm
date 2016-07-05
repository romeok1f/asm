;;;;;;;;;;;;;;;;;;
; Gives Check    ;
;;;;;;;;;;;;;;;;;;

	      align   64
GivesCheck:
	; in:  rbp  address of Pos
	;      rbx  address of State - check info must be filled in
	;      ecx  move
	; out: eax =  0 if does not give check
	;      eax = -1 if does give check
	;

	       push   rsi rdi
		mov   esi, dword[rbp+Pos.sideToMove]

		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63	; r8d = from
		mov   r9d, ecx
		and   r9d, 63	; r9d = to

	      movzx   r10d, byte[rbp+Pos.board+r8]     ; r10 = FROM PIECE
	     ; movzx   r11d, byte [rbp+Pos.board+r9]     ; r11 = TO PIECE
	      movzx   rdi, byte[rbx+State.ksq]

		 or   eax, -1

		xor   edx, edx
		bts   rdx, r9
		and   r10d, 7
	       test   rdx, qword[rbx+State.checkSq+8*r10]
		jnz   .Ret

		xor   edx, edx
		bts   rdx, r8
	       test   rdx, qword[rbx+State.dcCandidates]
		jnz   .DiscoveredCheck
.DiscoveredCheckRet:
		shr   ecx, 12
		xor   eax, eax
		cmp   ecx, MOVE_TYPE_PROM
		jae   .Special
.Ret:
		pop   rdi rsi
		ret

	      align   8
.Special:
		mov   rdx, qword[rbp+Pos.typeBB+8*White]
		 or   rdx, qword[rbp+Pos.typeBB+8*Black]
		btr   rdx, r8
		bts   rdx, r9

		mov   eax, dword[.JmpTable+4*rcx]
		lea   rax, [rax+GivesCheck]
		jmp   rax


align 8
.JmpTable:   dd .Error-GivesCheck
	     dd .Error-GivesCheck
	     dd .PromKnight-GivesCheck
	     dd .PromBishop-GivesCheck
	     dd .PromRook-GivesCheck
	     dd .PromQueen-GivesCheck
	     dd .Castling-GivesCheck
	     dd .EpCapture-GivesCheck


	      align   8
.Castling:
		mov   eax, r9d
		and   eax, 7
		cmp   eax, 4
		adc   esi, esi
	      movzx   eax, byte[castling_rfrom+rsi]
	      movzx   r11d, byte[castling_rto+rsi]
		btr   rdx, rax
		bts   rdx, r11
		bts   rdx, r9  ; set king again if nec
	RookAttacks   rax, r11, rdx, r10
		 bt   rax, rdi
		sbb   eax, eax
		pop   rdi rsi
		ret

	      align   8
.PromQueen:
      BishopAttacks   r8, r9, rdx, r10
	RookAttacks   rax, r9, rdx, r10
		 or   rax, r8
		 bt   rax, rdi
		sbb   eax, eax
		pop   rdi rsi
		ret

	      align   8
.EpCapture:
		lea   ecx, [2*rsi-1]
		lea   ecx, [r9+8*rcx]
		mov   r8, qword[rbp+Pos.typeBB+8*Bishop]
		mov   r9, qword[rbp+Pos.typeBB+8*Rook]
		btr   rdx, rcx
      BishopAttacks   rax, rdi, rdx, r10
	RookAttacks   r11, rdi, rdx, r10
		mov   r10, qword[rbp+Pos.typeBB+8*Queen]
		 or   r8, r10
		 or   r9, r10
		and   rax, r8
		and   r11, r9
		 or   rax, r11
		and   rax, qword[rbp+Pos.typeBB+8*rsi]
		neg   rax
		sbb   eax, eax
		pop   rdi rsi
		ret

	      align   8
.PromBishop:
      BishopAttacks   rax, r9, rdx, r10
		 bt   rax, rdi
		sbb   eax, eax
		pop   rdi rsi
		ret

	      align   8
.PromRook:
	RookAttacks   rax, r9, rdx, r10
		 bt   rax, rdi
		sbb   eax, eax
		pop   rdi rsi
		ret

	      align   8
.PromKnight:
		mov   rax, qword[KnightAttacks+8*r9]
		 bt   rax, rdi
		sbb   eax, eax
		pop   rdi rsi
		ret

	      align   8
.DiscoveredCheck:
		mov   eax, ecx
		and   eax, 64*64-1
		mov   rax, qword[LineBB+8*rax]
		 bt   rax, rdi
		 jc  .DiscoveredCheckRet
		 or   eax, -1
		pop   rdi rsi
		ret

.Error:
match =1, DEBUG {
                
}
               int3
