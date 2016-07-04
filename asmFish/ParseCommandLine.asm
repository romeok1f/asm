ParseCommandLine:
	       push   rbx rsi rdi r14 r15
		xor   eax, eax
		mov   qword[CmdLineStart], rax

	       call   _GetCommandLine
		mov   rsi, rax
		mov   r14, rax

		mov   rdi, rax
		xor   eax, eax
		 or   rcx, -1
	repne scasb					
		not   rcx
		add   ecx, 4095
		and   ecx, -4096
		mov   qword[InputBufferSizeB], rcx
	       call   _VirtualAlloc
		mov   qword[InputBuffer], rax

.find_command_start:
	      lodsb
		cmp   al, ' '
		 je   .find_command_start
		cmp   al, '"'
		 je   .skip_quoted_name
.skip_name:
	      lodsb
		cmp   al, ' '
		 je   .find_param
	       test   al, al
		 jz   .done
		jmp   .skip_name
.skip_quoted_name:
	      lodsb
		cmp   al, '"'
		 je   .find_param
	       test   al, al
		 jz   .done
		jmp   .skip_quoted_name
.find_param:

	       call   SkipSpaces
		cmp   byte[rsi], 0
		 je   .done

		mov   rdi, qword[InputBuffer]
		mov   qword[CmdLineStart], rdi

		mov   dl, 10
.next_char:
	      lodsb
		cmp   al, ';'
	      cmove   eax, edx
	      stosb
	       test   al, al
		jnz   .next_char
.done:
		pop   r15 r14 rdi rsi rbx
		ret