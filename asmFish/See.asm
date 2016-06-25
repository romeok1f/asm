		      align  16
See:
	; in: rbp address of Pos
	;     ecx = capture move (preserved)
	;            type = 0 or MOVE_TYPE_EPCAP
	; out: eax > 0 good capture
	;      eax < 0 bad capture

	; r8 = from
	; r9 = t0
		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63
		mov   r9d, ecx
		and   r9d, 63

	       push   rcx rsi rdi r12 r13 r14 r15
	       push   rbx
		mov   rbx, rsp

		shr   ecx, 12

	; rsi = bishops + queens
	; rdi = rooks + queens
		mov   rax, qword[rbp+Pos.typeBB+8*Queen]
		mov   rsi, qword[rbp+Pos.typeBB+8*Bishop]
		mov   rdi, qword[rbp+Pos.typeBB+8*Rook]
		 or   rdi, rax
		 or   rsi, rax

	; r12d = type
	; r13d = (side to move) *8
	      movzx   r12d, byte[rbp+Pos.board+r8]
		mov   r13d, r12d
		and   r12d, 7
		and   r13d, 8

	; set initial gain
	      movzx   eax, byte[rbp+Pos.board+r9]
		mov   eax, dword[PieceValue_MG+4*rax]
	       push   rax

	; r14 = occupied
	; r15 = attackers

		mov   r14, qword[rbp+Pos.typeBB+8*White]
		 or   r14, qword[rbp+Pos.typeBB+8*Black]
		btr   r14, r8

		cmp   ecx, _MOVE_TYPE_CASTLE
		jae   .Special
.EpCaptureRet:

	; king
		mov   r15, qword[KingAttacks+8*r9]
		and   r15, qword[rbp+Pos.typeBB+8*King]
	; pawn
		mov   rax, qword[BlackPawnAttacks+8*r9]
		and   rax, qword[rbp+Pos.typeBB+8*White]
		and   rax, qword[rbp+Pos.typeBB+8*Pawn]
		 or   r15,rax
		mov   rax, qword[WhitePawnAttacks+8*r9]
		and   rax, qword[rbp+Pos.typeBB+8*Black]
		and   rax, qword[rbp+Pos.typeBB+8*Pawn]
		 or   r15,rax
	; knight
		mov   rax, qword[KnightAttacks+8*r9]
		and   rax, qword[rbp+Pos.typeBB+8*Knight]
		 or   r15, rax
	; rook + queen
	RookAttacks   rdx, r9, r14, r10
		and   rdx, rdi
		 or   r15, rdx
	; bishop + queen
      BishopAttacks   rdx, r9, r14, r10
		and   rdx, rsi
		 or   r15, rdx

		and   r15, r14

		xor   r13, 8
		mov   r11, [rbp+Pos.typeBB+r13]
		and   r11, r15
		 jz   .NoAttackers
.AttackerLoop:
		mov   eax, dword[PieceValue_MG+4*r12]
		sub   eax, dword[rsp]
	       push   rax

		mov   r12d, Pawn
		mov   rax, qword[rbp+Pos.typeBB+8*Pawn]
		and   rax, r11
		jnz   .FoundPawn
		mov   r12d, Knight
		mov   rax, qword[rbp+Pos.typeBB+8*Knight]
		and   rax, r11
		jnz   .FoundBishop
		mov   r12d, Bishop
		mov   rax, qword[rbp+Pos.typeBB+8*Bishop]
		and   rax, r11
		jnz   .FoundBishop
		mov   r12d, Rook
		mov   rax, qword[rbp+Pos.typeBB+8*Rook]
		and   rax, r11
		jnz   .FoundRook
		mov   r12d, Queen
		mov   rax, qword[rbp+Pos.typeBB+8*Queen]
		and   rax, r11
		jnz   .FoundQueen
		cmp   r15, r11
		 je   .SwapDone
		pop   rax
.NoAttackers:
.SwapDone:
		pop   rax
		cmp   rsp, rbx
		jae   .Return
.PopLoop:	pop   rcx
		neg   eax
		cmp   eax, ecx
	      cmovg   eax, ecx
		cmp   rsp, rbx
		 jb   .PopLoop
.Return:
		pop   rbx
		pop   r15 r14 r13 r12 rdi rsi rcx
		ret


	      align   8
.FoundKnight:
	       blsi   rax, rax, rcx
		xor   r14, rax

		and   r15, r14

		xor   r13, 8
		mov   r11, qword[rbp+Pos.typeBB+r13]
		and   r11, r15
		jnz   .AttackerLoop
		jmp   .SwapDone


	      align   8
.FoundBishop:
.FoundPawn:
	       blsi   rax, rax, rcx
		xor   r14, rax
      BishopAttacks   rdx, r9, r14, r10
		and   rdx, rsi
		 or   r15, rdx

		and   r15, r14

		xor   r13, 8
		mov   r11, qword[rbp+Pos.typeBB+r13]
		and   r11, r15
		jnz   .AttackerLoop
		jmp   .SwapDone


	      align   8
.FoundQueen:
	       blsi   rax, rax, rcx
		xor   r14, rax
      BishopAttacks   rdx, r9, r14, r10
		and   rdx, rsi
		 or   r15, rdx
		jmp   @f


	      align   8
.FoundRook:
	       blsi   rax, rax, rcx
		xor   r14, rax
	@@:
	RookAttacks   rdx, r9, r14, r10
		and   rdx, rdi
		 or   r15, rdx

		and   r15, r14

		xor   r13, 8
		mov   r11, qword[rbp+Pos.typeBB+r13]
		and   r11, r15
		jnz   .AttackerLoop
		jmp   .SwapDone


	      align   8
.Special:
		cmp   ecx, _MOVE_TYPE_CASTLE
		 je   .Castle
.EpCapture:
		lea   eax, [r9+2*r13-8]
		btr   r14 ,rax
		mov   dword[rsp], PawnValueMg
		jmp   .EpCaptureRet


.Castle:
		pop   rax
		xor   eax, eax
		pop   rbx
		pop   r15 r14 r13 r12 rdi rsi rcx
		ret




