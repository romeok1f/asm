macro SliderBlockers result, sliders, s, pinners, pieces, queenRook, queenBishop, b, p, t, zero {

local ..YesPinners, ..NoPinners
	     Assert   e, result, 0, 'Assertion result=0 failed in slider_blockers'

		mov   p, qword[RookAttacksPDEP+8*s]
		and   p, queenRook
		mov   b, qword[BishopAttacksPDEP+8*s]
		and   b, queenBishop
		 or   p, b

		shl   s#d, 6+3
		lea   s, [BetweenBB+s]

		and   p, sliders
		mov   pinners, p
		 jz   ..NoPinners
..YesPinners:
		bsf   b, p
		mov   b, qword[s+8*b]
		and   b, pieces
		lea   t, [b-1]
	       test   t, b
	     cmovnz   b, zero
		 or   result, b
	       blsr   p, p, t
		jnz   ..YesPinners
..NoPinners:
}