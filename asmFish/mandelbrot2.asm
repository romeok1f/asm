format ELF64 executable 3
entry start
segment readable executable
;==============================================================================
macro IACA_START {
;  mov ebx,111
;  db 0x64,0x67,0x90
}
macro IACA_END {
;  mov ebx,222
;  db 0x64,0x67,0x90
}
;==============================================================================
  align 16
  thread:
;------------------------------------------------------------------------------
  virtual at rsp
    .startx dd ?
    .starty dd ?
  end virtual
  push rbp rbx
  mov rbp,rsp
  sub rsp,32
  and rsp,-32
    .loop_tile:
  mov r15d,1
  lock xadd [image_tile],r15d
  cmp r15d,TILE_COUNT
  jge .finish
  xor edx,edx
  mov eax,r15d
  mov edi,TILE_X_COUNT
  div edi
  imul eax,TILE_SIZE
  imul edx,TILE_SIZE
  mov [.startx],edx
  mov [.starty],eax
  imul eax,IMAGE_SIZE
  add eax,edx
  shl eax,2
  mov rbx,[image_ptr]
  add rbx,rax
  xor r14d,r14d
    align 32
    .loop_row:
  xor r13d,r13d
    align 32
    .loop_pixel:
  mov edx,[.startx]
  mov eax,[.starty]
  add edx,r13d
  add eax,r14d
  ;------------------------------------ compute color
  vmovaps ymm5,[image_size_rcp]
  vmovaps ymm6,[.c_m0_5]
  vxorps ymm0,ymm0,ymm0
  vxorps ymm2,ymm2,ymm2
  vcvtsi2ss xmm0,xmm0,edx
  vcvtsi2ss xmm2,xmm2,eax
  vbroadcastss ymm0,xmm0
  vbroadcastss ymm2,xmm2
  vmovaps ymm1,ymm0
  vaddps ymm0,ymm0,[.c_0_to_7]
  vaddps ymm1,ymm1,[.c_8_to_15]
  vfmadd213ps ymm0,ymm5,ymm6
  vfmadd213ps ymm1,ymm5,ymm6
  vfmadd213ps ymm2,ymm5,ymm6
  vaddps ymm13,ymm0,ymm0	      ; ymm13 = a0
  vaddps ymm14,ymm1,ymm1	      ; ymm14 = a1
  vaddps ymm15,ymm2,ymm2	      ; ymm15 = b
  vaddps ymm13,ymm13,[.c_m0_5]
  vaddps ymm14,ymm14,[.c_m0_5]
  vxorps ymm0,ymm0,ymm0 	      ; ymm0 = x0
  vxorps ymm1,ymm1,ymm1 	      ; ymm1 = x1
  vxorps ymm2,ymm2,ymm2 	      ; ymm2 = y0
  vxorps ymm3,ymm3,ymm3 	      ; ymm3 = y1
  vxorps ymm4,ymm4,ymm4 	      ; ymm4 = x0^2
  vxorps ymm5,ymm5,ymm5 	      ; ymm5 = x1^2
  vxorps ymm6,ymm6,ymm6 	      ; ymm6 = y0^2
  vxorps ymm7,ymm7,ymm7 	      ; ymm7 = y1^2
  vmovaps ymm12,[.c_4_0]	      ; ymm12 = 4.0
  vpcmpeqd ymm10,ymm10,ymm10	      ; ymm10 = (a0,b) iterations
  vpcmpeqd ymm11,ymm11,ymm11	      ; ymm11 = (a1,b) iterations
  mov eax,256
    align 32
    .loop:
  vaddps ymm0,ymm0,ymm0 	      ; ymm0 = 2*x0
  vaddps ymm1,ymm1,ymm1 	      ; ymm1 = 2*x1
  vfmadd213ps ymm2,ymm0,ymm15	      ; ymm2 = y0n = 2*x0*y0 + b
  vfmadd213ps ymm3,ymm1,ymm15	      ; ymm3 = y1n = 2*x1*y1 + b
  vsubps ymm0,ymm4,ymm6 	      ; ymm0 = x0^2 - y0^2
  vsubps ymm1,ymm5,ymm7 	      ; ymm1 = x1^2 - y1^2
  vaddps ymm0,ymm0,ymm13	      ; ymm0 = x0n = x0^2 - y0^2 + a
  vaddps ymm1,ymm1,ymm14	      ; ymm1 = x1n = x1^2 - y1^2 + a
  vmulps ymm4,ymm0,ymm0 	      ; ymm4 = x0n^2
  vmulps ymm5,ymm1,ymm1 	      ; ymm5 = x1n^2
  vmulps ymm6,ymm2,ymm2 	      ; ymm6 = y0n^2
  vmulps ymm7,ymm3,ymm3 	      ; ymm7 = y1n^2
  vaddps ymm8,ymm4,ymm6 	      ; ymm8 = m0 = x0n^2 + y0n^2
  vaddps ymm9,ymm5,ymm7 	      ; ymm9 = m1 = x1n^2 + y1n^2
  vcmpltps ymm8,ymm8,ymm12	      ; ymm8 = ymm8 < 4.0
  vcmpltps ymm9,ymm9,ymm12	      ; ymm9 = ymm9 < 4.0
  vpsubd ymm10,ymm10,ymm8	      ; increment ymm10 when m0 < 4.0
  vpsubd ymm11,ymm11,ymm9	      ; increment ymm11 when m1 < 4.0
  sub eax,1
  jnz .loop
  vmovdqa ymm0,[.c_255]
  vmovaps ymm2,[.c_1div255]
  vpsubd ymm10,ymm0,ymm10
  vpsubd ymm11,ymm0,ymm11
  vcvtdq2ps ymm0,ymm10
  vcvtdq2ps ymm1,ymm11
  vmulps ymm0,ymm0,ymm2
  vmulps ymm1,ymm1,ymm2
  vmulps ymm0,ymm0,ymm0
  vmulps ymm1,ymm1,ymm1
  vmulps ymm0,ymm0,ymm0
  vmulps ymm1,ymm1,ymm1
  vmulps ymm0,ymm0,ymm0
  vmulps ymm1,ymm1,ymm1
  vmovaps ymm2,[.c_255_0]
  vmulps ymm0,ymm0,ymm2
  vmulps ymm1,ymm1,ymm2
  vcvttps2dq ymm0,ymm0
  vcvttps2dq ymm1,ymm1
  vmovdqa ymm6,[.c_ff000000]
  vpslld ymm2,ymm0,8
  vpslld ymm4,ymm1,8
  vpslld ymm3,ymm0,16
  vpslld ymm5,ymm1,16
  vpor ymm0,ymm0,ymm2
  vpor ymm1,ymm1,ymm4
  vpor ymm3,ymm3,ymm6
  vpor ymm5,ymm5,ymm6
  vpor ymm0,ymm0,ymm3
  vpor ymm1,ymm1,ymm5
  vmovdqa [rbx+r13*4],ymm0
  vmovdqa [rbx+r13*4+32],ymm1
  ;------------------------------------
  add r13d,16
  cmp r13d,TILE_SIZE
  jne .loop_pixel
  add rbx,IMAGE_SIZE*4
  add r14d,1
  cmp r14d,TILE_SIZE
  jne .loop_row
  jmp .loop_tile
    .finish:
  mov rsp,rbp
  pop rbx rbp
  ret
    align 32
    .c_0_to_7: dd 0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0
    .c_8_to_15: dd 8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0
    .c_16_to_23: dd 16.0,17.0,18.0,19.0,20.0,21.0,22.0,23.0
    .c_24_to_31: dd 24.0,25.0,26.0,27.0,28.0,29.0,30.0,31.0
    .c_m0_5: dd 8 dup -0.5
    .c_255: dd 8 dup 255
    .c_255_0: dd 8 dup 255.0
    .c_4_0: dd 8 dup 4.0
    .c_ff000000: dd 8 dup 0xff000000
    .c_1div255: dd 8 dup 0.003921569
;==============================================================================
  align 16
  mem_alloc:
; in: <rdi> size in bytes
; out: <rax> pointer to the allocated memory
;------------------------------------------------------------------------------
  mov eax,9			      ; sys_mmap
  mov rsi,rdi			      ; length
  xor edi,edi			      ; addr
  mov edx,0x1+0x2		      ; PROT_READ | PROT_WRITE
  mov r10d,0x02+0x20		      ; MAP_PRIVATE | MAP_ANONYMOUS
  mov r8,-1			      ; fd
  xor r9d,r9d			      ; offset
  syscall
  ret
;==============================================================================
  align 16
  thread_create:
; in: <rbx> mutex address
;------------------------------------------------------------------------------
  mov edi,4096
  call mem_alloc
  mov rsi,rax
  add rsi,4096
  mov eax,56			      ; sys_clone
  mov edi,0x100+0x200+0x400+0x800+0x10000
  xor edx,edx
  syscall
  test eax,eax
  jnz .ret
  call thread
  mov dword [rbx],1
  mov eax,202			      ; sys_futex
  mov rdi,rbx			      ; mutex address
  mov esi,1			      ; FUTEX_WAKE
  mov edx,1			      ; wake 1 thread
  syscall
  mov eax,60			      ; sys_exit
  xor edi,edi			      ; exit code
  syscall
    .ret:
  ret
;==============================================================================
  align 16
  thread_wait:
; in: <rbx> mutex address
;------------------------------------------------------------------------------
  mov eax,202			      ; sys_futex
  mov rdi,rbx			      ; mutex address
  mov esi,0			      ; FUTEX_WAIT
  mov edx,0			      ; mutex 'running' value
  xor r10d,r10d 		      ; unused but must be zero
  syscall
  ret
;==============================================================================
  align 16
  image_save:
;------------------------------------------------------------------------------
  push rbx
  mov eax,85
  mov rdi,.tga_name
  mov esi,110000000b
  syscall
  mov rbx,rax
  mov eax,1
  mov rdi,rbx
  mov rsi,.tga_head
  mov edx,18
  syscall
  mov eax,1
  mov rdi,rbx
  mov rsi,[image_ptr]
  mov edx,IMAGE_SIZE*IMAGE_SIZE*4
  syscall
  pop rbx
  ret
    .tga_name db 'mandelbrot2.tga',0
    .tga_head db 0,0,2,9 dup 0
	      db (IMAGE_SIZE and 0x00ff),(IMAGE_SIZE and 0xff00) shr 8
	      db (IMAGE_SIZE and 0x00ff),(IMAGE_SIZE and 0xff00) shr 8,32,0
;==============================================================================
  align 16
  main:
;------------------------------------------------------------------------------
  mov edi,IMAGE_SIZE*IMAGE_SIZE*4
  call mem_alloc
  mov [image_ptr],rax
  xor r12d,r12d
    .loop_create:
  lea rbx,[thread_mutex+r12*4]
  call thread_create
  add r12d,1
  cmp r12d,THREAD_COUNT
  jne .loop_create
  xor r12d,r12d
    .loop_wait:
  lea rbx,[thread_mutex+r12*4]
  call thread_wait
  add r12d,1
  cmp r12d,THREAD_COUNT
  jne .loop_wait
  call image_save
  ret
;==============================================================================
  align 16
  start:
;------------------------------------------------------------------------------
  call main
  mov eax,60			      ; sys_exit
  xor edi,edi			      ; exit code
  syscall
;==============================================================================
segment readable writeable

align 4
THREAD_COUNT = 8
thread_mutex dd 0,0,0,0,0,0,0,0

align 8
image_ptr dq 0
align 4
image_tile dd 0

TILE_SIZE = 64
TILE_X_COUNT = IMAGE_SIZE / TILE_SIZE
TILE_Y_COUNT = IMAGE_SIZE / TILE_SIZE
TILE_COUNT = TILE_X_COUNT * TILE_Y_COUNT
IMAGE_SIZE = 1024

align 32
image_size_rcp: dd 8 dup 0.000976563 
;==============================================================================
