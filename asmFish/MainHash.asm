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

		mov   rcx, qword[rsi+MainHash.table]
		mov   edx, dword[rsi+MainHash.sizeMB]
		shl   rdx, 20
	       call   _VirtualFree

		mov   dword[rsi+MainHash.sizeMB], ebx
		shl   rbx, 20	; rbx = # of bytes in HashTable
		mov   rcx, rbx
	       call   _VirtualAlloc
		shr   rbx, 5	; cluster size is 32 bytes
		sub   rbx, 1
		mov   qword[rsi+MainHash.table], rax
		mov   qword[rsi+MainHash.mask], rbx
		mov   byte[rsi+MainHash.date], 0

		pop   rdi rsi rbx
		ret



MainHash_HashFull:
	; out: eax hash usage per thousand
		xor   eax, eax
		mov   r8, qword[mainHash.table]
	      movzx   edx, byte[mainHash.date]
		lea   r9, [r8+32*(1000/3)]	; three entires per cluster
.NextCluster:
	irps i, 0 1 2 {
	      movzx   ecx, byte[r8+8*i+MainHashEntry.genBound]
		xor   ecx, edx
		and   ecx, 0xFFFFFFFC
		cmp   ecx, 1
		adc   eax, 0
	}
		add   r8, 32
		cmp   r8, r9
		 jb   .NextCluster
		ret


MainHash_Clear:
	; hmmm, not sure if we want calling thread to touch each hash page
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
		mov   edx, dword[mainHash.sizeMB]
		shl   rdx, 20
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[mainHash.table], rax
		mov   qword[mainHash.sizeMB], rax
		pop   rbp
		ret
