macro MainHash_Save local, entr, key16, value, bounder, depth, move, ev {
local ..dont_write_move, ..write_everything, ..write_after_move, ..done


match =2, VERBOSE \{
mov qword[Verbr15], r15
mov r15w, key16
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea  rdi, [Output]
szcall PrintString, 'tt save key='

movzx rax, r15w
call PrintUnsignedInteger
call _WriteOut_Output
pop r11 r10 r9 r8 rdx rcx rax rsi rdi

mov r15d, move
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea  rdi, [Output]
szcall PrintString, ' move='
mov ecx, r15d
xor edx, edx
call PrintUciMove
call _WriteOut_Output
pop r11 r10 r9 r8 rdx rcx rax rsi rdi

mov r15d, value
push rdi rsi rax rcx rdx r8 r9 r10 r11
lea  rdi, [Output]
szcall PrintString, ' value='
movsxd rax, r15d
call PrintSignedInteger
call _WriteOut_Output
pop r11 r10 r9 r8 rdx rcx rax rsi rdi


    if ev eqtype 0
		mov   r15d, ev
    else
	      movsx   r15d, ev
    end if


push rdi rsi rax rcx rdx r8 r9 r10 r11
lea  rdi, [Output]
szcall PrintString, ' eval='
movsxd rax, r15d
call PrintSignedInteger
call _WriteOut_Output
pop r11 r10 r9 r8 rdx rcx rax rsi rdi

    if depth eqtype 0
		mov   r15d, depth
    else
	      movsx   r15d, depth
    end if

push rdi rsi rax rcx rdx r8 r9 r10 r11
lea  rdi, [Output]
szcall PrintString, ' depth='
movsxd rax, r15d
call PrintSignedInteger
mov al, '|'
stosb
call _WriteOut_Output
pop r11 r10 r9 r8 rdx rcx rax rsi rdi

mov r15, qword[Verbr15]

\}


ProfileInc MainHash_Save

	if value eq edx
	else if value eq 0
		xor   edx, edx
	else
	    display 'value argument of HashTable_Save is not edx or 0'
	    display 13,10
	    err
	end if

	if move eq eax
	else if move eq 0
		xor   eax, eax
	else
	    display 'move argument of HashTable_Save is not eax or 0'
	    display 13,10
	    err
	end if

		mov   rcx, qword[entr]
		mov   qword[local], rcx


		mov   rcx, entr
		shr   ecx, 3  -  1
		and   ecx, 3 shl 1
	     Assert   b, ecx, 3 shl 1, 'index 3 in cluster encountered'
		neg   rcx
		lea   rcx, [8*3+3*rcx]
		add   rcx, entr


		cmp   key16, word[rcx]
		jne   ..write_everything

if move eq 0
	if bounder eq BOUND_EXACT
		jmp   ..write_after_move
	else
	end if


else
	       test   eax, eax
	if bounder eq BOUND_EXACT
		 jz   ..write_after_move
	else
		 jz   ..dont_write_move
	end if
		mov   word[local+MainHashEntry.move], ax
end if

..dont_write_move:

	if bounder eq BOUND_EXACT
		jmp   ..write_after_move
	else
		mov   al, bounder
		cmp   al, BOUND_EXACT
		 je   ..write_after_move
	      movsx   eax, byte[local+MainHashEntry.depth]
		sub   eax, 4
		cmp   al, depth
		 jl   ..write_after_move
		jmp   ..done
	end if

..write_everything:
		mov   word[local+MainHashEntry.move], ax
		mov   word[rcx], key16
..write_after_move:
		mov   al, [mainHash.date]
		 or   al, bounder
		mov   byte[local+MainHashEntry.genBound], al
		mov   al, depth
		mov   byte[local+MainHashEntry.depth], al
    if ev eqtype 0
		mov   word[local+MainHashEntry.eval], ev
    else
	      movsx   eax, ev
		mov   word[local+MainHashEntry.eval], ax
    end if
		mov   word[local+MainHashEntry.value], dx
..done:
		mov   rax, qword[local]
		mov   qword[entr], rax


}


