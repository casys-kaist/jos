<h2>Introduction</h2>
<p>
   In this lab you will implement preemptive multitasking among multiple
   simultaneously active user-mode environments.
</p>
<p>
   In part A you will
   add multiprocessor support to JOS,
   implement round-robin scheduling, and add basic environment
   management system calls (calls that create and destroy environments,
   and allocate/map memory).
</p>
<p>
   In part B, you will implement a Unix-like <code>fork()</code>,
   which allows a user-mode environment to create copies of
   itself.
</p>
<p>
   Finally, in part C you will add support for inter-process
   communication (IPC), allowing different user-mode environments to
   communicate and synchronize with each other explicitly.  You will also
   add support for hardware clock interrupts and preemption.
</p>
<h3>Getting Started</h3>
<p>
   Use Git to commit your Lab 3 source, fetch the latest version of the course
   repository, and then create a local branch called <tt>lab4</tt> based on our
   lab4 branch, <tt>origin/lab4</tt>:
</p>
<pre>
kermit% <kbd>cd lab</kbd>
kermit% <kbd>add git</kbd>
kermit% <kbd>git pull</kbd>
Already up-to-date.
kermit% <kbd>git checkout -b lab4 origin/lab4</kbd>
Branch lab4 set up to track remote branch refs/remotes/origin/lab4.
Switched to a new branch "lab4"
kermit% <kbd>git merge lab3</kbd>
Merge made by recursive.
...
athena% 
</pre>
Lab 4 contains a number of new source files, some of which you should browse
before you start:
<table align="center">
   <tr>
      <td><tt>kern/cpu.h</tt></td>
      <td>Kernel-private definitions for multiprocessor support</td>
   </tr>
   <tr>
      <td><tt>kern/mpconfig.c</tt></td>
      <td>Code to read the multiprocessor configuration</td>
   </tr>
   <tr>
      <td><tt>kern/lapic.c</tt></td>
      <td>Kernel code driving the local APIC unit in each processor</td>
   </tr>
   <tr>
      <td><tt>kern/mpentry.S</tt></td>
      <td>Assembly-language entry code for non-boot CPUs</td>
   </tr>
   <tr>
      <td><tt>kern/spinlock.h</tt></td>
      <td>Kernel-private definitions for spin locks, including
         the big kernel lock
      </td>
   </tr>
   <tr>
      <td><tt>kern/spinlock.c</tt></td>
      <td>Kernel code implementing spin locks</td>
   </tr>
   <tr>
      <td><tt>kern/sched.c</tt></td>
      <td>Code skeleton of the scheduler that you are about to implement</td>
   </tr>
</table>
<h3>Lab Requirements</h3>
<p>
   This lab is divided into three parts, A, B, and C.
   We have allocated one week in the schedule for each part.
</p>
<p>
   As before,
   you will need to do all of the regular exercises described in the lab
   and <i>at least one</i> challenge problem.
   (You do not need to do one challenge problem per part,
   just one for the whole lab.)
   Additionally, you will need to write up a brief
   description of the challenge problem that you implemented.
   If you implement more than one challenge problem,
   you only need to describe one of them in the write-up,
   though of course you are welcome to do more.
   Place the write-up in a file called <tt>answers-lab4.txt</tt>
   in the top level of your <tt>lab</tt> directory
   before handing in your work.
</p>
<h2>Part A: Multiprocessor Support and Cooperative Multitasking</h2>
<p>
   In the first part of this lab,
   you will first extend JOS to run on a multiprocessor system, 
   and then implement some new JOS kernel system calls
   to allow user-level environments to create
   additional new environments.
   You will also implement <i>cooperative</i> round-robin scheduling,
   allowing the kernel to switch from one environment to another
   when the current environment voluntarily relinquishes the CPU (or exits).
   Later in part C you will implement <i>preemptive</i> scheduling,
   which allows the kernel to re-take control of the CPU from an environment
   after a certain time has passed even if the environment does not cooperate.
</p>
<h3> Multiprocessor Support </h3>
<p>
   We are going to make JOS support "symmetric multiprocessing" (SMP), a
   multiprocessor model in which all CPUs have equivalent access to
   system resources such as memory and I/O buses.  While all CPUs
   are functionally identical in SMP, during the boot process they
   can be classified into two types: the bootstrap processor (BSP) is
   responsible for initializing the system and for booting the operating
   system; and the application processors (APs) are activated by the BSP
   only after the operating system is up and running. Which processor is
   the BSP is determined by the hardware and the BIOS. Up to this point,
   all your existing JOS code has been running on the BSP. 
</p>
<p>
   In an SMP system, each CPU has an accompanying local APIC (LAPIC) unit.
   The LAPIC units are responsible for delivering interrupts throughout
   the system. The LAPIC also provides its connected CPU with a unique
   identifier. In this lab, we make use of the following basic
   functionality of the LAPIC unit (in <tt>kern/lapic.c</tt>):
</p>
<ul>
   <li>Reading the LAPIC identifier (APIC ID) to tell which CPU our code is
      currently running on (see <code>cpunum()</code>). 
   </li>
   <li>Sending the <code>STARTUP</code> interprocessor interrupt (IPI) from
      the BSP to the APs to bring up other CPUs (see
      <code>lapic_startap()</code>).
   </li>
   <li>In part C, we program LAPIC's built-in timer to trigger clock
      interrupts to support preemptive multitasking (see
      <code>apic_init()</code>).
   </li>
</ul>
<p>
   A processor accesses its LAPIC using memory-mapped I/O (MMIO).
   In MMIO, a portion of <i>physical</i> memory is hardwired to the
   registers of some I/O devices, so the same load/store instructions
   typically used to access memory can be used to access device
   registers.  You've already seen one IO hole at physical address
   <tt>0xA0000</tt> (we use this to write to the VGA display buffer).
   The LAPIC lives in a hole starting at physical address
   <tt>0xFE000000</tt> (32MB short of 4GB), so it's too high for us to
   access using our usual direct map at KERNBASE.  The JOS virtual memory
   map leaves a 4MB gap at <tt>MMIOBASE</tt> so we have a place to map
   devices like this.  Since later labs introduce more MMIO regions,
   you'll write a simple function to allocate space from this region and
   map device memory to it.
</p>
<div class="required">
   <p><span class="header">Exercise 1.</span>
      Implement <code>mmio_map_region</code> in <tt>kern/pmap.c</tt>.  To
      see how this is used, look at the beginning of
      <code>lapic_init</code> in <tt>kern/lapic.c</tt>.  You'll have to do
      the next exercise, too, before the tests for
      <code>mmio_map_region</code> will run.
   </p>
</div>
<h4>Application Processor Bootstrap</h4>
<p>
   Before booting up APs, the BSP should first collect information
   about the multiprocessor system, such as the total number of
   CPUs, their APIC IDs and the MMIO address of the LAPIC unit.
   The <code>mp_init()</code> function in <tt>kern/mpconfig.c</tt>
   retrieves this information by reading the MP configuration
   table that resides in the BIOS's region of memory.
</p>
<p>
   The <code>boot_aps()</code> function (in <tt>kern/init.c</tt>) drives
   the AP bootstrap process.  APs start in real mode, much like how the
   bootloader started in <tt>boot/boot.S</tt>, so <code>boot_aps()</code>
   copies the AP entry code (<tt>kern/mpentry.S</tt>) to a memory
   location that is addressable in the real mode.  Unlike with the
   bootloader, we have some control over where the AP will start
   executing code; we copy the entry code to <tt>0x7000</tt>
   (<code>MPENTRY_PADDR</code>), but any unused, page-aligned
   physical address below 640KB would work.
</p>
<p>
   After that, <code>boot_aps()</code> activates APs one after another, by
   sending <code>STARTUP</code> IPIs to the LAPIC unit of the corresponding
   AP, along with an initial <code>CS:IP</code> address at which the AP
   should start running its entry code (<code>MPENTRY_PADDR</code> in our
   case). The entry code in <tt>kern/mpentry.S</tt> is quite similar to
   that of <tt>boot/boot.S</tt>. After some brief setup, it puts the AP
   into protected mode with paging enabled, and then calls the C setup
   routine <code>mp_main()</code> (also in <tt>kern/init.c</tt>).
   <code>boot_aps()</code> waits for the AP to signal a 
   <code>CPU_STARTED</code> flag in <code>cpu_status</code> field of
   its <code>struct CpuInfo</code> before going on to wake up the next one.
</p>
<div class="required">
   <p><span class="header">Exercise 2.</span>
      Read <code>boot_aps()</code> and <code>mp_main()</code> in
      <tt>kern/init.c</tt>, and the assembly code in
      <tt>kern/mpentry.S</tt>.  Make sure you understand the control flow
      transfer during the bootstrap of APs. Then modify your implementation
      of <code>page_init()</code> in <tt>kern/pmap.c</tt> to avoid adding
      the page at <code>MPENTRY_PADDR</code> to the free list, so that we
      can safely copy and run AP bootstrap code at that physical address.
      Your code should pass the updated <code>check_page_free_list()</code>
      test (but might fail the updated <code>check_kern_pgdir()</code>
      test, which we will fix soon).
   </p>
</div>
<div class="question">
   <p><span class="header">Question</span></p>
   <ol>
      <li>
         Compare <tt>kern/mpentry.S</tt> side by side with
         <tt>boot/boot.S</tt>.  Bearing in mind that <tt>kern/mpentry.S</tt>
         is compiled and linked to run above <code>KERNBASE</code> just like
         everything else in the kernel, what is the purpose of macro
         <code>MPBOOTPHYS</code>? Why is it
         necessary in <tt>kern/mpentry.S</tt> but not in
         <tt>boot/boot.S</tt>? In other words, what could go wrong if it
         were omitted in <tt>kern/mpentry.S</tt>?
         <br/>
         Hint: recall the differences between the link address and the 
         load address that we have discussed in Lab 1.
      </li>
   </ol>
</div>
<h4>Per-CPU State and Initialization</h4>
<p>
   When writing a multiprocessor OS, it is important to distinguish
   between per-CPU state that is private to each processor, and global
   state that the whole system shares.  <tt>kern/cpu.h</tt> defines most
   of the per-CPU state, including <code>struct CpuInfo</code>, which stores
   per-CPU variables.  <code>cpunum()</code> always returns the ID of the
   CPU that calls it, which can be used as an index into arrays like
   <code>cpus</code>.  Alternatively, the macro <code>thiscpu</code> is
   shorthand for the current CPU's <code>struct CpuInfo</code>.
</p>
<p>
   Here is the per-CPU state you should be aware of:
</p>
<ul>
   <li>
      <p>
         <b>Per-CPU kernel stack</b>.
         <br />
         Because multiple CPUs can trap into the kernel simultaneously,
         we need a separate kernel stack for each processor to prevent them from
         interfering with each other's execution. The array
         <code>percpu_kstacks[NCPU][KSTKSIZE]</code> reserves space for NCPU's
         worth of kernel stacks.
      </p>
      <p>
         In Lab 2, you mapped the physical memory that <code>bootstack</code>
         refers to as the BSP's kernel stack just below
         <code>KSTACKTOP</code>.
         Similarly, in this lab, you will map each CPU's kernel stack into this
         region with guard pages acting as a buffer between them.  CPU 0's
         stack will still grow down from <code>KSTACKTOP</code>; CPU 1's stack
         will start <code>KSTKGAP</code> bytes below the bottom of CPU 0's
         stack, and so on. <tt>inc/memlayout.h</tt> shows the mapping layout.
      </p>
   </li>
   <li>
      <p>
         <b>Per-CPU TSS and TSS descriptor</b>.
         <br />
         A per-CPU task state segment (TSS) is also needed in order to specify
         where each CPU's kernel stack lives. The TSS for CPU <i>i</i> is stored
         in <code>cpus[i].cpu_ts</code>, and the corresponding TSS descriptor is
         defined in the GDT entry <code>gdt[(GD_TSS0 >> 3) + i]</code>. The
         global <code>ts</code> variable defined in <tt>kern/trap.c</tt> will
         no longer be useful.
      </p>
   </li>
   <li>
      <p>
         <b>Per-CPU current environment pointer</b>.
         <br />
         Since each CPU can run different user process simultaneously, we
         redefined the symbol <code>curenv</code> to refer to
         <code>cpus[cpunum()].cpu_env</code> (or <code>thiscpu->cpu_env</code>), which
         points to the environment <i>currently</i> executing on the
         <i>current</i> CPU (the CPU on which the code is running).
      </p>
   </li>
   <li>
      <p>
         <b>Per-CPU system registers</b>.
         <br />
         All registers, including system registers, are private to a
         CPU. Therefore, instructions that
         initialize these registers, such as <code>lcr3()</code>,
         <code>ltr()</code>, <code>lgdt()</code>, <code>lidt()</code>, etc., must
         be executed once on each CPU. Functions <code>env_init_percpu()</code>
         and <code>trap_init_percpu()</code> are defined for this purpose.
      </p>
   </li>
   <p>
      In addition to this, if you have added any extra per-CPU state or performed
      any additional CPU-specific initialization (by say, setting new bits in
      the CPU registers) in your solutions to challenge problems in earlier labs,
      be sure to replicate them on each CPU here!
   </p>
</ul>
<!-- XXX: describe zoombie env and env_cpunum -->
<div class="required">
   <p><span class="header">Exercise 3.</span>
      Modify <code>mem_init_mp()</code> (in <tt>kern/pmap.c</tt>) to map
      per-CPU stacks starting
      at <code>KSTACKTOP</code>, as shown in
      <tt>inc/memlayout.h</tt>.  The size of each stack is
      <code>KSTKSIZE</code> bytes plus <code>KSTKGAP</code> bytes of
      unmapped guard pages. Your code should pass the new check in
      <code>check_kern_pgdir()</code>.
   </p>
</div>
<div class="required">
   <p><span class="header">Exercise 4.</span>
      The code in <code>trap_init_percpu()</code> (<tt>kern/trap.c</tt>)
      initializes the TSS and
      TSS descriptor for the BSP. It worked in Lab 3, but is incorrect
      when running on other CPUs. Change the code so that it can work
      on all CPUs. (Note: your new code should not use the global
      <code>ts</code> variable any more.)
   </p>
</div>
<p>
   When you finish the above exercises, run JOS in QEMU with 4 CPUs using
   <kbd>make qemu CPUS=4</kbd> (or <kbd>make qemu-nox CPUS=4</kbd>), you
   should see output like this:
</p>
<pre>
...
Physical memory: 66556K available, base = 640K, extended = 65532K
check_page_alloc() succeeded!
check_page() succeeded!
check_kern_pgdir() succeeded!
check_page_installed_pgdir() succeeded!
SMP: CPU 0 found 4 CPU(s)
enabled interrupts: 1 2
SMP: CPU 1 starting
SMP: CPU 2 starting
SMP: CPU 3 starting
</pre>
<h4>Locking</h4>
<p>
   Our current code spins after initializing the AP in
   <code>mp_main()</code>. Before letting the AP get any further, we need
   to first address race conditions when multiple CPUs run kernel code
   simultaneously.  The simplest way to achieve this is to use a <i>big
   kernel lock</i>.
   The big kernel lock is a single global lock that is held whenever an
   environment enters kernel mode, and is released when the environment
   returns to user mode. In this model, environments in user mode can run
   concurrently on any available CPUs, but no more than one environment can
   run in kernel mode; any other environments that try to enter kernel mode
   are forced to wait.
</p>
<p>
   <tt>kern/spinlock.h</tt> declares the big kernel lock, namely
   <code>kernel_lock</code>. It also provides <code>lock_kernel()</code>
   and <code>unlock_kernel()</code>, shortcuts to acquire and
   release the lock. You should apply the big kernel lock at four locations:
</p>
<ul>
   <li>
      In <code>i386_init()</code>, acquire the lock before the BSP wakes up the
      other CPUs. 
   </li>
   <li>
      In <code>mp_main()</code>, acquire the lock after initializing the AP,
      and then call <code>sched_yield()</code> to start running environments
      on this AP.
   </li>
   <li>
      In <code>trap()</code>, acquire the lock when trapped from user mode.
      To determine whether a trap happened in user mode or in kernel mode,
      check the low bits of the <code>tf_cs</code>.
   </li>
   <li>
      In <code>env_run()</code>, release the lock <i>right before</i>
      switching to user mode. Do not do that too early or too late, otherwise
      you will experience races or deadlocks.
   </li>
</ul>
<div class="required">
   <p><span class="header">Exercise 5.</span>
      Apply the big kernel lock as described above, by calling
      <code>lock_kernel()</code> and <code>unlock_kernel()</code> at
      the proper locations.
   </p>
</div>
<p>
   How to test if your locking is correct? You can't at this moment! But you
   will be able to after you implement the scheduler in the
   next exercise.
</p>
<div class="question">
   <p><span class="header">Question</span></p>
   <ol start="2">
      <li>
         It seems that using the big kernel lock guarantees that only one CPU
         can run the kernel code at a time. 
         Why do we still need separate kernel stacks for each CPU?
         Describe a scenario in which using a shared kernel stack will go
         wrong, even with the protection of the big kernel lock.
      </li>
   </ol>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      The big kernel lock is simple and easy to use. Nevertheless, it
      eliminates all concurrency in kernel mode. Most
      modern operating systems use different locks to protect different
      parts of their shared state, an
      approach called <i>fine-grained locking</i>.
      Fine-grained locking can increase performance significantly, but is
      more difficult to implement and error-prone. If you are brave
      enough, drop the big kernel lock and embrace concurrency in JOS!
   </p>
   <p>
      It is up to you to decide the locking granularity (the amount of
      data that a lock protects). As a hint, you may consider using
      spin locks to ensure exclusive access to these shared components
      in the JOS kernel:
   </p>
   <ul>
      <li>The page allocator.</li>
      <li>The console driver.</li>
      <li>The scheduler.</li>
      <li>The inter-process communication (IPC) state that you will
         implement in the part C.
      </li>
   </ul>
</div>
<h3>Round-Robin Scheduling</h3>
<p>
   Your next task in this lab is to change the JOS kernel
   so that it can alternate between multiple environments
   in "round-robin" fashion.
   Round-robin scheduling in JOS works as follows:
</p>
<ul>
   <li>	The function <code>sched_yield()</code> in the new <tt>kern/sched.c</tt>
      is responsible for selecting a new environment to run.
      It searches sequentially through the <code>envs[]</code> array
      in circular fashion,
      starting just after the previously running environment
      (or at the beginning of the array
      if there was no previously running environment),
      picks the first environment it finds
      with a status of <code>ENV_RUNNABLE</code>
      (see <tt>inc/env.h</tt>),
      and calls <code>env_run()</code> to jump into that environment. 
   </li>
   <li>	<code>sched_yield()</code> must never run the same environment
      on two CPUs at the same time.  It can tell that an environment
      is currently running on some CPU (possibly the current CPU)
      because that environment's status will be <code>ENV_RUNNING</code>.
   </li>
   <li>	We have implemented a new system call for you,
      <code>sys_yield()</code>,
      which user environments can call
      to invoke the kernel's <code>sched_yield()</code> function
      and thereby voluntarily give up the CPU to a different environment.  
   </li>
</ul>
<div class="required">
   <p><span class="header">Exercise 6.</span>
      Implement round-robin scheduling in <code>sched_yield()</code>
      as described above.  Don't forget to modify
      <code>syscall()</code> to dispatch <code>sys_yield()</code>.
   </p>
   <p>Make sure to invoke <code>sched_yield()</code> in <code>mp_main</code>.
   <p> Modify <tt>kern/init.c</tt> to create three (or more!) environments
      that all run the program <tt>user/yield.c</tt>.
   </p>
   <p>Run <kbd>make qemu</kbd>.
      You should see the environments
      switch back and forth between each other
      five times before terminating, like below.
   </p>
   <p>Test also with several CPUS: <kbd>make qemu CPUS=2</kbd>.
   <pre>
...
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Hello, I am environment 00001002.
Back in environment 00001000, iteration 0.
Back in environment 00001001, iteration 0.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 1.
...
</pre>
   <p>
      After the <tt>yield</tt> programs exit, there will be no runnable
      environment in the system, the scheduler should
      invoke the JOS kernel monitor.
      If any of this does not happen,
      then fix your code before proceeding.
   </p>
   <!-- No longer true
      <p>
      If you use <kbd>CPUS=1</kbd> at this point, all environments should
      successfully run. Setting CPUS larger than 1 at this time may result in
      a general protection fault, kernel page fault, or other unexpected
      interrupt once there are no more runnable environments due to unhandled
      timer interrupts (which we will fix below!).
      </p>-->
</div>
<div class="question">
   <p><span class="header">Question</span></p>
   <ol start="3">
      <li>
         In your implementation of <code>env_run()</code> you should have
         called <code>lcr3()</code>.  Before and after the call to
         <code>lcr3()</code>, your code makes references (at least it should)
         to the variable <code>e</code>, the argument to <code>env_run</code>.
         Upon loading the <code>%cr3</code> register, the addressing context
         used by the MMU is instantly changed.  But a virtual
         address (namely <code>e</code>) has meaning relative to a given
         address context--the address context specifies the physical address to
         which the virtual address maps.  Why can the pointer <code>e</code> be
         dereferenced both before and after the addressing switch?
      </li>
      <li>
         Whenever the kernel switches from one environment to another,
         it must ensure the old environment's registers are saved
         so they can be restored properly later. 
         Why?  Where does this happen?
      </li>
   </ol>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Add a less trivial scheduling policy to the kernel,
      such as a fixed-priority scheduler that allows each environment
      to be assigned a priority
      and ensures that higher-priority environments
      are always chosen in preference to lower-priority environments.
      If you're feeling really adventurous,
      try implementing a Unix-style adjustable-priority scheduler
      or even a lottery or stride scheduler.
      (Look up "lottery scheduling" and "stride scheduling" in Google.)
   </p>
   <p>
      Write a test program or two
      that verifies that your scheduling algorithm is working correctly
      (i.e., the right environments get run in the right order).
      It may be easier to write these test programs
      once you have implemented <code>fork()</code> and IPC
      in parts B and C of this lab.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      The JOS kernel currently does not allow applications
      to use the x86 processor's x87 floating-point unit (FPU),
      MMX instructions, or Streaming SIMD Extensions (SSE).
      Extend the <code>Env</code> structure
      to provide a save area for the processor's floating point state,
      and extend the context switching code
      to save and restore this state properly
      when switching from one environment to another.
      The <code>FXSAVE</code> and <code>FXRSTOR</code> instructions may be useful,
      but note that these are not in the old i386 user's manual
      because they were introduced in more recent processors.
      Write a user-level test program
      that does something cool with floating-point.
   </p>
</div>
<h3>System Calls for Environment Creation</h3>
<p>
   Although your kernel is now capable of running and switching between
   multiple user-level environments,
   it is still limited to running environments
   that the <i>kernel</i> initially set up.
   You will now implement the necessary JOS system calls
   to allow <i>user</i> environments to create and start
   other new user environments.
</p>
<p>
   Unix provides the <code>fork()</code> system call
   as its process creation primitive.
   Unix <code>fork()</code> copies
   the entire address space of calling process (the parent)
   to create a new process (the child).
   The only differences between the two observable from user space
   are their process IDs and parent process IDs
   (as returned by <code>getpid</code> and <code>getppid</code>).
   In the parent,
   <code>fork()</code> returns the child's process ID,
   while in the child, <code>fork()</code> returns 0.
   By default, each process gets its own private address space, and
   neither process's modifications to memory are visible to the other.
</p>
<p>
   You will provide a different, more primitive
   set of JOS system calls
   for creating new user-mode environments.
   With these system calls you will be able to implement
   a Unix-like <code>fork()</code> entirely in user space,
   in addition to other styles of environment creation.
   The new system calls you will write for JOS are as follows:
</p>
<dl>
   <dt>	<code>sys_exofork</code>:</dt>
   <dd>	This system call creates a new environment with an almost blank slate:
      nothing is mapped in the user portion of its address space,
      and it is not runnable.
      The new environment will have the same register state as the
      parent environment at the time of the <code>sys_exofork</code> call.
      In the parent, <code>sys_exofork</code>
      will return the <code>envid_t</code> of the newly created
      environment
      (or a negative error code if the environment allocation failed).
      In the child, however, it will return 0.
      (Since the child starts out marked as not runnable,
      <code>sys_exofork</code> will not actually return in the child
      until the parent has explicitly allowed this
      by marking the child runnable using....)
   </dd>
   <dt>	<code>sys_env_set_status</code>:</dt>
   <dd>	Sets the status of a specified environment
      to <code>ENV_RUNNABLE</code> or <code>ENV_NOT_RUNNABLE</code>.
      This system call is typically used
      to mark a new environment ready to run,
      once its address space and register state
      has been fully initialized.
   </dd>
   <dt>	<code>sys_page_alloc</code>:</dt>
   <dd>	Allocates a page of physical memory
      and maps it at a given virtual address
      in a given environment's address space.
   </dd>
   <dt>	<code>sys_page_map</code>:</dt>
   <dd>	Copy a page mapping (<i>not</i> the contents of a page!)
      from one environment's address space to another,
      leaving a memory sharing arrangement in place
      so that the new and the old mappings both refer to
      the same page of physical memory.
   </dd>
   <dt>	<code>sys_page_unmap</code>:</dt>
   <dd>	Unmap a page mapped at a given virtual address
      in a given environment.
   </dd>
</dl>
<p>
   For all of the system calls above that accept environment IDs,
   the JOS kernel supports the convention
   that a value of 0 means "the current environment."
   This convention is implemented by <code>envid2env()</code>
   in <tt>kern/env.c</tt>.
</p>
<p>
   We have provided a very primitive implementation
   of a Unix-like <code>fork()</code>
   in the test program <tt>user/dumbfork.c</tt>.
   This test program uses the above system calls
   to create and run a child environment
   with a copy of its own address space.
   The two environments
   then switch back and forth using <code>sys_yield</code>
   as in the previous exercise.
   The parent exits after 10 iterations,
   whereas the child exits after 20.
</p>
<div class="required">
   <p><span class="header">Exercise 7.</span>
      Implement the system calls described above
      in <tt>kern/syscall.c</tt> and make sure <tt>syscall()</tt> calls
      them.
      You will need to use various functions
      in <tt>kern/pmap.c</tt> and <tt>kern/env.c</tt>,
      particularly <code>envid2env()</code>.
      For now, whenever you call <code>envid2env()</code>,
      pass 1 in the <code>checkperm</code> parameter.
      Be sure you check for any invalid system call arguments,
      returning <code>-E_INVAL</code> in that case.
      Test your JOS kernel with <tt>user/dumbfork</tt>
      and make sure it works before proceeding.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Add the additional system calls necessary
      to <i>read</i> all of the vital state of an existing environment
      as well as set it up.
      Then implement a user mode program that forks off a child environment,
      runs it for a while (e.g., a few iterations of <code>sys_yield()</code>),
      then takes a complete snapshot or <i>checkpoint</i>
      of the child environment,
      runs the child for a while longer,
      and finally restores the child environment to the state it was in
      at the checkpoint
      and continues it from there.
      Thus, you are effectively "replaying"
      the execution of the child environment from an intermediate state.
      Make the child environment perform some interaction with the user
      using <code>sys_cgetc()</code> or <code>readline()</code>
      so that the user can view and mutate its internal state,
      and verify that with your checkpoint/restart
      you can give the child environment a case of selective amnesia,
      making it "forget" everything that happened beyond a certain point.
   </p>
</div>
<p>
   This completes Part A of the lab;
   make sure it passes all of the Part A tests when you run
   <kbd>make grade</kbd>, and hand it in using <kbd>make
   handin</kbd> as usual.  If you are trying to figure out why a particular
   test case is failing, run <kbd>./grade-lab4 -v</kbd>, which will
   show you the output of the kernel builds and QEMU runs for each
   test, until a test fails.  When a test fails, the script will stop,
   and then you can inspect <tt>jos.out</tt> to see what the
   kernel actually printed.
</p>
<h2>Part B: Copy-on-Write Fork</h2>
<p>
   As mentioned earlier,
   Unix provides the <code>fork()</code> system call
   as its primary process creation primitive.
   The <code>fork()</code> system call
   copies the address space of the calling process (the parent)
   to create a new process (the child).
</p>
<p>
   xv6 Unix implements <code>fork()</code> by copying all data from the
   parent's pages into new pages allocated for the child.
   This is essentially the same approach
   that <code>dumbfork()</code> takes.
   The copying of the parent's address space into the child is
   the most expensive part of the <code>fork()</code> operation.
</p>
<p>
   However, a call to <code>fork()</code>
   is frequently followed almost immediately
   by a call to <code>exec()</code> in the child process,
   which replaces the child's memory with a new program.
   This is what the the shell typically does, for example.
   In this case,
   the time spent copying the parent's address space is largely wasted,
   because the child process will use
   very little of its memory before calling <code>exec()</code>.
</p>
<p>
   For this reason,
   later versions of Unix took advantage
   of virtual memory hardware
   to allow the parent and child to <i>share</i>
   the memory mapped into their respective address spaces
   until one of the processes actually modifies it.  
   This technique is known as <i>copy-on-write</i>.
   To do this,
   on <code>fork()</code> the kernel would
   copy the address space <i>mappings</i>
   from the parent to the child
   instead of the contents of the mapped pages,
   and at the same time mark the now-shared pages read-only.
   When one of the two processes tries to write to one of these shared pages,
   the process takes a page fault.
   At this point, the Unix kernel realizes that the page
   was really a "virtual" or "copy-on-write" copy,
   and so it makes a new, private, writable copy of the page for the
   faulting process.
   In this way, the contents of individual pages aren't actually copied
   until they are actually written to.
   This optimization makes a <code>fork()</code> followed by
   an <code>exec()</code> in the child much cheaper:
   the child will probably only need to copy one page
   (the current page of its stack)
   before it calls <code>exec()</code>.
</p>
<p>
   In the next piece of this lab, you will implement a "proper"
   Unix-like <code>fork()</code> with copy-on-write,
   as a user space library routine.
   Implementing <code>fork()</code> and copy-on-write support in user space
   has the benefit that the kernel remains much simpler
   and thus more likely to be correct.
   It also lets individual user-mode programs
   define their own semantics for <code>fork()</code>.
   A program that wants a slightly different implementation
   (for example, the expensive always-copy version like <code>dumbfork()</code>,
   or one in which the parent and child actually share memory afterward)
   can easily provide its own.
</p>
<h3>User-level page fault handling</h3>
<p>
   A user-level copy-on-write <code>fork()</code> needs to know about
   page faults on write-protected pages, so that's what you'll
   implement first.
   Copy-on-write is only one of many possible uses
   for user-level page fault handling.
</p>
<p>
   It's common to set up an address space so that page faults
   indicate when some action needs to take place.
   For example,
   most Unix kernels initially map only a single page
   in a new process's stack region,
   and allocate and map additional stack pages later "on demand"
   as the process's stack consumption increases
   and causes page faults on stack addresses that are not yet mapped.
   A typical Unix kernel must keep track of what action to take
   when a page fault occurs in each region of a process's space.
   For example,
   a fault in the stack region will typically
   allocate and map new page of physical memory.
   A fault in the program's BSS region will typically
   allocate  a new page, fill it with zeroes, and map it.
   In systems with demand-paged executables,
   a fault in the text region will read the corresponding page
   of the binary off of disk and then map it.
</p>
<p>
   This is a lot of information for the kernel to keep track of.
   Instead of taking the traditional Unix approach,
   you will decide what to do about each page fault in user space,
   where bugs are less damaging.
   This design has the added benefit of allowing 
   programs great flexibility in defining their memory regions;
   you'll use user-level page fault handling later
   for mapping and accessing files on a disk-based file system.
</p>
<h4>Setting the Page Fault Handler</h4>
<p>
   In order to handle its own page faults,
   a user environment will need to register
   a <i>page fault handler entrypoint</i> with the JOS kernel.
   The user environment registers its page fault entrypoint
   via the new <code>sys_env_set_pgfault_upcall</code> system call.
   We have added a new member to the <code>Env</code> structure,
   <code>env_pgfault_upcall</code>,
   to record this information.
</p>
<div class="required">
   <p><span class="header">Exercise 8.</span>
      Implement the <code>sys_env_set_pgfault_upcall</code> system call.
      Be sure to enable permission checking
      when looking up the environment ID of the target environment,
      since this is a "dangerous" system call.
   </p>
</div>
<h4>Normal and Exception Stacks in User Environments</h4>
<p>
   During normal execution,
   a user environment in JOS
   will run on the <i>normal</i> user stack:
   its <tt>ESP</tt> register starts out pointing at <code>USTACKTOP</code>,
   and the stack data it pushes resides on the page
   between <code>USTACKTOP-PGSIZE</code> and <code>USTACKTOP-1</code> inclusive.
   When a page fault occurs in user mode,
   however,
   the kernel will restart the user environment
   running a designated user-level page fault handler
   on a different stack,
   namely the <i>user exception</i> stack.
   In essence, we will make the JOS kernel
   implement automatic "stack switching"
   on behalf of the user environment,
   in much the same way that the x86 <i>processor</i>
   already implements stack switching on behalf of JOS
   when transferring from user mode to kernel mode!
</p>
<p>
   The JOS user exception stack is also one page in size,
   and its top is defined to be at virtual address <code>UXSTACKTOP</code>,
   so the valid bytes of the user exception stack
   are from <code>UXSTACKTOP-PGSIZE</code> through <code>UXSTACKTOP-1</code> inclusive.
   While running on this exception stack,
   the user-level page fault handler
   can use JOS's regular system calls to map new pages or adjust mappings
   so as to fix whatever problem originally caused the page fault.
   Then the user-level page fault handler returns,
   via an assembly language stub,
   to the faulting code on the original stack. 
</p>
<p>
   Each user environment that wants to support user-level page fault handling
   will need to allocate memory for its own exception stack,
   using the <code>sys_page_alloc()</code> system call introduced in part A.
</p>
<h4>Invoking the User Page Fault Handler</h4>
<p>
   You will now need to
   change the page fault handling code in <tt>kern/trap.c</tt>
   to handle page faults from user mode as follows.
   We will call the state of the user environment at the time of the 
   fault the <i>trap-time</i> state.  
</p>
<p>
   If there is no page fault handler registered,
   the JOS kernel destroys the user environment with a message as before.
   Otherwise,
   the kernel sets up a trap frame on the exception stack that looks like
   a <code>struct UTrapframe</code> from <tt>inc/trap.h</tt>:
</p>
<pre>
                    &lt;-- UXSTACKTOP
trap-time esp
trap-time eflags
trap-time eip
trap-time eax       start of struct PushRegs
trap-time ecx
trap-time edx
trap-time ebx
trap-time esp
trap-time ebp
trap-time esi
trap-time edi       end of struct PushRegs
tf_err (error code)
fault_va            &lt;-- %esp when handler is run
</pre>
<p>
   The kernel then arranges for the user environment to resume execution
   with the page fault handler
   running on the exception stack with this stack frame;
   you must figure out how to make this happen.
   The <tt>fault_va</tt> is the virtual address
   that caused the page fault.
</p>
<p>
   If the user environment is <i>already</i> running on the user exception stack
   when an exception occurs,
   then the page fault handler itself has faulted.
   In this case,
   you should start the new stack frame just under the current
   <code>tf->tf_esp</code> rather than at <code>UXSTACKTOP</code>.
   You should first push an empty 32-bit word, then a <code>struct UTrapframe</code>.
</p>
<p>
   To test whether <code>tf->tf_esp</code> is already on the user
   exception stack, check whether it is in the range
   between <code>UXSTACKTOP-PGSIZE</code> and <code>UXSTACKTOP-1</code>, inclusive.
</p>
<div class="required">
   <p><span class="header">Exercise 9.</span>
      Implement the code in <code>page_fault_handler</code> in
      <tt>kern/trap.c</tt>
      required to dispatch page faults to the user-mode handler.
      Be sure to take appropriate precautions
      when writing into the exception stack.
      (What happens if the user environment runs out of space
      on the exception stack?)
   </p>
</div>
<h4>User-mode Page Fault Entrypoint</h4>
<p>
   Next, you need to implement the assembly routine that will
   take care of calling the C page fault handler and resume
   execution at the original faulting instruction.
   This assembly routine is the handler that will be registered
   with the kernel using <code>sys_env_set_pgfault_upcall()</code>.
</p>
<div class="required">
   <p><span class="header">Exercise 10.</span>
      Implement the <code>_pgfault_upcall</code> routine
      in <tt>lib/pfentry.S</tt>.
      The interesting part is returning to the original point in
      the user code that caused the page fault.
      You'll return directly there, without going back through
      the kernel.
      The hard part is simultaneously switching stacks and
      re-loading the EIP.
   </p>
</div>
<p>
   Finally, you need to implement the C user library side
   of the user-level page fault handling mechanism.
</p>
<div class="required">
   <p><span class="header">Exercise 11.</span>
      Finish <code>set_pgfault_handler()</code>
      in <tt>lib/pgfault.c</tt>.
   </p>
</div>
<h4>Testing</h4>
<p>
   Run <tt>user/faultread</tt> (<kbd>make run-faultread</kbd>).  You should see:
</p>
<pre>
...
[00000000] new env 00001000
[00001000] user fault va 00000000 ip 0080003a
TRAP frame ...
[00001000] free env 00001000
</pre>
<p>
   Run <tt>user/faultdie</tt>.  You should see:
</p>
<pre>
...
[00000000] new env 00001000
i faulted at va deadbeef, err 6
[00001000] exiting gracefully
[00001000] free env 00001000
</pre>
<p>
   Run <tt>user/faultalloc</tt>.  You should see:
</p>
<pre>
...
[00000000] new env 00001000
fault deadbeef
this string was faulted in at deadbeef
fault cafebffe
fault cafec000
this string was faulted in at cafebffe
[00001000] exiting gracefully
[00001000] free env 00001000
</pre>
<p>
   If you see only the first "this string" line,
   it means you are not handling
   recursive page faults properly.
</p>
<p>
   Run <tt>user/faultallocbad</tt>.  You should see:
</p>
<pre>
...
[00000000] new env 00001000
[00001000] user_mem_check assertion failure for va deadbeef
[00001000] free env 00001000
</pre>
<p>
   Make sure you understand why <tt>user/faultalloc</tt> and
   <tt>user/faultallocbad</tt> behave differently.
</p>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Extend your kernel so that not only page faults,
      but <i>all</i> types of processor exceptions
      that code running in user space can generate,
      can be redirected to a user-mode exception handler.
      Write user-mode test programs
      to test user-mode handling of various exceptions
      such as divide-by-zero, general protection fault,
      and illegal opcode.
   </p>
</div>
<h3>Implementing Copy-on-Write Fork</h3>
<p>
   You now have the kernel facilities
   to implement copy-on-write <code>fork()</code>
   entirely in user space.
</p>
<p>
   We have provided a skeleton for your <code>fork()</code>
   in <tt>lib/fork.c</tt>.
   Like <code>dumbfork()</code>,
   <code>fork()</code> should create a new environment,
   then scan through the parent environment's entire address space
   and set up corresponding page mappings in the child.
   The key difference is that,
   while <code>dumbfork()</code> copied <i>pages</i>,
   <code>fork()</code> will initially only copy page <i>mappings</i>.
   <code>fork()</code> will
   copy each page only when one of the environments tries to write it.
</p>
<p>
   The basic control flow for <code>fork()</code> is as follows:
</p>
<ol>
   <li>	The parent installs <code>pgfault()</code>
      as the C-level page fault handler,
      using the <code>set_pgfault_handler()</code> function
      you implemented above.
   </li>
   <li>	The parent calls <code>sys_exofork()</code> to create
      a child environment.
   </li>
   <li>
      For each writable or copy-on-write page in its address space below UTOP,
      the parent calls <code>duppage</code>, which should
      map the page copy-on-write into the address
      space of the child and then <i>remap</i> the page copy-on-write
      in its own address space. [ Note: The ordering here (i.e., marking a page
      as COW in the child before marking it in the parent) actually matters!
      Can you see why? Try to think of a specific case where reversing the
      order could cause trouble. ] <code>duppage</code> sets both PTEs so that
      the page is not writeable, and to contain <code>PTE_COW</code> in the
      "avail" field to distinguish copy-on-write pages from genuine
      read-only pages.
      <p>
         The exception stack is <i>not</i> remapped this way, however.
         Instead you need to allocate a fresh page in the child for
         the exception stack.  Since the page fault handler will be 
         doing the actual copying and the page fault handler runs
         on the exception stack, the exception stack cannot be made
         copy-on-write: who would copy it?
      </p>
      <p><code>fork()</code> also needs to handle pages that are
         present, but not writable or copy-on-write.
      </p>
   </li>
   <li>	The parent sets the user page fault entrypoint for the child
      to look like its own.
   </li>
   <li>	The child is now ready to run, so the parent marks it runnable.</li>
</ol>
<p>
   Each time one of the environments writes a copy-on-write page that it
   hasn't yet written, it will take a page fault.
   Here's the control flow for the user page fault handler:
</p>
<ol>
   <li>	The kernel propagates the page fault to <code>_pgfault_upcall</code>,
      which calls <code>fork()</code>'s <code>pgfault()</code> handler.
   </li>
   <li>	<code>pgfault()</code> checks that the fault is a write
      (check for <code>FEC_WR</code> in the error code) and that the
      PTE for the page is marked <code>PTE_COW</code>.
      If not, panic.
   </li>
   <li>	<code>pgfault()</code> allocates a new page mapped
      at a temporary location and copies
      the contents of the faulting page into it.
      Then the fault handler maps the new page at the
      appropriate address with read/write permissions,
      in place of the old read-only mapping.
   </li>
</ol>
<p>The user-level <tt>lib/fork.c</tt> code must consult the environment's page
   tables for several of the operations above (e.g., that the PTE for a page is
   marked <code>PTE_COW</code>).  The kernel maps the environment's page tables at
   <code>UVPT</code> exactly for this purpose.  It uses a <a
      href="uvpt.html">clever mapping trick</a> to make it to make it easy to lookup
   PTEs for user code. <tt>lib/entry.S</tt> sets up <code>uvpt</code> and
   <code>uvpd</code> so that you can easily lookup page-table information in
   <tt>lib/fork.c</tt>.
<div class="required">
   <p><span class="header">Exercise 12.</span>
      Implement <code>fork</code>, <code>duppage</code> and
      <code>pgfault</code> in <tt>lib/fork.c</tt>.
   </p>
   <p>
      Test your code with the <tt>forktree</tt> program.
      It should produce the following messages,
      with interspersed 'new env', 'free env',
      and 'exiting gracefully' messages.
      The messages may not appear in this order, and the
      environment IDs may be different.
   </p>
   <pre>
	1000: I am ''
	1001: I am '0'
	2000: I am '00'
	2001: I am '000'
	1002: I am '1'
	3000: I am '11'
	3001: I am '10'
	4000: I am '100'
	1003: I am '01'
	5000: I am '010'
	4001: I am '011'
	2002: I am '110'
	1004: I am '001'
	1005: I am '111'
	1006: I am '101'
	</pre>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Implement a shared-memory <code>fork()</code>
      called <code>sfork()</code>.  This version should have the parent
      and child <i>share</i> all their memory pages
      (so writes in one environment appear in the other)
      except for pages in the stack area,
      which should be treated in the usual copy-on-write manner.
      Modify <tt>user/forktree.c</tt>
      to use <code>sfork()</code> instead of regular <code>fork()</code>.
      Also, once you have finished implementing IPC in part C,
      use your <code>sfork()</code> to run <tt>user/pingpongs</tt>.
      You will have to find a new way to provide the functionality
      of the global <code>thisenv</code> pointer.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Your implementation of <code>fork</code> 
      makes a huge number of system calls.  On the x86, switching into
      the kernel using interrupts has non-trivial cost.  Augment the
      system call interface
      so that it is possible to send a batch of system calls at once.
      Then change <code>fork</code> to use this interface.
   </p>
   <p>How much faster is your new <code>fork</code>?</p>
   <p>You can answer this (roughly) by using analytical
      arguments to estimate how much of an improvement batching
      system calls will make to the performance of your
      <code>fork</code>: How expensive is an <code>int 0x30</code>
      instruction? How many times do you execute <code>int 0x30</code>
      in your <code>fork</code>? Is accessing the <tt>TSS</tt> stack
      switch also expensive? And so on...
   </p>
   <p>Alternatively, you can boot your kernel on real hardware
      and <i>really</i> benchmark your code. See the <code>RDTSC</code>
      (read time-stamp counter) instruction, defined in the IA32
      manual, which counts the number of clock cycles that have
      elapsed since the last processor reset. QEMU doesn't emulate
      this instruction faithfully (it can either count the number of
      virtual instructions executed or use the host TSC, neither of
      which reflects the number of cycles a real CPU would
      require).
   </p>
</div>
<p>
   This ends part B.  Make sure you pass all of the Part B tests when you run
   <kbd>make grade</kbd>.
   As usual, you can hand in your submission
   with <kbd>make handin</kbd>.
</p>
<h2>Part C: Preemptive Multitasking and Inter-Process communication (IPC)</h2>
<p>
   In the final part of lab 4
   you will modify the kernel to preempt uncooperative environments
   and to allow environments to pass messages to each other explicitly.
</p>
<h3>Clock Interrupts and Preemption</h3>
<p>
   Run the <tt>user/spin</tt> test program.
   This test program forks off a child environment,
   which simply spins forever in a tight loop
   once it receives control of the CPU.
   Neither the parent environment nor the kernel ever regains the CPU.
   This is obviously not an ideal situation
   in terms of protecting the system from bugs or malicious code
   in user-mode environments,
   because any user-mode environment can bring the whole system to a halt
   simply by getting into an infinite loop and never giving back the CPU.
   In order to allow the kernel to <i>preempt</i> a running environment,
   forcefully retaking control of the CPU from it,
   we must extend the JOS kernel to support external hardware interrupts
   from the clock hardware.
</p>
<h4>Interrupt discipline</h4>
<p>
   External interrupts (i.e., device interrupts) are referred to as IRQs.
   There are 16 possible IRQs, numbered 0 through 15.
   The mapping from IRQ number to IDT entry is not fixed.
   <code>pic_init</code> in <tt>picirq.c</tt> maps IRQs 0-15
   to IDT entries <code>IRQ_OFFSET</code> through <code>IRQ_OFFSET+15</code>.
</p>
<p>
   In <tt>inc/trap.h</tt>,
   <code>IRQ_OFFSET</code> is defined to be decimal 32.
   Thus the IDT entries 32-47 correspond to the IRQs 0-15.
   For example, the clock interrupt is IRQ 0.
   Thus, IDT[IRQ_OFFSET+0] (i.e., IDT[32]) contains the address of
   the clock's interrupt handler routine in the kernel.
   This <code>IRQ_OFFSET</code> is chosen so that the device interrupts
   do not overlap with the processor exceptions,
   which could obviously cause confusion.
   (In fact, in the early days of PCs running MS-DOS,
   the <code>IRQ_OFFSET</code> effectively <i>was</i> zero,
   which indeed caused massive confusion between handling hardware interrupts
   and handling processor exceptions!)
</p>
<p>
   In JOS, we make a key simplification compared to xv6 Unix.
   External device interrupts are <i>always</i> disabled
   when in the kernel (and, like xv6, enabled when in user space).
   External interrupts are controlled by the <code>FL_IF</code> flag bit
   of the <code>%eflags</code> register
   (see <tt>inc/mmu.h</tt>).
   When this bit is set, external interrupts are enabled.
   While the bit can be modified in several ways,
   because of our simplification, we will handle it solely
   through the process of saving and restoring <code>%eflags</code> register
   as we enter and leave user mode.
</p>
<p>
   You will have to ensure that the <code>FL_IF</code> flag is set in
   user environments when they run so that when an interrupt arrives, it
   gets passed through to the processor and handled by your interrupt code.
   Otherwise, interrupts are <i>masked</i>,
   or ignored until interrupts are re-enabled.
   We masked interrupts with the very first instruction of the bootloader,
   and so far we have never gotten around to re-enabling them.
</p>
<div class="required">
   <p><span class="header">Exercise 13.</span>
      Modify <tt>kern/trapentry.S</tt> and <tt>kern/trap.c</tt> to
      initialize the appropriate entries in the IDT and provide
      handlers for IRQs 0 through 15.  Then modify the code
      in <code>env_alloc()</code> in <tt>kern/env.c</tt> to ensure
      that user environments are always run with interrupts enabled.
   </p>
   <p>
      Also uncomment the <tt>sti</tt> instruction in <tt>sched_halt()</tt> so
      that idle CPUs unmask interrupts.
   </p>
   <p>
      The processor never pushes an error code
      when invoking a hardware interrupt handler.
      You might want to re-read section 9.2 of the
      <a href="../../readings/i386/toc.htm">
      80386 Reference Manual</a>,
      or section 5.8 of the
      <a href="../../readings/ia32/IA32-3A.pdf">
      IA-32 Intel Architecture Software Developer's Manual, Volume 3</a>,
      at this time.
   </p>
   <p>
      After doing this exercise,
      if you run your kernel with any test program
      that runs for a non-trivial length of time
      (e.g., <tt>spin</tt>),
      you should see the kernel print trap frames for hardware
      interrupts.  While interrupts are now enabled in the
      processor, JOS isn't yet handling them, so you should see it
      misattribute each interrupt to the currently running user
      environment and destroy it.  Eventually it should run out of
      environments to destroy and drop into the monitor.
   </p>
</div>
<h4>Handling Clock Interrupts</h4>
<p>
   In the <tt>user/spin</tt> program,
   after the child environment was first run,
   it just spun in a loop,
   and the kernel never got control back.
   We need to program the hardware to generate clock interrupts periodically,
   which will force control back to the kernel
   where we can switch control to a different user environment.
</p>
<p>
   The calls to <code>lapic_init</code> and <code>pic_init</code>
   (from <code>i386_init</code> in <tt>init.c</tt>),
   which we have written for you,
   set up the clock and the interrupt controller to generate interrupts.
   You now need to write the code to handle these interrupts.
</p>
<div class="required">
   <p><span class="header">Exercise 14.</span>
      Modify the kernel's <code>trap_dispatch()</code> function
      so that it calls <code>sched_yield()</code>
      to find and run a different environment
      whenever a clock interrupt takes place.
   </p>
   <p>
      You should now be able to get the <tt>user/spin</tt> test to work:
      the parent environment should fork off the child,
      <code>sys_yield()</code> to it a couple times
      but in each case regain control of the CPU after one time slice,
      and finally kill the child environment and terminate gracefully.
   </p>
</div>
<!-- (Austin) I don't think QEMU keeps an instruction count
   <p>
   Make sure you can answer the following questions:
   </p>
   
   <ol>
   <li> How many instruction of user code are executed between each
   interrupt?</li>
   
   <li> How many instructions of kernel code are executed to handle the
   interrupt?
   <br />
   Hint: use the <kbd>vb</kbd> command mentioned earlier.</li>
   </ol>
   -->
<p>
   This is a great time to do some <i>regression testing</i>.  Make sure that you
   haven't broken any earlier part of that lab that used to work (e.g.
   <tt>forktree</tt>) by enabling interrupts.  Also, try running with
   multiple CPUs using <kbd>make CPUS=2 <i>target</i></kbd>.  You should
   also be able to
   pass <tt>stresssched</tt> now.  Run <kbd>make grade</kbd> to see
   for sure. You should now get a total score of 65/80 points on this lab.
</p>
<h3>Inter-Process communication (IPC)</h3>
<p>
   (Technically in JOS this is "inter-environment communication" or "IEC",
   but everyone else calls it IPC, so we'll use the standard
   term.)
</p>
<p>
   We've been focusing on the isolation aspects of the operating
   system, the ways it provides the illusion that each program
   has a machine all to itself.  Another important service of
   an operating system is to allow programs to communicate
   with each other when they want to.  It can be quite powerful
   to let programs interact with other programs.  The Unix
   pipe model is the canonical example.
</p>
<p>
   There are many models for interprocess communication. Even
   today there are still debates about which models are best.
   We won't get into that debate.
   Instead, we'll implement a simple IPC mechanism and then try it out.
</p>
<h4>IPC in JOS</h4>
<p>
   You will implement a few additional JOS kernel system calls
   that collectively provide a simple interprocess communication mechanism.
   You will implement two
   system calls, <code>sys_ipc_recv</code> and
   <code>sys_ipc_try_send</code>.
   Then you will implement two library wrappers
   <code>ipc_recv</code> and <code>ipc_send</code>.
</p>
<p>
   The "messages" that user environments can send to each other
   using JOS's IPC mechanism
   consist of two components:
   a single 32-bit value,
   and optionally a single page mapping.
   Allowing environments to pass page mappings in messages
   provides an efficient way to transfer more data
   than will fit into a single 32-bit integer,
   and also allows environments to set up shared memory arrangements easily.
</p>
<h4>Sending and Receiving Messages</h4>
<p>
   To receive a message, an environment calls
   <code>sys_ipc_recv</code>.
   This system call de-schedules the current
   environment and does not run it again until a message has
   been received.
   When an environment is waiting to receive a message,
   <i>any</i> other environment can send it a message -
   not just a particular environment,
   and not just environments that have a parent/child arrangement
   with the receiving environment.
   In other words, the permission checking that you implemented in Part A
   will not apply to IPC,
   because the IPC system calls are carefully designed so as to be "safe":
   an environment cannot cause another environment to malfunction
   simply by sending it messages
   (unless the target environment is also buggy).
</p>
<p>
   To try to send a value, an environment calls
   <code>sys_ipc_try_send</code> with both the receiver's
   environment id and the value to be sent.  If the named
   environment is actually receiving (it has called
   <code>sys_ipc_recv</code> and not gotten a value yet),
   then the send delivers the message and returns 0.  Otherwise
   the send returns <code>-E_IPC_NOT_RECV</code> to indicate
   that the target environment is not currently expecting
   to receive a value.
</p>
<p>
   A library function <code>ipc_recv</code> in user space will take care
   of calling <code>sys_ipc_recv</code> and then looking up
   the information about the received values in the current
   environment's <code>struct Env</code>.
</p>
<p>
   Similarly, a library function <code>ipc_send</code> will
   take care of repeatedly calling <code>sys_ipc_try_send</code>
   until the send succeeds.
</p>
<h4>Transferring Pages</h4>
<p>
   When an environment calls <code>sys_ipc_recv</code>
   with a valid <code>dstva</code> parameter (below <code>UTOP</code>),
   the environment is stating that it is willing to receive a page mapping.
   If the sender sends a page,
   then that page should be mapped at <code>dstva</code>
   in the receiver's address space.
   If the receiver already had a page mapped at <code>dstva</code>,
   then that previous page is unmapped.
</p>
<p>
   When an environment calls <code>sys_ipc_try_send</code>
   with a valid <code>srcva</code> (below <code>UTOP</code>),
   it means the sender wants to send the page
   currently mapped at <code>srcva</code> to the receiver,
   with permissions <code>perm</code>.
   After a successful IPC,
   the sender keeps its original mapping
   for the page at <code>srcva</code> in its address space,
   but the receiver also obtains a mapping for this same physical page
   at the <code>dstva</code> originally specified by the receiver,
   in the receiver's address space.
   As a result this page becomes shared between the sender and receiver.
</p>
<p>
   If either the sender or the receiver does not indicate
   that a page should be transferred,
   then no page is transferred.
   After any IPC
   the kernel sets the new field <code>env_ipc_perm</code>
   in the receiver's <code>Env</code> structure
   to the permissions of the page received,
   or zero if no page was received.
</p>
<h4>Implementing IPC</h4>
<div class="required">
   <p><span class="header">Exercise 15.</span>
      Implement <code>sys_ipc_recv</code> and
      <code>sys_ipc_try_send</code> in <tt>kern/syscall.c</tt>.
      Read the comments on both before implementing them, since they
      have to work together.
      When you call <code>envid2env</code> in these routines, you should
      set the <code>checkperm</code> flag to 0,
      meaning that any environment is allowed to send
      IPC messages to any other environment,
      and the kernel does no special permission checking
      other than verifying that the target envid is valid.
   </p>
   <p>Then implement
      the <code>ipc_recv</code> and <code>ipc_send</code> functions
      in <tt>lib/ipc.c</tt>.
   </p>
   <p>
      Use the <tt>user/pingpong</tt> and <tt>user/primes</tt>
      functions to test your IPC mechanism.  <tt>user/primes</tt>
      will generate for each prime number a new environment until
      JOS runs out of environments.  You might find it interesting
      to read <tt>user/primes.c</tt> to see all the forking and IPC
      going on behind the scenes.
   </p>
</div>
<!--
   <div class="challenge">
   <p><span class="header">Challenge!</span>
   	The <code>ipc_send</code> function is not very fair.
   	Run three copies of <tt>user/fairness</tt> and you will
   	see this problem.  The first two copies are both trying to send to 
   	the third copy, but only one of them will ever succeed.
   	Make the IPC fair, so that each copy has approximately
   	equal chance of succeeding.
   </p></div>
   -->
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Why does <code>ipc_send</code>
      have to loop?  Change the system call interface so it
      doesn't have to.  Make sure you can handle multiple
      environments trying to send to one environment at the
      same time.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      The prime sieve is only one neat use of
      message passing between a large number of concurrent programs.
      Read C. A. R. Hoare, ``Communicating Sequential Processes,''
      <i>Communications of the ACM</i> 21(8) (August 1978), 666-667,
      and implement the matrix multiplication example.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      One of the most impressive examples of
      the power of message passing is Doug McIlroy's power series
      calculator, described in 
      <a href="https://swtch.com/~rsc/thread/squint.pdf"
         >M. Douglas McIlroy, ``Squinting at 
      Power Series,'' <i>Software--Practice and Experience</i>, 20(7)
      (July 1990), 661-683</a>.  Implement his
      power series calculator and compute the power series for 
      <i>sin</i>(<i>x</i>+<i>x</i>^3).
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span>
      Make JOS's IPC mechanism more efficient
      by applying some of the techniques from Liedtke's paper,
      <a href="http://dl.acm.org/citation.cfm?id=168633">Improving IPC by Kernel Design</a>,
      or any other tricks you may think of.
      Feel free to modify the kernel's system call API for this purpose,
      as long as your code is backwards compatible
      with what our grading scripts expect.
   </p>
</div>
<!-- (Austin) L4 isn't on the 2009 schedule
   <div class="challenge">
   <p><span class="header">Challenge!</span>
   	Generalize the JOS IPC interface so it is more like L4's,
   	supporting more complex message formats.
   </p></div>
   -->
<!-- Challenge problems: other IPC, matrix multiply, power
   series -->
<p>
   <b>This ends part C.</b>
   Make sure you pass all of the <kbd>make grade</kbd> tests and
   don't forget to write up your answers to the questions and a
   description of your challenge exercise solution in
   <tt>answers-lab4.txt</tt>.
</p>
<p>
   Before handing in, use <kbd>git status</kbd> and <kbd>git diff</kbd>
   to examine your changes and don't forget to <kbd>git add
   answers-lab4.txt</kbd>.  When you're ready, commit your changes with
   <kbd>git commit -am 'my solutions to lab 4'</kbd>, then <kbd>make
   handin</kbd> and follow the directions.
</p>