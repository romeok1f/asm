GoDirection:	; in: ebx square
	;     cl  x coord
	;     ch  y coord
	; out: eax square ebx + (x,y) or 64 if rbx + (x,y) is off board

	       call   SquareToXY
		add   al, cl
		 js   .Fail
		cmp   al, 8
		jae   .Fail
		add   ah, ch
		 js   .Fail
		cmp   ah, 8
		jae   .Fail
		mov   ecx, 7
		and   ecx, eax
		shr   eax, 5
		 or   eax, ecx
		ret
     .Fail:	mov   eax, 64
		ret

SquareToXY:	; in: rbx square
	; out: al  x coord
	;      ah  y coord
		xor   eax, eax
		mov   al, bl
		and   al, 7
		mov   ah, bl
		shr   ah, 3
		ret




MoveGen_Init:
	       push   r15 r14 r13 r12


;for rook/bishop attacks the PDEP bitboard for a square s consists of all squares
;         that are attacked by a rook/bishop on square s on an otherwise empty board
;for rook/bishop attacks the PEXT bitboard, which is a subset of the PDEP bitboard, consists of those squares
;         that are necessary in determining which squares are actually attacked by a rook/bishop on square s on a non-empty chessboard
;the MASK array contains the actuall bitboards of attacks
; example: B means bishop, X means any piece
;
; suppose that the board is
;
; . . . . . . . .
; . X . . . . . .
; . X . . X . . .
; . X . . . . . .
; . . B . . . . .
; . . . . . . . .
; X X X X X X X X
; . . . . . . . .

; the PDEP bitboard for the bishop's square is
; . . . . . . 1 .
; . . . . . 1 . .
; 1 . . . 1 . . .
; . 1 . 1 . . . .
; . . . . . . . .
; . 1 . 1 . . . .
; 1 . . . 1 . . .
; . . . . . 1 . .

; the boarders are not necessary in determning attack info, so the PEXT bitboard is
; . . . . . . . .
; . . . . . 1 . .
; . . . . 1 . . .
; . 1 . 1 . . . .
; . . . . . . . .
; . 1 . 1 . . . .
; . . . . 1 . . .
; . . . . . . . .

;using the PEXT bitboard as a mask, extracting the bits in the bitboard of all pieces gives
; offset = pext(all pieces,PEXT board) = 1000110b
; this offset is used to lookup a pre-computed bitboard of attacks:
;
; . . . . . . . .
; . . . . . . . .
; . . . . 1 . . .
; . 1 . 1 . . . .
; . . . . . . . .
; . 1 . 1 . . . .
; 1 . . . 1 . . .
; . . . . . . . .
;
; these are the squares that are attacked by the bishop



; the magics are shamelessly copied from Gull
; of course there is error checking in the init code to make sure that they are correct
match =0, CPU_HAS_BMI2 {

Init_IMUL_SHIFT:
		lea   rdi, [SlidingAttackMasks]
		mov   ecx, 2*107648*4/8
		 or   rax, -1
	  rep stosq

		mov   ecx,64
		lea   rsi,[.RookSHIFT]
		lea   rdi,[RookAttacksSHIFT]
	  rep movsb

		mov   ecx, 64
		lea   rsi, [.BishopSHIFT]
		lea   rdi, [BishopAttacksSHIFT]
	  rep movsb

		mov   ecx, 64
		lea   rsi, [.RookIMUL]
		lea   rdi, [RookAttacksIMUL]
	  rep movsq

		mov   ecx, 64
		lea   rsi, [.BishopIMUL]
		lea   rdi, [BishopAttacksIMUL]
	  rep movsq

		jmp   .Done

.RookSHIFT: db	52, 53, 53, 53, 53, 53, 53, 52, \
	53, 54, 54, 54, 54, 54, 54, 53, \
	53, 54, 54, 54, 54, 54, 54, 53, \
	53, 54, 54, 54, 54, 54, 54, 53, \
	53, 54, 54, 54, 54, 54, 54, 53, \
	53, 54, 54, 54, 54, 54, 54, 53, \
	53, 54, 54, 54, 54, 54, 54, 53, \
	52, 53, 53, 53, 53, 53, 53, 52

.BishopSHIFT: db  58, 59, 59, 59, 59, 59, 59, 58, \
	  59, 59, 59, 59, 59, 59, 59, 59, \
	  59, 59, 57, 57, 57, 57, 59, 59, \
	  59, 59, 57, 55, 55, 57, 59, 59, \
	  59, 59, 57, 55, 55, 57, 59, 59, \
	  59, 59, 57, 57, 57, 57, 59, 59, \
	  59, 59, 59, 59, 59, 59, 59, 59, \
	  58, 59, 59, 59, 59, 59, 59, 58

.BishopIMUL: dq  0x0048610528020080, 0x00c4100212410004, 0x0004180181002010, 0x0004040188108502, 0x0012021008003040, 0x0002900420228000, 0x0080808410c00100, 0x000600410c500622, \
	 0x00c0056084140184, 0x0080608816830050, 0x00a010050200b0c0, 0x0000510400800181, 0x0000431040064009, 0x0000008820890a06, 0x0050028488184008, 0x00214a0104068200, \
	 0x004090100c080081, 0x000a002014012604, 0x0020402409002200, 0x008400c240128100, 0x0001000820084200, 0x0024c02201101144, 0x002401008088a800, 0x0003001045009000, \
	 0x0084200040981549, 0x0001188120080100, 0x0048050048044300, 0x0008080000820012, 0x0001001181004003, 0x0090038000445000, 0x0010820800a21000, 0x0044010108210110, \
	 0x0090241008204e30, 0x000c04204004c305, 0x0080804303300400, 0x00a0020080080080, 0x0000408020220200, 0x0000c08200010100, 0x0010008102022104, 0x0008148118008140, \
	 0x0008080414809028, 0x0005031010004318, 0x0000603048001008, 0x0008012018000100, 0x0000202028802901, 0x004011004b049180, 0x0022240b42081400, 0x00c4840c00400020, \
	 0x0084009219204000, 0x000080c802104000, 0x0002602201100282, 0x0002040821880020, 0x0002014008320080, 0x0002082078208004, 0x0009094800840082, 0x0020080200b1a010, \
	 0x0003440407051000, 0x000000220e100440, 0x00480220a4041204, 0x00c1800011084800, 0x000008021020a200, 0x0000414128092100, 0x0000042002024200, 0x0002081204004200

.RookIMUL:
  dq   0x00800011400080a6, 0x004000100120004e, 0x0080100008600082, 0x0080080016500080, 0x0080040008000280, 0x0080020005040080, 0x0080108046000100, 0x0080010000204080, \
       0x0010800424400082, 0x00004002c8201000, 0x000c802000100080, 0x00810010002100b8, 0x00ca808014000800, 0x0002002884900200, 0x0042002148041200, 0x00010000c200a100, \
       0x00008580004002a0, 0x0020004001403008, 0x0000820020411600, 0x0002120021401a00, 0x0024808044010800, 0x0022008100040080, 0x00004400094a8810, 0x0000020002814c21, \
       0x0011400280082080, 0x004a050e002080c0, 0x00101103002002c0, 0x0025020900201000, 0x0001001100042800, 0x0002008080022400, 0x000830440021081a, 0x0080004200010084, \
       0x00008000c9002104, 0x0090400081002900, 0x0080220082004010, 0x0001100101000820, 0x0000080011001500, 0x0010020080800400, 0x0034010224009048, 0x0002208412000841, \
       0x000040008020800c, 0x001000c460094000, 0x0020006101330040, 0x0000a30010010028, 0x0004080004008080, 0x0024000201004040, 0x0000300802440041, 0x00120400c08a0011, \
       0x0080006085004100, 0x0028600040100040, 0x00a0082110018080, 0x0010184200221200, 0x0040080005001100, 0x0004200440104801, 0x0080800900220080, 0x000a01140081c200, \
       0x0080044180110021, 0x0008804001001225, 0x00a00c4020010011, 0x00001000a0050009, 0x0011001800021025, 0x00c9000400620811, 0x0032009001080224, 0x001400810044086a

.Done:

}


Init_RookAttack_PDEP_PEXT:
		xor   r15d, r15d
.NextSquare:	mov   ebx, r15d
	       call   SquareToXY
		mov   edx, eax
		xor   r13, r13
		xor   r14d, r14d
.NextSquare2:	mov   ebx, r14d
	       call   SquareToXY
		cmp   al, dl
		jne   @f
		btc   r13, r14
	  @@:	cmp   ah, dh
		jne   @f
		btc   r13, r14
	  @@:	add   r14d, 1
		cmp   r14d, 64
		 jb   .NextSquare2
		mov   rax, not (Rank1BB or Rank8BB or FileABB or FileHBB)
		cmp   dh, 7
		jne   @f
		mov   rcx, Rank8BB
		 or   rax, rcx;[BitBoard_Rank8]
	  @@:	cmp   dh, 0
		jne   @f
		mov   rcx, Rank1BB
		 or   rax, rcx;[BitBoard_Rank1]
	  @@:	cmp   dl, 0
		jne   @f
		mov   rcx, FileABB
		 or   rax, rcx;[BitBoard_FileA]
	  @@:	cmp   dl, 7
		jne   @f
		mov   rcx, FileHBB
		 or   rax, rcx;[BitBoard_FileH]
	  @@:	mov   rcx, CornersBB
		and   rax, rcx;[BitBoard_Corners]
		and   rax, r13
		mov   qword[RookAttacksPDEP+8*r15], r13
		mov   qword[RookAttacksPEXT+8*r15], rax
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare


Init_BishopAttack_PDEP_PEXT:
		xor   r15d, r15d
.NextSquare:	mov   ebx, r15d
	       call   SquareToXY
		mov   edx, eax
		xor   r13, r13
		xor   r14d, r14d
.NextSquare2:	mov   ebx, r14d
	       call   SquareToXY
		mov   cl, dl
		add   cl, dh
		sub   cl, al
		sub   cl, ah
		jnz   @f
		btc   r13, r14
	  @@:	mov   cl, dl
		sub   cl, dh
		sub   cl, al
		add   cl, ah
		jnz   @f
		btc   r13, r14
	  @@:	add   r14d, 1
		cmp   r14d, 64
		 jb   .NextSquare2
		mov   rax, not (Rank1BB or Rank8BB or FileABB or FileHBB)
		and   rax, r13
		mov   qword[BishopAttacksPDEP+8*r15], r13
		mov   qword[BishopAttacksPEXT+8*r15], rax
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare




		lea   rdi,[SlidingAttackMasks]	; rdi will keep track of the addresses
Init_RookAttack_MASK:
		xor   r15d, r15d
.NextSquare:	mov   dword[RookAttacksMOFF+4*r15], edi
		xor   r14d, r14d
	     popcnt   rax, qword[RookAttacksPEXT+8*r15], rcx
		xor   r13, r13
		bts   r13, rax
.NextMask:
	      _pdep   r12, r14, qword[RookAttacksPEXT+8*r15], rax, rbx, rcx
		xor   r10, r10
		xor   r11d, r11d
.NextDirection: mov   r9, r15
		 or   r8, -1
		jmp   .Step
.NextStep:	xor   eax, eax
		bts   rax, r9
		and   rax, r8
		add   r10, rax
		 bt   r12, r9
		sbb   rax, rax
	       andn   r8, rax,r8
.Step:		mov   ebx, r9d
	      movzx   rcx, word[.Directions+2*r11]
	       call   GoDirection
		mov   r9d, eax
		cmp   eax, 64
		 jb   .NextStep
		add   r11d, 1
		cmp   r11d, 4
		 jb   .NextDirection

match =1, CPU_HAS_BMI2 {
		mov   rax, r10
	      stosq
}
match =0, CPU_HAS_BMI2 {
		mov   rax, r12
	       imul   rax, qword[RookAttacksIMUL+8*r15]
	      movzx   ecx, byte[RookAttacksSHIFT+r15]
		shr   rax, cl
		mov   edx, dword[RookAttacksMOFF+4*r15]
		cmp   qword[rdx+8*rax], -1
		jne   .Error
		mov   qword[rdx+8*rax], r10
		add   rdi,8
}
		add   r14d, 1
		cmp   r14d, r13d
		 jb   .NextMask
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare
		jmp   .Done
.Directions:	db +1, 0, -1, 0, 0, +1, 0, -1

.Error:
	       push   rdi
		lea   rdi, [Output]
		mov   rax, 'rook @: '
		mov   eax, r15d
	       call   PrintUnsignedInteger
		mov   ax, ', '
	      stosw
		mov   eax, r14d
	       call   PrintUnsignedInteger
		mov   ax, ', '
	      stosw
		mov   eax, r13d
	       call   PrintUnsignedInteger
		xor   eax, eax
	      stosd

		lea   rdi, [Output]
	       call   _ErrorBox
	       call   _ExitProcess



       .Done:

Init_BishopAttack_MASK:
		xor   r15d, r15d
.NextSquare:	mov   dword[BishopAttacksMOFF+4*r15], edi
		xor   r14d, r14d
	     popcnt   rax, qword[BishopAttacksPEXT+8*r15],rcx
		xor   r13, r13
		bts   r13, rax
.NextMask:
	      _pdep   r12, r14, qword[BishopAttacksPEXT+8*r15], rax, rbx, rcx
		xor   r10, r10
		xor   r11d, r11d
.NextDirection: mov   r9, r15
		 or   r8,-1
		jmp   .Step
.NextStep:	xor   eax, eax
		bts   rax, r9
		and   rax, r8
		add   r10, rax
		 bt   r12, r9
		sbb   rax, rax
	       andn   r8, rax, r8
.Step:		mov   ebx, r9d
	      movzx   rcx, word[.Directions+2*r11]
	       call   GoDirection
		mov   r9d, eax
		cmp   eax, 64
		 jb   .NextStep
		add   r11d, 1
		cmp   r11d, 4
		 jb   .NextDirection

match =1, CPU_HAS_BMI2 {
		mov   rax, r10
	      stosq
}
match =0, CPU_HAS_BMI2 {
		mov   rax, r12
	       imul   rax, qword[BishopAttacksIMUL+8*r15]
	      movzx   ecx, byte[BishopAttacksSHIFT+r15]
		shr   rax, cl
		mov   edx, dword[BishopAttacksMOFF+4*r15]
		cmp   qword[rdx+8*rax], -1
		jne   .Error
		mov   qword[rdx+8*rax], r10
		add   rdi, 8
}

		add   r14d, 1
		cmp   r14d, r13d
		 jb   .NextMask
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare
		jmp   .Done
.Directions:	db +1, +1, -1, +1, +1, -1, -1, -1
	@@:

.Error:
	       push   rdi
		lea   rdi, [Output]
		mov   rax, 'bishop @'
	      stosq
		mov   ax, ': '
	      stosw
		mov   eax, r15d
	       call   PrintUnsignedInteger
		mov   ax, ', '
	      stosw
		mov   eax, r14d
	       call   PrintUnsignedInteger
		mov   ax, ', '
	      stosw
		mov   eax, r13d
	       call   PrintUnsignedInteger
		xor   eax, eax
	      stosd

		lea   rdi, [Output]
	       call   _ErrorBox
	       call   _ExitProcess

.Done:
		cmp   rdi, SlidingAttackMasks+8*107648	 ; this should be the size of the table
		 je   .NoSlidingError
		lea   rdi,[.BigSizeError]
	       call   _ErrorBox
	       call   _ExitProcess
	 .BigSizeError: db 'error in calculating slinding attacks',0
.NoSlidingError:







Init_KnightAttacks:
		xor   r15d, r15d
.NextSquare:	xor   r14d, r14d
		xor   r13d, r13d
.NextDirection: mov   ebx, r15d
	      movzx   rcx, word[.Directions+2*r14]
	       call   GoDirection
		cmp   eax, 64
		jae   @f
		bts   r13, rax
	@@:	add   r14d, 1
		cmp   r14d, 8
		 jb   .NextDirection
		mov   qword[KnightAttacks+8*r15], r13
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare
		jmp   @f
.Directions:	db +2,+1, +2,-1, -2,+1, -2,-1, +1,+2, -1,+2, +1,-2, -1,-2
	@@:


Init_KingAttacks:
		xor   r15d, r15d
.NextSquare:	xor   r14d, r14d
		xor   r13d, r13d
.NextDirection: mov   ebx, r15d
	      movzx   rcx, word[.Directions+2*r14]
	       call   GoDirection
		cmp   eax, 64
		jae   @f
		bts   r13, rax
	@@:	add   r14d, 1
		cmp   r14d, 8
		 jb   .NextDirection
		mov   qword[KingAttacks+8*r15], r13
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare
		jmp   @f
.Directions:	db +1,+1, +1, 0, +1,-1,  0,+1,	0,-1, -1,+1, -1, 0, -1,-1
	@@:


Init_WhitePawnAttacks:
		xor   r15d, r15d
.NextSquare:	xor   r14d, r14d
		xor   r13d, r13d
.NextDirection: mov   ebx, r15d
	      movzx   rcx, word[.Directions+2*r14]
	       call   GoDirection
		cmp   eax, 64
		jae   @f
		bts   r13, rax
	@@:	add   r14d, 1
		cmp   r14d, 2
		 jb   .NextDirection
		mov   qword[WhitePawnAttacks+8*r15], r13
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare
		jmp   @f
.Directions:	db +1,+1, -1,+1
	@@:


Init_BlackPawnAttacks:
		xor   r15d, r15d
.NextSquare:	xor   r14d, r14d
		xor   r13d, r13d
.NextDirection: mov   ebx, r15d
	      movzx   rcx, word[.Directions+2*r14]
	       call   GoDirection
		cmp   eax, 64
		jae   @f
		bts   r13, rax
	@@:	add   r14d, 1
		cmp   r14d, 2
		 jb   .NextDirection
		mov   qword[BlackPawnAttacks+8*r15],r13
		add   r15d, 1
		cmp   r15d, 64
		 jb   .NextSquare
		jmp   @f
.Directions:	db +1,-1, -1,-1
	@@:

		pop  r12 r13 r14 r15
		ret

