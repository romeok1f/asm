;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                 ;
; sliding attack functions                        ;
;     note:  ecx must be clobbered without bmi2   ;
;                                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; x = bitboard of pseudo legal moves for a piece on sq with occ pieces occluding its movement on the board

macro RookAttacks x,sq,occ,t {
 match =1, CPU_HAS_BMI2 \{
                mov   x#d, dword[RookAttacksMOFF+4*(sq)]
               pext   t, occ, qword[RookAttacksPEXT+8*(sq)]
                mov   x, qword[x+8*t]
 \}
 match =0, CPU_HAS_BMI2 \{
                mov   t, qword[RookAttacksPEXT+8*(sq)]
                and   t, occ
                mov   x#d, dword[RookAttacksMOFF+4*(sq)]
              movzx   ecx, byte[RookAttacksSHIFT+(sq)]
               imul   t, qword[RookAttacksIMUL+8*(sq)]
                shr   t, cl
                mov   x, qword[x+8*t]
 \}
}


macro BishopAttacks x,sq,occ,t {
 match =1, CPU_HAS_BMI2 \{
                mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
               pext   t, occ, qword[BishopAttacksPEXT+8*(sq)]
                mov   x, qword[x+8*(t)]
 \}
 match =0, CPU_HAS_BMI2 \{
                mov   t, qword[BishopAttacksPEXT+8*(sq)]
                and   t, occ
                mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
              movzx   ecx, byte[BishopAttacksSHIFT+(sq)]
               imul   t, qword[BishopAttacksIMUL+8*(sq)]
                shr   t, cl
                mov   x, qword[x+8*(t)]
 \}
}

macro QueenAttacks x,sq,occ,t,s  {
 match =1, CPU_HAS_BMI2 \{
                mov   x#d, dword[BishopAttacksMOFF+4*sq]
                mov   s#d, dword[RookAttacksMOFF+4*sq]
               pext   t, occ, qword[BishopAttacksPEXT+8*(sq)]
                mov   x, qword[x+8*(t)]
               pext   t, occ, qword[RookAttacksPEXT+8*(sq)]
                 or   x, qword[s+8*(t)]
 \}
 match =0, CPU_HAS_BMI2 \{
                mov   t, qword[BishopAttacksPEXT+8*(sq)]
                and   t, occ
                mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
              movzx   ecx, byte[BishopAttacksSHIFT+(sq)]
               imul   t, qword[BishopAttacksIMUL+8*(sq)]
                shr   t, cl
                mov   x, qword[x+8*(t)]

                mov   t, qword[RookAttacksPEXT+8*(sq)]
                and   t, occ
                mov   s#d, dword[RookAttacksMOFF+4*(sq)]
              movzx   ecx, byte[RookAttacksSHIFT+(sq)]
               imul   t, qword[RookAttacksIMUL+8*(sq)]
                shr   t, cl
                 or   x, qword[s+8*(t)]
 \}


}
