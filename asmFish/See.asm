	      align   16, See.HaveFromTo
See:
	; in: rbp address of Pos
	;     ecx = capture move (preserved)
	;            type = 0 or MOVE_TYPE_EPCAP
	; out: eax > 0 good capture
	;      eax < 0 bad capture

	; r8 = from
	; r9 = to
		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63
		mov   r9d, ecx
		and   r9d, 63
.HaveFromTo:

ProfileInc See

	       push   r12 r13 r14 r15 rcx rsi rdi
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
	      vmovq   xmm0, r14
		btr   r14, r8

		cmp   ecx, MOVE_TYPE_CASTLE
		jae   .Special
.EpCaptureRet:
		xor   r13, 8
		mov   r11, [rbp+Pos.typeBB+r13]
	      vmovq   xmm1, r11
		mov   r13, qword[rbp+Pos.typeBB+8*Pawn]

	; king
		mov   r15, qword[KingAttacks+8*r9]
		and   r15, qword[rbp+Pos.typeBB+8*King]
	; pawn
		mov   rax, qword[BlackPawnAttacks+8*r9]
		and   rax, qword[rbp+Pos.typeBB+8*White]
		and   rax, r13
		 or   r15, rax
		mov   rax, qword[WhitePawnAttacks+8*r9]
		and   rax, qword[rbp+Pos.typeBB+8*Black]
		and   rax, r13
		 or   r15, rax
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

		mov   eax, dword[PieceValue_MG+4*r12]
		and   r11, r15
		 jz   .NoAttackers
.AttackerLoop:
		sub   eax, dword[rsp]
	       push   rax

	      vpxor   xmm1, xmm1, xmm0

		mov   eax, PawnValueMg
		mov   r12, r13
		and   r12, r11
		jnz   .FoundPawn

		mov   r12, qword[rbp+Pos.typeBB+8*Knight]
		and   r12, r11
		jnz   .FoundKnight

		mov   eax, BishopValueMg
		mov   r12, qword[rbp+Pos.typeBB+8*Bishop]
		and   r12, r11
		jnz   .FoundBishop

		mov   r12, qword[rbp+Pos.typeBB+8*Rook]
	       test   rdi, r11
		jnz   .FoundRookOrQueen

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
		pop   rdi rsi rcx r15 r14 r13 r12
SD_String 'see:'
SD_Int rax
SD_String '|'
		ret


	      align   8

.FoundRookOrQueen:
		and   r12, r11
		jnz   .FoundRook

		mov   r12, qword[rbp+Pos.typeBB+8*Queen]
		and   r12, r11
.FoundQueen:
	       blsi   r12, r12, rcx
		xor   r14, r12
	      vmovq   r11, xmm1
		mov   eax, QueenValueMg

      BishopAttacks   rdx, r9, r14, r10
		and   rdx, rsi
		 or   r15, rdx
		jmp   .QueenContinue

	      align   8
.FoundRook:
	       blsi   r12, r12, rcx
		xor   r14, r12
	      vmovq   r11, xmm1
		mov   eax, RookValueMg

.QueenContinue:
	RookAttacks   rdx, r9, r14, r10
		and   rdx, rdi
		 or   r15, rdx

		and   r15, r14

		and   r11, r15
		jnz   .AttackerLoop
		jmp   .SwapDone


	      align   8
.FoundBishop:
.FoundPawn:
	       blsi   r12, r12, rcx
		xor   r14, r12
	      vmovq   r11, xmm1

      BishopAttacks   rdx, r9, r14, r10
		and   rdx, rsi
		 or   r15, rdx

		and   r15, r14

		and   r11, r15
		jnz   .AttackerLoop
		jmp   .SwapDone



	      align   8
.FoundKnight:
	       blsi   r12, r12, rcx
		xor   r14, r12
	      vmovq   r11, xmm1
		mov   eax, KnightValueMg

		and   r15, r14

		and   r11, r15
		jnz   .AttackerLoop
		jmp   .SwapDone


	      align   8
.Special:
		cmp   ecx, MOVE_TYPE_CASTLE
		 je   .Castle
.EpCapture:
		lea   eax, [r9+2*r13-8]
		btr   r14, rax
		mov   dword[rsp], PawnValueMg
		jmp   .EpCaptureRet


.Castle:
		pop   rax
		xor   eax, eax
		pop   rbx
		pop   rdi rsi rcx r15 r14 r13 r12
SD_String 'see:'
SD_Int rax
SD_String '|'
		ret




