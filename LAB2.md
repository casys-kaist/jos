<h2>Introduction</h2>

<p>
In this lab, you will write the memory management code for your
operating system. Memory management has two components.
</p>

<p>
The first component is a physical memory allocator for the kernel,
so that the kernel can allocate memory and later free it.
Your allocator will operate in units of 4096 bytes, called
<i>pages</i>.
Your task will be to maintain data structures that record
which physical pages are free and which are
allocated, and how many processes are sharing
each allocated page.  You will also write the routines to allocate and
free pages of memory.
</p>

<p>
The second component of memory management is <i>virtual memory</i>,
which maps the virtual addresses used by kernel and user software
to addresses in physical memory.
The amd64 hardware's memory management unit (MMU) performs the
mapping when instructions use memory, consulting a
set of page tables.
You will modify JOS to set up the MMU's page tables
according to a specification we provide.
</p>


<h3>Getting started</h3>

<p>
In this and future labs you will progressively build up your kernel.
We will also provide you with some additional source.
To fetch that source, use Git to commit your Lab 1 source,
fetch the latest version of the course repository,
and then
create a local branch called <tt>lab2</tt> based on our lab2
branch, <tt>origin/lab2</tt>:
</p>
<pre>
kermit% <kbd>cd lab</kbd>
kermit% <kbd>git commit -am 'my solution to lab1'</kbd>
Created commit 254dac5: my solution to lab1
 3 files changed, 31 insertions(+), 6 deletions(-)
kermit% <kbd>git pull</kbd>

Already up-to-date.
kermit% <kbd>git checkout -b lab2 origin/lab2</kbd>
Branch lab2 set up to track remote branch refs/remotes/origin/lab2.
Switched to a new branch "lab2"
kermit% 
</pre>

<p>
The <kbd>git checkout -b</kbd> command shown above actually does two
things: it first creates a local branch <tt>lab2</tt> that is
based on the <tt>origin/lab2</tt> branch provided by the course
staff, and second, it changes the contents of your <tt>lab</tt>

directory to reflect the files stored on the <tt>lab2</tt> branch.
Git allows switching between existing branches using <kbd>git
checkout <i>branch-name</i></kbd>, though you should commit any
outstanding changes on one branch before switching to a different
one.
</p>

<p>
You will now need to merge the changes you made in your <tt>master</tt> (lab1)
branch into the <tt>lab2</tt> branch, as follows:

</p>
<pre>
kermit% <kbd>git merge master</kbd>
Merge made by recursive.
 kern/kdebug.c  |   11 +++++++++--
 kern/monitor.c |   19 +++++++++++++++++++
 lib/printfmt.c |    7 +++----
 3 files changed, 31 insertions(+), 6 deletions(-)
kermit% 
</pre>
<p>
In some cases, Git may not be able to figure out how to merge your changes with
the new lab assignment (e.g. if you modified some of the code that
is changed in the second lab assignment).  In that case, the <kbd>git
merge</kbd> command will tell you which files are <i>conflicted</i>,
and you should first resolve the conflict (by editing the relevant files)
and then commit the resulting files with <kbd>git commit -a</kbd>.
</p>

<p>
Lab 2 contains the following new source files,
which you should browse through:
</p>
<ul>
<li>	<tt>inc/memlayout.h</tt></li>
<li>	<tt>kern/pmap.c</tt></li>
<li>	<tt>kern/pmap.h</tt></li>
<li>	<tt>kern/kclock.h</tt></li>

<li>	<tt>kern/kclock.c</tt></li>

</ul>

<p>
<tt>memlayout.h</tt> describes the layout of the virtual
address space that you must implement by modifying <tt>pmap.c</tt>.
<tt>memlayout.h</tt> and <tt>pmap.h</tt> define the PageInfo
structure that you'll use to keep track of which pages of
physical memory are free.

<tt>kclock.c</tt> and <tt>kclock.h</tt>
manipulate
the PC's battery-backed clock and CMOS RAM hardware,
in which the BIOS records the amount of physical memory the PC contains,
among other things.
The code in <tt>pmap.c</tt> needs to read this device hardware
in order to figure out how much physical memory there is,
but that part of the code is done for you:
you do not need to know the details of how the CMOS hardware works.
</p>

<p>
Pay particular attention to <tt>memlayout.h</tt> and <tt>pmap.h</tt>,
since this lab requires you to use and understand many of the
definitions they contain.  You may want to review<tt>inc/mmu.h</tt>,
too, as it also contains a number of definitions that will be useful
for this lab.

</p>


<h2>Part 1: Physical Page Management</h2>

<p>
The operating system must keep track of
which parts of physical RAM are free
and which are currently in use.
JOS manages the PC's physical memory
with <i>page granularity</i>
so that it can use the MMU to map and protect each
piece of allocated memory.
</p>

<p>

    JOS is "told" the amount of physical memory it has by the
    bootloader. JOS's bootloader passes the kernel a multiboot info
    structure which possibly contains the physical memory map of the
    system. The memory map may exclude regions of memory that are in use
    for reasons including IO mappings for devices (e.g., the "memory hole"), space
    reserved for the BIOS, or physically damaged memory.
    For more details on how this structure looks and what it
    contains, refer to the <a
    href="http://www.gnu.org/software/grub/manual/multiboot/multiboot.html">specification</a>. A
    typical physical memory map for a PC with 10 GB of memory looks
    like below.

    <pre>e820 MEMORY MAP
	address: 0x0000000000000000, length: 0x000000000009f400, type: USABLE
	address: 0x000000000009f400, length: 0x0000000000000c00, type: RESERVED
	address: 0x00000000000f0000, length: 0x0000000000010000, type: RESERVED
	address: 0x0000000000100000, length: 0x00000000dfefd000, type: USABLE
	address: 0x00000000dfffd000, length: 0x0000000000003000, type: RESERVED
	address: 0x00000000fffc0000, length: 0x0000000000040000, type: RESERVED
	address: 0x0000000100000000, length: 0x00000001a0000000, type: USABLE</pre>
</p>

<p>
You'll now write the physical page allocator.  It keeps track of which
pages are free with a linked list of <code>struct PageInfo</code> objects,
each corresponding to a physical page.  You need to write the physical
page allocator before you can write the rest of the virtual memory
implementation, because your page table management code will need to
allocate physical memory in which to store page tables.

</p>

<div class="required">
<p><span class="header">Exercise 1.</span>
	In the file <tt>kern/pmap.c</tt>,
	you must implement code for the following functions.</p>

	<pre>
	boot_alloc()
	page_init()
	page_alloc()
	page_free()</pre>
        <p>

        You also need to add some code to <code>x64_vm_init()</code>
        in <tt>pmap.c</tt>, as indicated by comments there. For now,
        just add the code needed before the call to <code>check_page_alloc()</code>.
        </p>
        <p>
        You probably want to work on <code>boot_alloc()</code>,
        then <code>x64_vm_init()</code>,
        then
	<code>page_init()</code>,
	<code>page_alloc()</code>, and
	<code>page_free()</code>.
        </p>

	<p>
	<code>check_page_alloc()</code> tests your physical page allocator.
        You should boot JOS and see whether <code>check_page_alloc()</code>
        reports success. Fix your code so that it passes. You may find it
        helpful to add your own <code>assert()</code>s to verify that
        your assumptions are correct.
</p></div>

<p>
This lab, and all the labs, will require you to do a bit of
detective work to figure out exactly what you need to do. This
assignment does not describe all the details of the code you'll have
to add to JOS.  Look for comments in the parts of the JOS source that
you have to modify; those comments often contain specifications and
hints.  You will also need to look at related parts of JOS, at the
Intel manuals, and perhaps at your notes from previous Operating Systems
courses.</p>

<h2>Part 2: Virtual Memory</h2>

<!--
<p><i> Aside: Contrast this to the VM layout for version 7 Unix on the
PDP/11-40.  You will recall from lecture, that in v7, the kernel and
each user process each have their own address spaces.
</i>
-->

<p>
Before doing anything else,
familiarize yourself with the AMD64's
long-mode memory management architecture:
namely <i>segmentation</i> and <i>page translation</i>.
</p>

<div class="required">
<p><span class="header">(self study)Exercise 2.</span>
	Read chapters 4 and 5 of the
	<a href="ref/amd64/AMD64_Architecture_Programmers_Manual.pdf
    ">

	AMD64 Architecture Programmer's Reference Manual</a>,
	if you haven't done so already.
	Read the sections about page
	translation and page-based protection closely (5.1).
	Although JOS relies most heavily on page translation,
	you will also need a basic understanding
	of how segmentation works in long mode
	to understand what's going on in JOS.
</p></div>

<h3>Virtual, Linear, and Physical Addresses</h3>

<p>
In AMD64 terminology,
a <i>virtual address</i>
consists of a segment selector and an offset within the segment.
A <i>linear address</i>
is what you get after segment translation but before page translation.
A <i>physical address</i>
is what you finally get after both segment and page translation and
what ultimately goes out on the hardware bus to your RAM.
Be sure you understand the difference
between these three types or "levels" of addresses!
</p>

<table style="margin: auto;"><tr><td>
<pre>
           Selector  +--------------+         +-----------+
          ---------->|              |         |           |
                     | Segmentation |         |  Paging   |
Software             |              |-------->|           |---------->  RAM
            Offset   |  Mechanism   |         | Mechanism |
          ---------->|              |         |           |
                     +--------------+         +-----------+
            Virtual                   Linear                Physical
</pre>
</td></tr></table>

<p>
A C pointer is the "offset" component of the virtual address.
In <tt>kern/bootstrap.S</tt>, we installed a Global Descriptor Table (GDT)
that effectively disabled segment translation by setting all segment
base addresses to 0 and limits to <code>0xffffffff</code>.  Hence the
"selector" has no effect and the linear address always equals the
offset of the virtual address.  In lab 3,
we'll have to interact a little more with segmentation to set up
privilege levels, but as for memory translation, we can
ignore segmentation throughout the JOS labs and focus solely on page
translation.
</p>

<!--
<p>
Recall that in kern/bootstrap.S of lab 1, we installed a simple page table 
in so that the kernel could run at its link address of 0x8004100000,
even though it is actually loaded in physical memory
just above the ROM BIOS at 0x00100000.  This page table mapped first 3GB
of memory(VA=PA)and upper 256 MB of memory (VA-KERNBASE=PA).  
Now we need to implement a set of page tables in C that JOS will manage.
</p>

<p>
Our page tables will differ from the bootloader's simple page tables
in several ways. 
Most notably, 
we will use a 4 KB page size.  For simplicity, the bootloader
        used a 2 MB page table.  As a result, in <tt> boot1/head64.S</tt>,
     the bootloader's page tables 
     have level-4 (PML4), level-3 (PDPE)
     and level-2 (pgdir) but skip the last level of translation, i.e., the page table. 
     We will need to use four levels of translation in order to use a smaller
     page size of 4 KB.  Note that there is a trade-off between
     the granularity of the page size and the space overhead of the page tables.
</p>
-->

<div class="required">
<p><span class="header">(Self study)Exercise 3.</span>
	While GDB can only access QEMU's memory by virtual address,
	it's often useful to be able to inspect physical memory while
	setting up virtual memory.  Review the QEMU <a
	href="tools.html#qemu">monitor
	commands</a> from the lab tools guide, especially the
	<tt>xp</tt> command, which lets
	you inspect physical memory.  To access the QEMU monitor,
	press <kbd>Ctrl-a c</kbd> in the terminal (the same binding
	returns to the serial console).
	</p>

	<p>Use the <kbd>xp</kbd> command in the QEMU monitor and the
	<kbd>x</kbd> command in GDB to inspect memory at corresponding
	physical and virtual addresses and make sure you see the same
	data.</p>

	<p>Our patched version of QEMU provides an <kbd>info pg</kbd>
	command that may also prove useful: it shows a compact but
	detailed representation of the current page tables, including
	all mapped memory ranges, permissions, and flags.  Stock QEMU
	also provides an <kbd>info mem</kbd> command that shows an
	overview of which ranges of virtual memory are mapped
	and with what permissions.
</p></div>

<p>From code executing on the CPU, once we're in protected/long mode, there's no way to
directly use a linear or physical address.  <i>All</i> memory
references are interpreted as virtual addresses and translated by the
MMU, which means all pointers in C are virtual addresses.</p>

<p>The JOS kernel often needs to manipulate addresses as opaque values
or as integers, without dereferencing them, for example in the
physical memory allocator.  Sometimes these are virtual addresses,
and sometimes they are physical addresses.  To help document the code, the
JOS source distinguishes the two cases: the
type <code>uintptr_t</code> represents virtual addresses,
and <code>physaddr_t</code> represents physical addresses.  Both these
types are really just synonyms for 64-bit integers
(<code>uint64_t</code>), so the compiler won't stop you from assigning
one type to another! Since they are integer types (not pointers), the
compiler <i>will</i> complain if you try to dereference them.</p>

<p>

The JOS kernel can dereference a <code>uintptr_t</code> by first
casting it to a pointer type. In contrast,
the kernel can't sensibly dereference a physical
address, since the MMU translates all memory references.
If you cast a <code>physaddr_t</code> to a pointer and dereference it,
you may be able to load and store to the resulting address (the hardware
will interpret it as a virtual address), but you probably won't
get the memory location you intended.</p>

<p>
To summarize:</p>

<table style="margin: auto;">
<tr><th>C type</th><th>Address type</th></tr>

<tr><td><code>T*</code>&nbsp;&nbsp;</td><td>Virtual</td></tr>
<tr><td><code>uintptr_t</code>&nbsp;&nbsp;</td><td>Virtual</td></tr>
<tr><td><code>physaddr_t</code>&nbsp;&nbsp;</td><td>Physical</td></tr>
</table>

<p></p>

<div class="question">
<p><span class="header">Question</span></p>
  <ol><li>Assuming that the
following JOS kernel code is correct, what type
should variable <code>x</code> have, <code>uintptr_t</code> or

<code>physaddr_t</code>?

<pre>
	<i>mystery_t</i> x;
	char* value = return_a_pointer();
	*value = 10;
	x = (<i>mystery_t</i>) value;</pre></li>
</ol></div>


<p>
In Part 3 of Lab 1 we noted that
the kernel's first step is to set up simple segmentation and paging (in kern/bootstrap.S)
so that the kernel runs at its link address of 0x8004100000,
even though it is actually loaded in physical memory
just above the ROM BIOS at 0x00100000.
In other words,
the kernel's <i>virtual</i> starting address at this point is 0x8004100000,
but its <i>physical</i> starting address
is 0x00100000.
The kernel's virtual and linear addresses are same because of the
flat segmentation hardware in AMD64, while its linear and physical addresses differ
because of the paging hardware (Remember we mapped the upper 256 MB 0xf000000 through
0xffffffff back to 0x0 through 0xfffffff)

</p>
<!---
<p>
In the virtual memory layout you are going to rewrite the page tables in C.
As mentioned before this will be needed in some of the system-calls you 
will be writing in Lab 4. It also serves the purpose of relocating your
page tables above 1 MB physical memory where the JOS kernel resides. 

</p>
--!>
<!--
<p>
In the virtual memory layout you are going to set up for JOS in this
lab, we will switch from using the x86 segmentation hardware for
virtual memory to using page translation instead.  Using page
translation, we will accomplish the same virtual memory layout we
currently use segmentation for, plus much more.  While we can't
actually disable the segmentation hardware, we will stop using it for
anything interesting, effectively disabling it by giving it segments
with zero offsets.  After you finish this lab
and the JOS kernel successfully enables paging and "disables"
segmentation, the kernel's virtual and linear addresses will be the
same, while its linear and physical addresses will differ because of
page translation.
</p>
-->

<p>
However, the JOS kernel sometimes needs to read or modify memory for which it
only knows the physical address. For example, adding a mapping to a
page table may require allocating physical memory to store a page
directory and then initializing that memory.  However, the kernel,
like any other software, cannot bypass virtual memory translation and thus
cannot directly load and store to physical addresses. One reason JOS
remaps of all of physical memory starting from physical address 0 at
virtual address
0x8004000000 is to help the kernel read and write memory
for which it knows just the physical address.  In order to translate a
physical address into a virtual address that the kernel can actually
read and write, the kernel must add 0x8004000000 to the
physical address to find its corresponding virtual address in the
remapped region. You should use <code>KADDR(pa)</code> to do that
addition.
</p>

<p>
The JOS kernel also sometimes needs to be able to find a physical
address given the virtual address of the memory in which a kernel data
structure is stored.  The
kernel addresses its global variables and memory that
<code>boot_alloc()</code> allocates, with addresses in the region
where the kernel was loaded, starting at
0x8004000000, the
very region where we mapped all of physical memory.
Thus, to turn a virtual address in this region into a physical
address, the kernel can simply
subtract 0x8004000000. You should use <code>PADDR(va)</code>
to do that subtraction.
</p>

<h3>Reference counting</h3>

<p>
In future labs you will often have the same physical page mapped at
multiple virtual addresses simultaneously (or in the address spaces of
multiple environments).  You will keep a count of the number of
references to each physical page in the <code>pp_ref</code> field of
the <code>struct PageInfo</code> corresponding to the physical page.  When
this count goes to zero for a physical page, that page can be freed
because it is no longer used.  In general, this count should equal to the
number of times the physical page appears <em>below
<code>UTOP</code></em> in all page tables (the mappings above
<code>UTOP</code> are mostly set up at boot time by the kernel and
should never be freed, so there's no need to reference count them).
We'll also use it to keep track of the number of pointers we keep to
the page directory pages and, in turn, of the number of references the
page directories have to page table pages.
</p>

<p>
Be careful when using <tt>page_alloc</tt>.  The page it returns will
always have a reference count of 0, so <tt>pp_ref</tt> should be
incremented as soon as you've done something with the returned page
(like inserting it into a page table).  Sometimes this is handled by
other functions (for example, <tt>page_insert</tt>) and sometimes the
function calling <tt>page_alloc</tt> must do it directly.
</p>


<h3>Page Table Management</h3>

<p>
Now you'll write a set of routines to manage page tables: to insert
and remove linear-to-physical mappings, and to create page table pages
when needed.
</p>

<div class="required">
<p><span class="header">Exercise 4.</span>
	In the file <tt>kern/pmap.c</tt>,
	you must implement code for the following functions.</p>

	<pre>
        pml4e_walk()
        pdpe_walk()
        pgdir_walk()
        boot_map_region()
        page_lookup()
        page_remove()
        page_insert()
	</pre>
        <p>

	<code>page_check()</code>, called from <code>x64_vm_init()</code>,
        tests your page table management routines.
        You should make sure it reports success before proceeding.
</p></div>

<h2>Part 3: Kernel Address Space</h2>

<p>
JOS divides the processor's linear address space
into two parts.
User environments (processes),
which we will begin loading and running in lab 3,
will have control over the layout and contents of the lower part,
while the kernel always maintains complete control over the upper part.
The dividing line is defined somewhat arbitrarily
by the symbol <code>ULIM</code> in <tt>inc/memlayout.h</tt>,
reserving approximately 256MB of linear (and therefore virtual) address space
for the kernel.

</p>

<p>
You'll find it helpful to refer to the JOS memory layout diagram in
<tt>inc/memlayout.h</tt> both for this part and for later labs.
</p>


<h3>Permissions and Fault Isolation</h3>

<p>
Since kernel and user memory
are both present in each environment's address space,
we will have to use permission bits in our amd64 page tables to
allow user code access only to the user part of the address space.
Otherwise bugs in user code might overwrite kernel data,
causing a crash or more subtle malfunction;
user code might also be able to steal other environments' private data.
</p>

<p>The user environment will have no permission to any of the
memory above <code>ULIM</code>, while the kernel will be able to
read and write this memory.  For the address range
<code>(UTOP,ULIM]</code>, both the kernel and the user environment have
the same permission: they can read but not write this address range.
This range of address is used to expose certain kernel data structures
read-only to the user environment.  Lastly, the address space below
<code>UTOP</code> is for the user environment to use; the user environment
will set permissions for accessing this memory.

</p>

<h3>Initializing the Kernel Address Space</h3>

<p>
Now you'll set up the address space above <code>UTOP</code>: the
kernel part of the address space.  <tt>inc/memlayout.h</tt> shows
the layout you should use.  You'll use the functions you just wrote to
set up the appropriate linear to physical mappings.
</p>

<div class="required">
<p><span class="header">Exercise 5.</span>

	Fill in the missing code in <code>x64_vm_init()</code> after the
        call to <code>page_check()</code>.</p>
	<p>
        Your code should now pass the <code>check_boot_pml4e()</code> check.
</p></div>

<p></p>

<div class="question">
<p><span class="header">Question</span></p>
<ol>
<li style="counter-reset: start 1"> What entries (rows) in the page directory have been filled in
     at this point for the 4th page directory pointer entry(Make sure you understand why 4th pdpe entry)?
     What addresses do they map and where do they point? In other words, fill out this table as much as possible:
     <table border="1">
     <tr><td align="center">Entry</td>
         <td align="center">Base Virtual Address</td>
         <td align="center">Points to (logically):</td></tr>

     <tr><td>511</td><td>?</td><td>Page table for top 2MB of phys
         memory</td></tr>
     <tr><td>510</td><td>?</td><td>?</td></tr>
     <tr><td align="center">.</td><td>?</td><td>?</td></tr>
     <tr><td align="center">.</td><td>?</td><td>?</td></tr>

     <tr><td align="center">.</td><td>?</td><td>?</td></tr>
     <tr><td>184</td><td>0xF0000000</td><td>?</td></tr>
     <tr><td>2</td><td>0x00800000</td><td>?</td></tr>
     <tr><td>1</td><td>0x00400000</td><td>?</td></tr>
     <tr><td>0</td><td>0x00000000</td><td>[see next question?]</td></tr>

     </table></li>
<!--     
<li> After <code>check_boot_pgdir()</code>,
     <code>i386_vm_init()</code> maps the first four MB of virtual
     address space to the first four MB of physical memory,
     then deletes this mapping at the end of the function.  Why is
     this mapping necessary? What would happen if it were omitted? Does this
     actually limit our kernel to be 4MB? What must be true if our
     kernel were larger than 4MB?</li>
-->
<li> We have placed the kernel and user environment
in the same address space.  Why will user programs not be able to
read or write the kernel's memory? What specific mechanisms protect
the kernel memory?</li>

<li> What is the maximum amount of physical memory that this operating
system can support? Why?</li>

<li> How much space overhead is there for managing memory, if we
actually had the maximum amount of physical memory? How is this
overhead broken down?</li>

<li> Read the simple page table setup code in <tt>kern/bootstrap.S</tt> . 
<br/>
	The bootloader tests whether the CPU supports long (64-bit) mode.
	It initializes a simple set of page tables for the first 4GB of memory.
	These pages map virtual addresses in the lowest 3GB to the same physical addresses,
	and then map the upper 256 MB back to the lowest 256 MB of memory.
	At this point, the bootloader places the CPU in long mode.
	Note that our bootloader transitioning to long mode isn't strictly necessary;
	typically, a bootloader only runs in long mode to load
	a 64-bit kernel at a high (>4 GB) virtual memory address.
	<br/>
	Note that once we transfer control to the kernel, the kernel
	assumes the CPU supports 64-bit mode.  Assuming the kernel was loaded 
	in the lower 4GB of virtual address space, 
	the kernel itself could test whether the CPU supports long mode
	and determine dynamically whether to run in 64 or 32-bit mode.
	Of course, this would substantially complicate the boot process.
<!--
Immediately after we turn on paging, RIP is still a low number (so as to run the 
rest of the 2nd phase boot loader in boot1/head64.S and boot1/main.c).
Remember in boot1/main.c we actually load the kernel from the ELF headers.
At what point do we transition to running at an RIP above KERNBASE? Is this
transition necessary? Why ?-->
</li>


<!--
<p> Is there a comparable mechanism on the PDP-11/40 which would
provide the fault isolation necessary to allow the kernel and the user
environment to run in the same address space?  (read: "same address space"
as "with the same set of PARs/PDRs")
-->

<!--
<li> What constraint does the placement of the kernel in the virtual
     address space place on the link address of user space programs?
     In particular, think about how kernel growth or different amounts
     of physical memory might affect available virtual address space.
-->
</ol>
</div>

<div class="challenge">
<p><span class="header">Challenge 1!</span> (10 bonus points)
	We consumed many physical pages to hold the
        page tables for the KERNBASE mapping.
	Do a more space-efficient job using the PTE_PS ("Page Size") bit
	in the page directory entries.
	You might want to refer to
	<a href="ref/amd64/AMD64_Architecture_Programmers_Manual.pdf">AMD64_Architecture_Programmers_Manual.pdf</a>.

</p></div>

<div class="challenge">
<p><span class="header">Challenge 2!</span> (1 bonus point each, up to 5 points)
	Extend the JOS kernel monitor with commands to:</p>
	<ul>
	<li>	Display in a useful and easy-to-read format
		all of the physical page mappings (or lack thereof)
		that apply to a particular range of virtual/linear addresses
		in the currently active address space.
		For example,
		you might enter <tt>'showmappings 0x3000 0x5000'</tt>
		to display the physical page mappings
		and corresponding permission bits
		that apply to the pages
		at virtual addresses 0x3000, 0x4000, and 0x5000.</li>

	<li>	Explicitly set, clear, or change the permissions
		of any mapping in the current address space.</li>
	<li>	Dump the contents of a range of memory
		given either a virtual or physical address range.
		Be sure the dump code behaves correctly
		when the range extends across page boundaries!</li>
	<li>	Do anything else that you think
		might be useful later for debugging the kernel.
		(There's a good chance it will be!)</li>
	</ul>
</div>


<h3>Address Space Layout Alternatives</h3>

<p>
The address space layout we use in JOS is not the only
one possible.
An operating system might
map the kernel at low linear addresses
while leaving the <i>upper</i> part of the linear address space
for user processes.
x86 kernels generally do not take this approach, however,
because one of the x86's backward-compatibility modes,
known as <i>virtual 8086 mode</i>,
is "hard-wired" in the processor
to use the bottom part of the linear address space,
and thus cannot be used at all if the kernel is mapped there.
</p>

<p>
It is even possible, though much more difficult,
to design the kernel so as not to have to reserve <i>any</i> fixed portion
of the processor's linear or virtual address space for itself,
but instead effectively to allow allow user-level processes
unrestricted use of the <i>entire</i> 4GB of virtual address space -
while still fully protecting the kernel from these processes
and protecting different processes from each other!

</p>

<div class="challenge">
<p><span class="header">Challenge 3!</span> (10 bonus points)
	Write up an outline of how a kernel could be designed
	to allow user environments unrestricted use
	of the full 4GB virtual and linear address space.
	Hint: the technique is sometimes known as
	"<i>follow the bouncing kernel</i>."
	In your design,
	be sure to address exactly what has to happen
	when the processor transitions between kernel and user modes,
	and how the kernel would accomplish such transitions.
	Also describe how the kernel
	would access physical memory and I/O devices in this scheme,
	and how the kernel would access
	a user environment's virtual address space
	during system calls and the like.
	Finally, think about and describe
	the advantages and disadvantages of such a scheme
	in terms of flexibility, performance, kernel complexity,
	and other factors you can think of.
</p></div>
<p></p>

<div class="challenge">
<p><span class="header">Challenge 4!</span> (10 bonus points)
	Since our JOS kernel's memory management system
	only allocates and frees memory on page granularity,
	we do not have anything comparable
	to a general-purpose <code>malloc</code>/<code>free</code> facility
	that we can use within the kernel.
	This could be a problem if we want to support
	certain types of I/O devices
	that require <i>physically contiguous</i> buffers
	larger than 4KB in size,
	or if we want user-level environments,
	and not just the kernel,
	to be able to allocate and map 4MB <i>superpages</i>

	for maximum processor efficiency.
	(See the earlier challenge problem about PTE_PS.)<br />
	</p>

	<p>
	Generalize the kernel's memory allocation system
	to support pages of a variety of power-of-two allocation unit sizes
	from 4KB up to some reasonable maximum of your choice.
	Be sure you have some way to divide larger allocation units
	into smaller ones on demand,
	and to coalesce multiple small allocation units
	back into larger units when possible.
	Think about the issues that might arise in such a system.
</p></div>

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
