
; the thread pool has two possible states
;  depending on whether the numa function are present or not
;
;1. not present:
;  threadPool.nodeCnt = 1 this is not accurate but works for the purpose of ThreadIdxToNode
;  the lone entry of threadPool.nodeTable has
;    .coreCnt =1         this is not accurate but works for the purpose of ThreadIdxToNode
;    .NodeNumber = -1    to bypass _VirtualAllocNuma for _VirtualAlloc instead
;    .GroupMask.Mask = 0 to bypass _BindThread;
;
;2. present:
;  entries are as expected


ThreadPool_Create:
	       push   rdi rsi rbx r12 r13 r14 r15
		sub   rsp, 8*16

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

	; figure out numa configuation

RelationProcessorCore = 0
RelationNumaNode      = 1


GD_String db '*** enumerating nodes *** '
GD_NewLine
		mov   ecx, RelationNumaNode
		lea   rdx, [threadPool.nodeTable]
		lea   r8, [rsp+8*8]
		mov   qword[r8], MAX_NUMANODES*sizeof.NumaNode
	       call   qword[__imp_GetLogicalProcessorInformationEx]
	     Assert   ne, eax, 0, 'GetLogicalProcessorInformationEx failed'
		mov   ebx, dword[rsp+8*8]
	     Assert   ne, ebx, 0, 'zero nodes returned in GetLogicalProcessorInformationEx'

		lea   rdi, [threadPool.nodeTable]
		add   rbx, rdi
		xor   esi, esi
.NextNumaNode:
		mov   dword[rdi+NumaNode.coreCnt], 0
GD_String db 'node number = '
GD_Int qword[rdi+NumaNode.NodeNumber]
GD_String db ': group = '
GD_Int qword[rdi+NumaNode.GroupMask.Group]
GD_String db ', mask = 0x'
GD_Hex qword[rdi+NumaNode.GroupMask.Mask]
GD_NewLine
		add   esi, 1
		add   rdi, sizeof.NumaNode
		cmp   rdi, rbx
		 jb   .NextNumaNode
		mov   dword[threadPool.nodeCnt], esi

GD_String db '*** finished enumerating nodes *** '
GD_NewLine
GD_NewLine





GD_String db '*** enumerating processor cores *** '
GD_NewLine

		mov   ecx, RelationProcessorCore
		xor   edx, edx
		lea   r8, [rsp+8*8]
		mov   qword[r8], 0
	       call   qword[__imp_GetLogicalProcessorInformationEx]

		mov   ecx, dword[rsp+8*8]
	       call   _VirtualAlloc
		mov   r15, rax

		mov   ecx, RelationProcessorCore
		mov   rdx, r15
		lea   r8, [rsp+8*8]
	       call   qword[__imp_GetLogicalProcessorInformationEx]
		mov   ebx, dword[rsp+8*8]

		mov   rdi, r15
		add   rbx, rdi
		mov   r14, rbx
.NextCore:
	      movzx   eax, word[rdi+32+GROUP_AFFINITY.Group]
		mov   rdx, qword[rdi+32+GROUP_AFFINITY.Mask]
GD_String db ' group = '
GD_Int rax
GD_String db ', mask = 0x'
GD_Hex rdx
GD_String db ', belongs to node '
	; find numa node that has this core
		lea   r8, [threadPool.nodeTable]
	       imul   r9d, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   r9, r8
.TryNextNode:
		cmp   ax, word[r8+NumaNode.GroupMask.Group]
		jne   @f
	       test   rdx, qword[r8+NumaNode.GroupMask.Mask]
		jnz   .Found
	@@:
		add   r8, sizeof.NumaNode
		cmp   r8, r9
		 jb   .TryNextNode
GD_String db 'ERROR: this core does not belong to one of the nodes!'
	     Assert   e, rsp, 0, 'ThreadPool_Create failed: no matching node for core'
.Found:
		inc   dword[r8+NumaNode.coreCnt]
GD_Int qword[r8+NumaNode.NodeNumber]
.Skip:
GD_NewLine
		mov   ecx, dword[rdi+4]
		add   rdi, rcx
		cmp   rdi, rbx
		 jb   .NextCore
GD_String db '*** finished enumerating processor cores *** '
GD_NewLine
GD_NewLine
		mov   rcx, r15
	       call   _VirtualFree




GD_String db '*** matching cores to nodes *** '
GD_NewLine

		lea   rdi, [threadPool.nodeTable]
	       imul   ebx, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   rbx, rdi
		xor   esi, esi
.NextNumaNode2:

		mov   ecx, 4*16*64*16*64
		mov   edx, dword[rdi+NumaNode.NodeNumber]
	       call   _VirtualAllocNuma
		mov   qword[rdi+NumaNode.cmhTable], rax

		add   esi, dword[rdi+NumaNode.coreCnt]

GD_String db 'node number = '
GD_Int qword[rdi+8]
GD_String db ': group = '
movzx eax, word[rdi+NumaNode.GroupMask.Group]
GD_Int rax
GD_String db ', mask = 0x'
GD_Hex qword[rdi+NumaNode.GroupMask.Mask]
GD_String db ', cores in node = '
GD_Int qword[rdi+NumaNode.coreCnt]
GD_String db ', cmh table = 0x'
GD_Hex qword[rdi+NumaNode.cmhTable]
GD_NewLine

		add   rdi, sizeof.NumaNode
		cmp   rdi, rbx
		 jb   .NextNumaNode2

		mov   dword[threadPool.coreCnt], esi

GD_String db ' total processor cores found: '
GD_Int rsi
GD_NewLine


GD_String db '*** finished matching cores to nodes *** '
GD_NewLine
GD_NewLine


.AbsentReturn:

		xor   ecx, ecx
	       call   Thread_Create
		mov   dword[threadPool.size], 1
	       call   ThreadPool_ReadOptions
		add   rsp, 8*16
		pop   r15 r14 r13 r12 rbx rdi rsi
		ret


.Absent:

GD_String db '*** numa functions not available ***'
GD_NewLine
GD_NewLine

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

		mov   qword[__imp_GetLogicalProcessorInformationEx], rax
		mov   qword[__imp_SetThreadGroupAffinity], rax
		mov   qword[__imp_VirtualAllocExNuma], rax
		jmp   .AbsentReturn







ThreadPool_Destroy:
	       push   rsi rdi rbx
		mov   edi, dword[threadPool.size]
		sub   edi, 1
.NextThread:
		mov   ecx, edi
	       call   Thread_Delete
		sub   edi, 1
		jns   .NextThread
		mov   dword[threadPool.size], 0

		lea   rdi, [threadPool.nodeTable]
	       imul   ebx, dword[threadPool.nodeCnt], sizeof.NumaNode
		add   rbx, rdi
.NextNumaNode:
		mov   rcx, qword[rdi+NumaNode.cmhTable]
	       call   _VirtualFree
		xor   eax, eax
		mov   qword[rdi+NumaNode.cmhTable], rax
		add   rdi, sizeof.NumaNode
		cmp   rdi, rbx
		 jb   .NextNumaNode

		pop   rbx rdi rsi
		ret


ThreadPool_ReadOptions:
	       push   rbx rsi rdi
		mov   esi, dword[options.threads]
		mov   edi, dword[threadPool.size]
.CheckCreate:
		cmp   edi, esi
		 jb   .Create
.CheckDelete:
		cmp   edi, esi
		 ja   .Delete
		pop   rdi rsi rbx
		ret
.Create:
		mov   ecx, edi
	       call   Thread_Create
		add   edi, 1
		mov   dword[threadPool.size], edi
		jmp   .CheckCreate
.Delete:
		sub   edi, 1
		mov   ecx, edi
	       call   Thread_Delete
		mov   dword[threadPool.size], edi
		jmp   .CheckDelete


ThreadPool_NodesSearched:
		xor   ecx, ecx
		xor   eax, eax
	.next_thread:
		mov   rdx, qword[threadPool.threadTable+8*rcx]
		add   rax, qword[rdx+Thread.nodes]
		add   ecx, 1
		cmp   ecx, dword[threadPool.size]
		 jb   .next_thread
		ret



ThreadPool_StartThinking:
	; in: rbp address of position
	;     rcx address of limits struct
	;            this will be copied to the global limits struct
	;            so that search threads can see it
	       push   rbp rbx rsi rdi r15
virtual at rsp
  .moveList rb sizeof.ExtMove*MAX_MOVES
  .lend rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))

	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize
		mov   rsi, rcx
		mov   r15, rbp

		mov   rcx, qword[threadPool.threadTable+8*0]
	       call   Thread_WaitForSearchFinished

		xor   eax, eax
		mov   byte[signals.stop], al
		mov   byte[signals.stopOnPonderhit], al
		lea   rcx, [limits]
		mov   rdx, rsi
	       call   Limits_Copy

	; copy to mainThread
		mov   rbx, qword[rbp+Pos.state]
	       call   SetCheckInfo
		lea   rdi, [.moveList]
	       call   Gen_Legal

		mov   rbx, qword[threadPool.threadTable+8*0]
		lea   rcx, [rbx+Thread.rootPos]
	       call   Position_CopyToSearch
		xor   eax, eax
		mov   dword[rbx+Thread.rootDepth], eax
		mov   qword[rbx+Thread.nodes], rax

		lea   rsi, [.moveList]
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
	       call   RootMovesVec_Clear
    .push_moves:
		cmp   rsi, rdi
		jae   .push_moves_done
		lea   rcx, [rbx+Thread.rootPos+Pos.rootMovesVec]
		mov   edx, dword[rsi+ExtMove.move]
		add   rsi, sizeof.ExtMove
	       call   RootMovesVec_PushBackMove
		jmp   .push_moves
    .push_moves_done:

	; the main thread should get the position for tb move filtering
		lea   rbp, [rbx+Thread.rootPos]
		mov   rbx, qword[rbp+Pos.state]
	; Skip TB probing when no TB found
		xor   eax, eax
		mov   dl, byte[options.syzygy50MoveRule]
		mov   qword[Tablebase_Hits], rax
		mov   byte[Tablebase_RootInTB], al
		mov   byte[Tablebase_UseRule50], dl
		mov   eax, dword[options.syzygyProbeLimit]
		mov   ecx, dword[options.syzygyProbeDepth]
		xor   edx, edx
		cmp   eax, dword[Tablebase_MaxCardinality]
	      cmovg   eax, dword[Tablebase_MaxCardinality]
	      cmovg   ecx, edx
		mov   dword[Tablebase_Cardinality], eax
		mov   dword[Tablebase_ProbeDepth], ecx
	; filter moves
		mov   rcx, qword[rbp+Pos.typeBB+8*White]
		 or   rcx, qword[rbp+Pos.typeBB+8*Black]
	     popcnt   rcx, rcx, rdx
		sub   eax, ecx
		sar   eax, 31
		 or   al, byte[rbx+State.castlingRights]
		 jz   .check_tb
.check_tb_ret:

	; filtering moves may have incremented nodes count
		mov   qword[rbx+Thread.nodes], rax


	; copy original position to workers
		xor   eax, eax
		mov   rbp, r15
		mov   rsi, qword[threadPool.threadTable+8*0]
		mov   qword[rsi+Thread.nodes], rax  ;filtering moves may have incremented mainThread.nodes
		xor   edi, edi
.next_thread:
		add   edi,1
		cmp   edi, dword[threadPool.size]
		jae   .thread_copy_done
		mov   rbx, qword[threadPool.threadTable+8*rdi]

		lea   rcx, [rbx+Thread.rootPos]
	       call   Position_CopyToSearch
		xor   eax, eax
		mov   dword[rbx+Thread.rootDepth], eax
		mov   qword[rbx+Thread.nodes], rax

	; copy the filtered moves of main thread to worker thread
		mov   rax, qword[rbx+Thread.rootPos.rootMovesVec.table]
		mov   rdx, qword[rsi+Thread.rootPos.rootMovesVec.table]
.copy_moves_loop:
		cmp   rdx, qword[rsi+Thread.rootPos.rootMovesVec.ender]
		jae   .copy_moves_done
	    vmovups   xmm0, dqword[rdx+0]    ; this should be sufficient to copy
	    vmovups   xmm1, dqword[rdx+16]   ; up to and including first move of pv
	    vmovups   dqword[rax+0], xmm0    ;
	    vmovups   dqword[rax+16], xmm1   ;
		add   rax, sizeof.RootMove
		add   rdx, sizeof.RootMove
		jmp   .copy_moves_loop
.copy_moves_done:
		mov   qword[rbx+Thread.rootPos.rootMovesVec.ender], rax

		jmp   .next_thread
.thread_copy_done:

		mov   rcx, qword[threadPool.threadTable+8*0]
	       call   Thread_StartSearching

		add   rsp, .localsize
		pop   r15 rdi rsi rbx rbp
		ret

.check_tb:
	       call   Tablebase_RootProbe
		mov   byte[Tablebase_RootInTB], al
		xor   edx, edx
	       test   eax, eax
		jnz   .root_in
	       call   Tablebase_RootProbeWDL
		mov   byte[Tablebase_RootInTB], al
		xor   edx, edx
		cmp   edx, dword[Tablebase_Score]
	      cmovg   edx, dword[Tablebase_Cardinality]
	.root_in:
		lea   rcx, [rbp+Pos.rootMovesVec]
		mov   dword[Tablebase_Cardinality], edx
	       call   RootMovesVec_Size
		mov   dword[Tablebase_Hits], eax
		mov   dl, byte[Tablebase_UseRule50]
		mov   eax, dword[Tablebase_Score]
	       test   dl, dl
		jnz   .check_tb_ret
		mov   ecx, VALUE_MATE - MAX_PLY - 1
		cmp   eax, 0
	      cmovg   eax, ecx
		neg   ecx
		cmp   eax, 0
	      cmovl   eax, ecx
		mov   dword[Tablebase_Score], eax
		jmp   .check_tb_ret
