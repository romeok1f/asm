MainHash_Allocate:
	; in:   ecx  size in MB
	       push   rbx rsi rdi
		lea   rsi, [mainHash]

		mov   edx, MAX_HASH_LOG2MB
		xor   eax, eax
		bsr   eax, ecx
		cmp   eax, edx
	      cmova   eax, edx
		xor   ebx, ebx
		bts   rbx, rax
		mov   dword[rsi+MainHash.sizeMB], ebx

		mov   rcx, qword[rsi+MainHash.table]
	       call   _VirtualFree

		shl   rbx, 20	; rbx = # of bytes in HashTable
		mov   rcx, rbx
	       call   _VirtualAlloc
		shr   rbx, 5
		sub   rbx, 1
		mov   qword[rsi+MainHash.table], rax
		mov   qword[rsi+MainHash.mask], rbx
		mov   byte[rsi+MainHash.date], 0

		pop   rdi rsi rbx
		ret



MainHash_Clear:
	       push   rdi
		mov   rdi, qword[mainHash.table]
		mov   ecx, dword[mainHash.sizeMB]
		shl   rcx, 20-3    ; convert MB to qwords
		xor   eax, eax
	  rep stosq
		pop   rdi
		ret


MainHash_Free:
	       push   rbp
		mov   rcx, qword[mainHash.table]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[mainHash.table], rax
		mov   qword[mainHash.sizeMB], rax
		pop   rbp
		ret
