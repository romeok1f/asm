
; here some code from http://locklessinc.com/articles/mutex_cv_futex/
; and from randal on the fasm board is collected
;
; this file is by no means correct
;  it is current a scratchpad


  align 16								       ;
  mem_alloc:								       ;
; rdi: size in bytes                                                           ;
; rax: pointer to the allocated memory                                         ;
;------------------------------------------------------------------------------;
  mov eax,9			       ; sys_mmap
  mov rsi,rdi			       ; length
  xor edi,edi			       ; addr
  mov edx,0x1+0x2		       ; PROT_READ | PROT_WRITE
  mov r10d,0x02+0x20		       ; MAP_PRIVATE | MAP_ANONYMOUS
  mov r8,-1			       ; fd
  xor r9d,r9d			       ; offset
  syscall
  ret
;==============================================================================;
  align 16								       ;
  thread_create:							       ;
; rbx: mutex address                                                           ;
;------------------------------------------------------------------------------;
  mov edi,4096
  call mem_alloc
  mov rsi,rax
  add rsi,4096
  mov eax,56			       ; sys_clone
  mov edi,0x100+0x200+0x400+0x800+0x10000
  xor edx,edx
  syscall
  test eax,eax
  jnz .ret
  call thread
  mov dword [rbx],1
  mov eax,202			       ; sys_futex
  mov rdi,rbx			       ; mutex address
  mov esi,1			       ; FUTEX_WAKE
  mov edx,1			       ; wake 1 thread
  syscall
  mov eax,60			       ; sys_exit
  xor edi,edi			       ; exit code
  syscall
    .ret:
  ret
;==============================================================================;
  align 16								       ;
  thread_wait:								       ;
; rbx: mutex address                                                           ;
;------------------------------------------------------------------------------;
  mov eax,202			       ; sys_futex
  mov rdi,rbx			       ; mutex address
  mov esi,0			       ; FUTEX_WAIT
  mov edx,0			       ; mutex 'running' value
  xor r10d,r10d 		       ; unused but must be zero
  syscall
  ret



;#include <linux/errno.h>
;#include <limits.h>
;
;#  <linux/futex.h> isn't clean for asm inclusion
;#define FUTEX_WAIT_PRIVATE              128
;#define FUTEX_WAKE_PRIVATE              129
;#define FUTEX_REQUEUE_PRIVATE           131
;
;#define SYS_futex 202
;
;#define LOCK_CONTEND    0x0101



;typedef union mutex mutex;
;
;union mutex
;{
;        unsigned u;
;        struct
;        {
;                unsigned char locked;
;                unsigned char contended;
;        } b;
;};
;
;int mutex_init(mutex *m, const pthread_mutexattr_t *a)
;{
;        (void) a;
;        m->u = 0;
;        return 0;
;}



.globl mutex_init
.type	mutex_init,@function
mutex_init:
	xor		%eax, %eax
	mov		%eax, (%rdi)
	ret
.size	mutex_init, .-mutex_init


;int mutex_destroy(mutex *m)
;{
;        /* Do nothing */
;        (void) m;
;        return 0;
;}

.globl mutex_destroy
.type	mutex_destroy,@function
mutex_destroy:
	xor		%eax, %eax
	ret
.size	mutex_destroy, .-mutex_destroy


;int mutex_lock(mutex *m)
;{
;        int i, c;
;
;        /* Spin and try to take lock */
;        for (i = 0; i < 100; i++)
;        {
;                c = cmpxchg(m, 0, 1);
;                if (!c) return 0;
;
;                cpu_relax();
;        }
;
;        /* The lock is now contended */
;        if (c == 1) c = xchg_32(m, 2);
;
;        while (c)
;        {
;                /* Wait in the kernel */
;                sys_futex(m, FUTEX_WAIT_PRIVATE, 2, NULL, NULL, 0);
;                c = xchg_32(m, 2);
;        }
;
;        return 0;
;}

.globl mutex_lock
.type mutex_lock,@function
mutex_lock:
	mov		$100, %rcx

# Spin a bit to try to get lock
1:	mov		$1, %dl
	xchgb		(%rdi), %dl
	test		%dl, %dl
	jz		4f
	rep; nop
	add		$-1, %ecx
	jnz		1b
	
# Set up syscall details
	mov		$LOCK_CONTEND, %edx
	mov		$FUTEX_WAIT_PRIVATE, %esi
	xor		%r10, %r10
	jmp		3f
	
# Wait loop
2:	mov		$SYS_futex, %eax
	syscall
3:	mov		%edx, %eax
	xchgl		(%rdi), %eax
	test		$1, %eax
	jnz		2b
4:	xor		%eax, %eax
	ret
.size	mutex_lock, .-mutex_lock

;int mutex_unlock(mutex *m)
;{
;        int i;
;
;        /* Unlock, and if not contended then exit. */
;        if (*m == 2)
;        {
;                *m = 0;
;        }
;        else if (xchg_32(m, 0) == 1) return 0;
;
;        /* Spin and hope someone takes the lock */
;        for (i = 0; i < 200; i++)
;        {
;                if (*m)
;                {
;                        /* Need to set to state 2 because there may be waiters */
;                        if (cmpxchg(m, 1, 2)) return 0;
;                }
;                cpu_relax();
;        }
;
;        /* We need to wake someone up */
;        sys_futex(m, FUTEX_WAKE_PRIVATE, 1, NULL, NULL, 0);
;
;        return 0;
;}
.globl mutex_unlock
.type mutex_unlock,@function
mutex_unlock:
	cmpl		$1, (%rdi)
	jne		1f
	mov		$1, %eax
	xor		%ecx, %ecx
	lock; cmpxchgl  %ecx, (%rdi)
	jz		3f
1:	movb		$0, (%rdi) 

# Spin, and hope someone takes the lock
	mov		$200, %ecx
2:	testb		$1, (%rdi)
	jnz		3f
	rep; nop
	add		$-1, %ecx 
	jnz		2b

# Wake up someone
	movb		$0, 1(%rdi)
	mov		$SYS_futex, %eax
	mov		$FUTEX_WAKE_PRIVATE, %esi
	mov		$1, %edx
	syscall
	
3:	xor		%eax, %eax
	ret
.size	mutex_unlock, .-mutex_unlock



;int mutex_trylock(mutex *m)
;{
;        /* Try to take the lock, if is currently unlocked */
;        unsigned c = cmpxchg(m, 0, 1);
;        if (!c) return 0;
;        return EBUSY;
;}

.globl mutex_trylock
.type mutex_trylock,@function
mutex_trylock:
	mov		$1, %eax
	mov		$EBUSY, %edx
	xchgb		(%rdi), %al
	test		%al, %al
	cmovnz		%edx, %eax
	retq
.size	mutex_trylock, .-mutex_trylock



;typedef struct cv cv;
;struct cv
;{
;        mutex *m;
;        int seq;
;        int pad;
;};
;
;#define PTHREAD_COND_INITIALIZER {NULL, 0, 0}

int cond_init(cv *c, pthread_condattr_t *a)
{
	(void) a;
	
	c->m = NULL;
	
	/* Sequence variable doesn't actually matter, but keep valgrind happy */
	c->seq = 0;
	
	return 0;
}


.globl cond_init
.type cond_init,@function
cond_init:
	xor		%rax, %rax
	mov		%rax, (%rdi)
	mov		%rax, 8(%rdi)
	ret
.size	cond_init, .-cond_init


;int cond_destroy(cv *c)
;{
;        /* No need to do anything */
;        (void) c;
;        return 0;
;}


.globl cond_destroy
.type cond_destroy,@function
cond_destroy:
	xor		%eax, %eax
	ret
.size	cond_destroy, .-cond_destroy






;int cond_signal(cv *c)
;{
;        /* We are waking someone up */
;        atomic_add(&c->seq, 1);
;
;        /* Wake up a thread */
;        sys_futex(&c->seq, FUTEX_WAKE_PRIVATE, 1, NULL, NULL, 0);
;
;        return 0;
;}


.globl cond_signal
.type cond_signal,@function
cond_signal:
	lock; addl      $1, (%rdi)
	mov		$SYS_futex, %eax
	mov		$FUTEX_WAKE_PRIVATE, %esi
	mov		$1, %edx
	syscall
	xor		%eax, %eax
	ret 
.size	cond_signal, .-cond_signal





;int cond_broadcast(cv *c)
;{
;        mutex *m = c->m;
;
;        /* No mutex means that there are no waiters */
;        if (!m) return 0;
;
;        /* We are waking everyone up */
;        atomic_add(&c->seq, 1);
;
;        /* Wake one thread, and requeue the rest on the mutex */
;        sys_futex(&c->seq, FUTEX_REQUEUE_PRIVATE, 1, (void *) INT_MAX, m, 0);
;
;        return 0;
;}



.globl cond_broadcast
.type cond_broadcast,@function
cond_broadcast:
	mov		8(%rdi), %r8
	cmpq	$0, %r8
	je		1f
	lock; addl      $1, (%rdi)
	mov		$SYS_futex, %eax
	mov		$FUTEX_REQUEUE_PRIVATE, %esi
	mov		$1, %edx
	mov		$INT_MAX, %r10
	syscall
1:	xor		%eax, %eax
	ret 
.size	cond_broadcast, .-cond_broadcast






;int cond_wait(cv *c, mutex *m)
;{
;        int seq = c->seq;
;
;        if (c->m != m)
;        {
;                /* Atomically set mutex inside cv */
;                cmpxchg(&c->m, NULL, m);
;                if (c->m != m) return EINVAL;
;        }
;
;        mutex_unlock(m);
;
;        sys_futex(&c->seq, FUTEX_WAIT_PRIVATE, seq, NULL, NULL, 0);
;
;        while (xchg_32(&m->b.locked, 257) & 1)
;        {
;                sys_futex(m, FUTEX_WAIT_PRIVATE, 257, NULL, NULL, 0);
;        }
;
;        return 0;
;}


.globl cond_wait
.type cond_wait,@function
cond_wait:
	cmp		8(%rdi), %rsi
	jne		4f

# Hack, save seq into r8 since unlock doesn't touch it
1:	movl	(%rdi), %r8d

# Hack, save mutex into r9 (we can be awoken after cond is destroyed)
	mov		%rsi, %r9

# Unlock
	push	%rbp
	mov		%rdi, %rbp
	mov		%rsi, %rdi
	call	mutex_unlock
	mov		%rbp, %rdi
	pop		%rbp

# Setup for wait on seq 
	movl	%r8d, %edx
	mov		$SYS_futex, %eax
	xor		%r10, %r10
	mov		$FUTEX_WAIT_PRIVATE, %esi
	syscall
	
# Set up for wait on mutex
	mov		%r9, %rdi
	mov		$LOCK_CONTEND, %edx
	jmp		3f
	
# Wait loop
2:	mov		$SYS_futex, %eax
	syscall
3:	mov		%edx, %eax
	xchgl	(%rdi), %eax
	test	$1, %eax
	jnz		2b
	
	xor		%eax, %eax
	ret
	
4:	xor		%rax, %rax
	lock; cmpxchgq %rsi, 8(%rdi)
	jz		1b
	cmp		8(%rdi), %rsi
	je		1b
5:	mov		$EINVAL, %eax
	ret	
.size	cond_wait, .-cond_wait





;;;;;;;;;
; mutex ;
;;;;;;;;;

_MutexCreate:
	; rcx: address of critial section object
		sub   rsp, 8*5
	       call   qword[__imp_InitializeCriticalSection]
		add   rsp, 8*5
		ret
_MutexLock:
	; rcx: address of critial section object
		sub   rsp, 8*5
	       call   qword[__imp_EnterCriticalSection]
		add   rsp, 8*5
		ret
_MutexUnlock:
	; rcx: address of critial section object
		sub   rsp, 8*5
	       call   qword[__imp_LeaveCriticalSection]
		add   rsp, 8*5
		ret
_MutexDestroy:
	; rcx: address of critial section object
		sub   rsp, 8*5
	       call   qword[__imp_InitializeCriticalSection]
		add   rsp, 8*5
		ret

;;;;;;;;;
; event ;
;;;;;;;;;

_EventCreate:
	; no arguments
		sub   rsp, 8*5
		xor   ecx, ecx
		xor   edx, edx
		xor   r8d, r8d
		xor   r9d, r9d
	       call   qword[__imp_CreateEvent]
		add   rsp, 8*5
		ret
_EventSignal:
	; rcx: handle
		sub   rsp, 8*5
	       call   qword[__imp_SetEvent]
		add   rsp, 8*5
		ret
_EventWait:
	; rcx: handle
	; rdx: address of critial section object
	       push   rbx rsi
		sub   rsp, 8*5
		mov   rbx, rcx
		mov   rsi, rdx
		mov   rcx, rdx
	       call   qword[__imp_LeaveCriticalSection]
		mov   rcx, rbx
		 or   edx, -1
	       call   qword[__imp_WaitForSingleObject]
		mov   rcx, rsi
	       call   qword[__imp_EnterCriticalSection]
		add   rsp, 8*5
		pop   rsi rbx
		ret
_EventDestroy:
	; rcx: handle
		sub   rsp, 8*5
	       call   qword[__imp_CloseHandle]
		add   rsp, 8*5
		ret

;;;;;;;;;;
; thread ;
;;;;;;;;;;

_ThreadCreate:
	; rcx: start address
	; rdx: parameter to pass
		sub   rsp, 8*7
		mov   r8, rcx
		mov   r9, rdx
		xor   ecx, ecx
		xor   edx, edx
		mov   qword[rsp+8*4], rcx
		mov   qword[rsp+8*5], rcx
	       call   qword[__imp_CreateThread]
		add   rsp, 8*7
		ret
_ThreadJoin:
	; rcx: handle
	       push   rbx
		sub   rsp, 8*4
		mov   rbx, rcx
		 or   edx, -1
	       call   qword[__imp_WaitForSingleObject]
		mov   rcx, rbx
	       call   qword[__imp_CloseHandle]
		add   rsp, 8*4
		pop   rbx
		ret

_ExitProcess:
	; rcx is exit code
		sub   rsp, 8*5
		jmp   qword[__imp_ExitProcess]
_ExitThread:
	; rcx is exit code
		sub   rsp, 8*5
		jmp   qword[__imp_ExitThread]





;;;;;;;;;;
; timing ;
;;;;;;;;;;

_GetTime:
	; out: rax  time in ms
	;      rdx  fractional part of time in ms
		sub   rsp, 8*9
		lea   rcx, [rsp+8*8]
	       call   qword [__imp_QueryPerformanceCounter]
		mov   rax, qword[Period]
		mul   qword[rsp+8*8]
	       xchg   rax, rdx
		add   rsp, 8*9
		ret

_SetFrequency:
	; no arguments
		sub   rsp, 8*5
		lea   rcx, [Frequency]
	       call   qword[__imp_QueryPerformanceFrequency]
		mov   dword[rsp], 64
		mov   dword[rsp+8], 1000
	       fild   dword[rsp]
	       fild   dword[rsp+8]
	     fscale
	       fstp   st1
	       fild   qword[Frequency]
	      fdivp   st1, st0
	      fistp   qword[Period]
		add   rsp, 8*5
		ret

_Sleep:
	; ecx  ms
		sub   rsp, 8*5
	       call   qword[__imp_Sleep]
		add   rsp, 8*5
		ret


;;;;;;;;;;
; memory ;
;;;;;;;;;;

_VirtualAlloc:
	; rcx is size
	       push   rsi  rdi
		mov   eax, 9				; sys_mmap
		mov   rsi, rcx				; length
		xor   edi, edi				; addr
		mov   edx, 0x1+0x2			; PROT_READ | PROT_WRITE
		mov   r10d, 0x02+0x20			; MAP_PRIVATE | MAP_ANONYMOUS
		 or   r8, -1				; fd
		xor   r9d, r9d				; offset
	    syscall
match =1,DEBUG{ add   dword[DebugBalance], 1}
		pop   rdi rsi
		ret

		sub   rsp, 8*5
		mov   rdx, rcx
		xor   ecx, ecx
		mov   r8d, MEM_COMMIT
		mov   r9d, PAGE_READWRITE
	       call   qword[__imp_VirtualAlloc]
		add   rsp, 8*5
		ret


_VirtualFree:
	; rcx is address
		sub   rsp, 8*5
		xor   edx, edx
		mov   r8d, MEM_RELEASE
	       test   rcx, rcx
		 jz   @f
match =1, DEBUG   {
		sub   dword[DebugBalance], 1   ; lockless because only read thread should call
}
	       call   qword[__imp_VirtualFree]
	   @@:	add   rsp, 8*5
		ret




;;;;;;;;;;;;;;;;
; input/output ;
;;;;;;;;;;;;;;;;

_SetStdHandles:
	; no arguments
	; these are always 0,1,2
		ret


_WriteOut_Output:
		lea   rcx, [Output]
_WriteOut:
	; in: rcx  address of string start
	;     rdi  address of string end
		sub   rsp, 8*9
		mov   r8, rdi
		sub   r8, rcx
		mov   rdx, rcx
		mov   qword[rsp+8*4], 0
		mov   rcx, qword[hStdOut]
		lea   r9, [rsp+8*8]
	       call   qword[__imp_WriteFile]
		add   rsp, 8*9
		ret


_WriteError:
	; in: rcx  address of string start
	;     rdi  address of string end
		sub   rsp, 8*9
		mov   r8, rdi
		sub   r8, rcx
		mov   rdx, rcx
		mov   qword[rsp+8*4], 0
		mov   rcx, qword[hStdError]
		lea   r9, [rsp+8*8]
	       call   qword[__imp_WriteFile]
		add   rsp, 8*9
		ret



_ReadIn:
	; out: eax =  0 if not file end
	;      eax = -1 if file end
	;      rsi address of string start
	;      rcx address of string end
	;
	; uses global InputBuffer and InputBufferSizeB
	; reads one line and then returns
	; any char < ' ' is considered a newline char and

	       push   rbx
		mov   rsi, qword[InputBuffer]
		mov   rbx, rsi
		sub   rsp, 8*8
.Read:
		mov   rcx, qword[InputBufferSizeB]
		add   rcx, rsi
		cmp   rbx, rcx
		     ;   jae   .ReAlloc
.ReAllocRet:
		mov   rcx, qword[hStdIn]
		mov   rdx, rbx
		mov   r8d, 1
		lea   r9, [rsp+8*6]
		mov   qword[rsp+8*4], 0
	       call   qword[__imp_ReadFile]
		mov   dl, byte [rbx]
		add   rbx, 1
	       test   eax, eax
		jnz   .FileEnd
.Compare:
		cmp   dl, ' '
		jae   .Read

		mov   byte [rbx-1], 0
		xor   eax, eax
.Return:
		mov   rcx, rbx
		add   rsp, 8*8
		pop   rbx
		ret
.FileEnd:
		 or   eax, -1
		cmp   dword [rsp+8*6], 0
		 jz   .Return
		jmp   .Compare
.ReAlloc:
		sub   rcx, rsi
		add   ecx, 4096
		mov   qword[InputBufferSizeB], rcx
	       call   _VirtualAlloc
		mov   rdi, rax
		mov   rcx, rbx
		sub   rcx, rsi
		lea   rbx, [rcx+rax]
	  rep movsb
		mov   rcx, qword [InputBuffer]
		mov   rsi, rax
	       call   _VirtualFree
		mov   qword [InputBuffer], rsi
		jmp   .ReAllocRet


_ErrorBox:
	; rdi points to null terminated string to write to message box
	; this may be called from a leaf with no stack allignment
	; the purpose is a hard exit on failure
	       push   rbp
		mov   rbp, rsp
		sub   rsp, 8*8
		and   rsp, -16
		lea   rcx, [.user32]
	       call   qword[__imp_LoadLibrary]
		mov   rcx, rax
		lea   rdx, [.MessageBoxA]
	       call   qword[__imp_GetProcAddress]
		xor   ecx, ecx
		mov   rdx, rdi
		lea   r8, [.caption]
		mov   r9d, MB_OK
	       call   rax
		mov   rsp, rbp
		pop   rbp
		ret

.user32: db 'user32.dll',0
.MessageBoxA: db 'MessageBoxA',0
.caption: db 'error',0


_CheckCPU:
	       push   rbp rbx r15

match =1, CPU_HAS_POPCNT {
		lea   r15, [szCPUError.POPCNT]
		mov   eax, 1
		xor   ecx, ecx
	      cpuid
		and   ecx, (1 shl 23)
		cmp   ecx, (1 shl 23)
		jne   .Failed
}

match =1, CPU_HAS_AVX1 {
		lea   r15, [szCPUError.AVX1]
		mov   eax, 1
		xor   ecx, ecx
	      cpuid
		and   ecx, (1 shl 27) + (1 shl 28)
		cmp   ecx, (1 shl 27) + (1 shl 28)
		jne   .Failed
		mov   ecx, 0
	     xgetbv
		and   eax, (1 shl 1) + (1 shl 2)
		cmp   eax, (1 shl 1) + (1 shl 2)
		jne   .Failed
}

match =1, CPU_HAS_AVX2 {
		lea   r15, [szCPUError.AVX2]
		mov   eax, 7
		xor   ecx, ecx
	      cpuid
		and   ebx, (1 shl 5)
		cmp   ebx, (1 shl 5)
		jne   .Failed
}

match =1, CPU_HAS_BMI1 {
		lea   r15, [szCPUError.BMI1]
		mov   eax, 7
		xor   ecx, ecx
	      cpuid
		and   ebx, (1 shl 3)
		cmp   ebx, (1 shl 3)
		jne   .Failed
}

match =1, CPU_HAS_BMI2 {
		lea   r15, [szCPUError.BMI2]
		mov   eax, 7
		xor   ecx, ecx
	      cpuid
		and   ebx, (1 shl 8)
		cmp   ebx, (1 shl 8)
		jne   .Failed
}

		pop  r15 rbx rbp
		ret

.Failed:
		lea   rdi, [Output]
		lea   rcx, [szCPUError]
	       call   PrintString
		mov   rcx, r15
	       call   PrintString
		xor   eax,eax
	      stosd
		lea   rdi, [Output]
	       call   _ErrorBox
		xor   ecx,ecx
	       call   _ExitProcess



