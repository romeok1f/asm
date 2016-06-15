
PrintScore:
	push rbx
	mov ebx, ecx
	mov al, '('
	stosb
	mov  eax, ebx
	add  eax, 0x08000
	sar  eax, 16
	movsxd rax, eax
	call PrintSignedInteger
	mov  al, ','
	stosb
	movsx  rax, bx
	call PrintSignedInteger
	mov al, ')'
	stosb
	pop   rbx
	ret





macro EvalInit Us {
local Them, Down
local ..SetPinned, ..PinnedLoop, ..NotUsed

match =White, Us
\{
	Them	 equ Black
	Down	 equ DELTA_S
\}

match =Black, Us
\{
	Them	 equ White
	Down	 equ DELTA_N
\}

		mov   r15, qword[rbp+Pos.typeBB+8*King]
		and   r15, qword[rbp+Pos.typeBB+8*Us]
		bsf   r15, r15
		mov   dword[.ei.ksq+4*Us], r15d

		mov   rdi, qword[rbp+Pos.typeBB+8*Us]
		 or   rdi, qword[rbp+Pos.typeBB+8*Them]

		mov   r13, qword[rbp+Pos.typeBB+8*Rook]
		mov   r12, qword[rbp+Pos.typeBB+8*Bishop]
		 or   r13, qword[rbp+Pos.typeBB+8*Queen]
		 or   r12, qword[rbp+Pos.typeBB+8*Queen]

		mov   rax, qword[RookAttacksPDEP+8*r15]
		and   rax, r13
		mov   rcx, qword[BishopAttacksPDEP+8*r15]
		and   rcx, r12
		 or   rax, rcx
		xor   esi, esi
		and   rax, qword[rbp+Pos.typeBB+8*Them]
		 jz   ..SetPinned
..PinnedLoop:
		mov   edx, r15d
		shl   rdx, 6+3
		lea   rdx, [BetweenBB+rdx]
		bsf   rcx, rax
	@@:	mov   rcx, qword[rdx+8*rcx]
	       blsr   rax, rax, r9
		and   rcx, rdi
	       blsr   r8, rcx, r9
		neg   r8
		sbb   r8, r8
	       andn   rcx, r8, rcx
		 or   rsi, rcx
		bsf   rcx, rax
		jnz   ..PinnedLoop
		and   rsi, qword[rbp+Pos.typeBB+8*Us]
..SetPinned:
		mov   qword[.ei.pinnedPieces+8*Us], rsi

		mov   rdx, qword[rbp+Pos.typeBB+8*King]
		and   rdx, qword[rbp+Pos.typeBB+8*Them]
		bsf   rdx, rdx
		mov   rdx, qword[KingAttacks+8*rdx]
		mov   qword[.ei.attackedBy+8*(8*Them+King)], rdx
		 or   qword[.ei.attackedBy+8*(8*Them+0)], rdx
		mov   rdi, qword[.ei.pi]
		mov   rax, qword[rdi+PawnEntry.pawnAttacks+8*Us]
		mov   qword[.ei.attackedBy+8*(8*Us+Pawn)], rax
		 or   qword[.ei.attackedBy+8*(8*Us+0)], rax
	; rdx = b

	      movzx   eax, word[rbx+State.npMaterial+2*Us]
		xor   r8, r8
		xor   r9d, r9d
		cmp   eax, QueenValueMg
		 jb   ..NotUsed
		mov   r8, rdx
	   shift_bb   Down, r8
		 or   r8, rdx
		and   rdx, qword[.ei.attackedBy+8*(8*Us+Pawn)]
	     popcnt   r9, rdx, rcx
		xor   eax, eax
		mov   dword[.ei.kingAttackersWeight+4*Us], eax
		mov   dword[.ei.kingAdjacentZoneAttacksCount+4*Us], eax
..NotUsed:
		mov   qword[.ei.kingRing+8*Them], r8
		mov   dword[.ei.kingAttackersCount+4*Us], r9d

}







macro EvalPieces Us, Pt {
	; in  rbp address of Pos struct
	;     rbx address of State struct
	;     rsp address of evaluation info
local ..NextPiece, ..NoPinned, ..NoKingRing, ..AllDone
local ..OutpostElse, ..OutpostDone, ..NoBehindPawnBonus
local ..NoEnemyPawnBonus, ..NoOpenFileBonus, ..NoTrappedByKing
local ..SkipQueenPin, ..QueenPinLoop

match =White, Us \{
	Them	 equ Black
	OutpostRanks equ 0x0000FFFFFF000000
\}

match =Black, Us \{

	Them	 equ White
	OutpostRanks equ 0x000000FFFFFF0000
\}

	MinorBehindPawn equ ((16 shl 16) + (0))
	BishopPawns	equ ((8 shl 16) + (12))
	RookOnPawn	equ ((8 shl 16) + (24))
	RookOnFile0	equ ((20 shl 16) + (7))
	RookOnFile1	equ ((45 shl 16) + (20))
	TrappedRook	equ ((92 shl 16) + (0))


match =Knight, Pt \{
	Outpost0	  equ ((43 shl 16) + (11))
	Outpost1	  equ ((65 shl 16) + (20))
	ReachableOutpost0 equ ((21 shl 16) + (5) )
	ReachableOutpost1 equ ((35 shl 16) + (8) )
	KingAttackWeight equ 7
	MobilityBonus	 equ MobilityBonus_Knight
\}
match =Bishop, Pt \{
	Outpost0	  equ ((20 shl 16) + (3))
	Outpost1	  equ ((29 shl 16) + (8))
	ReachableOutpost0 equ ((8 shl 16) + (0) )
	ReachableOutpost1 equ ((14 shl 16) + (4))
	KingAttackWeight equ 5
	MobilityBonus	 equ MobilityBonus_Bishop
\}
match =Rook, Pt \{
	KingAttackWeight equ 4
	MobilityBonus	 equ MobilityBonus_Rook
\}
match =Queen, Pt \{
	KingAttackWeight equ 1
	MobilityBonus	 equ MobilityBonus_Queen
	WeakQueen	 equ ((35 shl 16) + (  0))
\}


		xor   r13d, r13d
		mov   qword[.ei.attackedBy+8*(8*Us+Pt)], r13
	; r13d also holds the score

VerboseDisplayScore r13


		mov   r15, qword[rbp+Pos.typeBB+8*Pt]
		and   r15, qword[rbp+Pos.typeBB+8*Us]
		 jz   ..AllDone
..NextPiece:
		bsf   r14, r15
	       blsr   r15, r15, rcx


VerboseDisplay db 'new piece'
VerboseDisplayInt r14

	; Find attacked squares, including x-ray attacks for bishops and rooks
    if Pt eq Knight
		mov   r12, qword[KnightAttacks+8*r14]
    else if Pt eq Bishop
		mov   rax, qword[rbp+Pos.typeBB+8*White]
		 or   rax, qword[rbp+Pos.typeBB+8*Black]
		mov   rcx, qword[rbp+Pos.typeBB+8*Queen]
		and   rcx, qword[rbp+Pos.typeBB+8*Us]
		xor   rax, rcx
      BishopAttacks   r12, r14, rax, rdx
    else if Pt eq Rook
		mov   rax, qword[rbp+Pos.typeBB+8*White]
		 or   rax, qword[rbp+Pos.typeBB+8*Black]
		mov   rcx, qword[rbp+Pos.typeBB+8*Queen]
		 or   rcx, qword[rbp+Pos.typeBB+8*Rook]
		and   rcx, qword[rbp+Pos.typeBB+8*Us]
		xor   rax, rcx
	RookAttacks   r12, r14, rax, rdx
    else if Pt eq Queen
		mov   r8, qword[rbp+Pos.typeBB+8*White]
		 or   r8, qword[rbp+Pos.typeBB+8*Black]
       QueenAttacks   r12, r14, r8, rax, rdx
    else
	  display 'bad Pt in EvalPieces'
	  display 13,10
	  err
    end if
		mov   rax, qword[.ei.pinnedPieces+8*Us]
		 bt   rax, r14
		jnc   ..NoPinned
		mov   eax, dword[.ei.ksq+4*Us]
		shl   eax, 6+3
		and   r12, qword[LineBB+rax+8*r14]
..NoPinned:

		mov   rax, qword[.ei.attackedBy+8*(8*Us+Pt)]
		 or   rax, r12
		mov   qword[.ei.attackedBy+8*(8*Us+Pt)], rax
		 or   qword[.ei.attackedBy+8*(8*Us+0)], rax

	       test   r12, qword[.ei.kingRing+8*Them]
		 jz   ..NoKingRing

		add   dword[.ei.kingAttackersCount+4*Us], 1
		add   dword[.ei.kingAttackersWeight+4*Us], KingAttackWeight
		mov   rax, qword[.ei.attackedBy+8*(8*Them+King)]
		and   rax, r12 
	     popcnt   rax, rax, rcx
		add   dword[.ei.kingAdjacentZoneAttacksCount+4*Us], eax
..NoKingRing:

    if Pt eq Queen
		mov   rax, qword[.ei.attackedBy+8*(8*Them+Knight)]
		 or   rax, qword[.ei.attackedBy+8*(8*Them+Bishop)]
		 or   rax, qword[.ei.attackedBy+8*(8*Them+Rook)]
	       andn   r12, rax, r12
    end if

VerboseDisplay db 'b='
VerboseDisplayBigInt r12

		mov   rax, qword[.ei.mobilityArea+8*Us]
VerboseDisplay db 'ma='
VerboseDisplayBigInt rax

		and   rax, r12
	     popcnt   r11, rax, rcx
		mov   eax, dword[MobilityBonus+4*r11]
		add   dword[.ei.mobility+4*Us], eax

VerboseDisplay db 'mob='
VerboseDisplayInt r11


if (Pt in <Knight, Bishop>)
	; Bonus for outpost squares

		mov   rdi, qword[.ei.pi]

VerboseDisplay db 'pas='
VerboseDisplayBigInt qword[rdi+PawnEntry.pawnAttacksSpan+8*Them]


		mov   rax, OutpostRanks
		mov   rdi, qword[.ei.pi]
		mov   rcx, qword[rdi+PawnEntry.pawnAttacksSpan+8*Them]
		not   rcx
		and   rcx, rax
		 bt   rcx, r14
		jnc   ..OutpostElse
		mov   rax, qword[.ei.attackedBy+8*(8*Us+Pawn)]
		 bt   rax, r14
		sbb   eax, eax
		and   eax, Outpost1-Outpost0
		lea   r13d, [r13+rax+Outpost0]
		jmp   ..OutpostDone
..OutpostElse:
		mov   rax, qword[rbp+Pos.typeBB+8*Us]
		not   rax
		and   rcx, rax
		and   rcx, r12

VerboseDisplayBigInt rcx

	       test   rcx, rcx
		 jz   ..OutpostDone
		and   rcx, qword[.ei.attackedBy+8*(8*Us+Pawn)]
		neg   rcx
		sbb   eax, eax
		and   eax, ReachableOutpost1-ReachableOutpost0
		lea   r13d, [r13+rax+ReachableOutpost0]
..OutpostDone:

VerboseDisplayScore r13


	; Bonus when behind a pawn
    if Us eq White
		cmp   r14d, SQ_A5
		jae   ..NoBehindPawnBonus
    else if Us eq Black
		cmp   r14d, SQ_A5
		 jb   ..NoBehindPawnBonus
    end if
		mov   rax, qword[rbp+Pos.typeBB+8*Pawn]
		lea   ecx, [r14+8*(1-2*Us)]
		 bt   rax, rcx
		sbb   eax, eax
		and   eax, MinorBehindPawn
		add   r13d, eax
..NoBehindPawnBonus:

VerboseDisplayScore r13


	; Penalty for pawns on the same color square as the bishop
    if Pt eq Bishop
		mov   rdi, qword[.ei.pi]
		xor   ecx, ecx
		mov   rax, DarkSquares
		 bt   rax, r14
		adc   rcx, rdi
	      movzx   eax, byte[rcx+PawnEntry.pawnsOnSquares+2*Us]
	       imul   eax, BishopPawns
		sub   r13d, eax

    end if

VerboseDisplayScore r13



else if Pt eq Rook

    if Us eq White
		cmp   r14d, SQ_A5
		 jb   ..NoEnemyPawnBonus
    else if Us eq Black
		cmp   r14d, SQ_A5
		jae   ..NoEnemyPawnBonus
    else
	  display 'bad Pt in EvalPieces'
	  display 13,10
	  err
    end if
		mov   rax, qword[rbp+Pos.typeBB+8*Them]
		and   rax, qword[rbp+Pos.typeBB+8*Pawn]
		and   rax, qword[RookAttacksPDEP+8*r14]
	     popcnt   rax, rax, rcx
	       imul   eax, RookOnPawn
		add   r13d, eax
..NoEnemyPawnBonus:


VerboseDisplayScore r13


		mov   ecx, r14d
		and   ecx, 7
		mov   rdi, qword[.ei.pi]
	      movzx   eax, byte[rdi+PawnEntry.semiopenFiles+1*Us]
	      movzx   edx, byte[rdi+PawnEntry.semiopenFiles+1*Them]
		 bt   eax, ecx
		jnc   ..NoOpenFileBonus
		 bt   edx, ecx
		sbb   eax, eax
		and   eax, RookOnFile1-RookOnFile0
		lea   r13d, [r13+rax+RookOnFile0]
		jmp   ..NoTrappedByKing
..NoOpenFileBonus:

VerboseDisplay <db 'inside mob <= 3',10>


		mov   ecx, r14d
		and   ecx, 7
		mov   eax, dword[.ei.ksq+4*Us]
		cmp   r11d, 4
		jae   ..NoTrappedByKing
		mov   edx, eax
		and   eax, 7
		sub   ecx, eax
		sub   eax, 4
		xor   ecx, eax
		 js   ..NoTrappedByKing
		mov   eax, dword[.ei.ksq+4*Us]
		shr   eax, 3
		mov   ecx, r14d
		shr   ecx, 3
		cmp   eax, ecx
		 je   @f
		mov   eax, dword[.ei.ksq+4*Us]
	if Us eq White
		cmp   eax, SQ_A2
		jae   ..NoTrappedByKing
	else if Us eq Black
		cmp   eax, SQ_A8
		 jb   ..NoTrappedByKing
	end if
	@@:
		mov   ecx, dword[.ei.ksq+4*Us]
		and   ecx, 7
		mov   edx, ecx
		mov   eax, r14d
		and   eax, 7
		sub   ecx, eax
		sar   ecx, 31
		sub   edx, ecx
		xor   eax, eax
		bts   eax, edx
		sub   eax, 1
		xor   eax, ecx
		mov   r8, qword[.ei.pi]
	       test   al, byte[r8+PawnEntry.semiopenFiles+1*Us]
		jnz   ..NoTrappedByKing
	      movzx   eax, byte[rbx+State.castlingRights]
		and   eax, 3 shl (2*Us)
	       setz   al
		add   eax, 1
	       imul   r11d, 22*65536
		sub   r11d, TrappedRook
	       imul   r11d, eax
		add   r13d, r11d
..NoTrappedByKing:

VerboseDisplayScore r13



else if Pt eq Queen
		mov   r8, r14
		xor   esi, esi
		mov   rax, qword[rbp+Pos.typeBB+8*Queen]
		 or   rax, qword[rbp+Pos.typeBB+8*Rook]
		and   rax, qword[RookAttacksPDEP+8*r8]
		mov   rcx, qword[rbp+Pos.typeBB+8*Queen]
		 or   rcx, qword[rbp+Pos.typeBB+8*Bishop]
		and   rcx, qword[BishopAttacksPDEP+8*r8]
		 or   rax, rcx
		mov   rdx, qword[rbp+Pos.typeBB+8*Rook]
		 or   rdx, qword[rbp+Pos.typeBB+8*Bishop]
		and   rdx, qword[rbp+Pos.typeBB+8*Them]
		and   rax, rdx
		 jz   ..SkipQueenPin
		shl   r8d, 6+3
		lea   rdx, [BetweenBB+r8]
		mov   r10, qword[rbp+Pos.typeBB+8*White]
		 or   r10, qword[rbp+Pos.typeBB+8*Black]
		bsf   rcx, rax
..QueenPinLoop:
		mov   rcx, qword[rdx+8*rcx]
	       blsr   rax, rax, r9
		and   rcx, r10
	       blsr   r8, rcx, r9
		neg   r8
		sbb   r8, r8
	       andn   rcx, r8, rcx
		 or   rsi, rcx
		bsf   rcx, rax
		jnz   ..QueenPinLoop
		and   rsi, r10
		neg   rsi
		sbb   esi, esi
		and   esi, WeakQueen
		sub   r13d, esi
..SkipQueenPin:


end if


	       test   r15 ,r15
		jnz   ..NextPiece

..AllDone:
	if Us eq White
		add   dword[.ei.score], r13d
	else if Us eq Black
		sub   dword[.ei.score], r13d
	end if


match =3, VERBOSE \{
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea rdi,[VerboseOutput]
szcall PrintString, ' evaluate_pieces<'
mov eax, Us
call PrintUnsignedInteger
mov ax, ', '
stosw
mov eax, Pt
call PrintUnsignedInteger
szcall PrintString, '>: '
mov ecx, r13d
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
\}

match =1, VERBOSE \{
		mov   dword[trace.Knight+4*(3*(Pt-Knight)+Us)], r13d

\}


restore Them
restore OutpostRanks
restore MinorBehindPawn
restore BishopPawns
restore RookOnPawn
restore RookOnFile0
restore RookOnFile1
restore TrappedRook
restore Outpost0
restore Outpost1
restore ReachableOutpost0
restore ReachableOutpost1
restore KingAttackWeight
restore MobilityBonus

}



macro EvalKing Us {
	; in  rbp address of Pos struct
	;     rbx address of State struct
	;     rsp address of evaluation info
local ..AllDone, ..KingSafetyDone, ..DoKingSafety, ..KingSafetyDoneRet
local ..NoQueenContactCheck
local ..NoKingSide, ..NoQueenSide, ..kingRingLoop, ..NoPawns
local ..ShelterStorm, ..FileLookUp

match =White, Us
\{
	Them  equ Black
	Up    equ DELTA_N
\}

match =Black, Us
\{
	Them  equ White
	Up    equ DELTA_S
\}

	QueenContactCheck equ 89
	QueenCheck  equ 62
	RookCheck   equ 57
	BishopCheck equ 48
	KnightCheck equ 78
	SafeCheck  equ	((20 shl 16) + (20))
	OtherCheck equ	((10 shl 16) + (10))


VerboseDisplay <db 'new king',10,0>
		mov   rdi, qword[.ei.pi]
		mov   ecx, dword[.ei.ksq+4*Us]
	      movzx   eax, byte[rbx+State.castlingRights]
	      movzx   edx, byte[rdi+PawnEntry.castlingRights]
		mov   esi, dword[rdi+PawnEntry.kingSafety+4*Us]
		cmp   cl, byte[rdi+PawnEntry.kingSquares+1*Us]
		jne   ..DoKingSafety
		xor   eax, edx
	       test   eax, 3 shl (2*Us)
		jne   ..DoKingSafety
..KingSafetyDoneRet:

match =2, VERBOSE \{
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea rdi,[VerboseOutput]
szcall PrintString, 'ks:'
mov ecx, esi
call PrintScore
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
\}


		mov   r11d, dword[.ei.kingAttackersCount+4*Them]
	       test   r11d, r11d
		 jz   ..AllDone

VerboseDisplay <db 'have king attackers',10,0>
VerboseDisplay db 'kingAttackersCount[Them]='
VerboseDisplayInt qword[.ei.kingAttackersCount+4*Them]
VerboseDisplay db 'kingAttackersWeight[Them]='
VerboseDisplayInt qword[.ei.kingAttackersWeight+4*Them]
VerboseDisplay db 'kingAdjacentZoneAttacksCount[Them]='
VerboseDisplayInt qword[.ei.kingAdjacentZoneAttacksCount+4*Them]


		mov   r8, qword[.ei.attackedBy+8*(8*Us+Pawn)]
		 or   r8, qword[.ei.attackedBy+8*(8*Us+Knight)]
		 or   r8, qword[.ei.attackedBy+8*(8*Us+Bishop)]
		 or   r8, qword[.ei.attackedBy+8*(8*Us+Rook)]
		 or   r8, qword[.ei.attackedBy+8*(8*Us+Queen)]
		not   r8
		and   r8, qword[.ei.attackedBy+8*(8*Us+King)]
		and   r8, qword[.ei.attackedBy+8*(8*Them+0)]
	; r8=undefended

		mov   r9, qword[rbp+Pos.typeBB+8*Them]
		 or   r9, qword[.ei.attackedBy+8*(8*Us+0)]
		not   r9
		and   r9, qword[.ei.kingRing+8*Us]
		and   r9, qword[.ei.attackedBy+8*(8*Them+0)]
	; r9=b

VerboseDisplay db 'undefended='
VerboseDisplayBigInt r8
VerboseDisplay db 'b='
VerboseDisplayBigInt r9

		mov   eax, 72
		mov   edi, dword[.ei.kingAttackersCount+4*Them]
	       imul   edi, dword[.ei.kingAttackersWeight+4*Them]
		cmp   edi, eax
	      cmovg   edi, eax
	       imul   eax, dword[.ei.kingAdjacentZoneAttacksCount+4*Them], 9
		add   edi, eax
	     popcnt   rax, r8, rcx
	       imul   eax, 21
		add   edi, eax
	     popcnt   rax, r9, rcx
		mov   rdx, qword[.ei.pinnedPieces+8*Us]
		neg   rdx
		adc   eax, 0
	       imul   eax, 12
		add   edi, eax
		mov   rax, qword[rbp+Pos.typeBB+8*Them]
		and   rax, qword[rbp+Pos.typeBB+8*Queen]
		cmp   rax, 1
		sbb   eax, eax
		and   eax, 64
		sub   edi, eax
		lea   eax, [rsi+0x08000]
		sar   eax, 16
		cdq
		and   edx, 7
		add   eax, edx
		sar   eax, 3
		sub   edi, eax
	; edi = attackUnits

VerboseDisplay <db 'au='>
VerboseDisplayInt rdi


		mov   r9, qword[rbp+Pos.typeBB+8*Them]
		not   r9
		and   r9, qword[.ei.attackedBy+8*(8*Them+Queen)]
		and   r9, r8
		 jz   ..NoQueenContactCheck
		mov   r10, qword[.ei.attackedBy+8*(8*Them+Pawn)]
		 or   r10, qword[.ei.attackedBy+8*(8*Them+Knight)]
		 or   r10, qword[.ei.attackedBy+8*(8*Them+Bishop)]
		 or   r10, qword[.ei.attackedBy+8*(8*Them+Rook)]
		 or   r10, qword[.ei.attackedBy+8*(8*Them+King)]
		and   r9, r10
	     popcnt   rax, r9, rcx
	       imul   eax, QueenContactCheck
		add   edi, eax
..NoQueenContactCheck:


VerboseDisplay <db 'au='>
VerboseDisplayInt rdi

	; lower 32 bits of rsi are for additional attackunits, which is always positive
		shl   rsi, 32


		mov   r8, qword[.ei.attackedBy+8*(8*Us+0)]
		 or   r8, qword[rbp+Pos.typeBB+8*Them]
		not   r8
	; r8 = safe
		mov   r9, qword[rbp+Pos.typeBB+8*Pawn]
		mov   rax, qword[rbp+Pos.typeBB+8*Them]
		and   rax, r9
	   shift_bb   Up, r9
		and   r9, rax
		 or   r9, qword[.ei.attackedBy+8*(8*Us+Pawn)]
		not   r9
	; r9 = other
		mov   eax, dword[.ei.ksq+4*Us]
		mov   r15, qword[rbp+Pos.typeBB+8*White]
		 or   r15, qword[rbp+Pos.typeBB+8*Black]
	RookAttacks   r10, rax, r15, rdx
	; r10 = b1 = pos.attacks_from<ROOK  >(ksq)
      BishopAttacks   r11, rax, r15, rdx
	; r11 = b1 = pos.attacks_from<BISHOP>(ksq)

		mov   rcx, ((-SafeCheck) shl 32) + QueenCheck
		mov   rax, r10
		 or   rax, r11
		and   rax, qword[.ei.attackedBy+8*(8*Them+Queen)]
		and   rax, r8
		neg   rax
		sbb   rax, rax
		and   rax, rcx
		add   rsi, rax

VerboseDisplay <db 'au='>
VerboseDisplayInt rsi
VerboseDisplayScoreHi rsi


		and   r10, qword[.ei.attackedBy+8*(8*Them+Rook)]
		mov   rcx, ((-SafeCheck) shl 32) + RookCheck
		mov   rax, r8
		and   rax, r10
		neg   rax
		sbb   rax, rax
		and   rcx, rax
		add   rsi, rcx
		mov   rcx, ((-OtherCheck) shl 32) + 0
		not   rax
		and   rax, r9
		and   rax, r10
		neg   rax
		sbb   rax, rax
		and   rcx, rax
		add   rsi, rcx
VerboseDisplay <db 'au='>
VerboseDisplayInt rsi
VerboseDisplayScoreHi rsi


		and   r11, qword[.ei.attackedBy+8*(8*Them+Bishop)]
		mov   rcx, ((-SafeCheck) shl 32) + BishopCheck
		mov   rax, r8
		and   rax, r11
		neg   rax
		sbb   rax, rax
		and   rcx, rax
		add   rsi, rcx
		mov   rcx, ((-OtherCheck) shl 32) + 0
		not   rax
		and   rax, r9
		and   rax, r11
		neg   rax
		sbb   rax, rax
		and   rcx, rax
		add   rsi, rcx
VerboseDisplay <db 'au='>
VerboseDisplayInt rsi
VerboseDisplayScoreHi rsi

		mov   edx, dword[.ei.ksq+4*Us]
		mov   r12, qword[KnightAttacks+8*rdx]
		and   r12, qword[.ei.attackedBy+8*(8*Them+Knight)]
		mov   rcx, ((-SafeCheck) shl 32) + KnightCheck
		mov   rax, r8
		and   rax, r12
		neg   rax
		sbb   rax, rax
		and   rcx, rax
		add   rsi, rcx
		mov   rcx, ((-OtherCheck) shl 32) + 0
		not   rax
		and   rax, r9
		and   rax, r12
		neg   rax
		sbb   rax, rax
		and   rcx, rax
		add   rsi, rcx
VerboseDisplay <db 'au='>
VerboseDisplayInt rsi
VerboseDisplayScoreHi rsi


		add   edi, esi
		shr   rsi, 32


		xor   eax, eax
		cmp   edi, eax
	      cmovl   edi, eax
		mov   eax, 399
		cmp   edi, eax
	      cmovg   edi, eax

		sub   esi, dword[KingDanger+4*rdi]


VerboseDisplayScore rsi


		jmp   ..AllDone

..DoKingSafety:
	; rdi = address of PawnEntry
		mov   ecx, dword[.ei.ksq+4*Us]
	      movzx   eax, byte[rbx+State.castlingRights]
	      movzx   edx, byte[rdi+PawnEntry.castlingRights]
		mov   r12d, eax
		and   eax, 3 shl (2*Us)
		and   edx, 3 shl (2*Them)
		add   edx, eax
		mov   byte[rdi+PawnEntry.kingSquares+1*Us], cl
		mov   byte[rdi+PawnEntry.castlingRights], dl

	       call   ..ShelterStorm
		mov   esi, eax

VerboseDisplay <db 'bonus='>
VerboseDisplayInt rsi


		mov   ecx, SQ_G1 + Us*(SQ_G8-SQ_G1)
	       test   r12d, 1 shl (2*Us+0)
		 jz   ..NoKingSide
	       call   ..ShelterStorm
		cmp   esi, eax
	      cmovl   esi, eax
..NoKingSide:
VerboseDisplay <db 'bonus='>
VerboseDisplayInt rsi

		mov   ecx, SQ_C1 + Us*(SQ_C8-SQ_C1)
	       test   r12d, 1 shl (2*Us+1)
		 jz   ..NoQueenSide
	       call   ..ShelterStorm
		cmp   esi, eax
	      cmovl   esi, eax
..NoQueenSide:

VerboseDisplay <db 'bonus='>
VerboseDisplayInt rsi


		shl   esi, 16
	; esi = score
		mov   ecx, dword[.ei.ksq+4*Us]
		shl   ecx, 3+3
		lea   rcx, [DistanceRingBB+rcx]
		mov   rdx, qword[rbp+Pos.typeBB+8*Us]
		and   rdx, qword[rbp+Pos.typeBB+8*Pawn]
		 jz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*0]
		jnz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*1]
		jnz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*2]
		jnz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*3]
		jnz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*4]
		jnz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*5]
		jnz   ..KingSafetyDone
		sub   esi, 16
	       test   rdx, qword[rcx+8*6]
		jnz   ..KingSafetyDone
		sub   esi, 16
match=1,DEBUG\{ and   rdx, qword[rcx+8*7] \}
	     Assert   ne, rdx, 0, 'assertion rdx !=0 failed in  ..DoKingSafety'
		jmp   ..KingSafetyDone

..KingSafetyDone:
		mov   dword[rdi+PawnEntry.kingSafety+4*Us], esi
		jmp   ..KingSafetyDoneRet


..ShelterStorm:
	; in: rbp position
	;     rbx state
	;     ecx ksq
	; out: eax saftey

	MaxSafetyBonus equ 258

	       push   rsi rdi r12 r13 r14 r15

		mov   r15d, ecx
	; r15 = ksq
		mov   r14d, ecx
		shr   r14d, 3
		mov   r8, qword[InFrontBB+8*(8*Us+r14)]
		 or   r8, qword[RankBB+8*r14]
		and   r8, qword[rbp+Pos.typeBB+8*Pawn]
	; r8 = b
		mov   r9, qword[rbp+Pos.typeBB+8*Us]
		and   r9, r8
	; r9 = ourPawns
		mov   r10, qword[rbp+Pos.typeBB+8*Them]
		and   r10, r8
	; r10 = theirPawns
		mov   eax, MaxSafetyBonus
	; eax = saftey
	if Us eq Black
		xor   r14d, 7
	end if
		add   r14d, 1
	; r14d = relative_rank(Us, ksq)+1

		mov   edi, r15d
		and   edi, 7
	      movzx   edi, byte[..FileLookUp+rdi]

rept 3 i \{
\local ..AddStormDanger

VerboseDisplay <db 'file='>
VerboseDisplayInt rdi

		mov   r13d, edi
		xor   r13d, 7
		cmp   r13d, edi
	      cmova   r13d, edi
	; r13d = std::min(f, FILE_H - f)
		shl   r13d, 3+2

		mov   r8, qword[FileBB+8*rdi]
		and   r8, r9
	if Us eq White
		xor   edx, edx
		bsf   r11, r8
	      cmovz   r11d, edx
		shr   r11d, 3
	else if Us eq Black
		mov   edx, 7 shl 3
		bsr   r11, r8
	      cmovz   r11d, edx
		shr   r11d, 3
		xor   r11d, 7
	end if
	; r11d = rkUs
VerboseDisplay <db 'rkUs='>
VerboseDisplayInt r11


		mov   r8, qword[FileBB+8*rdi]
		and   r8, r10
	if Us eq White
		xor   edx, edx
		bsf   r12, r8
	      cmovz   r12d, edx
		shr   r12d, 3
	else if Us eq Black
		mov   edx, 7 shl 3
		bsr   r12, r8
	      cmovz   r12d, edx
		shr   r12d, 3
		xor   r12d, 7
	end if
	; r12d = rkThem

VerboseDisplay <db 'rkThem='>
VerboseDisplayInt r12



		sub   eax, dword[ShelterWeakness+r13+4*r11]

VerboseDisplay <db '  sw='>
VerboseDisplayInt qword[ShelterWeakness+r13+4*r11]


		add   r11d, 1
	; r11d = rkUs+1

		lea   rsi, [StormDanger_BlockedByKing+r13]
		mov   edx, r15d
		and   edx, 7
		sub   edx, edi
		mov   ecx, r14d
		sub   ecx, r12d
		add   edi, 1
		 or   edx, ecx
		 jz   ..AddStormDanger
		lea   rsi, [StormDanger_NoFriendlyPawn+r13]
		cmp   r11d, 1
		 je   ..AddStormDanger
		lea   rsi, [StormDanger_BlockedByPawn+r13]
		cmp   r11d, r12d
		 je   ..AddStormDanger
		lea   rsi, [StormDanger_Unblocked+r13]
	..AddStormDanger:
		sub   eax, dword[rsi+4*r12]


VerboseDisplay <db '  sd='>
VerboseDisplayInt qword[rsi+4*r12]


\}

		pop   r15 r14 r13 r12 rdi rsi
		ret

..FileLookUp: db 0,0,1,2,3,4,5,5


..AllDone:
	if Us eq White
		add   dword[.ei.score], esi
	else if Us eq Black
		sub   dword[.ei.score], esi
	end if


match =3, VERBOSE \{
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea rdi,[VerboseOutput]
szcall PrintString, ' evaluate_king<'
mov eax, Us
call PrintUnsignedInteger
szcall PrintString, '>: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
\}

}


macro EvalThreats Us {
	; in: rbp position
	;     rbx state
	;     rsp evaluation info

local ..SafeThreatsDone, ..SafeThreatsLoop, ..WeakDone
local ..ThreatMinorLoop, ..ThreatMinorDone, ..ThreatRookLoop, ..ThreatRookDone

match =White, Us
\{
	Them  equ Black
	Up    equ DELTA_N
	Left  equ DELTA_NW
	Right equ DELTA_NE
	TRank2BB equ Rank2BB
	TRank7BB equ Rank7BB
\}

match =Black, Us
\{
	Them  equ White
	Up    equ DELTA_S
	Left  equ DELTA_SE
	Right equ DELTA_SW
	TRank2BB equ Rank7BB
	TRank7BB equ Rank2BB
\}

	LooseEnemies		equ (( 0 shl 16) + ( 25))
	ThreatByHangingPawn	equ ((71 shl 16) + ( 61))
	ThreatByKing0		equ (( 3 shl 16) + ( 62))
	ThreatByKing1		equ (( 9 shl 16) + (138))
	Hanging 		equ ((48 shl 16) + ( 27))
	ThreatByPawnPush	equ ((38 shl 16) + ( 22))


VerboseDisplay <db 'new threats',10,0>

		mov   rax, qword[.ei.attackedBy+8*(8*Us+0)]
		 or   rax, qword[.ei.attackedBy+8*(8*Them+0)]
		not   rax
		mov   rcx, qword[rbp+Pos.typeBB+8*Them]
		mov   rdx, qword[rbp+Pos.typeBB+8*Queen]
		 or   rdx, qword[rbp+Pos.typeBB+8*King]
		and   rdx, rcx
		xor   rdx, rcx
		and   rax, rdx
		neg   rax
		sbb   esi, esi
		and   esi, LooseEnemies
VerboseDisplayScore rsi



		mov   r8, qword[rbp+Pos.typeBB+8*Them]
		mov   r9, qword[rbp+Pos.typeBB+8*Pawn]
		and   r9, r8
		xor   r8, r9
		and   r8, qword[.ei.attackedBy+8*(8*Us+Pawn)]
	; r8 = weak
	       test   r8, r8
		 jz   ..SafeThreatsDone

		mov   rax, qword[.ei.attackedBy+8*(8*Them+0)]
		not   rax
		 or   rax, qword[.ei.attackedBy+8*(8*Us+0)]
		mov   rcx, qword[rbp+Pos.typeBB+8*Us]
		and   rcx, qword[rbp+Pos.typeBB+8*Pawn]
		and   rax, rcx
		mov   r9, rax
		mov   r10, rax
	   shift_bb   Right, r9, rcx
	   shift_bb   Left, r10, rcx
		 or   r9, r10
		and   r9, r8
	; r9 = safeThreats
		xor   r8, r9
		neg   r8
		sbb   eax, eax
		and   eax, ThreatByHangingPawn
		add   esi, eax

VerboseDisplay <db 'before loop '>
VerboseDisplayScore rsi
	       test   r9, r9
		 jz   ..SafeThreatsDone
..SafeThreatsLoop:
		bsf   rax, r9
	      movzx   eax, byte[rbp+Pos.board+rax]
		add   esi, dword[ThreatBySafePawn+4*rax]

VerboseDisplay <db 'inside loop '>
VerboseDisplayScore rsi

	       blsr   r9, r9, rcx
		jnz   ..SafeThreatsLoop
..SafeThreatsDone:

VerboseDisplayScore rsi

		mov   r8, qword[rbp+Pos.typeBB+8*Them]
		mov   r9, qword[rbp+Pos.typeBB+8*Pawn]
		and   r9, r8
		xor   r8, r9
		and   r8, qword[.ei.attackedBy+8*(8*Them+Pawn)]
	; r8 = defended
		mov   r9, qword[.ei.attackedBy+8*(8*Them+Pawn)]
		not   r9
		and   r9, qword[rbp+Pos.typeBB+8*Them]
		and   r9, qword[.ei.attackedBy+8*(8*Us+0)]
	; r9 = weak
		 or   r8, r9
	; r8 = defended | weak
		 jz   ..WeakDone
		mov   rax, qword[.ei.attackedBy+8*(8*Us+Knight)]
		 or   rax, qword[.ei.attackedBy+8*(8*Us+Bishop)]
		and   r8, rax
		 jz   ..ThreatMinorDone
..ThreatMinorLoop:
		bsf   rax, r8
	      movzx   eax, byte[rbp+Pos.board+rax]
		add   esi, dword[Threat_Minor+4*rax]
	       blsr   r8, r8, rcx
		jnz   ..ThreatMinorLoop
..ThreatMinorDone:

VerboseDisplayScore rsi

		mov   r10, qword[rbp+Pos.typeBB+8*Them]
		and   r10, qword[rbp+Pos.typeBB+8*Queen]
		 or   r10, r9
		and   r10, qword[.ei.attackedBy+8*(8*Us+Rook)]
		 jz   ..ThreatRookDone
..ThreatRookLoop:
		bsf   rax, r10
	      movzx   eax, byte[rbp+Pos.board+rax]
		add   esi, dword[Threat_Rook+4*rax]
	       blsr   r10, r10, rcx
		jnz   ..ThreatRookLoop
..ThreatRookDone:

VerboseDisplayScore rsi

		mov   rax, qword[.ei.attackedBy+8*(8*Them+0)]
		not   rax
		and   rax, r9
	     popcnt   rax, rax, rcx
	       imul   eax, Hanging
		add   esi, eax

VerboseDisplayScore rsi


		mov   r11, qword[.ei.attackedBy+8*(8*Us+King)]
		and   r11, r9
		mov   rdx, r11
		neg   rdx
		sbb   edx, edx
	       blsr   r11, r11, rcx
		neg   r11
		sbb   eax, eax
		and   eax, ThreatByKing1-ThreatByKing0
		add   eax, ThreatByKing0
		and   eax, edx
		add   esi, eax

..WeakDone:


VerboseDisplayScore rsi


		mov   rax, not TRank7BB
		and   rax, qword[rbp+Pos.typeBB+8*Us]
		and   rax, qword[rbp+Pos.typeBB+8*Pawn]

		mov   rcx, TRank2BB
		and   rcx, rax
	   shift_bb   Up, rcx
		mov   rdx, qword[rbp+Pos.typeBB+8*Us]
		 or   rdx, qword[rbp+Pos.typeBB+8*Them]
		not   rdx
		and   rcx, rdx
		 or   rax, rcx
	   shift_bb   Up, rax

		mov   rdx, qword[rbp+Pos.typeBB+8*Us]
		 or   rdx, qword[rbp+Pos.typeBB+8*Them]
		not   rdx
		and   rax, rdx
		mov   rcx, qword[.ei.attackedBy+8*(8*Them+Pawn)]
		not   rcx
		and   rax, rcx
		mov   rdx, qword[.ei.attackedBy+8*(8*Them+0)]
		not   rdx
		 or   rdx, qword[.ei.attackedBy+8*(8*Us+0)]
		and   rax, rdx

		mov   rdx, rax
	   shift_bb   Left, rax, rcx
	   shift_bb   Right, rdx, rcx
		 or   rax, rdx
		and   rax, qword[rbp+Pos.typeBB+8*Them]
		mov   rcx, qword[.ei.attackedBy+8*(8*Us+Pawn)]
		not   rcx
		and   rax, rcx
	     popcnt   rax, rax, rdx
	       imul   eax, ThreatByPawnPush
		add   esi, eax

VerboseDisplayScore rsi


	if Us eq White
		add   dword[.ei.score], esi
	else if Us eq Black
		sub   dword[.ei.score], esi
	end if


match =3, VERBOSE \{
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea rdi,[VerboseOutput]
szcall PrintString, ' evaluate_threats<'
mov eax, Us
call PrintUnsignedInteger
szcall PrintString, '>: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
\}



}






macro EvalPassedPawns Us {
	; in: rbp position
	;     rbx state
	;     rsp evaluation info

local ..NextPawn, ..AllDone, ..AddBonus, ..Continue

match =White, Us
\{
	Them  equ Black
	Up    equ DELTA_N
\}

match =Black, Us
\{
	Them  equ White
	Up    equ DELTA_S
\}
		mov   rdi, qword[.ei.pi]
		mov   r15, qword[rdi+PawnEntry.passedPawns+8*Us]
		xor   esi, esi
	       test   r15, r15
		 jz   ..AllDone
..NextPawn:
		bsf   rcx, r15
	       blsr   r15, r15, rax


VerboseDisplay <db ' passed pawn on '>
VerboseDisplayInt rcx


		mov   r12d,  ecx
		shr   r12d, 3
	if Us eq Black
		xor   r12d, 7
	end if
	; r12d = r+1
		add   esi, dword[PassedRank+4*r12]
		mov   eax, ecx
		and   eax, 7
		add   esi, dword[PassedFile+4*rax]

		lea   r13d, [r12-2]
		sub   r12d, 1
	       imul   r13d, r12d
	; r13d = rr = r*(r-1)

ED_String db 'r: '
ED_Int r12
ED_String db 10

ED_String db 'rr: '
ED_Int r13
ED_String db 10

		lea   r14d, [rcx+Up]
	; r14d = blockSq

	if Us eq White
		cmp   ecx, SQ_A4
		 jb   ..Continue
	else if Us eq Black
		cmp   ecx, SQ_A6
		jae   ..Continue
	end if

		mov   r8d, dword[.ei.ksq+4*Them]
		mov   r9d, dword[.ei.ksq+4*Us]
		shl   r8d, 6
		shl   r9d, 6
		xor   r10d, r10d
	      movzx   eax, byte[SquareDistance+r8+r14]
	      movzx   edx, byte[SquareDistance+r9+r14]
	      movzx   r11d, byte[SquareDistance+r9+r14+Up]
		lea   eax, [5*rax]
	if Us eq White
		cmp   ecx, SQ_A7
	      cmovb   r10d, r11d
	else if Us eq Black
		cmp   ecx, SQ_A3
	     cmovae   r10d, r11d
	end if
		lea   edx, [2*rdx+r10]
		sub   eax, edx
	       imul   eax, r13d
		add   esi, eax
VerboseDisplay <db 'total incr: '>
VerboseDisplayInt rax


		mov   r8, qword[rbp+Pos.typeBB+8*Us]
		mov   r9, qword[rbp+Pos.typeBB+8*Them]
		mov   r10, qword[ForwardBB+8*(64*Us+r14-Up)]
		lea   eax, [r13+2*r12]
		 bt   r8, r14
		 jc   ..AddBonus  ; the pawn is blocked by us
		mov   r11, r10
		mov   r12, r10
		 bt   r9, r14
		 jc   ..Continue  ; the pawn is blocked by them

		xor   r9, r8
	RookAttacks   rax, (r14-Up), r9, rdx
		xor   r9, r8
		mov   rcx, qword[rbp+Pos.typeBB+8*Rook]
		 or   rcx, qword[rbp+Pos.typeBB+8*Queen]
		and   rcx, qword[ForwardBB+8*(64*Them+r14-Up)]
		and   rax, rcx

		 or   rcx, -1
	       test   r8, rax
	      cmovz   rcx, qword[.ei.attackedBy+8*(8*Us+0)]
		and   r10, rcx

		 or   rcx, -1
	       test   r9, rax
	      cmovz   rcx, qword[.ei.attackedBy+8*(8*Them+0)]
		 or   rcx, r9
		and   r11, rcx

		 bt   r11, r14
		sbb   eax, eax
		neg   r11
		sbb   ecx, ecx
		lea   ecx, [5*rcx]
		lea   eax, [rcx+4*rax+9]
	; eax = k/2
		xor   ecx, ecx
		 bt   r10, r14
		adc   ecx, ecx
		xor   r10, qword[ForwardBB+8*(64*Us+r14-Up)]
		cmp   r10, 1
		adc   ecx, ecx
		add   eax, ecx
	; eax = k/2

ED_String db 'k/2: '
ED_Int rax
ED_String db 10


		add   r13d, r13d
	       imul   eax, r13d
..AddBonus:
	       imul   eax, 0x00010001
		add   esi, eax
..Continue:
	       test   r15, r15
		jnz   ..NextPawn

..AllDone:
	if Us eq White
		add   dword[.ei.score], esi
	else if Us eq Black
		sub   dword[.ei.score], esi
	end if


match =3, VERBOSE \{
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea rdi,[VerboseOutput]
szcall PrintString, ' evaluate_passed_pawns<'
mov eax, Us
call PrintUnsignedInteger
szcall PrintString, '>: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
\}


}









macro EvalSpace Us {
	; in: rbp position
	;     rbx state
	;     rsp evaluation info

match =White, Us
\{
	Them  equ Black
	SpaceMask  equ ((FileCBB or FileDBB or FileEBB or FileFBB) \
			and (Rank2BB or Rank3BB or Rank4BB))
\}

match =Black, Us
\{
	Them  equ White
	SpaceMask  equ ((FileCBB or FileDBB or FileEBB or FileFBB) \
			and (Rank7BB or Rank6BB or Rank5BB))

\}


		mov   rax, SpaceMask
		mov   rcx, qword[rbp+Pos.typeBB+8*Us]
		and   rcx, qword[rbp+Pos.typeBB+8*Pawn]
		not   rcx
		and   rax, rcx
		mov   rdx, qword[.ei.attackedBy+8*(8*Them+Pawn)]
		not   rdx
		and   rax, rdx
		mov   rcx, qword[.ei.attackedBy+8*(8*Them+0)]
		not   rcx
		 or   rcx, qword[.ei.attackedBy+8*(8*Us+0)]
		and   rax, rcx
	; rax = safe

VerboseDisplay <db 'safe='>
VerboseDisplayBigInt rax

		mov   rdx, qword[rbp+Pos.typeBB+8*Us]
		and   rdx, qword[rbp+Pos.typeBB+8*Pawn]
		mov   rcx, rdx
	if Us eq White
		shr   rdx, 8
		 or   rcx, rdx
		mov   rdx, rcx
		shr   rdx, 16
		 or   rcx, rdx
	else if Us eq Black
		shl   rdx, 8
		 or   rcx, rdx
		mov   rdx, rcx
		shl   rdx, 16
		 or   rcx, rdx
	end if
	; rcx = behind

		and   rcx, rax
	if Us eq White
		shl   rax, 32
	else if Us eq Black
		shr   rax, 32
	end if
		 or   rax, rcx
	     popcnt   rax, rax, rdx

		mov   rsi, qword[rbp+Pos.typeBB+8*Knight]
		 or   rsi, qword[rbp+Pos.typeBB+8*Bishop]
	     popcnt   rsi, rsi, rdx

VerboseDisplay <db 'bonus='>
VerboseDisplayInt rax
VerboseDisplay <db 'weight='>
VerboseDisplayInt rsi



	       imul   esi, esi
		add   esi, esi

	       imul   eax, esi
		xor   edx, edx
		mov   ecx, 11
	       idiv   ecx
		shl   eax, 16
	if Us eq White
		add   dword[.ei.score], eax
	else if Us eq Black
		sub   dword[.ei.score], eax
	end if

match =3, VERBOSE \{
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, ' evaluate_space<'
mov eax, Us
call PrintUnsignedInteger
szcall PrintString, '>: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
\}


}






	      align  64
Evaluate:
	; in  rbp address of Pos struct
	;     rbx address of State struct
	; out eax evaluation

	       push   rbx rsi rdi r12 r13 r14 r15
		sub   rsp, sizeof.EvalInfo
virtual at rsp
 .ei EvalInfo
end virtual

		mov   eax, dword[rbx+State.psq]
		mov   dword[.ei.score], eax



match =3, VERBOSE {
mov eax, dword[.ei.score]
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, 'psq score: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
}




		mov   rsi, qword[rbx+State.materialKey]
		and   esi, MATERIAL_HASH_ENTRY_COUNT-1
	       imul   esi, sizeof.MaterialEntry
		add   rsi, qword[rbp+Pos.materialTable]
		mov   rdx, qword[rsi+MaterialEntry.key]
	      movsx   eax, word[rsi+MaterialEntry.value]
	      movzx   ecx, byte[rsi+MaterialEntry.evaluationFunction]
		mov   qword[.ei.me], rsi
		cmp   rdx, qword[rbx+State.materialKey]
		jne   DoMaterialEval
.DoMaterialEvalReturn:
	       imul   eax, 0x00010001
		add   dword[.ei.score], eax


match =2, VERBOSE {
mov eax, dword[.ei.score]
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, 'imb:'
mov ecx, esi
call PrintScore
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
}


	       test   ecx, ecx
		jnz   .HaveSpecializedEval




		mov   rdi, qword[rbx+State.pawnKey]
		and   edi, PAWN_HASH_ENTRY_COUNT-1
	       imul   edi, sizeof.PawnEntry
		add   rdi, qword[rbp+Pos.pawnTable]
		mov   r15, qword[rdi+PawnEntry.key]
		mov   eax, dword[rdi+PawnEntry.score]
		mov   qword[.ei.pi], rdi
		cmp   r15, qword[rbx+State.pawnKey]
		jne   .DoPawnEval
.DoPawnEvalReturn:
		add   dword[.ei.score], eax


match =2, VERBOSE {
mov eax, dword[.ei.score]
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, 'ps:'
mov ecx, esi
call PrintScore
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
}


		xor   eax, eax
		mov   dword[.ei.mobility+4*0], eax
		mov   dword[.ei.mobility+4*1], eax
		mov   qword[.ei.attackedBy+8*0], rax
		mov   qword[.ei.attackedBy+8*8], rax
	   EvalInit   White
	   EvalInit   Black
		mov   r8, qword[rbp+Pos.typeBB+8*White]
		mov   r9, qword[rbp+Pos.typeBB+8*Black]
		mov   rcx, Rank2BB+Rank3BB
		mov   rsi, Rank7BB+Rank6BB
		mov   rax, r8
		 or   rax, r9
		mov   rdx, rax
	   shift_bb   DELTA_S, rax
	   shift_bb   DELTA_N, rdx
		and   r8, qword[rbp+Pos.typeBB+8*Pawn]
		and   r9, qword[rbp+Pos.typeBB+8*Pawn]
		 or   rax, rcx
		 or   rdx, rsi
		and   rax, r8
		and   rdx, r9
		mov   ecx, dword[.ei.ksq+4*White]
		mov   esi, dword[.ei.ksq+4*Black]
		 or   rax, qword[.ei.attackedBy+8*(8*Black+Pawn)]
		 or   rdx, qword[.ei.attackedBy+8*(8*White+Pawn)]
		bts   rax, rcx
		bts   rdx, rsi
		not   rax
		not   rdx
		mov   qword[.ei.mobilityArea+8*White], rax
		mov   qword[.ei.mobilityArea+8*Black], rdx


	 EvalPieces   White, Knight
	 EvalPieces   Black, Knight
	 EvalPieces   White, Bishop
	 EvalPieces   Black, Bishop
	 EvalPieces   White, Rook
	 EvalPieces   Black, Rook
	 EvalPieces   White, Queen
	 EvalPieces   Black, Queen
		mov   eax, dword[.ei.mobility+4*White]
		mov   ecx, dword[.ei.mobility+4*Black]
		sub   eax, ecx


match =3, VERBOSE {
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, 'mobility: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
}

		add   dword[.ei.score], eax

	   EvalKing   Black
	   EvalKing   White

	EvalThreats   Black
	EvalThreats   White

    EvalPassedPawns   White
    EvalPassedPawns   Black


    Unstoppable  equ ((0 shl 16) + (20))
		mov   r14, qword[.ei.pi]
		mov   eax, dword[rbx+State.npMaterial+2*0]
	       test   eax, eax
		jnz   .SkipUnstoppable
		mov   rcx, qword[r14+PawnEntry.passedPawns+8*White]
		mov   rdx, qword[r14+PawnEntry.passedPawns+8*Black]
		mov   eax, 0
		bsr   rcx, rcx
	      cmovz   ecx, eax
		shr   ecx, 3
		mov   eax, 7*8
		bsf   rdx, rdx
	      cmovz   edx, eax
		shr   edx, 3
		xor   edx, 7
		sub   ecx, edx
	       imul   ecx, Unstoppable
		add   dword[.ei.score], ecx

match =3, VERBOSE {
mov eax, dword[.ei.score]
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, 'Unstoppable score: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
}

.SkipUnstoppable:



	      movzx   eax, word[rbx+State.npMaterial+2*0]
	      movzx   ecx, word[rbx+State.npMaterial+2*1]
		add   eax, ecx
		cmp   eax, 12222
		 jb   .SkipSpace
	  EvalSpace   Black
	  EvalSpace   White
.SkipSpace:

	; Evaluate position potential for the winning side
		mov   r14, qword[.ei.pi]
	     popcnt   r9, qword[rbp+Pos.typeBB+8*Pawn], rcx




ED_String db 'pawns: '
ED_Int r9
ED_String db 10


	      movzx   edx, byte[r14+PawnEntry.asymmetry]

ED_String db 'asymmetry: '
ED_Int rdx
ED_String db 10


		lea   edx, [rdx+r9-15]
		shl   edx, 3
		lea   r9d, [rdx+4*r9]
	; r9d = 8*(asy+pawns-15)+4*pawns

		mov   esi, dword[.ei.score]
	      movsx   r10d, si


ED_String db 'eg: '
ED_Int r10
ED_String db 10


		sar   r10d, 31
		mov   r11d, r10d

		mov   eax, dword[.ei.ksq+4*White]
		mov   ecx, dword[.ei.ksq+4*Black]
		and   eax, 7
		and   ecx, 7
		sub   eax, ecx
		cdq
		xor   eax, edx
		sub   eax, edx
		mov   r8d, eax
		mov   eax, dword[.ei.ksq+4*White]
		mov   ecx, dword[.ei.ksq+4*Black]
		shr   eax, 3
		shr   ecx, 3
		sub   eax, ecx
		cdq
		xor   eax, edx
		sub   eax, edx
		sub   r8d, eax



		lea   eax, [r9+8*r8]
	; eax = initiative

ED_String db 'initiative: '
ED_Int rax
ED_String db 10

	      movsx   edx, si
		xor   edx, r11d
		sub   edx, r11d
		shr   edx, 1
		neg   edx
		cmp   eax, edx
	      cmovl   eax, edx
	; eax = std::max(initiative, -abs(eg / 2))
	       test   esi, 0x0FFFF
	      cmovz   r10d, eax
		xor   eax, r10d
		sub   eax, r11d
		add   esi, eax


match =3, VERBOSE {
push rdi rsi rax rcx rdx r8 r9 r10 r11
mov esi, eax
lea rdi,[VerboseOutput]
szcall PrintString, ' evaluate_initiative: '
mov ecx, esi
call PrintScore
mov al, 10
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop r11 r10 r9 r8 rdx rcx rax rsi rdi
}


ED_String db 'partial score: '
ED_Score rsi

	; esi = score
	; r14 = ei.pi
	; Evaluate scale factor for the winning side

		mov   r15, qword[.ei.me]
		xor   r13d, r13d
		 bt   esi, 15
		adc   r13d, r13d
	      movzx   ecx, byte[r15+MaterialEntry.scalingFunction+r13]
	      movzx   eax, byte[r15+MaterialEntry.factor+r13]
	      movzx   edx, byte[r15+MaterialEntry.gamePhase]
	      movsx   r12d, si
		add   esi, 0x08000
		sar   esi, 16
	       test   ecx, ecx
		jnz   .HaveScaleFunction
.HaveScaleFunctionReturn:
ED_String db ' ei.me->scale_factor(pos, strongSide): '
ED_Int rax
		lea   ecx, [rax-48]
		mov   r10, qword[rbp+Pos.typeBB+8*Bishop]
		mov   r8, qword[rbp+Pos.typeBB+8*White]
		mov   r9, qword[rbp+Pos.typeBB+8*Black]
		mov   edi, dword[rbx+State.npMaterial]
		and   r8, r10
		and   r9, r10
		cmp   edx, PHASE_MIDGAME
		jae   .ScaleFactorDone
		and   ecx, not 16
		jnz   .ScaleFactorDone
	       blsr   r8, r8, rcx
	       blsr   r9, r9, rcx
		mov   rcx, DarkSquares
	       test   rcx, r10
		 jz   .NotOppBishop
		mov   rcx, LightSquares
	       test   rcx, r10
		 jz   .NotOppBishop
		mov   rcx, qword[rbp+Pos.typeBB+8*Pawn]
		 or   r8, r9
		jnz   .NotOppBishop
	       blsr   rcx, rcx, r8
	       imul   eax, 46
		sar   eax, 6
		neg   rcx
		sbb   ecx, ecx
		and   ecx, 31-9
		add   ecx, 9
		cmp   edi, (BishopValueMg shl 16) + BishopValueMg
	      cmove   eax, ecx
		jmp   .ScaleFactorDone
.HaveScaleFunction:
		mov   eax, ecx
		shr   eax, 1
		mov   eax, dword[EndgameScale_FxnTable+4*rax]
		and   ecx, 1
	       call   rax
		cmp   eax, SCALE_FACTOR_NONE
	      movzx   edx, byte[r15+MaterialEntry.gamePhase]
	      movzx   ecx, byte[r15+MaterialEntry.factor+r13]
	      cmove   eax, ecx
		jmp   .HaveScaleFunctionReturn
.NotOppBishop:
	      movzx   ecx, byte[r14+PawnEntry.pawnSpan+r13]
		lea   r8d, [r12+BishopValueEg]
		cmp   r8d, 2*BishopValueEg
		 ja   .ScaleFactorDone
		sub   ecx, 1
		 ja   .ScaleFactorDone
		mov   r8, qword[rbp+Pos.typeBB+8*Pawn]
		and   r8, qword[rbp+Pos.typeBB+8*r13]
		xor   r13d, 1
		mov   r9d, dword[.ei.ksq+4*r13]
		shl   r13, 6+3
		and   ecx, 37-51
		add   ecx, 51
	       test   r8, qword[PassedPawnMask+r13+8*r9]
	     cmovnz   eax, ecx
.ScaleFactorDone:
	; eax = scale factor
	; edx = phase
	; esi = mg_score(score)
	; r12d = eg_value(score)
	; adjust score for side to move


match =3, VERBOSE {
push rsi rdi rax rcx rdx r14 r15
mov r15, rax
mov r14, rdx
lea rdi, [Output]
szcall PrintString, 'score: '
mov ecx, esi
shl ecx, 16
add ecx, r12d
call PrintScore
szcall PrintString, ' sf: '
movsxd rax, r15d
call PrintSignedInteger
szcall PrintString, ' phase: '
movsxd rax, r14d
call PrintSignedInteger
mov al, 10
stosb
call _WriteOut_Output
pop r15 r14 rdx rcx rax rdi rsi
}

	; the evaluation should be exactly symmetric
	;  hence the signed division by PHASE_MIDGAME*SCALE_FACTOR_NORMAL
	;  requires some care
	; example: x/16 = sar(x+7-sar(x,31),4)
	;  rounds to the nearest integer  with ties going towards zero
		mov   ecx, dword[rbp+Pos.sideToMove]
		mov   edi, ecx
		neg   ecx
	       imul   esi, edx
		shl   esi, 6
		neg   r12d
		sub   edx, PHASE_MIDGAME
	       imul   edx, r12d
	       imul   eax, edx
		add   eax, esi

		cdq
		add   eax, (1 shl 12) - 1
		sub   eax, edx
		sar   eax, 13
		xor   eax, ecx
		lea   eax, [rax+rdi+Eval_Tempo]


SD_String db 'eval:'
SD_Int rax
SD_String db '|'

		add   rsp, sizeof.EvalInfo
		pop   r15 r14 r13 r12 rdi rsi rbx
		ret


.DoPawnEval:
	  EvalPawns   White
		mov   dword[rdi+PawnEntry.score], esi
	  EvalPawns   Black
		mov   eax, dword[rdi+PawnEntry.score]
	      movzx   ecx, byte[rdi+PawnEntry.semiopenFiles+0]
	      movzx   edx, byte[rdi+PawnEntry.semiopenFiles+1]
		mov   r8, qword[rbx+State.pawnKey]
		xor   ecx, edx
	     popcnt   rcx, rcx, r9
		sub   eax, esi
		mov   qword[rdi+PawnEntry.key], r8
		mov   dword[rdi+PawnEntry.score], eax
		mov   byte[rdi+PawnEntry.asymmetry], cl
		jmp   .DoPawnEvalReturn


.HaveSpecializedEval:
		mov   eax, ecx
		shr   eax, 1
		mov   eax, dword[EndgameEval_FxnTable+4*rax]
		and   ecx, 1
	       call   rax
		add   rsp, sizeof.EvalInfo
		pop   r15 r14 r13 r12 rdi rsi rbx
		ret




	; this is rarely called and should preserve rdi,r12,r13,r14,r15 (as well as rbx and rbp)
DoMaterialEval:
	; in: rsi address of MaterialEntry
	;     rbp address of position
	;     rbx address of state
	;     rsp address of EvalInfo
	; out:       return is .DoMaterialEvalReturn
	;     eax  sign_ext(word[rsi+MaterialEntry.value])
	;     ecx  zero_ext(byte[rsi+MaterialEntry.evaluationFunction])
	       push   r12 r13 r14 r15

		mov   rcx, qword[rbx+State.materialKey]
	      movzx   r14d, word[rbx+State.npMaterial+2*0]
	      movzx   r15d, word[rbx+State.npMaterial+2*1]
		lea   r9d, [r14+r15]
		mov   r8d, MidgameLimit
		cmp   r9d, r8d
	      cmovg   r9d, r8d
		mov   r8d, EndgameLimit
		cmp   r9d, r8d
	      cmovl   r9d, r8d
		mov   r11d, 1518793581
		lea   r10d, [r9-0x0F9E]
		shl   r10d, 7
		mov   eax, r10d
		sar   r10d, 31
	       imul   r11d
		sar   edx, 12
		sub   edx, r10d

		xor   eax, eax
		mov   qword[rsi+MaterialEntry.key], rcx
		mov   byte[rsi+MaterialEntry.scalingFunction+0], al
		mov   byte[rsi+MaterialEntry.scalingFunction+1], al
		mov   byte[rsi+MaterialEntry.evaluationFunction], al
		mov   byte[rsi+MaterialEntry.gamePhase], dl
		mov   byte[rsi+MaterialEntry.factor+1*White], SCALE_FACTOR_NORMAL
		mov   byte[rsi+MaterialEntry.factor+1*Black], SCALE_FACTOR_NORMAL
		mov   word[rsi+MaterialEntry.value], ax


	; Let's look if we have a specialized evaluation function for this particular
	; material configuration. Firstly we look for a fixed configuration one, then
	; for a generic one if the previous search failed.
		lea   r10, [EndgameEval_Map]
		lea   r11, [EndgameEval_Map+2*ENDGAME_EVAL_MAP_SIZE*sizeof.EndgameMapEntry]
		lea   r13, [rsi+MaterialEntry.evaluationFunction]
.NextEvalKey:
		mov   rdx, qword[r10+EndgameMapEntry.key]
		mov   ecx, dword[r10+EndgameMapEntry.entry]
		add   r10, sizeof.EndgameMapEntry
		cmp   rdx, qword[rsi+MaterialEntry.key]
		 je   .FoundEvalFxn
		cmp   r10, r11
		 jb   .NextEvalKey
		mov   r8, qword[rbp+Pos.typeBB+8*Black]
		mov   r9, qword[rbp+Pos.typeBB+8*White]
.Try_KXK_White:
		mov   ecx, 2*EndgameEval_KXK_index
	       blsr   rdx, r8
		jnz   .Try_KXK_Black
		cmp   r14d, RookValueMg
		jge   .FoundEvalFxn
.Try_KXK_Black:
		add   ecx, 1
	       blsr   rdx, r9
		jnz   .Try_KXK_Done
		cmp   r15d, RookValueMg
		jge   .FoundEvalFxn
.Try_KXK_Done:


	; OK, we didn't find any special evaluation function for the current material
	; configuration. Is there a suitable specialized scaling function?
		lea   r10, [EndgameScale_Map]
		lea   r11, [EndgameScale_Map+2*ENDGAME_SCALE_MAP_SIZE*sizeof.EndgameMapEntry]
.NextScaleKey:
		mov   rdx, qword[r10+EndgameMapEntry.key]
		mov   ecx, dword[r10+EndgameMapEntry.entry]
		add   r10, sizeof.EndgameMapEntry
		cmp   rdx, qword[rsi+MaterialEntry.key]
		 je   .FoundScaleFxn
		cmp   r10, r11
		 jb   .NextScaleKey

		sub   rsp, 8*16
		jmp   .Continue

.FoundScaleFxn:
		mov   r13d, ecx
		and   r13d, 1
		lea   r13, [rsi+MaterialEntry.scalingFunction+r13]
		xor   eax, eax	; obey out condtions
		mov   byte[r13], cl
		xor   ecx, ecx
		pop   r15 r14 r13 r12
		jmp   Evaluate.DoMaterialEvalReturn
.FoundEvalFxn:
		xor   eax, eax	; obey out condtions
		mov   byte[r13], cl
		pop   r15 r14 r13 r12
		jmp   Evaluate.DoMaterialEvalReturn



.Continue:
	; We didn't find any specialized scaling function, so fall back on generic
	; ones that refer to more than one material distribution. Note that in this
	; case we don't return after setting the function.

		xor   r8d, r8d
.CountLoop:
		mov   rdx, qword[rbp+Pos.typeBB+r8]
		mov   rax, qword[rbp+Pos.typeBB+8*Pawn]
		and   rax, rdx
	     popcnt   rax, rax, rcx
		mov   dword[rsp+4*(r8+Pawn)], eax
		mov   rax, qword[rbp+Pos.typeBB+8*Knight]
		and   rax, rdx
	     popcnt   rax, rax, rcx
		mov   dword[rsp+4*(r8+Knight)], eax
		mov   rax, qword[rbp+Pos.typeBB+8*Bishop]
		and   rax, rdx
	     popcnt   rax, rax, rcx
		mov   dword[rsp+4*(r8+Bishop)], eax
		cmp   eax, 2
		sbb   eax, eax
		add   eax, 1
		mov   dword[rsp+4*(r8+1)], eax		    ; bishop pair
		mov   rax, qword[rbp+Pos.typeBB+8*Rook]
		and   rax, rdx
	     popcnt   rax, rax, rcx
		mov   dword[rsp+4*(r8+Rook)], eax
		mov   rax, qword[rbp+Pos.typeBB+8*Queen]
		and   rax, rdx
	     popcnt   rax, rax, rcx
		mov   dword[rsp+4*(r8+Queen)], eax

		add   r8d, 8
		cmp   r8d, 16
		 jb   .CountLoop


irps Us, White Black {
match =White, Us \{
	Them	 equ Black
	npMat	 equ r14d \}
match =Black, Us \{
	Them	 equ White
	npMat	 equ r15d\}
.Check_KBPsKs_#Us:
		cmp   npMat, BishopValueMg
		jne   .Check_KQKRPs_#Us
		mov   eax, dword[rsp+4*(8*Us+Bishop)]
		cmp   eax, 1
		jne   .Check_KQKRPs_#Us
		mov   eax, dword[rsp+4*(8*Us+Pawn)]
	       test   eax, eax
		 jz   .Check_KQKRPs_#Us
		mov   byte[rsi+MaterialEntry.scalingFunction+1*Us], 2*EndgameScale_KBPsK_index+Us
		jmp   .Check_sDone_#Us
.Check_KQKRPs_#Us:
		cmp   npMat, QueenValueMg
		jne   .Check_sDone_#Us
		mov   eax, dword[rsp+4*(8*Us+Pawn)]
	       test   eax, eax
		jnz   .Check_sDone_#Us
		mov   eax, dword[rsp+4*(8*Us+Queen)]
		cmp   eax, 1
		jne   .Check_sDone_#Us
		mov   eax, dword[rsp+4*(8*Them+Rook)]
		cmp   eax, 1
		jne   .Check_sDone_#Us
		mov   eax, dword[rsp+4*(8*Them+Pawn)]
	       test   eax, eax
		 jz   .Check_sDone_#Us
		mov   byte[rsi+MaterialEntry.scalingFunction+1*Us], 2*EndgameScale_KQKRPs_index+Us
.Check_sDone_#Us:
}



		mov   rax, qword[rbp+Pos.typeBB+8*Pawn]
	       test   r14d, r14d
		jnz   .NotOnlyPawns
	       test   r15d, r15d
		jnz   .NotOnlyPawns
	       test   rax, rax
		 jz   .NotOnlyPawns
.OnlyPawns:
		mov   ecx, dword[rsp+4*(8*Black+Pawn)]
		mov   eax, ((0) shl 16) + ((2*EndgameScale_KPsK_index+White) shl 0)
	       test   ecx, ecx
		 jz   .OnlyPawnsWrite
		mov   edx, dword[rsp+4*(8*White+Pawn)]
		mov   eax, (((2*EndgameScale_KPsK_index+Black)) shl 8) + ((0) shl 0)
	       test   edx, edx
		 jz   .OnlyPawnsWrite
		xor   eax, eax
		cmp   ecx, 1
		jne   .OnlyPawnsWrite
		cmp   edx, 1
		jne   .OnlyPawnsWrite
		mov   eax, (((2*EndgameScale_KPKP_index+Black)) shl 8) + ((2*EndgameScale_KPKP_index+White) shl 0)
.OnlyPawnsWrite:
		mov   word[rsi+MaterialEntry.scalingFunction], ax  ; write both entries
.NotOnlyPawns:

		mov   eax, dword[rsp+4*(8*White+Pawn)]
	       test   eax, eax
		jnz   .P1
		mov   ecx, r14d
		sub   ecx, r15d
		cmp   ecx, BishopValueMg
		 jg   .P1
		mov   eax, 14
		mov   ecx, 4
		cmp   r15d, BishopValueMg
	     cmovle   eax, ecx
		mov   ecx, SCALE_FACTOR_DRAW
		cmp   r14d, RookValueMg
	      cmovl   eax, ecx
		mov   byte[rsi+MaterialEntry.factor+1*White], al
.P1:
		mov   eax, dword[rsp+4*(8*Black+Pawn)]
	       test   eax, eax
		jnz   .P2
		mov   ecx, r15d
		sub   ecx, r14d
		cmp   ecx, BishopValueMg
		 jg   .P2
		mov   eax, 14
		mov   ecx, 4
		cmp   r14d, BishopValueMg
	     cmovle   eax, ecx
		mov   ecx, SCALE_FACTOR_DRAW
		cmp   r15d, RookValueMg
	      cmovl   eax, ecx
		mov   byte[rsi+MaterialEntry.factor+1*Black], al
.P2:
		mov   eax, dword[rsp+4*(8*White+Pawn)]
		cmp   eax, 1
		jne   .P3
		mov   ecx, r14d
		sub   ecx, r15d
		cmp   ecx, BishopValueMg
		 jg   .P3
		mov   byte[rsi+MaterialEntry.factor+1*White], SCALE_FACTOR_ONEPAWN
.P3:
		mov   eax, dword[rsp+4*(8*Black+Pawn)]
		cmp   eax, 1
		jne   .P4
		mov   ecx, r15d
		sub   ecx, r14d
		cmp   ecx, BishopValueMg
		 jg   .P4
		mov   byte[rsi+MaterialEntry.factor+1*Black], SCALE_FACTOR_ONEPAWN
.P4:



		lea   r8, [rsp+4*0]	;  pieceCount[Us]
		lea   r9, [rsp+4*8]	;  pieceCount[Them]
		xor   eax, eax		; bonus
		xor   r15d, r15d
.ColorLoop:
		xor   r10d, r10d	; partial index into quadatic
		mov   r14d, 1
 .Piece1Loop:
		mov   r11d, dword[.Linear+4*r14]	; v
		mov   r13d, 1

		cmp   dword[r8+4*r14], 0
		 je   .SkipPiece
  .Piece2Loop:
		mov   ecx, dword[.QuadraticOurs+r10+4*r13]
	       imul   ecx, dword[r8+4*r13]
		add   r11d, ecx
		mov   ecx, dword[.QuadraticTheirs+r10+4*r13]
	       imul   ecx, dword[r9+4*r13]
		add   r11d, ecx
		add   r13, 1
		cmp   r13d, r14d
		jbe   .Piece2Loop

		lea   edx, [2*r15-1]
	       imul   edx, dword[r8+4*r14]
	       imul   r11d, edx
		sub   eax, r11d
.SkipPiece:
		add   r14, 1
		add   r10d, 8*4
		cmp   r14d, Queen
		jbe   .Piece1Loop

	       xchg   r8, r9
		add   r15d, 1
		cmp   r15d, 2
		 jb   .ColorLoop

	; divide by 16, round towards zero
		cdq
		and   edx, 15
		add   eax, edx
		sar   eax, 4

		mov   word[rsi+MaterialEntry.value], ax
	      movzx   ecx, byte[rsi+MaterialEntry.evaluationFunction]

		add   rsp, 8*16
		pop   r15 r14 r13 r12
		jmp   Evaluate.DoMaterialEvalReturn


align 16
.Linear:
	dd 0, 1667, -168,-1027, -166,  238, -138,    0
.QuadraticOurs:
	dd 0,	 0,    0,    0,    0,	 0,    0,    0
	dd 0,	40,    2,    0,    0,	 0,    0,    0
	dd 0,	32,  255,   -3,    0,	 0,    0,    0
	dd 0,	 0,  104,    4,    0,	 0,    0,    0
	dd 0,  -26,   -2,   47,  105, -149,    0,    0
	dd 0, -185,   24,  122,  137, -134,    0,    0
.QuadraticTheirs:
	dd 0,	 0,    0,    0,    0,	 0,    0,    0
	dd 0,	36,    0,    0,    0,	 0,    0,    0
	dd 0,	 9,   63,    0,    0,	 0,    0,    0
	dd 0,	59,   65,   42,    0,	 0,    0,    0
	dd 0,	46,   39,   24,  -24,	 0,    0,    0
	dd 0,  101,  100,  -37,  141,  268,    0,    0


