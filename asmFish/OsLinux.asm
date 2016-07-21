

;;;;;;;;;
; mutex ;
;;;;;;;;;


LOCK_CONTEND	= 0x0101

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


;int mutex_init(mutex *m, const pthread_mutexattr_t *a)
;{
;        (void) a;
;        m->u = 0;
;        return 0;
;}


_MutexCreate:
	; rcx: address of Mutex
	       push   rbx rsi rdi
		mov   rdi, rcx
		xor   eax, eax
		mov   dword[rdi], eax
		pop   rdi rsi rbx
		ret



;int mutex_destroy(mutex *m)
;{
;        /* Do nothing */
;        (void) m;
;        return 0;
;}

_MutexDestroy:
	; rcx: address of Mutex
	       push   rbx rsi rdi
		mov   rdi, rcx
		xor   eax, eax
		pop   rdi rsi rbx
		ret


;int mutex_lock(mutex *m)
;{
;        int i;
;
;        /* Try to grab lock */
;        for (i = 0; i < 100; i++)
;        {
;                if (!xchg_8(&m->b.locked, 1)) return 0;
;
;                cpu_relax();
;        }
;
;        /* Have to sleep */
;        while (xchg_32(&m->u, 257) & 1)
;        {
;                sys_futex(m, FUTEX_WAIT_PRIVATE, 257, NULL, NULL, 0);
;        }
;
;        return 0;
;}



_MutexLock:
	; rcx: address of Mutex
	       push   rbx rsi rdi
		mov   rdi, rcx
		mov   ecx, 100
	; Spin a bit to try to get lock
.1:		mov   dl, 1
	       xchg   dl, byte[rdi]
	       test   dl, dl
		 jz   .4
	    rep nop
		sub   ecx, 1
		jnz   .1
	; Set up syscall details
		mov   edx, LOCK_CONTEND
		mov   esi, FUTEX_WAIT_PRIVATE
		xor   r10, r10
		jmp   .3
	; Wait loop
.2:		mov   eax, sys_futex
	    syscall
.3:		mov   eax, edx
	       xchg   eax, dword[rdi]
	       test   eax, 1
		jnz   .2
.4:		xor   eax, eax
		pop   rdi rsi rbx
		ret



;int mutex_unlock(mutex *m)
;{
;        int i;
;
;        /* Locked and not contended */
;        if ((m->u == 1) && (cmpxchg(&m->u, 1, 0) == 1)) return 0;
;
;        /* Unlock */
;        m->b.locked = 0;
;
;        barrier();
;
;        /* Spin and hope someone takes the lock */
;        for (i = 0; i < 200; i++)
;        {
;                if (m->b.locked) return 0;
;
;                cpu_relax();
;        }
;
;        /* We need to wake someone up */
;        m->b.contended = 0;
;
;        sys_futex(m, FUTEX_WAKE_PRIVATE, 1, NULL, NULL, 0);
;
;        return 0;
;}


_MutexUnlock:
	; rcx: address of Mutex
	       push   rbx rsi rdi
		mov   rdi, rcx
		cmp   dword[rdi], 1
		jne   .1
		mov   eax, 1
		xor   ecx, ecx
       lock cmpxchg   dword[rdi], ecx
		 jz   .3
.1:		mov   byte[rdi], 0
	; Spin, and hope someone takes the lock
		mov   ecx, 200
.2:	       test   byte[rdi], 1
		jnz   .3
	    rep nop
		sub   ecx, 1
		jnz   .2
	; Wake up someone
		mov   byte[rdi+1], 0
		mov   esi, FUTEX_WAKE_PRIVATE
		mov   edx, 1
		mov   eax, sys_futex
	    syscall
		cmp   eax, -1
		 je   Failed_sys_futex

.3:		xor   eax, eax
		pop   rdi rsi rbx
		ret





;;;;;;;;;
; event ;
;;;;;;;;;


;typedef struct cv cv;
;struct cv
;{
;        mutex *m;
;        int seq;
;        int pad;
;};
;
;#define PTHREAD_COND_INITIALIZER {NULL, 0, 0}
;
;int cond_init(cv *c, pthread_condattr_t *a)
;{
;        (void) a;
;
;        c->m = NULL;
;
;        /* Sequence variable doesn't actually matter, but keep valgrind happy */
;        c->seq = 0;
;
;        return 0;
;}


_EventCreate:
	; rcx: address of ConditionalVariable
	       push   rbx rsi rdi
		mov   rdi, rcx
		xor   eax, eax
		mov   qword[rdi], rax
		mov   qword[rdi+8], rax
		pop   rdi rsi rbx
		ret

;int cond_destroy(cv *c)
;{
;        /* No need to do anything */
;        (void) c;
;        return 0;
;}

_EventDestroy:
	; rcx: address of ConditionalVariable
	       push   rbx rsi rdi
		mov   rdi, rcx
		xor   eax, eax
		pop   rdi rsi rbx
		ret



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

_EventSignal:
	; rcx: address of ConditionalVariable
	       push   rbx rsi rdi
		mov   rdi, rcx
	   lock add   dword[rdi], 1
		mov   eax, sys_futex
		mov   esi, FUTEX_WAKE_PRIVATE
		mov   edx, 1
	    syscall
		cmp   eax, -1
		 je   Failed_sys_futex
		xor   eax, eax
		pop   rdi rsi rbx
		ret




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


_EventWait:
	; rcx: address of ConditionalVariable
	; rdx: address of Mutex
	       push   rbx rsi rdi r14 r15
		mov   rdi, rcx
		mov   rsi, rdx
		cmp   rsi, qword[rdi+8]
		jne   .4
	; Hack, save seq into r8 since unlock doesn't touch it
.1:		mov   r14d, dword[rdi]
	; Hack, save mutex into r9 (we can be awoken after cond is destroyed)
		mov   r15, rsi
	; Unlock
		mov   rbx, rdi
		mov   rcx, rsi
	       call   _MutexUnlock
		mov   rdi, rbx
	; Setup for wait on seq
		mov   edx, r14d
		xor   r10, r10
		mov   esi, FUTEX_WAIT_PRIVATE
		mov   eax, sys_futex
	    syscall
	; Set up for wait on mutex
		mov   rdi, r15
		mov   edx, LOCK_CONTEND
		jmp   .3
	; Wait loop
.2:		mov   eax, sys_futex
	    syscall
.3:		mov   eax, edx
	       xchg   eax, dword[rdi]
	       test   eax, 1
		jnz   .2
		xor   eax, eax
		pop   r15 r14 rdi rsi rbx
		ret
	
.4:		xor   rax, rax
       lock cmpxchg   qword[rdi+8], rsi
		 jz   .1
		cmp   qword[rdi+8], rsi
		 je   .1
.5:		mov   eax, EINVAL
		pop   r15 r14 rdi rsi rbx
		ret






;;;;;;;;
; file ;
;;;;;;;;

_FileOpen:
	; in: rcx path string  
	; out: rax handle from CreateFile (win), fd (linux)  
	       push   rbx rsi rdi  
		mov   rdi, rcx
		mov   esi, O_RDWR
		mov   eax, sys_open
	    syscall  
		pop   rdi rsi rbx 
		ret

_FileClose:
	; in: rcx handle from CreateFile (win), fd (linux) 
	       push   rbx rsi rdi 
		mov   rdi, rcx 
		mov   eax, sys_close 
	    syscall 
		pop   rdi rsi rbx 
		ret

_FileMap:
	; in: rcx handle (win), fd (linux) 
	; out: rax base address 
	;      rdx handle from CreateFileMapping (win), size (linux) 
	; get file size 
	       push   rbp rbx rsi rdi r15
		sub   rsp, 20*8
		mov   rbp, rcx
		mov   rdi, rcx
		mov   rsi, rsp 
		mov   eax, sys_fstat 
	    syscall
		cmp   eax, -1
		 je   Failed_sys_fstat
		mov   rbx, qword[rsp+0x30] ; file size
	; map file
		pop   r8		; fd
		xor   edi, edi		; addr
		mov   rsi, rdx		; length
		mov   edx, PROT_READ	; protection flags
		mov   r10, MAP_PRIVATE	; mapping flags
		xor   r9d, r9d		; offset
		mov   eax, sys_mmap 
	    syscall
		cmp   rax, -1
		 je   Failed_sys_mmap
	; return size in rdx, base address in rax 
		mov   rdx, rbx

		add   rsp, 20*8
		pop   r15 rdi rsi rbx rbp
		ret

_FileUnmap:
	; in: rcx base address 
	;     rdx handle from CreateFileMapping (win), size (linux) 
	       push   rbx rsi rdi 
		mov   rdi, rcx	      ; addr 
		mov   rsi, rdx	      ; length 
		mov   eax, sys_munmap 
	    syscall
		cmp   eax, -1
		 je   Failed_sys_munmap
		pop   rdi rsi rbx 
		ret




;;;;;;;;;;
; thread ;
;;;;;;;;;;

_ThreadCreate:
	; in: rcx start address
	;     rdx parameter to pass
	;     r8  address of GROUP_AFFINITY structure (ignored if numa functions not avaiable)
	;     r9  address of ThreadHandle Struct
	       push   rbx rsi rdi r12 r13 r14 r15
		mov   r13, r9
		mov   r14, rcx
		mov   r15, rdx
	; allocate memory for the thread stack 
		xor   edi, edi						  ; addr
		mov   esi, THREAD_STACK_SIZE				  ; length
		mov   edx, PROT_READ or PROT_WRITE			  ; protection flags
		mov   r10d, MAP_PRIVATE or MAP_ANONYMOUS or MAP_GROWSDOWN ; mapping flags
		 or   r8, -1						  ; fd
		xor   r9, r9						  ; offset
		mov   eax, sys_mmap 
	    syscall
		mov   qword[r13+ThreadHandle.stackAddress], rax
		mov   rsi, rax
	; create child
		mov   edi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or CLONE_THREAD ; flags
		add   rsi, THREAD_STACK_SIZE					       ; child_stack
		xor   edx, edx									; ptid
		mov   r10d, 0									; ctid
		mov   r8d, 0									; regs
		mov   eax, stub_clone
	    syscall
		cmp   eax, -1
		 je   Failed_stub_clone
	; redirect child to function
	       test   eax, eax
		 jz   .WeAreChild
		pop   r15 r14 r13 r12 rdi rsi rbx
		ret
.WeAreChild:
		mov   rcx, r15
	       call   r14
	; signal that we are done
		mov   dword[r13+ThreadHandle.mutex], 1
		lea   rdi, [r13+ThreadHandle.mutex]
		mov   esi, FUTEX_WAKE
		mov   edx, 1
		mov   eax, sys_futex
	    syscall
		cmp   eax, -1
		 je   Failed_sys_futex
	; exit
		xor   edi, edi
		mov   eax, sys_exit
	    syscall
	       int3

_ThreadJoin:
	; rcx:  address of ThreadHandle struct
	       push   rbx rsi rdi
		mov   rbx, rcx
	; wait for the thread to return
		lea   rdi, [rbx+ThreadHandle.mutex]
		mov   esi, FUTEX_WAIT
		mov   edx, 0
		xor   r10d, r10d
		mov   eax, sys_futex
	    syscall
		cmp   eax, -1
		 je   Failed_sys_futex
	; free its stack
		mov   rdi, qword[rbx+ThreadHandle.stackAddress]
		mov   rsi, THREAD_STACK_SIZE
		mov   eax, sys_munmap
	    syscall
		cmp   eax, -1
		 je   Failed_sys_munmap
		pop   rdi rsi rbx
		ret

_ExitProcess:
	; rcx is exit code
	       push   rdi
		mov   rdi, rcx
		mov   eax, sys_exit
	    syscall


_ExitThread:
	; rcx is exit code
	; must not call _ExitThread on linux
	;  thread should just return
	       int3


;;;;;;;;;;
; timing ;
;;;;;;;;;;

_GetTime:
	; out: rax + rdx/2^64 = time in ms
	       push   rsi rdi rbx
		sub   rsp, 8*2
		mov   edi, CLOCK_MONOTONIC
		mov   rsi, rsp
		mov   eax, sys_clock_gettime
	    syscall				; todo: change to a faster vdso call  ?how?
		mov   eax, dword[rsp+8*1]	; tv_nsec
		mov   rcx, 18446744073709;551616   2^64/10^6
		mul   rcx
	       imul   rcx, qword[rsp+8*0], 1000
		add   rdx, rcx
	       xchg   rax, rdx
		add   rsp, 8*2
		pop   rbx rdi rsi
		ret

_SetFrequency:
	; no arguments
		ret

_Sleep:
	; ecx  ms
	       push   rsi rdi rbx
		sub   rsp, 8*2
		mov   eax, ecx
		xor   edx, edx
		mov   ecx, 1000
		div   ecx
	       imul   edx, 1000
		mov   qword[rsp+8*0], rax
		mov   qword[rsp+8*1], rdx
		mov   rdi, rsp
		xor   esi, esi
		mov   eax, sys_nanosleep
	    syscall
		add   rsp, 8*2
		pop   rbx rdi rsi
		ret


;;;;;;;;;;
; memory ;
;;;;;;;;;;


_VirtualAllocNuma:
	; rcx is size
	; edx is numa node


_VirtualAlloc:
	; rcx is size
	       push   rsi rdi rbx
		xor   edi, edi
		mov   rsi, rcx
		mov   edx, PROT_READ or PROT_WRITE
		mov   r10d, MAP_PRIVATE or MAP_ANONYMOUS
		 or   r8, -1
		xor   r9, r9
		mov   eax, sys_mmap
	    syscall
		cmp   rax, -1
		 je   Failed_sys_mmap
		pop   rbx rdi rsi
		ret


_VirtualFree:
	; rcx is address
	; rdx is size
	       push   rsi rdi rbx
	       test   rcx, rcx
		 jz   @f
		mov   rdi, rcx
		mov   rsi, rdx
		mov   eax, sys_munmap
	    syscall
		cmp   eax, -1
		 je   Failed_sys_munmap
	@@:	pop   rbx rdi rsi
		ret



;;;;;;;;;;;;;;;;
; input/output ;
;;;;;;;;;;;;;;;;

_GetCommandLine:
	; out: rax address of string

	; we are supposed to return the command line string
	;  for now, just return junk that won't break the command line processor
	       lea   rax, [@f]
	       ret
	@@: db ' ',0

_SetStdHandles:
	; no arguments
	; these are always 0,1,2
		ret


_WriteOut_Output:
		lea   rcx, [Output]
_WriteOut:
	; in: rcx  address of string start
	;     rdi  address of string end
	       push   rsi rdi rbx
		mov   rsi, rcx
		mov   rdx, rdi
		sub   rdx, rcx
		mov   edi, 1
		mov   eax, sys_write
	    syscall
		cmp   rax, -1
		 je   Failed_sys_write
		pop   rbx rdi rsi
		ret


_WriteError:
	; in: rcx  address of string start
	;     rdi  address of string end
	       push   rsi rdi rbx
		mov   rsi, rcx
		mov   rdx, rdi
		sub   rdx, rcx
		mov   edi, 2
		mov   eax, sys_write
	    syscall
		cmp   rax, -1
		 je   Failed_sys_write
		pop   rbx rdi rsi
		ret



_ReadIn:
	; out: eax =  0 if not file end 
	;      eax = -1 if file end 
	;      rsi address of string start 
	;      ecx length of string
	; 
	; uses global InputBuffer and InputBufferSizeB 
	; reads one line and then returns 
	; a line is a string of characters where the last
	;  and only the last character is below 0x20 (the space char)
	       push   rdi rbx r13 r14 r15
		xor   ebx, ebx				; ebx = length of return string
		mov   r15, qword[InputBuffer]		; r15 = buffer
		mov   r14, qword[InputBufferSizeB]	; r14 = size
.ReadLoop:
		cmp   rbx, r14
		jae   .ReAlloc
.ReAllocRet:
		mov   edi, stdin
		lea   rsi, [r15+rbx]
		mov   edx, 1
		mov   eax, sys_read 
	    syscall
	; check for file end 
		cmp   rax, 1
		 jl  .FileEnd
	; check for new line
		add   ebx, 1
		cmp   byte[rsi], ' '
		jae   .ReadLoop

		xor   eax, eax
.Return:
		mov   rsi, r15
		mov   ecx, ebx
		pop   r15 r14 r13 rbx rdi
		ret
.FileEnd:
		 or   eax, -1
		jmp  .Return
.ReAlloc:
	; get new buffer
		lea   rcx, [r14+4096]
	       call   _VirtualAlloc
		mov   r13, rax
		mov   rdi, rax
	; copy data
		mov   rsi, r15
		mov   rcx, r14
	  rep movsb
	; free old buffer
		mov   rcx, r15
		mov   rdx, r14
	       call   _VirtualFree
	; set new data
		mov   r15, r13
		add   r14, 4096
		mov   qword[InputBuffer], r13
		mov   qword[InputBufferSizeB], r14
		jmp   .ReAllocRet


;;;;;;;;;;;;;;;;;;
; priority class ;
;;;;;;;;;;;;;;;;;;

_SetRealtimePriority:
	; must be root to set "higher" priority, normal user can only lower priority 
	       push   rsi rdi rbx 
		mov   edi, PRIO_PROCESS    ; which 
		mov   esi, 0		   ; who 
		mov   edx, -15		   ; priority 
		mov   eax, sys_setpriority 
	    syscall 
		pop   rbx rdi rsi 
		ret

_SetNormalPriority:
	; must be root to set "higher" priority, normal user can only lower priority 
	       push   rsi rdi rbx 
		mov   edi, PRIO_PROCESS    ; which 
		mov   esi, 0		   ; who 
		mov   edx, 0		   ; priority 
		mov   eax, sys_setpriority 
	    syscall 
		pop   rbx rdi rsi 
		ret





;;;;;;;;;;;;;;;;;;;;;;;
; system capabilities ;
;;;;;;;;;;;;;;;;;;;;;;;


_SetThreadPoolInfo:
	; see ThreadPool.asm for what this is supposed to do
	; for now, this is set to the 'numa-unaware' state
	       push   rdi
		mov   dword[threadPool.nodeCnt], 1
		mov   dword[threadPool.coreCnt], 1
		lea   rdi, [threadPool.nodeTable]
		mov   dword[rdi+NumaNode.Relationship], RelationNumaNode
		mov   dword[rdi+NumaNode.Size], sizeof.NumaNode
		mov   dword[rdi+NumaNode.NodeNumber], -1
		mov   ecx, 4*16*64*16*64
	       call   _VirtualAlloc
		mov   qword[rdi+NumaNode.cmhTable], rax
		mov   qword[rdi+NumaNode.coreCnt], 1
		xor   eax, eax
		mov   qword[rdi+NumaNode.GroupMask.Mask], rax
		mov   word[rdi+NumaNode.GroupMask.Group], ax
		pop   rdi
		ret






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
		xor   ecx, ecx
	       call   _ExitProcess







;;;;;;;;;
; fails ;
;;;;;;;;;

Failed:
	       call   _ErrorBox
		xor   ecx, ecx
	       call   _ExitProcess


Failed_HashmaxTooLow:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'HSHMAX too low!',0
Failed_sys_write:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'sys_write failed',0
Failed_sys_mmap:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'sys_mmap failed',0
Failed_sys_fstat:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'sys_fstat failed',0
Failed_sys_munmap:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'sys_munmap failed',0
Failed_stub_clone:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'stub_clone failed',0
Failed_sys_futex:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'sys_futex failed',0





_ErrorBox:
	; rdi points to null terminated string to write to message box 
	; this may be called from a leaf with no stack allignment 
	; one purpose is a hard exit on failure
	       call   strlen 
	       push   rdi rsi rbx 
		mov   rsi, rdi 
		mov   edi, stderr 
		mov   rdx, rax 
		mov   eax, sys_write 
	    syscall 
		pop   rbx rsi rdi 
		ret


strlen:
		xor   rax, rax 
   @@: 
		cmp   byte [rdi+rax], $00 
		 je   @f 
		inc   rax 
		cmp   byte [rdi+rax], $00 
		 je   @f 
		inc   rax 
		cmp   byte [rdi+rax], $00 
		 je   @f 
		inc   rax 
		cmp   byte [rdi+rax], $00 
		 je   @f 
		inc   rax 
		cmp   byte [rdi+rax], $00 
		 je   @f 
		inc   rax 
		jmp   @b 
   @@: 
		ret
