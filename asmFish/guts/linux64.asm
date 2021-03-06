; Macroinstructions for defining data structures

macro struct name
 { virtual at 0
   fields@struct equ name
   match child parent, name \{ fields@struct equ child,fields@\#parent \}
   sub@struct equ
   struc db [val] \{ \common define field@struct .,db,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc dw [val] \{ \common define field@struct .,dw,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc du [val] \{ \common define field@struct .,du,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc dd [val] \{ \common define field@struct .,dd,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc dp [val] \{ \common define field@struct .,dp,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc dq [val] \{ \common define field@struct .,dq,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc dt [val] \{ \common define field@struct .,dt,<val>
			     fields@struct equ fields@struct,field@struct \}
   struc rb count \{ define field@struct .,db,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   struc rw count \{ define field@struct .,dw,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   struc rd count \{ define field@struct .,dd,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   struc rp count \{ define field@struct .,dp,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   struc rq count \{ define field@struct .,dq,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   struc rt count \{ define field@struct .,dt,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro db [val] \{ \common \local anonymous
		     define field@struct anonymous,db,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro dw [val] \{ \common \local anonymous
		     define field@struct anonymous,dw,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro du [val] \{ \common \local anonymous
		     define field@struct anonymous,du,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro dd [val] \{ \common \local anonymous
		     define field@struct anonymous,dd,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro dp [val] \{ \common \local anonymous
		     define field@struct anonymous,dp,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro dq [val] \{ \common \local anonymous
		     define field@struct anonymous,dq,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro dt [val] \{ \common \local anonymous
		     define field@struct anonymous,dt,<val>
		     fields@struct equ fields@struct,field@struct \}
   macro rb count \{ \local anonymous
		     define field@struct anonymous,db,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro rw count \{ \local anonymous
		     define field@struct anonymous,dw,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro rd count \{ \local anonymous
		     define field@struct anonymous,dd,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro rp count \{ \local anonymous
		     define field@struct anonymous,dp,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro rq count \{ \local anonymous
		     define field@struct anonymous,dq,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro rt count \{ \local anonymous
		     define field@struct anonymous,dt,count dup (?)
		     fields@struct equ fields@struct,field@struct \}
   macro union \{ fields@struct equ fields@struct,,union,<
		  sub@struct equ union \}
   macro struct \{ fields@struct equ fields@struct,,substruct,<
		  sub@struct equ substruct \} }

macro ends
 { match , sub@struct \{ restruc db,dw,du,dd,dp,dq,dt
			 restruc rb,rw,rd,rp,rq,rt
			 purge db,dw,du,dd,dp,dq,dt
			 purge rb,rw,rd,rp,rq,rt
			 purge union,struct
			 match name tail,fields@struct, \\{ if $
							    display 'Error: definition of ',\\`name,' contains illegal instructions.',0Dh,0Ah
							    err
							    end if \\}
			 match name=,fields,fields@struct \\{ fields@struct equ
							      make@struct name,fields
							      define fields@\\#name fields \\}
			 end virtual \}
   match any, sub@struct \{ fields@struct equ fields@struct> \}
   restore sub@struct }

macro make@struct name,[field,type,def]
 { common
    local define
    define equ name
   forward
    local sub
    match , field \{ make@substruct type,name,sub def
		     define equ define,.,sub, \}
    match any, field \{ define equ define,.#field,type,<def> \}
   common
    match fields, define \{ define@struct fields \} }

macro define@struct name,[field,type,def]
 { common
    virtual
    db `name
    load initial@struct byte from 0
    if initial@struct = '.'
    display 'Error: name of structure should not begin with a dot.',0Dh,0Ah
    err
    end if
    end virtual
    local list
    list equ
   forward
    if ~ field eq .
     name#field type def
     sizeof.#name#field = $ - name#field
    else
     label name#.#type
     rb sizeof.#type
    end if
    local value
    match any, list \{ list equ list, \}
    list equ list <value>
   common
    sizeof.#name = $
    restruc name
    match values, list \{
    struc name value \\{ \\local \\..base
    match any, fields@struct \\\{ fields@struct equ fields@struct,.,name,<values> \\\}
    match , fields@struct \\\{ label \\..base
   forward
     match , value \\\\{ field type def \\\\}
     match any, value \\\\{ field type value
			    if ~ field eq .
			     rb sizeof.#name#field - ($-field)
			    end if \\\\}
   common label . at \\..base \\\}
   \\}
    macro name value \\{
    match any, fields@struct \\\{ \\\local anonymous
				  fields@struct equ fields@struct,anonymous,name,<values> \\\}
    match , fields@struct \\\{
   forward
     match , value \\\\{ type def \\\\}
     match any, value \\\\{ \\\\local ..field
			   ..field = $
			   type value
			   if ~ field eq .
			    rb sizeof.#name#field - ($-..field)
			   end if \\\\}
   common \\\} \\} \} }

macro enable@substruct
 { macro make@substruct substruct,parent,name,[field,type,def]
    \{ \common
	\local define
	define equ parent,name
       \forward
	\local sub
	match , field \\{ match any, type \\\{ enable@substruct
					       make@substruct type,parent,sub def
					       purge make@substruct
					       define equ define,.,sub, \\\} \\}
	match any, field \\{ define equ define,.\#field,type,<def> \\}
       \common
	match fields, define \\{ define@\#substruct fields \\} \} }

enable@substruct

macro define@union parent,name,[field,type,def]
 { common
    virtual at parent#.#name
   forward
    if ~ field eq .
     virtual at parent#.#name
      parent#field type def
      sizeof.#parent#field = $ - parent#field
     end virtual
     if sizeof.#parent#field > $ - parent#.#name
      rb sizeof.#parent#field - ($ - parent#.#name)
     end if
    else
     virtual at parent#.#name
      label parent#.#type
      type def
     end virtual
     label name#.#type at parent#.#name
     if sizeof.#type > $ - parent#.#name
      rb sizeof.#type - ($ - parent#.#name)
     end if
    end if
   common
    sizeof.#name = $ - parent#.#name
    end virtual
    struc name [value] \{ \common
    label .\#name
    last@union equ
   forward
    match any, last@union \\{ virtual at .\#name
			       field type def
			      end virtual \\}
    match , last@union \\{ match , value \\\{ field type def \\\}
			   match any, value \\\{ field type value \\\} \\}
    last@union equ field
   common rb sizeof.#name - ($ - .\#name) \}
    macro name [value] \{ \common \local ..anonymous
			  ..anonymous name value \} }

macro define@substruct parent,name,[field,type,def]
 { common
    virtual at parent#.#name
   forward
    if ~ field eq .
     parent#field type def
     sizeof.#parent#field = $ - parent#field
    else
     label parent#.#type
     rb sizeof.#type
    end if
   common
    sizeof.#name = $ - parent#.#name
    end virtual
    struc name value \{
    label .\#name
   forward
     match , value \\{ field type def \\}
     match any, value \\{ field type value
			  if ~ field eq .
			   rb sizeof.#parent#field - ($-field)
			  end if \\}
   common \}
    macro name value \{ \local ..anonymous
			..anonymous name \} }


; Macroinstructions for making import section (64-bit)

macro library [name,string]
 { common
    import.data:
   forward
    local _label
    if defined name#.redundant
     if ~ name#.redundant
      dd RVA name#.lookup,0,0,RVA _label,RVA name#.address
     end if
    end if
    name#.referred = 1
   common
    dd 0,0,0,0,0
   forward
    if defined name#.redundant
     if ~ name#.redundant
      _label db string,0
	     rb RVA $ and 1
     end if
    end if }

macro import name,[label,string]
 { common
    rb (- rva $) and 7
    if defined name#.referred
     name#.lookup:
   forward
     if used label
      if string eqtype ''
       local _label
       dq RVA _label
      else
       dq 8000000000000000h + string
      end if
     end if
   common
     if $ > name#.lookup
      name#.redundant = 0
      dq 0
     else
      name#.redundant = 1
     end if
     name#.address:
   forward
     if used label
      if string eqtype ''
       label dq RVA _label
      else
       label dq 8000000000000000h + string
      end if
     end if
   common
     if ~ name#.redundant
      dq 0
     end if
   forward
     if used label & string eqtype ''
     _label dw 0
	    db string,0
	    rb RVA $ and 1
     end if
   common
    end if }

macro api [name] {}




sys_read		     = $0000
sys_write		     = $0001 
sys_open		     = $0002 
sys_close		     = $0003 
sys_newstat		     = $0004 
sys_newfstat		     = $0005 
sys_newlstat		     = $0006 
sys_stat		     = $0004 
sys_fstat		     = $0005 
sys_lstat		     = $0006 
sys_poll		     = $0007 
sys_lseek		     = $0008 
sys_mmap		     = $0009 
sys_mprotect		     = $000A 
sys_munmap		     = $000B 
sys_brk 		     = $000C 
sys_rt_sigaction	     = $000D 
sys_rt_sigprocmask	     = $000E 
stub_rt_sigreturn	     = $000F 
sys_ioctl		     = $0010 
sys_pread64		     = $0011 
sys_pwrite64		     = $0012 
sys_readv		     = $0013 
sys_writev		     = $0014 
sys_access		     = $0015 
sys_pipe		     = $0016 
sys_select		     = $0017 
sys_sched_yield 	     = $0018 
sys_mremap		     = $0019 
sys_msync		     = $001A 
sys_mincore		     = $001B 
sys_madvise		     = $001C 
sys_shmget		     = $001D 
sys_shmat		     = $001E 
sys_shmctl		     = $001F 
sys_dup 		     = $0020 
sys_dup2		     = $0021 
sys_pause		     = $0022 
sys_nanosleep		     = $0023 
sys_getitimer		     = $0024 
sys_alarm		     = $0025 
sys_setitimer		     = $0026 
sys_getpid		     = $0027 
sys_sendfile64		     = $0028 
sys_socket		     = $0029 
sys_connect		     = $002A 
sys_accept		     = $002B 
sys_sendto		     = $002C 
sys_recvfrom		     = $002D 
sys_sendmsg		     = $002E 
sys_recvmsg		     = $002F 
sys_shutdown		     = $0030 
sys_bind		     = $0031 
sys_listen		     = $0032 
sys_getsockname 	     = $0033 
sys_getpeername 	     = $0034 
sys_socketpair		     = $0035 
sys_setsockopt		     = $0036 
sys_getsockopt		     = $0037 
stub_clone		     = $0038 
stub_fork		     = $0039 
stub_vfork		     = $003A 
stub_execve		     = $003B 
sys_exit		     = $003C 
sys_wait4		     = $003D 
sys_kill		     = $003E 
sys_newuname		     = $003F 
sys_semget		     = $0040 
sys_semop		     = $0041 
sys_semctl		     = $0042 
sys_shmdt		     = $0043 
sys_msgget		     = $0044 
sys_msgsnd		     = $0045 
sys_msgrcv		     = $0046 
sys_msgctl		     = $0047 
sys_fcntl		     = $0048 
sys_flock		     = $0049 
sys_fsync		     = $004A 
sys_fdatasync		     = $004B 
sys_truncate		     = $004C 
sys_ftruncate		     = $004D 
sys_getdents		     = $004E 
sys_getcwd		     = $004F 
sys_chdir		     = $0050 
sys_fchdir		     = $0051 
sys_rename		     = $0052 
sys_mkdir		     = $0053 
sys_rmdir		     = $0054 
sys_creat		     = $0055 
sys_link		     = $0056 
sys_unlink		     = $0057 
sys_symlink		     = $0058 
sys_readlink		     = $0059 
sys_chmod		     = $005A 
sys_fchmod		     = $005B 
sys_chown		     = $005C 
sys_fchown		     = $005D 
sys_lchown		     = $005E 
sys_umask		     = $005F 
sys_gettimeofday	     = $0060 
sys_getrlimit		     = $0061 
sys_getrusage		     = $0062 
sys_sysinfo		     = $0063 
sys_times		     = $0064 
sys_ptrace		     = $0065 
sys_getuid		     = $0066 
sys_syslog		     = $0067 
sys_getgid		     = $0068 
sys_setuid		     = $0069 
sys_setgid		     = $006A 
sys_geteuid		     = $006B 
sys_getegid		     = $006C 
sys_setpgid		     = $006D 
sys_getppid		     = $006E 
sys_getpgrp		     = $006F 
sys_setsid		     = $0070 
sys_setreuid		     = $0071 
sys_setregid		     = $0072 
sys_getgroups		     = $0073 
sys_setgroups		     = $0074 
sys_setresuid		     = $0075 
sys_getresuid		     = $0076 
sys_setresgid		     = $0077 
sys_getresgid		     = $0078 
sys_getpgid		     = $0079 
sys_setfsuid		     = $007A 
sys_setfsgid		     = $007B 
sys_getsid		     = $007C 
sys_capget		     = $007D 
sys_capset		     = $007E 
sys_rt_sigpending	     = $007F 
sys_rt_sigtimedwait	     = $0080 
sys_rt_sigqueueinfo	     = $0081 
sys_rt_sigsuspend	     = $0082 
sys_sigaltstack 	     = $0083 
sys_utime		     = $0084 
sys_mknod		     = $0085 
sys_personality 	     = $0087 
sys_ustat		     = $0088 
sys_statfs		     = $0089 
sys_fstatfs		     = $008A 
sys_sysfs		     = $008B 
sys_getpriority 	     = $008C 
sys_setpriority 	     = $008D 
sys_sched_setparam	     = $008E 
sys_sched_getparam	     = $008F 
sys_sched_setscheduler	     = $0090 
sys_sched_getscheduler	     = $0091 
sys_sched_get_priority_max   = $0092 
sys_sched_get_priority_min   = $0093 
sys_sched_rr_get_interval    = $0094 
sys_mlock		     = $0095 
sys_munlock		     = $0096 
sys_mlockall		     = $0097 
sys_munlockall		     = $0098 
sys_vhangup		     = $0099 
sys_modify_ldt		     = $009A 
sys_pivot_root		     = $009B 
sys_sysctl		     = $009C 
sys_prctl		     = $009D 
sys_arch_prctl		     = $009E 
sys_adjtimex		     = $009F 
sys_setrlimit		     = $00A0 
sys_chroot		     = $00A1 
sys_sync		     = $00A2 
sys_acct		     = $00A3 
sys_settimeofday	     = $00A4 
sys_mount		     = $00A5 
sys_umount		     = $00A6 
sys_swapon		     = $00A7 
sys_swapoff		     = $00A8 
sys_reboot		     = $00A9 
sys_sethostname 	     = $00AA 
sys_setdomainname	     = $00AB 
stub_iopl		     = $00AC 
sys_ioperm		     = $00AD 
sys_init_module 	     = $00AF 
sys_delete_module	     = $00B0 
sys_quotactl		     = $00B3 
sys_gettid		     = $00BA 
sys_readahead		     = $00BB 
sys_setxattr		     = $00BC 
sys_lsetxattr		     = $00BD 
sys_fsetxattr		     = $00BE 
sys_getxattr		     = $00BF 
sys_lgetxattr		     = $00C0 
sys_fgetxattr		     = $00C1 
sys_listxattr		     = $00C2 
sys_llistxattr		     = $00C3 
sys_flistxattr		     = $00C4 
sys_removexattr 	     = $00C5 
sys_lremovexattr	     = $00C6 
sys_fremovexattr	     = $00C7 
sys_tkill		     = $00C8 
sys_time		     = $00C9 
sys_futex		     = $00CA 
sys_sched_setaffinity	     = $00CB 
sys_sched_getaffinity	     = $00CC 
sys_io_setup		     = $00CE 
sys_io_destroy		     = $00CF 
sys_io_getevents	     = $00D0 
sys_io_submit		     = $00D1 
sys_io_cancel		     = $00D2 
sys_lookup_dcookie	     = $00D4 
sys_epoll_create	     = $00D5 
sys_remap_file_pages	     = $00D8 
sys_getdents64		     = $00D9 
sys_set_tid_address	     = $00DA 
sys_restart_syscall	     = $00DB 
sys_semtimedop		     = $00DC 
sys_fadvise64		     = $00DD 
sys_timer_create	     = $00DE 
sys_timer_settime	     = $00DF 
sys_timer_gettime	     = $00E0 
sys_timer_getoverrun	     = $00E1 
sys_timer_delete	     = $00E2 
sys_clock_settime	     = $00E3 
sys_clock_gettime	     = $00E4 
sys_clock_getres	     = $00E5 
sys_clock_nanosleep	     = $00E6 
sys_exit_group		     = $00E7 
sys_epoll_wait		     = $00E8 
sys_epoll_ctl		     = $00E9 
sys_tgkill		     = $00EA 
sys_utimes		     = $00EB 
sys_mbind		     = $00ED 
sys_set_mempolicy	     = $00EE 
sys_get_mempolicy	     = $00EF 
sys_mq_open		     = $00F0 
sys_mq_unlink		     = $00F1 
sys_mq_timedsend	     = $00F2 
sys_mq_timedreceive	     = $00F3 
sys_mq_notify		     = $00F4 
sys_mq_getsetattr	     = $00F5 
sys_kexec_load		     = $00F6 
sys_waitid		     = $00F7 
sys_add_key		     = $00F8 
sys_request_key 	     = $00F9 
sys_keyctl		     = $00FA 
sys_ioprio_set		     = $00FB 
sys_ioprio_get		     = $00FC 
sys_inotify_init	     = $00FD 
sys_inotify_add_watch	     = $00FE 
sys_inotify_rm_watch	     = $00FF 
sys_migrate_pages	     = $0100 
sys_openat		     = $0101 
sys_mkdirat		     = $0102 
sys_mknodat		     = $0103 
sys_fchownat		     = $0104 
sys_futimesat		     = $0105 
sys_newfstatat		     = $0106 
sys_unlinkat		     = $0107 
sys_renameat		     = $0108 
sys_linkat		     = $0109 
sys_symlinkat		     = $010A 
sys_readlinkat		     = $010B 
sys_fchmodat		     = $010C 
sys_faccessat		     = $010D 
sys_pselect6		     = $010E 
sys_ppoll		     = $010F 
sys_unshare		     = $0110 
sys_set_robust_list	     = $0111 
sys_get_robust_list	     = $0112 
sys_splice		     = $0113 
sys_tee 		     = $0114 
sys_sync_file_range	     = $0115 
sys_vmsplice		     = $0116 
sys_move_pages		     = $0117 
sys_utimensat		     = $0118 
sys_epoll_pwait 	     = $0119 
sys_signalfd		     = $011A 
sys_timerfd_create	     = $011B 
sys_eventfd		     = $011C 
sys_fallocate		     = $011D 
sys_timerfd_settime	     = $011E 
sys_timerfd_gettime	     = $011F 
sys_accept4		     = $0120 
sys_signalfd4		     = $0121 
sys_eventfd2		     = $0122 
sys_epoll_create1	     = $0123 
sys_dup3		     = $0124 
sys_pipe2		     = $0125 
sys_inotify_init1	     = $0126 
sys_preadv		     = $0127 
sys_pwritev		     = $0128 
sys_rt_tgsigqueueinfo	     = $0129 
sys_perf_event_open	     = $012A 
sys_recvmmsg		     = $012B 
sys_fanotify_init	     = $012C 
sys_fanotify_mark	     = $012D 
sys_prlimit64		     = $012E 
sys_name_to_handle_at	     = $012F 
sys_open_by_handle_at	     = $0130 
sys_clock_adjtime	     = $0131 
sys_syncfs		     = $0132 
sys_sendmmsg		     = $0133 
sys_setns		     = $0134 
sys_getcpu		     = $0135 
sys_process_vm_readv	     = $0136 
sys_process_vm_writev	     = $0137 
sys_kcmp		     = $0138 
sys_finit_module	     = $0139 
sys_ni_syscall		     = $013A 
sys_ni_syscall2 	     = $013B 
sys_ni_syscall3 	     = $013C 
sys_seccomp		     = $013D 
compat_sys_rt_sigaction      = $0200 
stub_x32_rt_sigreturn	     = $0201 
compat_sys_ioctl	     = $0202 
compat_sys_readv	     = $0203 
compat_sys_writev	     = $0204 
compat_sys_recvfrom	     = $0205 
compat_sys_sendmsg	     = $0206 
compat_sys_recvmsg	     = $0207 
stub_x32_execve 	     = $0208 
compat_sys_ptrace	     = $0209 
compat_sys_rt_sigpending     = $020A 
compat_sys_rt_sigtimedwait   = $020B 
compat_sys_rt_sigqueueinfo   = $020C 
compat_sys_sigaltstack	     = $020D 
compat_sys_timer_create      = $020E 
compat_sys_mq_notify	     = $020F 
compat_sys_kexec_load	     = $0210 
compat_sys_waitid	     = $0211 
compat_sys_set_robust_list   = $0212 
compat_sys_get_robust_list   = $0213 
compat_sys_vmsplice	     = $0214 
compat_sys_move_pages	     = $0215 
compat_sys_preadv64	     = $0216 
compat_sys_pwritev64	     = $0217 
compat_sys_rt_tgsigqueueinfo = $0218 
compat_sys_recvmmsg	     = $0219 
compat_sys_sendmmsg	     = $021A 
compat_sys_process_vm_readv  = $021B 
compat_sys_process_vm_writev = $021C 
compat_sys_setsockopt	     = $021D 
compat_sys_getsockopt	     = $021E 
compat_sys_io_setup	     = $021F 
compat_sys_io_submit	     = $0220


; Signals
SIGHUP			= 1 
SIGINT			= 2 
SIGQUIT 		= 3 
SIGILL			= 4 
SIGTRAP 		= 5 
SIGIOT			= 6 
SIGABRT 		= 6 
SIGBUS			= 7 
SIGFPE			= 8 
SIGKILL 		= 9 
SIGUSR1 		= 10 
SIGSEGV 		= 11 
SIGUSR2 		= 12 
SIGPIPE 		= 13 
SIGALRM 		= 14 
SIGTERM 		= 15 
SIGSTKFLT		= 16 
SIGCHLD 		= 17 
SIGCLD			= 17 
SIGCONT 		= 18 
SIGSTOP 		= 19 
SIGTSTP 		= 20 
SIGTTIN 		= 21 
SIGTTOU 		= 22 
SIGURG			= 23 
SIGXCPU 		= 24 
SIGXFSZ 		= 25 
SIGVTALRM		= 26 
SIGPROF 		= 27 
SIGWINCH		= 28 
SIGIO			= 29 
SIGPOLL 		= 29 
SIGINFO 		= 30 
SIGPWR			= 30 
SIGSYS			= 31 

; Error numbers 
EPERM		= 1 
ENOENT		= 2 
ESRCH		= 3 
EINTR		= 4 
EIO		= 5 
ENXIO		= 6 
E2BIG		= 7 
ENOEXEC 	= 8 
EBADF		= 9 
ECHILD		= 10 
EAGAIN		= 11 
ENOMEM		= 12 
EACCES		= 13 
EFAULT		= 14 
ENOTBLK 	= 15 
EBUSY		= 16 
EEXIST		= 17 
EXDEV		= 18 
ENODEV		= 19 
ENOTDIR 	= 20 
EISDIR		= 21 
EINVAL		= 22 
ENFILE		= 23 
EMFILE		= 24 
ENOTTY		= 25 
ETXTBSY 	= 26 
EFBIG		= 27 
ENOSPC		= 28 
ESPIPE		= 29 
EROFS		= 30 
EMLINK		= 31 
EPIPE		= 32 
EDOM		= 33 
ERANGE		= 34 
EDEADLK 	= 35 
ENAMETOOLONG	= 36 
ENOLCK		= 37 
ENOSYS		= 38 
ENOTEMPTY	= 39 
ELOOP		= 40 
EWOULDBLOCK	= EAGAIN 
ENOMSG		= 42 
EIDRM		= 43 
ECHRNG		= 44 
EL2NSYNC	= 45 
EL3HLT		= 46 
EL3RST		= 47 
ELNRNG		= 48 
EUNATCH 	= 49 
ENOCSI		= 50 
EL2HLT		= 51 
EBADE		= 52 
EBADR		= 53 
EXFULL		= 54 
ENOANO		= 55 
EBADRQC 	= 56 
EBADSLT 	= 57 
EDEADLOCK	= EDEADLK 
EBFONT		= 59 
ENOSTR		= 60 
ENODATA 	= 61 
ETIME		= 62 
ENOSR		= 63 
ENONET		= 64 
ENOPKG		= 65 
EREMOTE 	= 66 
ENOLINK 	= 67 
EADV		= 68 
ESRMNT		= 69 
ECOMM		= 70 
EPROTO		= 71 
EMULTIHOP	= 72 
EDOTDOT 	= 73 
EBADMSG 	= 74 
EOVERFLOW	= 75 
ENOTUNIQ	= 76 
EBADFD		= 77 
EREMCHG 	= 78 
ELIBACC 	= 79 
ELIBBAD 	= 80 
ELIBSCN 	= 81 
ELIBMAX 	= 82 
ELIBEXEC	= 83 
EILSEQ		= 84 
ERESTART	= 85 
ESTRPIPE	= 86 
EUSERS		= 87 
ENOTSOCK	= 88 
EDESTADDRREQ	= 89 
EMSGSIZE	= 90 
EPROTOTYPE	= 91 
ENOPROTOOPT	= 92 
EPROTONOSUPPORT = 93 
ESOCKTNOSUPPORT = 94 
EOPNOTSUPP	= 95 
EPFNOSUPPORT	= 96 
EAFNOSUPPORT	= 97 
EADDRINUSE	= 98 
EADDRNOTAVAIL	= 99 
ENETDOWN	= 100 
ENETUNREACH	= 101 
ENETRESET	= 102 
ECONNABORTED	= 103 
ECONNRESET	= 104 
ENOBUFS 	= 105 
EISCONN 	= 106 
ENOTCONN	= 107 
ESHUTDOWN	= 108 
ETOOMANYREFS	= 109 
ETIMEDOUT	= 110 
ECONNREFUSED	= 111 
EHOSTDOWN	= 112 
EHOSTUNREACH	= 113 
EALREADY	= 114 
EINPROGRESS	= 115 
ESTALE		= 116 
EUCLEAN 	= 117 
ENOTNAM 	= 118 
ENAVAIL 	= 119 
EISNAM		= 120 
EREMOTEIO	= 121 
EDQUOT		= 122 
ENOMEDIUM	= 123 
EMEDIUMTYPE	= 124 
ECANCELED	= 125 
ENOKEY		= 126 
EKEYEXPIRED	= 127 
EKEYREVOKED	= 128 
EKEYREJECTED	= 129 
EOWNERDEAD	= 130 
ENOTRECOVERABLE = 131 
ERFKILL 	= 132 
EHWPOISON	= 133 

; O_ flags 
O_ACCMODE		= 00000003o 
O_RDONLY		= 00000000o 
O_WRONLY		= 00000001o 
O_RDWR			= 00000002o 
O_CREAT 		= 00000100o 
O_EXCL			= 00000200o 
O_NOCTTY		= 00000400o 
O_TRUNC 		= 00001000o 
O_APPEND		= 00002000o 
O_NONBLOCK		= 00004000o 
O_NDELAY		= O_NONBLOCK 
O_SYNC			= 04010000o 
O_FSYNC 		= O_SYNC 
O_ASYNC 		= 00020000o 
O_DIRECTORY		= 00200000o 
O_NOFOLLOW		= 00400000o 
O_CLOEXEC		= 02000000o 
O_DIRECT		= 00040000o 
O_NOATIME		= 01000000o 
O_PATH			= 10000000o 
O_DSYNC 		= 00010000o 
O_RSYNC 		= O_SYNC 
O_LARGEFILE		= 00100000o 

; R_ flags 
R_OK = 4 
W_OK = 2 
X_OK = 1 
F_OK = 0 

; S_ flags 
S_IRWXU 	   = 00000700o 
S_IRUSR 	   = 00000400o 
S_IWUSR 	   = 00000200o 
S_IXUSR 	   = 00000100o 
S_IRWXG 	   = 00000070o 
S_IRGRP 	   = 00000040o 
S_IWGRP 	   = 00000020o 
S_IXGRP 	   = 00000010o 
S_IRWXO 	   = 00000007o 
S_IROTH 	   = 00000004o 
S_IWOTH 	   = 00000002o 
S_IXOTH 	   = 00000001o 

; PROT_ flags 
PROT_READ		= $01 
PROT_WRITE		= $02 
PROT_EXEC		= $04 
PROT_SEM		= $08 
PROT_NONE		= $00 
PROT_GROWSDOWN		= $01000000 
PROT_GROWSUP		= $02000000 

; MAP_ flags 
MAP_SHARED		= $01 
MAP_PRIVATE		= $02 
MAP_TYPE		= $0F 
MAP_FIXED		= $10 
MAP_ANONYMOUS		= $20 
MAP_ANON		= MAP_ANONYMOUS 
MAP_FILE		= 0 
MAP_HUGE_SHIFT		= 26 
MAP_HUGE_MASK		= $3F 
MAP_32BIT		= $40 
MAP_GROWSUP		= $00200 
MAP_GROWSDOWN		= $00100 
MAP_DENYWRITE		= $00800 
MAP_EXECUTABLE		= $01000 
MAP_LOCKED		= $02000 
MAP_NORESERVE		= $04000 
MAP_POPULATE		= $08000 
MAP_NONBLOCK		= $10000 
MAP_STACK		= $20000 
MAP_HUGETLB		= $40000 

; MS_ flags 
MS_ASYNC		= 1 
MS_SYNC 		= 4 
MS_INVALIDATE		= 2 

; MCL_ flags 
MCL_CURRENT		= 1 
MCL_FUTURE		= 2 

; MREMAP_ flags 
MREMAP_MAYMOVE		= 1 
MREMAP_FIXED		= 2 

; MADV_ flags 
MADV_NORMAL		= 0 
MADV_RANDOM		= 1 
MADV_SEQUENTIAL 	= 2 
MADV_WILLNEED		= 3 
MADV_DONTNEED		= 4 
MADV_REMOVE		= 9 
MADV_DONTFORK		= 10 
MADV_DOFORK		= 11 
MADV_MERGEABLE		= 12 
MADV_UNMERGEABLE	= 13 
MADV_HUGEPAGE		= 14 
MADV_NOHUGEPAGE 	= 15 
MADV_HWPOISON		= 100 

; SEEK_ flags 
SEEK_6			= $0B 
SEEK_10 		= $2B 
SEEK_SET		= 0 
SEEK_CUR		= 1 
SEEK_END		= 2 
SEEK_DATA		= 3 
SEEK_HOLE		= 4 
SEEK_MAX		= SEEK_HOLE 

; CLONE_ flags 
CSIGNAL 		= $000000FF 
CLONE_VM		= $00000100 
CLONE_FS		= $00000200 
CLONE_FILES		= $00000400 
CLONE_SIGHAND		= $00000800 
CLONE_PTRACE		= $00002000 
CLONE_VFORK		= $00004000 
CLONE_PARENT		= $00008000 
CLONE_THREAD		= $00010000 
CLONE_NEWNS		= $00020000 
CLONE_SYSVSEM		= $00040000 
CLONE_SETTLS		= $00080000 
CLONE_PARENT_SETTID	= $00100000 
CLONE_CHILD_CLEARTID	= $00200000 
CLONE_DETACHED		= $00400000 
CLONE_UNTRACED		= $00800000 
CLONE_CHILD_SETTID	= $01000000 
CLONE_NEWUTS		= $04000000 
CLONE_NEWIPC		= $08000000 
CLONE_NEWUSER		= $10000000 
CLONE_NEWPID		= $20000000 
CLONE_NEWNET		= $40000000 
CLONE_IO		= $80000000 


; stdio
stdin  = 0 
stdout = 1 
stderr = 2 

; PRIO_ flags 
PRIO_PROCESS = 0 
PRIO_PGRP    = 1 
PRIO_USER    = 2


; futex
FUTEX_WAIT		= 0
FUTEX_WAKE		= 1
FUTEX_FD		= 2
FUTEX_REQUEUE		= 3
FUTEX_CMP_REQUEUE	= 4
FUTEX_WAKE_OP		= 5
FUTEX_LOCK_PI		= 6
FUTEX_UNLOCK_PI 	= 7
FUTEX_TRYLOCK_PI	= 8
FUTEX_WAIT_BITSET	= 9
FUTEX_WAKE_BITSET	= 10
FUTEX_WAIT_REQUEUE_PI	= 11
FUTEX_CMP_REQUEUE_PI	= 12
FUTEX_PRIVATE_FLAG	=128
FUTEX_CLOCK_REALTIME	=256
FUTEX_CMD_MASK		= not (FUTEX_PRIVATE_FLAG or FUTEX_CLOCK_REALTIME)
FUTEX_WAIT_PRIVATE	=(FUTEX_WAIT or FUTEX_PRIVATE_FLAG)
FUTEX_WAKE_PRIVATE	=(FUTEX_WAKE or FUTEX_PRIVATE_FLAG)
FUTEX_REQUEUE_PRIVATE	=(FUTEX_REQUEUE or FUTEX_PRIVATE_FLAG)
FUTEX_CMP_REQUEUE_PRIVATE =(FUTEX_CMP_REQUEUE or FUTEX_PRIVATE_FLAG)
FUTEX_WAKE_OP_PRIVATE	=(FUTEX_WAKE_OP or FUTEX_PRIVATE_FLAG)
FUTEX_LOCK_PI_PRIVATE	=(FUTEX_LOCK_PI or FUTEX_PRIVATE_FLAG)
FUTEX_UNLOCK_PI_PRIVATE =(FUTEX_UNLOCK_PI or FUTEX_PRIVATE_FLAG)
FUTEX_TRYLOCK_PI_PRIVATE =(FUTEX_TRYLOCK_PI or FUTEX_PRIVATE_FLAG)
FUTEX_WAIT_BITSET_PRIVATE	=(FUTEX_WAIT_BITSET or FUTEX_PRIVATE_FLAG)
FUTEX_WAKE_BITSET_PRIVATE	=(FUTEX_WAKE_BITSET or FUTEX_PRIVATE_FLAG)
FUTEX_WAIT_REQUEUE_PI_PRIVATE	=(FUTEX_WAIT_REQUEUE_PI or FUTEX_PRIVATE_FLAG)
FUTEX_CMP_REQUEUE_PI_PRIVATE	=(FUTEX_CMP_REQUEUE_PI or  FUTEX_PRIVATE_FLAG)


; memory policy
MPOL_DEFAULT	 = 0
MPOL_PREFERRED	 = 1
MPOL_BIND	 = 2
MPOL_INTERLEAVE  = 3


; CLOCK_ flags 
CLOCK_REALTIME		 = 0 
CLOCK_MONOTONIC 	 = 1 
CLOCK_PROCESS_CPUTIME_ID = 2 
CLOCK_THREAD_CPUTIME_ID  = 3 
CLOCK_MONOTONIC_RAW	 = 4 
CLOCK_REALTIME_COARSE	 = 5 
CLOCK_MONOTONIC_COARSE	 = 6 
CLOCK_BOOTTIME		 = 7 
CLOCK_REALTIME_ALARM	 = 8 
CLOCK_BOOTTIME_ALARM	 = 9 
CLOCK_SGI_CYCLE 	 = 10 
CLOCK_TAI		 = 11 
MAX_CLOCKS		 = 16 
CLOCKS_MASK		 = CLOCK_REALTIME or CLOCK_MONOTONIC 
CLOCKS_MONO		 = CLOCK_MONOTONIC 
TIMER_ABSTIME		 = 1 

; SIGEV_ flags 
SIGEV_SIGNAL	= 0 
SIGEV_NONE	= 1 
SIGEV_THREAD	= 2 
SIGEV_THREAD_ID = 4