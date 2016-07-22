
macro DebugStackUse m {
local ..message, ..over
 match =1, DEBUG \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rdi,[DebugOutput]
		mov   rax, qword[rbp-Thread.rootPos+Thread.stackBase]
		sub   rax, rsp
		cmp   rax, qword[rbp-Thread.rootPos+Thread.stackRecord]
		jbe   ..over
		mov   qword[rbp-Thread.rootPos+Thread.stackRecord], rax
	       call   PrintUnsignedInteger
		lea   rcx, [..message]
	       call   PrintString
		lea   rcx, [DebugOutput]
	       call   _WriteOut
		jmp   ..over
..message:
		db  ' new stack use record in '
		db m
		db 13,10,0
..over:
		pop   r11 r10 r9 r8 rdx rcx rax rdi
 \}
}

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

macro Display m {
; lets not clobber any registers here
local ..message, ..over
	       push   rdi rax rcx rdx r8 r9 r10 r11
		jmp   ..over
   ..message: db m
	      db 10,0
   ..over:
		lea   rdi,[..message]
	       call   _ErrorBox
		pop   r11 r10 r9 r8 rdx rcx rax rdi
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

macro Profile cc, index {
local ..TakingJump
; do a profile on the conditional jmp j#cc
;  increment  qword[...+0] if the jump is not taken
;  incrememnt qword[...+8] if the jump is taken
; use like this:
;    call foo
;    test eax, eax
;    Profile nz, 0
;    jnz EaxNotZero
;     ...
;

match =1, PROFILE \{
	       push   rax rcx
		lea   rcx, [profile.cjmpcounts+16*(index)+8]
	       j#cc   ..TakingJump
		lea   rcx, [profile.cjmpcounts+16*(index)+0]
..TakingJump:
		mov   rax, qword[rcx]
		lea   rax, [rax+1]
		mov   qword[rcx], rax
		pop   rcx rax

 \}
}


macro GD_String m {
; lets not clobber any registers here
local ..message, ..over
 match =1, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
	    db m
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

macro GD_Int x {
 match =1, VERBOSE \{
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


macro GD_Hex x {
 match =1, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov rcx, qword[rsp+8*8]
	call PrintAddress
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
 \}
}



macro GD_NewLine {
; lets not clobber any registers here
local ..message, ..over
 match =1, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
  match =1, OS_IS_WINDOWS \\{
	    db 13
  \\}
	    db 10
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





macro SD_NewLine {
; lets not clobber any registers here
local ..message, ..over
 match =2, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
  match =1, OS_IS_WINDOWS \\{
	    db 13
  \\}
	    db 10
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

macro SD_String m {
; lets not clobber any registers here
local ..message, ..over
 match =2, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
	    db m
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

macro SD_Move x {
 match =2, VERBOSE \{
	push  x
	push  rdi rax rcx rdx r8 r9 r10 r11
	lea  rdi, [VerboseOutput]
	mov ecx, dword[rsp+8*8]
	xor edx, edx
	call PrintUciMove
	lea  rcx, [VerboseOutput]
	call _WriteOut
	pop r11 r10 r9 r8 rdx rcx rax rdi
	add  rsp, 8
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
	    db m
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



macro ED_NewLine {
local ..message, ..over
 match =3, VERBOSE \{
	       push   rdi rax rcx rdx r8 r9 r10 r11
		lea   rcx, [..message]
		jmp   ..over
   ..message:
  match =1, OS_IS_WINDOWS \\{
	    db 13
  \\}
	    db 10
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