
<h2>Introduction</h2>

<p>
In this lab, you will implement <code>spawn</code>, a library call
that loads and runs on-disk executables.
You will then flesh out your kernel and library operating system
enough to run a shell on the console.

</p>

<h3>Getting Started</h3>

<p>
Use Git to fetch the latest version of the course
repository, and then create a local branch called <tt>lab5</tt> based on our
lab5 branch, <tt>origin/lab5</tt>:
</p>
<pre>
kermit% <kbd>cd lab</kbd>
kermit% <kbd>git commit -am 'my solution to lab4'</kbd>

Created commit 734fab7: my solution to lab4
 4 files changed, 42 insertions(+), 9 deletions(-)
kermit% <kbd>git pull</kbd>
....
kermit% <kbd>git checkout -b lab5 origin/lab5</kbd>
Branch lab5 set up to track remote branch refs/remotes/origin/lab5.
Switched to a new branch "lab5"
kermit% <kbd>git merge lab4</kbd>
Merge made by recursive.
....
kermit%
</pre>

<p> The main new component for this part of the lab is the file
system environment, located in the new <tt>fs</tt> directory.  Scan
through all the files in this directory to get a feel for what all is
new.  Also, there are some new file system-related source files in
the <tt>user</tt> and <tt>lib</tt> directories,
</p>

<table align="center">
<tr><td><tt>fs/fs.c</tt></td>
    <td>Code that mainipulates the file system's on-disk structure.</td></tr>
<tr><td><tt>fs/bc.c</tt></td>
    <td>A simple block cache built on top of our user-level page fault
	 handling facility.</td></tr>
<tr><td><tt>fs/ide.c</tt></td>
	<td>Minimal PIO-based (non-interrupt-driven) IDE driver code.</td></tr>
<tr><td><tt>fs/serv.c</tt></td>
    <td>The file system server that interacts with client environments
	 using file system IPCs.</td></tr>
<tr><td><tt>lib/fd.c</tt></td>
    <td>Code that implements the general UNIX-like file descriptor
	 interface.</td></tr>
<tr><td><tt>lib/file.c</tt></td>
    <td>The driver for on-disk file type, implemented as a file system
	 IPC client.</td></tr>
<tr><td><tt>lib/console.c</tt></td>
    <td>The driver for console input/output file type.</td></tr>
<tr><td><tt>lib/spawn.c</tt></td>
    <td>Code skeleton of the <tt>spawn</tt> library call.</td></tr>
</table>


<p>
You should run the pingpong, primes, and forktree test cases from lab
4 again after merging in the new lab 5 code.  You will need to comment
out the <code>ENV_CREATE(fs_fs)</code> line in <tt>kern/init.c</tt>
because <tt>fs/fs.c</tt> tries to do some I/O, which JOS does not allow
yet. 

Similarly, temporarily comment out the call to <code>close_all()</code> in
<tt>lib/exit.c</tt>; this function calls subroutines that you will implement
later in the lab, and therefore will panic if called. 

If your lab 4 code doesn't contain any bugs, the test cases should run
fine.  Don't proceed until they work.  Don't forget to un-comment
these lines when you start Exercise 1.
</p>

<p>
If they don't work, use <kbd> git diff lab4</kbd> to review
all the changes, making sure there isn't any code you wrote for lab4
(or before) missing from lab 5.  Make sure that lab 4 still works.
</p>
<!-- 
<h3>Lab Requirements</h3>
<p>
As before, you will need
to do all of the regular exercises described in the lab and <i>at
least one</i> challenge problem.
Additionally, you will
need to write up brief answers to the questions posed in the lab and a
short (e.g., one or two paragraph) description of what you did to
solve your chosen challenge problem.  If you implement more than one
challenge problem, you only need to describe one of them in the
write-up, though of course you are welcome to do more.  Place the
write-up in a file called <tt>answers-lab5.txt</tt> in the top level of
your <tt>lab5</tt> directory before handing in your work.
</p> -->

<h1>File system preliminaries</h1>

<p>
We have provided you with a simple, read-only, disk-based file system. 
You will need to slightly change your existing code in order to port
the file system for your JOS, so that
<tt>spawn</tt> can access on-disk executables using path names.

Although you do not have to understand every detail of the file system,
such as its on-disk structure.  It is very important that you familiarize
yourself with the design principles and its various interfaces.
</p>

<p>
The file system itself is implemented in micro-kernel fashion,
outside the kernel but within its own user-space environment.
Other environments access the file system by making IPC requests
to this special file system environment.
</p>


<h2>Disk Access</h2>

<p>
The file system environment in our operating system
needs to be able to access the disk,
but we have not yet implemented any disk access functionality in our kernel.
Instead of taking the conventional "monolithic" operating system strategy
of adding an IDE disk driver to the kernel
along with the necessary system calls to allow the file system to access it,
we instead implement the IDE disk driver
as part of the user-level file system environment.
We will still need to modify the kernel slightly,
in order to set things up so that the file system environment
has the privileges it needs to implement disk access itself.

</p><p>
It is easy to implement disk access in user space this way
as long as we rely on polling, "programmed I/O" (PIO)-based disk access
and do not use disk interrupts.
It is possible to implement interrupt-driven device drivers in user mode as well
(the L3 and L4 kernels do this, for example),
but it is more difficult
since the kernel must field device interrupts
and dispatch them to the correct user-mode environment.

</p><p>
The x86 processor uses the IOPL bits in the EFLAGS register
to determine whether protected-mode code
is allowed to perform special device I/O instructions
such as the IN and OUT instructions.
Since all of the IDE disk registers we need to access
are located in the x86's I/O space rather than being memory-mapped,
giving "I/O privilege" to the file system environment
is the only thing we need to do
in order to allow the file system to access these registers.
In effect, the IOPL bits in the EFLAGS register
provides the kernel with a simple "all-or-nothing" method
of controlling whether user-mode code can access I/O space.
In our case, we want the file system environment
to be able to access I/O space,
but we do not want any other environments
to be able to access I/O space at all.

</p>

<div class="required">
<p><span class="header">Exercise 1.</span>
<code>i386_init</code> identifies the file system environment by
passing the type <code>ENV_TYPE_FS</code> to your environment creation
function, <code>env_create</code>.
Modify <code>env_create</code> in <tt>env.c</tt>,
so that it gives the file system environment I/O privilege,
but never gives that privilege to any other environment.
</p><p>
Make sure you can start the file environment without causing a General
Protection fault.  You should pass the "fs i/o" test in <kbd>make grade</kbd>.
</p></div>

<div class="question">
<p><span class="header">Question</span></p>
<ol> <li>
Do you have to do anything else
to ensure that this I/O privilege setting
is saved and restored properly when you subsequently switch
from one environment to another? Why?
</li></ol>
</div>

<p>
Note that the <tt>GNUmakefile</tt> file in this lab
sets up QEMU to use the file <tt>obj/kern/kernel.img</tt>
as the image for disk 0 (typically "Drive C" under DOS/Windows) as before,
and to use the (new) file <tt>obj/fs/fs.img</tt>
as the image for disk 1 ("Drive D").
In this lab our file system should only ever touch disk 1;
disk 0 is used only to boot the kernel.

<h2>The Block Cache</h2>

<p>
In our file system,
we will implement a simple "buffer cache" (really just a block cache)
with the help of the processor's virtual memory system.
The code for the block cache is in <tt>fs/bc.c</tt>.
</p>

<p>
Our file system will be limited to handling disks of size 3GB or less.
We reserve a large, fixed 3GB region
of the file system environment's address space,
from 0x10000000 (<code>DISKMAP</code>)
up to 0xD0000000 (<code>DISKMAP+DISKMAX</code>),
as a "memory mapped" version of the disk.
For example,
disk block 0 is mapped at virtual address 0x10000000,
disk block 1 is mapped at virtual address 0x10001000,
and so on.  The <code>diskaddr</code> function in <tt>fs/bc.c</tt>
implements this translation from disk block numbers to virtual
addresses (along with some sanity checking).
</p>

<p>
Since our file system environment has its own virtual address space
independent of the virtual address spaces
of all other environments in the system,
and the only thing the file system environment needs to do
is to implement file access,
it is reasonable to reserve most of the file system environment's address space
in this way.
It would be awkward for a real file system implementation
on a 32-bit machine to do this
since modern disks are larger than 3GB.
Such a buffer cache management approach
may still be reasonable on a machine with a 64-bit address space.
</p>

<p>
Of course, it would be unreasonable to read the entire disk into
memory, so instead we'll implement a form of <i>demand paging</i>,
wherein we only allocate pages in the disk map region and read the
corresponding block from the disk in response to a page fault in this
region.  This way, we can pretend that the entire disk is in memory.
</p>

<div class="required">
<p><span class="header">Exercise 2.</span>
Implement the <code>bc_pgfault</code> functions in <tt>fs/bc.c</tt>.
<code>bc_pgfault</code> is a page fault handler, just like the one
your wrote in the previous lab for copy-on-write fork, except that
its job is to load pages in from the disk in response to a page
fault.  When writing this, keep in mind that (1) <code>addr</code>
may not be aligned to a block boundary and (2) <code>ide_read</code>
operates in sectors, not blocks.
</p><p>
Use <kbd>make grade</kbd> to test your code.  Your code should pass
"check_super".
</p><p>
</p></div>

The <code>fs_init</code> function in <tt>fs/fs.c</tt> is a prime
example of how to use the block cache.  After initializing the block
cache, it simply stores pointers into the disk map region in the
<code>super</code> global variable.  
After this point, we can simply read from the <code>super</code>
structure as if they were in memory and our page fault handler will
 read them from disk as necessary.


<h2>The file system interface</h2>

<p>

Now that we have the necessary functionality
within the file system environment itself,
we must make it accessible to other environments
that wish to use the file system.
Since other environments can't directly call functions in the file
system environment, we'll expose access to the file system
environment via a <i>remote procedure call</i>, or RPC, abstraction,
built atop JOS's IPC mechanism.
Graphically, here's what a call to the file system server (say, read)
looks like
</p>
<center><table><tr><td>
<pre>
      Regular env           FS env
   +---------------+   +---------------+
   |      read     |   |   file_read   |
   |   (lib/fd.c)  |   |   (fs/fs.c)   |
...|.......|.......|...|.......^.......|...............
   |       v       |   |       |       | RPC mechanism
   |  devfile_read |   |  serve_read   |
   |  (lib/file.c) |   |  (fs/serv.c)  |
   |       |       |   |       ^       |
   |       v       |   |       |       |
   |     fsipc     |   |     serve     |
   |  (lib/file.c) |   |  (fs/serv.c)  |
   |       |       |   |       ^       |
   |       v       |   |       |       |
   |   ipc_send    |   |   ipc_recv    |
   |       |       |   |       ^       |
   +-------|-------+   +-------|-------+
           |                   |
           +-------------------+
</pre>
</td></tr></table></center>
<p>
Everything below the dotted line is simply the mechanics of getting a
read request from the regular environment to the file system
environment.  Starting at the beginning, <code>read</code> (which we
provide) works on any file descriptor and simply dispatches to the
appropriate device read function, in this case
<code>devfile_read</code> (we can have more device types, like pipes).
 <code>devfile_read</code>
implements <code>read</code> specifically for on-disk files.  This and
the other <code>devfile_*</code> functions in <tt>lib/file.c</tt>
implement the client side of the FS operations and all work in roughly
the same way, bundling up arguments in a request structure, calling
<code>fsipc</code> to send the IPC request, and unpacking and
returning the results.  The <code>fsipc</code> function simply handles
the common details of sending a request to the server and receiving
the reply.
</p>

<p>
The file system server code can be found in <tt>fs/serv.c</tt>.  It
loops in the <code>serve</code> function, endlessly receiving a
request over IPC, dispatching that request to the appropriate handler
function, and sending the result back via IPC.  In the read example,
<code>serve</code> will dispatch to <code>serve_read</code>, which
will take care of the IPC details specific to read requests such as
unpacking the request structure and finally call
<code>file_read</code> to actually perform the file read.
</p>

<p>
Recall that JOS's IPC mechanism lets an environment send a single
32-bit number and, optionally, share a page.  To send a request from
the client to the server, we use the 32-bit number for the request
type (the file system server RPCs are numbered, just like how
syscalls were numbered) and store the arguments to the request in a
<code>union Fsipc</code> on the page shared via the IPC.  On the
client side, we always share the page at <code>fsipcbuf</code>; on the
server side, we map the incoming request page at <code>fsreq</code>
(<code>0x0ffff000</code>).
</p>

<p>
The server also sends the response back via IPC.  We use the 32-bit
number for the function's return code.  For most RPCs, this is all
they return.  <code>FSREQ_READ</code> and <code>FSREQ_STAT</code> also
return data, which they simply write to the page that the client sent
its request on.  There's no need to send this page in the response
IPC, since the client shared it with the file system server in the
first place.  Also, in its response, <code>FSREQ_OPEN</code> shares with
the client a new "Fd page". We'll return to the file descriptor 
page shortly.
</p>
<!-- 
<div class="challenge">
<p><span class="header">Challenge!</span>
	Extend the file system to support write access. 
Here are a few points you need to consider:
<ol><li>
	Use the block bitmap starting at block 2 to keep track of which
disk blocks are free and which are in use. 
Look at <tt>fs/fsformat.c</tt> to see how the bitmap is initialized.
</li><li>
	Make use of the <code>alloc</code> argument in 
<code>file_block_walk</code>. 
In <code>file_get_block</code>, allocate new disk blocks as necessary.
</li> <li>
	In your block cache, use the VM hardware (the <code>PTE_D</code>
 "dirty" bit in the
 <code>uvpt</code> entry) to keep track of whether a cached disk block
 has been modified, and thus needs to be written back to the disk.
</li> <li>
	Handle <code>O_CREAT</code> and <code>O_TRUNC</code> open modes 
in <code>serve_open</code>.
</li> <li>
	Handle more file system IPC requests, such as 
<code>FSREQ_SET_SIZE</code>, <code>FSREQ_WRITE</code>, 
<code>FSREQ_FLUSH</code>, <code>FSREQ_REMOVE</code>
and <code>FSREQ_SYNC</code>, in <tt>fs/serv.c</tt>. 
We have defined the argument for these calls for you in <tt>inc/fs.h</tt>.
Also, write the corresponding service routines in <tt>fs/fs.c</tt> and
hook them to client stubs in <tt>lib/file.c</tt>.
</li><li>
	For more information about the file system's on-disk structure,
read <tt>inc/fs.h</tt> and <tt>fs/fsformat.c</tt>. 
You may also refer to 
<a href="http://pdos.csail.mit.edu/6.828/2011/labs/lab5">
last year's lab 5 text.</a>
</li>
</ol>
</p></div> -->


<h1>Spawning Processes</h1>

<p>
We have given you the code for <code>spawn</code>
<!-- In this exercise you will implement <code>spawn</code>, -->
which creates a new environment,
loads a program image from the file system into it,
and then starts the child environment running this program.
The parent process then continues running independently of the child.
The <code>spawn</code> function effectively acts like a <code>fork</code> in UNIX
followed by an immediate <code>exec</code> in the child process.
</p>
<p>
We implemented <code>spawn</code> rather than a
UNIX-style <code>exec</code> because <code>spawn</code> is easier to
implement from user space in "exokernel fashion", without special help
from the kernel.  Think about what you would have to do in order to
implement <code>exec</code> in user space, and be sure you understand
why it is harder.
</p>

<div class="required">
<p><span class="header">Exercise 3.</span>
<code>spawn</code> relies on the new syscall
<code>sys_env_set_trapframe</code> to initialize the state of the
newly created environment.  Implement
<code>sys_env_set_trapframe</code>.  Test your code by running the
<tt>user/spawnhello</tt> program
from <tt>kern/init.c</tt>, which will attempt to
spawn <tt>/hello</tt> from the file system.
</p><p>
Use <kbd>make grade</kbd> to test your code.
</p></div>

<!-- <div class="challenge">
<p><span class="header">Challenge!</span>
	Implement Unix-style <code>exec</code>.
</p></div>

<div class="challenge">
<p><span class="header">Challenge!</span>
	Implement <code>mmap</code>-style memory-mapped files and
	modify <code>spawn</code> to map pages directly from the ELF
	image when possible.
</p></div> -->


<h2>Sharing library state across fork and spawn</h2>

<p>
The UNIX file descriptors are a general notion that also
encompasses pipes, console I/O, etc.  In JOS, each of these device
types has a corresponding <code>struct Dev</code>, 
with pointers to the functions that implement
read/write/etc. for that device type.  <tt>lib/fd.c</tt> implements the
general UNIX-like file descriptor interface on top of this.  Each
<code>struct Fd</code> indicates its device type, and most of the
functions in <tt>lib/fd.c</tt> simply dispatch operations to functions
in the appropriate <code>struct Dev</code>.
</p>

<p>
<tt>lib/fd.c</tt> also maintains the <i>file descriptor table</i>
region in each application environment's address space, starting at
<code>FSTABLE</code>.  This area reserves a page's worth (4KB) of
address space for each of the up to <code>MAXFD</code> (currently 32)
file descriptors the application can have open at once.  At any given
time, a particular file descriptor table page is mapped if and only if
the corresponding file descriptor is in use.  Each file descriptor
also has an optional "data page" in the region starting at
<code>FILEDATA</code>, which devices can use if they choose.
</p>

<p>
  We would like to share file descriptor state across
  <code>fork</code> and <code>spawn</code>, but file descriptor state is kept
  in user-space memory.  Right now, on <code>fork</code>, the memory
  will be marked copy-on-write,
  so the state will be duplicated rather than shared.
  (This means environments won't be able to seek in files they
  didn't open themselves and that pipes won't work across a fork.)
  On <code>spawn</code>, the memory will be
  left behind, not copied at all.  (Effectively, the spawned environment
  starts with no open file descriptors.)
</p>

<p>
  We will change <code>fork</code> to know that 
  certain regions of memory are used by the "library operating system" and
  should always be shared.  Rather than hard-code a list of regions somewhere,
  we will set an otherwise-unused bit in the page table entries (just like
  we did with the <code>PTE_COW</code> bit in <code>fork</code>).
</p>

<p>
  We have defined a new <code>PTE_SHARE</code> bit
  in <tt>inc/lib.h</tt>.
  This bit is one of the three PTE bits
  that are marked "available for software use"
  in the Intel and AMD manuals.
  We will establish the convention that
  if a page table entry has this bit set,
  the PTE should be copied directly from parent to child
  in both <code>fork</code> and <code>spawn</code>.
  Note that this is different from marking it copy-on-write:
  as described in the first paragraph,
  we want to make sure to <i>share</i>
  updates to the page.
</p>

  <div class="required">
	<p><span class="header">Exercise 4.</span>

  Change <code>duppage</code> in <tt>lib/fork.c</tt> to follow
  the new convention.  If the page table entry has the <code>PTE_SHARE</code>
  bit set, just copy the mapping directly.
  (You should use <code>PTE_SYSCALL</code>, not <code>0xfff</code>,
  to mask out the relevant bits from the page table entry. <code>0xfff</code>
  picks up the accessed and dirty bits as well.)
  </p>

  <p>
	Likewise, implement <code>copy_shared_pages</code> in
	<tt>lib/spawn.c</tt>.  It should loop through all page table
	entries in the current process (just like <code>fork</code>
	did), copying any page mappings that have the
	<code>PTE_SHARE</code> bit set into the child process.
  </p></div>

<p>
  Use <kbd>make run-testpteshare</kbd> to check that your code is 
  behaving properly.
  You should see lines that say "<tt>fork handles PTE_SHARE right</tt>"
  and "<tt>spawn handles PTE_SHARE right</tt>".
</p>

<p>
  Use <kbd>make run-testfdsharing</kbd> to check that file descriptors are shared
  properly.
  You should see lines that say "<tt>read in child succeeded</tt>" and
  "<tt>read in parent succeeded</tt>".
</p>

<h1>The keyboard interface</h1>

<p>
  For the shell to work, we need a way to type at it.
  QEMU has been displaying output we write to
  the CGA display and the serial port, but so far we've only taken
  input while in the kernel monitor.
  In QEMU, input typed in the graphical window appear as input
  from the keyboard to JOS, while input typed to the console
  appear as characters on the serial port.
  <tt>kern/console.c</tt> already contains the keyboard and serial
  drivers that have been used by the kernel monitor since lab 1,
  but now you need to attach these to the rest
  of the system.
</p>

  <div class="required">
	<p><span class="header">Exercise 5.</span>
  In your <tt>kern/trap.c</tt>, call <code>kbd_intr</code> to handle trap
  <code>IRQ_OFFSET+IRQ_KBD</code> and <code>serial_intr</code> to
  handle trap <code>IRQ_OFFSET+IRQ_SERIAL</code>.
  </p></div>

<p>
  We implemented the console input/output file type for you,
  in <tt>lib/console.c</tt>.
</p>

<p>
  Test your code by running <kbd>make run-testkbd</kbd> and type
  a few lines.  The system should echo your lines back to you as you finish them.
  Try typing in both the console and the graphical window, if you
  have both available.
</p>

<h1>The Shell</h1>

<p>
  Run <kbd>make run-icode</kbd> or <kbd>make run-icode-nox</kbd>.
  This will run your kernel and start <tt>user/icode</tt>.
  <tt>icode</tt> execs <tt>init</tt>,
  which will set up the console as file descriptors 0 and 1 (standard input and
  standard output).  It will then spawn <tt>sh</tt>, the shell.
  You should be able to run the following
  commands:
</p>
<pre>
	echo hello world | cat
	cat lorem |cat
	cat lorem |num
	cat lorem |num |num |num |num |num
	lsfd
	cat script
	sh &lt;script
</pre>
<p>
  Note that the user library routine <code>cprintf</code>
  prints straight
  to the console, without using the file descriptor code.  This is great
  for debugging but not great for piping into other programs.
  To print output to a particular file descriptor (for example, 1, standard output),
  use <code>fprintf(1, "...", ...)</code>.
  <code>printf("...", ...)</code> is a short-cut for printing to FD 1.
  See <tt>user/lsfd.c</tt> for examples.
</p>

<p>
  Run <kbd>make run-testshell</kbd> to test your shell.
  <tt>testshell</tt> simply feeds the above commands (also found in
  <tt>fs/testshell.sh</tt>) into the shell and then checks that the
  output matches <tt>fs/testshell.key</tt>. 
</p>

<p>
  Your code should pass all tests at this point.  As usual, you can
  grade your submission with <kbd>make grade</kbd> and hand it in with
  <kbd>make handin</kbd>.
</p>


<!-- 
<div class="question">
<p><span class="header">Questions</span></p>
<ol start="2">
<li>How long approximately did it take you to do this lab?</li>
<li>We simplified the file system this year with the goal of making 
more time for the final project. Do you feel like you gained
a basic understanding of the file I/O in JOS? Feel free to suggest
things we could improve.</li>
</ol>
</div> -->

<h3>Hand-In Procedure</h3>
<p>
Create a compressed LAB5_[Team_Number].tar file containing all the files and sumbit in KLMS. Make sure that your code runs successfully in the given kcloud VMs.

We will be grading your solutions with a grading program. You can run make grade to test your solutions with the grading program.
</p>

<p><b>This completes the lab.</b></p>
