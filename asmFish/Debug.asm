
macro DebugDisplay m {
; lets not clobber any registers here
local ..message, ..over
 match =1, DEBUG \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		jmp   ..over
   ..message: db m
	      db 10,0
   ..over:
		lea   rdi,[..message]
	       call   _ErrorBox
		pop   r11 r10 r9 r8 rdx rcx rax rdi
 \}
}



macro Assert cc,a,b,m {
; if the assertion succeeds, only the eflags are clobbered
local ..skip, ..errorbox, ..message
 match =1, DEBUG \{
		cmp   a, b
	       j#cc   ..skip
		jmp   ..errorbox

   ..message: db m
	      db 0
   ..errorbox:
		lea   rdi,[..message]
	       call   _ErrorBox
		xor   ecx, ecx
		jmp   _ExitProcess
   ..skip:
 \}
}

macro Profile cc, var {
; do a profile on the conditional jmp j#cc
;  increment  qword[var+0] if the jump is not taken
;  incrememnt qword[var+8] if the jump is taken

match =1, PROFILE \{
	       push   rax rcx
		lea   rcx, [var+8]
	       j#cc   ..TakingJump
		lea   rcx, [var+0]
..TakingJump:
		mov   rax, qword [rcx]
		lea   rax, [rax+1]
		mov   qword [rcx], rax
		pop   rcx rax

 \}
}


macro SD_String m {
; lets not clobber any registers here
local ..message, ..over
 match =2, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
	    m
	    db 0
   ..over:
		lea   rdi, [VerboseOutput]
	       call   PrintString
		lea   rcx, [VerboseOutput]
		lea  rcx, [VerboseOutput]
	       call _WriteOut
		pop   r11 r10 r9 r8 rdx rcx rax rdi
 \}
}



macro SD_Int x {
 match =2, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	movsxd rax, dword[rsp+8*8]
	call PrintSignedInteger
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
 \}
}


macro SD_UInt64 x {
 match =2, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov rax, qword[rsp+8*8]
	call PrintUnsignedInteger
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
 \}
}



macro SD_Bool8 x {
 match =2, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	movzx eax, byte[rsp+8*8]
	neg eax
	sbb eax, eax
	and eax, 1
	add eax, '0'
	stosb
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
 \}
}





macro ED_String m {
; lets not clobber any registers here
local ..message, ..over
 match =3, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
	    m
	    db 0
   ..over:
		lea   rdi, [VerboseOutput]
	       call   PrintString
		lea   rcx, [VerboseOutput]
		lea  rcx, [VerboseOutput]
	       call _WriteOut
		pop   r11 r10 r9 r8 rdx rcx rax rdi
 \}
}



macro ED_Int x {
 match =3, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	movsxd rax, dword[rsp+8*8]
	call PrintSignedInteger
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
 \}
}



macro ED_Score x {
 match =3, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov  eax, dword[rsp+8*8]
	add  eax, 0x08000
	sar  eax, 16
	movsxd rax, eax
	call PrintSignedInteger
	mov  al, ','
	stosb
	movsx  rax, word[rsp+8*8]
	call PrintSignedInteger
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add rsp, 8
 \}
}







macro VerboseDisplay m {
; lets not clobber any registers here
local ..message, ..over
 match =1, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
	    m
	    db 0
   ..over:
		lea   rdi, [VerboseOutput]
	       call   PrintString
		lea   rcx, [VerboseOutput]
		lea  rcx, [VerboseOutput]
	       call _WriteOut
		pop   r11 r10 r9 r8 rdx rcx rax rdi
 \}
}

macro VerboseDisplayScore x {
 match =1, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov  eax, dword[rsp+8*8]
	add  eax, 0x08000
	sar  eax, 16
	movsxd rax, eax
	call PrintSignedInteger
	mov  al, ','
	stosb
	movsx  rax, word[rsp+8*8]
	call PrintSignedInteger
	mov  al, 10
	stosb
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add rsp, 8
 \}
}

macro VerboseDisplayScoreHi x {
 match =1, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov  eax, dword[rsp+8*8+4]
	add  eax, 0x08000
	sar  eax, 16
	movsxd rax, eax
	call PrintSignedInteger
	mov  al, ','
	stosb
	movsx  rax, word[rsp+8*8+4]
	call PrintSignedInteger
	mov  al, 10
	stosb
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add rsp, 8
 \}
}

macro VerboseDisplayInt x {
 match =1, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	movsxd rax, dword[rsp+8*8]
	call PrintSignedInteger
	mov  al, 10
	stosb
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
 \}
}

macro VerboseDisplayBigInt x {
 match =1, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov rax, qword[rsp+8*8]
	call PrintUnsignedInteger
	mov  al, 10
	stosb
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add rsp, 8
 \}

}
