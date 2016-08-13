
; these os functions need to conform to the standards
; so stack support is given for the first four arguments


;;;;;;;;;
; mutex ;
;;;;;;;;;

_MutexCreate:
	; rcx: address of critial section object (win), Mutex (linux)
		sub   rsp, 8*5
	       call   qword[__imp_InitializeCriticalSection]
		add   rsp, 8*5
		ret
_MutexLock:
	; rcx: address of critial section object (win), Mutex (linux)
		sub   rsp, 8*5
	       call   qword[__imp_EnterCriticalSection]
		add   rsp, 8*5
		ret
_MutexUnlock:
	; rcx: address of critial section object (win), Mutex (linux)
		sub   rsp, 8*5
	       call   qword[__imp_LeaveCriticalSection]
		add   rsp, 8*5
		ret
_MutexDestroy:
	; rcx: address of critial section object (win), Mutex (linux)
		sub   rsp, 8*5
	       call   qword[__imp_DeleteCriticalSection]
		add   rsp, 8*5
		ret


;;;;;;;;;
; event ;
;;;;;;;;;

_EventCreate:
	; rcx: address of ConditionalVariable
	       push   rbx
		sub   rsp, 8*4
		mov   rbx, rcx
		xor   ecx, ecx
		xor   edx, edx
		xor   r8d, r8d
		xor   r9d, r9d
	       call   qword[__imp_CreateEvent]
	       test   rax, rax
		 jz   Failed__imp_CreateEvent
		mov   qword[rbx+ConditionalVariable.handle], rax
		add   rsp, 8*4
		pop   rbx
		ret


_EventSignal:
	; rcx: address of ConditionalVariable
		sub   rsp, 8*5
		mov   rcx, qword[rcx+ConditionalVariable.handle]
	       call   qword[__imp_SetEvent]
	       test   eax, eax
		 jz   Failed__imp_SetEvent
		add   rsp, 8*5
		ret

_EventWait:
	; rcx: address of ConditionalVariable
	; rdx: address of Mutex
	       push   rbx rsi
		sub   rsp, 8*5
		mov   rbx, qword[rcx+ConditionalVariable.handle]
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
	; rcx: address of ConditionalVariable
	       push   rbx
		sub   rsp, 8*4
		mov   rbx, rcx
		mov   rcx, qword[rbx+ConditionalVariable.handle]
	       call   qword[__imp_CloseHandle]
		xor   eax, eax
		mov   qword[rbx+ConditionalVariable.handle], rax
		add   rsp, 8*4
		pop   rbx
		ret





;;;;;;;;
; file ;
;;;;;;;;

_FileOpen:
	; in: rcx path string
	; out: rax handle from CreateFile (win), fd (linux)
	;      rax=-1 on error
		sub   rsp, 8*9
		mov   edx, 2147483648
		mov   r8d, 1
		xor   r9d, r9d
		mov   dword[rsp+8*4], 3
		mov   dword[rsp+8*5], 128
		mov   qword[rsp+8*6], 0
	       call   qword[__imp_CreateFileA]
		add   rsp, 8*9
		ret

_FileClose:
	; in: rcx handle from CreateFile (win), fd (linux)
		sub   rsp, 8*5
	       call   qword[__imp_CloseHandle]
		add   rsp, 8*5
		ret

_FileMap:
	; in: rcx handle (win), fd (linux)
	; out: rax base address
	;      rdx handle from CreateFileMapping (win), size (linux)

	       push   rbx rsi rdi
		sub   rsp, 40H

		lea   rdx, [rsp+3CH]
		mov   rsi, rcx
	       call   qword[__imp_GetFileSize]

		xor   edx, edx
		mov   r9d, dword [rsp+3CH]
		mov   rcx, rsi
		mov   qword[rsp+28H], 0
		mov   r8d, 2
		mov   dword[rsp+20H], eax
	       call   qword[__imp_CreateFileMappingA]
	       test   rax, rax
		 jz    Failed__imp_CreateFileMappingA

		mov   rbx, rax
		xor   r9d, r9d
		xor   r8d, r8d
		mov   edx, 4
		mov   qword [rsp+20H], 0
		mov   rcx, rax
	       call   qword[__imp_MapViewOfFile]
	       test   rax, rax
		 jz   Failed__imp_MapViewOfFile

		mov   rdx, rbx
		add   rsp, 40H
		pop   rdi rsi rbx
		ret



_FileUnmap:
	; in: rcx base address
	;     rdx handle from CreateFileMapping (win), size (linux)
	       push   rbx
		sub   rsp, 8*6
		mov   rbx, rdx
	       test   rcx, rcx
		 jz   @f
	       call   qword[__imp_UnmapViewOfFile]
		mov   rcx, rbx
	       call   qword[ __imp_CloseHandle]
	@@:	add   rsp, 8*6
		pop   rbx
		ret


;;;;;;;;;;
; thread ;
;;;;;;;;;;

_ThreadCreate:
	; in: rcx start address
	;     rdx parameter to pass
	;     r8  address of NumaNode struct
	;     r9  address of ThreadHandle struct
	       push   rbx rsi rdi
		sub   rsp, 8*6
		mov   rbx, qword[__imp_SetThreadGroupAffinity]
		mov   rdi, r8
		mov   rsi, r9

		mov   r8, rcx		; lpStartAddress
		mov   r9, rdx		; lpParameter
		xor   ecx, ecx		; lpThreadAttributes
		mov   edx, 1000 	; dwStackSize
		; at least 1000000 bytes are reserved for the stack by the "stack 1000000" directive in asmFishW.asm
		; when creating a thread, it is not clear how windows allocates the memory for the stack
		; we hope here that if a small number is given for the commit size, then as the thread commits more
		;  pages, it chooses them from the correct node
		; again, not sure how this works

	       test   rbx, rbx
		 jz   .DontSetAffinity

		mov   qword[rsp+8*4], CREATE_SUSPENDED	; dwCreationFlags
		mov   qword[rsp+8*5], rcx		; lpThreadId
	       call   qword[__imp_CreateThread]
		mov   qword[rsi+ThreadHandle.handle], rax
	       test   rax, rax
		 jz   Failed__imp_CreateThread_CREATE_SUSPENDED

		mov   rcx, rax
		lea   rdx, [rdi+NumaNode.groupMask]
		lea   r8, [rsp+8*4]
	       call   rbx
	       test   eax, eax
		 jz   Failed__imp_SetThreadGroupAffinity

		mov   rcx, qword[rsi+ThreadHandle.handle]
	       call   qword[__imp_ResumeThread]
		cmp   eax, 1
		jne   Failed__imp_ResumeThread

		add   rsp, 8*6
		pop   rdi rsi rbx
		ret

.DontSetAffinity:
		mov   qword[rsp+8*4], rcx
		mov   qword[rsp+8*5], rcx
	       call   qword[__imp_CreateThread]
	       test   rax, rax
		 jz   Failed__imp_CreateThread
		add   rsp, 8*6
		pop   rdi rsi rbx
		ret




_ThreadJoin:
	; rcx: address of ThreadHandle Struct
	       push   rbx
		sub   rsp, 8*4
		mov   rcx, qword[rcx+ThreadHandle.handle]
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
	; must not call _ExitThread on linux
	;  thread should just return
		sub   rsp, 8*5
		jmp   qword[__imp_ExitThread]





;;;;;;;;;;
; timing ;
;;;;;;;;;;

_GetTime:
	; out: rax + rdx/2^64 = time in ms
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

if DEBUG > 0
add qword[DebugBalance], rcx
end if


GD_String 'size: '
GD_Int rcx
GD_NewLine
GD_String 'alloc'
GD_Int rdx
GD_String ': '

		mov   qword[rsp+8*5], rdx
		mov   qword[rsp+8*4], PAGE_READWRITE
		mov   r9d, MEM_COMMIT
		mov   r8, rcx
		xor   edx, edx
		mov   rcx, qword[hProcess]
	       call   rax
	       test   rax, rax
		 jz   Failed__imp_VirtualAllocExNuma
GD_Hex rax
GD_NewLine

		add   rsp, 8*7
		ret



_VirtualAlloc:
	; rcx is size
	;  if this fails, we want to exit immediately
		sub   rsp, 8*5

if DEBUG > 0
add qword[DebugBalance], rcx
end if
GD_String 'size: '
GD_Int rcx
GD_NewLine
GD_String 'alloc:  '

		mov   rdx, rcx
		xor   ecx, ecx
		mov   r8d, MEM_COMMIT
		mov   r9d, PAGE_READWRITE
	       call   qword[__imp_VirtualAlloc]
	       test   rax, rax
		 jz   Failed__imp_VirtualAlloc
GD_Hex rax
GD_NewLine

		add   rsp, 8*5
		ret


_VirtualFree:
	; in: rcx address     if 0 is passed, we should do nothing
	;     rdx don't care (win), size (linux)  however we do care about this for DEBUG
		sub   rsp, 8*5
		mov   r8d, MEM_RELEASE
	       test   rcx, rcx
		 jz   .null

if DEBUG > 0
sub qword[DebugBalance], rdx
end if
GD_String 'size: '
GD_Int rdx
GD_NewLine
GD_String 'free:  '
GD_Hex rcx
GD_NewLine

		xor   edx, edx
	       call   qword[__imp_VirtualFree]
	       test   eax, eax
		 jz   Failed__imp_VirtualFree
 .null:
		add   rsp, 8*5
		ret



;;;;;;;;;;;;;;;;
; input/output ;
;;;;;;;;;;;;;;;;


_GetCommandLine:
	; out: rax address of string
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
	     Assert   b, r8, 3000, 'excessive write size in _WriteOut'
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
?_1062:
		mov   rax, rbx
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
if DEBUG > 0
add qword[DebugBalance], rdx
end if
	       call   qword[__imp_VirtualAlloc]
	       test   rax, rax
		 jz   Failed__imp_VirtualAlloc_ReadIn

GD_String 'alloc: '
GD_Hex rax
GD_NewLine

		mov   rcx, qword[InputBufferSizeB]

if DEBUG > 0
sub qword[DebugBalance], rcx
end if

		mov   r8d, MEM_RELEASE
		xor   edx, edx
		mov   rsi, qword[InputBuffer]
		mov   rdi, rax
		mov   rbp, rax
	  rep movsb
		mov   rcx, qword[InputBuffer]

GD_String 'free:  '
GD_Hex rcx
GD_NewLine

	       call   qword[__imp_VirtualFree]
	       test   rax, rax
		 jz   Failed__imp_VirtualFree_ReadIn
		sub   rbx, qword [InputBuffer]
		mov   qword[InputBuffer], rbp
		add   qword[InputBufferSizeB], 4096
		add   rbx, rbp
?_1063:
		mov   rdx, rbx
		mov   r9, r13
		mov   qword[rsp+20H], 0
		mov   r8d, 1
		mov   rcx, qword[hStdIn]
	       call   qword[__imp_ReadFile]
		mov   dl, byte[rbx]
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





;;;;;;;;;;;;;;;;;;;;;;;
; system capabilities ;
;;;;;;;;;;;;;;;;;;;;;;;


_SetThreadPoolInfo:
	; see ThreadPool.asm for what this is supposed to do

	       push   rdi rsi rbx r12 r13 r14 r15
virtual at rsp
	   rq 8
 .size	   rq 8
 .numadata rb sizeof.NumaNode*MAX_NUMANODES
 .lend	   rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))

	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

	; figure out if we have the numa functions
	; kernel32.dll is automatically loaded into exe
		lea   rcx, [sz_kernel32]
	       call   qword[__imp_GetModuleHandle]
		mov   rbx, rax

		mov   rcx, rbx
		lea   rdx, [sz_GetLogicalProcessorInformationEx]
	       call   qword[__imp_GetProcAddress]
		mov   qword[__imp_GetLogicalProcessorInformationEx], rax
	       test   rax, rax
		 jz   .Absent	; < windows 7
		mov   rcx, rbx
		lea   rdx, [sz_SetThreadGroupAffinity]
	       call   qword[__imp_GetProcAddress]
		mov   qword[__imp_SetThreadGroupAffinity], rax
	       test   rax, rax
		 jz   .Absent	; < windows 7
		mov   rcx, rbx
		lea   rdx, [sz_VirtualAllocExNuma]
	       call   qword[__imp_GetProcAddress]
		mov   qword[__imp_VirtualAllocExNuma], rax
	       test   rax, rax
		 jz   .Absent  ; < vista

	; retrieve numa configuation
		mov   ecx, RelationNumaNode
		lea   rdx, [.numadata]
		lea   r8, [.size]
		mov   qword[r8], MAX_NUMANODES*sizeof.NumaNode
	       call   qword[__imp_GetLogicalProcessorInformationEx]
	       test   eax, eax
		 jz   Failed__imp_GetLogicalProcessorInformationEx
		mov   ebx, dword[.size]
	       test   ebx, ebx
		 jz   Failed__imp_GetLogicalProcessorInformationEx
		mov   dword[threadPool.nodeCnt], 0
		mov   dword[threadPool.coreCnt], 0
		lea   rsi, [.numadata]
		lea   rdi, [threadPool.nodeTable]
		add   rbx, rsi
.NextNumaNode:
		mov   ecx, sizeof.CounterMoveHistoryStats
		mov   edx, dword[rsi+WinNumaNode.NodeNumber+8*0]
	       call   _VirtualAllocNuma
		mov   edx, dword[rsi+WinNumaNode.NodeNumber+8*0]
		mov   r8, qword[rsi+WinNumaNode.GroupMask+8*0]
		mov   r9, qword[rsi+WinNumaNode.GroupMask+8*1]
		mov   dword[rdi+NumaNode.nodeNumber], edx
		mov   dword[rdi+NumaNode.coreCnt], 0	; initialize to zero - will increment later
		mov   qword[rdi+NumaNode.cmhTable], rax
		mov   qword[rdi+NumaNode.groupMask+8*0], r8
		mov   qword[rdi+NumaNode.groupMask+8*1], r9
		add   dword[threadPool.nodeCnt], 1
		mov   eax, dword[rsi+WinNumaNode.Size]
		add   rsi, rax
		add   rdi, sizeof.NumaNode
		cmp   rsi, rbx
		 jb   .NextNumaNode

	; retrieve core configuation
		mov   ecx, RelationProcessorCore
		xor   edx, edx
		lea   r8, [.size]
		mov   qword[r8], 0
	       call   qword[__imp_GetLogicalProcessorInformationEx]
		mov   ecx, dword[.size]
	       call   _VirtualAlloc
		mov   r15, rax
		mov   ecx, RelationProcessorCore
		mov   rdx, r15
		lea   r8, [.size]
	       call   qword[__imp_GetLogicalProcessorInformationEx]
		mov   ebx, dword[.size]
		mov   rsi, r15
		add   rbx, rsi
.NextCore:
	      movzx   eax, word[rsi+32+GROUP_AFFINITY.Group]
		mov   rdx, qword[rsi+32+GROUP_AFFINITY.Mask]
	; find numa node that has this core
		lea   r8, [threadPool.nodeTable]
	       imul   r9d, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   r9, r8
.TryNextNode:
		cmp   ax, word[r8+NumaNode.groupMask.Group]
		jne   @f
	       test   rdx, qword[r8+NumaNode.groupMask.Mask]
		jnz   .Found
	@@:	add   r8, sizeof.NumaNode
		cmp   r8, r9
		 jb   .TryNextNode
		jmp   Failed_MatchingCore
.Found:
		add   dword[r8+NumaNode.coreCnt], 1
		add   dword[threadPool.coreCnt], 1
		mov   ecx, dword[rsi+4]
		add   rsi, rcx
		cmp   rsi, rbx
		 jb   .NextCore
		mov   rcx, r15
		mov   edx, dword[.size]
	       call   _VirtualFree
.Return:
		add   rsp, .localsize
		pop   r15 r14 r13 r12 rbx rdi rsi
		ret


.Absent:
		mov   dword[threadPool.nodeCnt], 1
		mov   dword[threadPool.coreCnt], 1
		lea   rdi, [threadPool.nodeTable]
		mov   dword[rdi+NumaNode.nodeNumber], -1
		mov   qword[rdi+NumaNode.coreCnt], 1
		mov   ecx, sizeof.CounterMoveHistoryStats
	       call   _VirtualAlloc
		mov   qword[rdi+NumaNode.cmhTable], rax
		xor   eax, eax
		mov   qword[rdi+NumaNode.groupMask.Mask], rax
		mov   word[rdi+NumaNode.groupMask.Group], ax

		mov   qword[__imp_GetLogicalProcessorInformationEx], rax
		mov   qword[__imp_SetThreadGroupAffinity], rax
		mov   qword[__imp_VirtualAllocExNuma], rax
		jmp   .Return


_DisplayThreadPoolInfo:
	       push   rbx rsi rdi
		lea   rsi, [threadPool.nodeTable]
	       imul   ebx, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   rbx, rsi
		cmp   dword[rsi+NumaNode.nodeNumber], -1
		 je   .Return
.NextNumaNode2:
		lea   rdi, [Output]
		mov   rax, 'info str'
	      stosq
		mov   rax, 'ing node'
	      stosq
		mov   al, ' '
	      stosb
		mov   eax, dword[rsi+NumaNode.nodeNumber]
	       call   PrintUnsignedInteger
		mov   rax, ' cores '
	      stosq
		sub   rdi, 1
		mov   eax, dword[rsi+NumaNode.coreCnt]
	       call   PrintUnsignedInteger
		mov   rax, ' group '
	      stosq
		sub   rdi, 1
	      movzx   eax, word[rsi+NumaNode.groupMask.Group]
	       call   PrintUnsignedInteger
		mov   rax, ' mask 0x'
	      stosq
		mov   rcx, qword[rsi+NumaNode.groupMask.Mask]
	       call   PrintHex
		add   rdi, 16
       PrintNewLine
	       call   _WriteOut_Output
		add   rsi, sizeof.NumaNode
		cmp   rsi, rbx
		 jb   .NextNumaNode2
.Return:
		pop   rdi rsi rbx
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
		mov   ecx, 1
	       call   _ExitProcess


Failed_HashmaxTooLow:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'HSHMAX too low!',0
Failed__imp_CreateFileMappingA:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateFileMappingA failed',0
Failed__imp_MapViewOfFile:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_MapViewOfFile failed',0

Failed__imp_SetEvent:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_SetEvent failed',0
Failed__imp_CreateEvent:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateEvent failed',0
Failed__imp_WaitForSingleObject:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_WaitForSingleObject failed',0
Failed__imp_CreateThread_CREATE_SUSPENDED:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateThread CREATE_SUSPENDED failed',0
Failed__imp_SetThreadGroupAffinity:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_SetThreadGroupAffinity failed',0
Failed__imp_ResumeThread:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_ResumeThread failed',0
Failed__imp_CreateThread:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_CreateThread failed',0
Failed__imp_QueryPerformanceFrequency:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_QueryPerformanceFrequency failed',0
Failed__imp_VirtualAllocExNuma:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualAllocExNuma failed',0
Failed__imp_VirtualAlloc:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualAlloc failed',0
Failed__imp_VirtualFree:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualFree failed',0
Failed__imp_VirtualAlloc_ReadIn:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualAlloc inside _ReadIn failed',0
Failed__imp_VirtualFree_ReadIn:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_VirtualFree inside _ReadIn failed',0
Failed__imp_GetLogicalProcessorInformationEx:
		lea   rdi, [@f]
		jmp   Failed
		@@: db '__imp_GetLogicalProcessorInformationEx failed',0
Failed_MatchingCore:
		lea   rdi, [@f]
		jmp   Failed
		@@: db 'matching core to node failed',0





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

