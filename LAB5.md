<h2>Introduction</h2>
<p>
   In this lab, you will implement a simple disk-based file system.
   The file system itself will be implemented in micro-kernel fashion,
   outside the kernel but within its own user-space environment.
   Other environments access the file system by making IPC requests
   to this special file system environment.
</p>
<p>
   You will implement <code>spawn</code>, a library call
   that loads and runs on-disk executables.
   You will then flesh out your kernel and library operating system
   enough to run a shell on the console.
</p>
<h3>Getting Started</h3>
<p>
   Use Git to commit your Lab 4 source, fetch the latest version of the course
   repository, and then create a local branch called <tt>lab5</tt> based on our
   lab5 branch, <tt>origin/lab5</tt>:
</p>
<pre>
kermit% <kbd>cd ~/COMP790/lab</kbd>
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
 kern/env.c |   42 +++++++++++++++++++
 1 files changed, 42 insertions(+), 0 deletions(-)
kermit%
</pre>
<p> The main new component for this part of the lab is the file
   system environment, located in the new <tt>fs</tt> directory.  Scan
   through all the files in this directory to get a feel for what all is
   new.  Also, there are some new file system-related source files in
   the <tt>user</tt> and <tt>lib</tt> directories.
   Be sure to scan through all of the files below.
</p>
<table align="center">
   <tr>
      <td><tt>fs/fs.c</tt></td>
      <td>Code that mainipulates the file system's on-disk structure.</td>
   </tr>
   <tr>
      <td><tt>fs/bc.c</tt></td>
      <td>A simple block cache built on top of our user-level page fault
         handling facility.
      </td>
   </tr>
   <tr>
      <td><tt>fs/ide.c</tt></td>
      <td>Minimal PIO-based (non-interrupt-driven) IDE driver code.</td>
   </tr>
   <tr>
      <td><tt>fs/serv.c</tt></td>
      <td>The file system server that interacts with client environments
         using file system IPCs.
      </td>
   </tr>
   <tr>
      <td><tt>lib/fd.c</tt></td>
      <td>Code that implements the general UNIX-like file descriptor
         interface.
      </td>
   </tr>
   <tr>
      <td><tt>lib/file.c</tt></td>
      <td>The driver for on-disk file type, implemented as a file system
         IPC client.
      </td>
   </tr>
   <tr>
      <td><tt>lib/console.c</tt></td>
      <td>The driver for console input/output file type.</td>
   </tr>
   <tr>
      <td><tt>lib/spawn.c</tt></td>
      <td>Code skeleton of the <tt>spawn</tt> library call.</td>
   </tr>
</table>
<p>
   You should run the pingpong, primes, and forktree test cases from lab
   4 again after merging in the new lab 5 code.  You will need to comment
   out the <code>ENV_CREATE(fs_fs)</code> line in <tt>kern/init.c</tt>
   because <tt>fs/fs.c</tt> tries to do some I/O, which JOS does allow
   yet. Similarly, temporarily comment out the call to
   <code>close_all()</code> in <tt>lib/exit.c</tt>; this function calls
   subroutines that you will
   implement later in the lab, and therefore will panic if called.  If
   your lab 4 code doesn't contain any bugs, the test cases should run
   fine.  Don't proceed until they work. Don't forget to un-comment
   these lines when you start Exercise 1.
</p>
<p>
   If they don't work, use <kbd> git diff lab4 </kbd> to review
   all the changes, making sure there isn't any code you wrote for lab4
   (or before) missing from lab 5.  Make sure that lab 4 still works.
</p>
<h3>Lab Requirements</h3>
<!--<p>In this and all other labs, you may complete challenge problems for extra credit.
   If you do this, please create entries in challenge5.txt, which includes
   a short (e.g., one or two paragraph) description of what you did
   to solve your chosen challenge problem and how to test it.
   If you implement more than one challenge problem,
   you must describe each one.
   Be sure to list the challenge problem number.
   If you complete challenges from previous labs, please list them in this file (not a previous
   lab challenge file), with both the lab and problem number.
</p>-->
<p>
   When you are ready to hand in your lab code and write-up,
   note in <tt>slack.txt</tt> how many
   late hours you have used for this assignment.
   (This is to help us agree on the number
   that you have used.)
   This file should contain a single line formatted as follows (where n is the number of late hours):
<pre>late hours taken: n</pre>
Commit your changes to the
git repository using <kbd>git commit -am "Your commit message"</kbd>.
<i>If you submit multiple times, we will take
the latest submission and count late hours accordingly.</i>
</p>
<h1>File system preliminaries</h1>
<p> The file system you will work with is much simpler than most
   "real" file systems including that of xv6 UNIX, but it is powerful
   enough to provide the basic features: creating, reading, writing, and
   deleting files organized in a hierarchical directory structure.
</p>
<p>We are (for the moment anyway) developing only a single-user
   operating system, which provides protection sufficient to catch bugs
   but not to protect multiple mutually suspicious users from each
   other. Our file system therefore does not support the UNIX notions of
   file ownership or permissions. Our file system also currently does not
   support hard links, symbolic links, time stamps, or special device
   files like most UNIX file systems do. 
</p>
<p>
   The file system itself is implemented in micro-kernel fashion,
   outside the kernel but within its own user-space environment.
   Other environments access the file system by making IPC requests
   to this special file system environment.
</p>
<h2>On-Disk File System Structure</h2>
<p>
   Most UNIX file systems divide available disk space into two main types
   of regions:
   <i>inode</i> regions and <i>data</i> regions.
   UNIX file systems assign one <i>inode</i> to each file in the file system;
   a file's inode holds critical meta-data about the file
   such as its <code>stat</code> attributes and pointers to its data blocks.
   The data regions are divided into much larger (typically 8KB or more)
   <i>data blocks</i>, within which the file system stores
   file data and directory meta-data.
   Directory entries contain file names and pointers to inodes;
   a file is said to be <i>hard-linked</i>
   if multiple directory entries in the file system
   refer to that file's inode.
   Since our file system will not support hard links,
   we do not need this level of indirection
   and therefore can make a convenient simplification:
   our file system will not use inodes at all
   and instead will simply store all of a file's (or sub-directory's) meta-data
   within the (one and only) directory entry describing that file.
</p>
<p>
   Both files and directories logically consist of a series of data blocks,
   which may be scattered throughout the disk
   much like the pages of an environment's virtual address space
   can be scattered throughout physical memory.
   The file system environment hides the details of block layout,
   presenting interfaces for reading and writing sequences of bytes at
   arbitrary offsets within files.  The file system environment
   handles all modifications to directories internally
   as a part of performing actions such as file creation and deletion.
   Our file system <i>does</i>, however, allow user environments
   to <i>read</i> directory meta-data directly
   (e.g., with <code>read</code> and <code>write</code>),
   which means that user environments can perform directory scanning operations
   themselves (e.g., to implement the <tt>ls</tt> program)
   rather than having to rely on additional special calls to the file system.
   The disadvantage of this approach to directory scanning,
   and the reason that most modern UNIX variants discourage it,
   is that it makes application programs dependent
   on the format of directory meta-data,
   making it difficult to change the file system's internal layout
   without changing or at least recompiling application programs as well.
</p>
<h3>Sectors and Blocks</h3>
<p>
   Most disks cannot perform reads and writes at byte granularity and
   instead perform reads and writes in units of <i>sectors</i>,
   which today are almost universally 512 bytes each.
   File systems actually allocate and use disk storage in units of <i>blocks</i>.
   Be wary of the distinction between the two terms:
   <i>sector size</i> is a property of the disk hardware,
   whereas <i>block size</i> is an aspect of the operating system using the disk.
   A file system's block size must be
   a multiple of the sector size of the underlying disk.
</p>
<p>
   <!--The UNIX xv6 file system uses a block size of 512 bytes,
      the same as the sector size of the underlying disk.
      Most modern file systems use a larger block size, however,
      because storage space has gotten much cheaper
      and it is more efficient to manage storage at larger granularities.-->
   Our file system will use a block size of 4096 bytes,
   conveniently matching the processor's page size.
</p>
<h3>Superblocks</h3>
<p>
   <img src="disk.png" style="float:right" alt="Disk layout" />
   File systems typically reserve certain disk blocks
   at "easy-to-find" locations on the disk
   (such as the very start or the very end)
   to hold meta-data describing properties of the file system as a whole,
   such as the block size, disk size,
   any meta-data required to find the root directory,
   the time the file system was last mounted,
   the time the file system was last checked for errors,
   and so on.
   These special blocks are called <i>superblocks</i>.
</p>
<p>
   Our file system will have exactly one superblock,
   which will always be at block 1 on the disk.
   Its layout is defined by <code>struct Super</code> in <tt>inc/fs.h</tt>.
   Block 0 is typically reserved to hold boot loaders and partition tables,
   so file systems generally do not use the very first disk block.
   Many "real" file systems maintain multiple superblocks,
   replicated throughout several widely-spaced regions of the disk,
   so that if one of them is corrupted
   or the disk develops a media error in that region,
   the other superblocks can still be found and used to access the file system.
</p>
<h3>The Block Bitmap: Managing Free Disk Blocks</h3>
<p>
   In the same way that the kernel must manage the system's physical memory
   to ensure that a given physical page is used for only one purpose at a time,
   a file system must manage the blocks of storage on a disk
   to ensure that a given disk block is used for only one purpose at a time.
   In <tt>pmap.c</tt> you keep the <code>Page</code> structures
   for all free physical pages
   on a linked list, <code>page_free_list</code>,
   to keep track of the free physical pages.
   In file systems it is more common to keep track of free disk blocks
   using a <i>bitmap</i> rather than a linked list,
   because a bitmap is more storage-efficient than a linked list
   and easier to keep consistent.
   Searching for a free block in a bitmap can take more CPU time
   than simply removing the first element of a linked list,
   but for file systems this isn't a problem
   because the I/O cost of actually accessing the free block after we find it
   dominates for performance purposes.
</p>
<p>
   To set up a free block bitmap,
   we reserve a contiguous region of space on the disk
   large enough to hold one bit for each disk block.
   For example, since our file system uses 4096-byte blocks,
   each bitmap block contains 4096*8=32768 bits,
   or enough bits to describe 32768 disk blocks.
   In other words, for every 32768 disk blocks the file system uses,
   we must reserve one disk block for the block bitmap.
   A given bit in the bitmap is set if the corresponding block is free,
   and clear if the corresponding block is in use.
   The block bitmap in our file system
   always starts at disk block 2,
   immediately after the superblock.
   For simplicity we will reserve enough bitmap blocks to hold one bit
   for each block in the entire disk,
   including the blocks containing the superblock and the bitmap itself.
   We will simply make sure that the bitmap bits
   corresponding to these special, "reserved" areas of the disk
   are always clear (marked in-use).
</p>
<h3>File Meta-data</h3>
<p>
   <img src="file.png" style="float:right" alt="File structure" />
   The layout of the meta-data describing a file in our file system is
   described by <code>struct File</code> in <tt>inc/fs.h</tt>.  This
   meta-data includes the file's name, size, type (regular file or
   directory), and pointers to the blocks comprising the file. As
   mentioned above, we do not have inodes, so this meta-data is stored in
   a directory entry on disk.  Unlike in most "real" file systems, for
   simplicity we will use this one <code>File</code> structure to
   represent file meta-data as it appears
   <i>both on disk and in memory</i>.
</p>
<p>
   The <code>f_direct</code> array in <code>struct File</code> contains space
   to store the block numbers
   of the first 10 (<code>NDIRECT</code>) blocks of the file,
   which we call the file's <i>direct</i> blocks.
   For small files up to 10*4096 = 40KB in size,
   this means that the block numbers of all of the file's blocks
   will fit directly within the <code>File</code> structure itself.
   For larger files, however, we need a place
   to hold the rest of the file's block numbers.
   For any file greater than 40KB in size, therefore,
   we allocate an additional disk block, called the file's <i>indirect block</i>,
   to hold up to 4096/4 = 1024 additional block numbers.
   Our file system therefore allows files to be up to 1034 blocks,
   or just over four megabytes, in size.
   To support larger files,
   "real" file systems typically support
   <i>double-</i> and <i>triple-indirect blocks</i> as well.
</p>
<h3>Directories versus Regular Files</h3>
<p>
   A <code>File</code> structure in our file system
   can represent either a <i>regular</i> file or a directory;
   these two types of "files" are distinguished by the <code>type</code> field
   in the <code>File</code> structure.
   The file system manages regular files and directory-files
   in exactly the same way,
   except that it does not interpret the contents of the data blocks
   associated with regular files at all,
   whereas the file system interprets the contents
   of a directory-file as a series of <code>File</code> structures
   describing the files and subdirectories within the directory.
</p>
<p>
   The superblock in our file system
   contains a <code>File</code> structure
   (the <code>root</code> field in <code>struct Super</code>)
   that holds the meta-data for the file system's root directory.
   The contents of this directory-file
   is a sequence of <code>File</code> structures
   describing the files and directories located
   within the root directory of the file system.
   Any subdirectories in the root directory
   may in turn contain more <code>File</code> structures
   representing sub-subdirectories, and so on.
</p>
<h1>The File System</h1>
<p>
   The goal for this lab is not to have you implement the
   entire file system, but for you to implement only certain key
   components. In particular, you will be responsible for reading blocks
   into the block cache and flushing them back to disk; allocating disk
   blocks; mapping file offsets to disk blocks; and implementing read,
   write, and open in the IPC interface.  Because you will not be
   implementing all of the file system yourself, it is very important
   that you familiarize yourself with the provided code and the various
   file system interfaces.
</p>
<h2>Disk Access</h2>
<p>
   The file system environment in our operating system
   needs to be able to access the disk,
   but we have not yet implemented any disk access functionality in our kernel.
   Instead of taking the conventional "monolithic" operating system strategy
   of adding an IDE disk driver to the kernel
   along with the necessary system calls to allow the file system to access it,
   we will instead implement the IDE disk driver
   as part of the user-level file system environment.
   We will still need to modify the kernel slightly,
   in order to set things up so that the file system environment
   has the privileges it needs to implement disk access itself.
</p>
<p>
   It is easy to implement disk access in user space this way
   as long as we rely on polling, "programmed I/O" (PIO)-based disk access
   and do not use disk interrupts.
   It is possible to implement interrupt-driven device drivers in user mode as well
   (the L3 and L4 kernels do this, for example),
   but it is more difficult
   since the kernel must field device interrupts
   and dispatch them to the correct user-mode environment.
</p>
<p>
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
<p>
   In the tests that follow, if you fail a test, <tt>obj/fs/fs.img</tt>
   is likely to be left inconsistent.  Be sure to remove it before running
   <kbd>make grade</kbd> or <kbd>make qemu</kbd>.
</p>
<div class="required">
   <p><span class="header">Exercise 1.</span>
      <code>i386_init</code> identifies the file system environment by
      passing the type <code>ENV_TYPE_FS</code> to your environment creation
      function, <code>env_create</code>.
      Modify <code>env_create</code> in <tt>env.c</tt>,
      so that it gives the file system environment I/O privilege,
      but never gives that privilege to any other environment.
   </p>
   <p>
      Make sure you can start the file environment without causing a General
      Protection fault.  You should pass the "fs i/o" test in <kbd>make grade</kbd>.
   </p>
</div>
<p>
   Do you have to do anything else
   to ensure that this I/O privilege setting
   is saved and restored properly when you subsequently switch
   from one environment to another?
   Make sure you understand how this environment state is handled.
</p>
<p>
   Read through the files in the new <tt>fs</tt> directory in the source tree.
   The file <tt>fs/ide.c</tt> implements our minimal PIO-based disk driver.
   The file <tt>fs/serv.c</tt> contains the <code>umain</code> function
   for the file system environment.
</p>
<p>
   Note that the <tt>GNUmakefile</tt> file in this lab
   sets up QEMU to use the file <tt>obj/kern/kernel.img</tt>
   as the image for disk 0 (typically "Drive C" under DOS/Windows) as before,
   and to use the (new) file <tt>obj/fs/fs.img</tt>
   as the image for disk 1 ("Drive D").
   In this lab your file system should only ever touch disk 1;
   disk 0 is used only to boot the kernel.
   If you manage to corrupt either disk image in some way,
   you can reset both of them to their original, "pristine" versions
   simply by typing:
</p>
<pre>$ <kbd>rm obj/kern/kernel.img obj/fs/fs.img</kbd>
$ <kbd>make</kbd>

</pre>
<p>or by doing: </p>
<pre>$ <kbd>make clean</kbd>
$ <kbd>make</kbd>
</pre>
<!--<div class="challenge">
   <p><span class="header">Challenge 1!</span> (5 points)
      Implement interrupt-driven IDE disk access,
      with or without DMA.
      You can decide whether to move the device driver into the kernel,
      keep it in user space along with the file system,
      or even (if you really want to get into the micro-kernel spirit)
      move it into a separate environment of its own.
   </p>
</div>-->
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
   up to 0xD0000000 (<code>DISKMAP+DISKSIZE</code>),
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
   may still be reasonable on a machine with a 64-bit address space,
   such as Intel's Itanium or AMD's Athlon 64 processors.
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
      Implement the <code>bc_pgfault</code> and <code>flush_block</code>
      functions in <tt>fs/bc.c</tt>.
      <code>bc_pgfault</code> is a page fault handler, just like the one
      your wrote in the previous lab for copy-on-write fork, except that
      its job is to load pages in from the disk in response to a page
      fault.  When writing this, keep in mind that (1) <code>addr</code>
      may not be aligned to a block boundary and (2) <code>ide_read</code>
      operates in sectors, not blocks.
   </p>
   <p>
      The <code>flush_block</code> function should write a block out to disk
      <i>if necessary</i>.  <code>flush_block</code> shouldn't do anything
      if the block isn't even in the block cache (that is, the page isn't
      mapped) or if it's not dirty.
      We will use the VM hardware to keep track of whether a disk
      block has been modified since it was last read from or written to disk.
      To see whether a block needs writing,
      we can just look to see if the <code>PTE_D</code> "dirty" bit
      is set in the <code>uvpt</code> entry.
      (The <code>PTE_D</code> bit is set by the processor in response to a
      write to that page; see 5.2.4.3 in <a
         href="ref/i386/s05_02.htm">chapter
      5</a> of the 386 reference manual.)
      After writing the block to disk, <code>flush_block</code> should clear
      the <code>PTE_D</code> bit using <code>sys_page_map</code>.
   </p>
   <p>
      Use <kbd>make grade</kbd> to test your code.  Your code should pass
      "check_bc", "check_super", and "check_bitmap".
   </p>
</div>
<p>
   The <code>fs_init</code> function in <tt>fs/fs.c</tt> is a prime
   example of how to use the block cache.  After initializing the block
   cache, it simply stores pointers into the disk map region in the
   <code>super</code> and <code>bitmap</code> global variables.  After
   this point, we can simply read from these structures as if they were
   in memory and our page fault handler will read them from disk as
   necessary.
</p>
<!--<div class="challenge">
   <p><span class="header">Challenge 2!</span> (5 points)
      The block cache has no eviction policy.  Once a block gets faulted in
      to it, it never gets removed and will remain in memory forevermore.
      Add eviction to the buffer cache.  Using the <code>PTE_A</code>
      "accessed" bits in the page tables, you can track approximate usage of
      disk blocks without the need to modify every place in the code that
      accesses the disk map region.
   </p>
</div>-->
<h2>The Block Bitmap</h2>
<p>
   After <code>fs_init</code> sets the <code>bitmap</code> pointer, we
   can treat <code>bitmap</code> as a packed array of bits, one for each
   block on the disk.  See, for example, <code>block_is_free</code>,
   which simply checks whether a given block is marked free in the
   bitmap.
</p>
<div class="required">
   <p><span class="header">Exercise 3.</span>
      Use <code>free_block</code> as a model to
      implement <code>alloc_block</code>, which should find a free disk
      block in the bitmap, mark it used, and return the number of that
      block.
      When you allocate a block, you should immediately flush
      the changed bitmap block to disk with <code>flush_block</code>, to
      help file system consistency.
   </p>
   <p>
      Use <kbd>make grade</kbd> to test your code.  Your code should now
      pass "alloc_block".
   </p>
</div>
<h2>File Operations</h2>
<p>
   We have provided a variety of functions in <tt>fs/fs.c</tt>
   to implement the basic facilities you will need
   to interpret and manage <code>File</code> structures,
   scan and manage the entries of directory-files,
   and walk the file system from the root
   to resolve an absolute pathname.
   Read through <i>all</i> of the code in <tt>fs/fs.c</tt> <i>carefully</i>
   and make sure you understand what each function does
   before proceeding.
</p>
<div class="required">
   <p><span class="header">Exercise 4.</span>  Implement
      <code>file_block_walk</code>
      and <code>file_get_block</code>.  <code>file_block_walk</code> maps
      from a block offset within a file to the pointer for that block in the
      <code>struct File</code> or the indirect block, very much like what
      <code>pgdir_walk</code> did for page tables.
      <code>file_get_block</code> goes one step further and maps to the
      actual disk block, allocating a new one if necessary.
   </p>
   <p>
      Use <kbd>make grade</kbd> to test your code.  Your code should pass
      "file_open", "file_get_block", and "file_flush/file_truncated/file rewrite", and "testfile".
   </p>
</div>
<p>
   <code>file_block_walk</code> and <code>file_get_block</code> are the
   workhorses of the file system.  For example, <code>file_read</code>
   -and <code>file_write</code> are little more than the bookkeeping atop
   <code>file_get_block</code> necessary to copy bytes between scattered
   blocks and a sequential buffer.
</p>
<!--<div class="challenge">
   <p><span class="header">Challenge!</span> (20 points)
      The file system is likely to be corrupted if it gets
      interrupted in the middle of an operation (for example, by a
      crash or a reboot).
      Implement soft updates or journalling to make the file system
      crash-resilient and demonstrate some situation where the old
      file system would get corrupted, but yours doesn't.
   </p>
</div>-->
<h2>The File System Interface</h2>
<p>
   Now that we have implemented the necessary functionality
   within the file system environment itself,
   we must make it accessible to other environments
   that wish to use the file system.
   Since other environments can't directly call functions in the file
   system environment, we'll expose access to the file system
   environment via a <i>remote procedure call</i>, or RPC, abstraction,
   built atop JOS's IPC mechanism.
</p>
<p>
   Graphically, here's what a call to the file system server (say, read)
   looks like
</p>
<center>
   <table>
      <tr>
         <td>
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
         </td>
      </tr>
   </table>
</center>
<p>
   Everything below the dotted line is simply the mechanics of getting a
   read request from the regular environment to the file system
   environment.  Starting at the beginning, <code>read</code> (which we
   provide) works on any file descriptor and simply dispatches to the
   appropriate device read function, in this case
   <code>devfile_read</code> (we'll have more device types in future
   labs, like pipes and network sockets).  <code>devfile_read</code>
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
   function, and sending the result back via IPC.  The corresponding
   client code can be found in <tt>lib/file.c</tt>.  Here, the
   <code>fsipc</code> function handles the common details of sending some
   request to the server and receiving the reply.  The remaining
   functions wrap the available RPC's as regular C functions that handle
   bundling up arguments in the request structure, calling
   <code>fsipc</code>, and unpacking and returning the results.
</p>
<p>
   Recall that JOS's IPC mechanism lets an environment send a single
   32-bit number and, optionally, share a page.  To send a request from
   the client to the server, we use the 32-bit number for the request
   type (the file system server
   RPCs are numbered, just as how
   syscalls were numbered) and store the arguments to the request in a
   <code>union Fsreq</code> on the page shared via the IPC.  On the
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
   first place. Also, in its response, <code>FSREQ_OPEN</code> shares with
   the client a new "Fd page". We'll return to this RPC shortly.
</p>
<div class="required">
   <p><span class="header">Exercise 5.</span>
      Implement <code>serve_read</code> in <tt>fs/serv.c</tt> and
      <code>devfile_read</code> in <tt>lib/file.c</tt>.
   </p>
   <p>
      <code>serve_read</code>'s heavy lifting will be done by
      the already-implemented <code>file_read</code> in <tt>fs/fs.c</tt> (which, in turn, is just a bunch of calls to
      <code>file_get_block</code>).  <code>serve_read</code> just has to
      provide the RPC interface for file reading.  Look at the comments and
      code in <code>serve_stat</code> to get a general idea of how the
      server functions should be structured.
   </p>
   <p>
      Likewise, <code>file_read</code> should pack its arguments into
      <code>fsipcbuf</code> for <code>serve_read</code>, call
      <code>fsipc</code>, and handle the result.
   </p>
   <p>
      Your code should pass
      "serve_open/file_stat/file_close" and "file_read".
   </p>
</div>
<div class="required">
   <p><span class="header">Exercise 6.</span>
      Implement <code>serve_write</code> in <tt>fs/serv.c</tt> and
      <code>devfile_write</code> in <tt>lib/file.c</tt>.
   </p>
   <p>
      Use <kbd>make grade</kbd> to test your code.  Your code should pass
      "file_write", "file_read after file_write", "open", and "large file".
   </p>
</div>
<h2>Client-Side File Operations</h2>
<p>
   The functions in <tt>lib/file.c</tt> are specific to on-disk files,
   but UNIX file descriptors are a more general notion that also
   encompasses pipes, console I/O, etc.  In JOS, each of these device
   types has (or will have in later labs) a corresponding <code>struct
   Dev</code>, with pointers to the functions that implement
   read/write/etc. for that device type.  <tt>lib/fd.c</tt> implements the
   general UNIX-like file descriptor interface on top of this.  Each
   <code>struct Fd</code> indicates its device type, and most of the
   functions in <tt>lib/fd.c</tt> simply dispatch operations to functions
   in the appropriate <code>struct Dev</code>.
</p>
<p>
   <tt>lib/fd.c</tt> also maintains the <i>file descriptor table</i>
   region in each application environment's address space, starting at
   <code>FDTABLE</code>.  This area reserves one page's worth (4KB) of
   address space for each of the up to <code>MAXFD</code> (currently 32)
   file descriptors that the application can have open at once.  At any given
   time, a particular file descriptor table page is mapped if and only if
   the corresponding file descriptor is in use.  Each file descriptor
   also has an optional "data page" in the region starting at
   <code>FILEDATA</code>, though we won't use that until later labs.
</p>
<p>
   For nearly all interactions with files, user code should go through
   the functions in <tt>lib/fd.c</tt>.  The one "public" function in
   <tt>lib/file.c</tt> is <code>open</code>, which constructs a new file
   descriptor by opening a named on-disk file.
</p>
<div class="required">
   <p><span class="header">Exercise 7.</span>
      Implement <code>open</code>.
      The <code>open</code> function must find an unused file descriptor
      using the <code>fd_alloc()</code> function we have provided, make an IPC
      request to the file system environment to open the file, and return
      the number of the allocated file descriptor.  Be sure your code fails
      gracefully if the maximum number
      of files are already open, or if any of the IPC requests to the file
      system environment fails.
   </p>
   <p>
      Use <kbd>make grade</kbd> to test your code.  Your code should pass all file system tests
      at this point.
   </p>
   </p>
</div>
<!--
<div class="challenge">
   <p><span class="header">Challenge!</span> (5 points)
      Change the file system
      to keep most file meta-data in Unix-style inodes
      rather than in directory entries,
      and add support for hard links.
   </p>
</div>-->
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
   <p><span class="header">Exercise 8.</span>
      <code>spawn</code> relies on the new syscall
      <code>sys_env_set_trapframe</code> to initialize the state of the
      newly created environment.
      Test your code by running the
      <tt>user/spawnhello</tt> program
      from <tt>kern/init.c</tt>, which will attempt to
      spawn <tt>/bin/hello</tt> from the file system.
   </p>
   <p>
      Use <kbd>make grade</kbd> to test your code.
   </p>
</div>
<!--<div class="challenge">
   <p><span class="header">Challenge!</span> (5 points)
      Implement Unix-style <code>exec</code>.
   </p>
</div>
<div class="challenge">
   <p><span class="header">Challenge!</span> (5 points)
      Implement <code>mmap</code>-style memory-mapped files and
      modify <code>spawn</code> to map pages directly from the ELF
      image when possible.
   </p>
</div>-->
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
   <p><span class="header">Exercise 9.</span>
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
   </p>
</div>
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
   <p><span class="header">Exercise 10.</span>
      In your <tt>kern/trap.c</tt>, call <code>kbd_intr</code> to handle trap
      <code>IRQ_OFFSET+IRQ_KBD</code> and <code>serial_intr</code> to
      handle trap <code>IRQ_OFFSET+IRQ_SERIAL</code>.
   </p>
</div>
<p>
   We implemented the console input/output file type for you,
   in <tt>lib/console.c</tt>.  <code>kbd_intr</code> and <code>serial_intr</code>
   fill a buffer with the recently read input while the console file
   type drains the buffer (the console file type is used for stdin/stdout by
   default unless the user redirects them).
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
   grade your submission with <kbd>make grade</kbd>.
</p>
<h3>Hand-In Procedure</h3>
<p>As with prior labs, you need to create a file in the top-level directory of your code
   named <tt>gitinfo.txt</tt>.  This file should have precisely two lines: one with the repository name,
   and one with the branch you wish to submit.  For example, if your team repo is <tt>jos-dontest</tt> and you are submitting
   the <tt>lab5</tt> branch, your <tt>gitinfo.txt</tt> file should look like ths:
</p>
<pre>
https://github.com/comp790-s20/jos-dontest/
lab5
</pre>
<p>Make sure you add and push this file to github.</p>
<p>Then, you will go to gradescope for the lab assignment, and submit via github.  After a few minutes, you should be able to see the results of the autograder and confirm it matches what you expect.  Let course staff know ASAP if there is an issue.</p>
<p>This completes the lab.</p>
