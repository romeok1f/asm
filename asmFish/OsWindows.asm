
; these os functions need to conform to the standards
; so stack support is given for the first four arguments




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
	       test   rax, rax
		 jz   Failed__imp_CreateEvent
		add   rsp, 8*5
		ret


_EventSignal:
	; rcx: handle
		sub   rsp, 8*5
	       call   qword[__imp_SetEvent]
	       test   eax, eax
		 jz   Failed__imp_SetEvent
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
		cmp   eax, WAIT_FAILED
		 je   Failed__imp_WaitForSingleObject
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
	; r8: address of GROUP_AFFINITY structure (ignored if numa functions not avaiable)
	       push   rbx rsi rdi
		sub   rsp, 8*6
		mov   rbx, qword[__imp_SetThreadGroupAffinity]
		mov   rdi, r8
	       test   rbx, rbx
		 jz   .DontSetAffinity

		mov   r8, rcx
		mov   r9, rdx
		xor   ecx, ecx
		mov   edx, 1 shl 19	; 0.5 MB of commited stack space
		mov   qword[rsp+8*4], CREATE_SUSPENDED
		mov   qword[rsp+8*5], rcx
	       call   qword[__imp_CreateThread]
		mov   rsi, rax
	       test   rax, rax
		 jz   Failed__imp_CreateThread_CREATE_SUSPENDED

		mov   rcx, rax
		mov   rdx, rdi
		lea   r8, [rsp+8*4]
	       call   qword[__imp_SetThreadGroupAffinity]
	       test   eax, eax
		 jz   Failed__imp_SetThreadGroupAffinity

		mov   rcx, rsi
	       call   qword[__imp_ResumeThread]
		cmp   eax, 1
		jne   Failed__imp_ResumeThread
	       
		mov   rax, rsi
		add   rsp, 8*6
		pop   rdi rsi rbx
		ret

.DontSetAffinity:
		mov   r8, rcx
		mov   r9, rdx
		xor   ecx, ecx
		xor   edx, edx
		mov   qword[rsp+8*4], rcx
		mov   qword[rsp+8*5], rcx
	       call   qword[__imp_CreateThread]
	       test   rax, rax
		 jz   Failed__imp_CreateThread
		add   rsp, 8*6
		pop   rdi rsi rbx
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
	       call   qword[__imp_QueryPerformanceCounter]
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
	       test   eax, eax
		 jz   Failed__imp_QueryPerformanceFrequency
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


_VirtualAllocNuma:
	; rcx is size
	; edx is numa node
		mov   rax, qword[__imp_VirtualAllocExNuma]
	       test   rax, rax
		 jz   _VirtualAlloc
		sub   rsp, 8*7
GD_String db 'alloc'
GD_Int rdx
GD_String db ': '
		mov   qword[rsp+8*5], rdx
		mov   qword[rsp+8*4], PAGE_READWRITE
		mov   r9d, MEM_COMMIT
		mov   r8, rcx
		xor   edx, edx
		mov   rcx, qword[hProcess]
	       call   rax
	       test   rax, rax
		 jz   Failed__imp_VirtualAllocExNuma
if DEBUG > 0
add dword[DebugBalance], 1
end if
GD_Hex rax
GD_NewLine
		add   rsp, 8*7
		ret



_VirtualAlloc:
	; rcx is size
	;  if this fails, we want to exit immediately
		sub   rsp, 8*5
GD_String db 'alloc:  '
		mov   rdx, rcx
		xor   ecx, ecx
		mov   r8d, MEM_COMMIT
		mov   r9d, PAGE_READWRITE
	       call   qword[__imp_VirtualAlloc]
	       test   rax, rax
		 jz   Failed__imp_VirtualAlloc
if DEBUG > 0
add dword[DebugBalance], 1
end if
GD_Hex rax
GD_NewLine
		add   rsp, 8*5
		ret


_VirtualFree:
	; rcx is address
	;  if 0 is passed, we should do nothing
		sub   rsp, 8*5
		xor   edx, edx
		mov   r8d, MEM_RELEASE
	       test   rcx, rcx
		 jz   .null
GD_String db 'free:  '
GD_Hex rcx
GD_NewLine
	       call   qword[__imp_VirtualFree]
	       test   eax, eax
		 jz   Failed__imp_VirtualFree
if DEBUG > 0
sub dword[DebugBalance], 1
end if
 .null:
		add   rsp, 8*5
		ret



;;;;;;;;;;;;;;;;
; input/output ;
;;;;;;;;;;;;;;;;


_GetCommandLine:
	; out: address of string
		sub   rsp,8*5
	       call   qword[__imp_GetCommandLine]
		add   rsp, 8*5
		ret

_SetStdHandles:
	; no arguments
		sub   rsp,8*5
	       call   qword[__imp_GetCurrentProcess]
		mov   qword[hProcess], rax
		mov   ecx, STD_INPUT_HANDLE
	       call   qword[__imp_GetStdHandle]
		mov   qword[hStdIn], rax
		mov   ecx, STD_OUTPUT_HANDLE
	       call   qword[__imp_GetStdHandle]
		mov   qword[hStdOut], rax
		mov   ecx, STD_ERROR_HANDLE
	       call   qword[__imp_GetStdHandle]
		mov   qword[hStdError], rax
		add   rsp, 8*5
		ret


_WriteOut_Output:
		lea   rcx, [Output]
_WriteOut:
	; in: rcx  address of string start
	;     rdi  address of string end
		sub   rsp, 8*9
		mov   r8, rdi
		sub   r8, rcx
	     Assert   b, r8, 2000, 'excessive write size in _WriteOut'
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
	       push   r13 rbp rdi rbx
		sub   rsp, 8*9
		mov   rbx, qword[InputBuffer]
		lea   r13, [rsp+3CH]
?_1062: 	mov   rax, rbx
		sub   rax, qword[InputBuffer]
		mov   rcx, qword[InputBufferSizeB]
		add   rax, 9
		cmp   rax, rcx
		mov   rdx, rcx
		 jl   ?_1063
		add   edx, 4096
		mov   r9d, 4
		mov   r8d, 4096
		xor   ecx, ecx
	       call   qword[__imp_VirtualAlloc]
	       test   rax, rax
		 jz   Failed__imp_VirtualAlloc_ReadIn
		mov   ecx, dword[InputBufferSizeB]
		mov   r8d, MEM_RELEASE
		xor   edx, edx
		mov   rsi, qword[InputBuffer]
		mov   rdi, rax
		mov   rbp, rax
	  rep movsb
		mov   rcx, qword[InputBuffer]
	       call   qword[__imp_VirtualFree]
	       test   rax, rax
		 jz   Failed__imp_VirtualFree_ReadIn
		sub   rbx, qword [InputBuffer]
		mov   qword[InputBuffer], rbp
		add   qword[InputBufferSizeB], 4096
		add   rbx, rbp
?_1063: 	mov   rdx, rbx
		mov   r9, r13
		mov   qword[rsp+20H], 0
		mov   r8d, 1
		mov   rcx, qword[hStdIn]
	       call   qword[__imp_ReadFile]
		mov   dl, byte [rbx]
	       test   eax, eax
		 jz   ?_1064
		cmp   dword[rsp+3CH], 0
		 jz   ?_1065
?_1064: 	cmp   dl, 31
		jle   ?_1066
		inc   rbx
		jmp   ?_1062
?_1065: 	 or   eax, -1
		jmp   ?_1067
?_1066: 	mov   byte[rbx], 0
		xor   eax, eax
?_1067: 	add   rsp, 8*9
		mov   rsi, qword[InputBuffer]
		pop   rbx rdi rbp r13
		ret




;;;;;;;;;;;;;;;;;;
; priority class ;
;;;;;;;;;;;;;;;;;;

_SetRealtimePriority:
	       push   rbx
		mov   ebx, REALTIME_PRIORITY_CLASS
	@@:
		sub   rsp, 8*4
	       call   qword[__imp_GetCurrentProcess]
		mov   rcx, rax
		mov   edx, ebx
	       call   qword[__imp_SetPriorityClass]
		add   rsp, 8*4
		pop   rbx
		ret

_SetNormalPriority:
	       push   rbx
		mov   ebx, NORMAL_PRIORITY_CLASS
		jmp   @b





;;;;;;;;;
; fails
;;;;;;;;;

Failed:
	       call   _ErrorBox
		xor   ecx, ecx
	       call   _ExitProcess

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



;;;;;;;;
; misc ;
;;;;;;;;


_ErrorBox:
	; rdi points to null terminated string to write to message box
	; this may be called from a leaf with no stack allignment
	; one purpose is a hard exit on failure
	; loading user32.dll multiple times (i.e. on each call)
	;   seems to result in a crash in ExitProcess
	;  so we load only once
	       push   rbp
		mov   rbp, rsp
		sub   rsp, 8*8
		and   rsp, -16
		mov   rax, qword[__imp_MessageBoxA]
	       test   rax, rax
		jnz   .loaded
		lea   rcx, [.user32]
	       call   qword[__imp_LoadLibrary]
		mov   rcx, rax
		lea   rdx, [.MessageBoxA]
	       call   qword[__imp_GetProcAddress]
		mov   qword[__imp_MessageBoxA], rax
.loaded:
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
		xor   ecx, ecx
	       call   _ExitProcess



