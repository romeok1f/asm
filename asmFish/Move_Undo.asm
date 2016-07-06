		      align  16
Move_Undo:
	; in: rbp  address of Pos
	;     rbx  address of State
	;     ecx  move

	       push   rsi

match =1, DEBUG {
		mov   dword[rbp+Pos.debugMove], ecx
}

match=2, VERBOSE {
		sub   dword[rbp+Pos.gamePly], 1
push rax rcx rsi rdi
mov esi, ecx
lea rdi, [VerboseOutput]
mov rax, 'undomove'
stosq
movsxd rax, dword[rbp+Pos.gamePly]
call PrintSignedInteger
mov al, ':'
stosb
mov ecx, esi
xor edx, edx
call PrintUciMove
mov al, '|'
stosb
lea rcx, [VerboseOutput]
call _WriteOut
pop rdi rsi rcx rax
}

		mov   esi, dword[rbp+Pos.sideToMove]
		xor   esi, 1

		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63	; r8d = from
		mov   r9d, ecx
		and   r9d, 63	; r9d = to
		shr   ecx, 12

match =1, PROFILE {
lock inc qword[profile.moveUnpack]
}

	      movzx   r11d, byte[rbx+State.capturedPiece]      ; r11 = TO PIECE
	      movzx   r10d, byte[rbp+Pos.board+r9]	       ; r10 = FROM PIECE

		xor   edx, edx
		bts   rdx, r8
		bts   rdx, r9

		mov   eax, r10d
		and   eax, 7

		sub   rbx, sizeof.State
		mov   qword[rbp+Pos.state], rbx
		mov   dword[rbp+Pos.sideToMove], esi
		mov   byte[rbp+Pos.board+r8], r10l
		mov   byte[rbp+Pos.board+r9], r11l
		xor   qword[rbp+Pos.typeBB+8*rax], rdx
		xor   qword[rbp+Pos.typeBB+8*rsi], rdx


		cmp   ecx, MOVE_TYPE_PROM
		jae   .Special
		and   r11d, 7
		jnz   .Captured

match =1, DEBUG {
		jmp   Move_Undo_Check
}
		pop   rsi
		ret


	      align   8
.Captured:
		xor   esi, 1
		btr   rdx, r8
		 or   qword[rbp+Pos.typeBB+8*r11], rdx
		 or   qword[rbp+Pos.typeBB+8*rsi], rdx
match =1, DEBUG {
		jmp   Move_Undo_Check
}
		pop   rsi
		ret


	      align   8
.Special:
		xor   edx, edx
		cmp   ecx, MOVE_TYPE_CASTLE
		 je   .Castle
		jae   .EpCapture

.Prom:
	; change promoted piece back to pawn on r8d
		lea   eax, [8*rsi+Pawn]
		lea   ecx, [rcx-MOVE_TYPE_PROM+Knight]
		bts   rdx, r8
		 or   qword[rbp+Pos.typeBB+8*Pawn], rdx
		xor   qword[rbp+Pos.typeBB+8*rcx], rdx
		mov   byte[rbp+Pos.board+r8], al
		mov   byte[rbp+Pos.board+r9], r11l
		xor   edx, edx
		and   r11d, 7
		jnz   .PromCapture
match =1, DEBUG {
		jmp   Move_Undo_Check
}
		pop   rsi
		ret
    .PromCapture:
		xor   esi, 1
		bts   rdx, r9
		 or   qword[rbp+Pos.typeBB+8*r11], rdx
		 or   qword[rbp+Pos.typeBB+8*rsi], rdx
match =1, DEBUG {
		jmp   Move_Undo_Check
}
		pop   rsi
		ret

		      align   8
.EpCapture:
		lea   ecx, [2*rsi-1]
		lea   ecx, [r9+8*rcx]
		xor   esi, 1
		bts   rdx, rcx
		 or   qword[rbp+Pos.typeBB+8*Pawn], rdx
		 or   qword[rbp+Pos.typeBB+8*rsi], rdx
		mov   byte[rbp+Pos.board+r9], 0
		mov   byte[rbp+Pos.board+rcx], r11l
match =1, DEBUG {
		jmp   Move_Undo_Check
}
		pop   rsi
		ret

	      align   8
.Castle:
	; r8 = kfrom
	; r9 = rfrom
	; ecx = kto
	; edx = rto
	; r10 = ourking
	; r11 = our rook
		bts   rdx, r8
		bts   rdx, r9
		xor   qword[rbp+Pos.typeBB+8*rax], rdx
		xor   qword[rbp+Pos.typeBB+8*rsi], rdx


		lea   r10d, [8*rsi+King]
		lea   r11d, [8*rsi+Rook]
		mov   edx, r8d
		and   edx, 56
		cmp   r9d, r8d
		sbb   eax, eax
		lea   ecx, [rdx+4*rax+FILE_G]
		lea   edx, [rdx+2*rax+FILE_F]

		mov   byte[rbp+Pos.board+rcx], 0
		mov   byte[rbp+Pos.board+rdx], 0
		mov   byte[rbp+Pos.board+r8], r10l
		mov   byte[rbp+Pos.board+r9], r11l

		mov   rax, qword[rbp+Pos.typeBB+8*rsi]
		mov   r10, qword[rbp+Pos.typeBB+8*King]
		mov   r11, qword[rbp+Pos.typeBB+8*Rook]
		btr   rax, rcx
		btr   rax, rdx
		bts   rax, r8
		bts   rax, r9
		btr   r10, rcx
		bts   r10, r8
		btr   r11, rdx
		bts   r11, r9
		mov   qword[rbp+Pos.typeBB+8*rsi], rax
		mov   qword[rbp+Pos.typeBB+8*King], r10
		mov   qword[rbp+Pos.typeBB+8*Rook], r11

match =1, DEBUG {
		jmp   Move_Undo_Check
}
		pop   rsi
		ret




match =1, DEBUG {

Move_Undo_Check:
		mov   qword[rbp+Pos.state], rbx
	       call   Position_IsLegal
	       test   eax, eax
		jnz   @f
		pop   rsi
		ret
@@:
		lea   rdi,[DebugOutput]
		mov   rax, 'UndoMove'
	      stosq
		mov   al, 10
	      stosb
		mov   ecx, dword[rbp+Pos.debugMove]
		xor   edx, edx
	       call   PrintUciMoveLong
		mov   eax, 10
	      stosd
		lea   rdi, [DebugOutput]
	       call   _ErrorBox
	       int3
}
