<h2>Introduction</h2>
<p>
This lab is split into three parts.
The first part concentrates on getting familiarized
with x86 assembly language,
the QEMU x86 emulator,
and the PC's power-on bootstrap procedure.
The second part examines the boot loader for our CS 530 kernel,
which resides in the <tt>boot</tt> directory of the <tt>lab</tt> tree.
Finally, the third part delves into the initial template
for our CS 530 kernel itself,
named JOS,
which resides in the <tt>kernel</tt> directory.

</p>

<h3>Software Setup</h3>
<p>
The files you will need for this and subsequent lab assignments in this
course are distributed using the <a href="http://git-scm.com/">Git</a>
version control system.
</p>

<p>
Git is a powerful, but tricky, version control system.
We highly recommend taking time to understand git so that you will be comfortable using it during the 
labs.
We recommend the following resources to learn more about git:
<ol>
	<li> <a href="https://marklodato.github.io/visual-git-guide/index-en.html">A visual git reference</a>
This is a MUST READ. the easist one to explain who git works with good visual aid
<li> <a href="http://www.sbf5.com/~cduan/technical/git/">Understanding git conceptually</a>
This is a highly-recommended READ if you want to work on git smoothly. (You may 
skip the last part: Rebasing, for now)</li>
<!--
<li> <a href="http://try.github.com/levels/1/challenges/1">Quick 15-20 mins online exercise to get to know git.</a></li>
<li> <a href="http://www.kernel.org/pub/software/scm/git/docs/user-manual.html">Git
user's manual</a></li>
<li> If you are already familiar with other version control
systems, you may find this
<a href="http://eagain.net/articles/git-for-computer-scientists/">CS-oriented
overview of Git</a> useful.</li>
-->
</ol>
</p>

<p>
Each student (enrolled and on the waiting list) 
will be given access to a department system 
with the basic required software installed.  
You will have root access to this machine, and be able to install additional 
tools (editors, debuggers, etc) as you see fit.
</p>

<p>
You are also welcome to install the needed software on your own laptop.
The course staff is not available to help you debug your personal
laptop configuration.
The <a href="tools.html">tools page</a>
has directions on how to set up <tt>qemu</tt> and <tt>gcc</tt> for
use with JOS.
</p>

<h3>Getting started with git</h3>

<p>
You will clone the read-only git repository on the course webpage, using the command below to get the baseline code:
</p>
<pre>
kermit% <kbd>git clone http://gitlab-edu.kaist.ac.kr/jos.git lab</kbd>
</pre>

<p>Note, having this read-only git repository also allows the instructor to post bugfixes, should they be required.</p>

<p>
Git allows you to keep track of the changes you make to the code.
For example, if you are finished with one of the exercises, and want
to checkpoint your progress, you can <i>commit</i> your changes
by running:
</p>
<pre>
kermit% <kbd>git commit -am 'my solution for lab1 exercise9'</kbd>
Created commit 60d2135: my solution for lab1 exercise9
 1 files changed, 1 insertions(+), 0 deletions(-)
</pre>

<p>
You can keep track of your changes by using the <kbd>git diff</kbd> command.
Running <kbd>git diff</kbd> will display the changes to your code since your
last commit, and <kbd>git diff origin/lab1</kbd> will display the changes
relative to the initial code supplied for this lab.
Here, <tt>origin/lab1</tt> is the name of the git branch with the
initial code you downloaded from our server for this assignment.
</p>

<p>We have set up the appropriate compilers and simulators for you on
the CS lab machines.
</p>


<h2>Part 1: PC Bootstrap</h2>

<p>
The purpose of the first exercise
is to introduce you to x86 assembly language
and the PC bootstrap process,
and to get you started with QEMU and QEMU/GDB debugging.
You will not have to write any code for this part of the lab,
but you should go through it anyway for your own understanding
and be prepared to answer the questions posed below.
</p>

<h3>Getting Started with x86 assembly</h3>

<p>
If you are not already familiar with x86 assembly language,
you will quickly become familiar with it during this course!
The <a href="ref/pcasm-book.pdf">PC Assembly Language Book</a>
is an excellent place to start.
Hopefully, the book contains mixture of new and old material for you.
</p>

<p><i>Warning:</i> Unfortunately the examples in the book are
written for the NASM assembler, whereas we will be using
the GNU assembler. NASM uses the so-called <i>Intel</i> syntax
while GNU uses the <i>AT&amp;T</i> syntax. While semantically
equivalent, an assembly file will differ quite a lot, at least
superficially, depending on which syntax is used. Luckily the
conversion between the two is pretty simple, and is covered in

<a href="http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html">Brennan's Guide to Inline Assembly</a>.
</p>

<div class="required">
<p><span class="header">Exercise 1.</span>
  Read or at least carefully scan the entire
<a href="ref/pcasm-book.pdf">PC Assembly Language</a> book,
except that you should skip all sections after 1.3.5 in chapter 1,
which talk about features of the NASM assembler
that do not apply directly to the GNU assembler.
You may also skip chapters 5 and 6, and all sections under 7.2,
which deal with processor and language features we won't use.
This reading is useful when trying to understand
assembly in JOS, and writing your own assembly. If you have never seen
assembly before, read this book carefully.
</p>
<p>
Also read the section "The Syntax" in
<a href="http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html">Brennan's Guide to Inline Assembly</a>

to familiarize yourself with the most important features
of GNU assembler syntax.  JOS uses the GNU assembler.
</p>
<p>We will be developing JOS for the 64-bit version of the x86 architecture (also known as amd64).
The assembly is very similar to 32-bit, with a few key differences.
Read <a href="ref/assembly.html">this guide</a>, which explains the key differences
between the assembly.
<p>Become familiar with inline assembly by writing a simple program.
Modify the program <a href="ex1.c">ex1.c</a> to include inline assembly that increments the
value of x by 1. <b>Add this file to your lab directory so that it is turned
in for grading with the rest of your code.</b></p>
</div>

<p>Certainly the definitive reference for x86 assembly language programming
is Intel's instruction set architecture reference,
which you can find on
<a href="reference.html">the reference page</a>
in two flavors:
an HTML edition of the old
<a href="ref/i386/toc.htm">80386 Programmer's Reference Manual</a>,
which is much shorter and easier to navigate than more recent manuals
but describes all of the x86 processor features
that we will make use of in CS 530;
and the full, latest and greatest
<a href="http://developer.intel.com/products/processor/manuals/index.htm">
Intel 64 and IA-32 Combined Software Developer's Manuals</a> from Intel,
covering all the features of the most recent processors
that we won't need in class but you may be interested in learning about.
An equivalent (but even longer) set of manuals is
<a href="http://www.amd.com/us-en/Processors/DevelopWithAMD/0,,30_2252_739_7044,00.html">available from AMD</a>,
which also covers the new 64-bit extensions
now appearing in both AMD and Intel processors.
</p>

<p>You should read the recommended chapters of the PC Assembly
book, "The Syntax" section in Brennan's Guide, and the gentle introduction to AMD 64 now.
Save the Intel/AMD architecture manuals for later
or use them for reference when you want to look up
the definitive explanation
of a particular processor feature or instruction.</p>


<h3>Simulating the x86</h3>

<p>
Instead of developing the operating system on a real, physical personal computer
(PC), we use a program that faithfully emulates a complete PC:
the code you write for the emulator will boot on a real PC too.
Using an emulator simplifies debugging; you can, for example, set
break points inside of the emulated x86, which is difficult
to do with the silicon-version of an x86.
</p>

<p>
In CS 530 we will use the
<a href="http://www.qemu.org/">QEMU Emulator</a>,
a modern and relatively fast emulator.
While QEMU's built-in monitor provides only limited debugging support,
QEMU can act as a remote debugging target for the
<a href="http://www.gnu.org/software/gdb/">GNU debugger</a> (GDB), which
we'll use in this lab to step through the early boot process.
</p>

<p>
To get started,
extract the Lab 1 files into your own directory
as described above in "Software Setup",
then type <kbd>make</kbd> in the <tt>lab</tt> directory
to build the minimal boot loader and kernel you will start with.
(It's a little generous to call the code we're running here a "kernel,"
but we'll flesh it out throughout the semester.)

</p>

<pre>
kermit% <kbd>cd lab</kbd>
kermit% <kbd>make</kbd>
+ as kern/entry.S
+ cc kern/init.c
+ cc kern/console.c
+ cc kern/monitor.c
+ cc kern/printf.c
+ cc lib/printfmt.c
+ cc lib/readline.c
+ cc lib/string.c
+ ld obj/kern/kernel
+ as boot/boot.S
+ cc -Os boot/main.c
+ ld boot/boot
boot block is 414 bytes (max 510)
+ mk obj/kern/kernel.img
</pre>

<p>
(If you get errors like "undefined reference to `__udivdi3'", you probably don't have the 32-bit gcc multilib. If you're running Debian or Ubuntu, try installing the gcc-multilib package.) 
</p>

<p>
Now you're ready to run QEMU, supplying the file <tt>obj/kern/kernel.img</tt>,
created above, as the contents of the emulated PC's "virtual hard disk."
This hard disk image contains both
our boot loader (<tt>obj/boot/boot</tt>)
and our kernel (<tt>obj/kern/kernel</tt>).

</p>

<pre>kermit% <kbd>make qemu</kbd>
</pre>

<p>This executes QEMU with the options required to set
the hard disk and direct serial port output to the terminal. (You could
also use <kbd>make qemu-nox</kbd> to run QEMU in the current terminal
instead of opening a new one.)</p>

<p>Some text should appear in the QEMU window:</p>

<pre>Booting from Hard Disk...
6828 decimal is XXX octal!
entering test_backtrace 5
entering test_backtrace 4
entering test_backtrace 3
entering test_backtrace 2
entering test_backtrace 1
entering test_backtrace 0
leaving test_backtrace 0
leaving test_backtrace 1
leaving test_backtrace 2
leaving test_backtrace 3
leaving test_backtrace 4
leaving test_backtrace 5
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K&gt;
</pre>

<p>

Everything after '<tt>Booting from Hard Disk...</tt>'
was printed by our skeletal JOS kernel;
the <tt>K&gt;</tt> is the prompt printed by
the small <i>monitor</i>, or interactive control program,
that we've included in the kernel.
These lines printed by the kernel
will also appear in the regular shell window from which you ran QEMU.
This is because for testing and lab grading purposes
we have set up the JOS kernel to write its console output
not only to the virtual VGA display (as seen in the QEMU window),
but also to the simulated PC's virtual serial port,
which QEMU outputs to its own standard output
because of the <tt>-serial</tt> argument.
Likewise, the JOS kernel will take input from both the keyboard and
the serial port, so you can give it commands in either the VGA display
window or the terminal running QEMU.
</p>

<p>
There are only two commands you can give to the kernel monitor,
<tt>help</tt> and <tt>kerninfo</tt>.  Make sure you type them
(and all other input to JOS) into the VGA display window, not
into the xterm running QEMU.

</p>

<pre>K&gt; <kbd>help</kbd>
help - display this list of commands
kerninfo - display information about the kernel
K&gt; <kbd>kerninfo</kbd>
Special kernel symbols:
	_start                  0020000c (phys)
	entry  800420000c (virt)  0020000c (phys)
	etext  800420924b (virt)  0020924b (phys)
	edata  800421b6a0 (virt)  0021b6a0 (phys)
	end    800421cd40 (virt)  0021cd40 (phys)
Kernel executable memory footprint: 116KB
K&gt;
</pre>

<p>
The <tt>help</tt> command is obvious,
and we will shortly discuss
the meaning of what the <tt>kerninfo</tt> command prints.
Although simple,
it's important to note that this kernel monitor
is running "directly" on the "raw (virtual) hardware"
of the simulated PC.
This means that you should be able to copy
the contents of <tt>obj/kern/kernel.img</tt>

onto the first few sectors of a <i>real</i> hard disk,
insert that hard disk into a real PC,
turn it on,
and see exactly the same thing on the PC's real screen
as you did above in the QEMU window.
(We don't recommend you do this on a real machine
with useful information on its hard disk, though,
because copying <tt>kernel.img</tt> onto the beginning of its hard disk
will trash the master boot record and the beginning of the first partition,
effectively causing everything previously on the hard disk to be lost!)
</p>

<h3>The PC's Physical Address Space</h3>

<p>
We will now dive into a bit more detail
about how a PC starts up.
A PC's physical address space is hard-wired
to have the following general layout:
</p>

<table style="margin: auto;"><tbody><tr><td>

<pre>+------------------+  &lt;- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  &lt;- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  &lt;- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  &lt;- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  &lt;- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  &lt;- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  &lt;- 0x00000000
</pre>
</td></tr>
</tbody></table>

<p>
The first PCs,
which were based on the 16-bit Intel 8088 processor,
were only capable of addressing 1MB of physical memory.
The physical address space of an early PC
would therefore start at 0x00000000
but end at 0x000FFFFF instead of 0xFFFFFFFF.
The 640KB area marked "Low Memory"
was the <i>only</i> random-access memory (RAM) that an early PC could use;
in fact the very earliest PCs only could be configured with
16KB, 32KB, or 64KB of RAM!

</p>

<p>
The 384KB area from 0x000A0000 through 0x000FFFFF
was reserved by the hardware for special uses
such as video display buffers
and firmware held in non-volatile memory.
The most important part of this reserved area
is the Basic Input/Output System (BIOS),
which occupies the 64KB region from 0x000F0000 through 0x000FFFFF.
In early PCs the BIOS was held in true read-only memory (ROM),
but current PCs store the BIOS in updateable flash memory.
The BIOS is responsible for performing basic system initialization
such as activating the video card and checking the amount of memory installed.
After performing this initialization,
the BIOS loads the operating system from some appropriate location
such as floppy disk, hard disk, CD-ROM, or the network,
and passes control of the machine to the operating system.
</p>

<p>
When Intel finally "broke the one megabyte barrier"
with the 80286 and 80386 processors,
which supported 16MB and 4GB physical address spaces respectively,
the PC architects nevertheless preserved the original layout
for the low 1MB of physical address space
in order to ensure backward compatibility with existing software.
Modern PCs therefore have a "hole" in physical memory
from 0x000A0000 to 0x00100000,
dividing RAM into "low" or "conventional memory" (the first 640KB)
and "extended memory" (everything else).
In addition,
some space at the very top of the PC's 32-bit physical address space,
above all physical RAM,
is now commonly reserved by the BIOS
for use by 32-bit PCI devices.
</p>

<p>
Recent x86 processors can support
<i>more</i> than 4GB of physical RAM,
so RAM can extend further above 0xFFFFFFFF.
In this case the BIOS must arrange to leave a <i>second</i> hole
in the system's RAM at the top of the 32-bit addressable region,
to leave room for these 32-bit devices to be mapped.
Because of design limitations JOS
will use only the first 256MB
of a PC's physical memory anyway,
so for now we will pretend that all PCs
have "only" a 32-bit physical address space.
But dealing with complicated physical address spaces
and other aspects of hardware organization
that evolved over many years
is one of the important practical challenges of OS development.

</p>


<h3>The ROM BIOS</h3>

<p>In this portion of the lab, you'll use QEMU's debugging facilities to
investigate how an IA-32 compatible computer boots.</p>

<p>Open two terminal windows.  In one, enter <kbd>make
qemu-gdb</kbd> (or <kbd>make qemu-nox-gdb</kbd>).  This starts up QEMU, but QEMU stops just before the
processor executes the first instruction and waits for a debugging
connection from GDB.  In the second terminal, from the same directory
you ran <kbd>make</kbd>, run <kbd>gdb</kbd>.  You should see something
like this,</p>

<pre>kermit% <kbd>gdb</kbd>
GNU gdb (GDB) 6.8-debian
Copyright (C) 2008 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later &lt;http://gnu.org/licenses/gpl.html&gt;
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "i486-linux-gnu".
+ target remote localhost:1234
The target architecture is assumed to be i8086
[f000:fff0] 0xffff0:	ljmp   $0xf000,$0xe05b
0x0000fff0 in ?? ()
(gdb) 
</pre>

<p>We provided a <tt>.gdbinit</tt> file that set up GDB to debug the
16-bit code used during early boot and directed it to attach to the
listening QEMU.</p>

<p>The following line:</p>

<pre>[f000:fff0] 0xffff0:	ljmp   $0xf000,$0xe05b
</pre>

<p>is GDB's disassembly of the first instruction to be executed.
From this output you can conclude a few things: 
</p>

<ul>
<li>	The IBM PC starts executing at physical address 0x000ffff0,
	which is at the very top of the 64KB area reserved for the ROM BIOS.</li>

<li>	The PC starts executing
	with <tt>CS = 0xf000</tt> and <tt>IP = 0xfff0</tt>.</li>

<li>	The first instruction to be executed is a <tt>jmp</tt> instruction,
	which jumps to the segmented address
	<tt>CS = 0xf000</tt> and <tt>IP = 0xe05b</tt>.</li>
</ul>

<p>
Why does QEMU start like this?
This is how Intel designed the 8088 processor,
which IBM used in their original PC.
Because the BIOS in a PC is "hard-wired"
to the physical address range 0x000f0000-0x000fffff,
this design ensures that the BIOS always gets control of the machine first
after power-up or any system restart -
which is crucial because on power-up
there <i>is</i> no other software anywhere in the machine's RAM
that the processor could execute.
The QEMU emulator comes with its own BIOS,
which it places at this location
in the processor's simulated physical address space.
On processor reset,
the (simulated) processor enters real mode
and sets CS to 0xf000 and the IP to 0xfff0, so that
execution begins at that (CS:IP) segment address.
How does the segmented address 0xf000:fff0
turn into a physical address?

</p>

<p>To answer that we need to know a bit about real mode addressing.
In real mode (the mode that PC starts off in),
address translation works according to the formula:
<i>physical address</i> = 16 * <i>segment</i> + <i>offset</i>.
So, when the PC sets CS to 0xf000 and IP to
0xfff0, the physical address referenced is:</p>

<pre>   16 * 0xf000 + 0xfff0   # in hex multiplication by 16 is
   = 0xf0000 + 0xfff0     # easy--just append a 0.
   = 0xffff0 
</pre>

<p>
<tt>0xffff0</tt> is 16 bytes before the end of the BIOS (<tt>0x100000</tt>).
Therefore we shouldn't be surprised that the
first thing that the BIOS does is <tt>jmp</tt> backwards
to an earlier location in the BIOS; after all
how much could it accomplish in just 16 bytes?
</p>

<div class="required">
	<span class="header">(Self-study) Exercise 2.</span>
	Use GDB's <kbd>si</kbd> (Step Instruction) command
	to trace into the ROM BIOS
	for a few more instructions,
	and try to guess what it might be doing.
	You might want to look at
	<a href="http://web.archive.org/web/20040404164813/members.iweb.net.au/%7Epstorr/pcbook/book2/book2.htm">Phil Storrs I/O Ports Description</a>,
	as well as other materials on the
	<a href="reference.html">reference materials page</a>.
	No need to figure out all the details -
	just the general idea of what the BIOS is doing first.

</div>

<p>
When the BIOS runs,
it sets up an interrupt descriptor table
and initializes various devices such as the VGA display.
This is where the "<tt>Starting SeaBIOS</tt>" messages
you see in the QEMU window come from.
</p>

<p>
After initializing the PCI bus
and all the important devices the BIOS knows about,
it searches for a bootable device
such as a floppy, hard drive, or CD-ROM.
Eventually, when it finds a bootable disk,
the BIOS reads the <i>boot loader</i> from the disk
and transfers control to it.
</p>

<h2>Part 2: The Boot Loader</h2>

<p>Floppy and hard disks for PCs are
divided into 512 byte regions called <i>sectors</i>.
A sector is the disk's minimum transfer granularity:
each read or write operation must be one or more sectors in size
and aligned on a sector boundary.
If the disk is bootable,
the first sector is called the <i>boot sector</i>,
since this is where the boot loader code resides.
When the BIOS finds a bootable floppy or hard disk,
it loads the 512-byte boot sector
into memory at physical addresses 0x7c00 through 0x7dff,
and then uses a <tt>jmp</tt> instruction
to set the CS:IP to <tt>0000:7c00</tt>,
passing control to the boot loader.
Like the BIOS load address,
these addresses are fairly arbitrary -
but they are fixed and standardized for PCs.
</p>

<p>
The ability to boot from a CD-ROM came much later
during the evolution of the PC,
and as a result the PC architects took the opportunity
to rethink the boot process slightly.
As a result,
the way a modern BIOS boots from a CD-ROM
is a bit more complicated (and more powerful).
CD-ROMs use a sector size of 2048 bytes instead of 512,
and the BIOS can load a much larger boot image from the disk into memory
(not just one sector)
before transferring control to it.
For more information,
see the <a
href="ref/boot-cdrom.pdf">"El Torito" Bootable CD-ROM Format Specification</a>.

</p>

<p>
For this class, however,
we will use the conventional hard drive boot mechanism,
which means that the BIOS will only load the first 
512 bytes.  
The bootloader (<tt>boot/boot.S</tt> and <tt>boot/main.c</tt>)
does the bootstrapping work.  
Look through these source files carefully
and make sure you understand what's going on.
The boot loader must perform the following main functions:
</p>

<ol>
<li> First, the boot loader obtains a map of the physical memory present
     in the system from the BIOS.  This is done using a system call to the BIOS (int 0x15),
     which returns a structure called an e820 map. For more details about e820 map, 
		 check out this 
		 <a href="http://www.uruk.org/orig-grub/mem64mb.html">link</a>.
     This call is possible only while the processor is 
     still in real mode.  JOS's bootloader constructs a multiboot
     structure, which it passes to the kernel.  <a href="http://www.gnu.org/software/grub/manual/multiboot/multiboot.html">Multiboot</a> is a standard for passing boot information 
     from the bootloader to a kernel.
</li>

<li>	The boot loader then switches the processor from real mode to
	<i>32-bit protected mode</i>,
	because it is only in this mode
	that software can access all the memory above 1MB
	in the processor's physical address space.
	Protected mode is described briefly
	in sections 1.2.7 and 1.2.8 of
	<a href="ref/pcasm-book.pdf">PC Assembly Language</a>,
	and in great detail in the Intel architecture manuals.
	At this point you only have to understand
	that translation of segmented addresses (segment:offset pairs)
	into physical addresses happens differently in protected mode,
	and that after the transition
	offsets are 32 bits instead of 16.
	<br/>

	One of the arcane x86 features the bootloader handles is properly configuring address bit 20.  To better understand this, skim <a href="http://www.win.tue.nl/~aeb/linux/kbd/A20.html">this article</a>.
</li>

<!--
<li>
	The bootloader then tests whether the CPU supports long (64-bit) mode.
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
</li>
-->
<li>    The bootloader sets up the stack and starts executing the kernel's C code in boot/main.c.</li>

<li>	Finally, the boot loader reads the kernel from the hard disk
	by directly accessing the IDE disk device registers
	via the x86's special I/O instructions.
	If you would like to understand better
	what the particular I/O instructions here mean,
	check out the "IDE hard drive controller" section
	on <a href="reference.html">the reference page</a>.
	You will not need to learn much
	about programming specific devices in this class:
	writing device drivers is in practice
	a very important part of OS development,
	but from a conceptual or architectural viewpoint
	it is also one of the least interesting.</li>
</ol>

<p>
After you understand the boot loader source code,
look at the files <tt>obj/boot/boot.asm</tt>.
This file is a disassembly of the boot loader
that our GNUmakefile creates <i>after</i> compiling the boot loader.
This disassembly file makes it easy to see
exactly where in physical memory all of the boot loader's code resides,
and makes it easier to track what's happening
while stepping through the boot loader in GDB.
</p>

<p>
You can set address breakpoints in GDB with the <kbd>b</kbd> command.  You
have to start hex numbers with <tt>0x</tt>, so say something like <kbd>hb *0x7c00</kbd> sets a
breakpoint at address 0x7C00. <b>Note:</b> an artifact of our infrastructure causes <kbd>b</kbd> not to work properly; use <kbd>hb</kbd> instead.
Once at a breakpoint, you can continue
execution using the <kbd>c</kbd> and
<kbd>si</kbd> commands: <kbd>c</kbd> causes
QEMU to continue execution until the next breakpoint (or until you press

<kbd>Ctrl-C</kbd> in GDB), and <kbd>si
<i>N</i></kbd> steps through the instructions <i><tt>N</tt></i> at a time.
</p>

<p>
To examine instructions in memory (besides the immediate next one to be
executed, which GDB prints automatically), you use the
<kbd>x/i</kbd> command.  This command has the syntax

<kbd>x/<i>N</i>i <i>ADDR</i></kbd>, where <i>N</i> is the
number of consecutive instructions to disassemble and <i>ADDR</i> is the
memory address at which to start disassembling.
</p>

<div class="required">
<p><span class="header">Exercise 3.</span>
       Take a look at the <a href="TOOLS.html">lab tools guide</a>,
       especially the section on GDB commands. Even if you're familiar
       with GDB, this includes some esoteric GDB commands that are
       useful for OS work.</p>

       <p>
	Set a breakpoint at address 0x7c00, which is
	where the boot sector will be loaded.
	Continue execution until that break point.
	Trace through the code in <tt>boot/boot.S</tt>,
	using the source code and the disassembly file
	<tt>obj/boot/boot.asm</tt> to keep track of where you are.
	Also use the <tt>x/i</tt> command in GDB to disassemble
	sequences of instructions in the boot loader,
	and compare the original boot loader source code
	with both the disassembly in <tt>obj/boot/boot.asm</tt>

	and GDB.
</p>
	<p>
	Trace into <tt>bootmain()</tt> in <tt>boot/main.c</tt>,
	and then into <tt>readsect()</tt>.
	Identify the exact assembly instructions
	that correspond to each of the statements in <tt>readsect()</tt>.
	Trace through the rest of <tt>readsect()</tt>

	and back out into <tt>bootmain()</tt>,
	and identify the begin and end of the <tt>for</tt> loop
	that reads the remaining sectors of the kernel from the disk.
	Find out what code will run when the loop is finished,
	set a breakpoint there, and continue to that breakpoint.
	Then step through the remainder of the boot loader.
</p>

<p>
Be able to answer the following questions:
</p>
<ul>
<li>	At what point does the processor start executing 32-bit code?
	What exactly causes the switch from 16- to 32-bit mode?</li>
<li>	What is the <i>last</i> instruction of the boot loader executed,
	and what is the <i>first</i> instruction of the kernel it just loaded?</li>

<li>	How does the boot loader decide how many sectors it must read
	in order to fetch the entire kernel from disk?
	Where does it find this information?</li>
</ul>
</div>

<h3> Loading the Kernel </h3>

<p>
We will now look in further detail
at the C language portion of the boot loader,
in <tt>boot/main.c</tt>.
But before doing so,
this is a good time to stop and review
some of the basics of C programming.
</p>

<div class="required">
<p><span class="header">(Self-study) Exercise 4.</span>

	Read about programming with pointers in C.  The best reference
	for the C language is <i>The C Programming Language</i>
	by Brian Kernighan and Dennis Ritchie (known as 'K&amp;R').  
	We recommend that students
	purchase this book (here is an
	<a href="http://www.amazon.com/C-Programming-Language-2nd/dp/0131103628/sr=8-1/qid=1157812738/ref=pd_bbs_1/104-1502762-1803102?ie=UTF8&amp;s=books">
	Amazon Link</a>).
	There are several copies on reserve in the Science and Engineering library as well.
	</p>
	<p>
	Read 5.1 (Pointers and Addresses) through 5.5 (Character Pointers
	and Functions) in K&amp;R.  Then download the code for
	<a href="pointers.c">pointers.c</a>, run it, and make sure you
	understand where all of the printed values come from.  In particular,
	make sure you understand where the pointer addresses in lines 1 and
	6 come from, how all the values in lines 2 through 4 get there, and
	why the values printed in line 5 are seemingly corrupted.
	</p>

	<p> There are other references on pointers in C, though not
	as strongly recommended.
	<a href="ref/pointers.pdf">A tutorial by Ted Jensen</a> 
	that cites K&amp;R heavily is available in the course readings.
	</p>

	<p>We also recommend reading the <a
	href="https://blogs.oracle.com/ksplice/entry/the_ksplice_pointer_challenge">Ksplice
	pointer challenge</a> as a way to test that you understand how
	pointer arithmetic and arrays work in C.  </p>

	<p>
	<i>Warning:</i>
	Unless you are already thoroughly versed in C,
	do not skip or even skim this reading exercise.
	If you do not really understand pointers in C,
	you will suffer untold pain and misery in subsequent labs,
	and then eventually come to understand them the hard way.
	Trust us; you don't want to find out what "the hard way" is.
	</p>
</div>

<p>
To make sense out of <tt>boot/main.c</tt>
you'll need to know what an ELF binary is.
When you compile and link a C program such as the JOS kernel,
the compiler transforms each C source ('<tt>.c</tt>') file
into an <i>object</i> ('<tt>.o</tt>') file
containing assembly language instructions
encoded in the binary format expected by the hardware.
The linker then combines all of the compiled object files
into a single <i>binary image</i> such as <tt>obj/kern/kernel</tt>,
which in this case is a binary in the ELF format,
which stands for "Executable and Linkable Format".

</p>

<p>
Full information about this format is available in
<a href="ref/elf.pdf">the ELF specification</a>
on <a href="reference.html">our reference page</a>,
but you will not need to delve very deeply
into the details of this format in this class.
Although as a whole the format is quite powerful and complex,
most of the complex parts are for supporting
dynamic loading of shared libraries,
which we will not do in this class.
</p>

<p>
For purposes of this class,
you can consider an ELF executable to be
a header with loading information,
followed by several <i>program sections</i>,
each of which is a contiguous chunk of code or data
intended to be loaded into memory at a specified address.
The boot loader does not modify the code or data; it
loads it into memory and starts executing it.
</p>

<p>
An ELF binary starts with a fixed-length <i>ELF header</i>,
followed by a variable-length <i>program header</i>
listing each of the program sections to be loaded.
The C definitions for these ELF headers are in <tt>inc/elf.h</tt>.
The program sections we're interested in are:
</p>
<ul>
<li>	<tt>.text</tt>:
	The program's executable instructions.</li>
<li>	<tt>.rodata</tt>:
	Read-only data,
	such as ASCII string constants produced by the C compiler.
	(We will not bother setting up the hardware to prohibit writing,
	however.)</li>

<li>	<tt>.data</tt>:
	The data section holds the program's initialized data,
	such as global variables declared with initializers
	like <code>int x = 5;</code>.</li>
</ul>

<p>
When the linker computes the memory layout of a program,
it reserves space for <i>uninitialized</i> global variables,
such as <code>int x;</code>,
in a section called <tt>.bss</tt>

that immediately follows <tt>.data</tt> in memory.
C requires that "uninitialized" global variables start with
a value of zero.
Thus there is no need to store contents for <tt>.bss</tt>
in the ELF binary; instead, the linker records just the address and
size of the <tt>.bss</tt> section.
The loader or the program itself must arrange to zero the
<tt>.bss</tt> section.
</p>

<p>
You can display a full list of the names, sizes, and link addresses
of all the sections in the kernel executable by typing:

</p>

<pre>
kermit% <kbd>objdump -h obj/kern/kernel</kbd>
</pre>

<p>
You will see many more sections than the ones we listed above,
but the others are not important for our purposes.
Most of the others are to hold debugging information,
which is typically included in the program's executable file
but not loaded into memory by the program loader.
</p>

<p>
Take particular note of the "VMA" (or <i>link address</i>) and the
"LMA" (or <i>load address</i>) of the
<tt>.text</tt> section.
The load address of a section is the memory address at which that
section should be loaded into memory.  In the ELF object, this is
stored in the <code>ph-&gt;p_pa</code> field (in this case, it really
is a physical address, though the ELF specification is vague on the
actual meaning of this field).
</p>

<p>
The link address of a section is the memory address from which the
section expects to execute.  The linker encodes the link address in
the binary in various ways, such as when the code needs the address of
a global variable, with the result that a binary usually won't work if
it is executing from an address that it is not linked for.  (It is
possible to generate <i>position-independent</i> code that does not
contain any such absolute addresses.  This is used extensively by
modern shared libraries, but it has performance and complexity costs,
so we won't be using it in this class.)
</p>

<p>
Typically, the link and load addresses are the same.  For example,
look at the <tt>.text</tt> section of the boot loader:
</p>
<pre>
kermit <kbd>objdump -h obj/boot/boot.out</kbd>
</pre>
<p>
The BIOS loads the boot sector into memory starting at address 0x7c00,
so this is the boot sector's load address.  This is also where the
boot sector executes from, so this is also its link address.  We set
the link address by passing <tt>-Ttext 0x7C00</tt> to the linker in
<tt>boot/Makefrag</tt>, so the linker will produce the correct memory
addresses in the generated code.
</p>

<div class="required">
<p><span class="header">(Self-study) Exercise 5.</span>
	Trace through the first few instructions of the boot loader again
	and identify the first instruction that would "break"
	or otherwise do the wrong thing
	if you were to get the boot loader's link address wrong.
	Then change the link address in <tt>boot/Makefrag</tt>
	to something wrong,
	run <kbd>make clean</kbd>,
	recompile the lab with <kbd>make</kbd>,
	and trace into the boot loader again to see what happens.
	Don't forget to change the link address back and <kbd>make
	clean</kbd> again afterward!
</p></div>

<p>
Look back at the load and link addresses for the kernel.  Unlike the
boot loader, these two addresses aren't the same: the kernel is
telling the boot loader to load it into memory at a low address (1
megabyte), but it expects to execute from a high address.  We'll dig
in to how we make this work in the next section.
</p>

<p>
Besides the section information,
there is one more field in the ELF header that is important to us,
named <code>e_entry</code>.
This field holds the link address
of the <i>entry point</i> in the program:
the memory address in the program's text section
at which the program should begin executing.
You can see the entry point:

</p>

<pre>
kermit% <kbd>objdump -f obj/kern/kernel</kbd>
</pre>

<p>
You should now be able to understand the minimal ELF loader in
<tt>boot/main.c</tt>.  It reads each section of the kernel from disk
into memory at the section's load address and then jumps to the
kernel's entry point.
</p>


<div class="required">
<p><span class="header">Exercise 6.</span>
	We can examine memory using GDB's <kbd>x</kbd> command.  The
	<a href="http://sourceware.org/gdb/current/onlinedocs/gdb_9.html#SEC63">GDB
	manual</a> has full details, but for now, it is enough to know
	that the command <kbd>x/<i>N</i>x <i>ADDR</i></kbd> prints
	<i><tt>N</tt></i> words of memory at <i><tt>ADDR</tt></i>.
	(Note that both '<tt>x</tt>'s in the command are lowercase.)
	<i>Warning</i>: The size of a word is not a universal standard.
	In GNU assembly, a word is two bytes (the 'w' in xorw, which
	stands for word, means 2 bytes).
	</p>
	
	<p>
	Reset the machine (exit QEMU/GDB and start them again).
	Examine the 8 words of memory at 0x00100000 
	at the point the BIOS enters the boot loader,
	and then again at the point the boot loader enters the kernel.
	Why are they different?
	What is there at the second breakpoint?
	(You do not really need to use QEMU to answer this question.
	Just think.)

</p></div>


<!--
<h3>Link vs. Load Address</h3>

<p>
The <i>load address</i> of a binary
is the memory address at which a binary is <i>actually</i> loaded.
For example, the BIOS is loaded by the PC hardware at
address 0xf0000. So this is the BIOS's load address.
Similarly, the BIOS loads the boot sector at address 0x7c00. So
this is the boot sector's load address.
</p>

<p>

The <i>link address</i> of a binary
is the memory address for which the binary is linked.
Linking a binary for a given link address
prepares it to be loaded at that address. 
The linker encodes the link address in the binary in various
ways, for example when the code needs the address of a global
variable,
with the result that a binary usually won't work if it is not loaded
at the address that it is linked for.
</p>

<p>In one sentence:
the link address is the location where a binary
<i>assumes</i> it is going to be loaded,
while the load address is the location
where a binary <i>is</i> loaded.
It's up to us to make sure that they turn out to be the same.
</p>

<p>
Look at the <tt>-Ttext</tt> linker command
in <tt>boot/Makefrag</tt>,
and at the address mentioned
early in the linker script in <tt>kern/kernel.ld</tt>.
These set the link address for the boot loader and kernel respectively.

</p>

<p>
When object code contains no absolute addresses that
encode the link address in this fashion,
we say that the code is <i>position-independent</i>:
it will behave correctly no matter where it is loaded.
GCC can generate position-independent code using the <tt>-fpic</tt> option,
and this feature is used extensively in modern shared libraries
that use the ELF executable format.
Position independence typically has some performance cost, however,
because it restricts the ways in which the compiler may choose instructions
to access the program's data.
We will not use <tt>-fpic</tt> in this class.
</p>
-->

<h2>Part 3: The Kernel</h2>

<p>
We will now start to examine the minimal JOS kernel in a bit more detail.
(And you will finally get to write some code!).
Like the boot loader,
the kernel begins with some assembly language code
that sets things up so that C language code can execute properly.
</p>

<p>
The initial assembly code of the kernel does the following:
</p>
<ol>
    <li>When the kernel starts executing, the processor is in the 32-bit protected mode. The first thing the kernel does is it tests whether the CPU supports long (64-bit) mode.</li>
    <li> The kernel initializes a simple set of page tables for the first 4GB of memory. These pages map virtual addresses in the lowest 3GB to the same physical addresses, and then map the upper 256 MB back to the lowest 256 MB of memory. At this point, the kernel places the CPU in long mode. The kernel could determine dynamically whether to run in 64 or 32-bit mode based on whether the CPU supports long mode. Of course, this would substantially complicate the kernel.
    </li>
    <li> Finally, the kernel sets up the stack and a few other things to start executing C code.</li>
</ol>
<p>Look through the kernel source files <tt>kern/entry.S</tt> and <tt>kern/bootstrap.S</tt>
and be able to answer the following question</p>
<ul>
<li>	At what point does the processor start executing 64-bit code?
	What exactly causes the switch from 32- to 64-bit mode?</li>
</ul>

<h3>Using segmentation to work around position dependence</h3>

<p>
Did you notice above
that while the boot loader's link and load addresses match perfectly,
there appears to be a (rather large) disparity
between the <i>kernel's</i> link and load addresses?
Go back and check both and make sure you can see what we're talking about.
</p>

<p>
Operating system kernels often like to be linked and run
at very high <i>virtual address</i>, such as 0x8004100000,
in order to leave the lower part of the processor's virtual address space
for user programs to use.
The reason for this arrangement will become clearer in the next lab.

</p>

<p>
Many machines don't have any physical memory at address 0x8004100000
so we can't count on being able to store the kernel there.
Instead, we will use the processor's memory management hardware
to map virtual address0x8004100000 -
the link address at which the kernel code <i>expects</i> to run -
to physical address 0x100000---
where the boot loader loaded the kernel.
This way, although the kernel's virtual address is high enough
to leave plenty of address space for user processes,
it will be loaded in physical memory at the 1MB point in the PC's RAM,
just above the BIOS ROM.
This approach requires that the PC have at least a few megabytes of
physical memory (so that address 0x00100000 works), but this is likely
to be true of any PC built after about 1990.
</p>

<p>We will eventually map physical address 0x0 
to virtual address . </p>

<p>
We will eventually map the <i>entire</i> bottom 256MB
of the PC's physical address space,
from 0x00000000 through 0x0fffffff,
to virtual addresses  0x8004000000 through 0x8013FFFFFF, respectively.
<!---
You should now see why JOS can only use
the first 256MB of physical memory.
-->
</p>

<!---
<p>

The x86 processor has two distinct memory management mechanisms
that JOS could use to achieve this mapping:
<i>segmentation</i> and <i>paging</i>.
Both are described in full detail in the
<a href="ref/i386/toc.htm">80386 Programmer's Reference Manual</a>
and the
<a href="ref/ia32/IA32-3A.pdf">IA-32 Developer's Manual, Volume 3</a>.
When the JOS kernel first starts up,
it initially uses segmentation
to establish the desired virtual-to-physical mapping,
because it is quick and easy -
and the x86 processor requires us
to set up the segmentation hardware in any case,
because it can't be disabled!
</p>

<p>
For now, we'll just map the first 4MB of physical memory, which will
be enough to get us up and running.  We do this using the
hand-written, statically-initialized page directory and page table in
<tt>kern/entrypgdir.c</tt>.  For now, you don't have to understand the
details of how this works, just the effect that it accomplishes.  Up
until <tt>kern/entry.S</tt> sets the <code>CR0_PG</code> flag, memory
references are treated as physical addresses (strictly speaking,
they're linear addresses, but boot/boot.S set up an identity mapping
from linear addresses to physical addresses and we're never going to
change that).  Once <code>CR0_PG</code> is set, memory references are
virtual addresses that get translated by the virtual memory hardware
to physical addresses.  <code>entry_pgdir</code> translates virtual
addresses in the range 0xf0000000 through 0xf0400000 to physical
addresses 0x00000000 through 0x00400000, as well as virtual addresses
0x00000000 through 0x00400000 to physical addresses 0x00000000 through
0x00400000.  Any virtual address that is not in one of these two
ranges will cause a hardware exception which, since we haven't set up
interrupt handling yet, will cause QEMU to dump the machine state and
exit (or endlessly reboot if you aren't using the 506-patched
version of QEMU).
</p>
--!>

<p>
For now, the kernel will initially set up 
a hand-written, statically-initialized page tables
in <tt>kern/bootstrap.S</tt>.
For now, you don't have to understand the
details of how this works, just the effect that it accomplishes.  Up
until <tt>kern/bootstrap.S</tt> sets the <code>CR0_PG</code> flag, memory
references are treated as physical addresses (strictly speaking,
they're linear addresses, but <tt>boot/boot.S</tt> set up an identity mapping
from linear addresses to physical addresses and we're never going to
change that).  Once <code>CR0_PG</code> is set, memory references are
virtual addresses that get translated by the virtual memory hardware
to physical addresses.  <code>pml4</code> translates virtual
addresses in the range 0x8004000000  through  0x8013ffffff to physical
addresses 0x00000000 through 0x0fffffff, as well as virtual addresses
0x00000000 through 0xefffffff to physical addresses 0x00000000 through
0xefffffff.  
</p>


<div class="required">
<p><span class="header">Exercise 7.</span>
	Use QEMU and GDB to trace into the early JOS kernel boot code (in the <tt>kern/boostrap.S</tt> directory)
	and find where the new virtual-to-physical mapping takes effect.
	Then examine the Global Descriptor Table (GDT)
	that the code uses to achieve this effect,
	and make sure you understand what's going on.
	</p>

	<p>
	What is the first instruction <i>after</i> the new
	mapping is established that would fail to work properly
	if the old mapping were still in place?
	Comment out or otherwise intentionally break
	the segmentation setup code in <tt>kern/entry.S</tt>,
	trace into it,
	and see if you were right.
</p></div>


<h3>Formatted Printing to the Console</h3>

<p>
Most people take functions like <tt>printf()</tt> for granted,
sometimes even thinking of them as "primitives" of the C language.
But in an OS kernel, we have to implement all I/O ourselves.

</p>

<!--
<p>
<center><table border=1 width=80%><tr><td bgcolor=#e0e0ff>
	<b>Exercise 8.</b>
	Read chapter five of the Lions book, "Two Files".
	Although it is about UNIX on the PDP11,
	you may nevertheless find it highly relevant and useful
	in understanding this section of the lab.
</table></center>
</p>
-->

<p>
Read through <tt>kern/printf.c</tt>, <tt>lib/printfmt.c</tt>,
and <tt>kern/console.c</tt>,
and make sure you understand their relationship.
It will become clear in later labs why <tt>printfmt.c</tt>
is located in the separate <tt>lib</tt> directory.

</p>

<div class="required">
<p><span class="header">Exercise 8.</span>
	We have omitted a small fragment of code -
	the code necessary to print octal numbers
	using patterns of the form "%o".
	Find and fill in this code fragment.
</p></div>

<p>
Be able to answer the following questions:
</p>

<ol>
<li> Explain the interface between <tt>printf.c</tt> and

<tt>console.c</tt>.  Specifically, what function does
<tt>console.c</tt> export?  How is this function used by
<tt>printf.c</tt>?</li>

<li> Explain the following from <tt>console.c</tt>:
<pre>1      if (crt_pos &gt;= CRT_SIZE) {
2              int i;
3              memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
4              for (i = CRT_SIZE - CRT_COLS; i &lt; CRT_SIZE; i++)
5                      crt_buf[i] = 0x0700 | ' ';
6              crt_pos -= CRT_COLS;
7      }

</pre></li>

<li> Trace the execution of the following code step-by-step:

<pre>int x = 1, y = 3, z = 4;
cprintf("x %d, y %x, z %d\n", x, y, z);
</pre>
<ul>
<li>
	In the call to <code>cprintf()</code>,
	to what does <code>fmt</code> point?
	To what does <code>ap</code> point?</li>

<li> List (in order of execution) each call to
<code>cons_putc</code>, <code>va_arg</code>, and <code>vcprintf</code>.
For <code>cons_putc</code>, list its argument as well.  For
<code>va_arg</code>, list what <code>ap</code> points to before and
after the call.  For <code>vcprintf</code> list the values of its
two arguments.</li>

</ul></li>
<li> Run the following code.
<pre>
    unsigned int i = 0x00646c72;
    cprintf("H%x Wo%s", 57616, &amp;i);
</pre>

What is the output?  Explain how this output is arrived at in the
step-by-step manner of the previous exercise.
<a href="http://web.cs.mun.ca/%7Emichael/c/ascii-table.html">Here's an ASCII
  table</a> that maps bytes to characters.

<p>The output depends on that fact that the x86 is little-endian.  If
the x86 were instead big-endian what would you set <code>i</code> to in
order to yield the same output?  Would you need to change

<code>57616</code> to a different value?</p>

<p>
<a href="http://www.webopedia.com/TERM/b/big_endian.html">Here's
a description of little- and big-endian</a>
and
<a href="http://www.networksorcery.com/enp/ien/ien137.txt">a more
whimsical description</a>.
</p>
</li>

<li>
In the following code, what is going to be printed after
'<code>y=</code>'?  (note: the answer is not a specific value.)  Why
does this happen?


<pre>
    cprintf("x=%d y=%d", 3);
</pre>
</li>

<li>
Let's say that GCC changed its calling convention so that it
pushed arguments on the stack in declaration order,
so that the last argument is pushed last.
How would you have to change <code>cprintf</code> or its
interface so that it would still be possible to pass it a variable
number of arguments?
</li>
</ol>

<div class="challenge">
<p><span class="header">Challenge 1</span> (5 bonus points)

	Enhance the console to allow text to be printed in different colors.
	The traditional way to do this is to make it interpret
<!--	<a href="http://www.dee.ufcg.edu.br/~rrbrandt/tools/ansi.html">-->
	<a href="http://ascii-table.com/ansi-escape-sequences.php">
	ANSI escape sequences</a>
	embedded in the text strings printed to the console,
	but you may use any mechanism you like.
	There is plenty of information on
	<a href="reference.html">the reference page</a>
	and elsewhere on the web on programming the VGA display hardware.
	If you're feeling really adventurous,
	you could try switching the VGA hardware into a graphics mode
	and making the console draw text onto the graphical frame buffer.
</p></div>


<h3>The Stack</h3>

<p>
In the final exercise of this lab,
we will explore in more detail
the way the C language uses the stack on the x86,
and in the process write a useful new kernel monitor function
that prints a <i>backtrace</i> of the stack:
a list of the saved Instruction Pointer (IP) values
from the nested <tt>call</tt> instructions that
led to the current point of execution.
</p>

<div class="required">
<p><span class="header">Exercise 9.</span>
	Determine where the kernel initializes its stack,
	and exactly where in memory its stack is located.
	How does the kernel reserve space for its stack?
	And at which "end" of this reserved area
	is the stack pointer initialized to point to?

</p></div>

<p>
The x86-64 stack pointer (<tt>rsp</tt> register)
points to the lowest location on the stack that is
currently in use.
Everything <i>below</i> that location in the region reserved for the stack
is free.
Pushing a value onto the stack involves decreasing the stack
pointer and then writing the value to the place the stack pointer
points to.
Popping a value from the stack involves reading the value
the stack pointer points to and then increasing the stack pointer.
In 64-bit mode, the stack can only hold 64-bit values,
and rsp is always divisible by eight.
Various x86-64 instructions, such as <tt>call</tt>,
are "hard-wired" to use the stack pointer register.
</p>

<p>
The <tt>rbp</tt> (base pointer) register, in contrast,
is associated with the stack primarily by software convention.
On entry to a C function,
the function's <i>prologue</i> code normally
saves the previous function's base pointer by pushing it onto the stack,
and then copies the current <tt>rsp</tt> value into <tt>rbp</tt>

for the duration of the function.
If all the functions in a program obey this convention,
then at any given point during the program's execution,
it is possible to trace back through the stack
by following the chain of saved <tt>rbp</tt> pointers
and determining exactly what nested sequence of function calls
caused this particular point in the program to be reached.
This capability can be particularly useful, for example,
when a particular function causes an <tt>assert</tt> failure or <tt>panic</tt>
because bad arguments were passed to it,
but you aren't sure <i>who</i> passed the bad arguments.
A stack backtrace lets you find the offending function.
</p>

<div class="required">
<p><span class="header">Exercise 10.</span>

	To become familiar with the C calling conventions on the x86-64,
	find the address of the <code>test_backtrace</code> function
	in <tt>obj/kern/kernel.asm</tt>,
	set a breakpoint there,
	and examine what happens each time it gets called
	after the kernel starts.
	How many 64-bit words does each recursive nesting level
	of <code>test_backtrace</code> push on the stack,
	and what are those words?</p>

	<p>Note that, for this exercise to work properly, you should
	be using the patched version of QEMU available on the <a
	href="tools.html">tools</a> page or on your course virtual machine.
	Otherwise, you'll have to manually translate all breakpoint
	and memory addresses to linear addresses.

</p></div>

<p>
The above exercise should give you the information you need
to implement a stack backtrace function,
which you should call <code>mon_backtrace()</code>.
A prototype for this function is already waiting for you
in <tt>kern/monitor.c</tt>.
You can do it entirely in C,
but you may find the <code>read_rbp()</code> function in <tt>inc/x86.h</tt> useful.
You'll also have to hook this new function
into the kernel monitor's command list
so that it can be invoked interactively by the user.
</p>

<p>

The backtrace function should display a listing of function call frames
in the following format:
</p>

<pre>
Stack backtrace:
  rbp 00000000f0111f20  rip 00000000f01000be  
  rbp 00000000f0111f40  rip 00000000f01000a1  
  ...
</pre>

<p>
The first line printed reflects the <i>currently executing</i> function,
namely <code>mon_backtrace</code> itself,
the second line reflects the function that called <code>mon_backtrace</code>,
the third line reflects the function that called that one, and so on.
You should print <i>all</i> the outstanding stack frames.
By studying <tt>kern/entry.S</tt>

you'll find that there is an easy way to tell when to stop.
</p>

<p>
Within each line,
the <tt>rbp</tt> value indicates the base pointer into the stack
used by that function:
i.e., the position of the stack pointer just after the function was entered
and the function prologue code set up the base pointer.
The listed <tt>rip</tt> value
is the function's <i>return instruction pointer</i>:
the instruction address to which
control will return when the function returns.
The return instruction pointer typically points to the instruction
after the <tt>call</tt> instruction (why?).
</p>

<p>Read <a href="http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64.html">this article</a> on how arguments are mapped to registers on the x86-64 architecture.
This is called a <em>calling convention</em>, as software developers agree on this mapping by convention.
As the article explains, different compilers may have different standards.  For instance, the Windows x86-64 calling convention differs from the Linux x86-64 calling convention.
</p>

<p>
Here are a few specific points you read about in K&amp;R Chapter 5 that are
worth remembering for the following exercise and for future labs.
</p>
<ul>
<li>If <code>int *p = (int*)100</code>, then 
    <code>(int)p + 1</code> and <code>(int)(p + 1)</code>
    are different numbers: the first is <code>101</code> but
    the second is <code>104</code>.
    When adding an integer to a pointer, as in the second case,
    the integer is implicitly multiplied by the size of the object
    the pointer points to.</li>

<li><code>p[i]</code> is defined to be the same as <code>*(p+i)</code>,
referring to the i'th object in the memory pointed to by p.
The above rule for addition helps this definition work
when the objects are larger than one byte.</li>
<li> <code>&amp;p[i]</code> is the same as <code>(p+i)</code>, yielding
the address of the i'th object in the memory pointed to by p.</li>
</ul>
<p>
Although most C programs never need to cast between pointers and integers,
operating systems frequently do.
Whenever you see an addition involving a memory address,
ask yourself whether it is an integer addition or pointer addition
and make sure the value being added is appropriately multiplied
or not.
</p>

<div class="required">
<p><span class="header">Exercise 11.</span>
	Implement the backtrace function as specified above.
	Use the same format as in the example, since otherwise the
	grading script will be confused.
	When you think you have it working right,
	run <kbd>make grade</kbd> to see if its output
	conforms to what our grading script expects,
	and fix it if it doesn't.
	<i>After</i> you have handed in your Lab 1 code,
	you are welcome to change the output format of the backtrace function
	any way you like.
</p></div>

<p>
At this point, your backtrace function should give you the addresses of
the function callers on the stack that lead to <code>mon_backtrace()</code>

being executed.  However, in practice you often want to know the function
names corresponding to those addresses.  For instance, you may want to know
which functions could contain a bug that's causing your kernel to crash.
</p>

<p>The final exercise will have you list the arguments to each
function in the backtrace, if the funciton has any input values.</p>

<p>
On x86-64, arguments are generally passed in registers.  
If funciton a calls function b, a may save some register values on the stack and reload them,
depending on whether a value will be reused.  These decisions
are made by the compiler.
Thus, in order to find arguments on the stack, we need some help from 
the compiler.
</p>

<p>When JOS is compiled with debugging flags, the compiler outputs 
a variety of debugging information in the DWARF2 format.
Read <a href="http://dwarfstd.org/doc/Debugging%20using%20DWARF-2012.pdf">this article</a>
for a brief introduction to DWARF and how debugging symbols work.
The key intuition is that DWARF gives the debugger (or monitor backtrace function)
enough information to programmatically identify saved arguments on the stack.
</p>


<p>
To help you implement this functionality, we have provided the function
<code>debuginfo_rip()</code>, which looks up <tt>rip</tt> in the symbol table
and returns the debugging information for that address.  This function is
defined in <tt>kern/kdebug.c</tt>.
Each <tt>rip</tt> value maps onto a <tt>Ripdebuginfo</tt> structure.
Within this structure is a number of useful fields, including
the file and line the <tt>rip</tt> corresponds to, and fields
that list the number of entries and their offsets on the stack
(Hint: check out <tt>rip_fn_narg</tt>, <tt>offset_fn_art</tt>, and <tt>size_fn_arg</tt>).

</p>



<div class="required">
<p><span class="header">Exercise 12.</span>

        Modify your stack backtrace function to display, for each <tt>rip</tt>,
	the function arguments, 	
        the function name, source file name, and line number corresponding
        to that <tt>rip</tt>.</p>

	<p>Add a <tt>backtrace</tt> command to the kernel monitor, and
	extend your implementation of <code>mon_backtrace</code> to
	call <code>debuginfo_rip</code> and print a line for each
	stack frame of the form:</p>
	<pre>
K&gt; backtrace
Stack backtrace:
  rbp 000000800421af00  rip 00000080042010ff
       kern/monitor.c:86: mon_backtrace+0000000000000035  args:3  0000000000000000 000000000421b909 0000000000000080
  rbp 000000800421afb0  rip 000000800420144d
       kern/monitor.c:163: runcmd+00000000000001d3  args:2  0000000000000001 0000000000000002
  rbp 000000800421afe0  rip 0000008004201508
       kern/monitor.c:185: monitor+000000000000007d  args:1  0000000000000080
  rbp 000000800421aff0  rip 0000008004200196
       kern/init.c:172: i386_init+00000000000000ba  args:0 
</pre>
	<p>Each line gives the file name and line within that file of
	the stack frame's <tt>rip</tt>, followed by the name of the
	function and the offset of the <tt>rip</tt> from the first
	instruction of the function (e.g., <tt>monitor+106</tt> means
	the return <tt>rip</tt> is 106 bytes past the beginning of
	<tt>monitor</tt>), followed by the number of function arguments 
	and then the actual arguments themselves.</p>

	<p>Hint: for the function arguments, take a look the
	<tt>struct Ripdebuginfo</tt> in <tt>kern/kdebug.h</tt>. This
	structure is filled by the call to
	<code>debuginfo_rip</code>. The x86_64 calling convention
	states that the function arguments are pushed onto the
	stack. Refer to <a
	href="http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64/">this
	article</a> on the calling convention to figure out how to
	read the actual function arguments on the stack.</p>

	<p>Be sure to print the file and function names on a separate
	line, to avoid confusing the grading script.</p>
	<p>Tip: printf format strings provide an easy, albeit obscure,
	way to print non-null-terminated strings like those in the DWARF2 
	tables.	 <code>printf("%.*s", length, string)</code> prints at
	most <code>length</code> characters of <code>string</code>.
	Take a look at the printf man page to find out why this
	works.</p>
	<p>
        You may find that the some functions are missing from the
        backtrace. For example, you will probably see a call to
        <code>monitor()</code> but not to <code>runcmd()</code>. This is
        because the compiler in-lines some function calls.
        Other optimizations may cause you to see unexpected line
        numbers. If you get rid of the <tt>-O2</tt> from
        <tt>GNUMakefile</tt>, the backtraces may make more sense
        (but your kernel will run more slowly).

</p></div>


<h3>Hand-In Procedure</h3>

<p>TBD </p>

<!--
<p>In this and all other labs, you may complete challenge problems for extra credit.
If you do this, please add include details in the submission email, including
a short (e.g., one or two paragraph) description of what you did
to solve your chosen challenge problem and how to test it.
If you implement more than one challenge problem,
you must describe each one.
Be sure to list the challenge problem number.
</p>
-->

<i>If you submit multiple times, we will take the latest
submission and count late hours accordingly.</i>

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
