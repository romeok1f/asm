
; many bugs can be caught in DoMove
; we catch the caller of DoMove and make sure that the move is legal

	      align   16

Move_Do__UciParseMoves:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__UciParseMoves',0	   }

Move_Do__PerftGen_Root:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__PerftGen_Root',0	   }

Move_Do__PerftGen_Branch:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__PerftGen_Branch',0	     }

Move_Do__ExtractPonderFromTT:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__ExtractPonderFromTT',0		 }

Move_Do__Search:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__Search',0			 }

Move_Do__QSearch:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__QSearch',0			 }

Move_Do__EasyMoveMng:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__EasyMoveMng',0			 }

Move_Do__RootMove_InsertPVInTT:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__RootMove_InsertPVInTT',0	 }

Move_Do__ProbCut:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'DoMove__ProbCut',0	   }

Move_Do__Tablebase_ProbeAB:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_ProbeAB',0	      }

Move_Do__Tablebase_ProbeWDL:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_ProbeWDL',0	       }

Move_Do__Tablebase_ProbeDTZNoEP:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_ProbeDTZNoEP',0	   }

Move_Do__Tablebase_ProbeDTZNoEP_SuccessIsNeg_WdlIsPositive:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_ProbeDTZNoEP_SuccessIsNeg_WdlIsPositive',0	      }

Move_Do__Tablebase_ProbeDTZNoEP_SuccessIsNeg_WdlIsNonpositive:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_ProbeDTZNoEP_SuccessIsNeg_WdlIsNonpositive',0	 }

Move_Do__Tablebase_ProbeDTZ:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_ProbeDTZ',0	       }

Move_Do__Tablebase_RootProbe:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_RootProbe',0 	}

Move_Do__Tablebase_RootProbeWDL:
match =1, DEBUG {
lea	rax, [@f]
mov	[rbp+Pos.debugPointer], rax
jmp	Move_Do
@@: db 'Move_Do__Tablebase_RootProbeWDL',0	   }




Move_Do:
	; in: rbp  address of Pos
	;     rbx  address of State
	;     ecx  move
	;     edx  move is check

	       push   rsi rdi r12 r13 r14 r15
	       push   rcx rdx

match =1, DEBUG {
push	rcx rdx
sub	rsp, MAX_MOVES*sizeof.ExtMove
mov	dword[rbp+Pos.debugMove], ecx
lea	rdi, [DebugOutput]
mov	qword[rbp+Pos.state], rbx
call	Position_PrintSmall
mov	eax, 10
stosd
mov	qword[rbp+Pos.state], rbx
call	Position_IsLegal
test	eax, eax
jnz	Move_Do_posill
mov	ecx, dword[rbp+Pos.debugMove]
call	Move_IsPseudoLegal
test	rax, rax
jz	Move_Do_pillegal
mov	ecx, dword[rbp+Pos.debugMove]
call	Move_IsLegal
test	eax, eax
jz	Move_Do_illegal
mov	rdi, rsp
call	Gen_Legal
mov	rcx, rsp
@@:
cmp	rcx, rdi
jae	Move_Do_DoIllegal
mov	eax, dword[rbp+Pos.debugMove]
cmp	eax, dword[rcx]
lea	rcx, [rcx+sizeof.ExtMove]
jne	@b
add	rsp, MAX_MOVES*sizeof.ExtMove
pop	rdx rcx
}

match=2, VERBOSE {
push	rax rcx rsi rdi
mov	esi, ecx
lea	rdi, [VerboseOutput]
mov	rax, 'domove'
stosq
sub	rdi,2
movsxd	rax, dword[rbp+Pos.gamePly]
call	PrintSignedInteger
mov	al, ':'
stosb
mov	ecx, esi
xor	edx, edx
call	PrintUciMove
lea	rcx, [VerboseOutput]
call	_WriteOut
pop	rdi rsi rcx rax
add	dword[rbp+Pos.gamePly], 1	  ; gamePly is only used by search to init the timeman
}

		mov   esi, dword[rbp+Pos.sideToMove]

		mov   r15, qword[Zobrist_side]

		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63	; r8d = from
		mov   r9d, ecx
		and   r9d, 63	; r9d = to
		shr   ecx, 12

ProfileInc Move_Do
ProfileInc moveUnpack

	      movzx   r10d, byte[rbp+Pos.board+r8]     ; r10 = FROM PIECE
	      movzx   r11d, byte[rbp+Pos.board+r9]     ; r11 = TO PIECE

	       push   r10

		xor   r15, qword[rbx+State.key]
		mov   r14, qword[rbx+State.pawnKey]
		mov   r13, qword[rbx+State.materialKey]
	      vmovq   xmm0, qword[rbx+State.psq]       ; psq and npMaterial

		add   qword[rbp-Thread.rootPos+Thread.nodes], 1

	; update rule50 and pliesFromNull and capturedPiece
		mov   eax, dword[rbx+State.rule50]
		add   eax, 0x00010001
		mov   dword[rbx+sizeof.State+State.rule50], eax
		mov   byte[rbx+sizeof.State+State.capturedPiece], r11l

	; castling rights
	      movzx   edx, byte[rbx+State.castlingRights]
	      movzx   eax, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r8]
		 or   al, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r9]
		and   al, dl
		jnz   .Rights
.RightsRet:	mov   byte [rbx+sizeof.State+State.castlingRights], dl

	; ep square
	      movzx   eax, byte[rbx+State.epSquare]
		cmp   eax, 64
		 jb   .ResetEp
		mov   byte[rbx+sizeof.State+State.epSquare], al
.ResetEpRet:
	; capture
		mov   eax, r11d
		cmp   ecx, MOVE_TYPE_CASTLE
		 je   .Castling
		and   eax, 7
		jnz   .Capture
.CaptureRet:
	; move piece
		mov   r11d, r8d
		xor   r11d, r9d

		xor   edx, edx
		bts   rdx, r8
	       push   rdx
		bts   rdx, r9
	       push   rdx
		mov   eax, r10d
		and   eax, 7
		mov   byte[rbp+Pos.board+r8], 0
		mov   byte[rbp+Pos.board+r9], r10l
		xor   qword[rbp+Pos.typeBB+8*rax], rdx
		xor   qword[rbp+Pos.typeBB+8*rsi], rdx

	      movsx   rax, byte[IsPawnMasks+r10]
		and   r11d, eax
		shl   r10d, 6+3
		mov   rdx, qword[Zobrist_Pieces+r10+8*r8]
		xor   rdx, qword[Zobrist_Pieces+r10+8*r9]
	      vmovd   xmm1, dword[Scores_Pieces+r10+8*r8]
	      vmovd   xmm2, dword[Scores_Pieces+r10+8*r9]
		xor   r15, rdx
		and   rdx, rax
		xor   r14, rdx
	     vpsubd   xmm0, xmm0, xmm1
	     vpaddd   xmm0, xmm0, xmm2
		shr   r10d, 6+3

		not   eax
		and   word[rbx+sizeof.State+State.rule50], ax

	; special moves
		cmp   ecx, MOVE_TYPE_PROM
		jae   .Special
		cmp   r11d, 16
		 je   .DoublePawn
.SpecialRet:

	; write remaining data to next state entry

		pop   r9 r8 r10 rax rcx
	; r9 = to + from
	; r8 = from
	; r10 = from piece
	; rax = is check
	; ecx = move

		xor   esi, 1
		add   rbx, sizeof.State
		xor   r9, r8
		and   r10d, 7

		mov   dword[rbp+Pos.sideToMove], esi
		mov   qword[rbp+Pos.state], rbx

		mov   qword[rbx+State.key], r15
		mov   qword[rbx+State.pawnKey], r14
		mov   qword[rbx+State.materialKey], r13
	      vmovq   qword[rbx+State.psq], xmm0

match =2, VERBOSE {
movsx eax, word[rbx+State.rule50]
SD_Int rax
SD_String ','
movsx eax, word[rbx+State.pliesFromNull]
SD_Int rax
SD_String '|'
}

                mov   esi, dword[rbp+Pos.sideToMove]
                mov   r15, qword[rbp+Pos.typeBB+8*rsi]
                xor   esi, 1
                mov   r14, qword[rbp+Pos.typeBB+8*rsi]
                shl   esi, 6+3
                mov   r13, r15		; r13 = our pieces
                mov   r12, r14		; r12 = their pieces
                mov   rdi, r15
                 or   rdi, r14		; rdi = all pieces
                and   r15, qword[rbp+Pos.typeBB+8*King]
                and   r14, qword[rbp+Pos.typeBB+8*King]
                bsf   r15, r15		; r15 = our king
                bsf   r14, r14		; r14 = their king

	       test   rax, rax
		jnz   .MoveIsCheck
.CheckersDone:
		mov   qword[rbx+State.checkersBB], rax

match =1, DEBUG {
mov qword[rbp+Pos.state], rbx
call Position_IsLegal
test eax, eax
jnz Move_Do_post_posill
}
                jmp   SetCheckInfo.go


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	      align   8
.Capture:
		mov   r12d, r11d
		and   r12d, 8
	; remove piece r11(=r12+rax) on to square r9

match =1, DEBUG {
lea edx, [8*rsi]
cmp edx, r12d
je Move_Do_capself
cmp eax, King
je Move_Do_capking
}

		mov   rdi, qword[rbp+Pos.typeBB+r12]
		mov   rdx, qword[rbp+Pos.typeBB+8*rax]
		btr   rdi, r9
		btr   rdx, r9
		mov   qword[rbp+Pos.typeBB+r12], rdi
		mov   qword[rbp+Pos.typeBB+8*rax], rdx
		and   rdi, rdx
	     popcnt   rdi, rdi, rdx
	      movsx   rax, byte[IsPawnMasks+r11]
		shl   r11d, 6+3
		mov   rdx, qword[Zobrist_Pieces+r11+8*r9]
		xor   r15, rdx
		and   rax, rdx
		xor   r14, rax
		xor   r13, qword[Zobrist_Pieces+r11+8*rdi]
	      vmovq   xmm1, qword[Scores_Pieces+r11+8*r9]
	     vpsubd   xmm0, xmm0, xmm1
		shr   r11d, 6+3
		mov   word[rbx+sizeof.State+State.rule50], 0
		jmp   .CaptureRet


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	      align   8
.MoveIsCheck:
		mov   rdx, qword[rbx+State.dcCandidates-sizeof.State]
		mov   rax, qword[rbx+State.checkSq-sizeof.State+8*r10]
		cmp   ecx, 1 shl 12
		jae   .DoFull
		and   rax, r9
	       test   rdx, r8
		jnz   .DoFull
		mov   qword[rbx+State.checkersBB], rax
match =1, DEBUG {
mov qword[rbp+Pos.state], rbx
call Position_IsLegal
test eax, eax
jnz Move_Do_post_posill
}
                jmp   SetCheckInfo.go

.DoFull:
		mov   ecx, esi
                xor   ecx, 1 shl (6+3)

                mov   rax, qword[KingAttacks+8*r15]
                and   rax, qword[rbp+Pos.typeBB+8*King]

                mov   r8, qword[KnightAttacks+8*r15]
                and   r8, qword[rbp+Pos.typeBB+8*Knight]
                 or   rax, r8

                mov   r8, qword[WhitePawnAttacks+rcx+8*r15]
                and   r8, qword[rbp+Pos.typeBB+8*Pawn]
                 or   rax, r8

        RookAttacks   r8, r15, rdi, r9
                mov   r9, qword[rbp+Pos.typeBB+8*Rook]
                 or   r9, qword[rbp+Pos.typeBB+8*Queen]
                and   r8, r9
                 or   rax, r8

      BishopAttacks   r8, r15, rdi, r9
                mov   r9, qword[rbp+Pos.typeBB+8*Bishop]
                 or   r9, qword[rbp+Pos.typeBB+8*Queen]
                and   r8, r9
                 or   rax, r8

                and   rax, r12
		mov   qword[rbx+State.checkersBB], rax
match =1, DEBUG {
mov qword[rbp+Pos.state], rbx
call Position_IsLegal
test eax, eax
jnz Move_Do_post_posill
}
                jmp   SetCheckInfo.go

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	      align   8
.ResetEp:
		and   eax, 7
		xor   r15, qword[Zobrist_Ep+8*rax]
		mov   byte[rbx+sizeof.State+State.epSquare], 64
		jmp   .ResetEpRet


	      align   8
.Rights:
		xor   edx, eax
		xor   r15, qword[Zobrist_Castling+8*rax]
		jmp   .RightsRet

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	      align   8
.DoublePawn:
		mov   edx, esi
		shl   edx, 6+3
		add   r8d, r9d
		shr   r8d, 1
		mov   rax, qword[WhitePawnAttacks+rdx+8*r8]
		mov   edx, esi
		xor   edx, 1
		and   rax, qword[rbp+Pos.typeBB+8*Pawn]
	       test   rax, qword[rbp+Pos.typeBB+8*rdx]
		 jz   .SpecialRet
		mov   byte[rbx+State.epSquare+sizeof.State], r8l
		and   r8d, 7
		xor   r15, qword[Zobrist_Ep+8*r8]
		jmp   .SpecialRet


	      align   8
.Special:
		xor   edx, edx
		cmp   ecx, MOVE_TYPE_EPCAP
		 je   .EpCapture

.Promotion:
		lea   ecx, [rcx-MOVE_TYPE_PROM+8*rsi+Knight]
	; remove pawn r10 on square r9
		mov   rdx, qword[rbp+Pos.typeBB+8*Pawn]
		btr   rdx, r9
		mov   qword[rbp+Pos.typeBB+8*Pawn], rdx
		and   rdx, qword[rbp+Pos.typeBB+8*rsi]
	     popcnt   rax, rdx, r8
		shl   r10d, 6+3
		mov   rdx, qword[Zobrist_Pieces+r10+8*r9]
		xor   r15, rdx
		xor   r14, rdx
		xor   r13, qword[Zobrist_Pieces+r10+8*rax]
	      vmovq   xmm1, qword[Scores_Pieces+r10+8*r9]
	     vpsubd   xmm0, xmm0, xmm1
	; place piece ecx on square r9
		mov   eax, ecx
		and   eax, 7
		mov   rdx, qword[rbp+Pos.typeBB+8*rax]
		bts   rdx, r9
		mov   qword[rbp+Pos.typeBB+8*rax], rdx
		mov   byte[rbp+Pos.board+r9], cl
		and   rdx, qword [rbp+Pos.typeBB+8*rsi]
	     popcnt   rax, rdx, r8
		shl   ecx, 6+3
		xor   r15, qword[Zobrist_Pieces+rcx+8*r9]
		xor   r13, qword[Zobrist_Pieces+rcx+8*(rax-1)]
	      vmovq   xmm1, qword[Scores_Pieces+rcx+8*r9]
	     vpaddd   xmm0, xmm0, xmm1
		jmp   .SpecialRet



	      align   8
.EpCapture:
	; remove pawn r10^8 on square ecx=r9+8*(2*esi-1)
		lea   ecx, [2*rsi-1]
		lea   ecx, [r9+8*rcx]
		xor   r10, 8
		xor   esi, 1
		mov   rdx, qword[rbp+Pos.typeBB+8*Pawn]
		mov   rdi, qword[rbp+Pos.typeBB+8*rsi]
		btr   rdx, rcx
		btr   rdi, rcx
		mov   qword[rbp+Pos.typeBB+8*Pawn], rdx
		mov   qword[rbp+Pos.typeBB+8*rsi], rdi
		mov   byte[rbp+Pos.board+rcx], 0
		and   rdi, rdx
	     popcnt   rdi, rdi, rdx
		shl   r10d, 6+3
		mov   rdx, qword[Zobrist_Pieces+r10+8*rcx]
		xor   r15, rdx
		xor   r14, rdx
		xor   r13, qword[Zobrist_Pieces+r10+8*rdi]
	      vmovq   xmm1, qword[Scores_Pieces+r10+8*rcx]
	     vpsubd   xmm0, xmm0, xmm1
		lea   eax, [8*rsi+Pawn]
		mov   word[rbx+sizeof.State+State.rule50], 0
		mov   byte[rbx+sizeof.State+State.capturedPiece], al
		xor   esi, 1
		jmp   .SpecialRet


	      align   8
.Castling:
	; r8 = kfrom
	; r9 = rfrom
	; ecx = kto
	; edx = rto
	; r10 = ourking
	; r11 = our rook

match =1, DEBUG {
mov eax, dword[rbp+Pos.debugMove]
cmp eax, dword[rbp-Thread.rootPos+Thread.castling_movgen+8*rsi+0]
je @f
cmp eax, dword[rbp-Thread.rootPos+Thread.castling_movgen+8*rsi+4]
jne Move_Do_badcas
@@:
}
	       push   rax	    ; these are popped before exit
	       push   rax	    ;   and not used because move type is special

	; fix things caused by kingXrook encoding
		mov   byte[rbx+sizeof.State+State.capturedPiece], 0

	; move the pieces
		mov   edx, r8d
		and   edx, 56
		cmp   r9d, r8d
		sbb   eax, eax
		lea   ecx, [rdx+4*rax+FILE_G]
		lea   edx, [rdx+2*rax+FILE_F]
		lea   r11d, [r10-King+Rook]

		mov   byte[rbp+Pos.board+r8], 0
		mov   byte[rbp+Pos.board+r9], 0
		mov   byte[rbp+Pos.board+rcx], r10l
		mov   byte[rbp+Pos.board+rdx], r11l

		shl   r10d, 6+3
		shl   r11d, 6+3

	      vmovd   xmm1, dword[Scores_Pieces+r10+8*r8]
	      vmovd   xmm2, dword[Scores_Pieces+r11+8*r9]
		xor   r15, qword[Zobrist_Pieces+r10+8*r8]
		xor   r15, qword[Zobrist_Pieces+r11+8*r9]
	     vpsubd   xmm0, xmm0, xmm1
	     vpsubd   xmm0, xmm0, xmm2
	      vmovd   xmm1, dword[Scores_Pieces+r10+8*rcx]
	      vmovd   xmm2, dword[Scores_Pieces+r11+8*rdx]
		xor   r15, qword[Zobrist_Pieces+r10+8*rcx]
		xor   r15, qword[Zobrist_Pieces+r11+8*rdx]
	     vpaddd   xmm0, xmm0, xmm1
	     vpaddd   xmm0, xmm0, xmm2

		mov   rax, qword[rbp+Pos.typeBB+8*rsi]
		mov   r10, qword[rbp+Pos.typeBB+8*King]
		mov   r11, qword[rbp+Pos.typeBB+8*Rook]
		btr   rax, r8
		btr   rax, r9
		bts   rax, rcx
		bts   rax, rdx
		btr   r10, r8
		bts   r10, rcx
		btr   r11, r9
		bts   r11, rdx
		mov   qword[rbp+Pos.typeBB+8*rsi], rax
		mov   qword[rbp+Pos.typeBB+8*King], r10
		mov   qword[rbp+Pos.typeBB+8*Rook], r11
		jmp   .SpecialRet







match =1, DEBUG {

Move_Do_posill:
lea	rdi, [Output]
szcall	PrintString, 'position did not pass Position_IsLegal in DoMove'
jmp	Move_Do_GoError
Move_Do_pillegal:
lea	rdi, [Output]
szcall	PrintString, 'move did not pass IsMovePseudoLegal in DoMove'
jmp	Move_Do_GoError
Move_Do_illegal:
lea	rdi, [Output]
szcall	PrintString, 'move did not pass IsMoveLegal in DoMove'
jmp	Move_Do_GoError
Move_Do_DoIllegal:
lea	rdi, [Output]
szcall	PrintString, 'move not in legal list in DoMove'
jmp	Move_Do_GoError
Move_Do_badcas:
lea	rdi, [Output]
szcall	PrintString, 'bad castling in DoMove'
jmp	Move_Do_GoError
Move_Do_capself:
lea	rdi, [Output]
szcall	PrintString, 'capture self in DoMove'
jmp	Move_Do_GoError
Move_Do_capking:
lea	rdi, [Output]
szcall	PrintString, 'capture king in DoMove'
jmp	Move_Do_GoError
Move_Do_post_posill:
lea	rdi, [Output]
szcall	PrintString, 'position not legal after making'
jmp	Move_Do_GoError


Move_Do_GoError:
mov	al, 10
stosb
mov	rcx, qword[rbp+Pos.debugPointer]
call	PrintString
mov	al, 10
stosb
mov	rax, 'move:   '
mov	ecx, dword[rbp+Pos.debugMove]
mov	edx, dword[rbp+Pos.chess960]
call	PrintUciMoveLong
mov	al, 10
stosb
lea	rcx, [DebugOutput]
call	PrintString
xor	eax, eax
stosd
lea	rdi, [Output]
call	_ErrorBox
int3
}


