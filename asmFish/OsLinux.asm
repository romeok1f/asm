
;;;;;;;;;
; mutex ;
;;;;;;;;;

_MutexCreate:
	; rcx: address of critial section object
	       int3
_MutexLock:
	; rcx: address of critial section object
	       int3
_MutexUnlock:
	; rcx: address of critial section object
	       int3
_MutexDestroy:
	; rcx: address of critial section object
	       int3

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
	       int3

_FileMap:
	; in: rcx handle (win), fd (linux)
	; out: rax base address
	;      rdx handle from CreateFileMapping (win), size (linux)
	       int3

_FileUnmap:
	; in: rcx base address
	;     rdx handle from CreateFileMapping (win), size (linux)
	       int3





;;;;;;;;;
; event ;
;;;;;;;;;

_EventCreate:
	; no arguments
	       int3
_EventSignal:
	; rcx: handle
	       int3
_EventWait:
	; rcx: handle
	; rdx: address of critial section object
	       int3
_EventDestroy:
	; rcx: handle
	       int3


;;;;;;;;;;
; thread ;
;;;;;;;;;;

_ThreadCreate:
	; rcx: start address
	; rdx: parameter to pass
	       int3
_ThreadJoin:
	; rcx: handle
	       int3

_ExitProcess:
	; rcx is exit code
	       push   rdi
		mov   rdi, rcx
		mov   eax, sys_exit
	    syscall


_ExitThread:
	; rcx is exit code
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
	       int3


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
		pop   rbx rdi rsi
		ret


_VirtualFree:
	; rcx is address
	; rdx is size
	       push   rsi rdi rbx
		mov   rdi, rcx
		mov   rsi, rdx
		mov   eax, sys_munmap
	    syscall
		pop   rbx rdi rsi
		ret



;;;;;;;;;;;;;;;;
; input/output ;
;;;;;;;;;;;;;;;;

_GetCommandLine:
	; out: rax address of string
	       int3

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
		pop   rbx rdi rsi
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

	       int3





;;;;;;;;;;;;;;;;;;
; priority class ;
;;;;;;;;;;;;;;;;;;

_SetRealtimePriority:
	       int3

_SetNormalPriority:
	       int3





;;;;;;;;;;;;;;;;;;;;;;;
; system capabilities ;
;;;;;;;;;;;;;;;;;;;;;;;


_SetThreadPoolInfo:
	; see ThreadPool.asm for what this is supposed to do
	       int3






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
		@@: db 'HSHMAX too low!'

Failed__imp_CreateFileMappingA:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateFileMappingA failed'

Failed__imp_MapViewOfFile:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_MapViewOfFile failed'

Failed__imp_SetEvent:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_SetEvent failed'
Failed__imp_CreateEvent:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateEvent failed'
Failed__imp_WaitForSingleObject:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_WaitForSingleObject failed'
Failed__imp_CreateThread_CREATE_SUSPENDED:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateThread CREATE_SUSPENDED failed'
Failed__imp_SetThreadGroupAffinity:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_SetThreadGroupAffinity failed'
Failed__imp_ResumeThread:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_ResumeThread failed'
Failed__imp_CreateThread:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateThread failed'
Failed__imp_QueryPerformanceFrequency:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_QueryPerformanceFrequency failed'
Failed__imp_VirtualAllocExNuma:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualAllocExNuma failed'
Failed__imp_VirtualAlloc:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualAlloc failed'
Failed__imp_VirtualFree:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualFree failed'
Failed__imp_VirtualAlloc_ReadIn:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualAlloc inside _ReadIn failed'
Failed__imp_VirtualFree_ReadIn:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualFree inside _ReadIn failed'



_ErrorBox:
	; rdi points to null terminated string to write to message box
	; this may be called from a leaf with no stack allignment
	; one purpose is a hard exit on failure
	; loading user32.dll multiple times (i.e. on each call)
	;   seems to result in a crash in ExitProcess
	;  so we load only once
	       int3



