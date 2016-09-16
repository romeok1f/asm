

	      align   16
Math_Rand_i:
	; in: rcx address of Prng
	; out: rax  integer in [0,2^64)
		mov   rax, qword[rcx]
		mov   rdx, rax
		shr   rdx, 12
		xor   rax, rdx
		mov   rdx, rax
		shl   rdx, 25
		xor   rax, rdx
		mov   rdx, rax
		shr   rdx, 27
		xor   rax, rdx
		mov   rdx, 2685821657736338717
		mov   qword[rcx], rax
	       imul   rax, rdx
		ret

	     align   16
Math_Rand_d:
	; in: rcx address of Prng
	; out: xmm0  scalar double in [0,1)   *should* be uniformly distr
	       call   Math_Rand_i
		mov   ecx, 1023 ; 10 exponen bits
		shl   rax, 11	; 53 mantissa bits
		 jz   .Return
.Shift:
		sub   ecx, 1
		shl   rax, 1
		jnc   .Shift
		 or   rax, rcx
		ror   rax, 12
.Return:
	      vmovq   xmm0, rax
		ret



	      align   16
Math_Exp_d_d:
	; xmm0 = Exp[xmm0]
	       push   rbx
		sub   rsp, 32
	      movsd   qword[rsp+8H], xmm0
		fld   qword[rsp+8H]
	      fwait
	     fnstcw   word[rsp+1CH]
	      fwait
	     fnstcw   word[rsp+1EH]
		 or   word[rsp+1EH], 0C00H
	      fldcw   word[rsp+1EH]
	     fldl2e
	      fmulp   st1, st0
		fld   st0
	    frndint
	       fxch   st1
	       fsub   st0, st1
	      f2xm1
	       fld1
	      faddp   st1, st0
	       fxch   st1
	       fld1
	     fscale
	       fstp   st1
	      fmulp   st1, st0
	      fldcw   word[rsp+1CH]
	       fstp   qword[rsp+8H]
	      movsd   xmm0, qword[rsp+8H]
		add   rsp, 32
		pop   rbx
		ret

	      align   16
Math_Log_d_d:
	; xmm0 = Log[xmm0]
	       push  rbx
		sub  rsp, 32
	     vmovsd  qword[rsp+8H], xmm0
		fld  qword[rsp+8H]
	      fwait
	     fnstcw  word[rsp+1CH]
	      fwait
	     fnstcw  word[rsp+1EH]
		 or  word[rsp+1EH], 0C00H
	      fldcw  word[rsp+1EH]
	     fldln2
	       fxch  st1
	      fyl2x
	      fldcw  word[rsp+1CH]
	       fstp  qword[rsp+8H]
	     vmovsd  xmm0, qword[rsp+8H]
		add  rsp, 32
		pop  rbx
		ret


	      align   16
Math_Erfd:
	; xmm0 = Erf[xmm0]

	     vmovsd   xmm4, qword[.mask]
	     vmovsd   xmm5, qword[.a0]
	    vandnpd   xmm3, xmm4, xmm0
	     vandpd   xmm0, xmm0, xmm4

	     vmulsd   xmm1, xmm0, qword[.a4]
	     vaddsd   xmm1, xmm1, qword[.a3]
	     vmulsd   xmm1, xmm1, xmm0
	     vaddsd   xmm1, xmm1, qword[.a2]
	     vmulsd   xmm1, xmm1, xmm0
	     vaddsd   xmm1, xmm1, qword[.a1]
	     vmulsd   xmm1, xmm1, xmm0
	     vaddsd   xmm1, xmm1, xmm5

	     vdivsd   xmm0, xmm5, xmm1
	     vsubsd   xmm5, xmm5, xmm0

	      vorpd   xmm0, xmm5, xmm3
		ret

align 8
.mask dq 0x7FFFFFFFFFFFFFFF
.a0 dq 1.0
.a1 dq 0.278393
.a2 dq 0.230389
.a3 dq 0.000972
.a4 dq 0.078108

		      align   16
Math_Power_d_dd:
	; xmm0 = Power[xmm0, xmm1]
	       push   rsi
	       push   rbx
		sub   rsp, 40
	      movsd   qword[rsp+8H], xmm0
		fld   qword[rsp+8H]
	      movsd   qword[rsp+8H], xmm1
		fld   qword[rsp+8H]
	       fxch   st1
	       ftst
	      fwait
	     fnstsw   ax
		and   ah, 040H
		 jz   ._035
	       fstp   st0
	       ftst
	      fwait
	     fnstsw   ax
	       fstp   st0
		and   ah, 040H
		jnz   ._034
	       fldz
		jmp   ._036
._034:
	       fld1
		jmp   ._036
._035:
	      fwait
	     fnstcw   word[rsp+1CH]
	      fwait
	     fnstcw   word[rsp+1EH]
		 or   word[rsp+1EH], 0C00H
	      fldcw   word[rsp+1EH]
	       fld1
	       fxch   st1
	      fyl2x
	      fmulp   st1, st0
		fld   st0
	    frndint
	       fxch   st1
	       fsub   st0, st1
	      f2xm1
	       fld1
	      faddp   st1, st0
	       fxch   st1
	       fld1
	     fscale
	       fstp   st1
	      fmulp   st1, st0
	      fldcw   word[rsp+1CH]
._036:
	       fstp   qword[rsp+8H]
	      movsd   xmm0, qword[rsp+8H]
		add   rsp, 40
		pop   rbx
		pop   rsi
		ret











