<h2>Introduction</h2>
<p>
   In this lab you will implement the basic kernel facilities
   required to get a protected user-mode environment (i.e., "process") running.
   You will enhance the JOS kernel
   to set up the data structures to keep track of user environments,
   create a single user environment,
   load a program image into it,
   and start it running.
   You will also make the JOS kernel capable
   of handling any system calls the user environment makes
   and handling any other exceptions it causes.
</p>
<p>
   <b>Note:</b>
   In this lab, the terms <i>environment</i> and <i>process</i> are
   interchangeable - they have roughly the same meaning.  We introduce the
   term "environment" instead of the traditional term "process"
   in order to stress the point that JOS environments do not provide
   the same semantics as UNIX processes,
   even though they are roughly comparable.
</p>
<h3>Getting Started</h3>
<p>
   Use Git to commit your Lab 2 source,
   fetch the latest version of the course repository,
   and then
   create a local branch called <tt>lab3</tt> based on our lab3
   branch, <tt>origin/lab3</tt>:
</p>
<pre>
kermit% <kbd>cd lab</kbd>
kermit% <kbd>git commit -am 'my solution to lab2'</kbd>
Created commit 734fab7: my solution to lab2
 4 files changed, 42 insertions(+), 9 deletions(-)
kermit% <kbd>git pull</kbd>

Already up-to-date.
kermit% <kbd>git checkout -b lab3 origin/lab3</kbd>
Branch lab3 set up to track remote branch refs/remotes/origin/lab3.
Switched to a new branch "lab3"
kermit% <kbd>git merge lab2</kbd>
Merge made by recursive.
 kern/pmap.c |   42 +++++++++++++++++++
 1 files changed, 42 insertions(+), 0 deletions(-)
kermit% 
</pre>
<p>
   Lab 3 contains a number of new source files,
   which you should browse:
</p>
<table class="labfig"  style="margin: auto;">
   <tr>
      <td>	<tt>inc/</tt></td>
      <td>	<tt>env.h</tt></td>
      <td>	Public definitions for user-mode environments</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>trap.h</tt></td>
      <td>	Public definitions for trap handling</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>syscall.h</tt></td>
      <td>	Public definitions for system calls
         from user environments to the kernel
      </td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>lib.h</tt></td>
      <td>	Public definitions for the user-mode support library</td>
   </tr>
   <tr>
      <td>	<tt>kern/</tt></td>
      <td>	<tt>env.h</tt></td>
      <td>	Kernel-private definitions for user-mode environments</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>env.c</tt></td>
      <td>	Kernel code implementing user-mode environments</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>trap.h</tt></td>
      <td>	Kernel-private trap handling definitions</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>trap.c</tt></td>
      <td>	Trap handling code</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>trapentry.S</tt></td>
      <td>	Assembly-language trap handler entry-points</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>syscall.h</tt></td>
      <td>	Kernel-private definitions for system call handling</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>syscall.c</tt></td>
      <td>	System call implementation code</td>
   </tr>
   <tr>
      <td>	<tt>lib/</tt></td>
      <td>	<tt>Makefrag</tt></td>
      <td>	Makefile fragment to build user-mode library,
         <tt>obj/lib/libuser.a</tt>
      </td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>entry.S</tt></td>
      <td>	Assembly-language entry-point for user environments</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>libmain.c</tt></td>
      <td>	User-mode library setup code called from <tt>entry.S</tt></td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>syscall.c</tt></td>
      <td>	User-mode system call stub functions</td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>console.c</tt></td>
      <td>	User-mode implementations of
         <tt>putchar</tt> and <tt>getchar</tt>,
         providing console I/O
      </td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>exit.c</tt></td>
      <td>	User-mode implementation of <tt>exit</tt></td>
   </tr>
   <tr>
      <td></td>
      <td>	<tt>panic.c</tt></td>
      <td>	User-mode implementation of <tt>panic</tt></td>
   </tr>
   <tr>
      <td>	<tt>user/</tt></td>
      <td>	<tt>*</tt></td>
      <td>	Various test programs to check kernel lab 3 code</td>
   </tr>
</table>
<p>
   In addition, a number of the source files we handed out for lab2
   are modified in lab3.
   To see the differences, you can type:
</p>
<pre>
$ <kbd>git diff lab2 | more</kbd>
</pre>
<p>
   You may also want to take another look at the <a href="tools.html">lab tools guide</a>, as it includes information on debugging user code that becomes relevant in this lab. 
</p>
<h3>Lab Requirements</h3>
<p>
   This lab is divided into two parts, A and B. 
   We provide a deadline for Part A so that you can be sure you are on track
   to complete the entire lab on time.  The deadline for Part A will not be enforced, 
   only the deadline for the entire lab will be checked.
   <!--even though your code may not yet pass all of the grade script tests.
      (If it does, great!)
      You only need to have all the grade script tests passing
      by the Part B deadline.-->
</p>
<p>
   As in lab 2,
   you may do challenge problems for extra credit.
   If you do this, please create entires in the file called challenge3.txt, which includes 
   a short (e.g., one or two paragraph) description of what you did
   to solve your chosen challenge problem and how to test it.
   If you implement more than one challenge problem,
   you must describe each one.
   Be sure to list the challenge problem number.
   If you complete challenges from previous labs, please list them in this file (not a previous
   lab challenge file), with both the lab and problem number.
</p>
<p>
   Passing all the <kbd>make grade</kbd> tests
   does not mean your code is perfect.  It may have subtle bugs that will
   only be tickled by future labs.
   All your kernel code is running in the same address space with no protection.
   If you get weird crashes
   that don't seem to be explainable by a bug in the crashing code,
   it's likely that they're due to a bug somewhere else that is
   modifying memory used by the crashing code.
</p>
<h3>Inline Assembly</h3>
<p>
   In this lab you may find GCC's inline assembly language feature useful,
   although it is also possible to complete the lab without using it.
   At the very least, you will need to be able to understand
   the fragments of inline assembly language ("asm" statements)
   that already exist in the source code we gave you.
   You can find several sources of information
   on GCC inline assembly language
   on the class <a href="reference.html">reference materials</a> page.
</p>
<h2>Part A: User Environments and Exception Handling</h2>
<p>
   The new include file <tt>inc/env.h</tt>
   contains basic definitions for user environments in JOS;
   read it now.
   The kernel uses the <code>Env</code> data structure
   to keep track of each user environment.
   In this lab you will initially create just one environment,
   but you will need to design the JOS kernel
   to support multiple environments;
   lab 4 will take advantage of this feature
   by allowing a user environment to <code>fork</code> other environments.
</p>
<p>
   As you can see in <tt>kern/env.c</tt>,
   the kernel maintains three main global variables
   pertaining to environments:
</p>
<pre>
struct Env *envs = NULL;		/* All environments */
struct Env *curenv = NULL;	        /* the current env */
static struct Env_list env_free_list;	/* Free list */
</pre>
<p>
   Once JOS gets up and running,
   the <code>envs</code> pointer points to an array of <code>Env</code> structures
   representing all the environments in the system.
   In our design,
   the JOS kernel will support a maximum of <code>NENV</code>
   simultaneously active environments,
   although there will typically be far fewer running environments
   at any given time.
   (<code>NENV</code> is a constant <code>#define</code>'d in <tt>inc/env.h</tt>.)
   Once it is allocated,
   the <code>envs</code> array will contain
   a single instance of the <code>Env</code> data structure
   for each of the <code>NENV</code> possible environments.
</p>
<p>
   The JOS kernel keeps all of the inactive <code>Env</code> structures
   on the <code>env_free_list</code>.
   This design allows easy allocation and
   deallocation of environments,
   as they merely have to be added to or removed from the free list.
</p>
<p>
   The kernel uses the <code>curenv</code> variable
   to keep track of the <i>currently executing</i> environment at any given time.
   During boot up, before the first environment is run,
   <code>curenv</code> is initially set to <code>NULL</code>.
</p>
<h3>Environment State</h3>
<p>
   The <code>Env</code> structure
   is defined in <tt>inc/env.h</tt> as follows
   (although more fields will be added in future labs):
</p>
<pre>
struct Env {
	struct Trapframe env_tf;        // Saved register
	struct Env *env_link;		// Next free Env
	envid_t env_id;                 // Unique environment identifier
	envid_t env_parent_id;          // env_id of this env's parent
	enum EnvType env_type;		// Indicates special system environments
	unsigned env_status;            // Status of the environment
	uint32_t env_runs;              // Number of times environment has run
	// Address space
	pml4e_t *env_pml4e;               // Kernel virtual address of page map level-4
};
</pre>
<p>
   Here's what the <code>Env</code> fields are for:
</p>
<dl>
   <dt><b>env_tf</b>:</dt>
   <dd>	This structure, defined in <tt>inc/trap.h</tt>,
      holds the saved register values for the environment
      while that environment is <i>not</i> running:
      i.e., when the kernel or a different environment is running.
      The kernel saves these when
      switching from user to kernel mode,
      so that the environment can later be resumed where it left off.
   </dd>
   <dt><b>env_link</b>:</dt>
   <dd>	This is a link to the next <code>Env</code> on the
      <code>env_free_list</code>.  <code>env_free_list</code> points
      to the first free environment on the list.
   </dd>
   <dt><b>env_id</b>:</dt>
   <dd>	The kernel stores here a value
      that uniquely identifiers
      the environment currently using this <code>Env</code> structure
      (i.e., using this particular slot in the <code>envs</code> array).
      After a user environment terminates,
      the kernel may re-allocate
      the same <code>Env</code> structure to a different environment -
      but the new environment
      will have a different <code>env_id</code> from the old one
      even though the new environment
      is re-using the same slot in the <code>envs</code> array.
   </dd>
   <dt><b>env_parent_id</b>:</dt>
   <dd>	The kernel stores here the <code>env_id</code>
      of the environment that created this environment.
      In this way the environments can form a ``family tree,''
      which will be useful for making security decisions
      about which environments are allowed to do what to whom.
   </dd>
   <dt><b>env_type</b>:</dt>
   <dd>	This is used to distinguish special environments.  For most
      environments, it will be <code>ENV_TYPE_USER</code>.  The idle
      environment is <code>ENV_TYPE_IDLE</code> and we'll introduce
      a few more special types for special system service
      environments in later labs.
   </dd>
   <dt><b>env_status</b>:</dt>
   <dd>
      This variable holds one of the following values:
      <dl>
         <dt><code>ENV_FREE</code>:</dt>
         <dd>	Indicates that the <code>Env</code> structure is inactive,
            and therefore on the <code>env_free_list</code>.
         </dd>
         <dt><code>ENV_RUNNABLE</code>:</dt>
         <dd>	Indicates that the <code>Env</code> structure
            represents a currently active environment,
            and the environment is waiting to run on the processor.
         </dd>
         <dt><code>ENV_RUNNING</code>:</dt>
         <dd>	Indicates that the <code>Env</code> structure
            represents the currently running environment.
         </dd>
         <dt><code>ENV_NOT_RUNNABLE</code>:</dt>
         <dd>	Indicates that the <code>Env</code> structure
            represents a currently active environment,
            but it is not currently ready to run:
            for example, because it is waiting
            for an interprocess communication (IPC)
            from another environment.
         </dd>
         <dt><code>ENV_DYING</code>:</dt>
         <dd>	Indicates that the <code>Env</code> structure
            represents a zombie environment. A zombie environment will be
            freed the next time it traps to the kernel. We will not use
            this flag until Lab 4.
         </dd>
      </dl>
   </dd>
   <dt><b>env_pml4e</b>:</dt>
   <dd>	This variable holds the kernel <i>virtual address</i> 
      of this environment's top-level (4th level) page directory.
   </dd>
</dl>
<p>
   Like a Unix process, a JOS environment couples the concepts of
   "thread" and "address space".  The thread is defined primarily by the
   saved registers (the <code>env_tf</code> field), and the address space
   is defined by the PML4,page directory pointer, page directory and page tables pointed to by
   <code>env_pml4e</code> and <code>env_cr3</code>.  To run an
   environment, the kernel must set up the CPU with <i>both</i> the saved
   registers and the appropriate address space.
</p>
<p>
   Note that in Unix-like systems, individual environments have their own
   kernel stacks. In JOS, however, only one environment can be active in
   the kernel at once, so JOS needs only a <i>single</i> kernel stack.
</p>
<!--Our <code>struct Env</code> is analogous to <code>struct proc</code>
   in xv6.  Both structures hold the environment's (i.e., process's)
   user-mode register state in a <code>Trapframe</code>
   structure.  In JOS,
   individual environments do not have their own kernel stacks as
   processes do in xv6.  There can be only JOS environment active in
   the kernel at a time, so JOS needs only a
   <i>single</i> kernel stack.
   </p>
   -->
<h3>Allocating the Environments Array</h3>
<p>
   In lab 2,
   you allocated memory in <code>x86_vm_init()</code>
   for the <code>pages[]</code> array,
   which is a table the kernel uses to keep track of
   which pages are free and which are not.
   You will now need to modify <code>x64_vm_init()</code> further
   to allocate a similar array of <code>Env</code> structures,
   called <code>envs</code>.
</p>
<div class="required">
   <p><span class="header">Exercise 1.</span>
      Modify <code>x64_vm_init()</code> in <tt>kern/pmap.c</tt>
      to allocate and map the <code>envs</code> array.
      This array consists of
      exactly <code>NENV</code> instances of the <code>Env</code>
      structure allocated much like how you allocated the
      <code>pages</code> array.
      Also like the <code>pages</code> array, the memory backing
      <code>envs</code> should also be mapped user read-only at
      <code>UENVS</code> (defined in <tt>inc/memlayout.h</tt>) so
      user processes can read from this array.
   </p>
   <p>
      You should run your code and make sure
      <code>check_boot_pml4e()</code> succeeds.
   </p>
</div>
<h3>Creating and Running Environments</h3>
<p>
   You will now write the code in <tt>kern/env.c</tt> necessary to run a
   user environment.  Because we do not yet have a filesystem, we will
   set up the kernel to load a static binary image that is <i>embedded
   within the kernel itself</i>. JOS embeds
   this binary in the kernel as a ELF executable image.
</p>
<p>
   The Lab 3 <tt>GNUmakefile</tt> generates a number of binary images in
   the <tt>obj/user/</tt> directory.  If you look at
   <tt>kern/Makefrag</tt>, you will notice some magic that "links" these
   binaries directly into the kernel executable as if they were
   <tt>.o</tt> files.  The <tt>-b binary</tt> option on the linker
   command line causes these files to be linked in as "raw" uninterpreted
   binary files rather than as regular <tt>.o</tt> files produced by the
   compiler.  (As far as the linker is concerned, these files do not have
   to be ELF images at all - they could be anything, such as text files
   or pictures!)  If you look at <tt>obj/kern/kernel.sym</tt> after
   building the kernel, you will notice that the linker has "magically"
   produced a number of funny symbols with obscure names like
   <tt>_binary_obj_user_hello_start</tt>,
   <tt>_binary_obj_user_hello_end</tt>, and
   <tt>_binary_obj_user_hello_size</tt>.  The linker generates these
   symbol names by mangling the file names of the binary files; the
   symbols provide the regular kernel code with a way to reference the
   embedded binary files.
</p>
<p>
   In <code>i386_init()</code> in <tt>kern/init.c</tt> you'll see code to run
   one of these binary images in an environment.  However, the critical
   functions to set up user environments are not complete; you will need
   to fill them in.
</p>
<div class="required">
   <p><span class="header">Exercise 2.</span>
      In the file <tt>env.c</tt>,
      finish coding the following functions:
   </p>
   <dl>
      <dt>	<code>env_init()</code>:</dt>
      <dd>	Initialize all of the <code>Env</code> structures
         in the <code>envs</code> array
         and add them to the <code>env_free_list</code>.
         Also calls <code>env_init_percpu</code>, which
         configures the segmentation hardware with
         separate segments for privilege level 0 (kernel) and
         privilege level 3 (user).
      </dd>
      <dt>	<code>env_setup_vm()</code>:</dt>
      <dd>	Allocate a page map level four (pml4e) for a new environment
         and initialize the kernel portion
         of the new environment's address space.
         Note that in the previous lab, we set up our memory mapping such that everything above UTOP is in the second entry of the PML4. Everything above UTOP needs to be mapped into every environment's virtual space. This involves simple copying of this entry form kernel's pml4 to the environment's pml4.
      </dd>
      <dt>	<code>region_alloc()</code>:</dt>
      <dd>	Allocates and maps physical memory for an environment</dd>
      <dt>	<code>load_icode()</code>:</dt>
      <dd>	You will need to parse an ELF binary image,
         much like the boot loader already does,
         and load its contents into the user address space
         of a new environment.
      </dd>
      <dt>	<code>env_create()</code>:</dt>
      <dd>	Allocate an environment with <code>env_alloc</code>
         and call <code>load_icode</code> load an ELF binary into it.
      </dd>
      <dt>	<code>env_run()</code>:</dt>
      <dd>	Start a given environment running in user mode.</dd>
   </dl>
   <p>
      As you write these functions,
      you might find the new cprintf verb <code>%e</code>
      useful -- it prints a description corresponding to an error code.
      For example,
   </p>
   <pre>
	r = -E_NO_MEM;
	panic("env_alloc: %e", r);
	</pre>
   <p>
      will panic with the message "env_alloc: out of memory".
   </p>
</div>
<p>
   Below is a call graph of the code up to the point where the user
   code is invoked. 
   Make sure you understand the purpose of each step.
</p>
<ul>
   <li> <code>start</code> (<code>kern/entry.S</code>)</li>
   <li>
      <code>i386_init</code>
      <ul>
         <li> <code>cons_init</code></li>
         <li> <code>x86_vm_init</code></li>
         <li> <code>env_init</code></li>
         <li> <code>trap_init</code> (still incomplete at this point)</li>
         <li> <code>env_create</code></li>
         <li>
            <code>env_run</code>
            <ul>
               <li> <code>env_pop_tf</code></li>
            </ul>
         </li>
      </ul>
   </li>
</ul>
<p>
   Once you are done you should compile your kernel and run it under QEMU.
   If all goes well, your system should enter user space and execute the
   <tt>hello</tt> binary until it makes a system call with the
   <code>int</code> instruction.  At that point there will be trouble, since
   JOS has not set up the hardware to allow any kind of transition
   from user space into the kernel.
   When the CPU discovers that it is not set up to handle this system
   call interrupt, it will generate a general protection exception, find
   that it can't handle that, generate a double fault exception, find
   that it can't handle that either, and finally give up, reset, and
   reboot in what's known as a "triple fault".  
   Usually, you would then see the CPU reset
   and the system reboot.  While this is important for legacy
   applications (see <a
      href="http://blogs.msdn.com/larryosterman/archive/2005/02/08/369243.aspx">
   this blog post</a> for an explanation of why), it's a pain for kernel
   development.
   <!--, so with the 506 patched QEMU you'll instead see a
      register dump and a "Triple fault." message. -->
</p>
<p>
   We'll address this problem shortly, but for now we can use the
   debugger to check that we're entering user mode.  Use <kbd>make
   qemu-gdb</kbd> (or <kbd>make qemu-nox-gdb</kbd>) and set a GDB breakpoint 
   at <code>env_pop_tf</code>,
   which should be the last function you hit before actually entering user mode.
   Single step through this function using <kbd>si</kbd>;
   the processor should enter user mode after the <code>iret</code> instruction.
   You should then see the first instruction
   in the user environment's executable,
   which is the <code>cmpl</code> instruction at the label <code>start</code>
   in <tt>lib/entry.S</tt>.
   Now use <kbd>b *0x...</kbd> to set a breakpoint at the
   <code>int&nbsp;$0x30</code> in <code>sys_cputs()</code> in <tt>hello</tt>
   (see <tt>obj/user/hello.asm</tt> for the user-space address).
   This <code>int</code> is the system call to display a character to
   the console.
   If you cannot execute as far as the <code>int</code>,
   then something is wrong with your address space setup
   or program loading code;
   go back and fix it before continuing.
</p>
<h3>Handling Interrupts and Exceptions</h3>
<p>
   At this point,
   the first <code>int&nbsp;$0x30</code> system call instruction in user space
   is a dead end:
   once the processor gets into user mode,
   there is no way to get back out.
   You will now need to implement
   basic exception and system call handling,
   so that it is possible for the kernel to recover control of the processor
   from user-mode code.
   The first thing you should do
   is thoroughly familiarize yourself with
   the x86 interrupt and exception mechanism.
</p>
<div class="required">
   <p><span class="header">Exercise 3.</span>
      Read
      <a href="ref/i386/c09.htm">
      Chapter 9, Exceptions and Interrupts</a>
      in the
      <a href="ref/i386/toc.htm">80386 Programmer's Manual</a>
      (or Chapter 5 of the <a href="ref/ia32/IA32-3A.pdf">
      IA-32 Developer's Manual</a>),
      if you haven't already.
   </p>
</div>
<p>
   In this lab we generally follow Intel's terminology
   for interrupts, exceptions, and the like.
   However,
   terms such as exception, trap, interrupt, fault and
   abort have no standard meaning
   across architectures or operating systems,
   and are often used without regard to the subtle distinctions between them
   on a particular architecture such as the x86.
   When you see these terms outside of this lab,
   the meanings might be slightly different.
</p>
<h3>Basics of Protected Control Transfer</h3>
<p>
   Exceptions and interrupts are both
   "protected control transfers,"
   which cause the processor to switch from user to kernel mode
   (CPL=0) without giving the user-mode code any opportunity
   to interfere with the functioning of the kernel or other environments.
   In Intel's terminology,
   an <i>interrupt</i> is a protected control transfer
   that is caused by an asynchronous event usually external to the processor,
   such as notification of external device I/O activity.
   An <i>exception</i>, in contrast,
   is a protected control transfer
   caused synchronously by the currently running code,
   for example due to a divide by zero or an invalid memory access.
</p>
<p>
   In order to ensure that these protected control transfers
   are actually <i>protected</i>,
   the processor's interrupt/exception mechanism is designed so that
   the code currently running when the interrupt or exception occurs
   <i>does not get to choose arbitrarily where the kernel is entered or how</i>.
   Instead,
   the processor ensures that the kernel can be entered
   only under carefully controlled conditions.
   On the x86, two mechanisms provide this protection:
</p>
<ol>
   <li>
      <p>	<b>The Interrupt Descriptor Table.</b>
         The processor ensures that interrupts and exceptions
         can only cause the kernel to be entered
         at a few specific, well-defined entry-points
         <i>determined by the kernel itself</i>,
         and not by the code running
         when the interrupt or exception is taken.
      </p>
      <p>
         The x86 allows up to 256 different
         interrupt or exception entry points into the kernel,
         each with a different <i>interrupt vector</i>.
         A vector is a number between 0 and 255.
         An interrupt's vector is determined by the
         source of the interrupt: different devices, error
         conditions, and application requests to the kernel
         generate interrupts with different vectors.
         The CPU uses the vector as an index
         into the processor's <i>interrupt descriptor table</i> (IDT),
         which the kernel sets up in kernel-private memory,
         much like the GDT.
         From the appropriate entry in this table
         the processor loads:
      </p>
      <ul>
         <li>	the value to load into
            the instruction pointer (<tt>RIP</tt>) register,
            pointing to the kernel code designated
            to handle that type of exception.
         </li>
         <li>	the value to load into
            the code segment (<tt>CS</tt>) register,
            which includes in bits 0-1 the privilege level
            at which the exception handler is to run.
            (In JOS, all exceptions are handled in kernel mode,
            privilege level 0.)
         </li>
      </ul>
   </li>
   <li>
      <p>	<b>The Task State Segment.</b>
         The processor needs a place
         to save the <i>old</i> processor state
         before the interrupt or exception occurred,
         such as the original values of <tt>RIP</tt> and <tt>CS</tt>
         before the processor invoked the exception handler,
         so that the exception handler can later restore that old state
         and resume the interrupted code from where it left off.
         But this save area for the old processor state
         must in turn be protected from unprivileged user-mode code;
         otherwise buggy or malicious user code
         could compromise the kernel.
      </p>
      <p>
         For this reason,
         when an x86 processor takes an interrupt or trap
         that causes a privilege level change from user to kernel mode,
         it also switches to a stack in the kernel's memory.
         A structure called the <i>task state segment</i> (TSS) specifies
         the segment selector and address where this stack lives.
         The processor pushes (on this new stack)
         <tt>SS</tt>, <tt>RSP</tt>, <tt>EFLAGS</tt>, <tt>CS</tt>, <tt>RIP</tt>, and an optional error code.
         Then it loads the <tt>CS</tt> and <tt>RIP</tt> from the interrupt descriptor,
         and sets the <tt>RSP</tt> and <tt>SS</tt> to refer to the new stack.
      </p>
      <p>
         Although the TSS is large
         and can potentially serve a variety of purposes,
         JOS only uses it to define
         the kernel stack that the processor should switch to
         when it transfers from user to kernel mode.
         Since "kernel mode" in JOS
         is privilege level 0 on the x86,
         the processor uses the <tt>RSP0</tt> and <tt>SS0</tt> fields of the TSS
         to define the kernel stack when entering kernel mode.
         JOS doesn't use any other TSS fields.
      </p>
   </li>
</ol>
<h3>Types of Exceptions and Interrupts</h3>
<p>
   All of the synchronous exceptions
   that the x86 processor can generate internally
   use interrupt vectors between 0 and 31,
   and therefore map to IDT entries 0-31.
   For example,
   a page fault always causes an exception through vector 14.
   Interrupt vectors greater than 31 are only used by
   <i>software interrupts</i>,
   which can be generated by the <code>int</code> instruction, or
   asynchronous <i>hardware interrupts</i>,
   caused by external devices when they need attention.
</p>
<p>
   In this section we will extend JOS to handle
   the internally generated x86 exceptions in vectors 0-31.
   In the next section we will make JOS handle
   software interrupt vector 48 (0x30),
   which JOS (fairly arbitrarily) uses as its system call interrupt vector.
   In Lab 4 we will extend JOS to handle externally generated hardware interrupts
   such as the clock interrupt.
</p>
<h3>An Example</h3>
<p>
   Let's put these pieces together and trace through an example.
   Let's say the processor is executing code in a user environment
   and encounters a divide instruction that attempts to divide by zero.
</p>
<ol>
   <li>	The processor switches to the stack defined by the
      <tt>SS0</tt> and <tt>RSP0</tt> fields of the TSS,
      which in JOS will hold the values
      <code>GD_KD</code> and <code>KSTACKTOP</code>, respectively.
   </li>
   <li>
      The processor pushes the exception parameters on the
      kernel stack, starting at address <code>KSTACKTOP</code>:
      <pre>
                     +--------------------+ KSTACKTOP     
                     | 0x00000 | old SS   |     " - 8
                     |      old RSP       |     " - 16
                     |     old EFLAGS     |     " - 24
                     | 0x00000 | old CS   |     " - 32
                     |      old RIP       |     " - 40 &lt;---- RSP 
                     +--------------------+             
	</pre>
   </li>
   <li>	Because we're handling a divide error,
      which is interrupt vector 0 on the x86,
      the processor reads IDT entry 0 and sets
      <tt>CS:RIP</tt> to point to the handler function defined there.
   </li>
   <li>	The handler function takes control and handles the exception,
      for example by terminating the user environment.
   </li>
</ol>
<p>
   For certain types of x86 exceptions,
   in addition to the "standard" five words above,
   the processor pushes onto the stack another word
   containing an <i>error code</i>.
   The page fault exception, number 14,
   is an important example.
   See the 80386 manual to determine for which exception numbers
   the processor pushes an error code,
   and what the error code means in that case.
   When the processor pushes an error code,
   the stack would look as follows at the beginning of the exception handler
   when coming in from user mode:
</p>
<pre>
                     +--------------------+ KSTACKTOP             
                     | 0x00000 | old SS   |     " - 8
                     |      old RSP       |     " - 16
                     |     old EFLAGS     |     " - 24
                     | 0x00000 | old CS   |     " - 32
                     |      old RIP       |     " - 40
                     |     error code     |     " - 48 &lt;---- RSP
                     +--------------------+             
	</pre>
<h3>Nested Exceptions and Interrupts</h3>
<p>
   The processor can take exceptions and interrupts
   both from kernel and user mode.
   It is only when entering the kernel from user mode, however,
   that the x86 processor automatically switches stacks
   before pushing its old register state onto the stack
   and invoking the appropriate exception handler through the IDT.
   If the processor is <i>already</i> in kernel mode
   when the interrupt or exception occurs
   (the low 2 bits of the <tt>CS</tt> register are already zero),
   then the kernel just pushes more values on the same kernel stack.
   In this way, the kernel can gracefully handle <i>nested exceptions</i>
   caused by code within the kernel itself.
   This capability is an important tool in implementing protection,
   as we will see later in the section on system calls.
</p>
<p>
   If the processor is already in kernel mode
   and takes a nested exception,
   since it does not need to switch stacks,
   it does not save the old <tt>SS</tt> or <tt>RSP</tt> registers.
   For exception types that do not push an error code,
   the kernel stack therefore looks like the following
   on entry to the exception handler:
</p>
<pre>
                     +--------------------+ &lt;---- old RSP
                     |     old EFLAGS     |     " - 8
                     | 0x00000 | old CS   |     " - 16
                     |      old RIP       |     " - 24
                     +--------------------+             
</pre>
<p>
   For exception types that push an error code,
   the processor pushes the error code immediately after the old <tt>RIP</tt>,
   as before.
</p>
<p>
   There is one important caveat to the processor's nested exception capability.
   If the processor takes an exception while already in kernel mode,
   and <i>cannot push its old state onto the kernel stack</i> for any reason
   such as lack of stack space,
   then there is nothing the processor can do to recover,
   so it simply resets itself.
   Needless to say, the kernel should be designed so that this can't happen.
</p>
<h3>Setting Up the IDT</h3>
<p>
   You should now have the basic information you need
   in order to set up the IDT and handle exceptions in JOS.
   For now, you will set up the IDT to handle 
   interrupt vectors 0-31 (the processor exceptions)
   and interrupts 32-47 (the device IRQs).
</p>
<p>
   The header files <tt>inc/trap.h</tt> and <tt>kern/trap.h</tt>
   contain important definitions related to interrupts and exceptions
   that you will need to become familiar with.
   The file <tt>kern/trap.h</tt> contains definitions
   that are strictly private to the kernel,
   while <tt>inc/trap.h</tt>
   contains definitions that may also be useful
   to user-level programs and libraries.
</p>
<p>
   Note:
   Some of the exceptions in the range 0-31 are defined by Intel to be
   reserved.
   Since they will never be generated by the processor,
   it doesn't really matter how you handle them.
   Do whatever you think is cleanest.
</p>
<p>
   The overall flow of control that you should achieve is depicted below: 
</p>
<pre>
      IDT                   trapentry.S         trap.c
   
+----------------+                        
|   &amp;handler1    |---------> handler1:          trap (struct Trapframe *tf)
|                |             // do stuff      {
|                |             call trap          // handle the exception/interrupt
|                |             // undo stuff    }
+----------------+
|   &amp;handler2    |--------> handler2:
|                |            // do stuff
|                |            call trap
|                |            // undo stuff
+----------------+
       .
       .
       .
+----------------+
|   &amp;handlerX    |--------> handlerX:
|                |             // do stuff
|                |             call trap
|                |             // undo stuff
+----------------+
</pre>
<p>
   Each exception or interrupt should have
   its own handler in <tt>trapentry.S</tt>
   and <code>trap_init()</code> should initialize the IDT with the addresses
   of these handlers.
   Each of the handlers should build a <code>struct Trapframe</code>
   (see <tt>inc/trap.h</tt>) on the stack and call 
   <code>trap()</code> (in <tt>trap.c</tt>)
   with a pointer to the Trapframe.
</p>
<p>
   <code>trap()</code> handles the
   exception/interrupt or dispatches to a specific
   handler function.
   If and when <code>trap()</code> returns,
   the code in <tt>trapentry.S</tt>
   restores the old CPU state saved in the Trapframe
   and then uses the <code>iret</code> instruction
   to return from the exception.
</p>
<div class="required">
   <p><span class="header">Exercise 4.</span>
      Edit <tt>trapentry.S</tt> and <tt>trap.c</tt> and
      implement the features described above.  The macros
      <code>TRAPHANDLER</code> and <code>TRAPHANDLER_NOEC</code> in
      <tt>trapentry.S</tt> should help you, as well as the T_*
      defines in <tt>inc/trap.h</tt>.  You will need to add an
      entry point in <tt>trapentry.S</tt> (using those macros)
      for each trap defined in <tt>inc/trap.h</tt>, and
      you'll have to provide <code>_alltraps</code> which the
      <code>TRAPHANDLER</code> macros refer to.  You will
      also need to modify <code>trap_init()</code> to initialize the
      <code>idt</code> to point to each of these entry points
      defined in <tt>trapentry.S</tt>; the <code>SETGATE</code>
      macro will be helpful here.
   </p>
   <p>
      Hint: your <code>_alltraps</code> should:
   </p>
   <ol>
      <li>push values to make the stack look like a struct Trapframe</li>
      <li>load <code>GD_KD</code> into <tt>%ds</tt> and <tt>%es</tt></li>
      <li>Pass a pointer to the Trapframe as an argument to trap() (Hint: Review the x64 calling convention from lab 1).</li>
      <li><code>call trap</code> (can <code>trap</code> ever return?)</li>
   </ol>
   <p>
      Consider using the <code>PUSHA</code> and <code>POPA</code>
      macros; they fit nicely with the layout of the <code>struct
      Trapframe</code>.
   </p>
   <p>Be sure to initialize every possible trap entry to a default handler (T_DEFAULT).</p>
   <p>
      Test your trap handling code
      using some of the test programs in the <tt>user</tt> directory
      that cause exceptions before making any system calls,
      such as <tt>user/divzero</tt>.
      You should be able to get <kbd>make grade</kbd>
      to succeed on the <tt>divzero</tt>, <tt>softint</tt>,
      and <tt>badsegment</tt> tests at this point.
   </p>
   <p><b>Important note:</b> Be very careful not to 
      declare your trap handling functions (defined by a
      <code>TRAPHANDLER</code> or <code>TRAPHANDLER_NOEC</code> macro)
      with a name already in use in the code.  In your C code,
      these will likely be declared as <code>extern</code>,
      which disables the compiler checking for conflicting symbol names---the		
      compiler instead just picks the first instance of a symbol it finds.
   </p>
   <p>
      For instance, the function <code>breakpoint</code>
      is already defined in <code>inc/x86.h</code>, and the compiler will 
      not warn you about this if you also call your breakpoint
      trap handler <code>breakpoint</code>; rather, the compiler
      will likely pick the wrong function.
      For this reason, one strategy might be to pick a random prefix for 
      all traphandlers, like <code>XTRPX_divzero</code>, <code>XTRPX_pgfault</code>, etc.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge 1!</span> (2 bonus points)
      You probably have a lot of very similar code
      right now, between the lists of <code>TRAPHANDLER</code> in
      <tt>trapentry.S</tt> and their installations in
      <tt>trap.c</tt>.  Clean this up.  Change the macros in
      <tt>trapentry.S</tt> to automatically generate a table for
      <tt>trap.c</tt> to use.  Note that you can switch between
      laying down code and data in the assembler by using the
      directives <code>.text</code> and <code>.data</code>.
   </p>
</div>
<!--
   <div class="question">
   <p><span class="header">Questions</span></p>
   
   <p>
   Answer the following questions:
   </p>
   <ol>
   <li style="counter-reset: start 0">
   	What is the purpose of having an individual handler function for
   	each exception/interrupt?  (i.e., if all exceptions/interrupts were
   	delivered to the same handler, what feature that exists in
   	the current implementation could not be provided?)</li>
   <li>	Did you have to do anything
   	to make the <tt>user/softint</tt> program behave correctly?
   	The grade script expects it to produce a general protection
   	fault (trap 13), but <tt>softint</tt>'s code says
   	<code>int&nbsp;$14</code>.
   	<i>Why</i> should this produce interrupt vector 13?
   	What happens if the kernel actually allows <tt>softint</tt>'s
   	<code>int&nbsp;$14</code> instruction to invoke the kernel's page fault handler
   	(which is interrupt vector 14)?</li>
   
   </ol>
   </div>
   -->
<p>
   <b>This completes part A.</b>
</p>
<h2>Part B: Page Faults, Breakpoints Exceptions, and System Calls</h2>
<p>
   Now that your kernel has basic exception handling capabilities,
   you will refine it to provide important operating system primitives
   that depend on exception handling.
</p>
<h3>Handling Page Faults</h3>
<p>
   The page fault exception, interrupt vector 14 (<code>T_PGFLT</code>),
   is a particularly important one that we will exercise heavily
   throughout this lab and the next.
   When the processor takes a page fault,
   it stores the linear address that caused the fault
   in a special processor control register, <tt>CR2</tt>.
   In <tt>trap.c</tt>
   we have provided the beginnings of a special function,
   <code>page_fault_handler()</code>,
   to handle page fault exceptions.
</p>
<div class="required">
   <p><span class="header">Exercise 5.</span>
      Modify <code>trap_dispatch()</code>
      to dispatch page fault exceptions
      to <code>page_fault_handler()</code>.
      You should now be able to get <kbd>make grade</kbd>
      to succeed on the <tt>faultread</tt>, <tt>faultreadkernel</tt>,
      <tt>faultwrite</tt>, and <tt>faultwritekernel</tt> tests.
      If any of them don't work, figure out why and fix them.
      Remember that you can boot JOS into a particular user program
      using <kbd>make run-<i>x</i></kbd> or <kbd>make run-<i>x</i>-nox</kbd>.
   </p>
</div>
<p>
   You will further refine the kernel's page fault handling below,
   as you implement system calls.
</p>
<h3>The Breakpoint Exception</h3>
<p>
   The breakpoint exception, interrupt vector 3 (<code>T_BRKPT</code>),
   is normally used to allow debuggers
   to insert breakpoints in a program's code
   by temporarily replacing the relevant program instruction
   with the special 1-byte <code>int3</code> software interrupt instruction.
   In JOS we will abuse this exception slightly
   by turning it into a primitive pseudo-system call
   that any user environment can use to invoke the JOS kernel monitor.
   This usage is actually somewhat appropriate
   if we think of the JOS kernel monitor as a primitive debugger.
   The user-mode implementation of <code>panic()</code> in <tt>lib/panic.c</tt>,
   for example,
   performs an <code>int3</code> after displaying its panic message.
</p>
<div class="required">
   <p><span class="header">Exercise 6.</span>
      Modify <code>trap_dispatch()</code>
      to make breakpoint exceptions invoke the kernel monitor.
      You should now be able to get <kbd>make grade</kbd>
      to succeed on the <tt>breakpoint</tt> test.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge 2!</span> (5 bonus points; mega-bragging rights for a good disassembler)
      Modify the JOS kernel monitor so that
      you can 'continue' execution from the current location
      (e.g., after the <code>int3</code>,
      if the kernel monitor was invoked via the breakpoint exception),
      and so that you can single-step one instruction at a time.
      You will need to understand certain bits
      of the <tt>EFLAGS</tt> register
      in order to implement single-stepping.
   </p>
   <p><span class="header">Optional:</span>
      If you're feeling really adventurous,
      find some x86 disassembler source code -
      e.g., by ripping it out of QEMU,
      or out of GNU binutils, or just write it yourself -
      and extend the JOS kernel monitor
      to be able to disassemble and display instructions
      as you are stepping through them.
      Combined with the symbol table loading 
      from lab 2,
      this is the stuff of which real kernel debuggers are made.
   </p>
</div>
<div class="question">
   <p><span class="header">Questions</span></p>
   <ol>
      <li style="counter-reset: start 2">	The break point test case will either generate a break point
         exception or a general protection fault depending on how you initialized
         the break point entry in the IDT (i.e., your call to
         <code>SETGATE</code> from <code>trap_init</code>).  Why?
         How do you need to set it up in order to get the breakpoint exception
         to work as specified above and what incorrect setup would
         cause it to trigger a general protection fault?
      </li>
      <li>	What do you think is the point of these mechanisms,
         particularly in light of
         what the <tt>user/softint</tt> test program does?
      </li>
   </ol>
</div>
<h3>System calls</h3>
<p>
   User processes ask the kernel to do things for them by
   invoking system calls.  When the user process invokes a system call,
   the processor enters kernel mode,
   the processor and the kernel cooperate
   to save the user process's state,
   the kernel executes appropriate code in order to carry out the system
   call, and then resumes the user process.  The exact
   details of how the user process gets the kernel's attention
   and how it specifies which call it wants to execute vary
   from system to system.
</p>
<!--
   <p>
   In V6, user processes executed the <code>sys</code> instruction
   to get the kernel's attention.
   The user process specifies the type of system call
   with a constant in the instruction itself.  The
   arguments to the system call are also in the instruction
   stream, or in registers, or on the stack, or some combination
   of the three.  The kernel passes the return value
   back to the user process in <code>r0</code>.
   </p>
   -->
<p>
   In the JOS kernel, we will use the <code>int</code>
   instruction, which causes a processor interrupt.
   In particular, we will use <code>int&nbsp;$0x30</code>
   as the system call interrupt.
   We have defined the constant
   <code>T_SYSCALL</code> to 48 (0x30) for you.  You will have to
   set up the interrupt descriptor to allow user processes to
   cause that interrupt.  Note that interrupt 0x30 cannot be
   generated by hardware, so there is no ambiguity caused by
   allowing user code to generate it.
</p>
<p>
   The application will pass the system call number and
   the system call arguments in registers.  This way, the kernel won't
   need to grub around in the user environment's stack
   or instruction stream.  The
   system call number will go in <code>%rax</code>, and the
   arguments (up to five of them) will go in <code>%rdx</code>,
   <code>%rcx</code>, <code>%rbx</code>, <code>%rdi</code>,
   and <code>%rsi</code>, respectively.  The kernel passes the
   return value back in <code>%eax</code>.  The assembly code to
   invoke a system call has been written for you, in
   <code>syscall()</code> in <tt>lib/syscall.c</tt>.  You
   should read through it and make sure you understand what
   is going on.
</p>
<div class="required">
   <p><span class="header">Exercise 7.</span>
      Add a handler in the kernel
      for interrupt vector <code>T_SYSCALL</code>.
      You will have to edit <tt>kern/trapentry.S</tt> and
      <tt>kern/trap.c</tt>'s <code>trap_init()</code>.  You
      also need to change <code>trap_dispatch()</code> to handle the
      system call interrupt by calling <code>syscall()</code>
      (defined in <tt>kern/syscall.c</tt>)
      with the appropriate arguments,
      and then arranging for
      the return value to be passed back to the user process
      in <code>%eax</code>.
      Finally, you need to implement <code>syscall()</code> in
      <tt>kern/syscall.c</tt>.
      Make sure <code>syscall()</code> returns <code>-E_INVAL</code>
      if the system call number is invalid.
      You should read and understand <tt>lib/syscall.c</tt>
      (especially the inline assembly routine) in order to confirm
      your understanding of the system call interface.
      You may also find it helpful to read <tt>inc/syscall.h</tt>.
   </p>
   <p>
      Run the <tt>user/hello</tt> program under your kernel.
      It should print "<tt>hello, world</tt>" on the console
      and then cause a page fault in user mode.
      If this does not happen, it probably means
      your system call handler isn't quite right.
      You should also now be able to get <kbd>make grade</kbd>
      to succeed on the <tt>testbss</tt> test.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge 3!</span> (10 bonus points)
      Implement system calls using the <code>sysenter</code> and
      <code>sysexit</code> instructions instead of using
      <code>int&nbsp;0x30</code> and <code>iret</code>. 
   </p>
   <p>
      The <code>sysenter/sysexit</code> instructions were designed
      by Intel to be faster than <code>int/iret</code>.  They do
      this by using registers instead of the stack and by making
      assumptions about how the segmentation registers are used.
      The exact details of these instructions can be found in Volume
      2B of the Intel reference manuals.
   </p>
   <p>
      The easiest way to add support for these instructions in JOS
      is to add a <code>sysenter_handler</code> in
      <tt>kern/trapentry.S</tt> that saves enough information about
      the user environment to return to it, sets up the kernel
      environment, pushes the arguments to
      <code>syscall()</code> and calls <code>syscall()</code>
      directly.  Once <code>syscall()</code> returns, set everything
      up for and execute the <code>sysexit</code> instruction.
      You will also need to add code to <tt>kern/init.c</tt> to
      set up the necessary model specific registers (MSRs).  Section
      6.1.2 in Volume 2 of the AMD Architecture Programmer's Manual
      and the reference on SYSENTER in Volume 2B of the Intel
      reference manuals give good descriptions of the relevant MSRs.
      You can find an implementation of <code>wrmsr</code> to add to
      <tt>inc/x86.h</tt> for writing to these MSRs <a
         href="http://www.garloff.de/kurt/linux/k6mod.c">here</a>.
   </p>
   <p>
      Finally, <tt>lib/syscall.c</tt> must be changed to support
      making a system call with <code>sysenter</code>.  Here is a
      possible register layout for the <code>sysenter</code>
      instruction:
   </p>
   <pre>
	rax                - syscall number
	rdx, rcx, rbx, rdi - arg1, arg2, arg3, arg4
	rsi                - return pc
	rbp                - return rsp
	rsp                - trashed by sysenter
   </pre>
   <p>
      GCC's inline assembler will automatically save registers that
      you tell it to load values directly into.  Don't forget to
      either save (push) and restore (pop) other registers that you
      clobber, or tell the inline assembler that you're clobbering
      them.  The inline assembler doesn't support saving
      <code>%rbp</code>, so you will need to add code to save and
      restore it yourself.  The return
      address can be put into <code>%esi</code> by using an
      instruction like <code>leal after_sysenter_label,
      %%esi</code>.
   </p>
   <p>
      Note that this only supports 4 arguments, so you will need to
      leave the old method of doing system calls around
      to support 5 argument system calls.  Furthermore, because this
      fast path doesn't update the current environment's trap frame,
      it won't be suitable for some of the system calls we add in
      later labs.
   </p>
   <p>
      You may have to revisit your code once we enable asynchronous
      interrupts in the next lab.  Specifically, you'll need to
      enable interrupts when returning to the user process, which
      <code>sysexit</code> doesn't do for you.
   </p>
</div>
<h3>User-mode startup</h3>
<p>
   A user program starts running at the top of
   <tt>lib/entry.S</tt>.  After some setup, this code
   calls <code>libmain()</code>, in <tt>lib/libmain.c</tt>.
   You should modify <tt>libmain()</tt> to initialize the global pointer
   <code>env</code> to point at this environment's
   <code>struct Env</code> in the <code>envs[]</code> array.
   (Note that <tt>lib/entry.S</tt> has already defined <code>envs</code>
   to point at the <code>UENVS</code> mapping you set up in Part A.)
   Hint: look in <tt>inc/env.h</tt> and use
   <code>sys_getenvid</code>.
</p>
<p>
   <code>libmain()</code> then calls <code>umain</code>, which,
   in the case of the hello program, is in
   <tt>user/hello.c</tt>.  Note that after printing
   "<tt>hello, world</tt>", it tries to access
   <code>env->env_id</code>.  This is why it faulted earlier.
   Now that you've initialized <code>env</code> properly,
   it should not fault.
   If it still faults, you probably haven't mapped the
   <code>UENVS</code> area user-readable (back in Part A in
   <tt>pmap.c</tt>; this is the first time we've actually
   used the <code>UENVS</code> area).
</p>
<div class="required">
   <p><span class="header">Exercise 8.</span>
      Add the required code to the user library, then 
      boot your kernel.  You should see <tt>user/hello</tt>
      print "<tt>hello, world</tt>" and then print "<tt>i
      am environment 00001000</tt>".
      <tt>user/hello</tt> then attempts to "exit"
      by calling <code>sys_env_destroy()</code>
      (see <tt>lib/libmain.c</tt> and <tt>lib/exit.c</tt>).
      Since the kernel currently only supports one user environment,
      it should report that it has destroyed the only environment
      and then drop into the kernel monitor.
      You should be able to get <kbd>make grade</kbd>
      to succeed on the <tt>hello</tt> test.
   </p>
</div>
<h3>Page faults and memory protection</h3>
<p>
   Memory protection is a crucial feature of an operating system,
   ensuring that
   bugs in one program cannot corrupt other programs or corrupt the operating
   system itself.
</p>
<p>
   Operating systems usually rely on hardware support
   to implement memory protection. 
   The OS keeps the hardware informed about which virtual addresses
   are valid and which are not.  When a program tries to access an invalid
   address or one for which it has no permissions, the processor stops the
   program at the instruction causing the fault and then traps
   into the kernel with information about the attempted operation.
   If the fault is fixable, the kernel can fix it and let the program 
   continue running.  If the fault is not fixable, then the program cannot
   continue, since it will never get past the instruction causing the fault.
</p>
<p>
   As an example of a fixable fault, consider an automatically extended stack.
   In many systems the kernel initially allocates a single stack page, and then
   if a program faults accessing pages further down the stack, the kernel
   will allocate those pages automatically and let the program continue.
   By doing this, the kernel only allocates as much stack memory as
   the program needs, but the program can work under the illusion that it
   has an arbitrarily large stack.
</p>
<p>
   System calls present an interesting problem for memory protection.
   Most system call interfaces let user programs pass pointers to the 
   kernel.  These pointers point at user buffers to be read or written.
   The kernel then dereferences these pointers
   while carrying out the system call.
   There are two problems with this:
</p>
<ol>
   <li>
      A page fault in the kernel
      is potentially a lot more serious than a page fault in a user program.
      If the kernel page-faults while manipulating its own data structures,
      that's a kernel bug, and the
      fault handler should panic the kernel
      (and hence the whole system).
      But when the kernel is dereferencing pointers
      given to it by the user program,
      it needs a way to remember that any page faults these dereferences cause
      are actually on behalf of the user program.
   </li>
   <li>
      The kernel typically has more memory permissions than the user program.
      The user program might pass a pointer to a system call that points
      to memory that the kernel can read or write but that the program
      cannot.
      The kernel must be careful not to be tricked into dereferencing
      such a pointer, since that might reveal private information or
      destroy the integrity of the kernel.
   </li>
</ol>
<p>
   For both of these reasons the kernel must be extremely careful when 
   handling pointers presented by user programs.
</p>
<p>
   You will now solve these two problems with 
   a single mechanism that scrutinizes
   all pointers passed from userspace into the kernel.
   When a program passes the kernel a pointer, the kernel will check
   that the address is in the user part of the address space,
   and that the page table would allow the memory operation.
</p>
<p>
   Thus, the kernel will never suffer a page fault due to dereferencing
   a user-supplied pointer.
   If the kernel does page fault, it should panic and terminate.
</p>
<div class="required">
   <p><span class="header">Exercise 9.</span>
      Change <code>kern/trap.c</code> to panic if a page
      fault happens in kernel mode.
   </p>
   <p>
      Hint: to determine whether a fault happened in user mode or
      in kernel mode, check the low bits of the <code>tf_cs</code>.
   </p>
   <p>Read <code>user_mem_assert</code> in <tt>kern/pmap.c</tt>
      and implement <code>user_mem_check</code> in that same file.
   </p>
   <p>
      Change <tt>kern/syscall.c</tt> to sanity check arguments
      to system calls.
   </p>
   <p>
      Change <tt>kern/init.c</tt> to run <tt>user/buggyhello</tt>
      instead of <tt>user/hello</tt>.  Compile your kernel and boot it.
      The environment should be destroyed,
      and the kernel should <i>not</i> panic.
      You should see:
   </p>
   <pre>
	[00001000] user_mem_check assertion failure for va 00000001
	[00001000] free env 00001000
	Destroyed the only environment - nothing more to do!
	</pre>
   </div>
<p>
   Note that the same mechanism you just implemented also works for 
   malicious user applications (such as <tt>user/evilhello</tt>).
</p>
<div class="required">
   <p><span class="header">Exercise 10.</span>
      Change <tt>kern/init.c</tt> to run <tt>user/evilhello</tt>.
      Compile your kernel and boot it.
      The environment should be destroyed,
      and the kernel should not panic.
      You should see:
   </p>
   <pre>
	[00000000] new env 00001000
	[00001000] user_mem_check assertion failure for va f010000c
	[00001000] free env 00001000
	</pre>
</div>
<h3>Hand-In Procedure</h3>
<i>If you submit multiple times, we will take the latest
submission and count late hours accordingly.</i>
</p>
<p>
   You do not need to turn in answers
   to any of the questions in the text of the lab.
   (Do answer them for yourself though!  They will help with the rest of the lab.)
</p>
<p>
   We will be grading your solutions with a grading program.
   You can run <kbd>make grade</kbd>
   to test your solutions with the grading program.
</p>
<p>
   <b>This completes the lab.</b>
</p>