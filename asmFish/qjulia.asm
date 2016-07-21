format ELF64 executable 3
entry Start

;-------------------------------------------------------------------------------
; NAME:     shuf
;-------------------------------------------------------------------------------
macro	    shuf	d*,s*,z*,y*,x*,w* {
	    shufps	d,s,(z shl 6) or (y shl 4) or (x shl 2) or w
}
;-------------------------------------------------------------------------------
; NAME:     length3
; IN:       xmm0.xyz    input vector
; OUT:      xmm0.xyzw   vector length
;-------------------------------------------------------------------------------
macro	    length3	{
	    mulps	xmm0,xmm0
	    movaps	xmm1,xmm0
	    movaps	xmm2,xmm0
	    shufps	xmm0,xmm0,0x00
	    shufps	xmm1,xmm1,0x55
	    shufps	xmm2,xmm2,0xaa
	    addps	xmm0,xmm1
	    addps	xmm0,xmm2
	    sqrtps	xmm0,xmm0
}
;-------------------------------------------------------------------------------
; NAME:     length4
; IN:       xmm0.xyzw   input vector
; OUT:      xmm0.xyzw   vector length
;-------------------------------------------------------------------------------
macro	    length4	{
	    mulps	xmm0,xmm0
	    movaps	xmm1,xmm0
	    movaps	xmm2,xmm0
	    movaps	xmm3,xmm0
	    shufps	xmm0,xmm0,0x00
	    shufps	xmm1,xmm1,0x55
	    shufps	xmm2,xmm2,0xaa
	    shufps	xmm3,xmm3,0xff
	    addps	xmm0,xmm1
	    addps	xmm2,xmm3
	    addps	xmm0,xmm2
	    sqrtps	xmm0,xmm0
}
;-------------------------------------------------------------------------------
; NAME:     normalize3
; IN:       xmm0.xyz    input vector
; OUT:      xmm0.xyz    normalized vector
;-------------------------------------------------------------------------------
macro	    normalize3	{
	    movaps	xmm3,xmm0
	    mulps	xmm0,xmm0
	    movaps	xmm1,xmm0
	    movaps	xmm2,xmm0
	    shufps	xmm0,xmm0,0x00
	    shufps	xmm1,xmm1,0x55
	    shufps	xmm2,xmm2,0xaa
	    addps	xmm0,xmm1
	    addps	xmm0,xmm2
	    rsqrtps	xmm0,xmm0
	    mulps	xmm0,xmm3
}
;-------------------------------------------------------------------------------
; NAME:     cross
; IN:       xmm0.xyz    first input vector
; IN:       xmm1.xyz    second input vector
; OUT:      xmm0.xyz    cross product result
;-------------------------------------------------------------------------------
macro	    cross	{
	    movaps	xmm2,xmm0
	    movaps	xmm3,xmm1
	    shuf	xmm0,xmm0,3,0,2,1
	    shuf	xmm1,xmm1,3,1,0,2
	    shuf	xmm2,xmm2,3,1,0,2
	    shuf	xmm3,xmm3,3,0,2,1
	    mulps	xmm0,xmm1
	    mulps	xmm2,xmm3
	    subps	xmm0,xmm2
}
;-------------------------------------------------------------------------------
; NAME:     dot3
; IN:       xmm0.xyz    first input vector
; IN:       xmm1.xyz    second input vector
; OUT:      xmm0.xyzw   dot product result
;-------------------------------------------------------------------------------
macro	    dot3	{
	    mulps	xmm0,xmm1
	    movaps	xmm1,xmm0
	    movaps	xmm2,xmm0
	    shufps	xmm0,xmm0,0x00
	    shufps	xmm1,xmm1,0x55
	    shufps	xmm2,xmm2,0xaa
	    addps	xmm0,xmm1
	    addps	xmm0,xmm2
}
;-------------------------------------------------------------------------------
; NAME:     dot4
; IN:       xmm0.xyzw   first input vector
; IN:       xmm1.xyzw   second input vector
; OUT:      xmm0.xyzw   dot product result
;-------------------------------------------------------------------------------
macro	    dot4	{
	    mulps	xmm0,xmm1
	    movaps	xmm1,xmm0
	    movaps	xmm2,xmm0
	    movaps	xmm3,xmm0
	    shufps	xmm0,xmm0,0x00
	    shufps	xmm1,xmm1,0x55
	    shufps	xmm2,xmm2,0xaa
	    shufps	xmm3,xmm3,0xff
	    addps	xmm0,xmm1
	    addps	xmm2,xmm3
	    addps	xmm0,xmm2
}
;-------------------------------------------------------------------------------
; NAME:     qsq
; IN:       xmm0.xyzw   quaternion
; OUT:      xmm0.xyzw   squared quaternion
;-------------------------------------------------------------------------------
macro	    qsq 	{
	    movaps	xmm3,xmm0
	    movaps	xmm4,xmm0
	    movaps	xmm1,xmm0
	    dot3
	    shufps	xmm3,xmm3,0xff
	    movaps	xmm5,xmm3
	    mulps	xmm3,xmm3
	    subps	xmm3,xmm0   ; r.___w
	    mulps	xmm4,xmm5
	    addps	xmm4,xmm4   ; r.xyz_
	    andps	xmm3,dqword [g_ClearXYZ]
	    andps	xmm4,dqword [g_ClearW]
	    orps	xmm3,xmm4
	    movaps	xmm0,xmm3
}
;-------------------------------------------------------------------------------
; NAME:     qmul
; IN:       xmm0.xyzw   first quaternion
; IN:       xmm1.xyzw   second quaternion
; OUT:      xmm0.xyzw   first quaternion multiplied by second quaternion
;-------------------------------------------------------------------------------
macro	    qmul	{
	    movaps	xmm6,xmm0	; q1.xyzw
	    movaps	xmm7,xmm1	; q2.xyzw
	    dot3
	    movaps	xmm4,xmm6
	    movaps	xmm5,xmm7
	    shufps	xmm4,xmm4,0xff	; q1.wwww
	    shufps	xmm5,xmm5,0xff	; q2.wwww
	    movaps	xmm1,xmm4
	    mulps	xmm1,xmm5
	    subps	xmm1,xmm0
	    andps	xmm1,dqword [g_ClearXYZ]
	    movaps	xmm8,xmm1		    ; r.000w
	    movaps	xmm0,xmm6
	    movaps	xmm1,xmm7
	    cross
	    mulps	xmm7,xmm4
	    mulps	xmm6,xmm5
	    addps	xmm6,xmm7
	    addps	xmm0,xmm6
	    andps	xmm0,dqword [g_ClearW]
	    orps	xmm0,xmm8
}
;-------------------------------------------------------------------------------
; NAME:     logss
; IN:       xmm0.x      function argument
; OUT:      xmm0.x      function result
;-------------------------------------------------------------------------------
macro	    logss	{
	    maxss	xmm0,[g_MinNormPos]
	    movss	xmm1,[g_1_0]
	    movd	edx,xmm0
	    andps	xmm0,dqword [g_InvMantMask]
	    orps	xmm0,xmm1
	    movaps	xmm4,xmm0
	    subss	xmm0,xmm1
	    addss	xmm4,xmm1
	    shr 	edx,23
	    rcpss	xmm4,xmm4
	    mulss	xmm0,xmm4
	    addss	xmm0,xmm0
	    movaps	xmm2,xmm0
	    mulss	xmm0,xmm0
	    sub 	edx,0x7f
	    movss	xmm4,[g_log_p0]
	    movss	xmm6,[g_log_q0]
	    mulss	xmm4,xmm0
	    movss	xmm5,[g_log_p1]
	    mulss	xmm6,xmm0
	    movss	xmm7,[g_log_q1]
	    addss	xmm4,xmm5
	    addss	xmm6,xmm7
	    movss	xmm5,[g_log_p2]
	    mulss	xmm4,xmm0
	    movss	xmm7,[g_log_q2]
	    mulss	xmm6,xmm0
	    addss	xmm4,xmm5
	    movss	xmm5,[g_log_c0]
	    addss	xmm6,xmm7
	    cvtsi2ss	xmm1,edx
	    mulss	xmm0,xmm4
	    rcpss	xmm6,xmm6
	    mulss	xmm0,xmm6
	    mulss	xmm0,xmm2
	    mulss	xmm1,xmm5
	    addss	xmm0,xmm2
	    addss	xmm0,xmm1
}

segment readable executable

;-------------------------------------------------------------------------------
; NAME:     MemAlloc
; IN:       edi         allocation size in bytes
; OUT:      rax         allocation address
;-------------------------------------------------------------------------------
align 64
MemAlloc:
	    mov 	eax,9		; sys_mmap
	    xor 	esi,esi 	; addr
	    xchg	esi,edi 	; length (esi)
	    mov 	edx,0x1+0x2	; prot = PROT_READ | PROT_WRITE
	    mov 	r10d,0x02+0x20	; flags = MAP_PRIVATE | MAP_ANONYMOUS
	    mov 	r8,-1		; fd
	    xor 	r9d,r9d 	; offset
	    syscall
	    ret
;-------------------------------------------------------------------------------
; NAME:     QJuliaDist
; IN:       xmm0.xyz    position
; OUT:      xmm0.xyzw   distance to the nearest point in quaternion julia set
;-------------------------------------------------------------------------------
align 64
QJuliaDist:
	    Z		equ rbp-16
	    Zp		equ rbp-32
	    NormZ	equ rbp-36
	    NormZp	equ rbp-40
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,64
	    ; init Z and Zp
	    andps	xmm0,dqword [g_ClearW]
	    shuf	xmm0,xmm0,0,3,2,1
	    movaps	[Z],xmm0
	    movaps	xmm1,dqword [g_UnitW]
	    movaps	[Zp],xmm1
	    ; iterate
	    mov 	ecx,10
.Iterate:
	    ; compute and update Zp
	    movaps	xmm0,[Z]
	    movaps	xmm1,[Zp]
	    qmul
	    addps	xmm0,xmm0
	    movaps	[Zp],xmm0
	    ; compute and update Z
	    movaps	xmm0,[Z]
	    qsq
	    addps	xmm0,dqword [g_Quat]
	    movaps	[Z],xmm0
	    ; check if squared length of Z is greater than g_EscapeThreshold,
	    ; break the loop if it is
	    movaps	xmm1,xmm0
	    dot4
	    movss	xmm1,[g_EscapeThreshold]
	    cmpltss	xmm1,xmm0
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    je		.IterateEnd
	    ; continue the loop
	    sub 	ecx,1
	    test	ecx,ecx
	    jnz 	.Iterate
.IterateEnd:
	    movaps	xmm0,[Z]
	    length4
	    movss	[NormZ],xmm0
	    movaps	xmm0,[Zp]
	    length4
	    movss	[NormZp],xmm0
	    movss	xmm0,[NormZ]
	    logss
	    divss	xmm0,[NormZp]
	    mulss	xmm0,[NormZ]
	    mulss	xmm0,[g_0_5]
	    shufps	xmm0,xmm0,0x00
	    mov 	rsp,rbp
	    pop 	rbp
	    restore	Z,Zp,NormZ,NormZp
	    ret
;-------------------------------------------------------------------------------
; NAME:     Map
; IN:       xmm0.xyz    position
; OUT:      xmm0.xyzw   distance to the nearest object from input position
; OUT:      eax         material ID of the nearest object
;-------------------------------------------------------------------------------
align 64
Map:
	    P		equ rbp-16
	    MinDist	equ rbp-32
	    MatID	equ rbp-40
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,128
	    movaps	[P],xmm0
	    movaps	xmm0,dqword [g_255_0]
	    movaps	[MinDist],xmm0
	    mov 	dword [MatID],0
	    ; QJulia
	    movaps	xmm0,[P]
	    call	QJuliaDist
	    movaps	xmm1,xmm0
	    cmpltps	xmm1,[MinDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    jne 	@f
	    movaps	[MinDist],xmm0
	    mov 	dword [MatID],4
@@:
	    ; sphere
	    movaps	xmm0,[P]
	    subps	xmm0,dqword [g_UnitY]
	    length3
	    subps	xmm0,dqword [g_1_0]
	    movaps	xmm1,xmm0
	    cmpltps	xmm1,[MinDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    jne 	@f
	    ;movaps      [MinDist],xmm0
	    ;mov         dword [MatID],1
@@:
	    ; plane
	    movaps	xmm0,[P]
	    movaps	xmm1,dqword [g_UnitY]
	    dot3
	    addps	xmm0,dqword [g_1_0]
	    movaps	xmm1,xmm0
	    cmpltps	xmm1,[MinDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    jne 	@f
	    movaps	[MinDist],xmm0
	    mov 	dword [MatID],2
@@:
	    ; box
	    xorps	xmm0,xmm0
	    subps	xmm0,[P]
	    maxps	xmm0,[P]
	    subps	xmm0,dqword [g_BoxSize]
	    maxps	xmm0,dqword [g_0_0]
	    length3
	    subps	xmm0,dqword [g_BoxEdge]
	    movaps	xmm1,xmm0
	    cmpltps	xmm1,[MinDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    jne 	@f
	    ;movaps      [MinDist],xmm0
	    ;mov         dword [MatID],3
@@:
	    movaps	xmm0,[MinDist]
	    mov 	eax,[MatID]
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
	    restore	P,MinDist,MatID
;-------------------------------------------------------------------------------
; NAME:     CastRay
; IN:       xmm0.xyz    ray origin
; IN:       xmm1.xyz    ray direction
; OUT:      xmm0.xyzw   distance from ray orgin to the nearest intersected object
;                       or -1.0 if there is no intersection
;-------------------------------------------------------------------------------
align 64
CastRay:
	    RO		equ rbp-16
	    RD		equ rbp-32
	    T		equ rbp-48
	    MatID	equ rbp-52
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,128
	    ; init stack variables
	    movaps	[RO],xmm0
	    movaps	[RD],xmm1
	    xorps	xmm0,xmm0
	    movaps	[T],xmm0
.March:
	    ; find distance to the nearest object
	    movaps	xmm0,[RD]
	    mulps	xmm0,[T]
	    addps	xmm0,[RO]
	    call	Map
	    mov 	[MatID],eax
	    ; return if distance is less than g_HitDist
	    movaps	xmm1,xmm0
	    cmpltps	xmm1,dqword [g_HitDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    je		.Hit
	    ; increment T with distance to the nearest object
	    movaps	xmm1,[T]
	    addps	xmm1,xmm0
	    movaps	[T],xmm1
	    ; continue loop only if distance is less than g_MaxDist
	    cmpltps	xmm1,dqword [g_MaxDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    je		.March
	    xorps	xmm0,xmm0
	    subps	xmm0,dqword [g_1_0]
	    movaps	[T],xmm0
	    mov 	dword [MatID],0
.Hit:
	    movaps	xmm0,[T]
	    mov 	eax,[MatID]
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
	    restore	RO,RD,T,MatID
;-------------------------------------------------------------------------------
; NAME:     CastShadowRay
; IN:       xmm0.xyz    ray origin
; IN:       xmm1.xyz    ray direction
; OUT:      xmm0.xyzw   visibility factor [0.0, 1.0],
;                       0.0 means path is fully blocked,
;                       1.0 means path is fully clear
;-------------------------------------------------------------------------------
align 64
CastShadowRay:
	    RO		equ rbp-16
	    RD		equ rbp-32
	    R		equ rbp-48
	    T		equ rbp-64
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,128
	    ; init stack variables
	    movaps	[RO],xmm0
	    movaps	[RD],xmm1
	    movaps	xmm0,dqword [g_0_01]
	    movaps	[T],xmm0
	    movaps	xmm0,dqword [g_1_0]
	    movaps	[R],xmm0
.March:
	    ; find distance to the nearest object
	    movaps	xmm0,[RD]
	    mulps	xmm0,[T]
	    addps	xmm0,[RO]
	    call	Map
	    ; return 0.0 if distance is less than g_ShadowHitDist
	    movaps	xmm1,xmm0
	    cmpltps	xmm1,dqword [g_ShadowHitDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    je		.Hit
	    ; compute R
	    movaps	xmm1,xmm0
	    rcpps	xmm2,[T]
	    mulps	xmm1,xmm2
	    mulps	xmm1,dqword [g_16_0]
	    movaps	xmm2,[R]
	    minps	xmm2,xmm1
	    movaps	[R],xmm2
	    ; increment T with distance to the nearest object
	    movaps	xmm1,[T]
	    addps	xmm1,xmm0
	    movaps	[T],xmm1
	    ; continue loop only if distance is less than g_ShadowMaxDist
	    cmpltps	xmm1,dqword [g_ShadowMaxDist]
	    movd	eax,xmm1
	    cmp 	eax,0xffffffff
	    je		.March
	    ; return (R,R,R,R)
	    movaps	xmm0,[R]
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
.Hit:
	    ; return (0,0,0,0)
	    xorps	xmm0,xmm0
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
	    restore	RO,RD,R,T
;-------------------------------------------------------------------------------
; NAME:     ComputeNormal
; IN:       xmm0.xyz    position
; OUT:      xmm0.xyz    normal vector
;-------------------------------------------------------------------------------
align 64
ComputeNormal:
	    P		equ rbp-16
	    N		equ rbp-32
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,128
	    movaps	[P],xmm0
	    ; compute x coordinate
	    addps	xmm0,dqword [g_NormalDX]
	    call	Map
	    movss	[N+0],xmm0
	    movaps	xmm0,[P]
	    subps	xmm0,dqword [g_NormalDX]
	    call	Map
	    movss	xmm1,[N+0]
	    subss	xmm1,xmm0
	    movss	[N+0],xmm1
	    ; compute y coordinate
	    movaps	xmm0,[P]
	    addps	xmm0,dqword [g_NormalDY]
	    call	Map
	    movss	[N+4],xmm0
	    movaps	xmm0,[P]
	    subps	xmm0,dqword [g_NormalDY]
	    call	Map
	    movss	xmm1,[N+4]
	    subss	xmm1,xmm0
	    movss	[N+4],xmm1
	    ; compute z coordinate
	    movaps	xmm0,[P]
	    addps	xmm0,dqword [g_NormalDZ]
	    call	Map
	    movss	[N+8],xmm0
	    movaps	xmm0,[P]
	    subps	xmm0,dqword [g_NormalDZ]
	    call	Map
	    movss	xmm1,[N+8]
	    subss	xmm1,xmm0
	    movss	[N+8],xmm1
	    ; normalize
	    movaps	xmm0,[N]
	    normalize3
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
	    restore	P,N
;-------------------------------------------------------------------------------
; NAME:     Shade
; IN:       xmm0.xyz    position
; IN:       xmm1.xyz    normal vector
; IN:       edi         material ID
; OUT:      xmm0.xyz    color
;-------------------------------------------------------------------------------
align 64
Shade:
	    P		equ rbp-16
	    N		equ rbp-32
	    RGB 	equ rbp-48
	    C		equ rbp-64
	    NdotL	equ rbp-80
	    L		equ rbp-96
	    AOScale	equ rbp-112
	    AO		equ rbp-128
	    Temp	equ rbp-144
	    Idx 	equ rbp-148
	    MatID	equ rbp-152
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,256
	    movaps	[P],xmm0
	    movaps	[N],xmm1
	    mov 	[MatID],edi
	    ;
	    ; AO
	    ;
	    xorps	xmm0,xmm0
	    movaps	[AO],xmm0
	    movaps	xmm0,dqword [g_10_0]
	    movaps	[AOScale],xmm0
	    mov 	dword [Idx],0
.AOLoop:
	    cvtsi2ss	xmm0,[Idx]
	    shufps	xmm0,xmm0,0x00
	    mulps	xmm0,xmm0
	    mulps	xmm0,dqword [g_0_015]
	    addps	xmm0,dqword [g_0_01]
	    movaps	[Temp],xmm0
	    mulps	xmm0,[N]
	    addps	xmm0,[P]
	    call	Map
	    movaps	xmm1,[Temp]
	    subps	xmm1,xmm0
	    mulps	xmm1,[AOScale]
	    movaps	xmm0,[AO]
	    addps	xmm0,xmm1
	    movaps	[AO],xmm0
	    movaps	xmm0,[AOScale]
	    mulps	xmm0,dqword [g_0_5]
	    movaps	[AOScale],xmm0
	    add 	dword [Idx],1
	    cmp 	dword [Idx],5
	    jne 	.AOLoop
	    movaps	xmm0,[AO]
	    maxps	xmm0,dqword [g_0_0]
	    minps	xmm0,dqword [g_1_0]
	    movaps	xmm1,dqword [g_1_0]
	    subps	xmm1,xmm0
	    movaps	[AO],xmm1
	    ;
	    ; Material ID Switch
	    ;
	    mov 	edi,[MatID]
	    cmp 	edi,1
	    je		.Mat1
	    cmp 	edi,2
	    je		.Mat2
	    jmp 	.MatDef
.Mat1:
	    movaps	xmm0,dqword [g_Red]
	    movaps	[RGB],xmm0
	    jmp 	.MatBreak
.Mat2:
	    movaps	xmm0,dqword [g_Green]
	    movaps	[RGB],xmm0
	    jmp 	.MatBreak
.MatDef:
	    movaps	xmm0,dqword [g_1_0]
	    movaps	[RGB],xmm0
.MatBreak:
	    ;
	    ; Light0 Contribution
	    ;
	    ; compute light vector and "N dot L" value
	    movaps	xmm0,dqword [g_L0Pos]
	    subps	xmm0,[P]
	    normalize3
	    movaps	[L],xmm0
	    movaps	xmm1,[N]
	    dot3
	    movaps	[NdotL],xmm0
	    ; cast shadow ray
	    movaps	xmm0,[P]
	    movaps	xmm1,[L]
	    call	CastShadowRay
	    movaps	xmm1,[NdotL]
	    mulps	xmm0,xmm1
	    mulps	xmm0,dqword [g_0_6]
	    addps	xmm0,dqword [g_0_4]
	    maxps	xmm0,dqword [g_0_0]
	    mulps	xmm0,dqword [g_0_7]
	    mulps	xmm0,dqword [RGB]
	    movaps	[C],xmm0
	    ;
	    ; Light1 Contribution
	    ;
	    ; compute light vector and "N dot L" value
	    movaps	xmm0,dqword [g_L1Pos]
	    subps	xmm0,[P]
	    normalize3
	    movaps	[L],xmm0
	    movaps	xmm1,[N]
	    dot3
	    movaps	[NdotL],xmm0
	    ; cast shadow ray
	    movaps	xmm0,[P]
	    movaps	xmm1,[L]
	    call	CastShadowRay
	    movaps	xmm1,[NdotL]
	    mulps	xmm0,xmm1
	    mulps	xmm0,dqword [g_0_6]
	    addps	xmm0,dqword [g_0_4]
	    maxps	xmm0,dqword [g_0_0]
	    mulps	xmm0,dqword [g_0_3]
	    mulps	xmm0,dqword [RGB]
	    movaps	xmm1,[C]
	    addps	xmm0,xmm1
	    mulps	xmm0,[AO]
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
	    restore	P,N,C,RGB,NdotL,L,AOScale,AO,Temp,Idx,MatID
;-------------------------------------------------------------------------------
; NAME:     ComputeColor
; IN:       xmm0.x      normalized x coordinate
; IN:       xmm0.y      normalized y coordinate
; OUT:      xmm0.xyz    pixel color
;-------------------------------------------------------------------------------
align 64
ComputeColor:
	    X		equ rbp-32
	    Y		equ rbp-48
	    RD		equ rbp-64
	    P		equ rbp-80
	    N		equ rbp-96
	    MatID	equ rbp-100
	    push	rbp
	    mov 	rbp,rsp
	    sub 	rsp,128
	    ; save function parameters on the stack
	    shufps	xmm0,xmm0,0x00
	    shufps	xmm1,xmm1,0x00
	    movaps	[X],xmm0
	    movaps	[Y],xmm1
	    ; compute z axis
	    xorps	xmm0,xmm0
	    subps	xmm0,dqword [g_CamPos]
	    normalize3
	    movaps	xmm7,xmm0
	    ; compute x axis
	    movaps	xmm0,dqword [g_UnitY]
	    movaps	xmm1,xmm7
	    cross
	    normalize3
	    movaps	xmm6,xmm0
	    ; compute y axis
	    movaps	xmm0,xmm7
	    movaps	xmm1,xmm6
	    cross
	    normalize3
	    ; compute ray direction
	    mulps	xmm0,[Y]
	    mulps	xmm6,[X]
	    movaps	xmm1,xmm7
	    mulps	xmm1,dqword [g_0_5]
	    addps	xmm7,xmm1
	    addps	xmm0,xmm6
	    addps	xmm0,xmm7
	    normalize3
	    movaps	[RD],xmm0
	    ; cast ray
	    movaps	xmm0,dqword [g_CamPos]
	    movaps	xmm1,[RD]
	    call	CastRay
	    mov 	[MatID],eax
	    ; return if there is no intersection
	    movaps	xmm1,xmm0
	    cmpltps	xmm0,dqword [g_0_0]
	    movd	eax,xmm0
	    cmp 	eax,0xffffffff
	    je		.Return
	    ; compute intersection point
	    movaps	xmm0,[RD]
	    mulps	xmm0,xmm1
	    addps	xmm0,dqword [g_CamPos]
	    movaps	[P],xmm0
	    ; compute normal vector
	    call	ComputeNormal
	    movaps	[N],xmm0
	    ; shade
	    mov 	edi,[MatID]
	    movaps	xmm0,[P]
	    movaps	xmm1,[N]
	    call	Shade
.Return:
	    mov 	rsp,rbp
	    pop 	rbp
	    ret
	    restore	X,Y,RD,P,N,MatID
;===============================================================================
; Get number of CPUs
;-------------------------------------------------------------------------------
align 16
GetCPUsNum:
  cpuset equ rbp-32
    push      rbp
    mov       rbp, rsp
    sub       rsp, 32
    mov       eax, 204	    ; sys_sched_getaffinity
    xor       edi, edi	    ; pid, zero = calling process
    mov       esi, 32	    ; number of cpuset bytes to read
    lea       rdx, [cpuset] ; where to write
    syscall
    xor       eax, eax
    xor       edx, edx
  .L0:
    mov       ecx, 64
    mov       rdi, [cpuset+rdx*8]
  .L1:
    shr       rdi, 1
    jnc       .L2
    add       eax, 1
  .L2:
    sub       ecx, 1
    jnz       .L1
    add       edx, 1
    cmp       edx, 4
    jne       .L0
    mov       rsp, rbp
    pop       rbp
    ret
  restore cpuset
;===============================================================================
; Compute image tiles
;-------------------------------------------------------------------------------
align 16
ComputeImageThread:
  startx equ rbp-4
  starty equ rbp-8
  tid equ rbp-12
    push      rbx rbp r13 r14 r15
    mov       rbp, rsp
    sub       rsp, 32
    mov       edi, 1
    lock
    xadd      [g_thread_counter], edi
    mov       [tid], edi
  .ComputeTile:
    mov       r15d, 1
    lock
    xadd      [g_imgtile], r15d     ; r15 is tile index
    cmp       r15d, TILES_NUM
    jge       .Finish
    xor       edx, edx
    mov       eax, r15d
    mov       edi, TILESX_NUM
    div       edi
    imul      eax, TILE_SIZE	    ; pixel y coord
    imul      edx, TILE_SIZE	    ; pixel x coord
    mov       [startx], edx
    mov       [starty], eax
    imul      eax, IMAGE_WIDTH
    add       eax, edx
    shl       eax, 2
    mov       rbx, [g_imgptr]
    add       rbx, rax
    xor       r14d, r14d	    ; r14 is row counter
  .ComputeRow:
    xor       r13d, r13d	    ; r13 is pixel counter
  .ComputePixel:
    mov       edx, [startx]
    mov       eax, [starty]
    add       edx, r13d
    add       eax, r14d

    xorps     xmm0, xmm0
    xorps     xmm1, xmm1
    cvtsi2ss  xmm0, edx 	    ; xmm0 = | 0 0 0 x |
    cvtsi2ss  xmm1, eax 	    ; xmm1 = | 0 0 0 y |
    divss     xmm0, [g_image_width]
    divss     xmm1, [g_image_height]
    subss     xmm0, [g_0_5]
    subss     xmm1, [g_0_5]
    addps     xmm0, xmm0
    addps     xmm1, xmm1
    mulss     xmm0, [g_1_77]
    call      ComputeColor
    ;cmp       dword [tid], 1
    ;jne       .L0
    ;mulps     xmm0, dqword [g_0_5]
  ;.L0:
    minps     xmm0, dqword [g_1_0]
    maxps     xmm0, dqword [g_0_0]
    mulps     xmm0, dqword [g_255_0]
    cvttps2dq xmm0, xmm0
    pshufb    xmm0, dqword [g_img_conv_mask]
    movd      eax, xmm0
    or	      eax, 0xff000000
    mov       [rbx+r13*4], eax

    add       r13d, 1
    cmp       r13d, TILE_SIZE
    jne       .ComputePixel
    add       rbx, IMAGE_WIDTH*4    ; move to the next row
    add       r14d, 1
    cmp       r14d, TILE_SIZE
    jne       .ComputeRow
    jmp       .ComputeTile
  .Finish:
    mov       eax, [tid]
    lea       rbx, [g_thread_done+4*rax]
    mov       dword [rbx], 1 ; mark that this thread has finished rendering
    mov       eax, 202	     ; sys_futex
    mov       rdi, rbx	     ; address
    mov       esi, 1	     ; FUTEX_WAKE
    mov       edx, 1	     ; max num of threads to wake
    syscall		     ; wake main thread
    mov       rsp, rbp
    pop       r15 r14 r13 rbp rbx
    ret
  restore startx, starty, tid
;===============================================================================
; Save image to TGA file
;-------------------------------------------------------------------------------
align 16
SaveImage:
    push      rbx
    mov       eax, 85
    mov       rdi, g_tga_name
    mov       esi, 110000000b
    syscall
    mov       rbx, rax
    mov       eax, 1
    mov       rdi, rbx
    mov       rsi, g_tga_head
    mov       edx, 18
    syscall
    mov       eax, 1
    mov       rdi, rbx
    mov       rsi, [g_imgptr]
    mov       edx, IMAGE_WIDTH*IMAGE_HEIGHT*4
    syscall
    pop       rbx
    ret
;===============================================================================
; Allocate memory using sys_mmap
; [in] rdi: size in bytes
; [out] rax: pointer to the allocated memory
;-------------------------------------------------------------------------------
align 16
AllocMem:
    sub       rsp, 8
    mov       eax, 9	      ; sys_mmap
    mov       rsi, rdi	      ; length
    xor       edi, edi	      ; addr
    mov       edx, 0x1+0x2    ; PROT_READ | PROT_WRITE
    mov       r10d, 0x02+0x20 ; MAP_PRIVATE | MAP_ANONYMOUS
    mov       r8, -1	      ; fd
    xor       r9d, r9d	      ; offset
    syscall
    add       rsp, 8
    ret
;===============================================================================
; Create, compute and save image
;-------------------------------------------------------------------------------
align 16
Main:
  threads_num equ rbp-4
    push      rbp
    mov       rbp, rsp
    sub       rsp, 8
    mov       rdi, IMAGE_WIDTH*IMAGE_HEIGHT*4
    call      AllocMem
    mov       [g_imgptr], rax

    call      GetCPUsNum
    mov       dword [threads_num], eax

    mov       r15d, [threads_num]
  .CreateThread:
    mov       edi, 4096
    call      AllocMem
    mov       rsi, rax				   ; stack address
    add       rsi, 4096
    mov       eax, 56				   ; sys_clone
    mov       edi, 0x100+0x200+0x400+0x800+0x10000 ; CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD
    xor       edx, edx
    syscall
    test      eax, eax
    jnz       .Parent
    call      ComputeImageThread
    mov       eax, 60  ; sys_exit
    xor       edi, edi ; exit code
    syscall
  .Parent:
    sub       r15d, 1
    jnz       .CreateThread

    mov       rbx, g_thread_done
    xor       r15d, r15d
  .WaitForThread:
    cmp       r15d, [threads_num]
    je	      .WaitForThreadEnd
    mov       eax, [rbx+r15*4]
    add       r15d, 1
    cmp       eax, 1
    je	      .WaitForThread
    mov       eax, 202	   ; sys_futex
    lea       rdi, [rbx-4+r15*4] ; address to wait on
    mov       esi, 0	   ; FUTEX_WAIT
    mov       edx, 0	   ; 
    xor       r10d, r10d
    syscall
    jmp       .WaitForThread
  .WaitForThreadEnd:

    call      SaveImage
    mov       rsp, rbp
    pop       rbp
    ret
  restore threads_num
;===============================================================================
; Program entry point
;-------------------------------------------------------------------------------
align 16
Start:
    call      Main
    mov       eax, 60  ; sys_exit
    xor       edi, edi ; exit code
    syscall
;===============================================================================
segment readable writeable

align 1
g_tga_name db 'qjulia.tga',0
g_tga_head db 0,0,2,9 dup 0
	   db (IMAGE_WIDTH and 0x00ff),(IMAGE_WIDTH and 0xff00) shr 8
	   db (IMAGE_HEIGHT and 0x00ff),(IMAGE_HEIGHT and 0xff00) shr 8,32,0

align 4
g_imgtile dd 0
g_thread_counter dd 0
g_thread_done dd 16 dup 0

g_image_width dd 1280.0
g_image_height dd 720.0

align 8
g_imgptr dq 0

align 16
IMAGE_WIDTH = 1280
IMAGE_HEIGHT = 720
TILE_SIZE = 80
TILESX_NUM = IMAGE_WIDTH / TILE_SIZE
TILESY_NUM = IMAGE_HEIGHT / TILE_SIZE
TILES_NUM = TILESX_NUM * TILESY_NUM
;g_image_size dd 1280.0, 720.0, 1.0, 1.0

g_img_conv_mask db 8,4,0,12,12 dup 0x80

align 4
g_1_77			dd 1.77
g_EscapeThreshold	dd 16.0
g_MinNormPos		dd 0x00800000
g_log_p0		dd -0.789580278884799154124
g_log_p1		dd 16.3866645699558079767
g_log_p2		dd -64.1409952958715622951
g_log_q0		dd -35.6722798256324312549
g_log_q1		dd 312.093766372244180303
g_log_q2		dd -769.691943550460008604
g_log_c0		dd 0.693147180559945

align 16
g_InvMantMask		dd 4 dup (not 0x7f800000)
g_0_0			dd 4 dup 0.0
g_0_5			dd 4 dup 0.5
g_1_0			dd 4 dup 1.0
g_255_0 		dd 4 dup 255.0
g_16_0			dd 4 dup 128.0
g_10_0			dd 4 dup 10.0
g_0_6			dd 4 dup 0.6
g_0_4			dd 4 dup 0.4
g_0_7			dd 4 dup 0.7
g_0_3			dd 4 dup 0.3
g_0_01			dd 4 dup 0.01
g_0_015 		dd 4 dup 0.015
g_CamPos		dd 1.2,1.4,1.2,1.0
g_UnitY 		dd 0.0,1.0,0.0,0.0
g_UnitW 		dd 0.0,0.0,0.0,1.0
g_HitDist		dd 4 dup 0.001
g_ShadowHitDist 	dd 4 dup 0.0005
g_ShadowMaxDist 	dd 4 dup 10.0
g_MaxDist		dd 4 dup 40.0
g_NormalDX		dd 0.001,0.0,0.0,0.0
g_NormalDY		dd 0.0,0.001,0.0,0.0
g_NormalDZ		dd 0.0,0.0,0.001,0.0
g_L0Pos 		dd 10.0,8.0,-6.0,1.0
g_L1Pos 		dd -12.0,19.0,6.0,1.0
g_Red			dd 1.0,1.0,1.0,1.0
g_Green 		dd 1.0,1.0,1.0,1.0
g_BoxSize		dd 1.5,1.0,1.5,1.0
g_BoxEdge		dd 4 dup 0.03
g_ClearXYZ		dd 0x00000000,0x00000000,0x00000000,0xffffffff
g_ClearW		dd 0xffffffff,0xffffffff,0xffffffff,0x00000000
g_Quat			dd 0.2,0.0,0.0,-1.0
