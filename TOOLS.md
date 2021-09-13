<p>
Familiarity with your environment is crucial for productive
development and debugging.  This page gives a brief overview of the
JOS environment and useful GDB and QEMU commands.  Don't take our word
for it, though.  Read the GDB and QEMU manuals.  These are powerful
tools that are worth knowing how to use.
</p>

<div class="toc">
  <table>
    <tr>
      <th>Debugging tips:</th>
      <td>
        <a href="#debug-kernel">Kernel</a>
        <a href="#debug-user">User environments</a>
      </td>
    </tr>
    <tr>
      <th>Reference:</th>
      <td>
        <a href="#make">JOS makefile</a>
        <a href="#obj">JOS obj/</a>
        <a href="#gdb">GDB</a>
        <a href="#qemu">QEMU</a>
      </td>
    </tr>
  </table>
</div>

<p>
All of the tools that you need to execute and complete the labs are 
installed in your course virtual machine. 
</p>

<p>
If you wish to compile and run the tools on your own machine, the
information that you need is as follows. Note that we cannot guarantee
that these tools will run on your computer, and we cannot support these
tools on your own computer. However, the tools <i>should</i> run on
recent versions of Linux. The tools should also run under Windows with
the help of <a href="http://www.cygwin.com">Cygwin</a>.  Install cygwin,
and be sure to install the <samp>flex</samp> and <samp>bison</samp>

packages (they are under the development header).</p>

<h2>Compiler Toolchain</h2>


<p>Most modern Linux distributions and BSDs have an ELF toolchain compatible with
the JOS labs. That is, the system-standard <tt>gcc</tt>,
<tt>as</tt>, <tt>ld</tt> and <tt>objdump</tt> should just work. The lab
Makefile should automatically detect this. If
the makefile fails to detect your build tools,
you can specify their location  by adding the following line to
<tt>conf/env.mk</tt>:</p>

<pre>
GCCPREFIX=
</pre>

<p>
If you are using something other than standard x86
linux or BSD, you will need the GNU C compiler toolchain, configured
and built as a cross-compiler for the target
'<samp>i386-jos-elf</samp>', as well as the GNU debugger, configured for 
the <samp>i386-jos-elf</samp> toolchain.
You can download versions that are known
to work with JOS
via the following links, although more recent versions of gcc and
binutils, and GDB should work too:
</p>

<ul>
<li>	<a href="http://ftp.gnu.org/gnu/binutils/binutils-2.19.tar.bz2">

	http://ftp.gnu.org/gnu/binutils/binutils-2.19.tar.bz2</a>
</li>
<li>	<a href="http://ftp.gnu.org/gnu/gcc/gcc-4.1.2/gcc-core-4.1.2.tar.bz2">
	http://ftp.gnu.org/gnu/gcc/gcc-4.1.2/gcc-core-4.1.2.tar.bz2</a>
</li>
<li>	<a href="http://ftp.gnu.org/gnu/gdb/gdb-7.2a.tar.gz">
	http://ftp.gnu.org/gnu/gdb/gdb-7.2a.tar.gz</a>
</li>
</ul>


<p>Once you've unpacked these archives, run the following commands as
root:</p>

<pre>
# cd binutils-2.19
# ./configure --target=i386-jos-elf --disable-nls
# make
# make install
# cd ../gcc-4.1.2
# ./configure --target=i386-jos-elf --disable-nls --without-headers \
              --with-newlib --disable-threads --disable-shared \
              --disable-libmudflap --disable-libssp
# make
# make install
# cd ../gdb-7.2a
# ./configure --target=i386-jos-elf --program-prefix=i386-jos-elf- \
              --disable-werror
# make
# make install
</pre>

<!--
<p>If there are errors compiling gcc when it gets to libstdc++, don't
worry about it.</p>
-->

<p>Then you'll have in <samp>/usr/local/bin</samp> a bunch of binaries
with names like <samp>i386-jos-elf-gcc</samp>.  
The lab makefile
should detect this toolchain and use it in preference to your
machine's default toolchain.  If this doesn't work, there are
instructions on how to override the toolchain inside the GNUmakefile
in the labs.</p>
<!--
It will also be
necessary to change the Makefile used in the labs to use
<samp>i386-jos-elf-gcc</samp> instead of <samp>gcc</samp>.  There
are instructions for how to do this inside of the Makefile.</p>
-->

<h2><a name="gdb"/>Patched GDB</h2>

<p>The standard version of gdb does not correctly handle the transition 
to long mode during JOS boot, yielding a "Packet too long" error.
The patch below will fix this:
</p>
<ul>
<li>GDB versions up to 7.3: <a href="gdb-7.2-arch-remote-change.patch">patch</a></li>
<li>GDB version 7.7.1 (and later): <a href="gdb-7.7.1-mute-message-too-long.patch">patch</a></li>
</ul>

<p>For the provided environment, we have installed the patched gdb package for you.
For debugging 64-bit code on a 32-bit platform, you need both gdb and gdb-multiarch.
Below we post patched Ubuntu packages.
</p>

<ul>
<li> amd64: <ul>
     <li><a href="gdb_7.2-1ubuntu11jos_amd64.deb">gdb 7.2</a>.  </li>
     <li><a href="gdb_7.7.1-0ubuntu5~14.04.2_amd64.deb">gdb 7.7.1</a> (Ubuntu 14.04). </li>
     <li><a href="gdb_7.11-1ubuntu11jos_amd64.deb">gdb 7.11</a> (Ubuntu 16.04).  </li>
</ul>
gdb-multiarch is not required on amd64.
</ul>


<p>To build gdb against another version on Ubuntu or Debian, e.g., for home use, follow these steps:</p>
<pre>
    dpkg-source -x gdb-xxxxx.dsc   (the .dsc you installed)
    cd gdb-xxx  (a newly created directory)
    sudo apt-get build-dep gdb
    download gdb-7.7.1-mute-message-too-long.patch
    patch -p1 < gdb-7.7.1-mute-message-too-long.patch
    sudo debian/rules binary
</pre>


<h2><a name="qemu"/>QEMU Emulator</h2>
<p><a href="http://www.nongnu.org/qemu/">QEMU</a> is a modern and fast
PC emulator. </p>

<p>Unfortunately, QEMU's debugging facilities, while powerful, are
somewhat immature, so we highly recommend you use the MIT patched version
of QEMU instead of the stock version that may come with your
distribution.  The version installed on <tt>walter.cs.unc.edu</tt> is already patched.
To build your own patched version of QEMU:</p>

<!-- Note to staff:

     Some of the QEMU patches were applied upstream and should appear
     in releases post-0.15.
-->

<ol>
  <li>Clone the MIT QEMU git repository<br />
  <code>git clone https://github.com/geofft/qemu.git -b 6.828-1.7.0</code></li>
  <li>On Linux, you may need to install the SDL development libraries
  to get a graphical VGA window.  On Debian/Ubuntu, this is the
  libsdl1.2-dev package.</li>
  <li>Configure the source code<br />
  Linux: <code>./configure --disable-kvm [--prefix=PFX] [--target-list="i386-softmmu x86_64-softmmu"]</code><br />
  OS X: <code>./configure --disable-kvm --disable-sdl [--prefix=PFX] [--target-list="i386-softmmu x86_64-softmmu"]</code><br />
  The <code>prefix</code> argument specifies where to install QEMU;
  without it QEMU will install to <tt>/usr/local</tt> by default.  The
  <code>target-list</code> argument simply slims down the
  architectures QEMU will build support for.
  </li>
  <li>Run <code>make &amp;&amp; make install</code></li>
</ol>

<h2>Debugging tips</h2>

<h3 id="debug-kernel">Kernel</h3>

<p>GDB is your friend.  Use the <a
href="#make-qemu-gdb"><kbd>qemu-gdb</kbd></a> target (or its <a
href="#make-qemu-gdb-nox"><tt>qemu-gdb-nox</tt></a> variant) to make
QEMU wait for GDB to attach.  See the <a href="#gdb">GDB</a> reference
below for some commands that are useful when debugging kernels.</p>

<p>If you're getting unexpected interrupts, exceptions, or triple
faults, you can ask QEMU to generate a detailed log of interrupts
using the <a href="#qemu--d">-d</a> argument.</p>

<p>To debug virtual memory issues, try the QEMU monitor commands <a
href="#qemu-info-mem"><kbd>info mem</kbd></a> (for a high-level
overview) or <a href="#qemu-info-pg"><kbd>info pg</kbd></a> (for lots
of detail).  Note that these commands only display the <i>current</i>
page table.</p>

<p>(Lab 4+) To debug multiple CPUs, use GDB's thread-related commands
like <a href="#gdb-thread"><kbd>thread</kbd></a> and <a
href="#gdb-info-threads"><kbd>info threads</kbd></a>.</p>

<h3 id="debug-user">User environments (lab 3+)</h3>

<p>GDB also lets you debug user environments, but there are a few
things you need to watch out for, since GDB doesn't know that there's
a distinction between multiple user environments, or between user and
kernel.</p>

<p>You can start JOS with a specific user environment using <a
href="#make-run"><kbd>make run-<i>name</i></kbd></a> (or you can edit
<tt>kern/init.c</tt> directly).  To make QEMU wait for GDB to attach,
use the <a href="#make-run-x"><kbd>run-<i>name</i>-gdb</kbd></a>
variant.</p>

<p>You can symbolically debug user code, just like you can kernel
code, but you have to tell GDB which <a href="#obj-elf">symbol
table</a> to use with the <a
href="#gdb-symbol-file"><kbd>symbol-file</kbd></a> command, since it
can only use one symbol table at a time.  The provided
<tt>.gdbinit</tt> loads the kernel symbol table,
<tt>obj/kern/kernel</tt>.  The symbol table for a user environment is
in its ELF binary, so you can load it using <kbd>symbol-file
obj/user/<i>name</i></kbd>.  <i>Don't</i> load symbols from any
<tt>.o</tt> files, as those haven't been relocated by the linker
(libraries are statically linked into JOS user binaries, so those
symbols are already included in each user binary).  Make sure you get
the <i>right</i> user binary; library functions will be linked at
different EIPs in different binaries and GDB won't know any
better!</p>

<p>(Lab 4+) Since GDB is attached to the virtual machine as a whole,
it sees clock interrupts as just another control transfer.  This makes
it basically impossible to step through user code because a clock
interrupt is virtually guaranteed the moment you let the VM run again.
The <a href="#gdb-si"><kbd>stepi</kbd></a> command works because it
suppresses interrupts, but it only steps one assembly instruction.  <a
href="#gdb-b">Breakpoints</a> generally work, but watch out because
you can hit the same EIP in a different environment (indeed, a
different binary altogether!).</p>

<h2>Reference</h2>

<h3 id="make">JOS makefile</h3>

The JOS GNUmakefile includes a number of phony targets for running JOS
in various ways.  All of these targets configure QEMU to listen for
GDB connections (the <tt>*-gdb</tt> targets also wait for this
connection).  To start once QEMU is running, simply run <kbd>gdb</kbd>
from your lab directory.  We provide a <tt>.gdbinit</tt> file that
automatically points GDB at QEMU, loads the kernel symbol file, and
switches between 16-bit and 32-bit mode.  Exiting GDB will shut down
QEMU.

<dl>
  <dt id="make-qemu"><kbd>make qemu</kbd></dt>
  <dd>Build everything and start QEMU with the VGA console in a new
  window and the serial console in your terminal.  To exit, either
  close the VGA window or press <tt>Ctrl-c</tt> or <tt>Ctrl-a x</tt>
  in your terminal.</dd>

  <dt id="make-qemu-nox"><kbd>make qemu-nox</kbd></dt>
  <dd>Like <tt>make qemu</tt>, but run with only the serial console.
  To exit, press <tt>Ctrl-a x</tt>.  This is particularly useful over
  SSH connections to Athena dialups because the VGA window consumes a
  lot of bandwidth.</dd>

  <dt id="make-qemu-gdb"><kbd>make qemu-gdb</kbd></dt>
  <dd>Like <tt>make qemu</tt>, but rather than passively accepting GDB
  connections at any time, this pauses at the first machine
  instruction and waits for a GDB connection.</dd>

  <dt id="make-qemu-gdb-nox"><kbd>make qemu-nox-gdb</kbd></dt>
  <dd>A combination of the <tt>qemu-nox</tt> and <tt>qemu-gdb</tt>
  targets.</dd>

  <dt id="make-run"><kbd>make run-<i>name</i></kbd></dt>
  <dd>(Lab 3+) Run user program <i>name</i>.  For example, <tt>make
  run-hello</tt> runs <tt>user/hello.c</tt>.</dd>

  <dt id="make-run-x"><kbd>make run-<i>name</i>-nox</kbd>,
      <kbd>run-<i>name</i>-gdb</kbd>,
      <kbd>run-<i>name</i>-gdb-nox</kbd>, </dt>
  <dd>(Lab 3+) Variants of <tt>run-<i>name</i></tt> that correspond to
  the variants of the <tt>qemu</tt> target.</dd>
</dl>

The makefile also accepts a few useful variables:

<dl>
  <dt id="make-v"><kbd>make V=1 ...</kbd></dt>
  <dd>Verbose mode.  Print out every command being executed, including
  arguments.</dd>

  <dt id="make-v-grade"><kbd>make V=1 grade</kbd></dt>
  <dd>Stop after any failed grade test and leave the QEMU output in
  <tt>jos.out</tt> for inspection.</dd>

  <dt id="make-qemuextra"><kbd>make QEMUEXTRA='<i>args</i>' ...</kbd></dt>
  <dd>Specify additional arguments to pass to QEMU.</dd>
</dl>

<h3 id="obj">JOS obj/</h3>

<p>When building JOS, the makefile also produces some additional
output files that may prove useful while debugging:</p>

<dl>
  <dt id="obj-asm"><tt>obj/boot/boot.asm</tt>,
  <tt>obj/kern/kernel.asm</tt>, <tt>obj/user/hello.asm</tt>, etc.</dt>
  <dd>Assembly code listings for the bootloader, kernel, and user
  programs.</dd>

  <dt id="obj-sym"><tt>obj/kern/kernel.sym</tt>,
  <tt>obj/user/hello.sym</tt>, etc.</dt>
  <dd>Symbol tables for the kernel and user programs.</dd>

  <dt id="obj-elf"><tt>obj/boot/boot.out</tt>, <tt>obj/kern/kernel</tt>,
  <tt>obj/user/hello</tt>, etc</dt>
  <dd>Linked ELF images of the kernel and user programs.  These
  contain symbol information that can be used by GDB.</dd>
</dl>

<h3 id="gdb">GDB</h3>

<p>See the <a
href="http://sourceware.org/gdb/current/onlinedocs/gdb/">GDB
manual</a> for a full guide to GDB commands.  Here are some
particularly useful commands for 6.828, some of which don't typically
come up outside of OS development.</p>

<dl>
  <dt id="gdb-ctrl-c"><kbd>Ctrl-c</kbd></dt>
  <dd>Halt the machine and break in to GDB at the current
  instruction.  If QEMU has multiple virtual CPUs, this halts all of
  them.</dd>

  <dt id="gdb-c"><kbd>c</kbd> (or <kbd>continue</kbd>)</dt>
  <dd>Continue execution until the next breakpoint or <tt>Ctrl-c</tt>.</dd>

  <dt id="gdb-si"><kbd>si</kbd> (or <kbd>stepi</kbd>)</dt>
  <dd>Execute one machine instruction.</dd>

  <dt id="gdb-b"><kbd>b function</kbd> or <kbd>b file:line</kbd> (or
  <kbd>breakpoint</kbd>)</dt>
  <dd>Set a breakpoint at the given function or line.</dd>

  <dt id="gdb-bstar"><kbd>b *<i>addr</i></kbd> (or <kbd>breakpoint</kbd>)</dt>
  <dd>Set a breakpoint at the EIP <i>addr</i>.</dd>

  <dt id="gdb-pretty"><kbd>set print pretty</kbd></dt>
  <dd>Enable pretty-printing of arrays and structs.</dd>

  <dt id="gdb-info-registers"><kbd>info registers</kbd></dt>
  <dd>Print the general purpose registers, <tt>eip</tt>,
  <tt>eflags</tt>, and the segment selectors.  For a much more
  thorough dump of the machine register state, see QEMU's own <tt>info
  registers</tt> command.</dd>

  <dt id="gdb-x-x"><kbd>x/<i>N</i>x <i>addr</i></kbd></dt>
  <dd>Display a hex dump of <i>N</i> words starting at virtual address
  <i>addr</i>.  If <i>N</i> is omitted, it defaults to 1.  <i>addr</i>
  can be any expression.</dd>

  <dt id="gdb-x-i"><kbd>x/<i>N</i>i <i>addr</i></kbd></dt>
  <dd>Display the <i>N</i> assembly instructions starting at
  <i>addr</i>.  Using <tt>$eip</tt> as <i>addr</i> will display the
  instructions at the current instruction pointer.</dd>

  <dt id="gdb-symbol-file"><kbd>symbol-file <i>file</i></kbd></dt>
  <dd>(Lab 3+) Switch to symbol file <i>file</i>.  When GDB attaches
  to QEMU, it has no notion of the process boundaries within the
  virtual machine, so we have to tell it which symbols to use.  By
  default, we configure GDB to use the kernel symbol file,
  <tt>obj/kern/kernel</tt>.  If the machine is running user code, say
  <tt>hello.c</tt>, you can switch to the hello symbol file using
  <tt>symbol-file obj/user/hello</tt>.</dd>
</dl>

<p>QEMU represents each virtual CPU as a thread in GDB, so you can use
all of GDB's thread-related commands to view or manipulate QEMU's
virtual CPUs.</p>

<dl>
  <dt id="gdb-thread"><kbd>thread <i>n</i></kbd></dt>
  <dd>GDB focuses on one thread (i.e., CPU) at a time.  This command
  switches that focus to thread <i>n</i>, numbered from zero.</dd>

  <dt id="gdb-info-threads"><kbd>info threads</kbd></dt>
  <dd>List all threads (i.e., CPUs), including their state (active or
  halted) and what function they're in.</dd>
</dl>

<h3 id="qemu">QEMU</h3>

<p>QEMU includes a built-in monitor that can inspect and modify the
machine state in useful ways.  To enter the monitor, press <kbd>Ctrl-a
c</kbd> in the terminal running QEMU.  Press <kbd>Ctrl-a c</kbd> again
to switch back to the serial console.</p>

<p>For a complete reference to the monitor commands, see the <a
href="http://wiki.qemu.org/download/qemu-doc.html#pcsys_005fmonitor">QEMU
manual</a>.  Here are some particularly useful commands:</p>

<dl>
  <dt id="qemu-xp"><kbd>xp/<i>N</i>x <i>paddr</i></kbd></dt>
  <dd>Display a hex dump of <i>N</i> words starting at <i>physical</i>
  address <i>paddr</i>.  If <i>N</i> is omitted, it defaults to 1.
  This is the physical memory analogue of GDB's <tt>x</tt>
  command.</dd>

  <dt id="qemu-info-registers"><kbd>info registers</kbd></dt>
  <dd>Display a full dump of the machine's internal register state.
  In particular, this includes the machine's <i>hidden</i> segment
  state for the segment selectors and the local, global, and interrupt
  descriptor tables, plus the task register.  This hidden state is the
  information the virtual CPU read from the GDT/LDT when the segment
  selector was loaded.  Here's the CS when running in the JOS kernel
  in lab 1 and the meaning of each field:

  <pre>CS =0008 10000000 ffffffff 10cf9a00 DPL=0 CS32 [-R-]</pre>
  <dl>
    <dt><tt>CS =0008</tt></dt>
    <dd>The visible part of the code selector.  We're using segment
    0x8.  This also tells us we're referring to the global descriptor
    table (0x8&amp;4=0), and our CPL (current privilege level) is
    0x8&amp;3=0.</dd>
    <dt><tt>10000000</tt></dt>
    <dd>The base of this segment.  Linear address = logical address +
    0x10000000.</dd>
    <dt><tt>ffffffff</tt></dt>
    <dd>The limit of this segment.  Linear addresses above 0xffffffff
    will result in segment violation exceptions.</dd>
    <dt><tt>10cf9a00</tt></dt>
    <dd>The raw flags of this segment, which QEMU helpfully decodes
    for us in the next few fields.</dd>
    <dt><tt>DPL=0</tt></dt>
    <dd>The privilege level of this segment.  Only code running with
    privilege level 0 can load this segment.</dd>
    <dt><tt>CS32</tt></dt>
    <dd>This is a 32-bit code segment.  Other values include
    <tt>DS</tt> for data segments (not to be confused with the DS
    register), and <tt>LDT</tt> for local descriptor tables.</dd>
    <dt><tt>[-R-]</tt></dt>
    <dd>This segment is read-only.</dd>
  </dl>
  </dd>

  <dt id="qemu-info-mem"><kbd>info mem</kbd></dt>
  <dd>(Lab 2+) Display mapped virtual memory and permissions.  For
  example,

  <pre>ef7c0000-ef800000 00040000 urw
efbf8000-efc00000 00008000 -rw</pre>

  tells us that the 0x00040000 bytes of memory from 0xef7c0000 to
  0xef800000 are mapped read/write and user-accessible, while the
  memory from 0xefbf8000 to 0xefc00000 is mapped read/write, but only
  kernel-accessible.
  </dd>

  <dt id="qemu-info-pg"><kbd>info pg</kbd></dt>
  <dd>(Lab 2+) Display the current page table structure.  The output
  is similar to <tt>info mem</tt>, but distinguishes page directory
  entries and page table entries and gives the permissions for each
  separately.  Repeated PTE's and entire page tables are folded up
  into a single line.  For example,

  <pre>VPN range     Entry         Flags        Physical page
[00000-003ff]  PDE[000]     -------UWP
  [00200-00233]  PTE[200-233] -------U-P 00380 0037e 0037d 0037c 0037b 0037a ..
[00800-00bff]  PDE[002]     ----A--UWP
  [00800-00801]  PTE[000-001] ----A--U-P 0034b 00349
  [00802-00802]  PTE[002]     -------U-P 00348
</pre>

  This shows two page directory entries, spanning virtual addresses
  0x00000000 to 0x003fffff and 0x00800000 to 0x00bfffff, respectively.
  Both PDE's are present, writable, and user and the second PDE is also
  accessed.  The second of these page tables maps three pages, spanning
  virtual addresses 0x00800000 through 0x00802fff, of which the first
  two are present, user, and accessed and the third is only present and
  user.  The first of these PTE's maps physical page 0x34b.
  </dd>
</dl>

QEMU also takes some useful command line arguments, which can be
passed into the JOS makefile using the <a href="#make-qemuextra"
>QEMUEXTRA</a> variable.

<dl>
  <dt id="qemu--d"><kbd>make QEMUEXTRA='-d int' ...</kbd></dt>
  <dd>Log all interrupts, along with a full register dump, to
  <tt>qemu.log</tt>.  You can ignore the first two log entries, "SMM:
  enter" and "SMM: after RMS", as these are generated before entering
  the boot loader.  After this, log entries look like
  <pre>     4: v=30 e=0000 i=1 cpl=3 IP=001b:00800e2e pc=00800e2e SP=0023:eebfdf28 EAX=00000005
EAX=00000005 EBX=00001002 ECX=00200000 EDX=00000000
ESI=00000805 EDI=00200000 EBP=eebfdf60 ESP=eebfdf28
...</pre>
  The first line describes the interrupt.  The <tt>4:</tt> is just a
  log record counter.  <tt>v</tt> gives the vector number in hex.
  <tt>e</tt> gives the error code.  <tt>i=1</tt> indicates that this
  was produced by an <code>int</code> instruction (versus a hardware
  interrupt).  The rest of the line should be self-explanatory.  See
  <a href="#qemu-info-registers">info registers</a> for a description
  of the register dump that follows.
  </dd>
  <dd>Note: If you're running a pre-0.15 version of QEMU, the log will
  be written to <tt>/tmp</tt> instead of the current directory.</dd>
</dl>
