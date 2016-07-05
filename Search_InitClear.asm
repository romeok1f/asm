
; this works but should be cleaned up

Search_Init:
	push	r14					; 09D0 _ 41: 56
	push	r13					; 09D2 _ 41: 55
	push	r12					; 09D4 _ 41: 54
	push	rbp					; 09D6 _ 55
	push	rdi					; 09D7 _ 57
	push	rsi					; 09D8 _ 56
	push	rbx					; 09D9 _ 53
	sub	rsp, 160				; 09DA _ 48: 81. EC, 000000A0
	movaps	dqword[rsp+20H], xmm6			; 09E1 _ 0F 29. 74 24, 20
	movaps	dqword[rsp+30H], xmm7			; 09E6 _ 0F 29. 7C 24, 30
	movaps	dqword[rsp+40H], xmm8			; 09EB _ 44: 0F 29. 44 24, 40
	movaps	dqword[rsp+50H], xmm9			; 09F1 _ 44: 0F 29. 4C 24, 50
	movaps	dqword[rsp+60H], xmm10			; 09F7 _ 44: 0F 29. 54 24, 60
	movaps	dqword[rsp+70H], xmm11			; 09FD _ 44: 0F 29. 5C 24, 70
	movaps	dqword[rsp+80H], xmm12			; 0A03 _ 44: 0F 29. A4 24, 00000080
	movaps	dqword[rsp+90H], xmm13			; 0A0C _ 44: 0F 29. AC 24, 00000090
	lea	r12, [Reductions]			; 0A15 _ 4C: 8D. 25, 0041D6C0(rel)
	xor	ebp, ebp				; 0A1C _ 31. ED
	xor	ebx, ebx				; 0A1E _ 31. DB
	movsd	xmm6, qword[?_2729]			; 0A20 _ F2: 0F 10. 35, 00001AB0(rel)
	movsd	xmm8, qword[?_2730]			; 0A28 _ F2 44: 0F 10. 05, 00001AB8(rel)
._0048: mov	rax, rbp				; 0A31 _ 48: 89. E8
	mov	esi, ebp				; 0A34 _ 89. EE
	mov	edi, 1					; 0A36 _ BF, 00000001
	shl	rax, 14 				; 0A3B _ 48: C1. E0, 0E
	xor	esi, 01H				; 0A3F _ 83. F6, 01
	lea	r14, [r12+rax+100H]			; 0A42 _ 4D: 8D. B4 04, 00000100
	and	esi, 01H				; 0A4A _ 83. E6, 01
._0049: pxor	xmm0, xmm0				; 0A4D _ 66: 0F EF. C0
	cvtsi2sd xmm0, edi				; 0A51 _ F2: 0F 2A. C7
	xor	r13d, r13d				; 0A55 _ 45: 31. ED
	call	Math_Log_d_d				   ; 0A58 _ E8, 00000183
	movapd	xmm7, xmm0				; 0A5D _ 66: 0F 28. F8
._0050: lea	edx, [r13+1H]				; 0A61 _ 41: 8D. 55, 01
	pxor	xmm0, xmm0				; 0A65 _ 66: 0F EF. C0
	cvtsi2sd xmm0, edx				; 0A69 _ F2: 0F 2A. C2
	call	Math_Log_d_d				; 0A6D _ E8, 0000016E
	movapd	xmm1, xmm0				; 0A72 _ 66: 0F 28. C8
	mulsd	xmm1, xmm7				; 0A76 _ F2: 0F 59. CF
	mulsd	xmm1, xmm6				; 0A7A _ F2: 0F 59. CE
	ucomisd xmm8, xmm1				; 0A7E _ 66 44: 0F 2E. C1
	ja	._0051					; 0A83 _ 77, 3D
	addsd	xmm1, xmm6				; 0A85 _ F2: 0F 58. CE
	lea	rcx, [r13*4]				; 0A89 _ 4A: 8D. 0C AD, 00000000
	cvttsd2si r8d, xmm1				; 0A91 _ F2 44: 0F 2C. C1
	lea	r9d, [r8-1H]				; 0A96 _ 45: 8D. 48, FF
	mov	dword [r14+rcx+4H], r8d 		; 0A9A _ 45: 89. 44 0E, 04
	test	r9d, r9d				; 0A9F _ 45: 85. C9
	cmovs	r9d, ebx				; 0AA2 _ 44: 0F 48. CB
	cmp	r8d, 1					; 0AA6 _ 41: 83. F8, 01
	mov	dword [r14+rcx+8004H], r9d		; 0AAA _ 45: 89. 8C 0E, 00008004
	jle	._0051					; 0AB2 _ 7E, 0E
	test	sil, sil				; 0AB4 _ 40: 84. F6
	jz	._0051					; 0AB7 _ 74, 09
	add	r8d, 1					; 0AB9 _ 41: 83. C0, 01
	mov	dword [r14+rcx+4H], r8d 		; 0ABD _ 45: 89. 44 0E, 04
._0051: add	r13, 1					; 0AC2 _ 49: 83. C5, 01
	cmp	r13, 63 				; 0AC6 _ 49: 83. FD, 3F
	jnz	._0050					; 0ACA _ 75, 95
	add	edi, 1					; 0ACC _ 83. C7, 01
	add	r14, 256				; 0ACF _ 49: 81. C6, 00000100
	cmp	edi, 64 				; 0AD6 _ 83. FF, 40
	jne	._0049					; 0AD9 _ 0F 85, FFFFFF6E
	sub	rbp, 1					; 0ADF _ 48: 83. ED, 01
	jz	._0052					; 0AE3 _ 74, 0A
	mov	ebp, 1					; 0AE5 _ BD, 00000001
	jmp	._0048					; 0AEA _ E9, FFFFFF42
; _ZN6Search4initEv End of function

._0052: ; Local function
	movsd	xmm6, qword [?_2731]		    ; 0AEF _ F2: 0F 10. 35, 00001AC0(rel)
	xor	ebp, ebp				; 0AF7 _ 31. ED
	pxor	xmm13, xmm13				; 0AF9 _ 66 45: 0F EF. ED
	movsd	xmm12, qword [?_2732]		    ; 0AFE _ F2 44: 0F 10. 25, 00001AC8(rel)
	lea	r14, [FutilityMoveCounts]; 0B07 _ 4C: 8D. 35, 0042D6C0(rel)
	movsd	xmm11, qword [?_2733]		    ; 0B0E _ F2 44: 0F 10. 1D, 00001AD0(rel)
	lea	rdi, [r14+16*4] 		      ; 0B17 _ 48: 8D. 3D, 0042D700(rel)
	movsd	xmm10, qword [?_2734]		    ; 0B1E _ F2 44: 0F 10. 15, 00001AD8(rel)
	movsd	xmm8, qword [?_2735]		    ; 0B27 _ F2 44: 0F 10. 05, 00001AE0(rel)
	movsd	xmm7, qword [?_2736]		    ; 0B30 _ F2: 0F 10. 3D, 00001AE8(rel)
._0053: pxor	xmm9, xmm9				; 0B38 _ 66 45: 0F EF. C9
	cvtsi2sd xmm9, ebp				; 0B3D _ F2 44: 0F 2A. CD
	movapd	xmm1, xmm6				; 0B42 _ 66: 0F 28. CE
	movapd	xmm0, xmm9				; 0B46 _ 66 41: 0F 28. C1
	addsd	xmm0, xmm13				; 0B4B _ F2 41: 0F 58. C5
	call	Math_Power_d_dd 			    ; 0B50 _ E8, 000008A0(rel)
	movapd	xmm1, xmm6				; 0B55 _ 66: 0F 28. CE
	mulsd	xmm0, xmm12				; 0B59 _ F2 41: 0F 59. C4
	addsd	xmm0, xmm11				; 0B5E _ F2 41: 0F 58. C3
	cvttsd2si r10d, xmm0				; 0B63 _ F2 44: 0F 2C. D0
	movapd	xmm0, xmm9				; 0B68 _ 66 41: 0F 28. C1
	addsd	xmm0, xmm10				; 0B6D _ F2 41: 0F 58. C2
	mov	dword [r14+rbp*4], r10d 		; 0B72 _ 45: 89. 14 AE
	call	Math_Power_d_dd 			    ; 0B76 _ E8, 000008A0(rel)
	mulsd	xmm0, xmm8				; 0B7B _ F2 41: 0F 59. C0
	addsd	xmm0, xmm7				; 0B80 _ F2: 0F 58. C7
	cvttsd2si r11d, xmm0				; 0B84 _ F2 44: 0F 2C. D8
	mov	dword [rdi+rbp*4], r11d 		; 0B89 _ 44: 89. 1C AF
	add	rbp, 1					; 0B8D _ 48: 83. C5, 01
	cmp	rbp, 16 				; 0B91 _ 48: 83. FD, 10
	jnz	._0053					; 0B95 _ 75, A1
	movaps	xmm6, dqword[rsp+20H]			; 0B97 _ 0F 28. 74 24, 20
	movaps	xmm7, dqword[rsp+30H]			; 0B9C _ 0F 28. 7C 24, 30
	movaps	xmm8, dqword[rsp+40H]			; 0BA1 _ 44: 0F 28. 44 24, 40
	movaps	xmm9, dqword[rsp+50H]			; 0BA7 _ 44: 0F 28. 4C 24, 50
	movaps	xmm10, dqword[rsp+60H]			; 0BAD _ 44: 0F 28. 54 24, 60
	movaps	xmm11, dqword[rsp+70H]			; 0BB3 _ 44: 0F 28. 5C 24, 70
	movaps	xmm12, dqword[rsp+80H]			; 0BB9 _ 44: 0F 28. A4 24, 00000080
	movaps	xmm13, dqword[rsp+90H]			; 0BC2 _ 44: 0F 28. AC 24, 00000090
	add	rsp, 160				; 0BCB _ 48: 81. C4, 000000A0
	pop	rbx					; 0BD2 _ 5B
	pop	rsi					; 0BD3 _ 5E
	pop	rdi					; 0BD4 _ 5F
	pop	rbp					; 0BD5 _ 5D
	pop	r12					; 0BD6 _ 41: 5C
	pop	r13					; 0BD8 _ 41: 5D
	pop	r14					; 0BDA _ 41: 5E
	ret



; Search::clear() resets search state to zero, to obtain reproducible results
Search_Clear:
	       push   rbx rsi rdi

	       call   MainHash_Clear
		mov   byte[mainHash.date],0

		lea   rdi, [CounterMoveHistory]
		mov   ecx, 16*64*16*64*2
		xor   eax, eax
	  rep stosb

		lea   rbx, [mainThread]
		mov   edx, VALUE_INFINITE
.nexthread:
		mov   rdi, qword[rbx+Thread.rootPos+Pos.history]
		mov   ecx, 4*16*64
		xor   eax, eax
	  rep stosb

		mov   rdi, qword[rbx+Thread.rootPos+Pos.counterMoves]
		mov   ecx, 4*16*64
		xor   eax, eax
	  rep stosb

	; mainThread.previousScore is used in the time management part of idloop
	;  +VALUE_INFINITE causes us to think alot on the first move
		mov   dword[rbx+Thread.previousScore], edx

		sub   rbx, sizeof.Thread
		cmp   rbx, qword[threadPool.stackPointer]
		jae   .nexthread

		pop   rdi rsi rbx
		ret