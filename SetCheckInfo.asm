	    align   16
SetCheckInfo:
        ; in: rbp  address of Pos
	;     rbx  address of State

               push   rsi rdi r12 r13 r14 r15

                mov   ecx, dword[rbp+Pos.sideToMove]
                mov   rax, qword[rbp+Pos.typeBB+8*Queen]
                mov   rdx, qword[rbp+Pos.typeBB+8*King]
                mov   r15, qword[rbp+Pos.typeBB+8*rcx]
                xor   ecx, 1
                mov   r14, qword[rbp+Pos.typeBB+8*rcx]
                shl   ecx, 6+3
                mov   r11, r15		; r11 = our pieces
                mov   r10, r14		; r10 = their pieces
                mov   rdi, r15
                 or   rdi, r14		; rdi = all pieces
                and   r15, rdx
                and   r14, rdx
                bsf   r15, r15		; r15 = our king
                bsf   r14, r14		; r14 = their king

                mov   r13, qword[rbp+Pos.typeBB+8*Rook]
                mov   r12, qword[rbp+Pos.typeBB+8*Bishop]
                 or   r13, rax
                 or   r12, rax
                mov   byte[rbx+State.ksq], r14l

                mov   rax, qword[WhitePawnAttacks+rcx+8*r14]
                mov   rdx, qword[KnightAttacks+8*r14]
                mov   qword[rbx+State.checkSq+8*Pawn], rax
                mov   qword[rbx+State.checkSq+8*Knight], rdx

                mov   rax, qword[RookAttacksPDEP+8*r15]
                and   rax, r13
                mov   rcx, qword[BishopAttacksPDEP+8*r15]
                and   rcx, r12
                 or   rax, rcx
                xor   esi, esi
                and   rax, r10
                jnz   .Pinned
                mov   qword[rbx+State.pinned], rax
.PinnedRet:
                mov   rax, qword[RookAttacksPDEP+8*r14]
                and   rax, r13
                mov   rcx, qword[BishopAttacksPDEP+8*r14]
                and   rcx, r12
                 or   rax, rcx
                xor   esi, esi
                and   rax, r11
                jnz   .dcCandidates
                mov   qword[rbx+State.dcCandidates], rax
.dcCandidatesRet:

      BishopAttacks   rax, r14, rdi, r8
        RookAttacks   rdx, r14, rdi, r8
                xor   ecx, ecx
                mov   qword[rbx+State.checkSq+8*Bishop], rax
                mov   qword[rbx+State.checkSq+8*Rook], rdx
                 or   rax, rdx
                mov   qword[rbx+State.checkSq+8*Queen], rax
                mov   qword[rbx+State.checkSq+8*King], rcx

                pop   r15 r14 r13 r12 rdi rsi
                ret

              align   8
.Pinned:
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
                jnz   @b
                and   rsi, r11
                mov   qword[rbx+State.pinned], rsi
                jmp   .PinnedRet

              align   8
.dcCandidates:
                mov   edx, r14d
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
                jnz   @b
                and   rsi, r11
                mov   qword[rbx+State.dcCandidates], rsi
                jmp   .dcCandidatesRet

