<h2>OS textbooks</h2>
<h3>UNIX</h3>
<ul>
   <li>    <a href="https://www.youtube.com/watch?v=tc4ROCJYbm0">Youtube Unix intro</a>
   <li>	<a href="http://citeseer.ist.psu.edu/10962.html">
      The UNIX Time-Sharing System</a>,
      <a href="http://cm.bell-labs.com/who/dmr/">Dennis
      M. Ritchie</a>
      and <a href="http://cm.bell-labs.com/who/ken/">Ken
      L.Thompson</a>,.
      Bell System Technical Journal 57, number 6, part 2
      (July-August 1978) pages 1905-1930.
      <a href="readings/ritchie78unix.pdf">(local copy)</a>
      You read this paper in 6.033.
   <li>	<a href="http://www.read.seas.harvard.edu/~kohler/class/aosref/ritchie84evolution.pdf">
      The Evolution of the Unix Time-sharing System</a>,
      Dennis M. Ritchie, 1979.
   <li><i>The C programming language (second edition)</i> by Kernighan
      and Ritchie. Prentice Hall, Inc., 1988. ISBN 0-13-110362-8, 1998.
</ul>
<h2>C programming</h2>
<p>The classic book on C:</p>
<ul>
   <li><i>The C programming language (second edition)</i>, Brian W. Kernighan
      and Dennis M. Ritchie. Prentice Hall, Inc., 1988. ISBN: 0-13-110362-8.
   </li>
</ul>
<h2>Programming Intel vmx</h2>
<p>Although there are good summaries around the web, the relevant chapters of 
   Volume 3c Part 3 of the 
   <a href="ref/vmx/64-ia-32-architectures-software-developer-vol-3c-part-3-manual.pdf">Intel manual</a> 
   are the most comprehensive explanation of how to program 
   this hardware.
</p>
<h2>x86 Assembly Language Programming</h2>
<ul>
   <li>
      <a href='http://www.drpaulcarter.com/pcasm/'><i>PC Assembly
      Language</i></a>, Paul A. Carter, November 2003.  188pp.  <a
         href='ref/carter03pc.pdf'>(local PDF copy)</a>
      <p class='note'>A clear description of x86 assembly language and assembly
         language in general, including some stuff you ideally know already.
         You might prefer to read this on line, rather than print it out; it's a
         quick read.  <i>Warning:</i> This book uses "Intel" assembly syntax, in
         which instructions are written "<code>instr dst, src</code>"; we will use
         "AT&amp;T" assembly syntax, in which they are written "<code>instr src,
         dst</code>".  You don't need to read the following sections, which will
         not be needed for class: 1.3.6-1.3.7, 1.4, 1.5, 5, 6, and 7.2.
      </p>
   </li>
   <li>
      <a
         href='http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html'>Brennan's
      Guide to Inline Assembly</a>, Brennan "Bas" Underwood.  <a
         href='ref/brennansguide.html'>(local copy)</a>
      <p class='note'>A short and sweet description of how to use inline assembly
         instructions with GCC.  Includes a description of the "AT&amp;T" assembly
         syntax used by GCC.
      </p>
   </li>
   <li>
      <b>Reference Manuals</b>
      <ul>
         <li>
            <i>Intel 80386 Programmer's Reference Manual</i>, 1987 (HTML).
            <a href="ref/i386/toc.htm">(local copy - HTML)</a>
            <a href='ref/i386.pdf'>(local copy - PDF)</a>
            <p class='note'>Much shorter than the current Intel Architecture manuals,
               but describes most of the processor features we'll use.  The original was
               a flat text file that used the PC <a
                  href='ref/codepage437linedrawing.gif'>Line Drawing characters</a> for
               diagrams; this, and many other versions, are available on the
               net. JOS uses the following 486-and-later features, which you
               can read about in the IA-32 manuals: The
               <code>%cr0</code> register's <code>WP</code> bit (Volume 3).
            </p>
         </li>
         <li>
            <a
               href="http://developer.intel.com/products/processor/manuals/index.htm">IA-32
            Intel Architecture Software Developer's Manuals</a>, Intel, 2007.  Local copies:
            <ul>
               <li>	<a href="ref/ia32/IA32-1.pdf">
                  Volume 1: Basic Architecture</a>
               </li>
               <li>	<a href="ref/ia32/IA32-2A.pdf">
                  Volume 2A: Instruction Set Reference, A-M</a>
               </li>
               <li>	<a href="ref/ia32/IA32-2B.pdf">
                  Volume 2B: Instruction Set Reference, N-Z</a>
               </li>
               <li>	<a href="ref/ia32/IA32-3A.pdf">
                  Volume 3A: System Programming Guide, Part 1</a>
               </li>
               <li>	<a href="ref/ia32/IA32-3B.pdf">
                  Volume 3B: System Programming Guide, Part 2</a>
               </li>
            </ul>
            <p class='note'>The latest and longest documents from Intel.</p>
         </li>
         <li>
            <a
               href="http://www.amd.com/us-en/Processors/DevelopWithAMD/0,,30_2252_739_7044,00.html">AMD64 Architecture Programmer's Manual</a>
            <p class='note'>Covers both the "classic" 32-bit x86 architecture and the
               new 64-bit extensions supported by the latest AMD and Intel
               processors.
            </p>
         </li>
         <li>
            Multiprocessor references:
            <ul>
               <li>	<a href="ref/ia32/MPspec.pdf">MP
                  specification</a>
               </li>
               <li>	<a href="ref/ia32/ioapic.pdf">IO APIC</a></li>
            </ul>
         </li>
      </ul>
   </li>
   <li>
      <a href="ref/elf-1.2.pdf">Tool Interface Standard (TIS) Executable and
      Linking Format (ELF) Specification, Version
      1.2</a>
      <p class='note'>Our kernel runs ELF executables; this is the definitive
         standard for how these executables are constructed.
      </p>
   </li>
   <li><a
      href='http://ftp.gnu.org/pub/old-gnu/Manuals/ld-2.9.1/html_node/ld_5.html'>GNU ld Command Language</a> (for linker scripts)</li>
   <li><a href="http://sources.redhat.com/gdb/onlinedocs/stabs.html">The STABS Debugging Format</a> (for the debugging symbols used by our kernel)</li>
</ul>
<h2>x86 Emulation</h2>
<ul>
   <li>
      <a href="http://bochs.sourceforge.net">Bochs</a> - An x86 platform
      and CPU emulator.
      <ul>
         <li><a
            href="http://bochs.sourceforge.net/doc/docbook/user/index.html">User
            manual</a>
         </li>
         <li><a
            href="http://bochs.sourceforge.net/doc/docbook/user/internal-debugger.html">Debugger
            reference</a>
         </li>
      </ul>
   </li>
   <li>	<a href="http://bellard.org/qemu/">QEMU</a> -
      A new, much faster but less mature PC emulator.
      We now use qemu as the default JOS platform.
   </li>
</ul>
<h2> PC Hardware Progamming </h2>
<ul>
   <li>
      General PC architecture information
      <ul>
         <li>	<a href="http://web.archive.org/web/20040603021346/http://members.iweb.net.au/~pstorr/pcbook/">
            Phil Storrs PC Hardware book</a>,
            Phil Storrs, December 1998.
         <li>	<a href="http://bochs.sourceforge.net/techdata.html">
            Bochs technical hardware specifications directory</a>.
      </ul>
   <li>
      General BIOS and PC bootstrap
      <ul>
         <!--	<li>	<a href="http://www.bioscentral.com/">BIOS Central</a> -->
         <li>	<a href="http://www.htl-steyr.ac.at/~morg/pcinfo/hardware/interrupts/inte1at0.htm">BIOS Services and Software Interrupts</a>,
            Roger Morgan, 1997.
         <li>	<a href="readings/boot-cdrom.pdf">
            "El Torito" Bootable CD-ROM Format Specification</a>,
            Phoenix/IBM, January 1995.
      </ul>
   <li>
      VGA display - <samp>kern/console.c</samp>
      <ul>
         <li>	<a href="http://web.archive.org/web/20080302090304/http://www.vesa.org/public/VBE/vbe3.pdf">
            VESA BIOS Extension (VBE) 3.0</a>,
            <a href="http://www.vesa.org/">
            Video Electronics Standards Association</a>,
            September 1998.
            <a href="readings/hardware/vbe3.pdf">(local copy)</a>
         <li>	VGADOC, Finn Th&oslash;gersen, 2000.
            <a href="readings/hardware/vgadoc/">(local copy - text)</a>
            <a href="readings/hardware/vgadoc4b.zip">(local copy - ZIP)</a>
         <li>	<a href="http://www.osdever.net/FreeVGA/home.htm">
            Free VGA Project</a>, J.D. Neal, 1998.
      </ul>
   <li>
      Keyboard and Mouse - <samp>kern/console.c</samp>
      <ul>
         <li>	<a
            href="http://www.computer-engineering.org/index.html">Adam
            Chapweske's resources</a>.
      </ul>
   <li>
      8253/8254 Programmable Interval Timer (PIT)
      - <samp>inc/timerreg.h</samp>
      <ul>
         <li>	<a href="http://www.intel.com/design/archives/periphrl/docs/23124406.htm">82C54 CHMOS Programmable Interval Timer</a>,
            Intel, October 1994.
            <a href="readings/hardware/82C54.pdf">(local copy)</a>
         <li>	<a href="http://www.decisioncards.com/io/tutorials/8254_tut.html">Data Solutions 8253/8254 Tutorial</a>,
            Data Solutions.
      </ul>
   <li>
      8259/8259A Programmable Interrupt Controller (PIC)
      - <samp>kern/picirq.*</samp>
      <ul>
         <li>	<a href="readings/hardware/8259A.pdf">
            8259A Programmable Interrupt Controller</a>,
            Intel, December 1988.
      </ul>
   <li>
      Real-Time Clock (RTC)
      - <samp>kern/kclock.*</samp>
      <ul>
         <li>
            <a href="http://web.archive.org/web/20040603021346/http://members.iweb.net.au/~pstorr/pcbook/">
            Phil Storrs PC Hardware book</a>,
            Phil Storrs, December 1998.  In particular:
            <ul>
               <li>	<a href="http://web.archive.org/web/20040603021346/http://members.iweb.net.au/~pstorr/pcbook/book5/cmos.htm">Understanding the CMOS</a>
               <li>	<a href="http://web.archive.org/web/20040603021346/http://members.iweb.net.au/~pstorr/pcbook/book5/cmoslist.htm">A list of what is in the CMOS</a>
            </ul>
         <li>	<a href="http://bochs.sourceforge.net/techspec/CMOS-reference.txt">
            CMOS Memory Map</a>, Padgett Peterson, May 1996.
         <li>	<a href="http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/DATASHEET/CD00001009.pdf">
            M48T86 PC Real-Time Clock</a>,
            ST Microelectronics, April 2004.
            <a href="readings/hardware/M48T86.pdf">(local copy)</a>
      </ul>
   <li>
      16550 UART Serial Port - <samp>kern/console.c</samp>
      <ul>
         <li>	<a href="http://www.national.com/pf/PC/PC16550D.html">
            PC16550D Universal Asynchronous Receiver/Transmitter
            with FIFOs</a>,
            National Semiconductor, 1995.
         <li>	<a href="http://byterunner.com/16550.html">
            Technical Data on 16550</a>,
            Byterunner Technologies.
         <li>	<a href="http://www.beyondlogic.org/serial/serial.htm">
            Interfacing the Serial / RS232 Port</a>,
            Craig Peacock, August 2001.
      </ul>
   <li>
      IEEE 1284 Parallel Port - <samp>kern/console.c</samp>
      <ul>
         <li>	<a href="http://www.lvr.com/parport.htm">
            Parallel Port Central</a>, Jan Axelson.
         <li>	<a href="http://www.fapo.com/porthist.htm">
            Parallel Port Background</a>, Warp Nine Engineering.
         <li>	<a href="http://zone.ni.com/devzone/cda/tut/p/id/3466">
            IEEE 1284 - Updating the PC Parallel Port</a>,
            National Instruments.
         <li>	<a href="http://www.beyondlogic.org/spp/parallel.htm">
            Interfacing the Standard Parallel Port</a>,
            Craig Peacock, August 2001.
      </ul>
   <li>
      IDE hard drive controller - <samp>fs/ide.c</samp>
      <ul>
         <li>	<a href="readings/hardware/ATA-d1410r3a.pdf">
            AT Attachment with Packet Interface - 6 (working draft)</a>,
            ANSI, December 2001.
         <li>	<a href="readings/hardware/IDE-BusMaster.pdf">
            Programming Interface for Bus Master IDE Controller</a>,
            Brad Hosler, Intel, May 1994.
         <li>	<a href="http://suif.stanford.edu/~csapuntz/ide.html">
            The Guide to ATA/ATAPI documentation</a>,
            Constantine Sapuntzakis, January 2002.
      </ul>
   <li>
      Sound cards
      (not supported in 6.828 kernel,
      but you're welcome to do it as a challenge problem!)
      <ul>
         <!--	<li>	<a href="http://www.stud.fh-hannover.de/~heineman/proginfo.htm">
            Signal Processing using Sound Cards</a> -->
         <li>	<a href="readings/hardware/SoundBlaster.pdf">
            Sound Blaster Series Hardware Programming Guide</a>,
            Creative Technology, 1996.
         <li>	<a href="readings/hardware/8237A.pdf">
            8237A High Performance Programmable DMA Controller</a>,
            Intel, September 1993.
         <li>	<a href="http://homepages.cae.wisc.edu/~brodskye/sb16doc/sb16doc.html">
            Sound Blaster 16 Programming Document</a>,
            Ethan Brodsky, June 1997.
         <li>	<a href="http://www.inversereality.org/tutorials/sound%20programming/soundprogramming.html">Sound Programming</a>,
            Inverse Reality.
      </ul>
   <li>
      E100 Network Interface Card
      <ul>
         <li>	<a href="readings/hardware/8255X_OpenSDM.pdf">
            Intel 8255x 10/100 Mbps Ethernet Controller Family Open Source Software Developer Manual</a>
         <li>	<a href="readings/hardware/82559ER_datasheet.pdf">82559ER Fast Ethernet PCI Controller Datasheet</a>
      </ul>
   <li>
      E1000 Network Interface Card
      <ul>
         <li><a href="readings/hardware/8254x_GBe_SDM.pdf">PCI/PCI-X
            Family of Gigabit Ethernet Controllers Software Developer’s
            Manual</a>
         </li>
      </ul>
   </li>
</ul>
