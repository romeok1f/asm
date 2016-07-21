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
  compute_color:
; in: <ymm0>, <ymm1> normalized x, y coordinates
; out: <ymm0>, <ymm1>, <ymm2> r, g, b color components
;------------------------------------------------------------------------------
  vaddps ymm0,ymm0,[.c_xoffset]
  vxorps ymm2,ymm2,ymm2               ; ymm2 = x
  vmovaps ymm3,ymm2                   ; ymm3 = y
  vmovaps ymm4,ymm2                   ; ymm4 = x^2
  vmovaps ymm5,ymm2                   ; ymm5 = y^2
  vxorps ymm8,ymm8,ymm8
  mov eax,256
    align 32
    .loop:
  IACA_START                          ; 12.00 cycles on HSW
  vmulps ymm3,ymm2,ymm3               ; ymm3 = x*y
  vsubps ymm2,ymm4,ymm5               ; ymm2 = x^2 - y^2
  vaddps ymm3,ymm3,ymm3               ; ymm3 = 2*x*y
  vaddps ymm2,ymm2,ymm0               ; ymm2 = xn = x^2 - y^2 + a
  vaddps ymm3,ymm3,ymm1               ; ymm3 = yn = 2*x*y + b
  vmulps ymm4,ymm2,ymm2               ; ymm4 = xn^2
  vmulps ymm5,ymm3,ymm3               ; ymm5 = yn^2
  vaddps ymm6,ymm2,ymm3               ; ymm6 = xn^2 + yn^2 = m2
  vcmpltps ymm7,ymm6,[.c_4_0]
  vandnps ymm7,ymm7,[.c_1_0]
  vaddps ymm8,ymm8,ymm7
  sub eax,1
  jnz .loop
  IACA_END
  vmovaps ymm0,ymm8
  vdivps ymm0,ymm0,[.c_255_0]
  vmulps ymm0,ymm0,ymm0
  vmulps ymm0,ymm0,ymm0
  vmulps ymm0,ymm0,ymm0
  vmovaps ymm1,ymm0
  vmovaps ymm2,ymm0
  ret
    align 32
    .c_4_0: dd 8 dup 4.0
    .c_1_0: dd 8 dup 1.0
    .c_255_0: dd 8 dup 255.0
    .c_xoffset: dd 8 dup -0.5
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
    .tile:
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
    .row:
  xor r13d,r13d
    align 16
    .pixel:
  mov edx,[.startx]
  mov eax,[.starty]
  add edx,r13d
  add eax,r14d
  ;------------------------------------ compute color
  vmovaps ymm2,[image_size]
  vmovaps ymm3,ymm2
  vrcpps ymm3,ymm3
  vcvtsi2ss xmm0,xmm0,edx
  vcvtsi2ss xmm1,xmm1,eax
  vbroadcastss ymm0,xmm0
  vbroadcastss ymm1,xmm1
  vaddps ymm0,ymm0,[.c_01234567f]
  vaddps ymm1,ymm1,ymm1
  vaddps ymm0,ymm0,ymm0
  vsubps ymm0,ymm0,ymm2
  vsubps ymm1,ymm1,ymm2
  vmulps ymm0,ymm0,ymm3
  vmulps ymm1,ymm1,ymm3
  call compute_color
  ;------------------------------------ convert color from RGB32F to BGRA8
  vxorps ymm3,ymm3,ymm3
  vmovaps ymm4,[.c_1_0]
  vminps ymm0,ymm0,ymm4
  vminps ymm1,ymm1,ymm4
  vminps ymm2,ymm2,ymm4
  vmaxps ymm0,ymm0,ymm3
  vmaxps ymm1,ymm1,ymm3
  vmaxps ymm2,ymm2,ymm3
  vmovaps ymm3,[.c_255_0]
  vmulps ymm0,ymm0,ymm3
  vmulps ymm1,ymm1,ymm3
  vmulps ymm2,ymm2,ymm3
  vcvttps2dq ymm0,ymm0
  vcvttps2dq ymm1,ymm1
  vcvttps2dq ymm2,ymm2
  vpslld ymm1,ymm1,8
  vpslld ymm0,ymm0,16
  vpor ymm0,ymm0,[.c_ff000000]
  vpor ymm1,ymm1,ymm2
  vpor ymm0,ymm0,ymm1
  vmovdqa [rbx+r13*4],ymm0
  ;------------------------------------
  add r13d,8
  cmp r13d,TILE_SIZE
  jne .pixel
  add rbx,IMAGE_SIZE*4
  add r14d,1
  cmp r14d,TILE_SIZE
  jne .row
  jmp .tile
    .finish:
  mov rsp,rbp
  pop rbx rbp
  ret
    align 32
    .c_01234567f: dd 0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0
    .c_1_0: dd 8 dup 1.0
    .c_255_0: dd 8 dup 255.0
    .c_ff000000: dd 8 dup 0xff000000
;==============================================================================
  align 16
  mem_alloc:
; in: <rdi> size in bytes
; out: <rax> pointer to the allocated memory
;------------------------------------------------------------------------------
  mov eax,9                           ; sys_mmap
  mov rsi,rdi                         ; length
  xor edi,edi                         ; addr
  mov edx,0x1+0x2                     ; PROT_READ | PROT_WRITE
  mov r10d,0x02+0x20                  ; MAP_PRIVATE | MAP_ANONYMOUS
  mov r8,-1                           ; fd
  xor r9d,r9d                         ; offset
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
  mov eax,56                          ; sys_clone
  mov edi,0x100+0x200+0x400+0x800+0x10000
  xor edx,edx
  syscall
  test eax,eax
  jnz .ret
  call thread
  mov dword [rbx],1
  mov eax,202                         ; sys_futex
  mov rdi,rbx                         ; mutex address
  mov esi,1                           ; FUTEX_WAKE
  mov edx,1                           ; wake 1 thread
  syscall
  mov eax,60                          ; sys_exit
  xor edi,edi                         ; exit code
  syscall
    .ret:
  ret
;==============================================================================
  align 16
  thread_wait:
; in: <rbx> mutex address
;------------------------------------------------------------------------------
  mov eax,202                         ; sys_futex
  mov rdi,rbx                         ; mutex address
  mov esi,0                           ; FUTEX_WAIT
  mov edx,0                           ; mutex 'running' value
  xor r10d,r10d                       ; unused but must be zero
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
    .tga_name db 'mandelbrot.tga',0
    .tga_head db 0,0,2,9 dup 0
              db (IMAGE_SIZE and 0x00ff),(IMAGE_SIZE and 0xff00) shr 8
              db (IMAGE_SIZE and 0x00ff),(IMAGE_SIZE and 0xff00) shr 8,32,0
;==============================================================================
  align 16
  main:
;------------------------------------------------------------------------------
  mov rdi,IMAGE_SIZE*IMAGE_SIZE*4
  call mem_alloc
  mov [image_ptr],rax
  mov rbx,thread0_mutex
  call thread_create
  mov rbx,thread1_mutex
  call thread_create
  mov rbx,thread2_mutex
  call thread_create
  mov rbx,thread3_mutex
  call thread_create
  mov rbx,thread0_mutex
  call thread_wait
  mov rbx,thread1_mutex
  call thread_wait
  mov rbx,thread2_mutex
  call thread_wait
  mov rbx,thread3_mutex
  call thread_wait
  call image_save
  ret
;==============================================================================
  align 16
  start:
;------------------------------------------------------------------------------
  call main
  mov eax,60                          ; sys_exit
  xor edi,edi                         ; exit code
  syscall
;==============================================================================
segment readable writeable

align 4
thread0_mutex dd 0
thread1_mutex dd 0
thread2_mutex dd 0
thread3_mutex dd 0

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
image_size: dd 8 dup 1024.0
;==============================================================================
