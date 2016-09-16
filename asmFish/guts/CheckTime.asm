CheckTime:
		cmp   byte[limits.ponder], 0
		jnz   .return

	       call   _GetTime
		sub   rax, qword[time.startTime]
		add   rax, 10
		cmp   byte[limits.useTimeMgmt], 0
		 je   @f
		cmp   rax, qword[time.maximumTime]
		 ja   .stop
	@@:
		cmp   byte[limits.movetime], 0
		 je   @f
		sub   rax, 10
		cmp   eax, dword[limits.movetime]
		jae   .stop
	@@:
		cmp   byte[limits.nodes], 0
		 je   @f
	       call   ThreadPool_NodesSearched
		cmp   rax, qword[limits.nodes]
		jae   .stop
	@@:
.return:
		ret

.stop:

match =1, VERBOSE {
push   rax
GD_String 'setting signals.stop in CheckTime'
GD_NewLine
pop   rax
}
		mov   byte[signals.stop], -1
		ret