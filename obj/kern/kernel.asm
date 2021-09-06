
obj/kern/kernel:     file format elf64-x86-64


Disassembly of section .bootstrap:

0000000000100000 <_head64>:
.globl _head64
_head64:

# Save multiboot_info addr passed by bootloader
	
    movl $multiboot_info, %eax
  100000:	b8 00 70 10 00       	mov    $0x107000,%eax
    movl %ebx, (%eax)
  100005:	89 18                	mov    %ebx,(%rax)

    movw $0x1234,0x472			# warm boot	
  100007:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472(%rip)        # 100482 <verify_cpu_no_longmode+0x36f>
  10000e:	34 12 
	
# Reset the stack pointer in case we didn't come from the loader
    movl $0x7c00,%esp
  100010:	bc 00 7c 00 00       	mov    $0x7c00,%esp

    call verify_cpu   #check if CPU supports long mode
  100015:	e8 cc 00 00 00       	callq  1000e6 <verify_cpu>
    movl $CR4_PAE,%eax	
  10001a:	b8 20 00 00 00       	mov    $0x20,%eax
    movl %eax,%cr4
  10001f:	0f 22 e0             	mov    %rax,%cr4

# build an early boot pml4 at physical address pml4phys 

    #initializing the page tables
    movl $pml4,%edi
  100022:	bf 00 20 10 00       	mov    $0x102000,%edi
    xorl %eax,%eax
  100027:	31 c0                	xor    %eax,%eax
    movl $((4096/4)*5),%ecx  # moving these many words to the 6 pages with 4 second level pages + 1 3rd level + 1 4th level pages 
  100029:	b9 00 14 00 00       	mov    $0x1400,%ecx
    rep stosl
  10002e:	f3 ab                	rep stos %eax,%es:(%rdi)
    # creating a 4G boot page table
    # setting the 4th level page table only the second entry needed (PML4)
    movl $pml4,%eax
  100030:	b8 00 20 10 00       	mov    $0x102000,%eax
    movl $pdpt1, %ebx
  100035:	bb 00 30 10 00       	mov    $0x103000,%ebx
    orl $PTE_P,%ebx
  10003a:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10003d:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,(%eax)
  100040:	89 18                	mov    %ebx,(%rax)

    movl $pdpt2, %ebx
  100042:	bb 00 40 10 00       	mov    $0x104000,%ebx
    orl $PTE_P,%ebx
  100047:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10004a:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,0x8(%eax)
  10004d:	89 58 08             	mov    %ebx,0x8(%rax)

    # setting the 3rd level page table (PDPE)
    # 4 entries (counter in ecx), point to the next four physical pages (pgdirs)
    # pgdirs in 0xa0000--0xd000
    movl $pdpt1,%edi
  100050:	bf 00 30 10 00       	mov    $0x103000,%edi
    movl $pde1,%ebx
  100055:	bb 00 50 10 00       	mov    $0x105000,%ebx
    orl $PTE_P,%ebx
  10005a:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10005d:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,(%edi)
  100060:	89 1f                	mov    %ebx,(%rdi)

    movl $pdpt2,%edi
  100062:	bf 00 40 10 00       	mov    $0x104000,%edi
    movl $pde2,%ebx
  100067:	bb 00 60 10 00       	mov    $0x106000,%ebx
    orl $PTE_P,%ebx
  10006c:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10006f:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,(%edi)
  100072:	89 1f                	mov    %ebx,(%rdi)
    
    # setting the pgdir so that the LA=PA
    # mapping first 1G of mem at KERNBASE
    movl $128,%ecx
  100074:	b9 80 00 00 00       	mov    $0x80,%ecx
    # Start at the end and work backwards
    #leal (pml4 + 5*0x1000 - 0x8),%edi
    movl $pde1,%edi
  100079:	bf 00 50 10 00       	mov    $0x105000,%edi
    movl $pde2,%ebx
  10007e:	bb 00 60 10 00       	mov    $0x106000,%ebx
    #64th entry - 0x8004000000
    addl $256,%ebx 
  100083:	81 c3 00 01 00 00    	add    $0x100,%ebx
    # PTE_P|PTE_W|PTE_MBZ
    movl $0x00000183,%eax
  100089:	b8 83 01 00 00       	mov    $0x183,%eax
  1:
     movl %eax,(%edi)
  10008e:	89 07                	mov    %eax,(%rdi)
     movl %eax,(%ebx)
  100090:	89 03                	mov    %eax,(%rbx)
     addl $0x8,%edi
  100092:	83 c7 08             	add    $0x8,%edi
     addl $0x8,%ebx
  100095:	83 c3 08             	add    $0x8,%ebx
     addl $0x00200000,%eax
  100098:	05 00 00 20 00       	add    $0x200000,%eax
     subl $1,%ecx
  10009d:	83 e9 01             	sub    $0x1,%ecx
     cmp $0x0,%ecx
  1000a0:	83 f9 00             	cmp    $0x0,%ecx
     jne 1b
  1000a3:	75 e9                	jne    10008e <_head64+0x8e>
 /*    subl $1,%ecx */
 /*    cmp $0x0,%ecx */
 /*    jne 1b */

    # set the cr3 register
    movl $pml4,%eax
  1000a5:	b8 00 20 10 00       	mov    $0x102000,%eax
    movl %eax, %cr3
  1000aa:	0f 22 d8             	mov    %rax,%cr3

	
    # enable the long mode in MSR
    movl $EFER_MSR,%ecx
  1000ad:	b9 80 00 00 c0       	mov    $0xc0000080,%ecx
    rdmsr
  1000b2:	0f 32                	rdmsr  
    btsl $EFER_LME,%eax
  1000b4:	0f ba e8 08          	bts    $0x8,%eax
    wrmsr
  1000b8:	0f 30                	wrmsr  
    
    # enable paging 
    movl %cr0,%eax
  1000ba:	0f 20 c0             	mov    %cr0,%rax
    orl $CR0_PE,%eax
  1000bd:	83 c8 01             	or     $0x1,%eax
    orl $CR0_PG,%eax
  1000c0:	0d 00 00 00 80       	or     $0x80000000,%eax
    orl $CR0_AM,%eax
  1000c5:	0d 00 00 04 00       	or     $0x40000,%eax
    orl $CR0_WP,%eax
  1000ca:	0d 00 00 01 00       	or     $0x10000,%eax
    orl $CR0_MP,%eax
  1000cf:	83 c8 02             	or     $0x2,%eax
    movl %eax,%cr0
  1000d2:	0f 22 c0             	mov    %rax,%cr0
    #jump to long mode with CS=0 and

    movl $gdtdesc_64,%eax
  1000d5:	b8 18 10 10 00       	mov    $0x101018,%eax
    lgdt (%eax)
  1000da:	0f 01 10             	lgdt   (%rax)
    pushl $0x8
  1000dd:	6a 08                	pushq  $0x8
    movl $_start,%eax
  1000df:	b8 0c 00 20 00       	mov    $0x20000c,%eax
    pushl %eax
  1000e4:	50                   	push   %rax

00000000001000e5 <jumpto_longmode>:
    
    .globl jumpto_longmode
    .type jumpto_longmode,@function
jumpto_longmode:
    lret
  1000e5:	cb                   	lret   

00000000001000e6 <verify_cpu>:
/*     movabs $_back_from_head64, %rax */
/*     pushq %rax */
/*     lretq */

verify_cpu:
    pushfl                   # get eflags in eax -- standardard way to check for cpuid
  1000e6:	9c                   	pushfq 
    popl %eax
  1000e7:	58                   	pop    %rax
    movl %eax,%ecx
  1000e8:	89 c1                	mov    %eax,%ecx
    xorl $0x200000, %eax
  1000ea:	35 00 00 20 00       	xor    $0x200000,%eax
    pushl %eax
  1000ef:	50                   	push   %rax
    popfl
  1000f0:	9d                   	popfq  
    pushfl
  1000f1:	9c                   	pushfq 
    popl %eax
  1000f2:	58                   	pop    %rax
    cmpl %eax,%ebx
  1000f3:	39 c3                	cmp    %eax,%ebx
    jz verify_cpu_no_longmode   # no cpuid -- no long mode
  1000f5:	74 1c                	je     100113 <verify_cpu_no_longmode>

    movl $0x0,%eax              # see if cpuid 1 is implemented
  1000f7:	b8 00 00 00 00       	mov    $0x0,%eax
    cpuid
  1000fc:	0f a2                	cpuid  
    cmpl $0x1,%eax
  1000fe:	83 f8 01             	cmp    $0x1,%eax
    jb verify_cpu_no_longmode    # cpuid 1 is not implemented
  100101:	72 10                	jb     100113 <verify_cpu_no_longmode>


    mov $0x80000001, %eax
  100103:	b8 01 00 00 80       	mov    $0x80000001,%eax
    cpuid                 
  100108:	0f a2                	cpuid  
    test $(1 << 29),%edx                 #Test if the LM-bit, is set or not.
  10010a:	f7 c2 00 00 00 20    	test   $0x20000000,%edx
    jz verify_cpu_no_longmode
  100110:	74 01                	je     100113 <verify_cpu_no_longmode>

    ret
  100112:	c3                   	retq   

0000000000100113 <verify_cpu_no_longmode>:

verify_cpu_no_longmode:
    jmp verify_cpu_no_longmode
  100113:	eb fe                	jmp    100113 <verify_cpu_no_longmode>
  100115:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10011c:	00 00 00 
  10011f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100126:	00 00 00 
  100129:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100130:	00 00 00 
  100133:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10013a:	00 00 00 
  10013d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100144:	00 00 00 
  100147:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10014e:	00 00 00 
  100151:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100158:	00 00 00 
  10015b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100162:	00 00 00 
  100165:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10016c:	00 00 00 
  10016f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100176:	00 00 00 
  100179:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100180:	00 00 00 
  100183:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10018a:	00 00 00 
  10018d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100194:	00 00 00 
  100197:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10019e:	00 00 00 
  1001a1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001a8:	00 00 00 
  1001ab:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001b2:	00 00 00 
  1001b5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001bc:	00 00 00 
  1001bf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001c6:	00 00 00 
  1001c9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001d0:	00 00 00 
  1001d3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001da:	00 00 00 
  1001dd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001e4:	00 00 00 
  1001e7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001ee:	00 00 00 
  1001f1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1001f8:	00 00 00 
  1001fb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100202:	00 00 00 
  100205:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10020c:	00 00 00 
  10020f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100216:	00 00 00 
  100219:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100220:	00 00 00 
  100223:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10022a:	00 00 00 
  10022d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100234:	00 00 00 
  100237:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10023e:	00 00 00 
  100241:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100248:	00 00 00 
  10024b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100252:	00 00 00 
  100255:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10025c:	00 00 00 
  10025f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100266:	00 00 00 
  100269:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100270:	00 00 00 
  100273:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10027a:	00 00 00 
  10027d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100284:	00 00 00 
  100287:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10028e:	00 00 00 
  100291:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100298:	00 00 00 
  10029b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002a2:	00 00 00 
  1002a5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002ac:	00 00 00 
  1002af:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002b6:	00 00 00 
  1002b9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002c0:	00 00 00 
  1002c3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002ca:	00 00 00 
  1002cd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002d4:	00 00 00 
  1002d7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002de:	00 00 00 
  1002e1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002e8:	00 00 00 
  1002eb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002f2:	00 00 00 
  1002f5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1002fc:	00 00 00 
  1002ff:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100306:	00 00 00 
  100309:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100310:	00 00 00 
  100313:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10031a:	00 00 00 
  10031d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100324:	00 00 00 
  100327:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10032e:	00 00 00 
  100331:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100338:	00 00 00 
  10033b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100342:	00 00 00 
  100345:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10034c:	00 00 00 
  10034f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100356:	00 00 00 
  100359:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100360:	00 00 00 
  100363:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10036a:	00 00 00 
  10036d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100374:	00 00 00 
  100377:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10037e:	00 00 00 
  100381:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100388:	00 00 00 
  10038b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100392:	00 00 00 
  100395:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10039c:	00 00 00 
  10039f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003a6:	00 00 00 
  1003a9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003b0:	00 00 00 
  1003b3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003ba:	00 00 00 
  1003bd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003c4:	00 00 00 
  1003c7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003ce:	00 00 00 
  1003d1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003d8:	00 00 00 
  1003db:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003e2:	00 00 00 
  1003e5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003ec:	00 00 00 
  1003ef:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1003f6:	00 00 00 
  1003f9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100400:	00 00 00 
  100403:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10040a:	00 00 00 
  10040d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100414:	00 00 00 
  100417:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10041e:	00 00 00 
  100421:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100428:	00 00 00 
  10042b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100432:	00 00 00 
  100435:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10043c:	00 00 00 
  10043f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100446:	00 00 00 
  100449:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100450:	00 00 00 
  100453:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10045a:	00 00 00 
  10045d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100464:	00 00 00 
  100467:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10046e:	00 00 00 
  100471:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100478:	00 00 00 
  10047b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100482:	00 00 00 
  100485:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10048c:	00 00 00 
  10048f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100496:	00 00 00 
  100499:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004a0:	00 00 00 
  1004a3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004aa:	00 00 00 
  1004ad:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004b4:	00 00 00 
  1004b7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004be:	00 00 00 
  1004c1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004c8:	00 00 00 
  1004cb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004d2:	00 00 00 
  1004d5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004dc:	00 00 00 
  1004df:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004e6:	00 00 00 
  1004e9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004f0:	00 00 00 
  1004f3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1004fa:	00 00 00 
  1004fd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100504:	00 00 00 
  100507:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10050e:	00 00 00 
  100511:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100518:	00 00 00 
  10051b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100522:	00 00 00 
  100525:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10052c:	00 00 00 
  10052f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100536:	00 00 00 
  100539:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100540:	00 00 00 
  100543:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10054a:	00 00 00 
  10054d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100554:	00 00 00 
  100557:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10055e:	00 00 00 
  100561:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100568:	00 00 00 
  10056b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100572:	00 00 00 
  100575:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10057c:	00 00 00 
  10057f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100586:	00 00 00 
  100589:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100590:	00 00 00 
  100593:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10059a:	00 00 00 
  10059d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005a4:	00 00 00 
  1005a7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005ae:	00 00 00 
  1005b1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005b8:	00 00 00 
  1005bb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005c2:	00 00 00 
  1005c5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005cc:	00 00 00 
  1005cf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005d6:	00 00 00 
  1005d9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005e0:	00 00 00 
  1005e3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005ea:	00 00 00 
  1005ed:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005f4:	00 00 00 
  1005f7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1005fe:	00 00 00 
  100601:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100608:	00 00 00 
  10060b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100612:	00 00 00 
  100615:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10061c:	00 00 00 
  10061f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100626:	00 00 00 
  100629:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100630:	00 00 00 
  100633:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10063a:	00 00 00 
  10063d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100644:	00 00 00 
  100647:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10064e:	00 00 00 
  100651:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100658:	00 00 00 
  10065b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100662:	00 00 00 
  100665:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10066c:	00 00 00 
  10066f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100676:	00 00 00 
  100679:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100680:	00 00 00 
  100683:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10068a:	00 00 00 
  10068d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100694:	00 00 00 
  100697:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10069e:	00 00 00 
  1006a1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006a8:	00 00 00 
  1006ab:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006b2:	00 00 00 
  1006b5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006bc:	00 00 00 
  1006bf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006c6:	00 00 00 
  1006c9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006d0:	00 00 00 
  1006d3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006da:	00 00 00 
  1006dd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006e4:	00 00 00 
  1006e7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006ee:	00 00 00 
  1006f1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1006f8:	00 00 00 
  1006fb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100702:	00 00 00 
  100705:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10070c:	00 00 00 
  10070f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100716:	00 00 00 
  100719:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100720:	00 00 00 
  100723:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10072a:	00 00 00 
  10072d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100734:	00 00 00 
  100737:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10073e:	00 00 00 
  100741:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100748:	00 00 00 
  10074b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100752:	00 00 00 
  100755:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10075c:	00 00 00 
  10075f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100766:	00 00 00 
  100769:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100770:	00 00 00 
  100773:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10077a:	00 00 00 
  10077d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100784:	00 00 00 
  100787:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10078e:	00 00 00 
  100791:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100798:	00 00 00 
  10079b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007a2:	00 00 00 
  1007a5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007ac:	00 00 00 
  1007af:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007b6:	00 00 00 
  1007b9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007c0:	00 00 00 
  1007c3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007ca:	00 00 00 
  1007cd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007d4:	00 00 00 
  1007d7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007de:	00 00 00 
  1007e1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007e8:	00 00 00 
  1007eb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007f2:	00 00 00 
  1007f5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1007fc:	00 00 00 
  1007ff:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100806:	00 00 00 
  100809:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100810:	00 00 00 
  100813:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10081a:	00 00 00 
  10081d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100824:	00 00 00 
  100827:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10082e:	00 00 00 
  100831:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100838:	00 00 00 
  10083b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100842:	00 00 00 
  100845:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10084c:	00 00 00 
  10084f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100856:	00 00 00 
  100859:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100860:	00 00 00 
  100863:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10086a:	00 00 00 
  10086d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100874:	00 00 00 
  100877:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10087e:	00 00 00 
  100881:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100888:	00 00 00 
  10088b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100892:	00 00 00 
  100895:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10089c:	00 00 00 
  10089f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008a6:	00 00 00 
  1008a9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008b0:	00 00 00 
  1008b3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008ba:	00 00 00 
  1008bd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008c4:	00 00 00 
  1008c7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008ce:	00 00 00 
  1008d1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008d8:	00 00 00 
  1008db:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008e2:	00 00 00 
  1008e5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008ec:	00 00 00 
  1008ef:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1008f6:	00 00 00 
  1008f9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100900:	00 00 00 
  100903:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10090a:	00 00 00 
  10090d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100914:	00 00 00 
  100917:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10091e:	00 00 00 
  100921:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100928:	00 00 00 
  10092b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100932:	00 00 00 
  100935:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10093c:	00 00 00 
  10093f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100946:	00 00 00 
  100949:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100950:	00 00 00 
  100953:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10095a:	00 00 00 
  10095d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100964:	00 00 00 
  100967:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10096e:	00 00 00 
  100971:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100978:	00 00 00 
  10097b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100982:	00 00 00 
  100985:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  10098c:	00 00 00 
  10098f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100996:	00 00 00 
  100999:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009a0:	00 00 00 
  1009a3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009aa:	00 00 00 
  1009ad:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009b4:	00 00 00 
  1009b7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009be:	00 00 00 
  1009c1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009c8:	00 00 00 
  1009cb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009d2:	00 00 00 
  1009d5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009dc:	00 00 00 
  1009df:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009e6:	00 00 00 
  1009e9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009f0:	00 00 00 
  1009f3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  1009fa:	00 00 00 
  1009fd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a04:	00 00 00 
  100a07:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a0e:	00 00 00 
  100a11:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a18:	00 00 00 
  100a1b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a22:	00 00 00 
  100a25:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a2c:	00 00 00 
  100a2f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a36:	00 00 00 
  100a39:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a40:	00 00 00 
  100a43:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a4a:	00 00 00 
  100a4d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a54:	00 00 00 
  100a57:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a5e:	00 00 00 
  100a61:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a68:	00 00 00 
  100a6b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a72:	00 00 00 
  100a75:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a7c:	00 00 00 
  100a7f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a86:	00 00 00 
  100a89:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a90:	00 00 00 
  100a93:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100a9a:	00 00 00 
  100a9d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100aa4:	00 00 00 
  100aa7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100aae:	00 00 00 
  100ab1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ab8:	00 00 00 
  100abb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ac2:	00 00 00 
  100ac5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100acc:	00 00 00 
  100acf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ad6:	00 00 00 
  100ad9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ae0:	00 00 00 
  100ae3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100aea:	00 00 00 
  100aed:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100af4:	00 00 00 
  100af7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100afe:	00 00 00 
  100b01:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b08:	00 00 00 
  100b0b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b12:	00 00 00 
  100b15:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b1c:	00 00 00 
  100b1f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b26:	00 00 00 
  100b29:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b30:	00 00 00 
  100b33:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b3a:	00 00 00 
  100b3d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b44:	00 00 00 
  100b47:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b4e:	00 00 00 
  100b51:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b58:	00 00 00 
  100b5b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b62:	00 00 00 
  100b65:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b6c:	00 00 00 
  100b6f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b76:	00 00 00 
  100b79:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b80:	00 00 00 
  100b83:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b8a:	00 00 00 
  100b8d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b94:	00 00 00 
  100b97:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100b9e:	00 00 00 
  100ba1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ba8:	00 00 00 
  100bab:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bb2:	00 00 00 
  100bb5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bbc:	00 00 00 
  100bbf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bc6:	00 00 00 
  100bc9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bd0:	00 00 00 
  100bd3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bda:	00 00 00 
  100bdd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100be4:	00 00 00 
  100be7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bee:	00 00 00 
  100bf1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100bf8:	00 00 00 
  100bfb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c02:	00 00 00 
  100c05:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c0c:	00 00 00 
  100c0f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c16:	00 00 00 
  100c19:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c20:	00 00 00 
  100c23:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c2a:	00 00 00 
  100c2d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c34:	00 00 00 
  100c37:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c3e:	00 00 00 
  100c41:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c48:	00 00 00 
  100c4b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c52:	00 00 00 
  100c55:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c5c:	00 00 00 
  100c5f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c66:	00 00 00 
  100c69:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c70:	00 00 00 
  100c73:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c7a:	00 00 00 
  100c7d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c84:	00 00 00 
  100c87:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c8e:	00 00 00 
  100c91:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100c98:	00 00 00 
  100c9b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ca2:	00 00 00 
  100ca5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cac:	00 00 00 
  100caf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cb6:	00 00 00 
  100cb9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cc0:	00 00 00 
  100cc3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cca:	00 00 00 
  100ccd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cd4:	00 00 00 
  100cd7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cde:	00 00 00 
  100ce1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ce8:	00 00 00 
  100ceb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cf2:	00 00 00 
  100cf5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100cfc:	00 00 00 
  100cff:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d06:	00 00 00 
  100d09:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d10:	00 00 00 
  100d13:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d1a:	00 00 00 
  100d1d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d24:	00 00 00 
  100d27:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d2e:	00 00 00 
  100d31:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d38:	00 00 00 
  100d3b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d42:	00 00 00 
  100d45:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d4c:	00 00 00 
  100d4f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d56:	00 00 00 
  100d59:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d60:	00 00 00 
  100d63:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d6a:	00 00 00 
  100d6d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d74:	00 00 00 
  100d77:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d7e:	00 00 00 
  100d81:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d88:	00 00 00 
  100d8b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d92:	00 00 00 
  100d95:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100d9c:	00 00 00 
  100d9f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100da6:	00 00 00 
  100da9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100db0:	00 00 00 
  100db3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100dba:	00 00 00 
  100dbd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100dc4:	00 00 00 
  100dc7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100dce:	00 00 00 
  100dd1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100dd8:	00 00 00 
  100ddb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100de2:	00 00 00 
  100de5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100dec:	00 00 00 
  100def:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100df6:	00 00 00 
  100df9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e00:	00 00 00 
  100e03:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e0a:	00 00 00 
  100e0d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e14:	00 00 00 
  100e17:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e1e:	00 00 00 
  100e21:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e28:	00 00 00 
  100e2b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e32:	00 00 00 
  100e35:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e3c:	00 00 00 
  100e3f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e46:	00 00 00 
  100e49:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e50:	00 00 00 
  100e53:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e5a:	00 00 00 
  100e5d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e64:	00 00 00 
  100e67:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e6e:	00 00 00 
  100e71:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e78:	00 00 00 
  100e7b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e82:	00 00 00 
  100e85:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e8c:	00 00 00 
  100e8f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100e96:	00 00 00 
  100e99:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ea0:	00 00 00 
  100ea3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100eaa:	00 00 00 
  100ead:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100eb4:	00 00 00 
  100eb7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ebe:	00 00 00 
  100ec1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ec8:	00 00 00 
  100ecb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ed2:	00 00 00 
  100ed5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100edc:	00 00 00 
  100edf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ee6:	00 00 00 
  100ee9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ef0:	00 00 00 
  100ef3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100efa:	00 00 00 
  100efd:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f04:	00 00 00 
  100f07:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f0e:	00 00 00 
  100f11:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f18:	00 00 00 
  100f1b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f22:	00 00 00 
  100f25:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f2c:	00 00 00 
  100f2f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f36:	00 00 00 
  100f39:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f40:	00 00 00 
  100f43:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f4a:	00 00 00 
  100f4d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f54:	00 00 00 
  100f57:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f5e:	00 00 00 
  100f61:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f68:	00 00 00 
  100f6b:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f72:	00 00 00 
  100f75:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f7c:	00 00 00 
  100f7f:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f86:	00 00 00 
  100f89:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f90:	00 00 00 
  100f93:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100f9a:	00 00 00 
  100f9d:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fa4:	00 00 00 
  100fa7:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fae:	00 00 00 
  100fb1:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fb8:	00 00 00 
  100fbb:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fc2:	00 00 00 
  100fc5:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fcc:	00 00 00 
  100fcf:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fd6:	00 00 00 
  100fd9:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fe0:	00 00 00 
  100fe3:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100fea:	00 00 00 
  100fed:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  100ff4:	00 00 00 
  100ff7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
  100ffe:	00 00 

0000000000101000 <gdt_64>:
	...
  101008:	ff                   	(bad)  
  101009:	ff 00                	incl   (%rax)
  10100b:	00 00                	add    %al,(%rax)
  10100d:	9a                   	(bad)  
  10100e:	af                   	scas   %es:(%rdi),%eax
  10100f:	00 ff                	add    %bh,%bh
  101011:	ff 00                	incl   (%rax)
  101013:	00 00                	add    %al,(%rax)
  101015:	92                   	xchg   %eax,%edx
  101016:	cf                   	iret   
	...

0000000000101018 <gdtdesc_64>:
  101018:	17                   	(bad)  
  101019:	00 00                	add    %al,(%rax)
  10101b:	10 10                	adc    %dl,(%rax)
	...

0000000000102000 <pml4phys>:
	...

0000000000103000 <pdpt1>:
	...

0000000000104000 <pdpt2>:
	...

0000000000105000 <pde1>:
	...

0000000000106000 <pde2>:
	...

0000000000107000 <multiboot_info>:
  107000:	00 00                	add    %al,(%rax)
	...

Disassembly of section .text:

0000008004200000 <_start+0x8003fffff4>:
  8004200000:	02 b0 ad 1b 00 00    	add    0x1bad(%rax),%dh
  8004200006:	00 00                	add    %al,(%rax)
  8004200008:	fe 4f 52             	decb   0x52(%rdi)
  800420000b:	e4                   	.byte 0xe4

000000800420000c <entry>:
entry:

/* .globl _back_from_head64 */
/* _back_from_head64: */

    movabs   $gdtdesc_64,%rax
  800420000c:	48 b8 38 b0 21 04 80 	movabs $0x800421b038,%rax
  8004200013:	00 00 00 
    lgdt     (%rax)
  8004200016:	0f 01 10             	lgdt   (%rax)
    movw    $DATA_SEL,%ax
  8004200019:	66 b8 10 00          	mov    $0x10,%ax
    movw    %ax,%ds
  800420001d:	8e d8                	mov    %eax,%ds
    movw    %ax,%ss
  800420001f:	8e d0                	mov    %eax,%ss
    movw    %ax,%fs
  8004200021:	8e e0                	mov    %eax,%fs
    movw    %ax,%gs
  8004200023:	8e e8                	mov    %eax,%gs
    movw    %ax,%es
  8004200025:	8e c0                	mov    %eax,%es
    pushq   $CODE_SEL
  8004200027:	6a 08                	pushq  $0x8
    movabs  $relocated,%rax
  8004200029:	48 b8 36 00 20 04 80 	movabs $0x8004200036,%rax
  8004200030:	00 00 00 
    pushq   %rax
  8004200033:	50                   	push   %rax
    lretq
  8004200034:	48 cb                	lretq  

0000008004200036 <relocated>:
relocated:

	# Clear the frame pointer register (RBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movq	$0x0,%rbp			# nuke frame pointer
  8004200036:	48 c7 c5 00 00 00 00 	mov    $0x0,%rbp

	# Set the stack pointer
	movabs	$(bootstacktop),%rax
  800420003d:	48 b8 00 b0 21 04 80 	movabs $0x800421b000,%rax
  8004200044:	00 00 00 
	movq  %rax,%rsp
  8004200047:	48 89 c4             	mov    %rax,%rsp

	# now to C code
    movabs $i386_init, %rax
  800420004a:	48 b8 dd 00 20 04 80 	movabs $0x80042000dd,%rax
  8004200051:	00 00 00 
	call *%rax
  8004200054:	ff d0                	callq  *%rax

0000008004200056 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  8004200056:	eb fe                	jmp    8004200056 <spin>

0000008004200058 <test_backtrace>:


// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
  8004200058:	55                   	push   %rbp
  8004200059:	48 89 e5             	mov    %rsp,%rbp
  800420005c:	48 83 ec 10          	sub    $0x10,%rsp
  8004200060:	89 7d fc             	mov    %edi,-0x4(%rbp)
	cprintf("entering test_backtrace %d\n", x);
  8004200063:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200066:	89 c6                	mov    %eax,%esi
  8004200068:	48 bf 60 92 20 04 80 	movabs $0x8004209260,%rdi
  800420006f:	00 00 00 
  8004200072:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200077:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  800420007e:	00 00 00 
  8004200081:	ff d2                	callq  *%rdx
	if (x > 0)
  8004200083:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004200087:	7e 16                	jle    800420009f <test_backtrace+0x47>
		test_backtrace(x-1);
  8004200089:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420008c:	83 e8 01             	sub    $0x1,%eax
  800420008f:	89 c7                	mov    %eax,%edi
  8004200091:	48 b8 58 00 20 04 80 	movabs $0x8004200058,%rax
  8004200098:	00 00 00 
  800420009b:	ff d0                	callq  *%rax
  800420009d:	eb 1b                	jmp    80042000ba <test_backtrace+0x62>
	else
		mon_backtrace(0, 0, 0);
  800420009f:	ba 00 00 00 00       	mov    $0x0,%edx
  80042000a4:	be 00 00 00 00       	mov    $0x0,%esi
  80042000a9:	bf 00 00 00 00       	mov    $0x0,%edi
  80042000ae:	48 b8 eb 10 20 04 80 	movabs $0x80042010eb,%rax
  80042000b5:	00 00 00 
  80042000b8:	ff d0                	callq  *%rax
	cprintf("leaving test_backtrace %d\n", x);
  80042000ba:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042000bd:	89 c6                	mov    %eax,%esi
  80042000bf:	48 bf 7c 92 20 04 80 	movabs $0x800420927c,%rdi
  80042000c6:	00 00 00 
  80042000c9:	b8 00 00 00 00       	mov    $0x0,%eax
  80042000ce:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  80042000d5:	00 00 00 
  80042000d8:	ff d2                	callq  *%rdx
}
  80042000da:	90                   	nop
  80042000db:	c9                   	leaveq 
  80042000dc:	c3                   	retq   

00000080042000dd <i386_init>:

void
i386_init(void)
{
  80042000dd:	55                   	push   %rbp
  80042000de:	48 89 e5             	mov    %rsp,%rbp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
  80042000e1:	48 ba 40 cd 21 04 80 	movabs $0x800421cd40,%rdx
  80042000e8:	00 00 00 
  80042000eb:	48 b8 a0 b6 21 04 80 	movabs $0x800421b6a0,%rax
  80042000f2:	00 00 00 
  80042000f5:	48 29 c2             	sub    %rax,%rdx
  80042000f8:	48 89 d0             	mov    %rdx,%rax
  80042000fb:	48 89 c2             	mov    %rax,%rdx
  80042000fe:	be 00 00 00 00       	mov    $0x0,%esi
  8004200103:	48 bf a0 b6 21 04 80 	movabs $0x800421b6a0,%rdi
  800420010a:	00 00 00 
  800420010d:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  8004200114:	00 00 00 
  8004200117:	ff d0                	callq  *%rax

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  8004200119:	48 b8 10 0e 20 04 80 	movabs $0x8004200e10,%rax
  8004200120:	00 00 00 
  8004200123:	ff d0                	callq  *%rax

	cprintf("6828 decimal is %o octal!\n", 6828);
  8004200125:	be ac 1a 00 00       	mov    $0x1aac,%esi
  800420012a:	48 bf 97 92 20 04 80 	movabs $0x8004209297,%rdi
  8004200131:	00 00 00 
  8004200134:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200139:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004200140:	00 00 00 
  8004200143:	ff d2                	callq  *%rdx

	extern char end[];
	end_debug = read_section_headers((0x10000+KERNBASE), (uintptr_t)end);
  8004200145:	48 b8 40 cd 21 04 80 	movabs $0x800421cd40,%rax
  800420014c:	00 00 00 
  800420014f:	48 89 c6             	mov    %rax,%rsi
  8004200152:	48 bf 00 00 01 04 80 	movabs $0x8004010000,%rdi
  8004200159:	00 00 00 
  800420015c:	48 b8 65 88 20 04 80 	movabs $0x8004208865,%rax
  8004200163:	00 00 00 
  8004200166:	ff d0                	callq  *%rax
  8004200168:	48 89 c2             	mov    %rax,%rdx
  800420016b:	48 b8 48 bd 21 04 80 	movabs $0x800421bd48,%rax
  8004200172:	00 00 00 
  8004200175:	48 89 10             	mov    %rdx,(%rax)




	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
  8004200178:	bf 05 00 00 00       	mov    $0x5,%edi
  800420017d:	48 b8 58 00 20 04 80 	movabs $0x8004200058,%rax
  8004200184:	00 00 00 
  8004200187:	ff d0                	callq  *%rax

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
  8004200189:	bf 00 00 00 00       	mov    $0x0,%edi
  800420018e:	48 b8 14 13 20 04 80 	movabs $0x8004201314,%rax
  8004200195:	00 00 00 
  8004200198:	ff d0                	callq  *%rax
  800420019a:	eb ed                	jmp    8004200189 <i386_init+0xac>

000000800420019c <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
  800420019c:	55                   	push   %rbp
  800420019d:	48 89 e5             	mov    %rsp,%rbp
  80042001a0:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  80042001a7:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  80042001ae:	89 b5 24 ff ff ff    	mov    %esi,-0xdc(%rbp)
  80042001b4:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  80042001bb:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80042001c2:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80042001c9:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80042001d0:	84 c0                	test   %al,%al
  80042001d2:	74 20                	je     80042001f4 <_panic+0x58>
  80042001d4:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  80042001d8:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  80042001dc:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80042001e0:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  80042001e4:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  80042001e8:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  80042001ec:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80042001f0:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
	va_list ap;

	if (panicstr)
  80042001f4:	48 b8 50 bd 21 04 80 	movabs $0x800421bd50,%rax
  80042001fb:	00 00 00 
  80042001fe:	48 8b 00             	mov    (%rax),%rax
  8004200201:	48 85 c0             	test   %rax,%rax
  8004200204:	0f 85 ab 00 00 00    	jne    80042002b5 <_panic+0x119>
		goto dead;
	panicstr = fmt;
  800420020a:	48 b8 50 bd 21 04 80 	movabs $0x800421bd50,%rax
  8004200211:	00 00 00 
  8004200214:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  800420021b:	48 89 10             	mov    %rdx,(%rax)

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
  800420021e:	fa                   	cli    
  800420021f:	fc                   	cld    

	va_start(ap, fmt);
  8004200220:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8004200227:	00 00 00 
  800420022a:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8004200231:	00 00 00 
  8004200234:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004200238:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  800420023f:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8004200246:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
	cprintf("kernel panic at %s:%d: ", file, line);
  800420024d:	8b 95 24 ff ff ff    	mov    -0xdc(%rbp),%edx
  8004200253:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  800420025a:	48 89 c6             	mov    %rax,%rsi
  800420025d:	48 bf b2 92 20 04 80 	movabs $0x80042092b2,%rdi
  8004200264:	00 00 00 
  8004200267:	b8 00 00 00 00       	mov    $0x0,%eax
  800420026c:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  8004200273:	00 00 00 
  8004200276:	ff d1                	callq  *%rcx
	vcprintf(fmt, ap);
  8004200278:	48 8d 95 38 ff ff ff 	lea    -0xc8(%rbp),%rdx
  800420027f:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
  8004200286:	48 89 d6             	mov    %rdx,%rsi
  8004200289:	48 89 c7             	mov    %rax,%rdi
  800420028c:	48 b8 ca 13 20 04 80 	movabs $0x80042013ca,%rax
  8004200293:	00 00 00 
  8004200296:	ff d0                	callq  *%rax
	cprintf("\n");
  8004200298:	48 bf ca 92 20 04 80 	movabs $0x80042092ca,%rdi
  800420029f:	00 00 00 
  80042002a2:	b8 00 00 00 00       	mov    $0x0,%eax
  80042002a7:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  80042002ae:	00 00 00 
  80042002b1:	ff d2                	callq  *%rdx
  80042002b3:	eb 01                	jmp    80042002b6 <_panic+0x11a>
		goto dead;
  80042002b5:	90                   	nop
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
  80042002b6:	bf 00 00 00 00       	mov    $0x0,%edi
  80042002bb:	48 b8 14 13 20 04 80 	movabs $0x8004201314,%rax
  80042002c2:	00 00 00 
  80042002c5:	ff d0                	callq  *%rax
  80042002c7:	eb ed                	jmp    80042002b6 <_panic+0x11a>

00000080042002c9 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
  80042002c9:	55                   	push   %rbp
  80042002ca:	48 89 e5             	mov    %rsp,%rbp
  80042002cd:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  80042002d4:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  80042002db:	89 b5 24 ff ff ff    	mov    %esi,-0xdc(%rbp)
  80042002e1:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  80042002e8:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80042002ef:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80042002f6:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80042002fd:	84 c0                	test   %al,%al
  80042002ff:	74 20                	je     8004200321 <_warn+0x58>
  8004200301:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8004200305:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8004200309:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800420030d:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004200311:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8004200315:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8004200319:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800420031d:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
	va_list ap;

	va_start(ap, fmt);
  8004200321:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8004200328:	00 00 00 
  800420032b:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8004200332:	00 00 00 
  8004200335:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004200339:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  8004200340:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8004200347:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
	cprintf("kernel warning at %s:%d: ", file, line);
  800420034e:	8b 95 24 ff ff ff    	mov    -0xdc(%rbp),%edx
  8004200354:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  800420035b:	48 89 c6             	mov    %rax,%rsi
  800420035e:	48 bf cc 92 20 04 80 	movabs $0x80042092cc,%rdi
  8004200365:	00 00 00 
  8004200368:	b8 00 00 00 00       	mov    $0x0,%eax
  800420036d:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  8004200374:	00 00 00 
  8004200377:	ff d1                	callq  *%rcx
	vcprintf(fmt, ap);
  8004200379:	48 8d 95 38 ff ff ff 	lea    -0xc8(%rbp),%rdx
  8004200380:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
  8004200387:	48 89 d6             	mov    %rdx,%rsi
  800420038a:	48 89 c7             	mov    %rax,%rdi
  800420038d:	48 b8 ca 13 20 04 80 	movabs $0x80042013ca,%rax
  8004200394:	00 00 00 
  8004200397:	ff d0                	callq  *%rax
	cprintf("\n");
  8004200399:	48 bf ca 92 20 04 80 	movabs $0x80042092ca,%rdi
  80042003a0:	00 00 00 
  80042003a3:	b8 00 00 00 00       	mov    $0x0,%eax
  80042003a8:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  80042003af:	00 00 00 
  80042003b2:	ff d2                	callq  *%rdx
	va_end(ap);
}
  80042003b4:	90                   	nop
  80042003b5:	c9                   	leaveq 
  80042003b6:	c3                   	retq   

00000080042003b7 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  80042003b7:	55                   	push   %rbp
  80042003b8:	48 89 e5             	mov    %rsp,%rbp
  80042003bb:	48 83 ec 20          	sub    $0x20,%rsp
  80042003bf:	c7 45 e4 84 00 00 00 	movl   $0x84,-0x1c(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042003c6:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042003c9:	89 c2                	mov    %eax,%edx
  80042003cb:	ec                   	in     (%dx),%al
  80042003cc:	88 45 e3             	mov    %al,-0x1d(%rbp)
  80042003cf:	c7 45 ec 84 00 00 00 	movl   $0x84,-0x14(%rbp)
  80042003d6:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80042003d9:	89 c2                	mov    %eax,%edx
  80042003db:	ec                   	in     (%dx),%al
  80042003dc:	88 45 eb             	mov    %al,-0x15(%rbp)
  80042003df:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%rbp)
  80042003e6:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042003e9:	89 c2                	mov    %eax,%edx
  80042003eb:	ec                   	in     (%dx),%al
  80042003ec:	88 45 f3             	mov    %al,-0xd(%rbp)
  80042003ef:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%rbp)
  80042003f6:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042003f9:	89 c2                	mov    %eax,%edx
  80042003fb:	ec                   	in     (%dx),%al
  80042003fc:	88 45 fb             	mov    %al,-0x5(%rbp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  80042003ff:	90                   	nop
  8004200400:	c9                   	leaveq 
  8004200401:	c3                   	retq   

0000008004200402 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
  8004200402:	55                   	push   %rbp
  8004200403:	48 89 e5             	mov    %rsp,%rbp
  8004200406:	48 83 ec 10          	sub    $0x10,%rsp
  800420040a:	c7 45 fc fd 03 00 00 	movl   $0x3fd,-0x4(%rbp)
  8004200411:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200414:	89 c2                	mov    %eax,%edx
  8004200416:	ec                   	in     (%dx),%al
  8004200417:	88 45 fb             	mov    %al,-0x5(%rbp)
	return data;
  800420041a:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  800420041e:	0f b6 c0             	movzbl %al,%eax
  8004200421:	83 e0 01             	and    $0x1,%eax
  8004200424:	85 c0                	test   %eax,%eax
  8004200426:	75 07                	jne    800420042f <serial_proc_data+0x2d>
		return -1;
  8004200428:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420042d:	eb 17                	jmp    8004200446 <serial_proc_data+0x44>
  800420042f:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200436:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004200439:	89 c2                	mov    %eax,%edx
  800420043b:	ec                   	in     (%dx),%al
  800420043c:	88 45 f3             	mov    %al,-0xd(%rbp)
	return data;
  800420043f:	0f b6 45 f3          	movzbl -0xd(%rbp),%eax
	return inb(COM1+COM_RX);
  8004200443:	0f b6 c0             	movzbl %al,%eax
}
  8004200446:	c9                   	leaveq 
  8004200447:	c3                   	retq   

0000008004200448 <serial_intr>:

void
serial_intr(void)
{
  8004200448:	55                   	push   %rbp
  8004200449:	48 89 e5             	mov    %rsp,%rbp
	if (serial_exists)
  800420044c:	48 b8 a0 b6 21 04 80 	movabs $0x800421b6a0,%rax
  8004200453:	00 00 00 
  8004200456:	0f b6 00             	movzbl (%rax),%eax
  8004200459:	84 c0                	test   %al,%al
  800420045b:	74 16                	je     8004200473 <serial_intr+0x2b>
		cons_intr(serial_proc_data);
  800420045d:	48 bf 02 04 20 04 80 	movabs $0x8004200402,%rdi
  8004200464:	00 00 00 
  8004200467:	48 b8 91 0c 20 04 80 	movabs $0x8004200c91,%rax
  800420046e:	00 00 00 
  8004200471:	ff d0                	callq  *%rax
}
  8004200473:	90                   	nop
  8004200474:	5d                   	pop    %rbp
  8004200475:	c3                   	retq   

0000008004200476 <serial_putc>:

static void
serial_putc(int c)
{
  8004200476:	55                   	push   %rbp
  8004200477:	48 89 e5             	mov    %rsp,%rbp
  800420047a:	48 83 ec 28          	sub    $0x28,%rsp
  800420047e:	89 7d dc             	mov    %edi,-0x24(%rbp)
	int i;

	for (i = 0;
  8004200481:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004200488:	eb 10                	jmp    800420049a <serial_putc+0x24>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  800420048a:	48 b8 b7 03 20 04 80 	movabs $0x80042003b7,%rax
  8004200491:	00 00 00 
  8004200494:	ff d0                	callq  *%rax
	     i++)
  8004200496:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  800420049a:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042004a1:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80042004a4:	89 c2                	mov    %eax,%edx
  80042004a6:	ec                   	in     (%dx),%al
  80042004a7:	88 45 f7             	mov    %al,-0x9(%rbp)
	return data;
  80042004aa:	0f b6 45 f7          	movzbl -0x9(%rbp),%eax
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  80042004ae:	0f b6 c0             	movzbl %al,%eax
  80042004b1:	83 e0 20             	and    $0x20,%eax
	for (i = 0;
  80042004b4:	85 c0                	test   %eax,%eax
  80042004b6:	75 09                	jne    80042004c1 <serial_putc+0x4b>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  80042004b8:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%rbp)
  80042004bf:	7e c9                	jle    800420048a <serial_putc+0x14>

	outb(COM1 + COM_TX, c);
  80042004c1:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042004c4:	0f b6 c0             	movzbl %al,%eax
  80042004c7:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%rbp)
  80042004ce:	88 45 ef             	mov    %al,-0x11(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  80042004d1:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  80042004d5:	8b 55 f0             	mov    -0x10(%rbp),%edx
  80042004d8:	ee                   	out    %al,(%dx)
}
  80042004d9:	90                   	nop
  80042004da:	c9                   	leaveq 
  80042004db:	c3                   	retq   

00000080042004dc <serial_init>:

static void
serial_init(void)
{
  80042004dc:	55                   	push   %rbp
  80042004dd:	48 89 e5             	mov    %rsp,%rbp
  80042004e0:	48 83 ec 50          	sub    $0x50,%rsp
  80042004e4:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%rbp)
  80042004eb:	c6 45 b3 00          	movb   $0x0,-0x4d(%rbp)
  80042004ef:	0f b6 45 b3          	movzbl -0x4d(%rbp),%eax
  80042004f3:	8b 55 b4             	mov    -0x4c(%rbp),%edx
  80042004f6:	ee                   	out    %al,(%dx)
  80042004f7:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%rbp)
  80042004fe:	c6 45 bb 80          	movb   $0x80,-0x45(%rbp)
  8004200502:	0f b6 45 bb          	movzbl -0x45(%rbp),%eax
  8004200506:	8b 55 bc             	mov    -0x44(%rbp),%edx
  8004200509:	ee                   	out    %al,(%dx)
  800420050a:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%rbp)
  8004200511:	c6 45 c3 0c          	movb   $0xc,-0x3d(%rbp)
  8004200515:	0f b6 45 c3          	movzbl -0x3d(%rbp),%eax
  8004200519:	8b 55 c4             	mov    -0x3c(%rbp),%edx
  800420051c:	ee                   	out    %al,(%dx)
  800420051d:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%rbp)
  8004200524:	c6 45 cb 00          	movb   $0x0,-0x35(%rbp)
  8004200528:	0f b6 45 cb          	movzbl -0x35(%rbp),%eax
  800420052c:	8b 55 cc             	mov    -0x34(%rbp),%edx
  800420052f:	ee                   	out    %al,(%dx)
  8004200530:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%rbp)
  8004200537:	c6 45 d3 03          	movb   $0x3,-0x2d(%rbp)
  800420053b:	0f b6 45 d3          	movzbl -0x2d(%rbp),%eax
  800420053f:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004200542:	ee                   	out    %al,(%dx)
  8004200543:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%rbp)
  800420054a:	c6 45 db 00          	movb   $0x0,-0x25(%rbp)
  800420054e:	0f b6 45 db          	movzbl -0x25(%rbp),%eax
  8004200552:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004200555:	ee                   	out    %al,(%dx)
  8004200556:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%rbp)
  800420055d:	c6 45 e3 01          	movb   $0x1,-0x1d(%rbp)
  8004200561:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
  8004200565:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200568:	ee                   	out    %al,(%dx)
  8004200569:	c7 45 ec fd 03 00 00 	movl   $0x3fd,-0x14(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200570:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004200573:	89 c2                	mov    %eax,%edx
  8004200575:	ec                   	in     (%dx),%al
  8004200576:	88 45 eb             	mov    %al,-0x15(%rbp)
	return data;
  8004200579:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  800420057d:	3c ff                	cmp    $0xff,%al
  800420057f:	0f 95 c2             	setne  %dl
  8004200582:	48 b8 a0 b6 21 04 80 	movabs $0x800421b6a0,%rax
  8004200589:	00 00 00 
  800420058c:	88 10                	mov    %dl,(%rax)
  800420058e:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,-0xc(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200595:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004200598:	89 c2                	mov    %eax,%edx
  800420059a:	ec                   	in     (%dx),%al
  800420059b:	88 45 f3             	mov    %al,-0xd(%rbp)
  800420059e:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%rbp)
  80042005a5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042005a8:	89 c2                	mov    %eax,%edx
  80042005aa:	ec                   	in     (%dx),%al
  80042005ab:	88 45 fb             	mov    %al,-0x5(%rbp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
  80042005ae:	90                   	nop
  80042005af:	c9                   	leaveq 
  80042005b0:	c3                   	retq   

00000080042005b1 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
  80042005b1:	55                   	push   %rbp
  80042005b2:	48 89 e5             	mov    %rsp,%rbp
  80042005b5:	48 83 ec 38          	sub    $0x38,%rsp
  80042005b9:	89 7d cc             	mov    %edi,-0x34(%rbp)
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
  80042005bc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80042005c3:	eb 10                	jmp    80042005d5 <lpt_putc+0x24>
		delay();
  80042005c5:	48 b8 b7 03 20 04 80 	movabs $0x80042003b7,%rax
  80042005cc:	00 00 00 
  80042005cf:	ff d0                	callq  *%rax
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
  80042005d1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80042005d5:	c7 45 f8 79 03 00 00 	movl   $0x379,-0x8(%rbp)
  80042005dc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80042005df:	89 c2                	mov    %eax,%edx
  80042005e1:	ec                   	in     (%dx),%al
  80042005e2:	88 45 f7             	mov    %al,-0x9(%rbp)
	return data;
  80042005e5:	0f b6 45 f7          	movzbl -0x9(%rbp),%eax
  80042005e9:	84 c0                	test   %al,%al
  80042005eb:	78 09                	js     80042005f6 <lpt_putc+0x45>
  80042005ed:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%rbp)
  80042005f4:	7e cf                	jle    80042005c5 <lpt_putc+0x14>
	outb(0x378+0, c);
  80042005f6:	8b 45 cc             	mov    -0x34(%rbp),%eax
  80042005f9:	0f b6 c0             	movzbl %al,%eax
  80042005fc:	c7 45 e0 78 03 00 00 	movl   $0x378,-0x20(%rbp)
  8004200603:	88 45 df             	mov    %al,-0x21(%rbp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004200606:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  800420060a:	8b 55 e0             	mov    -0x20(%rbp),%edx
  800420060d:	ee                   	out    %al,(%dx)
  800420060e:	c7 45 e8 7a 03 00 00 	movl   $0x37a,-0x18(%rbp)
  8004200615:	c6 45 e7 0d          	movb   $0xd,-0x19(%rbp)
  8004200619:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  800420061d:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8004200620:	ee                   	out    %al,(%dx)
  8004200621:	c7 45 f0 7a 03 00 00 	movl   $0x37a,-0x10(%rbp)
  8004200628:	c6 45 ef 08          	movb   $0x8,-0x11(%rbp)
  800420062c:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  8004200630:	8b 55 f0             	mov    -0x10(%rbp),%edx
  8004200633:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
  8004200634:	90                   	nop
  8004200635:	c9                   	leaveq 
  8004200636:	c3                   	retq   

0000008004200637 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
  8004200637:	55                   	push   %rbp
  8004200638:	48 89 e5             	mov    %rsp,%rbp
  800420063b:	48 83 ec 30          	sub    $0x30,%rsp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
  800420063f:	48 b8 00 80 0b 04 80 	movabs $0x80040b8000,%rax
  8004200646:	00 00 00 
  8004200649:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	was = *cp;
  800420064d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004200651:	0f b7 00             	movzwl (%rax),%eax
  8004200654:	66 89 45 f6          	mov    %ax,-0xa(%rbp)
	*cp = (uint16_t) 0xA55A;
  8004200658:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420065c:	66 c7 00 5a a5       	movw   $0xa55a,(%rax)
	if (*cp != 0xA55A) {
  8004200661:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004200665:	0f b7 00             	movzwl (%rax),%eax
  8004200668:	66 3d 5a a5          	cmp    $0xa55a,%ax
  800420066c:	74 20                	je     800420068e <cga_init+0x57>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
  800420066e:	48 b8 00 00 0b 04 80 	movabs $0x80040b0000,%rax
  8004200675:	00 00 00 
  8004200678:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		addr_6845 = MONO_BASE;
  800420067c:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  8004200683:	00 00 00 
  8004200686:	c7 00 b4 03 00 00    	movl   $0x3b4,(%rax)
  800420068c:	eb 1b                	jmp    80042006a9 <cga_init+0x72>
	} else {
		*cp = was;
  800420068e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004200692:	0f b7 55 f6          	movzwl -0xa(%rbp),%edx
  8004200696:	66 89 10             	mov    %dx,(%rax)
		addr_6845 = CGA_BASE;
  8004200699:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  80042006a0:	00 00 00 
  80042006a3:	c7 00 d4 03 00 00    	movl   $0x3d4,(%rax)
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
  80042006a9:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  80042006b0:	00 00 00 
  80042006b3:	8b 00                	mov    (%rax),%eax
  80042006b5:	89 45 d4             	mov    %eax,-0x2c(%rbp)
  80042006b8:	c6 45 d3 0e          	movb   $0xe,-0x2d(%rbp)
  80042006bc:	0f b6 45 d3          	movzbl -0x2d(%rbp),%eax
  80042006c0:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  80042006c3:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  80042006c4:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  80042006cb:	00 00 00 
  80042006ce:	8b 00                	mov    (%rax),%eax
  80042006d0:	83 c0 01             	add    $0x1,%eax
  80042006d3:	89 45 dc             	mov    %eax,-0x24(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042006d6:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042006d9:	89 c2                	mov    %eax,%edx
  80042006db:	ec                   	in     (%dx),%al
  80042006dc:	88 45 db             	mov    %al,-0x25(%rbp)
	return data;
  80042006df:	0f b6 45 db          	movzbl -0x25(%rbp),%eax
  80042006e3:	0f b6 c0             	movzbl %al,%eax
  80042006e6:	c1 e0 08             	shl    $0x8,%eax
  80042006e9:	89 45 f0             	mov    %eax,-0x10(%rbp)
	outb(addr_6845, 15);
  80042006ec:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  80042006f3:	00 00 00 
  80042006f6:	8b 00                	mov    (%rax),%eax
  80042006f8:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  80042006fb:	c6 45 e3 0f          	movb   $0xf,-0x1d(%rbp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  80042006ff:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
  8004200703:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200706:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  8004200707:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  800420070e:	00 00 00 
  8004200711:	8b 00                	mov    (%rax),%eax
  8004200713:	83 c0 01             	add    $0x1,%eax
  8004200716:	89 45 ec             	mov    %eax,-0x14(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200719:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800420071c:	89 c2                	mov    %eax,%edx
  800420071e:	ec                   	in     (%dx),%al
  800420071f:	88 45 eb             	mov    %al,-0x15(%rbp)
	return data;
  8004200722:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200726:	0f b6 c0             	movzbl %al,%eax
  8004200729:	09 45 f0             	or     %eax,-0x10(%rbp)

	crt_buf = (uint16_t*) cp;
  800420072c:	48 b8 a8 b6 21 04 80 	movabs $0x800421b6a8,%rax
  8004200733:	00 00 00 
  8004200736:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420073a:	48 89 10             	mov    %rdx,(%rax)
	crt_pos = pos;
  800420073d:	8b 45 f0             	mov    -0x10(%rbp),%eax
  8004200740:	89 c2                	mov    %eax,%edx
  8004200742:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  8004200749:	00 00 00 
  800420074c:	66 89 10             	mov    %dx,(%rax)
}
  800420074f:	90                   	nop
  8004200750:	c9                   	leaveq 
  8004200751:	c3                   	retq   

0000008004200752 <cga_putc>:



static void
cga_putc(int c)
{
  8004200752:	55                   	push   %rbp
  8004200753:	48 89 e5             	mov    %rsp,%rbp
  8004200756:	48 83 ec 40          	sub    $0x40,%rsp
  800420075a:	89 7d cc             	mov    %edi,-0x34(%rbp)
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  800420075d:	8b 45 cc             	mov    -0x34(%rbp),%eax
  8004200760:	b0 00                	mov    $0x0,%al
  8004200762:	85 c0                	test   %eax,%eax
  8004200764:	75 07                	jne    800420076d <cga_putc+0x1b>
		c |= 0x0700;
  8004200766:	81 4d cc 00 07 00 00 	orl    $0x700,-0x34(%rbp)

	switch (c & 0xff) {
  800420076d:	8b 45 cc             	mov    -0x34(%rbp),%eax
  8004200770:	0f b6 c0             	movzbl %al,%eax
  8004200773:	83 f8 09             	cmp    $0x9,%eax
  8004200776:	0f 84 f9 00 00 00    	je     8004200875 <cga_putc+0x123>
  800420077c:	83 f8 09             	cmp    $0x9,%eax
  800420077f:	7f 0a                	jg     800420078b <cga_putc+0x39>
  8004200781:	83 f8 08             	cmp    $0x8,%eax
  8004200784:	74 18                	je     800420079e <cga_putc+0x4c>
  8004200786:	e9 41 01 00 00       	jmpq   80042008cc <cga_putc+0x17a>
  800420078b:	83 f8 0a             	cmp    $0xa,%eax
  800420078e:	74 78                	je     8004200808 <cga_putc+0xb6>
  8004200790:	83 f8 0d             	cmp    $0xd,%eax
  8004200793:	0f 84 8c 00 00 00    	je     8004200825 <cga_putc+0xd3>
  8004200799:	e9 2e 01 00 00       	jmpq   80042008cc <cga_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
  800420079e:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042007a5:	00 00 00 
  80042007a8:	0f b7 00             	movzwl (%rax),%eax
  80042007ab:	66 85 c0             	test   %ax,%ax
  80042007ae:	0f 84 53 01 00 00    	je     8004200907 <cga_putc+0x1b5>
			crt_pos--;
  80042007b4:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042007bb:	00 00 00 
  80042007be:	0f b7 00             	movzwl (%rax),%eax
  80042007c1:	8d 50 ff             	lea    -0x1(%rax),%edx
  80042007c4:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042007cb:	00 00 00 
  80042007ce:	66 89 10             	mov    %dx,(%rax)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  80042007d1:	8b 45 cc             	mov    -0x34(%rbp),%eax
  80042007d4:	b0 00                	mov    $0x0,%al
  80042007d6:	83 c8 20             	or     $0x20,%eax
  80042007d9:	89 c1                	mov    %eax,%ecx
  80042007db:	48 b8 a8 b6 21 04 80 	movabs $0x800421b6a8,%rax
  80042007e2:	00 00 00 
  80042007e5:	48 8b 10             	mov    (%rax),%rdx
  80042007e8:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042007ef:	00 00 00 
  80042007f2:	0f b7 00             	movzwl (%rax),%eax
  80042007f5:	0f b7 c0             	movzwl %ax,%eax
  80042007f8:	48 01 c0             	add    %rax,%rax
  80042007fb:	48 01 d0             	add    %rdx,%rax
  80042007fe:	89 ca                	mov    %ecx,%edx
  8004200800:	66 89 10             	mov    %dx,(%rax)
		}
		break;
  8004200803:	e9 ff 00 00 00       	jmpq   8004200907 <cga_putc+0x1b5>
	case '\n':
		crt_pos += CRT_COLS;
  8004200808:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  800420080f:	00 00 00 
  8004200812:	0f b7 00             	movzwl (%rax),%eax
  8004200815:	8d 50 50             	lea    0x50(%rax),%edx
  8004200818:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  800420081f:	00 00 00 
  8004200822:	66 89 10             	mov    %dx,(%rax)
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  8004200825:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  800420082c:	00 00 00 
  800420082f:	0f b7 30             	movzwl (%rax),%esi
  8004200832:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  8004200839:	00 00 00 
  800420083c:	0f b7 08             	movzwl (%rax),%ecx
  800420083f:	0f b7 c1             	movzwl %cx,%eax
  8004200842:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  8004200848:	c1 e8 10             	shr    $0x10,%eax
  800420084b:	89 c2                	mov    %eax,%edx
  800420084d:	66 c1 ea 06          	shr    $0x6,%dx
  8004200851:	89 d0                	mov    %edx,%eax
  8004200853:	c1 e0 02             	shl    $0x2,%eax
  8004200856:	01 d0                	add    %edx,%eax
  8004200858:	c1 e0 04             	shl    $0x4,%eax
  800420085b:	29 c1                	sub    %eax,%ecx
  800420085d:	89 ca                	mov    %ecx,%edx
  800420085f:	29 d6                	sub    %edx,%esi
  8004200861:	89 f2                	mov    %esi,%edx
  8004200863:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  800420086a:	00 00 00 
  800420086d:	66 89 10             	mov    %dx,(%rax)
		break;
  8004200870:	e9 93 00 00 00       	jmpq   8004200908 <cga_putc+0x1b6>
	case '\t':
		cons_putc(' ');
  8004200875:	bf 20 00 00 00       	mov    $0x20,%edi
  800420087a:	48 b8 cf 0d 20 04 80 	movabs $0x8004200dcf,%rax
  8004200881:	00 00 00 
  8004200884:	ff d0                	callq  *%rax
		cons_putc(' ');
  8004200886:	bf 20 00 00 00       	mov    $0x20,%edi
  800420088b:	48 b8 cf 0d 20 04 80 	movabs $0x8004200dcf,%rax
  8004200892:	00 00 00 
  8004200895:	ff d0                	callq  *%rax
		cons_putc(' ');
  8004200897:	bf 20 00 00 00       	mov    $0x20,%edi
  800420089c:	48 b8 cf 0d 20 04 80 	movabs $0x8004200dcf,%rax
  80042008a3:	00 00 00 
  80042008a6:	ff d0                	callq  *%rax
		cons_putc(' ');
  80042008a8:	bf 20 00 00 00       	mov    $0x20,%edi
  80042008ad:	48 b8 cf 0d 20 04 80 	movabs $0x8004200dcf,%rax
  80042008b4:	00 00 00 
  80042008b7:	ff d0                	callq  *%rax
		cons_putc(' ');
  80042008b9:	bf 20 00 00 00       	mov    $0x20,%edi
  80042008be:	48 b8 cf 0d 20 04 80 	movabs $0x8004200dcf,%rax
  80042008c5:	00 00 00 
  80042008c8:	ff d0                	callq  *%rax
		break;
  80042008ca:	eb 3c                	jmp    8004200908 <cga_putc+0x1b6>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  80042008cc:	48 b8 a8 b6 21 04 80 	movabs $0x800421b6a8,%rax
  80042008d3:	00 00 00 
  80042008d6:	48 8b 30             	mov    (%rax),%rsi
  80042008d9:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042008e0:	00 00 00 
  80042008e3:	0f b7 00             	movzwl (%rax),%eax
  80042008e6:	8d 48 01             	lea    0x1(%rax),%ecx
  80042008e9:	48 ba b0 b6 21 04 80 	movabs $0x800421b6b0,%rdx
  80042008f0:	00 00 00 
  80042008f3:	66 89 0a             	mov    %cx,(%rdx)
  80042008f6:	0f b7 c0             	movzwl %ax,%eax
  80042008f9:	48 01 c0             	add    %rax,%rax
  80042008fc:	48 01 f0             	add    %rsi,%rax
  80042008ff:	8b 55 cc             	mov    -0x34(%rbp),%edx
  8004200902:	66 89 10             	mov    %dx,(%rax)
		break;
  8004200905:	eb 01                	jmp    8004200908 <cga_putc+0x1b6>
		break;
  8004200907:	90                   	nop
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  8004200908:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  800420090f:	00 00 00 
  8004200912:	0f b7 00             	movzwl (%rax),%eax
  8004200915:	66 3d cf 07          	cmp    $0x7cf,%ax
  8004200919:	0f 86 89 00 00 00    	jbe    80042009a8 <cga_putc+0x256>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
  800420091f:	48 b8 a8 b6 21 04 80 	movabs $0x800421b6a8,%rax
  8004200926:	00 00 00 
  8004200929:	48 8b 00             	mov    (%rax),%rax
  800420092c:	48 8d 88 a0 00 00 00 	lea    0xa0(%rax),%rcx
  8004200933:	48 b8 a8 b6 21 04 80 	movabs $0x800421b6a8,%rax
  800420093a:	00 00 00 
  800420093d:	48 8b 00             	mov    (%rax),%rax
  8004200940:	ba 00 0f 00 00       	mov    $0xf00,%edx
  8004200945:	48 89 ce             	mov    %rcx,%rsi
  8004200948:	48 89 c7             	mov    %rax,%rdi
  800420094b:	48 b8 8c 2f 20 04 80 	movabs $0x8004202f8c,%rax
  8004200952:	00 00 00 
  8004200955:	ff d0                	callq  *%rax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  8004200957:	c7 45 fc 80 07 00 00 	movl   $0x780,-0x4(%rbp)
  800420095e:	eb 22                	jmp    8004200982 <cga_putc+0x230>
			crt_buf[i] = 0x0700 | ' ';
  8004200960:	48 b8 a8 b6 21 04 80 	movabs $0x800421b6a8,%rax
  8004200967:	00 00 00 
  800420096a:	48 8b 00             	mov    (%rax),%rax
  800420096d:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004200970:	48 63 d2             	movslq %edx,%rdx
  8004200973:	48 01 d2             	add    %rdx,%rdx
  8004200976:	48 01 d0             	add    %rdx,%rax
  8004200979:	66 c7 00 20 07       	movw   $0x720,(%rax)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  800420097e:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004200982:	81 7d fc cf 07 00 00 	cmpl   $0x7cf,-0x4(%rbp)
  8004200989:	7e d5                	jle    8004200960 <cga_putc+0x20e>
		crt_pos -= CRT_COLS;
  800420098b:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  8004200992:	00 00 00 
  8004200995:	0f b7 00             	movzwl (%rax),%eax
  8004200998:	8d 50 b0             	lea    -0x50(%rax),%edx
  800420099b:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042009a2:	00 00 00 
  80042009a5:	66 89 10             	mov    %dx,(%rax)
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  80042009a8:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  80042009af:	00 00 00 
  80042009b2:	8b 00                	mov    (%rax),%eax
  80042009b4:	89 45 e0             	mov    %eax,-0x20(%rbp)
  80042009b7:	c6 45 df 0e          	movb   $0xe,-0x21(%rbp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  80042009bb:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  80042009bf:	8b 55 e0             	mov    -0x20(%rbp),%edx
  80042009c2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  80042009c3:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  80042009ca:	00 00 00 
  80042009cd:	0f b7 00             	movzwl (%rax),%eax
  80042009d0:	66 c1 e8 08          	shr    $0x8,%ax
  80042009d4:	0f b6 c0             	movzbl %al,%eax
  80042009d7:	48 ba a4 b6 21 04 80 	movabs $0x800421b6a4,%rdx
  80042009de:	00 00 00 
  80042009e1:	8b 12                	mov    (%rdx),%edx
  80042009e3:	83 c2 01             	add    $0x1,%edx
  80042009e6:	89 55 e8             	mov    %edx,-0x18(%rbp)
  80042009e9:	88 45 e7             	mov    %al,-0x19(%rbp)
  80042009ec:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  80042009f0:	8b 55 e8             	mov    -0x18(%rbp),%edx
  80042009f3:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  80042009f4:	48 b8 a4 b6 21 04 80 	movabs $0x800421b6a4,%rax
  80042009fb:	00 00 00 
  80042009fe:	8b 00                	mov    (%rax),%eax
  8004200a00:	89 45 f0             	mov    %eax,-0x10(%rbp)
  8004200a03:	c6 45 ef 0f          	movb   $0xf,-0x11(%rbp)
  8004200a07:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  8004200a0b:	8b 55 f0             	mov    -0x10(%rbp),%edx
  8004200a0e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  8004200a0f:	48 b8 b0 b6 21 04 80 	movabs $0x800421b6b0,%rax
  8004200a16:	00 00 00 
  8004200a19:	0f b7 00             	movzwl (%rax),%eax
  8004200a1c:	0f b6 c0             	movzbl %al,%eax
  8004200a1f:	48 ba a4 b6 21 04 80 	movabs $0x800421b6a4,%rdx
  8004200a26:	00 00 00 
  8004200a29:	8b 12                	mov    (%rdx),%edx
  8004200a2b:	83 c2 01             	add    $0x1,%edx
  8004200a2e:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8004200a31:	88 45 f7             	mov    %al,-0x9(%rbp)
  8004200a34:	0f b6 45 f7          	movzbl -0x9(%rbp),%eax
  8004200a38:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8004200a3b:	ee                   	out    %al,(%dx)
}
  8004200a3c:	90                   	nop
  8004200a3d:	c9                   	leaveq 
  8004200a3e:	c3                   	retq   

0000008004200a3f <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  8004200a3f:	55                   	push   %rbp
  8004200a40:	48 89 e5             	mov    %rsp,%rbp
  8004200a43:	48 83 ec 20          	sub    $0x20,%rsp
  8004200a47:	c7 45 f4 64 00 00 00 	movl   $0x64,-0xc(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200a4e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004200a51:	89 c2                	mov    %eax,%edx
  8004200a53:	ec                   	in     (%dx),%al
  8004200a54:	88 45 f3             	mov    %al,-0xd(%rbp)
	return data;
  8004200a57:	0f b6 45 f3          	movzbl -0xd(%rbp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;
	int r;
	if ((inb(KBSTATP) & KBS_DIB) == 0)
  8004200a5b:	0f b6 c0             	movzbl %al,%eax
  8004200a5e:	83 e0 01             	and    $0x1,%eax
  8004200a61:	85 c0                	test   %eax,%eax
  8004200a63:	75 0a                	jne    8004200a6f <kbd_proc_data+0x30>
		return -1;
  8004200a65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004200a6a:	e9 fc 01 00 00       	jmpq   8004200c6b <kbd_proc_data+0x22c>
  8004200a6f:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200a76:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004200a79:	89 c2                	mov    %eax,%edx
  8004200a7b:	ec                   	in     (%dx),%al
  8004200a7c:	88 45 eb             	mov    %al,-0x15(%rbp)
	return data;
  8004200a7f:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax

	data = inb(KBDATAP);
  8004200a83:	88 45 fb             	mov    %al,-0x5(%rbp)

	if (data == 0xE0) {
  8004200a86:	80 7d fb e0          	cmpb   $0xe0,-0x5(%rbp)
  8004200a8a:	75 27                	jne    8004200ab3 <kbd_proc_data+0x74>
		// E0 escape character
		shift |= E0ESC;
  8004200a8c:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200a93:	00 00 00 
  8004200a96:	8b 00                	mov    (%rax),%eax
  8004200a98:	83 c8 40             	or     $0x40,%eax
  8004200a9b:	89 c2                	mov    %eax,%edx
  8004200a9d:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200aa4:	00 00 00 
  8004200aa7:	89 10                	mov    %edx,(%rax)
		return 0;
  8004200aa9:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200aae:	e9 b8 01 00 00       	jmpq   8004200c6b <kbd_proc_data+0x22c>
	} else if (data & 0x80) {
  8004200ab3:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200ab7:	84 c0                	test   %al,%al
  8004200ab9:	79 65                	jns    8004200b20 <kbd_proc_data+0xe1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  8004200abb:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200ac2:	00 00 00 
  8004200ac5:	8b 00                	mov    (%rax),%eax
  8004200ac7:	83 e0 40             	and    $0x40,%eax
  8004200aca:	85 c0                	test   %eax,%eax
  8004200acc:	75 09                	jne    8004200ad7 <kbd_proc_data+0x98>
  8004200ace:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200ad2:	83 e0 7f             	and    $0x7f,%eax
  8004200ad5:	eb 04                	jmp    8004200adb <kbd_proc_data+0x9c>
  8004200ad7:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200adb:	88 45 fb             	mov    %al,-0x5(%rbp)
		shift &= ~(shiftcode[data] | E0ESC);
  8004200ade:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200ae2:	48 ba 60 b0 21 04 80 	movabs $0x800421b060,%rdx
  8004200ae9:	00 00 00 
  8004200aec:	48 98                	cltq   
  8004200aee:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200af2:	83 c8 40             	or     $0x40,%eax
  8004200af5:	0f b6 c0             	movzbl %al,%eax
  8004200af8:	f7 d0                	not    %eax
  8004200afa:	89 c2                	mov    %eax,%edx
  8004200afc:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b03:	00 00 00 
  8004200b06:	8b 00                	mov    (%rax),%eax
  8004200b08:	21 c2                	and    %eax,%edx
  8004200b0a:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b11:	00 00 00 
  8004200b14:	89 10                	mov    %edx,(%rax)
		return 0;
  8004200b16:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200b1b:	e9 4b 01 00 00       	jmpq   8004200c6b <kbd_proc_data+0x22c>
	} else if (shift & E0ESC) {
  8004200b20:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b27:	00 00 00 
  8004200b2a:	8b 00                	mov    (%rax),%eax
  8004200b2c:	83 e0 40             	and    $0x40,%eax
  8004200b2f:	85 c0                	test   %eax,%eax
  8004200b31:	74 21                	je     8004200b54 <kbd_proc_data+0x115>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  8004200b33:	80 4d fb 80          	orb    $0x80,-0x5(%rbp)
		shift &= ~E0ESC;
  8004200b37:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b3e:	00 00 00 
  8004200b41:	8b 00                	mov    (%rax),%eax
  8004200b43:	83 e0 bf             	and    $0xffffffbf,%eax
  8004200b46:	89 c2                	mov    %eax,%edx
  8004200b48:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b4f:	00 00 00 
  8004200b52:	89 10                	mov    %edx,(%rax)
	}

	shift |= shiftcode[data];
  8004200b54:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200b58:	48 ba 60 b0 21 04 80 	movabs $0x800421b060,%rdx
  8004200b5f:	00 00 00 
  8004200b62:	48 98                	cltq   
  8004200b64:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200b68:	0f b6 d0             	movzbl %al,%edx
  8004200b6b:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b72:	00 00 00 
  8004200b75:	8b 00                	mov    (%rax),%eax
  8004200b77:	09 c2                	or     %eax,%edx
  8004200b79:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200b80:	00 00 00 
  8004200b83:	89 10                	mov    %edx,(%rax)
	shift ^= togglecode[data];
  8004200b85:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200b89:	48 ba 60 b1 21 04 80 	movabs $0x800421b160,%rdx
  8004200b90:	00 00 00 
  8004200b93:	48 98                	cltq   
  8004200b95:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200b99:	0f b6 d0             	movzbl %al,%edx
  8004200b9c:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200ba3:	00 00 00 
  8004200ba6:	8b 00                	mov    (%rax),%eax
  8004200ba8:	31 c2                	xor    %eax,%edx
  8004200baa:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200bb1:	00 00 00 
  8004200bb4:	89 10                	mov    %edx,(%rax)

	c = charcode[shift & (CTL | SHIFT)][data];
  8004200bb6:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200bbd:	00 00 00 
  8004200bc0:	8b 00                	mov    (%rax),%eax
  8004200bc2:	83 e0 03             	and    $0x3,%eax
  8004200bc5:	89 c2                	mov    %eax,%edx
  8004200bc7:	48 b8 60 b5 21 04 80 	movabs $0x800421b560,%rax
  8004200bce:	00 00 00 
  8004200bd1:	89 d2                	mov    %edx,%edx
  8004200bd3:	48 8b 14 d0          	mov    (%rax,%rdx,8),%rdx
  8004200bd7:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004200bdb:	48 01 d0             	add    %rdx,%rax
  8004200bde:	0f b6 00             	movzbl (%rax),%eax
  8004200be1:	0f b6 c0             	movzbl %al,%eax
  8004200be4:	89 45 fc             	mov    %eax,-0x4(%rbp)
	if (shift & CAPSLOCK) {
  8004200be7:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200bee:	00 00 00 
  8004200bf1:	8b 00                	mov    (%rax),%eax
  8004200bf3:	83 e0 08             	and    $0x8,%eax
  8004200bf6:	85 c0                	test   %eax,%eax
  8004200bf8:	74 22                	je     8004200c1c <kbd_proc_data+0x1dd>
		if ('a' <= c && c <= 'z')
  8004200bfa:	83 7d fc 60          	cmpl   $0x60,-0x4(%rbp)
  8004200bfe:	7e 0c                	jle    8004200c0c <kbd_proc_data+0x1cd>
  8004200c00:	83 7d fc 7a          	cmpl   $0x7a,-0x4(%rbp)
  8004200c04:	7f 06                	jg     8004200c0c <kbd_proc_data+0x1cd>
			c += 'A' - 'a';
  8004200c06:	83 6d fc 20          	subl   $0x20,-0x4(%rbp)
  8004200c0a:	eb 10                	jmp    8004200c1c <kbd_proc_data+0x1dd>
		else if ('A' <= c && c <= 'Z')
  8004200c0c:	83 7d fc 40          	cmpl   $0x40,-0x4(%rbp)
  8004200c10:	7e 0a                	jle    8004200c1c <kbd_proc_data+0x1dd>
  8004200c12:	83 7d fc 5a          	cmpl   $0x5a,-0x4(%rbp)
  8004200c16:	7f 04                	jg     8004200c1c <kbd_proc_data+0x1dd>
			c += 'a' - 'A';
  8004200c18:	83 45 fc 20          	addl   $0x20,-0x4(%rbp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  8004200c1c:	48 b8 c8 b8 21 04 80 	movabs $0x800421b8c8,%rax
  8004200c23:	00 00 00 
  8004200c26:	8b 00                	mov    (%rax),%eax
  8004200c28:	f7 d0                	not    %eax
  8004200c2a:	83 e0 06             	and    $0x6,%eax
  8004200c2d:	85 c0                	test   %eax,%eax
  8004200c2f:	75 37                	jne    8004200c68 <kbd_proc_data+0x229>
  8004200c31:	81 7d fc e9 00 00 00 	cmpl   $0xe9,-0x4(%rbp)
  8004200c38:	75 2e                	jne    8004200c68 <kbd_proc_data+0x229>
		cprintf("Rebooting!\n");
  8004200c3a:	48 bf e6 92 20 04 80 	movabs $0x80042092e6,%rdi
  8004200c41:	00 00 00 
  8004200c44:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200c49:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004200c50:	00 00 00 
  8004200c53:	ff d2                	callq  *%rdx
  8004200c55:	c7 45 e4 92 00 00 00 	movl   $0x92,-0x1c(%rbp)
  8004200c5c:	c6 45 e3 03          	movb   $0x3,-0x1d(%rbp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004200c60:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
  8004200c64:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200c67:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}
	return c;
  8004200c68:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004200c6b:	c9                   	leaveq 
  8004200c6c:	c3                   	retq   

0000008004200c6d <kbd_intr>:

void
kbd_intr(void)
{
  8004200c6d:	55                   	push   %rbp
  8004200c6e:	48 89 e5             	mov    %rsp,%rbp
	cons_intr(kbd_proc_data);
  8004200c71:	48 bf 3f 0a 20 04 80 	movabs $0x8004200a3f,%rdi
  8004200c78:	00 00 00 
  8004200c7b:	48 b8 91 0c 20 04 80 	movabs $0x8004200c91,%rax
  8004200c82:	00 00 00 
  8004200c85:	ff d0                	callq  *%rax
}
  8004200c87:	90                   	nop
  8004200c88:	5d                   	pop    %rbp
  8004200c89:	c3                   	retq   

0000008004200c8a <kbd_init>:

static void
kbd_init(void)
{
  8004200c8a:	55                   	push   %rbp
  8004200c8b:	48 89 e5             	mov    %rsp,%rbp
}
  8004200c8e:	90                   	nop
  8004200c8f:	5d                   	pop    %rbp
  8004200c90:	c3                   	retq   

0000008004200c91 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
  8004200c91:	55                   	push   %rbp
  8004200c92:	48 89 e5             	mov    %rsp,%rbp
  8004200c95:	48 83 ec 20          	sub    $0x20,%rsp
  8004200c99:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	int c;

	while ((c = (*proc)()) != -1) {
  8004200c9d:	eb 6a                	jmp    8004200d09 <cons_intr+0x78>
		if (c == 0)
  8004200c9f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004200ca3:	75 02                	jne    8004200ca7 <cons_intr+0x16>
			continue;
  8004200ca5:	eb 62                	jmp    8004200d09 <cons_intr+0x78>
		cons.buf[cons.wpos++] = c;
  8004200ca7:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200cae:	00 00 00 
  8004200cb1:	8b 80 04 02 00 00    	mov    0x204(%rax),%eax
  8004200cb7:	8d 48 01             	lea    0x1(%rax),%ecx
  8004200cba:	48 ba c0 b6 21 04 80 	movabs $0x800421b6c0,%rdx
  8004200cc1:	00 00 00 
  8004200cc4:	89 8a 04 02 00 00    	mov    %ecx,0x204(%rdx)
  8004200cca:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004200ccd:	89 d1                	mov    %edx,%ecx
  8004200ccf:	48 ba c0 b6 21 04 80 	movabs $0x800421b6c0,%rdx
  8004200cd6:	00 00 00 
  8004200cd9:	89 c0                	mov    %eax,%eax
  8004200cdb:	88 0c 02             	mov    %cl,(%rdx,%rax,1)
		if (cons.wpos == CONSBUFSIZE)
  8004200cde:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200ce5:	00 00 00 
  8004200ce8:	8b 80 04 02 00 00    	mov    0x204(%rax),%eax
  8004200cee:	3d 00 02 00 00       	cmp    $0x200,%eax
  8004200cf3:	75 14                	jne    8004200d09 <cons_intr+0x78>
			cons.wpos = 0;
  8004200cf5:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200cfc:	00 00 00 
  8004200cff:	c7 80 04 02 00 00 00 	movl   $0x0,0x204(%rax)
  8004200d06:	00 00 00 
	while ((c = (*proc)()) != -1) {
  8004200d09:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004200d0d:	ff d0                	callq  *%rax
  8004200d0f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004200d12:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%rbp)
  8004200d16:	75 87                	jne    8004200c9f <cons_intr+0xe>
	}
}
  8004200d18:	90                   	nop
  8004200d19:	c9                   	leaveq 
  8004200d1a:	c3                   	retq   

0000008004200d1b <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  8004200d1b:	55                   	push   %rbp
  8004200d1c:	48 89 e5             	mov    %rsp,%rbp
  8004200d1f:	48 83 ec 10          	sub    $0x10,%rsp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  8004200d23:	48 b8 48 04 20 04 80 	movabs $0x8004200448,%rax
  8004200d2a:	00 00 00 
  8004200d2d:	ff d0                	callq  *%rax
	kbd_intr();
  8004200d2f:	48 b8 6d 0c 20 04 80 	movabs $0x8004200c6d,%rax
  8004200d36:	00 00 00 
  8004200d39:	ff d0                	callq  *%rax

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  8004200d3b:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200d42:	00 00 00 
  8004200d45:	8b 90 00 02 00 00    	mov    0x200(%rax),%edx
  8004200d4b:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200d52:	00 00 00 
  8004200d55:	8b 80 04 02 00 00    	mov    0x204(%rax),%eax
  8004200d5b:	39 c2                	cmp    %eax,%edx
  8004200d5d:	74 69                	je     8004200dc8 <cons_getc+0xad>
		c = cons.buf[cons.rpos++];
  8004200d5f:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200d66:	00 00 00 
  8004200d69:	8b 80 00 02 00 00    	mov    0x200(%rax),%eax
  8004200d6f:	8d 48 01             	lea    0x1(%rax),%ecx
  8004200d72:	48 ba c0 b6 21 04 80 	movabs $0x800421b6c0,%rdx
  8004200d79:	00 00 00 
  8004200d7c:	89 8a 00 02 00 00    	mov    %ecx,0x200(%rdx)
  8004200d82:	48 ba c0 b6 21 04 80 	movabs $0x800421b6c0,%rdx
  8004200d89:	00 00 00 
  8004200d8c:	89 c0                	mov    %eax,%eax
  8004200d8e:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200d92:	0f b6 c0             	movzbl %al,%eax
  8004200d95:	89 45 fc             	mov    %eax,-0x4(%rbp)
		if (cons.rpos == CONSBUFSIZE)
  8004200d98:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200d9f:	00 00 00 
  8004200da2:	8b 80 00 02 00 00    	mov    0x200(%rax),%eax
  8004200da8:	3d 00 02 00 00       	cmp    $0x200,%eax
  8004200dad:	75 14                	jne    8004200dc3 <cons_getc+0xa8>
			cons.rpos = 0;
  8004200daf:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200db6:	00 00 00 
  8004200db9:	c7 80 00 02 00 00 00 	movl   $0x0,0x200(%rax)
  8004200dc0:	00 00 00 
		return c;
  8004200dc3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200dc6:	eb 05                	jmp    8004200dcd <cons_getc+0xb2>
	}
	return 0;
  8004200dc8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004200dcd:	c9                   	leaveq 
  8004200dce:	c3                   	retq   

0000008004200dcf <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  8004200dcf:	55                   	push   %rbp
  8004200dd0:	48 89 e5             	mov    %rsp,%rbp
  8004200dd3:	48 83 ec 10          	sub    $0x10,%rsp
  8004200dd7:	89 7d fc             	mov    %edi,-0x4(%rbp)
	serial_putc(c);
  8004200dda:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200ddd:	89 c7                	mov    %eax,%edi
  8004200ddf:	48 b8 76 04 20 04 80 	movabs $0x8004200476,%rax
  8004200de6:	00 00 00 
  8004200de9:	ff d0                	callq  *%rax
	lpt_putc(c);
  8004200deb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200dee:	89 c7                	mov    %eax,%edi
  8004200df0:	48 b8 b1 05 20 04 80 	movabs $0x80042005b1,%rax
  8004200df7:	00 00 00 
  8004200dfa:	ff d0                	callq  *%rax
	cga_putc(c);
  8004200dfc:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200dff:	89 c7                	mov    %eax,%edi
  8004200e01:	48 b8 52 07 20 04 80 	movabs $0x8004200752,%rax
  8004200e08:	00 00 00 
  8004200e0b:	ff d0                	callq  *%rax
}
  8004200e0d:	90                   	nop
  8004200e0e:	c9                   	leaveq 
  8004200e0f:	c3                   	retq   

0000008004200e10 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  8004200e10:	55                   	push   %rbp
  8004200e11:	48 89 e5             	mov    %rsp,%rbp
	cga_init();
  8004200e14:	48 b8 37 06 20 04 80 	movabs $0x8004200637,%rax
  8004200e1b:	00 00 00 
  8004200e1e:	ff d0                	callq  *%rax
	kbd_init();
  8004200e20:	48 b8 8a 0c 20 04 80 	movabs $0x8004200c8a,%rax
  8004200e27:	00 00 00 
  8004200e2a:	ff d0                	callq  *%rax
	serial_init();
  8004200e2c:	48 b8 dc 04 20 04 80 	movabs $0x80042004dc,%rax
  8004200e33:	00 00 00 
  8004200e36:	ff d0                	callq  *%rax

	if (!serial_exists)
  8004200e38:	48 b8 a0 b6 21 04 80 	movabs $0x800421b6a0,%rax
  8004200e3f:	00 00 00 
  8004200e42:	0f b6 00             	movzbl (%rax),%eax
  8004200e45:	83 f0 01             	xor    $0x1,%eax
  8004200e48:	84 c0                	test   %al,%al
  8004200e4a:	74 1b                	je     8004200e67 <cons_init+0x57>
		cprintf("Serial port does not exist!\n");
  8004200e4c:	48 bf f2 92 20 04 80 	movabs $0x80042092f2,%rdi
  8004200e53:	00 00 00 
  8004200e56:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200e5b:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004200e62:	00 00 00 
  8004200e65:	ff d2                	callq  *%rdx
}
  8004200e67:	90                   	nop
  8004200e68:	5d                   	pop    %rbp
  8004200e69:	c3                   	retq   

0000008004200e6a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
  8004200e6a:	55                   	push   %rbp
  8004200e6b:	48 89 e5             	mov    %rsp,%rbp
  8004200e6e:	48 83 ec 10          	sub    $0x10,%rsp
  8004200e72:	89 7d fc             	mov    %edi,-0x4(%rbp)
	cons_putc(c);
  8004200e75:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200e78:	89 c7                	mov    %eax,%edi
  8004200e7a:	48 b8 cf 0d 20 04 80 	movabs $0x8004200dcf,%rax
  8004200e81:	00 00 00 
  8004200e84:	ff d0                	callq  *%rax
}
  8004200e86:	90                   	nop
  8004200e87:	c9                   	leaveq 
  8004200e88:	c3                   	retq   

0000008004200e89 <getchar>:

int
getchar(void)
{
  8004200e89:	55                   	push   %rbp
  8004200e8a:	48 89 e5             	mov    %rsp,%rbp
  8004200e8d:	48 83 ec 10          	sub    $0x10,%rsp
	int c;

	while ((c = cons_getc()) == 0)
  8004200e91:	48 b8 1b 0d 20 04 80 	movabs $0x8004200d1b,%rax
  8004200e98:	00 00 00 
  8004200e9b:	ff d0                	callq  *%rax
  8004200e9d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004200ea0:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004200ea4:	74 eb                	je     8004200e91 <getchar+0x8>
		/* do nothing */;
	return c;
  8004200ea6:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004200ea9:	c9                   	leaveq 
  8004200eaa:	c3                   	retq   

0000008004200eab <iscons>:

int
iscons(int fdnum)
{
  8004200eab:	55                   	push   %rbp
  8004200eac:	48 89 e5             	mov    %rsp,%rbp
  8004200eaf:	48 83 ec 08          	sub    $0x8,%rsp
  8004200eb3:	89 7d fc             	mov    %edi,-0x4(%rbp)
	// used by readline
	return 1;
  8004200eb6:	b8 01 00 00 00       	mov    $0x1,%eax
}
  8004200ebb:	c9                   	leaveq 
  8004200ebc:	c3                   	retq   

0000008004200ebd <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
  8004200ebd:	55                   	push   %rbp
  8004200ebe:	48 89 e5             	mov    %rsp,%rbp
  8004200ec1:	48 83 ec 30          	sub    $0x30,%rsp
  8004200ec5:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8004200ec8:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004200ecc:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	int i;

	for (i = 0; i < NCOMMANDS; i++)
  8004200ed0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004200ed7:	eb 6f                	jmp    8004200f48 <mon_help+0x8b>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
  8004200ed9:	48 b9 80 b5 21 04 80 	movabs $0x800421b580,%rcx
  8004200ee0:	00 00 00 
  8004200ee3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200ee6:	48 63 d0             	movslq %eax,%rdx
  8004200ee9:	48 89 d0             	mov    %rdx,%rax
  8004200eec:	48 01 c0             	add    %rax,%rax
  8004200eef:	48 01 d0             	add    %rdx,%rax
  8004200ef2:	48 c1 e0 03          	shl    $0x3,%rax
  8004200ef6:	48 01 c8             	add    %rcx,%rax
  8004200ef9:	48 83 c0 08          	add    $0x8,%rax
  8004200efd:	48 8b 08             	mov    (%rax),%rcx
  8004200f00:	48 be 80 b5 21 04 80 	movabs $0x800421b580,%rsi
  8004200f07:	00 00 00 
  8004200f0a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200f0d:	48 63 d0             	movslq %eax,%rdx
  8004200f10:	48 89 d0             	mov    %rdx,%rax
  8004200f13:	48 01 c0             	add    %rax,%rax
  8004200f16:	48 01 d0             	add    %rdx,%rax
  8004200f19:	48 c1 e0 03          	shl    $0x3,%rax
  8004200f1d:	48 01 f0             	add    %rsi,%rax
  8004200f20:	48 8b 00             	mov    (%rax),%rax
  8004200f23:	48 89 ca             	mov    %rcx,%rdx
  8004200f26:	48 89 c6             	mov    %rax,%rsi
  8004200f29:	48 bf 65 93 20 04 80 	movabs $0x8004209365,%rdi
  8004200f30:	00 00 00 
  8004200f33:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200f38:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  8004200f3f:	00 00 00 
  8004200f42:	ff d1                	callq  *%rcx
	for (i = 0; i < NCOMMANDS; i++)
  8004200f44:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004200f48:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200f4b:	83 f8 01             	cmp    $0x1,%eax
  8004200f4e:	76 89                	jbe    8004200ed9 <mon_help+0x1c>
	return 0;
  8004200f50:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004200f55:	c9                   	leaveq 
  8004200f56:	c3                   	retq   

0000008004200f57 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
  8004200f57:	55                   	push   %rbp
  8004200f58:	48 89 e5             	mov    %rsp,%rbp
  8004200f5b:	48 83 ec 30          	sub    $0x30,%rsp
  8004200f5f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8004200f62:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004200f66:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
  8004200f6a:	48 bf 6e 93 20 04 80 	movabs $0x800420936e,%rdi
  8004200f71:	00 00 00 
  8004200f74:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200f79:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004200f80:	00 00 00 
  8004200f83:	ff d2                	callq  *%rdx
	cprintf("  _start                  %08x (phys)\n", _start);
  8004200f85:	48 be 0c 00 20 00 00 	movabs $0x20000c,%rsi
  8004200f8c:	00 00 00 
  8004200f8f:	48 bf 88 93 20 04 80 	movabs $0x8004209388,%rdi
  8004200f96:	00 00 00 
  8004200f99:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200f9e:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004200fa5:	00 00 00 
  8004200fa8:	ff d2                	callq  *%rdx
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
  8004200faa:	48 b8 0c 00 20 00 00 	movabs $0x20000c,%rax
  8004200fb1:	00 00 00 
  8004200fb4:	48 89 c2             	mov    %rax,%rdx
  8004200fb7:	48 be 0c 00 20 04 80 	movabs $0x800420000c,%rsi
  8004200fbe:	00 00 00 
  8004200fc1:	48 bf b0 93 20 04 80 	movabs $0x80042093b0,%rdi
  8004200fc8:	00 00 00 
  8004200fcb:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200fd0:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  8004200fd7:	00 00 00 
  8004200fda:	ff d1                	callq  *%rcx
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
  8004200fdc:	48 b8 4b 92 20 00 00 	movabs $0x20924b,%rax
  8004200fe3:	00 00 00 
  8004200fe6:	48 89 c2             	mov    %rax,%rdx
  8004200fe9:	48 be 4b 92 20 04 80 	movabs $0x800420924b,%rsi
  8004200ff0:	00 00 00 
  8004200ff3:	48 bf d8 93 20 04 80 	movabs $0x80042093d8,%rdi
  8004200ffa:	00 00 00 
  8004200ffd:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201002:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  8004201009:	00 00 00 
  800420100c:	ff d1                	callq  *%rcx
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
  800420100e:	48 b8 a0 b6 21 00 00 	movabs $0x21b6a0,%rax
  8004201015:	00 00 00 
  8004201018:	48 89 c2             	mov    %rax,%rdx
  800420101b:	48 be a0 b6 21 04 80 	movabs $0x800421b6a0,%rsi
  8004201022:	00 00 00 
  8004201025:	48 bf 00 94 20 04 80 	movabs $0x8004209400,%rdi
  800420102c:	00 00 00 
  800420102f:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201034:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  800420103b:	00 00 00 
  800420103e:	ff d1                	callq  *%rcx
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
  8004201040:	48 b8 40 cd 21 00 00 	movabs $0x21cd40,%rax
  8004201047:	00 00 00 
  800420104a:	48 89 c2             	mov    %rax,%rdx
  800420104d:	48 be 40 cd 21 04 80 	movabs $0x800421cd40,%rsi
  8004201054:	00 00 00 
  8004201057:	48 bf 28 94 20 04 80 	movabs $0x8004209428,%rdi
  800420105e:	00 00 00 
  8004201061:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201066:	48 b9 29 14 20 04 80 	movabs $0x8004201429,%rcx
  800420106d:	00 00 00 
  8004201070:	ff d1                	callq  *%rcx
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
  8004201072:	48 c7 45 f8 00 04 00 	movq   $0x400,-0x8(%rbp)
  8004201079:	00 
  800420107a:	48 b8 0c 00 20 04 80 	movabs $0x800420000c,%rax
  8004201081:	00 00 00 
  8004201084:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004201088:	48 29 c2             	sub    %rax,%rdx
  800420108b:	48 b8 40 cd 21 04 80 	movabs $0x800421cd40,%rax
  8004201092:	00 00 00 
  8004201095:	48 83 e8 01          	sub    $0x1,%rax
  8004201099:	48 01 d0             	add    %rdx,%rax
  800420109c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80042010a0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042010a4:	ba 00 00 00 00       	mov    $0x0,%edx
  80042010a9:	48 f7 75 f8          	divq   -0x8(%rbp)
  80042010ad:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042010b1:	48 29 d0             	sub    %rdx,%rax
	cprintf("Kernel executable memory footprint: %dKB\n",
  80042010b4:	48 8d 90 ff 03 00 00 	lea    0x3ff(%rax),%rdx
  80042010bb:	48 85 c0             	test   %rax,%rax
  80042010be:	48 0f 48 c2          	cmovs  %rdx,%rax
  80042010c2:	48 c1 f8 0a          	sar    $0xa,%rax
  80042010c6:	48 89 c6             	mov    %rax,%rsi
  80042010c9:	48 bf 50 94 20 04 80 	movabs $0x8004209450,%rdi
  80042010d0:	00 00 00 
  80042010d3:	b8 00 00 00 00       	mov    $0x0,%eax
  80042010d8:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  80042010df:	00 00 00 
  80042010e2:	ff d2                	callq  *%rdx
	return 0;
  80042010e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042010e9:	c9                   	leaveq 
  80042010ea:	c3                   	retq   

00000080042010eb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
  80042010eb:	55                   	push   %rbp
  80042010ec:	48 89 e5             	mov    %rsp,%rbp
  80042010ef:	48 83 ec 18          	sub    $0x18,%rsp
  80042010f3:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80042010f6:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80042010fa:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	// Your code here.
	return 0;
  80042010fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004201103:	c9                   	leaveq 
  8004201104:	c3                   	retq   

0000008004201105 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
  8004201105:	55                   	push   %rbp
  8004201106:	48 89 e5             	mov    %rsp,%rbp
  8004201109:	48 81 ec a0 00 00 00 	sub    $0xa0,%rsp
  8004201110:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  8004201117:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
  800420111e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	argv[argc] = 0;
  8004201125:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004201128:	48 98                	cltq   
  800420112a:	48 c7 84 c5 70 ff ff 	movq   $0x0,-0x90(%rbp,%rax,8)
  8004201131:	ff 00 00 00 00 
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
  8004201136:	eb 15                	jmp    800420114d <runcmd+0x48>
			*buf++ = 0;
  8004201138:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420113f:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004201143:	48 89 95 68 ff ff ff 	mov    %rdx,-0x98(%rbp)
  800420114a:	c6 00 00             	movb   $0x0,(%rax)
		while (*buf && strchr(WHITESPACE, *buf))
  800420114d:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201154:	0f b6 00             	movzbl (%rax),%eax
  8004201157:	84 c0                	test   %al,%al
  8004201159:	74 2a                	je     8004201185 <runcmd+0x80>
  800420115b:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201162:	0f b6 00             	movzbl (%rax),%eax
  8004201165:	0f be c0             	movsbl %al,%eax
  8004201168:	89 c6                	mov    %eax,%esi
  800420116a:	48 bf 7a 94 20 04 80 	movabs $0x800420947a,%rdi
  8004201171:	00 00 00 
  8004201174:	48 b8 8d 2e 20 04 80 	movabs $0x8004202e8d,%rax
  800420117b:	00 00 00 
  800420117e:	ff d0                	callq  *%rax
  8004201180:	48 85 c0             	test   %rax,%rax
  8004201183:	75 b3                	jne    8004201138 <runcmd+0x33>
		if (*buf == 0)
  8004201185:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420118c:	0f b6 00             	movzbl (%rax),%eax
  800420118f:	84 c0                	test   %al,%al
  8004201191:	0f 84 95 00 00 00    	je     800420122c <runcmd+0x127>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
  8004201197:	83 7d fc 0f          	cmpl   $0xf,-0x4(%rbp)
  800420119b:	75 2a                	jne    80042011c7 <runcmd+0xc2>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
  800420119d:	be 10 00 00 00       	mov    $0x10,%esi
  80042011a2:	48 bf 7f 94 20 04 80 	movabs $0x800420947f,%rdi
  80042011a9:	00 00 00 
  80042011ac:	b8 00 00 00 00       	mov    $0x0,%eax
  80042011b1:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  80042011b8:	00 00 00 
  80042011bb:	ff d2                	callq  *%rdx
			return 0;
  80042011bd:	b8 00 00 00 00       	mov    $0x0,%eax
  80042011c2:	e9 4b 01 00 00       	jmpq   8004201312 <runcmd+0x20d>
		}
		argv[argc++] = buf;
  80042011c7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042011ca:	8d 50 01             	lea    0x1(%rax),%edx
  80042011cd:	89 55 fc             	mov    %edx,-0x4(%rbp)
  80042011d0:	48 98                	cltq   
  80042011d2:	48 8b 95 68 ff ff ff 	mov    -0x98(%rbp),%rdx
  80042011d9:	48 89 94 c5 70 ff ff 	mov    %rdx,-0x90(%rbp,%rax,8)
  80042011e0:	ff 
		while (*buf && !strchr(WHITESPACE, *buf))
  80042011e1:	eb 08                	jmp    80042011eb <runcmd+0xe6>
			buf++;
  80042011e3:	48 83 85 68 ff ff ff 	addq   $0x1,-0x98(%rbp)
  80042011ea:	01 
		while (*buf && !strchr(WHITESPACE, *buf))
  80042011eb:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042011f2:	0f b6 00             	movzbl (%rax),%eax
  80042011f5:	84 c0                	test   %al,%al
  80042011f7:	0f 84 50 ff ff ff    	je     800420114d <runcmd+0x48>
  80042011fd:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201204:	0f b6 00             	movzbl (%rax),%eax
  8004201207:	0f be c0             	movsbl %al,%eax
  800420120a:	89 c6                	mov    %eax,%esi
  800420120c:	48 bf 7a 94 20 04 80 	movabs $0x800420947a,%rdi
  8004201213:	00 00 00 
  8004201216:	48 b8 8d 2e 20 04 80 	movabs $0x8004202e8d,%rax
  800420121d:	00 00 00 
  8004201220:	ff d0                	callq  *%rax
  8004201222:	48 85 c0             	test   %rax,%rax
  8004201225:	74 bc                	je     80042011e3 <runcmd+0xde>
		while (*buf && strchr(WHITESPACE, *buf))
  8004201227:	e9 21 ff ff ff       	jmpq   800420114d <runcmd+0x48>
			break;
  800420122c:	90                   	nop
	}
	argv[argc] = 0;
  800420122d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004201230:	48 98                	cltq   
  8004201232:	48 c7 84 c5 70 ff ff 	movq   $0x0,-0x90(%rbp,%rax,8)
  8004201239:	ff 00 00 00 00 

	// Lookup and invoke the command
	if (argc == 0)
  800420123e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004201242:	75 0a                	jne    800420124e <runcmd+0x149>
		return 0;
  8004201244:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201249:	e9 c4 00 00 00       	jmpq   8004201312 <runcmd+0x20d>
	for (i = 0; i < NCOMMANDS; i++) {
  800420124e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
  8004201255:	e9 82 00 00 00       	jmpq   80042012dc <runcmd+0x1d7>
		if (strcmp(argv[0], commands[i].name) == 0)
  800420125a:	48 b9 80 b5 21 04 80 	movabs $0x800421b580,%rcx
  8004201261:	00 00 00 
  8004201264:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004201267:	48 63 d0             	movslq %eax,%rdx
  800420126a:	48 89 d0             	mov    %rdx,%rax
  800420126d:	48 01 c0             	add    %rax,%rax
  8004201270:	48 01 d0             	add    %rdx,%rax
  8004201273:	48 c1 e0 03          	shl    $0x3,%rax
  8004201277:	48 01 c8             	add    %rcx,%rax
  800420127a:	48 8b 10             	mov    (%rax),%rdx
  800420127d:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  8004201284:	48 89 d6             	mov    %rdx,%rsi
  8004201287:	48 89 c7             	mov    %rax,%rdi
  800420128a:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004201291:	00 00 00 
  8004201294:	ff d0                	callq  *%rax
  8004201296:	85 c0                	test   %eax,%eax
  8004201298:	75 3e                	jne    80042012d8 <runcmd+0x1d3>
			return commands[i].func(argc, argv, tf);
  800420129a:	48 b9 80 b5 21 04 80 	movabs $0x800421b580,%rcx
  80042012a1:	00 00 00 
  80042012a4:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80042012a7:	48 63 d0             	movslq %eax,%rdx
  80042012aa:	48 89 d0             	mov    %rdx,%rax
  80042012ad:	48 01 c0             	add    %rax,%rax
  80042012b0:	48 01 d0             	add    %rdx,%rax
  80042012b3:	48 c1 e0 03          	shl    $0x3,%rax
  80042012b7:	48 01 c8             	add    %rcx,%rax
  80042012ba:	48 83 c0 10          	add    $0x10,%rax
  80042012be:	48 8b 00             	mov    (%rax),%rax
  80042012c1:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  80042012c8:	48 8d b5 70 ff ff ff 	lea    -0x90(%rbp),%rsi
  80042012cf:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  80042012d2:	89 cf                	mov    %ecx,%edi
  80042012d4:	ff d0                	callq  *%rax
  80042012d6:	eb 3a                	jmp    8004201312 <runcmd+0x20d>
	for (i = 0; i < NCOMMANDS; i++) {
  80042012d8:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
  80042012dc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80042012df:	83 f8 01             	cmp    $0x1,%eax
  80042012e2:	0f 86 72 ff ff ff    	jbe    800420125a <runcmd+0x155>
	}
	cprintf("Unknown command '%s'\n", argv[0]);
  80042012e8:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  80042012ef:	48 89 c6             	mov    %rax,%rsi
  80042012f2:	48 bf 9c 94 20 04 80 	movabs $0x800420949c,%rdi
  80042012f9:	00 00 00 
  80042012fc:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201301:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004201308:	00 00 00 
  800420130b:	ff d2                	callq  *%rdx
	return 0;
  800420130d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004201312:	c9                   	leaveq 
  8004201313:	c3                   	retq   

0000008004201314 <monitor>:

void
monitor(struct Trapframe *tf)
{
  8004201314:	55                   	push   %rbp
  8004201315:	48 89 e5             	mov    %rsp,%rbp
  8004201318:	48 83 ec 20          	sub    $0x20,%rsp
  800420131c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
  8004201320:	48 bf b8 94 20 04 80 	movabs $0x80042094b8,%rdi
  8004201327:	00 00 00 
  800420132a:	b8 00 00 00 00       	mov    $0x0,%eax
  800420132f:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004201336:	00 00 00 
  8004201339:	ff d2                	callq  *%rdx
	cprintf("Type 'help' for a list of commands.\n");
  800420133b:	48 bf e0 94 20 04 80 	movabs $0x80042094e0,%rdi
  8004201342:	00 00 00 
  8004201345:	b8 00 00 00 00       	mov    $0x0,%eax
  800420134a:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004201351:	00 00 00 
  8004201354:	ff d2                	callq  *%rdx


	while (1) {
		buf = readline("K> ");
  8004201356:	48 bf 05 95 20 04 80 	movabs $0x8004209505,%rdi
  800420135d:	00 00 00 
  8004201360:	48 b8 a8 2a 20 04 80 	movabs $0x8004202aa8,%rax
  8004201367:	00 00 00 
  800420136a:	ff d0                	callq  *%rax
  800420136c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		if (buf != NULL)
  8004201370:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004201375:	74 df                	je     8004201356 <monitor+0x42>
			if (runcmd(buf, tf) < 0)
  8004201377:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420137b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420137f:	48 89 d6             	mov    %rdx,%rsi
  8004201382:	48 89 c7             	mov    %rax,%rdi
  8004201385:	48 b8 05 11 20 04 80 	movabs $0x8004201105,%rax
  800420138c:	00 00 00 
  800420138f:	ff d0                	callq  *%rax
  8004201391:	85 c0                	test   %eax,%eax
  8004201393:	78 02                	js     8004201397 <monitor+0x83>
		buf = readline("K> ");
  8004201395:	eb bf                	jmp    8004201356 <monitor+0x42>
				break;
  8004201397:	90                   	nop
	}
}
  8004201398:	90                   	nop
  8004201399:	c9                   	leaveq 
  800420139a:	c3                   	retq   

000000800420139b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
  800420139b:	55                   	push   %rbp
  800420139c:	48 89 e5             	mov    %rsp,%rbp
  800420139f:	48 83 ec 10          	sub    $0x10,%rsp
  80042013a3:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80042013a6:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	cputchar(ch);
  80042013aa:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042013ad:	89 c7                	mov    %eax,%edi
  80042013af:	48 b8 6a 0e 20 04 80 	movabs $0x8004200e6a,%rax
  80042013b6:	00 00 00 
  80042013b9:	ff d0                	callq  *%rax
	*cnt++;
  80042013bb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042013bf:	48 83 c0 04          	add    $0x4,%rax
  80042013c3:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
}
  80042013c7:	90                   	nop
  80042013c8:	c9                   	leaveq 
  80042013c9:	c3                   	retq   

00000080042013ca <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80042013ca:	55                   	push   %rbp
  80042013cb:	48 89 e5             	mov    %rsp,%rbp
  80042013ce:	48 83 ec 30          	sub    $0x30,%rsp
  80042013d2:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80042013d6:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
	int cnt = 0;
  80042013da:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	va_list aq;
	va_copy(aq,ap);
  80042013e1:	48 8d 4d e0          	lea    -0x20(%rbp),%rcx
  80042013e5:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  80042013e9:	48 8b 06             	mov    (%rsi),%rax
  80042013ec:	48 8b 56 08          	mov    0x8(%rsi),%rdx
  80042013f0:	48 89 01             	mov    %rax,(%rcx)
  80042013f3:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  80042013f7:	48 8b 46 10          	mov    0x10(%rsi),%rax
  80042013fb:	48 89 41 10          	mov    %rax,0x10(%rcx)
	vprintfmt((void*)putch, &cnt, fmt, aq);
  80042013ff:	48 8d 4d e0          	lea    -0x20(%rbp),%rcx
  8004201403:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004201407:	48 8d 45 fc          	lea    -0x4(%rbp),%rax
  800420140b:	48 89 c6             	mov    %rax,%rsi
  800420140e:	48 bf 9b 13 20 04 80 	movabs $0x800420139b,%rdi
  8004201415:	00 00 00 
  8004201418:	48 b8 0f 23 20 04 80 	movabs $0x800420230f,%rax
  800420141f:	00 00 00 
  8004201422:	ff d0                	callq  *%rax
	va_end(aq);
	return cnt;
  8004201424:	8b 45 fc             	mov    -0x4(%rbp),%eax

}
  8004201427:	c9                   	leaveq 
  8004201428:	c3                   	retq   

0000008004201429 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8004201429:	55                   	push   %rbp
  800420142a:	48 89 e5             	mov    %rsp,%rbp
  800420142d:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  8004201434:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  800420143b:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
  8004201442:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
  8004201449:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8004201450:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8004201457:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  800420145e:	84 c0                	test   %al,%al
  8004201460:	74 20                	je     8004201482 <cprintf+0x59>
  8004201462:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8004201466:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  800420146a:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800420146e:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004201472:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8004201476:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  800420147a:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800420147e:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
	va_list ap;
	int cnt;
	va_start(ap, fmt);
  8004201482:	c7 85 30 ff ff ff 08 	movl   $0x8,-0xd0(%rbp)
  8004201489:	00 00 00 
  800420148c:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  8004201493:	00 00 00 
  8004201496:	48 8d 45 10          	lea    0x10(%rbp),%rax
  800420149a:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  80042014a1:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80042014a8:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
	va_list aq;
	va_copy(aq,ap);
  80042014af:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  80042014b6:	48 8d b5 30 ff ff ff 	lea    -0xd0(%rbp),%rsi
  80042014bd:	48 8b 06             	mov    (%rsi),%rax
  80042014c0:	48 8b 56 08          	mov    0x8(%rsi),%rdx
  80042014c4:	48 89 01             	mov    %rax,(%rcx)
  80042014c7:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  80042014cb:	48 8b 46 10          	mov    0x10(%rsi),%rax
  80042014cf:	48 89 41 10          	mov    %rax,0x10(%rcx)
	cnt = vcprintf(fmt, aq);
  80042014d3:	48 8d 95 18 ff ff ff 	lea    -0xe8(%rbp),%rdx
  80042014da:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  80042014e1:	48 89 d6             	mov    %rdx,%rsi
  80042014e4:	48 89 c7             	mov    %rax,%rdi
  80042014e7:	48 b8 ca 13 20 04 80 	movabs $0x80042013ca,%rax
  80042014ee:	00 00 00 
  80042014f1:	ff d0                	callq  *%rax
  80042014f3:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
	va_end(aq);

	return cnt;
  80042014f9:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
}
  80042014ff:	c9                   	leaveq 
  8004201500:	c3                   	retq   

0000008004201501 <syscall>:


// Dispatches to the correct kernel function, passing the arguments.
int64_t
syscall(uint64_t syscallno, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5)
{
  8004201501:	55                   	push   %rbp
  8004201502:	48 89 e5             	mov    %rsp,%rbp
  8004201505:	48 83 ec 30          	sub    $0x30,%rsp
  8004201509:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  800420150d:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8004201511:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8004201515:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  8004201519:	4c 89 45 d8          	mov    %r8,-0x28(%rbp)
  800420151d:	4c 89 4d d0          	mov    %r9,-0x30(%rbp)
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
  8004201521:	48 ba 09 95 20 04 80 	movabs $0x8004209509,%rdx
  8004201528:	00 00 00 
  800420152b:	be 0e 00 00 00       	mov    $0xe,%esi
  8004201530:	48 bf 21 95 20 04 80 	movabs $0x8004209521,%rdi
  8004201537:	00 00 00 
  800420153a:	b8 00 00 00 00       	mov    $0x0,%eax
  800420153f:	48 b9 9c 01 20 04 80 	movabs $0x800420019c,%rcx
  8004201546:	00 00 00 
  8004201549:	ff d1                	callq  *%rcx

000000800420154b <list_func_die>:

#endif


int list_func_die(struct Ripdebuginfo *info, Dwarf_Die *die, uint64_t addr)
{
  800420154b:	55                   	push   %rbp
  800420154c:	48 89 e5             	mov    %rsp,%rbp
  800420154f:	48 81 ec c0 61 00 00 	sub    $0x61c0,%rsp
  8004201556:	48 89 bd 58 9e ff ff 	mov    %rdi,-0x61a8(%rbp)
  800420155d:	48 89 b5 50 9e ff ff 	mov    %rsi,-0x61b0(%rbp)
  8004201564:	48 89 95 48 9e ff ff 	mov    %rdx,-0x61b8(%rbp)
	_Dwarf_Line ln;
	Dwarf_Attribute *low;
	Dwarf_Attribute *high;
	Dwarf_CU *cu = die->cu_header;
  800420156b:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  8004201572:	48 8b 80 60 03 00 00 	mov    0x360(%rax),%rax
  8004201579:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	Dwarf_Die *cudie = die->cu_die; 
  800420157d:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  8004201584:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  800420158b:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	Dwarf_Die ret, sib=*die; 
  800420158f:	48 8b 95 50 9e ff ff 	mov    -0x61b0(%rbp),%rdx
  8004201596:	48 8d 85 70 9e ff ff 	lea    -0x6190(%rbp),%rax
  800420159d:	48 89 d1             	mov    %rdx,%rcx
  80042015a0:	ba 70 30 00 00       	mov    $0x3070,%edx
  80042015a5:	48 89 ce             	mov    %rcx,%rsi
  80042015a8:	48 89 c7             	mov    %rax,%rdi
  80042015ab:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  80042015b2:	00 00 00 
  80042015b5:	ff d0                	callq  *%rax
	Dwarf_Attribute *attr;
	uint64_t offset;
	uint64_t ret_val=8;
  80042015b7:	48 c7 45 f8 08 00 00 	movq   $0x8,-0x8(%rbp)
  80042015be:	00 
	uint64_t ret_offset=0;
  80042015bf:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  80042015c6:	00 

	if(die->die_tag != DW_TAG_subprogram)
  80042015c7:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  80042015ce:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042015d2:	48 83 f8 2e          	cmp    $0x2e,%rax
  80042015d6:	74 0a                	je     80042015e2 <list_func_die+0x97>
		return 0;
  80042015d8:	b8 00 00 00 00       	mov    $0x0,%eax
  80042015dd:	e9 8e 06 00 00       	jmpq   8004201c70 <list_func_die+0x725>

	memset(&ln, 0, sizeof(_Dwarf_Line));
  80042015e2:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80042015e9:	ba 38 00 00 00       	mov    $0x38,%edx
  80042015ee:	be 00 00 00 00       	mov    $0x0,%esi
  80042015f3:	48 89 c7             	mov    %rax,%rdi
  80042015f6:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  80042015fd:	00 00 00 
  8004201600:	ff d0                	callq  *%rax

	low  = _dwarf_attr_find(die, DW_AT_low_pc);
  8004201602:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  8004201609:	be 11 00 00 00       	mov    $0x11,%esi
  800420160e:	48 89 c7             	mov    %rax,%rdi
  8004201611:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004201618:	00 00 00 
  800420161b:	ff d0                	callq  *%rax
  800420161d:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
	high = _dwarf_attr_find(die, DW_AT_high_pc);
  8004201621:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  8004201628:	be 12 00 00 00       	mov    $0x12,%esi
  800420162d:	48 89 c7             	mov    %rax,%rdi
  8004201630:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004201637:	00 00 00 
  800420163a:	ff d0                	callq  *%rax
  800420163c:	48 89 45 c8          	mov    %rax,-0x38(%rbp)

	if((low && (low->u[0].u64 < addr)) && (high && (high->u[0].u64 > addr)))
  8004201640:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  8004201645:	0f 84 20 06 00 00    	je     8004201c6b <list_func_die+0x720>
  800420164b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420164f:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201653:	48 39 85 48 9e ff ff 	cmp    %rax,-0x61b8(%rbp)
  800420165a:	0f 86 0b 06 00 00    	jbe    8004201c6b <list_func_die+0x720>
  8004201660:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004201665:	0f 84 00 06 00 00    	je     8004201c6b <list_func_die+0x720>
  800420166b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420166f:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201673:	48 39 85 48 9e ff ff 	cmp    %rax,-0x61b8(%rbp)
  800420167a:	0f 83 eb 05 00 00    	jae    8004201c6b <list_func_die+0x720>
	{
		info->rip_file = die->cu_die->die_name;
  8004201680:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  8004201687:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  800420168e:	48 8b 90 50 03 00 00 	mov    0x350(%rax),%rdx
  8004201695:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  800420169c:	48 89 10             	mov    %rdx,(%rax)

		info->rip_fn_name = die->die_name;
  800420169f:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  80042016a6:	48 8b 90 50 03 00 00 	mov    0x350(%rax),%rdx
  80042016ad:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042016b4:	48 89 50 10          	mov    %rdx,0x10(%rax)
		info->rip_fn_namelen = strlen(die->die_name);
  80042016b8:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  80042016bf:	48 8b 80 50 03 00 00 	mov    0x350(%rax),%rax
  80042016c6:	48 89 c7             	mov    %rax,%rdi
  80042016c9:	48 b8 fb 2b 20 04 80 	movabs $0x8004202bfb,%rax
  80042016d0:	00 00 00 
  80042016d3:	ff d0                	callq  *%rax
  80042016d5:	89 c2                	mov    %eax,%edx
  80042016d7:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042016de:	89 50 18             	mov    %edx,0x18(%rax)

		info->rip_fn_addr = (uintptr_t)low->u[0].u64;
  80042016e1:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042016e5:	48 8b 50 28          	mov    0x28(%rax),%rdx
  80042016e9:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042016f0:	48 89 50 20          	mov    %rdx,0x20(%rax)

		assert(die->cu_die);	
  80042016f4:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  80042016fb:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  8004201702:	48 85 c0             	test   %rax,%rax
  8004201705:	75 35                	jne    800420173c <list_func_die+0x1f1>
  8004201707:	48 b9 60 98 20 04 80 	movabs $0x8004209860,%rcx
  800420170e:	00 00 00 
  8004201711:	48 ba 6c 98 20 04 80 	movabs $0x800420986c,%rdx
  8004201718:	00 00 00 
  800420171b:	be 88 00 00 00       	mov    $0x88,%esi
  8004201720:	48 bf 81 98 20 04 80 	movabs $0x8004209881,%rdi
  8004201727:	00 00 00 
  800420172a:	b8 00 00 00 00       	mov    $0x0,%eax
  800420172f:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004201736:	00 00 00 
  8004201739:	41 ff d0             	callq  *%r8
		dwarf_srclines(die->cu_die, &ln, addr, NULL); 
  800420173c:	48 8b 85 50 9e ff ff 	mov    -0x61b0(%rbp),%rax
  8004201743:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  800420174a:	48 8b 95 48 9e ff ff 	mov    -0x61b8(%rbp),%rdx
  8004201751:	48 8d b5 50 ff ff ff 	lea    -0xb0(%rbp),%rsi
  8004201758:	b9 00 00 00 00       	mov    $0x0,%ecx
  800420175d:	48 89 c7             	mov    %rax,%rdi
  8004201760:	48 b8 a0 83 20 04 80 	movabs $0x80042083a0,%rax
  8004201767:	00 00 00 
  800420176a:	ff d0                	callq  *%rax

		info->rip_line = ln.ln_lineno;
  800420176c:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201773:	89 c2                	mov    %eax,%edx
  8004201775:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  800420177c:	89 50 08             	mov    %edx,0x8(%rax)
		info->rip_fn_narg = 0;
  800420177f:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201786:	c7 40 28 00 00 00 00 	movl   $0x0,0x28(%rax)

		Dwarf_Attribute* attr;

		if(dwarf_child(dbg, cu, &sib, &ret) != DW_DLE_NO_ENTRY)
  800420178d:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201794:	00 00 00 
  8004201797:	48 8b 00             	mov    (%rax),%rax
  800420179a:	48 8d 8d e0 ce ff ff 	lea    -0x3120(%rbp),%rcx
  80042017a1:	48 8d 95 70 9e ff ff 	lea    -0x6190(%rbp),%rdx
  80042017a8:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  80042017ac:	48 89 c7             	mov    %rax,%rdi
  80042017af:	48 b8 70 50 20 04 80 	movabs $0x8004205070,%rax
  80042017b6:	00 00 00 
  80042017b9:	ff d0                	callq  *%rax
  80042017bb:	83 f8 04             	cmp    $0x4,%eax
  80042017be:	0f 84 99 04 00 00    	je     8004201c5d <list_func_die+0x712>
		{
			if(ret.die_tag != DW_TAG_formal_parameter)
  80042017c4:	48 8b 85 f8 ce ff ff 	mov    -0x3108(%rbp),%rax
  80042017cb:	48 83 f8 05          	cmp    $0x5,%rax
  80042017cf:	0f 85 8b 04 00 00    	jne    8004201c60 <list_func_die+0x715>
				goto last;

			attr = _dwarf_attr_find(&ret, DW_AT_type);
  80042017d5:	48 8d 85 e0 ce ff ff 	lea    -0x3120(%rbp),%rax
  80042017dc:	be 49 00 00 00       	mov    $0x49,%esi
  80042017e1:	48 89 c7             	mov    %rax,%rdi
  80042017e4:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  80042017eb:	00 00 00 
  80042017ee:	ff d0                	callq  *%rax
  80042017f0:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	
		try_again:
			if(attr != NULL)
  80042017f4:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80042017f9:	0f 84 b6 00 00 00    	je     80042018b5 <list_func_die+0x36a>
			{
				offset = (uint64_t)cu->cu_offset + attr->u[0].u64;
  80042017ff:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004201803:	48 8b 50 30          	mov    0x30(%rax),%rdx
  8004201807:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420180b:	48 8b 40 28          	mov    0x28(%rax),%rax
  800420180f:	48 01 d0             	add    %rdx,%rax
  8004201812:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
				dwarf_offdie(dbg, offset, &sib, *cu);
  8004201816:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  800420181d:	00 00 00 
  8004201820:	48 8b 08             	mov    (%rax),%rcx
  8004201823:	48 8d 95 70 9e ff ff 	lea    -0x6190(%rbp),%rdx
  800420182a:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  800420182e:	48 83 ec 08          	sub    $0x8,%rsp
  8004201832:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004201836:	ff 70 30             	pushq  0x30(%rax)
  8004201839:	ff 70 28             	pushq  0x28(%rax)
  800420183c:	ff 70 20             	pushq  0x20(%rax)
  800420183f:	ff 70 18             	pushq  0x18(%rax)
  8004201842:	ff 70 10             	pushq  0x10(%rax)
  8004201845:	ff 70 08             	pushq  0x8(%rax)
  8004201848:	ff 30                	pushq  (%rax)
  800420184a:	48 89 cf             	mov    %rcx,%rdi
  800420184d:	48 b8 f9 4c 20 04 80 	movabs $0x8004204cf9,%rax
  8004201854:	00 00 00 
  8004201857:	ff d0                	callq  *%rax
  8004201859:	48 83 c4 40          	add    $0x40,%rsp
				attr = _dwarf_attr_find(&sib, DW_AT_byte_size);
  800420185d:	48 8d 85 70 9e ff ff 	lea    -0x6190(%rbp),%rax
  8004201864:	be 0b 00 00 00       	mov    $0xb,%esi
  8004201869:	48 89 c7             	mov    %rax,%rdi
  800420186c:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004201873:	00 00 00 
  8004201876:	ff d0                	callq  *%rax
  8004201878:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
		
				if(attr != NULL)
  800420187c:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004201881:	74 0e                	je     8004201891 <list_func_die+0x346>
				{
					ret_val = attr->u[0].u64;
  8004201883:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201887:	48 8b 40 28          	mov    0x28(%rax),%rax
  800420188b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800420188f:	eb 24                	jmp    80042018b5 <list_func_die+0x36a>
				}
				else
				{
					attr = _dwarf_attr_find(&sib, DW_AT_type);
  8004201891:	48 8d 85 70 9e ff ff 	lea    -0x6190(%rbp),%rax
  8004201898:	be 49 00 00 00       	mov    $0x49,%esi
  800420189d:	48 89 c7             	mov    %rax,%rdi
  80042018a0:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  80042018a7:	00 00 00 
  80042018aa:	ff d0                	callq  *%rax
  80042018ac:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
					goto try_again;
  80042018b0:	e9 3f ff ff ff       	jmpq   80042017f4 <list_func_die+0x2a9>
				}
			}

			ret_offset = 0;
  80042018b5:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  80042018bc:	00 
			attr = _dwarf_attr_find(&ret, DW_AT_location);
  80042018bd:	48 8d 85 e0 ce ff ff 	lea    -0x3120(%rbp),%rax
  80042018c4:	be 02 00 00 00       	mov    $0x2,%esi
  80042018c9:	48 89 c7             	mov    %rax,%rdi
  80042018cc:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  80042018d3:	00 00 00 
  80042018d6:	ff d0                	callq  *%rax
  80042018d8:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			if (attr != NULL)
  80042018dc:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80042018e1:	0f 84 a0 00 00 00    	je     8004201987 <list_func_die+0x43c>
			{
				Dwarf_Unsigned loc_len = attr->at_block.bl_len;
  80042018e7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042018eb:	48 8b 40 38          	mov    0x38(%rax),%rax
  80042018ef:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
				Dwarf_Small *loc_ptr = attr->at_block.bl_data;
  80042018f3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042018f7:	48 8b 40 40          	mov    0x40(%rax),%rax
  80042018fb:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
				Dwarf_Small atom;
				Dwarf_Unsigned op1, op2;

				switch(attr->at_form) {
  80042018ff:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201903:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004201907:	48 83 f8 03          	cmp    $0x3,%rax
  800420190b:	72 7a                	jb     8004201987 <list_func_die+0x43c>
  800420190d:	48 83 f8 04          	cmp    $0x4,%rax
  8004201911:	76 06                	jbe    8004201919 <list_func_die+0x3ce>
  8004201913:	48 83 f8 0a          	cmp    $0xa,%rax
  8004201917:	75 6e                	jne    8004201987 <list_func_die+0x43c>
					case DW_FORM_block1:
					case DW_FORM_block2:
					case DW_FORM_block4:
						offset = 0;
  8004201919:	48 c7 45 c0 00 00 00 	movq   $0x0,-0x40(%rbp)
  8004201920:	00 
						atom = *(loc_ptr++);
  8004201921:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004201925:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004201929:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  800420192d:	0f b6 00             	movzbl (%rax),%eax
  8004201930:	88 45 af             	mov    %al,-0x51(%rbp)
						offset++;
  8004201933:	48 83 45 c0 01       	addq   $0x1,-0x40(%rbp)
						if (atom == DW_OP_fbreg) {
  8004201938:	80 7d af 91          	cmpb   $0x91,-0x51(%rbp)
  800420193c:	75 48                	jne    8004201986 <list_func_die+0x43b>
							uint8_t *p = loc_ptr;
  800420193e:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004201942:	48 89 85 68 9e ff ff 	mov    %rax,-0x6198(%rbp)
							ret_offset = _dwarf_decode_sleb128(&p);
  8004201949:	48 8d 85 68 9e ff ff 	lea    -0x6198(%rbp),%rax
  8004201950:	48 89 c7             	mov    %rax,%rdi
  8004201953:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  800420195a:	00 00 00 
  800420195d:	ff d0                	callq  *%rax
  800420195f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
							offset += p - loc_ptr;
  8004201963:	48 8b 85 68 9e ff ff 	mov    -0x6198(%rbp),%rax
  800420196a:	48 89 c2             	mov    %rax,%rdx
  800420196d:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004201971:	48 29 c2             	sub    %rax,%rdx
  8004201974:	48 89 d0             	mov    %rdx,%rax
  8004201977:	48 01 45 c0          	add    %rax,-0x40(%rbp)
							loc_ptr = p;
  800420197b:	48 8b 85 68 9e ff ff 	mov    -0x6198(%rbp),%rax
  8004201982:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
						}
						break;
  8004201986:	90                   	nop
				}
			}

			info->size_fn_arg[info->rip_fn_narg] = ret_val;
  8004201987:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  800420198e:	8b 50 28             	mov    0x28(%rax),%edx
  8004201991:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004201995:	89 c1                	mov    %eax,%ecx
  8004201997:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  800420199e:	48 63 d2             	movslq %edx,%rdx
  80042019a1:	48 83 c2 08          	add    $0x8,%rdx
  80042019a5:	89 4c 90 0c          	mov    %ecx,0xc(%rax,%rdx,4)
			info->offset_fn_arg[info->rip_fn_narg] = ret_offset;
  80042019a9:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042019b0:	8b 50 28             	mov    0x28(%rax),%edx
  80042019b3:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042019ba:	48 63 d2             	movslq %edx,%rdx
  80042019bd:	48 8d 4a 0a          	lea    0xa(%rdx),%rcx
  80042019c1:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042019c5:	48 89 54 c8 08       	mov    %rdx,0x8(%rax,%rcx,8)
			info->rip_fn_narg++;
  80042019ca:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042019d1:	8b 40 28             	mov    0x28(%rax),%eax
  80042019d4:	8d 50 01             	lea    0x1(%rax),%edx
  80042019d7:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  80042019de:	89 50 28             	mov    %edx,0x28(%rax)
			sib = ret; 
  80042019e1:	48 8d 85 70 9e ff ff 	lea    -0x6190(%rbp),%rax
  80042019e8:	48 8d 8d e0 ce ff ff 	lea    -0x3120(%rbp),%rcx
  80042019ef:	ba 70 30 00 00       	mov    $0x3070,%edx
  80042019f4:	48 89 ce             	mov    %rcx,%rsi
  80042019f7:	48 89 c7             	mov    %rax,%rdi
  80042019fa:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  8004201a01:	00 00 00 
  8004201a04:	ff d0                	callq  *%rax

			while(dwarf_siblingof(dbg, &sib, &ret, cu) == DW_DLV_OK)	
  8004201a06:	e9 1c 02 00 00       	jmpq   8004201c27 <list_func_die+0x6dc>
			{
				if(ret.die_tag != DW_TAG_formal_parameter)
  8004201a0b:	48 8b 85 f8 ce ff ff 	mov    -0x3108(%rbp),%rax
  8004201a12:	48 83 f8 05          	cmp    $0x5,%rax
  8004201a16:	0f 85 47 02 00 00    	jne    8004201c63 <list_func_die+0x718>
					break;

				attr = _dwarf_attr_find(&ret, DW_AT_type);
  8004201a1c:	48 8d 85 e0 ce ff ff 	lea    -0x3120(%rbp),%rax
  8004201a23:	be 49 00 00 00       	mov    $0x49,%esi
  8004201a28:	48 89 c7             	mov    %rax,%rdi
  8004201a2b:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004201a32:	00 00 00 
  8004201a35:	ff d0                	callq  *%rax
  8004201a37:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    
				if(attr != NULL)
  8004201a3b:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004201a40:	0f 84 90 00 00 00    	je     8004201ad6 <list_func_die+0x58b>
				{	   
					offset = (uint64_t)cu->cu_offset + attr->u[0].u64;
  8004201a46:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004201a4a:	48 8b 50 30          	mov    0x30(%rax),%rdx
  8004201a4e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201a52:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201a56:	48 01 d0             	add    %rdx,%rax
  8004201a59:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
					dwarf_offdie(dbg, offset, &sib, *cu);
  8004201a5d:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201a64:	00 00 00 
  8004201a67:	48 8b 08             	mov    (%rax),%rcx
  8004201a6a:	48 8d 95 70 9e ff ff 	lea    -0x6190(%rbp),%rdx
  8004201a71:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  8004201a75:	48 83 ec 08          	sub    $0x8,%rsp
  8004201a79:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004201a7d:	ff 70 30             	pushq  0x30(%rax)
  8004201a80:	ff 70 28             	pushq  0x28(%rax)
  8004201a83:	ff 70 20             	pushq  0x20(%rax)
  8004201a86:	ff 70 18             	pushq  0x18(%rax)
  8004201a89:	ff 70 10             	pushq  0x10(%rax)
  8004201a8c:	ff 70 08             	pushq  0x8(%rax)
  8004201a8f:	ff 30                	pushq  (%rax)
  8004201a91:	48 89 cf             	mov    %rcx,%rdi
  8004201a94:	48 b8 f9 4c 20 04 80 	movabs $0x8004204cf9,%rax
  8004201a9b:	00 00 00 
  8004201a9e:	ff d0                	callq  *%rax
  8004201aa0:	48 83 c4 40          	add    $0x40,%rsp
					attr = _dwarf_attr_find(&sib, DW_AT_byte_size);
  8004201aa4:	48 8d 85 70 9e ff ff 	lea    -0x6190(%rbp),%rax
  8004201aab:	be 0b 00 00 00       	mov    $0xb,%esi
  8004201ab0:	48 89 c7             	mov    %rax,%rdi
  8004201ab3:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004201aba:	00 00 00 
  8004201abd:	ff d0                	callq  *%rax
  8004201abf:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
        
					if(attr != NULL)
  8004201ac3:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004201ac8:	74 0c                	je     8004201ad6 <list_func_die+0x58b>
					{
						ret_val = attr->u[0].u64;
  8004201aca:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201ace:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201ad2:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
					}
				}
	
				ret_offset = 0;
  8004201ad6:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  8004201add:	00 
				attr = _dwarf_attr_find(&ret, DW_AT_location);
  8004201ade:	48 8d 85 e0 ce ff ff 	lea    -0x3120(%rbp),%rax
  8004201ae5:	be 02 00 00 00       	mov    $0x2,%esi
  8004201aea:	48 89 c7             	mov    %rax,%rdi
  8004201aed:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004201af4:	00 00 00 
  8004201af7:	ff d0                	callq  *%rax
  8004201af9:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
				if (attr != NULL)
  8004201afd:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004201b02:	0f 84 a0 00 00 00    	je     8004201ba8 <list_func_die+0x65d>
				{
					Dwarf_Unsigned loc_len = attr->at_block.bl_len;
  8004201b08:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201b0c:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004201b10:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
					Dwarf_Small *loc_ptr = attr->at_block.bl_data;
  8004201b14:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201b18:	48 8b 40 40          	mov    0x40(%rax),%rax
  8004201b1c:	48 89 45 98          	mov    %rax,-0x68(%rbp)
					Dwarf_Small atom;
					Dwarf_Unsigned op1, op2;

					switch(attr->at_form) {
  8004201b20:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201b24:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004201b28:	48 83 f8 03          	cmp    $0x3,%rax
  8004201b2c:	72 7a                	jb     8004201ba8 <list_func_die+0x65d>
  8004201b2e:	48 83 f8 04          	cmp    $0x4,%rax
  8004201b32:	76 06                	jbe    8004201b3a <list_func_die+0x5ef>
  8004201b34:	48 83 f8 0a          	cmp    $0xa,%rax
  8004201b38:	75 6e                	jne    8004201ba8 <list_func_die+0x65d>
						case DW_FORM_block1:
						case DW_FORM_block2:
						case DW_FORM_block4:
							offset = 0;
  8004201b3a:	48 c7 45 c0 00 00 00 	movq   $0x0,-0x40(%rbp)
  8004201b41:	00 
							atom = *(loc_ptr++);
  8004201b42:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004201b46:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004201b4a:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  8004201b4e:	0f b6 00             	movzbl (%rax),%eax
  8004201b51:	88 45 97             	mov    %al,-0x69(%rbp)
							offset++;
  8004201b54:	48 83 45 c0 01       	addq   $0x1,-0x40(%rbp)
							if (atom == DW_OP_fbreg) {
  8004201b59:	80 7d 97 91          	cmpb   $0x91,-0x69(%rbp)
  8004201b5d:	75 48                	jne    8004201ba7 <list_func_die+0x65c>
								uint8_t *p = loc_ptr;
  8004201b5f:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004201b63:	48 89 85 60 9e ff ff 	mov    %rax,-0x61a0(%rbp)
								ret_offset = _dwarf_decode_sleb128(&p);
  8004201b6a:	48 8d 85 60 9e ff ff 	lea    -0x61a0(%rbp),%rax
  8004201b71:	48 89 c7             	mov    %rax,%rdi
  8004201b74:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  8004201b7b:	00 00 00 
  8004201b7e:	ff d0                	callq  *%rax
  8004201b80:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
								offset += p - loc_ptr;
  8004201b84:	48 8b 85 60 9e ff ff 	mov    -0x61a0(%rbp),%rax
  8004201b8b:	48 89 c2             	mov    %rax,%rdx
  8004201b8e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004201b92:	48 29 c2             	sub    %rax,%rdx
  8004201b95:	48 89 d0             	mov    %rdx,%rax
  8004201b98:	48 01 45 c0          	add    %rax,-0x40(%rbp)
								loc_ptr = p;
  8004201b9c:	48 8b 85 60 9e ff ff 	mov    -0x61a0(%rbp),%rax
  8004201ba3:	48 89 45 98          	mov    %rax,-0x68(%rbp)
							}
							break;
  8004201ba7:	90                   	nop
					}
				}

				info->size_fn_arg[info->rip_fn_narg]=ret_val;// _get_arg_size(ret);
  8004201ba8:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201baf:	8b 50 28             	mov    0x28(%rax),%edx
  8004201bb2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004201bb6:	89 c1                	mov    %eax,%ecx
  8004201bb8:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201bbf:	48 63 d2             	movslq %edx,%rdx
  8004201bc2:	48 83 c2 08          	add    $0x8,%rdx
  8004201bc6:	89 4c 90 0c          	mov    %ecx,0xc(%rax,%rdx,4)
				info->offset_fn_arg[info->rip_fn_narg]=ret_offset;
  8004201bca:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201bd1:	8b 50 28             	mov    0x28(%rax),%edx
  8004201bd4:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201bdb:	48 63 d2             	movslq %edx,%rdx
  8004201bde:	48 8d 4a 0a          	lea    0xa(%rdx),%rcx
  8004201be2:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004201be6:	48 89 54 c8 08       	mov    %rdx,0x8(%rax,%rcx,8)
				info->rip_fn_narg++;
  8004201beb:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201bf2:	8b 40 28             	mov    0x28(%rax),%eax
  8004201bf5:	8d 50 01             	lea    0x1(%rax),%edx
  8004201bf8:	48 8b 85 58 9e ff ff 	mov    -0x61a8(%rbp),%rax
  8004201bff:	89 50 28             	mov    %edx,0x28(%rax)
				sib = ret; 
  8004201c02:	48 8d 85 70 9e ff ff 	lea    -0x6190(%rbp),%rax
  8004201c09:	48 8d 8d e0 ce ff ff 	lea    -0x3120(%rbp),%rcx
  8004201c10:	ba 70 30 00 00       	mov    $0x3070,%edx
  8004201c15:	48 89 ce             	mov    %rcx,%rsi
  8004201c18:	48 89 c7             	mov    %rax,%rdi
  8004201c1b:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  8004201c22:	00 00 00 
  8004201c25:	ff d0                	callq  *%rax
			while(dwarf_siblingof(dbg, &sib, &ret, cu) == DW_DLV_OK)	
  8004201c27:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201c2e:	00 00 00 
  8004201c31:	48 8b 00             	mov    (%rax),%rax
  8004201c34:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8004201c38:	48 8d 95 e0 ce ff ff 	lea    -0x3120(%rbp),%rdx
  8004201c3f:	48 8d b5 70 9e ff ff 	lea    -0x6190(%rbp),%rsi
  8004201c46:	48 89 c7             	mov    %rax,%rdi
  8004201c49:	48 b8 6e 4e 20 04 80 	movabs $0x8004204e6e,%rax
  8004201c50:	00 00 00 
  8004201c53:	ff d0                	callq  *%rax
  8004201c55:	85 c0                	test   %eax,%eax
  8004201c57:	0f 84 ae fd ff ff    	je     8004201a0b <list_func_die+0x4c0>
			}
		}
	last:	
  8004201c5d:	90                   	nop
  8004201c5e:	eb 04                	jmp    8004201c64 <list_func_die+0x719>
				goto last;
  8004201c60:	90                   	nop
  8004201c61:	eb 01                	jmp    8004201c64 <list_func_die+0x719>
					break;
  8004201c63:	90                   	nop
		return 1;
  8004201c64:	b8 01 00 00 00       	mov    $0x1,%eax
  8004201c69:	eb 05                	jmp    8004201c70 <list_func_die+0x725>
	}

	return 0;
  8004201c6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004201c70:	c9                   	leaveq 
  8004201c71:	c3                   	retq   

0000008004201c72 <debuginfo_rip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_rip(uintptr_t addr, struct Ripdebuginfo *info)
{
  8004201c72:	55                   	push   %rbp
  8004201c73:	48 89 e5             	mov    %rsp,%rbp
  8004201c76:	48 81 ec c0 91 00 00 	sub    $0x91c0,%rsp
  8004201c7d:	48 89 bd 48 6e ff ff 	mov    %rdi,-0x91b8(%rbp)
  8004201c84:	48 89 b5 40 6e ff ff 	mov    %rsi,-0x91c0(%rbp)
	static struct Env* lastenv = NULL;
	void* elf;    
	Dwarf_Section *sect;
	Dwarf_CU cu;
	Dwarf_Die die, cudie, die2;
	Dwarf_Regtable *rt = NULL;
  8004201c8b:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004201c92:	00 
	//Set up initial pc
	uint64_t pc  = (uintptr_t)addr;
  8004201c93:	48 8b 85 48 6e ff ff 	mov    -0x91b8(%rbp),%rax
  8004201c9a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

    
	// Initialize *info
	info->rip_file = "<unknown>";
  8004201c9e:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201ca5:	48 bf 8f 98 20 04 80 	movabs $0x800420988f,%rdi
  8004201cac:	00 00 00 
  8004201caf:	48 89 38             	mov    %rdi,(%rax)
	info->rip_line = 0;
  8004201cb2:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cb9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%rax)
	info->rip_fn_name = "<unknown>";
  8004201cc0:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cc7:	48 89 78 10          	mov    %rdi,0x10(%rax)
	info->rip_fn_namelen = 9;
  8004201ccb:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cd2:	c7 40 18 09 00 00 00 	movl   $0x9,0x18(%rax)
	info->rip_fn_addr = addr;
  8004201cd9:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201ce0:	48 8b 95 48 6e ff ff 	mov    -0x91b8(%rbp),%rdx
  8004201ce7:	48 89 50 20          	mov    %rdx,0x20(%rax)
	info->rip_fn_narg = 0;
  8004201ceb:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cf2:	c7 40 28 00 00 00 00 	movl   $0x0,0x28(%rax)
    
	// Find the relevant set of stabs
	if (addr >= ULIM) {
  8004201cf9:	48 b8 ff ff bf 03 80 	movabs $0x8003bfffff,%rax
  8004201d00:	00 00 00 
  8004201d03:	48 39 85 48 6e ff ff 	cmp    %rax,-0x91b8(%rbp)
  8004201d0a:	0f 86 99 00 00 00    	jbe    8004201da9 <debuginfo_rip+0x137>
		elf = (void *)0x10000 + KERNBASE;
  8004201d10:	48 b8 00 00 01 04 80 	movabs $0x8004010000,%rax
  8004201d17:	00 00 00 
  8004201d1a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	} else {
		// Can't search for user-level addresses yet!
		panic("User address");
	}
	_dwarf_init(dbg, elf);
  8004201d1e:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201d25:	00 00 00 
  8004201d28:	48 8b 00             	mov    (%rax),%rax
  8004201d2b:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004201d2f:	48 89 d6             	mov    %rdx,%rsi
  8004201d32:	48 89 c7             	mov    %rax,%rdi
  8004201d35:	48 b8 41 3d 20 04 80 	movabs $0x8004203d41,%rax
  8004201d3c:	00 00 00 
  8004201d3f:	ff d0                	callq  *%rax

	sect = _dwarf_find_section(".debug_info");	
  8004201d41:	48 bf a6 98 20 04 80 	movabs $0x80042098a6,%rdi
  8004201d48:	00 00 00 
  8004201d4b:	48 b8 1b 85 20 04 80 	movabs $0x800420851b,%rax
  8004201d52:	00 00 00 
  8004201d55:	ff d0                	callq  *%rax
  8004201d57:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	dbg->dbg_info_offset_elf = (uint64_t)sect->ds_data; 
  8004201d5b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004201d5f:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004201d63:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201d6a:	00 00 00 
  8004201d6d:	48 8b 00             	mov    (%rax),%rax
  8004201d70:	48 89 50 08          	mov    %rdx,0x8(%rax)
	dbg->dbg_info_size = sect->ds_size;
  8004201d74:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201d7b:	00 00 00 
  8004201d7e:	48 8b 00             	mov    (%rax),%rax
  8004201d81:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004201d85:	48 8b 52 18          	mov    0x18(%rdx),%rdx
  8004201d89:	48 89 50 10          	mov    %rdx,0x10(%rax)

	assert(dbg->dbg_info_size);
  8004201d8d:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201d94:	00 00 00 
  8004201d97:	48 8b 00             	mov    (%rax),%rax
  8004201d9a:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004201d9e:	48 85 c0             	test   %rax,%rax
  8004201da1:	0f 85 a4 01 00 00    	jne    8004201f4b <debuginfo_rip+0x2d9>
  8004201da7:	eb 2a                	jmp    8004201dd3 <debuginfo_rip+0x161>
		panic("User address");
  8004201da9:	48 ba 99 98 20 04 80 	movabs $0x8004209899,%rdx
  8004201db0:	00 00 00 
  8004201db3:	be 23 01 00 00       	mov    $0x123,%esi
  8004201db8:	48 bf 81 98 20 04 80 	movabs $0x8004209881,%rdi
  8004201dbf:	00 00 00 
  8004201dc2:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201dc7:	48 b9 9c 01 20 04 80 	movabs $0x800420019c,%rcx
  8004201dce:	00 00 00 
  8004201dd1:	ff d1                	callq  *%rcx
	assert(dbg->dbg_info_size);
  8004201dd3:	48 b9 b2 98 20 04 80 	movabs $0x80042098b2,%rcx
  8004201dda:	00 00 00 
  8004201ddd:	48 ba 6c 98 20 04 80 	movabs $0x800420986c,%rdx
  8004201de4:	00 00 00 
  8004201de7:	be 2b 01 00 00       	mov    $0x12b,%esi
  8004201dec:	48 bf 81 98 20 04 80 	movabs $0x8004209881,%rdi
  8004201df3:	00 00 00 
  8004201df6:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201dfb:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004201e02:	00 00 00 
  8004201e05:	41 ff d0             	callq  *%r8
	while(_get_next_cu(dbg, &cu) == 0)
	{
		if(dwarf_siblingof(dbg, NULL, &cudie, &cu) == DW_DLE_NO_ENTRY)
  8004201e08:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201e0f:	00 00 00 
  8004201e12:	48 8b 00             	mov    (%rax),%rax
  8004201e15:	48 8d 4d a0          	lea    -0x60(%rbp),%rcx
  8004201e19:	48 8d 95 c0 9e ff ff 	lea    -0x6140(%rbp),%rdx
  8004201e20:	be 00 00 00 00       	mov    $0x0,%esi
  8004201e25:	48 89 c7             	mov    %rax,%rdi
  8004201e28:	48 b8 6e 4e 20 04 80 	movabs $0x8004204e6e,%rax
  8004201e2f:	00 00 00 
  8004201e32:	ff d0                	callq  *%rax
  8004201e34:	83 f8 04             	cmp    $0x4,%eax
  8004201e37:	75 05                	jne    8004201e3e <debuginfo_rip+0x1cc>
			continue;
  8004201e39:	e9 0d 01 00 00       	jmpq   8004201f4b <debuginfo_rip+0x2d9>

		cudie.cu_header = &cu;
  8004201e3e:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004201e42:	48 89 85 20 a2 ff ff 	mov    %rax,-0x5de0(%rbp)
		cudie.cu_die = NULL;
  8004201e49:	48 c7 85 28 a2 ff ff 	movq   $0x0,-0x5dd8(%rbp)
  8004201e50:	00 00 00 00 

		if(dwarf_child(dbg, &cu, &cudie, &die) == DW_DLE_NO_ENTRY)
  8004201e54:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201e5b:	00 00 00 
  8004201e5e:	48 8b 00             	mov    (%rax),%rax
  8004201e61:	48 8d 8d 30 cf ff ff 	lea    -0x30d0(%rbp),%rcx
  8004201e68:	48 8d 95 c0 9e ff ff 	lea    -0x6140(%rbp),%rdx
  8004201e6f:	48 8d 75 a0          	lea    -0x60(%rbp),%rsi
  8004201e73:	48 89 c7             	mov    %rax,%rdi
  8004201e76:	48 b8 70 50 20 04 80 	movabs $0x8004205070,%rax
  8004201e7d:	00 00 00 
  8004201e80:	ff d0                	callq  *%rax
  8004201e82:	83 f8 04             	cmp    $0x4,%eax
  8004201e85:	75 05                	jne    8004201e8c <debuginfo_rip+0x21a>
			continue;
  8004201e87:	e9 bf 00 00 00       	jmpq   8004201f4b <debuginfo_rip+0x2d9>

		die.cu_header = &cu;
  8004201e8c:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004201e90:	48 89 85 90 d2 ff ff 	mov    %rax,-0x2d70(%rbp)
		die.cu_die = &cudie;
  8004201e97:	48 8d 85 c0 9e ff ff 	lea    -0x6140(%rbp),%rax
  8004201e9e:	48 89 85 98 d2 ff ff 	mov    %rax,-0x2d68(%rbp)
		while(1)
		{
			if(list_func_die(info, &die, addr))
  8004201ea5:	48 8b 95 48 6e ff ff 	mov    -0x91b8(%rbp),%rdx
  8004201eac:	48 8d 8d 30 cf ff ff 	lea    -0x30d0(%rbp),%rcx
  8004201eb3:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201eba:	48 89 ce             	mov    %rcx,%rsi
  8004201ebd:	48 89 c7             	mov    %rax,%rdi
  8004201ec0:	48 b8 4b 15 20 04 80 	movabs $0x800420154b,%rax
  8004201ec7:	00 00 00 
  8004201eca:	ff d0                	callq  *%rax
  8004201ecc:	85 c0                	test   %eax,%eax
  8004201ece:	0f 85 ac 00 00 00    	jne    8004201f80 <debuginfo_rip+0x30e>
				goto find_done;
			if(dwarf_siblingof(dbg, &die, &die2, &cu) < 0)
  8004201ed4:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201edb:	00 00 00 
  8004201ede:	48 8b 00             	mov    (%rax),%rax
  8004201ee1:	48 8d 4d a0          	lea    -0x60(%rbp),%rcx
  8004201ee5:	48 8d 95 50 6e ff ff 	lea    -0x91b0(%rbp),%rdx
  8004201eec:	48 8d b5 30 cf ff ff 	lea    -0x30d0(%rbp),%rsi
  8004201ef3:	48 89 c7             	mov    %rax,%rdi
  8004201ef6:	48 b8 6e 4e 20 04 80 	movabs $0x8004204e6e,%rax
  8004201efd:	00 00 00 
  8004201f00:	ff d0                	callq  *%rax
  8004201f02:	85 c0                	test   %eax,%eax
  8004201f04:	79 02                	jns    8004201f08 <debuginfo_rip+0x296>
				break; 
  8004201f06:	eb 43                	jmp    8004201f4b <debuginfo_rip+0x2d9>
			die = die2;
  8004201f08:	48 8d 85 30 cf ff ff 	lea    -0x30d0(%rbp),%rax
  8004201f0f:	48 8d 8d 50 6e ff ff 	lea    -0x91b0(%rbp),%rcx
  8004201f16:	ba 70 30 00 00       	mov    $0x3070,%edx
  8004201f1b:	48 89 ce             	mov    %rcx,%rsi
  8004201f1e:	48 89 c7             	mov    %rax,%rdi
  8004201f21:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  8004201f28:	00 00 00 
  8004201f2b:	ff d0                	callq  *%rax
			die.cu_header = &cu;
  8004201f2d:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004201f31:	48 89 85 90 d2 ff ff 	mov    %rax,-0x2d70(%rbp)
			die.cu_die = &cudie;
  8004201f38:	48 8d 85 c0 9e ff ff 	lea    -0x6140(%rbp),%rax
  8004201f3f:	48 89 85 98 d2 ff ff 	mov    %rax,-0x2d68(%rbp)
			if(list_func_die(info, &die, addr))
  8004201f46:	e9 5a ff ff ff       	jmpq   8004201ea5 <debuginfo_rip+0x233>
	while(_get_next_cu(dbg, &cu) == 0)
  8004201f4b:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201f52:	00 00 00 
  8004201f55:	48 8b 00             	mov    (%rax),%rax
  8004201f58:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
  8004201f5c:	48 89 d6             	mov    %rdx,%rsi
  8004201f5f:	48 89 c7             	mov    %rax,%rdi
  8004201f62:	48 b8 1d 3e 20 04 80 	movabs $0x8004203e1d,%rax
  8004201f69:	00 00 00 
  8004201f6c:	ff d0                	callq  *%rax
  8004201f6e:	85 c0                	test   %eax,%eax
  8004201f70:	0f 84 92 fe ff ff    	je     8004201e08 <debuginfo_rip+0x196>
		}
	}

	return -1;
  8004201f76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004201f7b:	e9 c7 00 00 00       	jmpq   8004202047 <debuginfo_rip+0x3d5>
				goto find_done;
  8004201f80:	90                   	nop

find_done:

	if (dwarf_init_eh_section(dbg, NULL) == DW_DLV_ERROR)
  8004201f81:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201f88:	00 00 00 
  8004201f8b:	48 8b 00             	mov    (%rax),%rax
  8004201f8e:	be 00 00 00 00       	mov    $0x0,%esi
  8004201f93:	48 89 c7             	mov    %rax,%rdi
  8004201f96:	48 b8 98 77 20 04 80 	movabs $0x8004207798,%rax
  8004201f9d:	00 00 00 
  8004201fa0:	ff d0                	callq  *%rax
  8004201fa2:	83 f8 01             	cmp    $0x1,%eax
  8004201fa5:	75 0a                	jne    8004201fb1 <debuginfo_rip+0x33f>
		return -1;
  8004201fa7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004201fac:	e9 96 00 00 00       	jmpq   8004202047 <debuginfo_rip+0x3d5>

	if (dwarf_get_fde_at_pc(dbg, addr, fde, cie, NULL) == DW_DLV_OK) {
  8004201fb1:	48 b8 b8 b5 21 04 80 	movabs $0x800421b5b8,%rax
  8004201fb8:	00 00 00 
  8004201fbb:	48 8b 08             	mov    (%rax),%rcx
  8004201fbe:	48 b8 b0 b5 21 04 80 	movabs $0x800421b5b0,%rax
  8004201fc5:	00 00 00 
  8004201fc8:	48 8b 10             	mov    (%rax),%rdx
  8004201fcb:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004201fd2:	00 00 00 
  8004201fd5:	48 8b 00             	mov    (%rax),%rax
  8004201fd8:	48 8b b5 48 6e ff ff 	mov    -0x91b8(%rbp),%rsi
  8004201fdf:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8004201fe5:	48 89 c7             	mov    %rax,%rdi
  8004201fe8:	48 b8 8e 52 20 04 80 	movabs $0x800420528e,%rax
  8004201fef:	00 00 00 
  8004201ff2:	ff d0                	callq  *%rax
  8004201ff4:	85 c0                	test   %eax,%eax
  8004201ff6:	75 4a                	jne    8004202042 <debuginfo_rip+0x3d0>
		dwarf_get_fde_info_for_all_regs(dbg, fde, addr,
  8004201ff8:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201fff:	48 8d 88 a8 00 00 00 	lea    0xa8(%rax),%rcx
  8004202006:	48 b8 b0 b5 21 04 80 	movabs $0x800421b5b0,%rax
  800420200d:	00 00 00 
  8004202010:	48 8b 30             	mov    (%rax),%rsi
  8004202013:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  800420201a:	00 00 00 
  800420201d:	48 8b 00             	mov    (%rax),%rax
  8004202020:	48 8b 95 48 6e ff ff 	mov    -0x91b8(%rbp),%rdx
  8004202027:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  800420202d:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8004202033:	48 89 c7             	mov    %rax,%rdi
  8004202036:	48 b8 8d 65 20 04 80 	movabs $0x800420658d,%rax
  800420203d:	00 00 00 
  8004202040:	ff d0                	callq  *%rax
					break;
			}
		}
#endif
	}
	return 0;
  8004202042:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004202047:	c9                   	leaveq 
  8004202048:	c3                   	retq   

0000008004202049 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8004202049:	55                   	push   %rbp
  800420204a:	48 89 e5             	mov    %rsp,%rbp
  800420204d:	48 83 ec 30          	sub    $0x30,%rsp
  8004202051:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202055:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8004202059:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  800420205d:	89 4d e4             	mov    %ecx,-0x1c(%rbp)
  8004202060:	44 89 45 e0          	mov    %r8d,-0x20(%rbp)
  8004202064:	44 89 4d dc          	mov    %r9d,-0x24(%rbp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8004202068:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  800420206b:	48 39 45 e8          	cmp    %rax,-0x18(%rbp)
  800420206f:	72 54                	jb     80042020c5 <printnum+0x7c>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8004202071:	8b 45 e0             	mov    -0x20(%rbp),%eax
  8004202074:	8d 78 ff             	lea    -0x1(%rax),%edi
  8004202077:	8b 75 e4             	mov    -0x1c(%rbp),%esi
  800420207a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420207e:	ba 00 00 00 00       	mov    $0x0,%edx
  8004202083:	48 f7 f6             	div    %rsi
  8004202086:	49 89 c2             	mov    %rax,%r10
  8004202089:	8b 4d dc             	mov    -0x24(%rbp),%ecx
  800420208c:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  800420208f:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  8004202093:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202097:	41 89 c9             	mov    %ecx,%r9d
  800420209a:	41 89 f8             	mov    %edi,%r8d
  800420209d:	89 d1                	mov    %edx,%ecx
  800420209f:	4c 89 d2             	mov    %r10,%rdx
  80042020a2:	48 89 c7             	mov    %rax,%rdi
  80042020a5:	48 b8 49 20 20 04 80 	movabs $0x8004202049,%rax
  80042020ac:	00 00 00 
  80042020af:	ff d0                	callq  *%rax
  80042020b1:	eb 1c                	jmp    80042020cf <printnum+0x86>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80042020b3:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  80042020b7:	8b 55 dc             	mov    -0x24(%rbp),%edx
  80042020ba:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042020be:	48 89 ce             	mov    %rcx,%rsi
  80042020c1:	89 d7                	mov    %edx,%edi
  80042020c3:	ff d0                	callq  *%rax
		while (--width > 0)
  80042020c5:	83 6d e0 01          	subl   $0x1,-0x20(%rbp)
  80042020c9:	83 7d e0 00          	cmpl   $0x0,-0x20(%rbp)
  80042020cd:	7f e4                	jg     80042020b3 <printnum+0x6a>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80042020cf:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  80042020d2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042020d6:	ba 00 00 00 00       	mov    $0x0,%edx
  80042020db:	48 f7 f1             	div    %rcx
  80042020de:	48 b8 10 9a 20 04 80 	movabs $0x8004209a10,%rax
  80042020e5:	00 00 00 
  80042020e8:	0f b6 04 10          	movzbl (%rax,%rdx,1),%eax
  80042020ec:	0f be d0             	movsbl %al,%edx
  80042020ef:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  80042020f3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042020f7:	48 89 ce             	mov    %rcx,%rsi
  80042020fa:	89 d7                	mov    %edx,%edi
  80042020fc:	ff d0                	callq  *%rax
}
  80042020fe:	90                   	nop
  80042020ff:	c9                   	leaveq 
  8004202100:	c3                   	retq   

0000008004202101 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8004202101:	55                   	push   %rbp
  8004202102:	48 89 e5             	mov    %rsp,%rbp
  8004202105:	48 83 ec 20          	sub    $0x20,%rsp
  8004202109:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420210d:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	unsigned long long x;    
	if (lflag >= 2)
  8004202110:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  8004202114:	7e 4f                	jle    8004202165 <getuint+0x64>
		x= va_arg(*ap, unsigned long long);
  8004202116:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420211a:	8b 00                	mov    (%rax),%eax
  800420211c:	83 f8 2f             	cmp    $0x2f,%eax
  800420211f:	77 24                	ja     8004202145 <getuint+0x44>
  8004202121:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202125:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004202129:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420212d:	8b 00                	mov    (%rax),%eax
  800420212f:	89 c0                	mov    %eax,%eax
  8004202131:	48 01 d0             	add    %rdx,%rax
  8004202134:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202138:	8b 12                	mov    (%rdx),%edx
  800420213a:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800420213d:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202141:	89 0a                	mov    %ecx,(%rdx)
  8004202143:	eb 14                	jmp    8004202159 <getuint+0x58>
  8004202145:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202149:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420214d:	48 8d 48 08          	lea    0x8(%rax),%rcx
  8004202151:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202155:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8004202159:	48 8b 00             	mov    (%rax),%rax
  800420215c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004202160:	e9 9d 00 00 00       	jmpq   8004202202 <getuint+0x101>
	else if (lflag)
  8004202165:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004202169:	74 4c                	je     80042021b7 <getuint+0xb6>
		x= va_arg(*ap, unsigned long);
  800420216b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420216f:	8b 00                	mov    (%rax),%eax
  8004202171:	83 f8 2f             	cmp    $0x2f,%eax
  8004202174:	77 24                	ja     800420219a <getuint+0x99>
  8004202176:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420217a:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800420217e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202182:	8b 00                	mov    (%rax),%eax
  8004202184:	89 c0                	mov    %eax,%eax
  8004202186:	48 01 d0             	add    %rdx,%rax
  8004202189:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420218d:	8b 12                	mov    (%rdx),%edx
  800420218f:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202192:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202196:	89 0a                	mov    %ecx,(%rdx)
  8004202198:	eb 14                	jmp    80042021ae <getuint+0xad>
  800420219a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420219e:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042021a2:	48 8d 48 08          	lea    0x8(%rax),%rcx
  80042021a6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021aa:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  80042021ae:	48 8b 00             	mov    (%rax),%rax
  80042021b1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042021b5:	eb 4b                	jmp    8004202202 <getuint+0x101>
	else
		x= va_arg(*ap, unsigned int);
  80042021b7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021bb:	8b 00                	mov    (%rax),%eax
  80042021bd:	83 f8 2f             	cmp    $0x2f,%eax
  80042021c0:	77 24                	ja     80042021e6 <getuint+0xe5>
  80042021c2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021c6:	48 8b 50 10          	mov    0x10(%rax),%rdx
  80042021ca:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021ce:	8b 00                	mov    (%rax),%eax
  80042021d0:	89 c0                	mov    %eax,%eax
  80042021d2:	48 01 d0             	add    %rdx,%rax
  80042021d5:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021d9:	8b 12                	mov    (%rdx),%edx
  80042021db:	8d 4a 08             	lea    0x8(%rdx),%ecx
  80042021de:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021e2:	89 0a                	mov    %ecx,(%rdx)
  80042021e4:	eb 14                	jmp    80042021fa <getuint+0xf9>
  80042021e6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021ea:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042021ee:	48 8d 48 08          	lea    0x8(%rax),%rcx
  80042021f2:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021f6:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  80042021fa:	8b 00                	mov    (%rax),%eax
  80042021fc:	89 c0                	mov    %eax,%eax
  80042021fe:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	return x;
  8004202202:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202206:	c9                   	leaveq 
  8004202207:	c3                   	retq   

0000008004202208 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  8004202208:	55                   	push   %rbp
  8004202209:	48 89 e5             	mov    %rsp,%rbp
  800420220c:	48 83 ec 20          	sub    $0x20,%rsp
  8004202210:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202214:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	long long x;
	if (lflag >= 2)
  8004202217:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800420221b:	7e 4f                	jle    800420226c <getint+0x64>
		x=va_arg(*ap, long long);
  800420221d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202221:	8b 00                	mov    (%rax),%eax
  8004202223:	83 f8 2f             	cmp    $0x2f,%eax
  8004202226:	77 24                	ja     800420224c <getint+0x44>
  8004202228:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420222c:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004202230:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202234:	8b 00                	mov    (%rax),%eax
  8004202236:	89 c0                	mov    %eax,%eax
  8004202238:	48 01 d0             	add    %rdx,%rax
  800420223b:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420223f:	8b 12                	mov    (%rdx),%edx
  8004202241:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202244:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202248:	89 0a                	mov    %ecx,(%rdx)
  800420224a:	eb 14                	jmp    8004202260 <getint+0x58>
  800420224c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202250:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004202254:	48 8d 48 08          	lea    0x8(%rax),%rcx
  8004202258:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420225c:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8004202260:	48 8b 00             	mov    (%rax),%rax
  8004202263:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004202267:	e9 9d 00 00 00       	jmpq   8004202309 <getint+0x101>
	else if (lflag)
  800420226c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004202270:	74 4c                	je     80042022be <getint+0xb6>
		x=va_arg(*ap, long);
  8004202272:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202276:	8b 00                	mov    (%rax),%eax
  8004202278:	83 f8 2f             	cmp    $0x2f,%eax
  800420227b:	77 24                	ja     80042022a1 <getint+0x99>
  800420227d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202281:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004202285:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202289:	8b 00                	mov    (%rax),%eax
  800420228b:	89 c0                	mov    %eax,%eax
  800420228d:	48 01 d0             	add    %rdx,%rax
  8004202290:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202294:	8b 12                	mov    (%rdx),%edx
  8004202296:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202299:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420229d:	89 0a                	mov    %ecx,(%rdx)
  800420229f:	eb 14                	jmp    80042022b5 <getint+0xad>
  80042022a1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042022a5:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042022a9:	48 8d 48 08          	lea    0x8(%rax),%rcx
  80042022ad:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042022b1:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  80042022b5:	48 8b 00             	mov    (%rax),%rax
  80042022b8:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042022bc:	eb 4b                	jmp    8004202309 <getint+0x101>
	else
		x=va_arg(*ap, int);
  80042022be:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042022c2:	8b 00                	mov    (%rax),%eax
  80042022c4:	83 f8 2f             	cmp    $0x2f,%eax
  80042022c7:	77 24                	ja     80042022ed <getint+0xe5>
  80042022c9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042022cd:	48 8b 50 10          	mov    0x10(%rax),%rdx
  80042022d1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042022d5:	8b 00                	mov    (%rax),%eax
  80042022d7:	89 c0                	mov    %eax,%eax
  80042022d9:	48 01 d0             	add    %rdx,%rax
  80042022dc:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042022e0:	8b 12                	mov    (%rdx),%edx
  80042022e2:	8d 4a 08             	lea    0x8(%rdx),%ecx
  80042022e5:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042022e9:	89 0a                	mov    %ecx,(%rdx)
  80042022eb:	eb 14                	jmp    8004202301 <getint+0xf9>
  80042022ed:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042022f1:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042022f5:	48 8d 48 08          	lea    0x8(%rax),%rcx
  80042022f9:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042022fd:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8004202301:	8b 00                	mov    (%rax),%eax
  8004202303:	48 98                	cltq   
  8004202305:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	return x;
  8004202309:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  800420230d:	c9                   	leaveq 
  800420230e:	c3                   	retq   

000000800420230f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800420230f:	55                   	push   %rbp
  8004202310:	48 89 e5             	mov    %rsp,%rbp
  8004202313:	41 54                	push   %r12
  8004202315:	53                   	push   %rbx
  8004202316:	48 83 ec 60          	sub    $0x60,%rsp
  800420231a:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  800420231e:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  8004202322:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  8004202326:	48 89 4d 90          	mov    %rcx,-0x70(%rbp)
	register int ch, err;
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	va_list aq;
	va_copy(aq,ap);
  800420232a:	48 8d 4d b8          	lea    -0x48(%rbp),%rcx
  800420232e:	48 8b 75 90          	mov    -0x70(%rbp),%rsi
  8004202332:	48 8b 06             	mov    (%rsi),%rax
  8004202335:	48 8b 56 08          	mov    0x8(%rsi),%rdx
  8004202339:	48 89 01             	mov    %rax,(%rcx)
  800420233c:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  8004202340:	48 8b 46 10          	mov    0x10(%rsi),%rax
  8004202344:	48 89 41 10          	mov    %rax,0x10(%rcx)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004202348:	eb 17                	jmp    8004202361 <vprintfmt+0x52>
			if (ch == '\0')
  800420234a:	85 db                	test   %ebx,%ebx
  800420234c:	0f 84 cc 04 00 00    	je     800420281e <vprintfmt+0x50f>
				return;
			putch(ch, putdat);
  8004202352:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202356:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420235a:	48 89 d6             	mov    %rdx,%rsi
  800420235d:	89 df                	mov    %ebx,%edi
  800420235f:	ff d0                	callq  *%rax
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004202361:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004202365:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004202369:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800420236d:	0f b6 00             	movzbl (%rax),%eax
  8004202370:	0f b6 d8             	movzbl %al,%ebx
  8004202373:	83 fb 25             	cmp    $0x25,%ebx
  8004202376:	75 d2                	jne    800420234a <vprintfmt+0x3b>
		}

		// Process a %-escape sequence
		padc = ' ';
  8004202378:	c6 45 d3 20          	movb   $0x20,-0x2d(%rbp)
		width = -1;
  800420237c:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%rbp)
		precision = -1;
  8004202383:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
		lflag = 0;
  800420238a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
		altflag = 0;
  8004202391:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004202398:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420239c:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80042023a0:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  80042023a4:	0f b6 00             	movzbl (%rax),%eax
  80042023a7:	0f b6 d8             	movzbl %al,%ebx
  80042023aa:	8d 43 dd             	lea    -0x23(%rbx),%eax
  80042023ad:	83 f8 55             	cmp    $0x55,%eax
  80042023b0:	0f 87 35 04 00 00    	ja     80042027eb <vprintfmt+0x4dc>
  80042023b6:	89 c0                	mov    %eax,%eax
  80042023b8:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  80042023bf:	00 
  80042023c0:	48 b8 38 9a 20 04 80 	movabs $0x8004209a38,%rax
  80042023c7:	00 00 00 
  80042023ca:	48 01 d0             	add    %rdx,%rax
  80042023cd:	48 8b 00             	mov    (%rax),%rax
  80042023d0:	ff e0                	jmpq   *%rax

			// flag to pad on the right
		case '-':
			padc = '-';
  80042023d2:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%rbp)
			goto reswitch;
  80042023d6:	eb c0                	jmp    8004202398 <vprintfmt+0x89>

			// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80042023d8:	c6 45 d3 30          	movb   $0x30,-0x2d(%rbp)
			goto reswitch;
  80042023dc:	eb ba                	jmp    8004202398 <vprintfmt+0x89>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80042023de:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
				precision = precision * 10 + ch - '0';
  80042023e5:	8b 55 d8             	mov    -0x28(%rbp),%edx
  80042023e8:	89 d0                	mov    %edx,%eax
  80042023ea:	c1 e0 02             	shl    $0x2,%eax
  80042023ed:	01 d0                	add    %edx,%eax
  80042023ef:	01 c0                	add    %eax,%eax
  80042023f1:	01 d8                	add    %ebx,%eax
  80042023f3:	83 e8 30             	sub    $0x30,%eax
  80042023f6:	89 45 d8             	mov    %eax,-0x28(%rbp)
				ch = *fmt;
  80042023f9:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042023fd:	0f b6 00             	movzbl (%rax),%eax
  8004202400:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  8004202403:	83 fb 2f             	cmp    $0x2f,%ebx
  8004202406:	7e 60                	jle    8004202468 <vprintfmt+0x159>
  8004202408:	83 fb 39             	cmp    $0x39,%ebx
  800420240b:	7f 5b                	jg     8004202468 <vprintfmt+0x159>
			for (precision = 0; ; ++fmt) {
  800420240d:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
				precision = precision * 10 + ch - '0';
  8004202412:	eb d1                	jmp    80042023e5 <vprintfmt+0xd6>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(aq, int);
  8004202414:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8004202417:	83 f8 2f             	cmp    $0x2f,%eax
  800420241a:	77 17                	ja     8004202433 <vprintfmt+0x124>
  800420241c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004202420:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202423:	89 d2                	mov    %edx,%edx
  8004202425:	48 01 d0             	add    %rdx,%rax
  8004202428:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800420242b:	83 c2 08             	add    $0x8,%edx
  800420242e:	89 55 b8             	mov    %edx,-0x48(%rbp)
  8004202431:	eb 0c                	jmp    800420243f <vprintfmt+0x130>
  8004202433:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004202437:	48 8d 50 08          	lea    0x8(%rax),%rdx
  800420243b:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800420243f:	8b 00                	mov    (%rax),%eax
  8004202441:	89 45 d8             	mov    %eax,-0x28(%rbp)
			goto process_precision;
  8004202444:	eb 23                	jmp    8004202469 <vprintfmt+0x15a>

		case '.':
			if (width < 0)
  8004202446:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800420244a:	0f 89 48 ff ff ff    	jns    8004202398 <vprintfmt+0x89>
				width = 0;
  8004202450:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
			goto reswitch;
  8004202457:	e9 3c ff ff ff       	jmpq   8004202398 <vprintfmt+0x89>

		case '#':
			altflag = 1;
  800420245c:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
			goto reswitch;
  8004202463:	e9 30 ff ff ff       	jmpq   8004202398 <vprintfmt+0x89>
			goto process_precision;
  8004202468:	90                   	nop

		process_precision:
			if (width < 0)
  8004202469:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800420246d:	0f 89 25 ff ff ff    	jns    8004202398 <vprintfmt+0x89>
				width = precision, precision = -1;
  8004202473:	8b 45 d8             	mov    -0x28(%rbp),%eax
  8004202476:	89 45 dc             	mov    %eax,-0x24(%rbp)
  8004202479:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
			goto reswitch;
  8004202480:	e9 13 ff ff ff       	jmpq   8004202398 <vprintfmt+0x89>

			// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004202485:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
			goto reswitch;
  8004202489:	e9 0a ff ff ff       	jmpq   8004202398 <vprintfmt+0x89>

			// character
		case 'c':
			putch(va_arg(aq, int), putdat);
  800420248e:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8004202491:	83 f8 2f             	cmp    $0x2f,%eax
  8004202494:	77 17                	ja     80042024ad <vprintfmt+0x19e>
  8004202496:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420249a:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800420249d:	89 d2                	mov    %edx,%edx
  800420249f:	48 01 d0             	add    %rdx,%rax
  80042024a2:	8b 55 b8             	mov    -0x48(%rbp),%edx
  80042024a5:	83 c2 08             	add    $0x8,%edx
  80042024a8:	89 55 b8             	mov    %edx,-0x48(%rbp)
  80042024ab:	eb 0c                	jmp    80042024b9 <vprintfmt+0x1aa>
  80042024ad:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042024b1:	48 8d 50 08          	lea    0x8(%rax),%rdx
  80042024b5:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80042024b9:	8b 10                	mov    (%rax),%edx
  80042024bb:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  80042024bf:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042024c3:	48 89 ce             	mov    %rcx,%rsi
  80042024c6:	89 d7                	mov    %edx,%edi
  80042024c8:	ff d0                	callq  *%rax
			break;
  80042024ca:	e9 4a 03 00 00       	jmpq   8004202819 <vprintfmt+0x50a>

			// error message
		case 'e':
			err = va_arg(aq, int);
  80042024cf:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042024d2:	83 f8 2f             	cmp    $0x2f,%eax
  80042024d5:	77 17                	ja     80042024ee <vprintfmt+0x1df>
  80042024d7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042024db:	8b 55 b8             	mov    -0x48(%rbp),%edx
  80042024de:	89 d2                	mov    %edx,%edx
  80042024e0:	48 01 d0             	add    %rdx,%rax
  80042024e3:	8b 55 b8             	mov    -0x48(%rbp),%edx
  80042024e6:	83 c2 08             	add    $0x8,%edx
  80042024e9:	89 55 b8             	mov    %edx,-0x48(%rbp)
  80042024ec:	eb 0c                	jmp    80042024fa <vprintfmt+0x1eb>
  80042024ee:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042024f2:	48 8d 50 08          	lea    0x8(%rax),%rdx
  80042024f6:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80042024fa:	8b 18                	mov    (%rax),%ebx
			if (err < 0)
  80042024fc:	85 db                	test   %ebx,%ebx
  80042024fe:	79 02                	jns    8004202502 <vprintfmt+0x1f3>
				err = -err;
  8004202500:	f7 db                	neg    %ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004202502:	83 fb 15             	cmp    $0x15,%ebx
  8004202505:	7f 16                	jg     800420251d <vprintfmt+0x20e>
  8004202507:	48 b8 60 99 20 04 80 	movabs $0x8004209960,%rax
  800420250e:	00 00 00 
  8004202511:	48 63 d3             	movslq %ebx,%rdx
  8004202514:	4c 8b 24 d0          	mov    (%rax,%rdx,8),%r12
  8004202518:	4d 85 e4             	test   %r12,%r12
  800420251b:	75 2e                	jne    800420254b <vprintfmt+0x23c>
				printfmt(putch, putdat, "error %d", err);
  800420251d:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  8004202521:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202525:	89 d9                	mov    %ebx,%ecx
  8004202527:	48 ba 21 9a 20 04 80 	movabs $0x8004209a21,%rdx
  800420252e:	00 00 00 
  8004202531:	48 89 c7             	mov    %rax,%rdi
  8004202534:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202539:	49 b8 28 28 20 04 80 	movabs $0x8004202828,%r8
  8004202540:	00 00 00 
  8004202543:	41 ff d0             	callq  *%r8
			else
				printfmt(putch, putdat, "%s", p);
			break;
  8004202546:	e9 ce 02 00 00       	jmpq   8004202819 <vprintfmt+0x50a>
				printfmt(putch, putdat, "%s", p);
  800420254b:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800420254f:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202553:	4c 89 e1             	mov    %r12,%rcx
  8004202556:	48 ba 2a 9a 20 04 80 	movabs $0x8004209a2a,%rdx
  800420255d:	00 00 00 
  8004202560:	48 89 c7             	mov    %rax,%rdi
  8004202563:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202568:	49 b8 28 28 20 04 80 	movabs $0x8004202828,%r8
  800420256f:	00 00 00 
  8004202572:	41 ff d0             	callq  *%r8
			break;
  8004202575:	e9 9f 02 00 00       	jmpq   8004202819 <vprintfmt+0x50a>

			// string
		case 's':
			if ((p = va_arg(aq, char *)) == NULL)
  800420257a:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800420257d:	83 f8 2f             	cmp    $0x2f,%eax
  8004202580:	77 17                	ja     8004202599 <vprintfmt+0x28a>
  8004202582:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004202586:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202589:	89 d2                	mov    %edx,%edx
  800420258b:	48 01 d0             	add    %rdx,%rax
  800420258e:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202591:	83 c2 08             	add    $0x8,%edx
  8004202594:	89 55 b8             	mov    %edx,-0x48(%rbp)
  8004202597:	eb 0c                	jmp    80042025a5 <vprintfmt+0x296>
  8004202599:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420259d:	48 8d 50 08          	lea    0x8(%rax),%rdx
  80042025a1:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80042025a5:	4c 8b 20             	mov    (%rax),%r12
  80042025a8:	4d 85 e4             	test   %r12,%r12
  80042025ab:	75 0a                	jne    80042025b7 <vprintfmt+0x2a8>
				p = "(null)";
  80042025ad:	49 bc 2d 9a 20 04 80 	movabs $0x8004209a2d,%r12
  80042025b4:	00 00 00 
			if (width > 0 && padc != '-')
  80042025b7:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  80042025bb:	7e 78                	jle    8004202635 <vprintfmt+0x326>
  80042025bd:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%rbp)
  80042025c1:	74 72                	je     8004202635 <vprintfmt+0x326>
				for (width -= strnlen(p, precision); width > 0; width--)
  80042025c3:	8b 45 d8             	mov    -0x28(%rbp),%eax
  80042025c6:	48 98                	cltq   
  80042025c8:	48 89 c6             	mov    %rax,%rsi
  80042025cb:	4c 89 e7             	mov    %r12,%rdi
  80042025ce:	48 b8 29 2c 20 04 80 	movabs $0x8004202c29,%rax
  80042025d5:	00 00 00 
  80042025d8:	ff d0                	callq  *%rax
  80042025da:	29 45 dc             	sub    %eax,-0x24(%rbp)
  80042025dd:	eb 17                	jmp    80042025f6 <vprintfmt+0x2e7>
					putch(padc, putdat);
  80042025df:	0f be 55 d3          	movsbl -0x2d(%rbp),%edx
  80042025e3:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  80042025e7:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042025eb:	48 89 ce             	mov    %rcx,%rsi
  80042025ee:	89 d7                	mov    %edx,%edi
  80042025f0:	ff d0                	callq  *%rax
				for (width -= strnlen(p, precision); width > 0; width--)
  80042025f2:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  80042025f6:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  80042025fa:	7f e3                	jg     80042025df <vprintfmt+0x2d0>
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80042025fc:	eb 37                	jmp    8004202635 <vprintfmt+0x326>
				if (altflag && (ch < ' ' || ch > '~'))
  80042025fe:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
  8004202602:	74 1e                	je     8004202622 <vprintfmt+0x313>
  8004202604:	83 fb 1f             	cmp    $0x1f,%ebx
  8004202607:	7e 05                	jle    800420260e <vprintfmt+0x2ff>
  8004202609:	83 fb 7e             	cmp    $0x7e,%ebx
  800420260c:	7e 14                	jle    8004202622 <vprintfmt+0x313>
					putch('?', putdat);
  800420260e:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202612:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202616:	48 89 d6             	mov    %rdx,%rsi
  8004202619:	bf 3f 00 00 00       	mov    $0x3f,%edi
  800420261e:	ff d0                	callq  *%rax
  8004202620:	eb 0f                	jmp    8004202631 <vprintfmt+0x322>
				else
					putch(ch, putdat);
  8004202622:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202626:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420262a:	48 89 d6             	mov    %rdx,%rsi
  800420262d:	89 df                	mov    %ebx,%edi
  800420262f:	ff d0                	callq  *%rax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004202631:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  8004202635:	4c 89 e0             	mov    %r12,%rax
  8004202638:	4c 8d 60 01          	lea    0x1(%rax),%r12
  800420263c:	0f b6 00             	movzbl (%rax),%eax
  800420263f:	0f be d8             	movsbl %al,%ebx
  8004202642:	85 db                	test   %ebx,%ebx
  8004202644:	74 28                	je     800420266e <vprintfmt+0x35f>
  8004202646:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  800420264a:	78 b2                	js     80042025fe <vprintfmt+0x2ef>
  800420264c:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
  8004202650:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  8004202654:	79 a8                	jns    80042025fe <vprintfmt+0x2ef>
			for (; width > 0; width--)
  8004202656:	eb 16                	jmp    800420266e <vprintfmt+0x35f>
				putch(' ', putdat);
  8004202658:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800420265c:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202660:	48 89 d6             	mov    %rdx,%rsi
  8004202663:	bf 20 00 00 00       	mov    $0x20,%edi
  8004202668:	ff d0                	callq  *%rax
			for (; width > 0; width--)
  800420266a:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800420266e:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004202672:	7f e4                	jg     8004202658 <vprintfmt+0x349>
			break;
  8004202674:	e9 a0 01 00 00       	jmpq   8004202819 <vprintfmt+0x50a>

			// (signed) decimal
		case 'd':
			num = getint(&aq, 3);
  8004202679:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800420267d:	be 03 00 00 00       	mov    $0x3,%esi
  8004202682:	48 89 c7             	mov    %rax,%rdi
  8004202685:	48 b8 08 22 20 04 80 	movabs $0x8004202208,%rax
  800420268c:	00 00 00 
  800420268f:	ff d0                	callq  *%rax
  8004202691:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			if ((long long) num < 0) {
  8004202695:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202699:	48 85 c0             	test   %rax,%rax
  800420269c:	79 1d                	jns    80042026bb <vprintfmt+0x3ac>
				putch('-', putdat);
  800420269e:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80042026a2:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042026a6:	48 89 d6             	mov    %rdx,%rsi
  80042026a9:	bf 2d 00 00 00       	mov    $0x2d,%edi
  80042026ae:	ff d0                	callq  *%rax
				num = -(long long) num;
  80042026b0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042026b4:	48 f7 d8             	neg    %rax
  80042026b7:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			}
			base = 10;
  80042026bb:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
			goto number;
  80042026c2:	e9 e5 00 00 00       	jmpq   80042027ac <vprintfmt+0x49d>

			// unsigned decimal
		case 'u':
			num = getuint(&aq, 3);
  80042026c7:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  80042026cb:	be 03 00 00 00       	mov    $0x3,%esi
  80042026d0:	48 89 c7             	mov    %rax,%rdi
  80042026d3:	48 b8 01 21 20 04 80 	movabs $0x8004202101,%rax
  80042026da:	00 00 00 
  80042026dd:	ff d0                	callq  *%rax
  80042026df:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			base = 10;
  80042026e3:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
			goto number;
  80042026ea:	e9 bd 00 00 00       	jmpq   80042027ac <vprintfmt+0x49d>

			// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80042026ef:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80042026f3:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042026f7:	48 89 d6             	mov    %rdx,%rsi
  80042026fa:	bf 58 00 00 00       	mov    $0x58,%edi
  80042026ff:	ff d0                	callq  *%rax
			putch('X', putdat);
  8004202701:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202705:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202709:	48 89 d6             	mov    %rdx,%rsi
  800420270c:	bf 58 00 00 00       	mov    $0x58,%edi
  8004202711:	ff d0                	callq  *%rax
			putch('X', putdat);
  8004202713:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202717:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420271b:	48 89 d6             	mov    %rdx,%rsi
  800420271e:	bf 58 00 00 00       	mov    $0x58,%edi
  8004202723:	ff d0                	callq  *%rax
			break;
  8004202725:	e9 ef 00 00 00       	jmpq   8004202819 <vprintfmt+0x50a>

			// pointer
		case 'p':
			putch('0', putdat);
  800420272a:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800420272e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202732:	48 89 d6             	mov    %rdx,%rsi
  8004202735:	bf 30 00 00 00       	mov    $0x30,%edi
  800420273a:	ff d0                	callq  *%rax
			putch('x', putdat);
  800420273c:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202740:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202744:	48 89 d6             	mov    %rdx,%rsi
  8004202747:	bf 78 00 00 00       	mov    $0x78,%edi
  800420274c:	ff d0                	callq  *%rax
			num = (unsigned long long)
				(uintptr_t) va_arg(aq, void *);
  800420274e:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8004202751:	83 f8 2f             	cmp    $0x2f,%eax
  8004202754:	77 17                	ja     800420276d <vprintfmt+0x45e>
  8004202756:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420275a:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800420275d:	89 d2                	mov    %edx,%edx
  800420275f:	48 01 d0             	add    %rdx,%rax
  8004202762:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202765:	83 c2 08             	add    $0x8,%edx
  8004202768:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800420276b:	eb 0c                	jmp    8004202779 <vprintfmt+0x46a>
  800420276d:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004202771:	48 8d 50 08          	lea    0x8(%rax),%rdx
  8004202775:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  8004202779:	48 8b 00             	mov    (%rax),%rax
			num = (unsigned long long)
  800420277c:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			base = 16;
  8004202780:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
			goto number;
  8004202787:	eb 23                	jmp    80042027ac <vprintfmt+0x49d>

			// (unsigned) hexadecimal
		case 'x':
			num = getuint(&aq, 3);
  8004202789:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800420278d:	be 03 00 00 00       	mov    $0x3,%esi
  8004202792:	48 89 c7             	mov    %rax,%rdi
  8004202795:	48 b8 01 21 20 04 80 	movabs $0x8004202101,%rax
  800420279c:	00 00 00 
  800420279f:	ff d0                	callq  *%rax
  80042027a1:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			base = 16;
  80042027a5:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
		number:
			printnum(putch, putdat, num, base, width, padc);
  80042027ac:	44 0f be 45 d3       	movsbl -0x2d(%rbp),%r8d
  80042027b1:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  80042027b4:	8b 7d dc             	mov    -0x24(%rbp),%edi
  80042027b7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042027bb:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  80042027bf:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042027c3:	45 89 c1             	mov    %r8d,%r9d
  80042027c6:	41 89 f8             	mov    %edi,%r8d
  80042027c9:	48 89 c7             	mov    %rax,%rdi
  80042027cc:	48 b8 49 20 20 04 80 	movabs $0x8004202049,%rax
  80042027d3:	00 00 00 
  80042027d6:	ff d0                	callq  *%rax
			break;
  80042027d8:	eb 3f                	jmp    8004202819 <vprintfmt+0x50a>

			// escaped '%' character
		case '%':
			putch(ch, putdat);
  80042027da:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80042027de:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042027e2:	48 89 d6             	mov    %rdx,%rsi
  80042027e5:	89 df                	mov    %ebx,%edi
  80042027e7:	ff d0                	callq  *%rax
			break;
  80042027e9:	eb 2e                	jmp    8004202819 <vprintfmt+0x50a>

			// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80042027eb:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80042027ef:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042027f3:	48 89 d6             	mov    %rdx,%rsi
  80042027f6:	bf 25 00 00 00       	mov    $0x25,%edi
  80042027fb:	ff d0                	callq  *%rax
			for (fmt--; fmt[-1] != '%'; fmt--)
  80042027fd:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8004202802:	eb 05                	jmp    8004202809 <vprintfmt+0x4fa>
  8004202804:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8004202809:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420280d:	48 83 e8 01          	sub    $0x1,%rax
  8004202811:	0f b6 00             	movzbl (%rax),%eax
  8004202814:	3c 25                	cmp    $0x25,%al
  8004202816:	75 ec                	jne    8004202804 <vprintfmt+0x4f5>
				/* do nothing */;
			break;
  8004202818:	90                   	nop
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004202819:	e9 43 fb ff ff       	jmpq   8004202361 <vprintfmt+0x52>
				return;
  800420281e:	90                   	nop
		}
	}
	va_end(aq);
}
  800420281f:	48 83 c4 60          	add    $0x60,%rsp
  8004202823:	5b                   	pop    %rbx
  8004202824:	41 5c                	pop    %r12
  8004202826:	5d                   	pop    %rbp
  8004202827:	c3                   	retq   

0000008004202828 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004202828:	55                   	push   %rbp
  8004202829:	48 89 e5             	mov    %rsp,%rbp
  800420282c:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  8004202833:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  800420283a:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  8004202841:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  8004202848:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  800420284f:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8004202856:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  800420285d:	84 c0                	test   %al,%al
  800420285f:	74 20                	je     8004202881 <printfmt+0x59>
  8004202861:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8004202865:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8004202869:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800420286d:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004202871:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8004202875:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8004202879:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800420287d:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
	va_list ap;

	va_start(ap, fmt);
  8004202881:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8004202888:	00 00 00 
  800420288b:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8004202892:	00 00 00 
  8004202895:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004202899:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  80042028a0:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80042028a7:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
	vprintfmt(putch, putdat, fmt, ap);
  80042028ae:	48 8d 8d 38 ff ff ff 	lea    -0xc8(%rbp),%rcx
  80042028b5:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  80042028bc:	48 8b b5 20 ff ff ff 	mov    -0xe0(%rbp),%rsi
  80042028c3:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  80042028ca:	48 89 c7             	mov    %rax,%rdi
  80042028cd:	48 b8 0f 23 20 04 80 	movabs $0x800420230f,%rax
  80042028d4:	00 00 00 
  80042028d7:	ff d0                	callq  *%rax
	va_end(ap);
}
  80042028d9:	90                   	nop
  80042028da:	c9                   	leaveq 
  80042028db:	c3                   	retq   

00000080042028dc <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80042028dc:	55                   	push   %rbp
  80042028dd:	48 89 e5             	mov    %rsp,%rbp
  80042028e0:	48 83 ec 10          	sub    $0x10,%rsp
  80042028e4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80042028e7:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	b->cnt++;
  80042028eb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042028ef:	8b 40 10             	mov    0x10(%rax),%eax
  80042028f2:	8d 50 01             	lea    0x1(%rax),%edx
  80042028f5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042028f9:	89 50 10             	mov    %edx,0x10(%rax)
	if (b->buf < b->ebuf)
  80042028fc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202900:	48 8b 10             	mov    (%rax),%rdx
  8004202903:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202907:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420290b:	48 39 c2             	cmp    %rax,%rdx
  800420290e:	73 17                	jae    8004202927 <sprintputch+0x4b>
		*b->buf++ = ch;
  8004202910:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202914:	48 8b 00             	mov    (%rax),%rax
  8004202917:	48 8d 48 01          	lea    0x1(%rax),%rcx
  800420291b:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800420291f:	48 89 0a             	mov    %rcx,(%rdx)
  8004202922:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004202925:	88 10                	mov    %dl,(%rax)
}
  8004202927:	90                   	nop
  8004202928:	c9                   	leaveq 
  8004202929:	c3                   	retq   

000000800420292a <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800420292a:	55                   	push   %rbp
  800420292b:	48 89 e5             	mov    %rsp,%rbp
  800420292e:	48 83 ec 50          	sub    $0x50,%rsp
  8004202932:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004202936:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  8004202939:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  800420293d:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
	va_list aq;
	va_copy(aq,ap);
  8004202941:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  8004202945:	48 8b 75 b0          	mov    -0x50(%rbp),%rsi
  8004202949:	48 8b 06             	mov    (%rsi),%rax
  800420294c:	48 8b 56 08          	mov    0x8(%rsi),%rdx
  8004202950:	48 89 01             	mov    %rax,(%rcx)
  8004202953:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  8004202957:	48 8b 46 10          	mov    0x10(%rsi),%rax
  800420295b:	48 89 41 10          	mov    %rax,0x10(%rcx)
	struct sprintbuf b = {buf, buf+n-1, 0};
  800420295f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004202963:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  8004202967:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  800420296a:	48 98                	cltq   
  800420296c:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  8004202970:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004202974:	48 01 d0             	add    %rdx,%rax
  8004202977:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  800420297b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)

	if (buf == NULL || n < 1)
  8004202982:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004202987:	74 06                	je     800420298f <vsnprintf+0x65>
  8004202989:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  800420298d:	7f 07                	jg     8004202996 <vsnprintf+0x6c>
		return -E_INVAL;
  800420298f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8004202994:	eb 2f                	jmp    80042029c5 <vsnprintf+0x9b>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, aq);
  8004202996:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  800420299a:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  800420299e:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  80042029a2:	48 89 c6             	mov    %rax,%rsi
  80042029a5:	48 bf dc 28 20 04 80 	movabs $0x80042028dc,%rdi
  80042029ac:	00 00 00 
  80042029af:	48 b8 0f 23 20 04 80 	movabs $0x800420230f,%rax
  80042029b6:	00 00 00 
  80042029b9:	ff d0                	callq  *%rax
	va_end(aq);
	// null terminate the buffer
	*b.buf = '\0';
  80042029bb:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042029bf:	c6 00 00             	movb   $0x0,(%rax)

	return b.cnt;
  80042029c2:	8b 45 e0             	mov    -0x20(%rbp),%eax
}
  80042029c5:	c9                   	leaveq 
  80042029c6:	c3                   	retq   

00000080042029c7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80042029c7:	55                   	push   %rbp
  80042029c8:	48 89 e5             	mov    %rsp,%rbp
  80042029cb:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  80042029d2:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  80042029d9:	89 b5 04 ff ff ff    	mov    %esi,-0xfc(%rbp)
  80042029df:	48 89 95 f8 fe ff ff 	mov    %rdx,-0x108(%rbp)
  80042029e6:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80042029ed:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80042029f4:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80042029fb:	84 c0                	test   %al,%al
  80042029fd:	74 20                	je     8004202a1f <snprintf+0x58>
  80042029ff:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8004202a03:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8004202a07:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8004202a0b:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004202a0f:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8004202a13:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8004202a17:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8004202a1b:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
	va_list ap;
	int rc;
	va_list aq;
	va_start(ap, fmt);
  8004202a1f:	c7 85 30 ff ff ff 18 	movl   $0x18,-0xd0(%rbp)
  8004202a26:	00 00 00 
  8004202a29:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  8004202a30:	00 00 00 
  8004202a33:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004202a37:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  8004202a3e:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8004202a45:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
	va_copy(aq,ap);
  8004202a4c:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  8004202a53:	48 8d b5 30 ff ff ff 	lea    -0xd0(%rbp),%rsi
  8004202a5a:	48 8b 06             	mov    (%rsi),%rax
  8004202a5d:	48 8b 56 08          	mov    0x8(%rsi),%rdx
  8004202a61:	48 89 01             	mov    %rax,(%rcx)
  8004202a64:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  8004202a68:	48 8b 46 10          	mov    0x10(%rsi),%rax
  8004202a6c:	48 89 41 10          	mov    %rax,0x10(%rcx)
	rc = vsnprintf(buf, n, fmt, aq);
  8004202a70:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  8004202a77:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  8004202a7e:	8b b5 04 ff ff ff    	mov    -0xfc(%rbp),%esi
  8004202a84:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8004202a8b:	48 89 c7             	mov    %rax,%rdi
  8004202a8e:	48 b8 2a 29 20 04 80 	movabs $0x800420292a,%rax
  8004202a95:	00 00 00 
  8004202a98:	ff d0                	callq  *%rax
  8004202a9a:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
	va_end(aq);

	return rc;
  8004202aa0:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
}
  8004202aa6:	c9                   	leaveq 
  8004202aa7:	c3                   	retq   

0000008004202aa8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
  8004202aa8:	55                   	push   %rbp
  8004202aa9:	48 89 e5             	mov    %rsp,%rbp
  8004202aac:	48 83 ec 20          	sub    $0x20,%rsp
  8004202ab0:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	int i, c, echoing;

	if (prompt != NULL)
  8004202ab4:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202ab9:	74 22                	je     8004202add <readline+0x35>
		cprintf("%s", prompt);
  8004202abb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202abf:	48 89 c6             	mov    %rax,%rsi
  8004202ac2:	48 bf e8 9c 20 04 80 	movabs $0x8004209ce8,%rdi
  8004202ac9:	00 00 00 
  8004202acc:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202ad1:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004202ad8:	00 00 00 
  8004202adb:	ff d2                	callq  *%rdx

	i = 0;
  8004202add:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	echoing = iscons(0);
  8004202ae4:	bf 00 00 00 00       	mov    $0x0,%edi
  8004202ae9:	48 b8 ab 0e 20 04 80 	movabs $0x8004200eab,%rax
  8004202af0:	00 00 00 
  8004202af3:	ff d0                	callq  *%rax
  8004202af5:	89 45 f8             	mov    %eax,-0x8(%rbp)
	while (1) {
		c = getchar();
  8004202af8:	48 b8 89 0e 20 04 80 	movabs $0x8004200e89,%rax
  8004202aff:	00 00 00 
  8004202b02:	ff d0                	callq  *%rax
  8004202b04:	89 45 f4             	mov    %eax,-0xc(%rbp)
		if (c < 0) {
  8004202b07:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8004202b0b:	79 2a                	jns    8004202b37 <readline+0x8f>
			cprintf("read error: %e\n", c);
  8004202b0d:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202b10:	89 c6                	mov    %eax,%esi
  8004202b12:	48 bf eb 9c 20 04 80 	movabs $0x8004209ceb,%rdi
  8004202b19:	00 00 00 
  8004202b1c:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202b21:	48 ba 29 14 20 04 80 	movabs $0x8004201429,%rdx
  8004202b28:	00 00 00 
  8004202b2b:	ff d2                	callq  *%rdx
			return NULL;
  8004202b2d:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202b32:	e9 c2 00 00 00       	jmpq   8004202bf9 <readline+0x151>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
  8004202b37:	83 7d f4 08          	cmpl   $0x8,-0xc(%rbp)
  8004202b3b:	74 06                	je     8004202b43 <readline+0x9b>
  8004202b3d:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%rbp)
  8004202b41:	75 26                	jne    8004202b69 <readline+0xc1>
  8004202b43:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004202b47:	7e 20                	jle    8004202b69 <readline+0xc1>
			if (echoing)
  8004202b49:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004202b4d:	74 11                	je     8004202b60 <readline+0xb8>
				cputchar('\b');
  8004202b4f:	bf 08 00 00 00       	mov    $0x8,%edi
  8004202b54:	48 b8 6a 0e 20 04 80 	movabs $0x8004200e6a,%rax
  8004202b5b:	00 00 00 
  8004202b5e:	ff d0                	callq  *%rax
			i--;
  8004202b60:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
  8004202b64:	e9 8b 00 00 00       	jmpq   8004202bf4 <readline+0x14c>
		} else if (c >= ' ' && i < BUFLEN-1) {
  8004202b69:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%rbp)
  8004202b6d:	7e 3f                	jle    8004202bae <readline+0x106>
  8004202b6f:	81 7d fc fe 03 00 00 	cmpl   $0x3fe,-0x4(%rbp)
  8004202b76:	7f 36                	jg     8004202bae <readline+0x106>
			if (echoing)
  8004202b78:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004202b7c:	74 11                	je     8004202b8f <readline+0xe7>
				cputchar(c);
  8004202b7e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202b81:	89 c7                	mov    %eax,%edi
  8004202b83:	48 b8 6a 0e 20 04 80 	movabs $0x8004200e6a,%rax
  8004202b8a:	00 00 00 
  8004202b8d:	ff d0                	callq  *%rax
			buf[i++] = c;
  8004202b8f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004202b92:	8d 50 01             	lea    0x1(%rax),%edx
  8004202b95:	89 55 fc             	mov    %edx,-0x4(%rbp)
  8004202b98:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004202b9b:	89 d1                	mov    %edx,%ecx
  8004202b9d:	48 ba e0 b8 21 04 80 	movabs $0x800421b8e0,%rdx
  8004202ba4:	00 00 00 
  8004202ba7:	48 98                	cltq   
  8004202ba9:	88 0c 02             	mov    %cl,(%rdx,%rax,1)
  8004202bac:	eb 46                	jmp    8004202bf4 <readline+0x14c>
		} else if (c == '\n' || c == '\r') {
  8004202bae:	83 7d f4 0a          	cmpl   $0xa,-0xc(%rbp)
  8004202bb2:	74 0a                	je     8004202bbe <readline+0x116>
  8004202bb4:	83 7d f4 0d          	cmpl   $0xd,-0xc(%rbp)
  8004202bb8:	0f 85 3a ff ff ff    	jne    8004202af8 <readline+0x50>
			if (echoing)
  8004202bbe:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004202bc2:	74 11                	je     8004202bd5 <readline+0x12d>
				cputchar('\n');
  8004202bc4:	bf 0a 00 00 00       	mov    $0xa,%edi
  8004202bc9:	48 b8 6a 0e 20 04 80 	movabs $0x8004200e6a,%rax
  8004202bd0:	00 00 00 
  8004202bd3:	ff d0                	callq  *%rax
			buf[i] = 0;
  8004202bd5:	48 ba e0 b8 21 04 80 	movabs $0x800421b8e0,%rdx
  8004202bdc:	00 00 00 
  8004202bdf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004202be2:	48 98                	cltq   
  8004202be4:	c6 04 02 00          	movb   $0x0,(%rdx,%rax,1)
			return buf;
  8004202be8:	48 b8 e0 b8 21 04 80 	movabs $0x800421b8e0,%rax
  8004202bef:	00 00 00 
  8004202bf2:	eb 05                	jmp    8004202bf9 <readline+0x151>
		c = getchar();
  8004202bf4:	e9 ff fe ff ff       	jmpq   8004202af8 <readline+0x50>
		}
	}
}
  8004202bf9:	c9                   	leaveq 
  8004202bfa:	c3                   	retq   

0000008004202bfb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8004202bfb:	55                   	push   %rbp
  8004202bfc:	48 89 e5             	mov    %rsp,%rbp
  8004202bff:	48 83 ec 18          	sub    $0x18,%rsp
  8004202c03:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	int n;

	for (n = 0; *s != '\0'; s++)
  8004202c07:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004202c0e:	eb 09                	jmp    8004202c19 <strlen+0x1e>
		n++;
  8004202c10:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
	for (n = 0; *s != '\0'; s++)
  8004202c14:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004202c19:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c1d:	0f b6 00             	movzbl (%rax),%eax
  8004202c20:	84 c0                	test   %al,%al
  8004202c22:	75 ec                	jne    8004202c10 <strlen+0x15>
	return n;
  8004202c24:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004202c27:	c9                   	leaveq 
  8004202c28:	c3                   	retq   

0000008004202c29 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8004202c29:	55                   	push   %rbp
  8004202c2a:	48 89 e5             	mov    %rsp,%rbp
  8004202c2d:	48 83 ec 20          	sub    $0x20,%rsp
  8004202c31:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202c35:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8004202c39:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004202c40:	eb 0e                	jmp    8004202c50 <strnlen+0x27>
		n++;
  8004202c42:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8004202c46:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004202c4b:	48 83 6d e0 01       	subq   $0x1,-0x20(%rbp)
  8004202c50:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004202c55:	74 0b                	je     8004202c62 <strnlen+0x39>
  8004202c57:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c5b:	0f b6 00             	movzbl (%rax),%eax
  8004202c5e:	84 c0                	test   %al,%al
  8004202c60:	75 e0                	jne    8004202c42 <strnlen+0x19>
	return n;
  8004202c62:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004202c65:	c9                   	leaveq 
  8004202c66:	c3                   	retq   

0000008004202c67 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8004202c67:	55                   	push   %rbp
  8004202c68:	48 89 e5             	mov    %rsp,%rbp
  8004202c6b:	48 83 ec 20          	sub    $0x20,%rsp
  8004202c6f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202c73:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	char *ret;

	ret = dst;
  8004202c77:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c7b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	while ((*dst++ = *src++) != '\0')
  8004202c7f:	90                   	nop
  8004202c80:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004202c84:	48 8d 42 01          	lea    0x1(%rdx),%rax
  8004202c88:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8004202c8c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c90:	48 8d 48 01          	lea    0x1(%rax),%rcx
  8004202c94:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  8004202c98:	0f b6 12             	movzbl (%rdx),%edx
  8004202c9b:	88 10                	mov    %dl,(%rax)
  8004202c9d:	0f b6 00             	movzbl (%rax),%eax
  8004202ca0:	84 c0                	test   %al,%al
  8004202ca2:	75 dc                	jne    8004202c80 <strcpy+0x19>
		/* do nothing */;
	return ret;
  8004202ca4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202ca8:	c9                   	leaveq 
  8004202ca9:	c3                   	retq   

0000008004202caa <strcat>:

char *
strcat(char *dst, const char *src)
{
  8004202caa:	55                   	push   %rbp
  8004202cab:	48 89 e5             	mov    %rsp,%rbp
  8004202cae:	48 83 ec 20          	sub    $0x20,%rsp
  8004202cb2:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202cb6:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	int len = strlen(dst);
  8004202cba:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202cbe:	48 89 c7             	mov    %rax,%rdi
  8004202cc1:	48 b8 fb 2b 20 04 80 	movabs $0x8004202bfb,%rax
  8004202cc8:	00 00 00 
  8004202ccb:	ff d0                	callq  *%rax
  8004202ccd:	89 45 fc             	mov    %eax,-0x4(%rbp)
	strcpy(dst + len, src);
  8004202cd0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004202cd3:	48 63 d0             	movslq %eax,%rdx
  8004202cd6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202cda:	48 01 c2             	add    %rax,%rdx
  8004202cdd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202ce1:	48 89 c6             	mov    %rax,%rsi
  8004202ce4:	48 89 d7             	mov    %rdx,%rdi
  8004202ce7:	48 b8 67 2c 20 04 80 	movabs $0x8004202c67,%rax
  8004202cee:	00 00 00 
  8004202cf1:	ff d0                	callq  *%rax
	return dst;
  8004202cf3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
  8004202cf7:	c9                   	leaveq 
  8004202cf8:	c3                   	retq   

0000008004202cf9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8004202cf9:	55                   	push   %rbp
  8004202cfa:	48 89 e5             	mov    %rsp,%rbp
  8004202cfd:	48 83 ec 28          	sub    $0x28,%rsp
  8004202d01:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202d05:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004202d09:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	size_t i;
	char *ret;

	ret = dst;
  8004202d0d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202d11:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	for (i = 0; i < size; i++) {
  8004202d15:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004202d1c:	00 
  8004202d1d:	eb 2a                	jmp    8004202d49 <strncpy+0x50>
		*dst++ = *src;
  8004202d1f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202d23:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004202d27:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8004202d2b:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004202d2f:	0f b6 12             	movzbl (%rdx),%edx
  8004202d32:	88 10                	mov    %dl,(%rax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  8004202d34:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202d38:	0f b6 00             	movzbl (%rax),%eax
  8004202d3b:	84 c0                	test   %al,%al
  8004202d3d:	74 05                	je     8004202d44 <strncpy+0x4b>
			src++;
  8004202d3f:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
	for (i = 0; i < size; i++) {
  8004202d44:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202d49:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202d4d:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8004202d51:	72 cc                	jb     8004202d1f <strncpy+0x26>
	}
	return ret;
  8004202d53:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004202d57:	c9                   	leaveq 
  8004202d58:	c3                   	retq   

0000008004202d59 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8004202d59:	55                   	push   %rbp
  8004202d5a:	48 89 e5             	mov    %rsp,%rbp
  8004202d5d:	48 83 ec 28          	sub    $0x28,%rsp
  8004202d61:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202d65:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004202d69:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	char *dst_in;

	dst_in = dst;
  8004202d6d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202d71:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (size > 0) {
  8004202d75:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004202d7a:	74 3d                	je     8004202db9 <strlcpy+0x60>
		while (--size > 0 && *src != '\0')
  8004202d7c:	eb 1d                	jmp    8004202d9b <strlcpy+0x42>
			*dst++ = *src++;
  8004202d7e:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004202d82:	48 8d 42 01          	lea    0x1(%rdx),%rax
  8004202d86:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8004202d8a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202d8e:	48 8d 48 01          	lea    0x1(%rax),%rcx
  8004202d92:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  8004202d96:	0f b6 12             	movzbl (%rdx),%edx
  8004202d99:	88 10                	mov    %dl,(%rax)
		while (--size > 0 && *src != '\0')
  8004202d9b:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  8004202da0:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004202da5:	74 0b                	je     8004202db2 <strlcpy+0x59>
  8004202da7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202dab:	0f b6 00             	movzbl (%rax),%eax
  8004202dae:	84 c0                	test   %al,%al
  8004202db0:	75 cc                	jne    8004202d7e <strlcpy+0x25>
		*dst = '\0';
  8004202db2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202db6:	c6 00 00             	movb   $0x0,(%rax)
	}
	return dst - dst_in;
  8004202db9:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202dbd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202dc1:	48 29 c2             	sub    %rax,%rdx
  8004202dc4:	48 89 d0             	mov    %rdx,%rax
}
  8004202dc7:	c9                   	leaveq 
  8004202dc8:	c3                   	retq   

0000008004202dc9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8004202dc9:	55                   	push   %rbp
  8004202dca:	48 89 e5             	mov    %rsp,%rbp
  8004202dcd:	48 83 ec 10          	sub    $0x10,%rsp
  8004202dd1:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202dd5:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	while (*p && *p == *q)
  8004202dd9:	eb 0a                	jmp    8004202de5 <strcmp+0x1c>
		p++, q++;
  8004202ddb:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202de0:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
	while (*p && *p == *q)
  8004202de5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202de9:	0f b6 00             	movzbl (%rax),%eax
  8004202dec:	84 c0                	test   %al,%al
  8004202dee:	74 12                	je     8004202e02 <strcmp+0x39>
  8004202df0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202df4:	0f b6 10             	movzbl (%rax),%edx
  8004202df7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202dfb:	0f b6 00             	movzbl (%rax),%eax
  8004202dfe:	38 c2                	cmp    %al,%dl
  8004202e00:	74 d9                	je     8004202ddb <strcmp+0x12>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8004202e02:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e06:	0f b6 00             	movzbl (%rax),%eax
  8004202e09:	0f b6 d0             	movzbl %al,%edx
  8004202e0c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202e10:	0f b6 00             	movzbl (%rax),%eax
  8004202e13:	0f b6 c0             	movzbl %al,%eax
  8004202e16:	29 c2                	sub    %eax,%edx
  8004202e18:	89 d0                	mov    %edx,%eax
}
  8004202e1a:	c9                   	leaveq 
  8004202e1b:	c3                   	retq   

0000008004202e1c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8004202e1c:	55                   	push   %rbp
  8004202e1d:	48 89 e5             	mov    %rsp,%rbp
  8004202e20:	48 83 ec 18          	sub    $0x18,%rsp
  8004202e24:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202e28:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8004202e2c:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	while (n > 0 && *p && *p == *q)
  8004202e30:	eb 0f                	jmp    8004202e41 <strncmp+0x25>
		n--, p++, q++;
  8004202e32:	48 83 6d e8 01       	subq   $0x1,-0x18(%rbp)
  8004202e37:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202e3c:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
	while (n > 0 && *p && *p == *q)
  8004202e41:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202e46:	74 1d                	je     8004202e65 <strncmp+0x49>
  8004202e48:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e4c:	0f b6 00             	movzbl (%rax),%eax
  8004202e4f:	84 c0                	test   %al,%al
  8004202e51:	74 12                	je     8004202e65 <strncmp+0x49>
  8004202e53:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e57:	0f b6 10             	movzbl (%rax),%edx
  8004202e5a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202e5e:	0f b6 00             	movzbl (%rax),%eax
  8004202e61:	38 c2                	cmp    %al,%dl
  8004202e63:	74 cd                	je     8004202e32 <strncmp+0x16>
	if (n == 0)
  8004202e65:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202e6a:	75 07                	jne    8004202e73 <strncmp+0x57>
		return 0;
  8004202e6c:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202e71:	eb 18                	jmp    8004202e8b <strncmp+0x6f>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8004202e73:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e77:	0f b6 00             	movzbl (%rax),%eax
  8004202e7a:	0f b6 d0             	movzbl %al,%edx
  8004202e7d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202e81:	0f b6 00             	movzbl (%rax),%eax
  8004202e84:	0f b6 c0             	movzbl %al,%eax
  8004202e87:	29 c2                	sub    %eax,%edx
  8004202e89:	89 d0                	mov    %edx,%eax
}
  8004202e8b:	c9                   	leaveq 
  8004202e8c:	c3                   	retq   

0000008004202e8d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8004202e8d:	55                   	push   %rbp
  8004202e8e:	48 89 e5             	mov    %rsp,%rbp
  8004202e91:	48 83 ec 10          	sub    $0x10,%rsp
  8004202e95:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202e99:	89 f0                	mov    %esi,%eax
  8004202e9b:	88 45 f4             	mov    %al,-0xc(%rbp)
	for (; *s; s++)
  8004202e9e:	eb 17                	jmp    8004202eb7 <strchr+0x2a>
		if (*s == c)
  8004202ea0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202ea4:	0f b6 00             	movzbl (%rax),%eax
  8004202ea7:	38 45 f4             	cmp    %al,-0xc(%rbp)
  8004202eaa:	75 06                	jne    8004202eb2 <strchr+0x25>
			return (char *) s;
  8004202eac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202eb0:	eb 15                	jmp    8004202ec7 <strchr+0x3a>
	for (; *s; s++)
  8004202eb2:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202eb7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202ebb:	0f b6 00             	movzbl (%rax),%eax
  8004202ebe:	84 c0                	test   %al,%al
  8004202ec0:	75 de                	jne    8004202ea0 <strchr+0x13>
	return 0;
  8004202ec2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004202ec7:	c9                   	leaveq 
  8004202ec8:	c3                   	retq   

0000008004202ec9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8004202ec9:	55                   	push   %rbp
  8004202eca:	48 89 e5             	mov    %rsp,%rbp
  8004202ecd:	48 83 ec 10          	sub    $0x10,%rsp
  8004202ed1:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202ed5:	89 f0                	mov    %esi,%eax
  8004202ed7:	88 45 f4             	mov    %al,-0xc(%rbp)
	for (; *s; s++)
  8004202eda:	eb 11                	jmp    8004202eed <strfind+0x24>
		if (*s == c)
  8004202edc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202ee0:	0f b6 00             	movzbl (%rax),%eax
  8004202ee3:	38 45 f4             	cmp    %al,-0xc(%rbp)
  8004202ee6:	74 12                	je     8004202efa <strfind+0x31>
	for (; *s; s++)
  8004202ee8:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202eed:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202ef1:	0f b6 00             	movzbl (%rax),%eax
  8004202ef4:	84 c0                	test   %al,%al
  8004202ef6:	75 e4                	jne    8004202edc <strfind+0x13>
  8004202ef8:	eb 01                	jmp    8004202efb <strfind+0x32>
			break;
  8004202efa:	90                   	nop
	return (char *) s;
  8004202efb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202eff:	c9                   	leaveq 
  8004202f00:	c3                   	retq   

0000008004202f01 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8004202f01:	55                   	push   %rbp
  8004202f02:	48 89 e5             	mov    %rsp,%rbp
  8004202f05:	48 83 ec 18          	sub    $0x18,%rsp
  8004202f09:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202f0d:	89 75 f4             	mov    %esi,-0xc(%rbp)
  8004202f10:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	char *p;

	if (n == 0)
  8004202f14:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202f19:	75 06                	jne    8004202f21 <memset+0x20>
		return v;
  8004202f1b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202f1f:	eb 69                	jmp    8004202f8a <memset+0x89>
	if ((int64_t)v%4 == 0 && n%4 == 0) {
  8004202f21:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202f25:	83 e0 03             	and    $0x3,%eax
  8004202f28:	48 85 c0             	test   %rax,%rax
  8004202f2b:	75 48                	jne    8004202f75 <memset+0x74>
  8004202f2d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202f31:	83 e0 03             	and    $0x3,%eax
  8004202f34:	48 85 c0             	test   %rax,%rax
  8004202f37:	75 3c                	jne    8004202f75 <memset+0x74>
		c &= 0xFF;
  8004202f39:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8004202f40:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202f43:	c1 e0 18             	shl    $0x18,%eax
  8004202f46:	89 c2                	mov    %eax,%edx
  8004202f48:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202f4b:	c1 e0 10             	shl    $0x10,%eax
  8004202f4e:	09 c2                	or     %eax,%edx
  8004202f50:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202f53:	c1 e0 08             	shl    $0x8,%eax
  8004202f56:	09 d0                	or     %edx,%eax
  8004202f58:	09 45 f4             	or     %eax,-0xc(%rbp)
		asm volatile("cld; rep stosl\n"
			     :: "D" (v), "a" (c), "c" (n/4)
  8004202f5b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202f5f:	48 c1 e8 02          	shr    $0x2,%rax
  8004202f63:	48 89 c1             	mov    %rax,%rcx
		asm volatile("cld; rep stosl\n"
  8004202f66:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202f6a:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202f6d:	48 89 d7             	mov    %rdx,%rdi
  8004202f70:	fc                   	cld    
  8004202f71:	f3 ab                	rep stos %eax,%es:(%rdi)
  8004202f73:	eb 11                	jmp    8004202f86 <memset+0x85>
			     : "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8004202f75:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202f79:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202f7c:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004202f80:	48 89 d7             	mov    %rdx,%rdi
  8004202f83:	fc                   	cld    
  8004202f84:	f3 aa                	rep stos %al,%es:(%rdi)
			     :: "D" (v), "a" (c), "c" (n)
			     : "cc", "memory");
	return v;
  8004202f86:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202f8a:	c9                   	leaveq 
  8004202f8b:	c3                   	retq   

0000008004202f8c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8004202f8c:	55                   	push   %rbp
  8004202f8d:	48 89 e5             	mov    %rsp,%rbp
  8004202f90:	48 83 ec 28          	sub    $0x28,%rsp
  8004202f94:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202f98:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004202f9c:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	const char *s;
	char *d;

	s = src;
  8004202fa0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202fa4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	d = dst;
  8004202fa8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202fac:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	if (s < d && s + n > d) {
  8004202fb0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202fb4:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8004202fb8:	0f 83 88 00 00 00    	jae    8004203046 <memmove+0xba>
  8004202fbe:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202fc2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202fc6:	48 01 d0             	add    %rdx,%rax
  8004202fc9:	48 39 45 f0          	cmp    %rax,-0x10(%rbp)
  8004202fcd:	73 77                	jae    8004203046 <memmove+0xba>
		s += n;
  8004202fcf:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202fd3:	48 01 45 f8          	add    %rax,-0x8(%rbp)
		d += n;
  8004202fd7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202fdb:	48 01 45 f0          	add    %rax,-0x10(%rbp)
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
  8004202fdf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202fe3:	83 e0 03             	and    $0x3,%eax
  8004202fe6:	48 85 c0             	test   %rax,%rax
  8004202fe9:	75 3b                	jne    8004203026 <memmove+0x9a>
  8004202feb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202fef:	83 e0 03             	and    $0x3,%eax
  8004202ff2:	48 85 c0             	test   %rax,%rax
  8004202ff5:	75 2f                	jne    8004203026 <memmove+0x9a>
  8004202ff7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202ffb:	83 e0 03             	and    $0x3,%eax
  8004202ffe:	48 85 c0             	test   %rax,%rax
  8004203001:	75 23                	jne    8004203026 <memmove+0x9a>
			asm volatile("std; rep movsl\n"
				     :: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8004203003:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203007:	48 83 e8 04          	sub    $0x4,%rax
  800420300b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420300f:	48 83 ea 04          	sub    $0x4,%rdx
  8004203013:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004203017:	48 c1 e9 02          	shr    $0x2,%rcx
			asm volatile("std; rep movsl\n"
  800420301b:	48 89 c7             	mov    %rax,%rdi
  800420301e:	48 89 d6             	mov    %rdx,%rsi
  8004203021:	fd                   	std    
  8004203022:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  8004203024:	eb 1d                	jmp    8004203043 <memmove+0xb7>
		else
			asm volatile("std; rep movsb\n"
				     :: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  8004203026:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420302a:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  800420302e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203032:	48 8d 70 ff          	lea    -0x1(%rax),%rsi
			asm volatile("std; rep movsb\n"
  8004203036:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420303a:	48 89 d7             	mov    %rdx,%rdi
  800420303d:	48 89 c1             	mov    %rax,%rcx
  8004203040:	fd                   	std    
  8004203041:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8004203043:	fc                   	cld    
  8004203044:	eb 57                	jmp    800420309d <memmove+0x111>
	} else {
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
  8004203046:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420304a:	83 e0 03             	and    $0x3,%eax
  800420304d:	48 85 c0             	test   %rax,%rax
  8004203050:	75 36                	jne    8004203088 <memmove+0xfc>
  8004203052:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203056:	83 e0 03             	and    $0x3,%eax
  8004203059:	48 85 c0             	test   %rax,%rax
  800420305c:	75 2a                	jne    8004203088 <memmove+0xfc>
  800420305e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203062:	83 e0 03             	and    $0x3,%eax
  8004203065:	48 85 c0             	test   %rax,%rax
  8004203068:	75 1e                	jne    8004203088 <memmove+0xfc>
			asm volatile("cld; rep movsl\n"
				     :: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800420306a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420306e:	48 c1 e8 02          	shr    $0x2,%rax
  8004203072:	48 89 c1             	mov    %rax,%rcx
			asm volatile("cld; rep movsl\n"
  8004203075:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203079:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420307d:	48 89 c7             	mov    %rax,%rdi
  8004203080:	48 89 d6             	mov    %rdx,%rsi
  8004203083:	fc                   	cld    
  8004203084:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  8004203086:	eb 15                	jmp    800420309d <memmove+0x111>
		else
			asm volatile("cld; rep movsb\n"
  8004203088:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420308c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004203090:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004203094:	48 89 c7             	mov    %rax,%rdi
  8004203097:	48 89 d6             	mov    %rdx,%rsi
  800420309a:	fc                   	cld    
  800420309b:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
				     :: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  800420309d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
  80042030a1:	c9                   	leaveq 
  80042030a2:	c3                   	retq   

00000080042030a3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80042030a3:	55                   	push   %rbp
  80042030a4:	48 89 e5             	mov    %rsp,%rbp
  80042030a7:	48 83 ec 18          	sub    $0x18,%rsp
  80042030ab:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80042030af:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80042030b3:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	return memmove(dst, src, n);
  80042030b7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042030bb:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  80042030bf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042030c3:	48 89 ce             	mov    %rcx,%rsi
  80042030c6:	48 89 c7             	mov    %rax,%rdi
  80042030c9:	48 b8 8c 2f 20 04 80 	movabs $0x8004202f8c,%rax
  80042030d0:	00 00 00 
  80042030d3:	ff d0                	callq  *%rax
}
  80042030d5:	c9                   	leaveq 
  80042030d6:	c3                   	retq   

00000080042030d7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80042030d7:	55                   	push   %rbp
  80042030d8:	48 89 e5             	mov    %rsp,%rbp
  80042030db:	48 83 ec 28          	sub    $0x28,%rsp
  80042030df:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042030e3:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80042030e7:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	const uint8_t *s1 = (const uint8_t *) v1;
  80042030eb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042030ef:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	const uint8_t *s2 = (const uint8_t *) v2;
  80042030f3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042030f7:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	while (n-- > 0) {
  80042030fb:	eb 36                	jmp    8004203133 <memcmp+0x5c>
		if (*s1 != *s2)
  80042030fd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203101:	0f b6 10             	movzbl (%rax),%edx
  8004203104:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203108:	0f b6 00             	movzbl (%rax),%eax
  800420310b:	38 c2                	cmp    %al,%dl
  800420310d:	74 1a                	je     8004203129 <memcmp+0x52>
			return (int) *s1 - (int) *s2;
  800420310f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203113:	0f b6 00             	movzbl (%rax),%eax
  8004203116:	0f b6 d0             	movzbl %al,%edx
  8004203119:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420311d:	0f b6 00             	movzbl (%rax),%eax
  8004203120:	0f b6 c0             	movzbl %al,%eax
  8004203123:	29 c2                	sub    %eax,%edx
  8004203125:	89 d0                	mov    %edx,%eax
  8004203127:	eb 20                	jmp    8004203149 <memcmp+0x72>
		s1++, s2++;
  8004203129:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  800420312e:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
	while (n-- > 0) {
  8004203133:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203137:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  800420313b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  800420313f:	48 85 c0             	test   %rax,%rax
  8004203142:	75 b9                	jne    80042030fd <memcmp+0x26>
	}

	return 0;
  8004203144:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004203149:	c9                   	leaveq 
  800420314a:	c3                   	retq   

000000800420314b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800420314b:	55                   	push   %rbp
  800420314c:	48 89 e5             	mov    %rsp,%rbp
  800420314f:	48 83 ec 28          	sub    $0x28,%rsp
  8004203153:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203157:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800420315a:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	const void *ends = (const char *) s + n;
  800420315e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203162:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203166:	48 01 d0             	add    %rdx,%rax
  8004203169:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	for (; s < ends; s++)
  800420316d:	eb 13                	jmp    8004203182 <memfind+0x37>
		if (*(const unsigned char *) s == (unsigned char) c)
  800420316f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203173:	0f b6 00             	movzbl (%rax),%eax
  8004203176:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004203179:	38 d0                	cmp    %dl,%al
  800420317b:	74 11                	je     800420318e <memfind+0x43>
	for (; s < ends; s++)
  800420317d:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004203182:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203186:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  800420318a:	72 e3                	jb     800420316f <memfind+0x24>
  800420318c:	eb 01                	jmp    800420318f <memfind+0x44>
			break;
  800420318e:	90                   	nop
	return (void *) s;
  800420318f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
  8004203193:	c9                   	leaveq 
  8004203194:	c3                   	retq   

0000008004203195 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8004203195:	55                   	push   %rbp
  8004203196:	48 89 e5             	mov    %rsp,%rbp
  8004203199:	48 83 ec 38          	sub    $0x38,%rsp
  800420319d:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80042031a1:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  80042031a5:	89 55 cc             	mov    %edx,-0x34(%rbp)
	int neg = 0;
  80042031a8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	long val = 0;
  80042031af:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  80042031b6:	00 

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80042031b7:	eb 05                	jmp    80042031be <strtol+0x29>
		s++;
  80042031b9:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
	while (*s == ' ' || *s == '\t')
  80042031be:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031c2:	0f b6 00             	movzbl (%rax),%eax
  80042031c5:	3c 20                	cmp    $0x20,%al
  80042031c7:	74 f0                	je     80042031b9 <strtol+0x24>
  80042031c9:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031cd:	0f b6 00             	movzbl (%rax),%eax
  80042031d0:	3c 09                	cmp    $0x9,%al
  80042031d2:	74 e5                	je     80042031b9 <strtol+0x24>

	// plus/minus sign
	if (*s == '+')
  80042031d4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031d8:	0f b6 00             	movzbl (%rax),%eax
  80042031db:	3c 2b                	cmp    $0x2b,%al
  80042031dd:	75 07                	jne    80042031e6 <strtol+0x51>
		s++;
  80042031df:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  80042031e4:	eb 17                	jmp    80042031fd <strtol+0x68>
	else if (*s == '-')
  80042031e6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031ea:	0f b6 00             	movzbl (%rax),%eax
  80042031ed:	3c 2d                	cmp    $0x2d,%al
  80042031ef:	75 0c                	jne    80042031fd <strtol+0x68>
		s++, neg = 1;
  80042031f1:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  80042031f6:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  80042031fd:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  8004203201:	74 06                	je     8004203209 <strtol+0x74>
  8004203203:	83 7d cc 10          	cmpl   $0x10,-0x34(%rbp)
  8004203207:	75 28                	jne    8004203231 <strtol+0x9c>
  8004203209:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420320d:	0f b6 00             	movzbl (%rax),%eax
  8004203210:	3c 30                	cmp    $0x30,%al
  8004203212:	75 1d                	jne    8004203231 <strtol+0x9c>
  8004203214:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203218:	48 83 c0 01          	add    $0x1,%rax
  800420321c:	0f b6 00             	movzbl (%rax),%eax
  800420321f:	3c 78                	cmp    $0x78,%al
  8004203221:	75 0e                	jne    8004203231 <strtol+0x9c>
		s += 2, base = 16;
  8004203223:	48 83 45 d8 02       	addq   $0x2,-0x28(%rbp)
  8004203228:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%rbp)
  800420322f:	eb 2c                	jmp    800420325d <strtol+0xc8>
	else if (base == 0 && s[0] == '0')
  8004203231:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  8004203235:	75 19                	jne    8004203250 <strtol+0xbb>
  8004203237:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420323b:	0f b6 00             	movzbl (%rax),%eax
  800420323e:	3c 30                	cmp    $0x30,%al
  8004203240:	75 0e                	jne    8004203250 <strtol+0xbb>
		s++, base = 8;
  8004203242:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8004203247:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%rbp)
  800420324e:	eb 0d                	jmp    800420325d <strtol+0xc8>
	else if (base == 0)
  8004203250:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  8004203254:	75 07                	jne    800420325d <strtol+0xc8>
		base = 10;
  8004203256:	c7 45 cc 0a 00 00 00 	movl   $0xa,-0x34(%rbp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800420325d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203261:	0f b6 00             	movzbl (%rax),%eax
  8004203264:	3c 2f                	cmp    $0x2f,%al
  8004203266:	7e 1d                	jle    8004203285 <strtol+0xf0>
  8004203268:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420326c:	0f b6 00             	movzbl (%rax),%eax
  800420326f:	3c 39                	cmp    $0x39,%al
  8004203271:	7f 12                	jg     8004203285 <strtol+0xf0>
			dig = *s - '0';
  8004203273:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203277:	0f b6 00             	movzbl (%rax),%eax
  800420327a:	0f be c0             	movsbl %al,%eax
  800420327d:	83 e8 30             	sub    $0x30,%eax
  8004203280:	89 45 ec             	mov    %eax,-0x14(%rbp)
  8004203283:	eb 4e                	jmp    80042032d3 <strtol+0x13e>
		else if (*s >= 'a' && *s <= 'z')
  8004203285:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203289:	0f b6 00             	movzbl (%rax),%eax
  800420328c:	3c 60                	cmp    $0x60,%al
  800420328e:	7e 1d                	jle    80042032ad <strtol+0x118>
  8004203290:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203294:	0f b6 00             	movzbl (%rax),%eax
  8004203297:	3c 7a                	cmp    $0x7a,%al
  8004203299:	7f 12                	jg     80042032ad <strtol+0x118>
			dig = *s - 'a' + 10;
  800420329b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420329f:	0f b6 00             	movzbl (%rax),%eax
  80042032a2:	0f be c0             	movsbl %al,%eax
  80042032a5:	83 e8 57             	sub    $0x57,%eax
  80042032a8:	89 45 ec             	mov    %eax,-0x14(%rbp)
  80042032ab:	eb 26                	jmp    80042032d3 <strtol+0x13e>
		else if (*s >= 'A' && *s <= 'Z')
  80042032ad:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042032b1:	0f b6 00             	movzbl (%rax),%eax
  80042032b4:	3c 40                	cmp    $0x40,%al
  80042032b6:	7e 47                	jle    80042032ff <strtol+0x16a>
  80042032b8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042032bc:	0f b6 00             	movzbl (%rax),%eax
  80042032bf:	3c 5a                	cmp    $0x5a,%al
  80042032c1:	7f 3c                	jg     80042032ff <strtol+0x16a>
			dig = *s - 'A' + 10;
  80042032c3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042032c7:	0f b6 00             	movzbl (%rax),%eax
  80042032ca:	0f be c0             	movsbl %al,%eax
  80042032cd:	83 e8 37             	sub    $0x37,%eax
  80042032d0:	89 45 ec             	mov    %eax,-0x14(%rbp)
		else
			break;
		if (dig >= base)
  80042032d3:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80042032d6:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  80042032d9:	7d 23                	jge    80042032fe <strtol+0x169>
			break;
		s++, val = (val * base) + dig;
  80042032db:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  80042032e0:	8b 45 cc             	mov    -0x34(%rbp),%eax
  80042032e3:	48 98                	cltq   
  80042032e5:	48 0f af 45 f0       	imul   -0x10(%rbp),%rax
  80042032ea:	48 89 c2             	mov    %rax,%rdx
  80042032ed:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80042032f0:	48 98                	cltq   
  80042032f2:	48 01 d0             	add    %rdx,%rax
  80042032f5:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	while (1) {
  80042032f9:	e9 5f ff ff ff       	jmpq   800420325d <strtol+0xc8>
			break;
  80042032fe:	90                   	nop
		// we don't properly detect overflow!
	}

	if (endptr)
  80042032ff:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  8004203304:	74 0b                	je     8004203311 <strtol+0x17c>
		*endptr = (char *) s;
  8004203306:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420330a:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  800420330e:	48 89 10             	mov    %rdx,(%rax)
	return (neg ? -val : val);
  8004203311:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004203315:	74 09                	je     8004203320 <strtol+0x18b>
  8004203317:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420331b:	48 f7 d8             	neg    %rax
  800420331e:	eb 04                	jmp    8004203324 <strtol+0x18f>
  8004203320:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203324:	c9                   	leaveq 
  8004203325:	c3                   	retq   

0000008004203326 <strstr>:

char * strstr(const char *in, const char *str)
{
  8004203326:	55                   	push   %rbp
  8004203327:	48 89 e5             	mov    %rsp,%rbp
  800420332a:	48 83 ec 30          	sub    $0x30,%rsp
  800420332e:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004203332:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
	char c;
	size_t len;

	c = *str++;
  8004203336:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420333a:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800420333e:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  8004203342:	0f b6 00             	movzbl (%rax),%eax
  8004203345:	88 45 ff             	mov    %al,-0x1(%rbp)
	if (!c)
  8004203348:	80 7d ff 00          	cmpb   $0x0,-0x1(%rbp)
  800420334c:	75 06                	jne    8004203354 <strstr+0x2e>
		return (char *) in;	// Trivial empty string case
  800420334e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203352:	eb 6b                	jmp    80042033bf <strstr+0x99>

	len = strlen(str);
  8004203354:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203358:	48 89 c7             	mov    %rax,%rdi
  800420335b:	48 b8 fb 2b 20 04 80 	movabs $0x8004202bfb,%rax
  8004203362:	00 00 00 
  8004203365:	ff d0                	callq  *%rax
  8004203367:	48 98                	cltq   
  8004203369:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	do {
		char sc;

		do {
			sc = *in++;
  800420336d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203371:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203375:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004203379:	0f b6 00             	movzbl (%rax),%eax
  800420337c:	88 45 ef             	mov    %al,-0x11(%rbp)
			if (!sc)
  800420337f:	80 7d ef 00          	cmpb   $0x0,-0x11(%rbp)
  8004203383:	75 07                	jne    800420338c <strstr+0x66>
				return (char *) 0;
  8004203385:	b8 00 00 00 00       	mov    $0x0,%eax
  800420338a:	eb 33                	jmp    80042033bf <strstr+0x99>
		} while (sc != c);
  800420338c:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  8004203390:	3a 45 ff             	cmp    -0x1(%rbp),%al
  8004203393:	75 d8                	jne    800420336d <strstr+0x47>
	} while (strncmp(in, str, len) != 0);
  8004203395:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203399:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  800420339d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042033a1:	48 89 ce             	mov    %rcx,%rsi
  80042033a4:	48 89 c7             	mov    %rax,%rdi
  80042033a7:	48 b8 1c 2e 20 04 80 	movabs $0x8004202e1c,%rax
  80042033ae:	00 00 00 
  80042033b1:	ff d0                	callq  *%rax
  80042033b3:	85 c0                	test   %eax,%eax
  80042033b5:	75 b6                	jne    800420336d <strstr+0x47>

	return (char *) (in - 1);
  80042033b7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042033bb:	48 83 e8 01          	sub    $0x1,%rax
}
  80042033bf:	c9                   	leaveq 
  80042033c0:	c3                   	retq   

00000080042033c1 <_dwarf_read_lsb>:
Dwarf_Section *
_dwarf_find_section(const char *name);

uint64_t
_dwarf_read_lsb(uint8_t *data, uint64_t *offsetp, int bytes_to_read)
{
  80042033c1:	55                   	push   %rbp
  80042033c2:	48 89 e5             	mov    %rsp,%rbp
  80042033c5:	48 83 ec 28          	sub    $0x28,%rsp
  80042033c9:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042033cd:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80042033d1:	89 55 dc             	mov    %edx,-0x24(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = data + *offsetp;
  80042033d4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042033d8:	48 8b 10             	mov    (%rax),%rdx
  80042033db:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042033df:	48 01 d0             	add    %rdx,%rax
  80042033e2:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	ret = 0;
  80042033e6:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  80042033ed:	00 
	switch (bytes_to_read) {
  80042033ee:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042033f1:	83 f8 02             	cmp    $0x2,%eax
  80042033f4:	0f 84 ab 00 00 00    	je     80042034a5 <_dwarf_read_lsb+0xe4>
  80042033fa:	83 f8 02             	cmp    $0x2,%eax
  80042033fd:	7f 0e                	jg     800420340d <_dwarf_read_lsb+0x4c>
  80042033ff:	83 f8 01             	cmp    $0x1,%eax
  8004203402:	0f 84 b3 00 00 00    	je     80042034bb <_dwarf_read_lsb+0xfa>
  8004203408:	e9 d9 00 00 00       	jmpq   80042034e6 <_dwarf_read_lsb+0x125>
  800420340d:	83 f8 04             	cmp    $0x4,%eax
  8004203410:	74 65                	je     8004203477 <_dwarf_read_lsb+0xb6>
  8004203412:	83 f8 08             	cmp    $0x8,%eax
  8004203415:	0f 85 cb 00 00 00    	jne    80042034e6 <_dwarf_read_lsb+0x125>
	case 8:
		ret |= ((uint64_t) src[4]) << 32 | ((uint64_t) src[5]) << 40;
  800420341b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420341f:	48 83 c0 04          	add    $0x4,%rax
  8004203423:	0f b6 00             	movzbl (%rax),%eax
  8004203426:	0f b6 c0             	movzbl %al,%eax
  8004203429:	48 c1 e0 20          	shl    $0x20,%rax
  800420342d:	48 89 c2             	mov    %rax,%rdx
  8004203430:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203434:	48 83 c0 05          	add    $0x5,%rax
  8004203438:	0f b6 00             	movzbl (%rax),%eax
  800420343b:	0f b6 c0             	movzbl %al,%eax
  800420343e:	48 c1 e0 28          	shl    $0x28,%rax
  8004203442:	48 09 d0             	or     %rdx,%rax
  8004203445:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[6]) << 48 | ((uint64_t) src[7]) << 56;
  8004203449:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420344d:	48 83 c0 06          	add    $0x6,%rax
  8004203451:	0f b6 00             	movzbl (%rax),%eax
  8004203454:	0f b6 c0             	movzbl %al,%eax
  8004203457:	48 c1 e0 30          	shl    $0x30,%rax
  800420345b:	48 89 c2             	mov    %rax,%rdx
  800420345e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203462:	48 83 c0 07          	add    $0x7,%rax
  8004203466:	0f b6 00             	movzbl (%rax),%eax
  8004203469:	0f b6 c0             	movzbl %al,%eax
  800420346c:	48 c1 e0 38          	shl    $0x38,%rax
  8004203470:	48 09 d0             	or     %rdx,%rax
  8004203473:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 4:
		ret |= ((uint64_t) src[2]) << 16 | ((uint64_t) src[3]) << 24;
  8004203477:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420347b:	48 83 c0 02          	add    $0x2,%rax
  800420347f:	0f b6 00             	movzbl (%rax),%eax
  8004203482:	0f b6 c0             	movzbl %al,%eax
  8004203485:	48 c1 e0 10          	shl    $0x10,%rax
  8004203489:	48 89 c2             	mov    %rax,%rdx
  800420348c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203490:	48 83 c0 03          	add    $0x3,%rax
  8004203494:	0f b6 00             	movzbl (%rax),%eax
  8004203497:	0f b6 c0             	movzbl %al,%eax
  800420349a:	48 c1 e0 18          	shl    $0x18,%rax
  800420349e:	48 09 d0             	or     %rdx,%rax
  80042034a1:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 2:
		ret |= ((uint64_t) src[1]) << 8;
  80042034a5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042034a9:	48 83 c0 01          	add    $0x1,%rax
  80042034ad:	0f b6 00             	movzbl (%rax),%eax
  80042034b0:	0f b6 c0             	movzbl %al,%eax
  80042034b3:	48 c1 e0 08          	shl    $0x8,%rax
  80042034b7:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 1:
		ret |= src[0];
  80042034bb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042034bf:	0f b6 00             	movzbl (%rax),%eax
  80042034c2:	0f b6 c0             	movzbl %al,%eax
  80042034c5:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  80042034c9:	90                   	nop
	default:
		return (0);
	}

	*offsetp += bytes_to_read;
  80042034ca:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042034ce:	48 8b 10             	mov    (%rax),%rdx
  80042034d1:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042034d4:	48 98                	cltq   
  80042034d6:	48 01 c2             	add    %rax,%rdx
  80042034d9:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042034dd:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  80042034e0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042034e4:	eb 05                	jmp    80042034eb <_dwarf_read_lsb+0x12a>
		return (0);
  80042034e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042034eb:	c9                   	leaveq 
  80042034ec:	c3                   	retq   

00000080042034ed <_dwarf_decode_lsb>:

uint64_t
_dwarf_decode_lsb(uint8_t **data, int bytes_to_read)
{
  80042034ed:	55                   	push   %rbp
  80042034ee:	48 89 e5             	mov    %rsp,%rbp
  80042034f1:	48 83 ec 20          	sub    $0x20,%rsp
  80042034f5:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042034f9:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = *data;
  80042034fc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203500:	48 8b 00             	mov    (%rax),%rax
  8004203503:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	ret = 0;
  8004203507:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  800420350e:	00 
	switch (bytes_to_read) {
  800420350f:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004203512:	83 f8 02             	cmp    $0x2,%eax
  8004203515:	0f 84 ab 00 00 00    	je     80042035c6 <_dwarf_decode_lsb+0xd9>
  800420351b:	83 f8 02             	cmp    $0x2,%eax
  800420351e:	7f 0e                	jg     800420352e <_dwarf_decode_lsb+0x41>
  8004203520:	83 f8 01             	cmp    $0x1,%eax
  8004203523:	0f 84 b3 00 00 00    	je     80042035dc <_dwarf_decode_lsb+0xef>
  8004203529:	e9 d9 00 00 00       	jmpq   8004203607 <_dwarf_decode_lsb+0x11a>
  800420352e:	83 f8 04             	cmp    $0x4,%eax
  8004203531:	74 65                	je     8004203598 <_dwarf_decode_lsb+0xab>
  8004203533:	83 f8 08             	cmp    $0x8,%eax
  8004203536:	0f 85 cb 00 00 00    	jne    8004203607 <_dwarf_decode_lsb+0x11a>
	case 8:
		ret |= ((uint64_t) src[4]) << 32 | ((uint64_t) src[5]) << 40;
  800420353c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203540:	48 83 c0 04          	add    $0x4,%rax
  8004203544:	0f b6 00             	movzbl (%rax),%eax
  8004203547:	0f b6 c0             	movzbl %al,%eax
  800420354a:	48 c1 e0 20          	shl    $0x20,%rax
  800420354e:	48 89 c2             	mov    %rax,%rdx
  8004203551:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203555:	48 83 c0 05          	add    $0x5,%rax
  8004203559:	0f b6 00             	movzbl (%rax),%eax
  800420355c:	0f b6 c0             	movzbl %al,%eax
  800420355f:	48 c1 e0 28          	shl    $0x28,%rax
  8004203563:	48 09 d0             	or     %rdx,%rax
  8004203566:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[6]) << 48 | ((uint64_t) src[7]) << 56;
  800420356a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420356e:	48 83 c0 06          	add    $0x6,%rax
  8004203572:	0f b6 00             	movzbl (%rax),%eax
  8004203575:	0f b6 c0             	movzbl %al,%eax
  8004203578:	48 c1 e0 30          	shl    $0x30,%rax
  800420357c:	48 89 c2             	mov    %rax,%rdx
  800420357f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203583:	48 83 c0 07          	add    $0x7,%rax
  8004203587:	0f b6 00             	movzbl (%rax),%eax
  800420358a:	0f b6 c0             	movzbl %al,%eax
  800420358d:	48 c1 e0 38          	shl    $0x38,%rax
  8004203591:	48 09 d0             	or     %rdx,%rax
  8004203594:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 4:
		ret |= ((uint64_t) src[2]) << 16 | ((uint64_t) src[3]) << 24;
  8004203598:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420359c:	48 83 c0 02          	add    $0x2,%rax
  80042035a0:	0f b6 00             	movzbl (%rax),%eax
  80042035a3:	0f b6 c0             	movzbl %al,%eax
  80042035a6:	48 c1 e0 10          	shl    $0x10,%rax
  80042035aa:	48 89 c2             	mov    %rax,%rdx
  80042035ad:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035b1:	48 83 c0 03          	add    $0x3,%rax
  80042035b5:	0f b6 00             	movzbl (%rax),%eax
  80042035b8:	0f b6 c0             	movzbl %al,%eax
  80042035bb:	48 c1 e0 18          	shl    $0x18,%rax
  80042035bf:	48 09 d0             	or     %rdx,%rax
  80042035c2:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 2:
		ret |= ((uint64_t) src[1]) << 8;
  80042035c6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035ca:	48 83 c0 01          	add    $0x1,%rax
  80042035ce:	0f b6 00             	movzbl (%rax),%eax
  80042035d1:	0f b6 c0             	movzbl %al,%eax
  80042035d4:	48 c1 e0 08          	shl    $0x8,%rax
  80042035d8:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 1:
		ret |= src[0];
  80042035dc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035e0:	0f b6 00             	movzbl (%rax),%eax
  80042035e3:	0f b6 c0             	movzbl %al,%eax
  80042035e6:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  80042035ea:	90                   	nop
	default:
		return (0);
	}

	*data += bytes_to_read;
  80042035eb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042035ef:	48 8b 10             	mov    (%rax),%rdx
  80042035f2:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042035f5:	48 98                	cltq   
  80042035f7:	48 01 c2             	add    %rax,%rdx
  80042035fa:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042035fe:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203601:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203605:	eb 05                	jmp    800420360c <_dwarf_decode_lsb+0x11f>
		return (0);
  8004203607:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420360c:	c9                   	leaveq 
  800420360d:	c3                   	retq   

000000800420360e <_dwarf_read_msb>:

uint64_t
_dwarf_read_msb(uint8_t *data, uint64_t *offsetp, int bytes_to_read)
{
  800420360e:	55                   	push   %rbp
  800420360f:	48 89 e5             	mov    %rsp,%rbp
  8004203612:	48 83 ec 28          	sub    $0x28,%rsp
  8004203616:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420361a:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  800420361e:	89 55 dc             	mov    %edx,-0x24(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = data + *offsetp;
  8004203621:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203625:	48 8b 10             	mov    (%rax),%rdx
  8004203628:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420362c:	48 01 d0             	add    %rdx,%rax
  800420362f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	switch (bytes_to_read) {
  8004203633:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004203636:	83 f8 02             	cmp    $0x2,%eax
  8004203639:	74 35                	je     8004203670 <_dwarf_read_msb+0x62>
  800420363b:	83 f8 02             	cmp    $0x2,%eax
  800420363e:	7f 0a                	jg     800420364a <_dwarf_read_msb+0x3c>
  8004203640:	83 f8 01             	cmp    $0x1,%eax
  8004203643:	74 18                	je     800420365d <_dwarf_read_msb+0x4f>
  8004203645:	e9 53 01 00 00       	jmpq   800420379d <_dwarf_read_msb+0x18f>
  800420364a:	83 f8 04             	cmp    $0x4,%eax
  800420364d:	74 49                	je     8004203698 <_dwarf_read_msb+0x8a>
  800420364f:	83 f8 08             	cmp    $0x8,%eax
  8004203652:	0f 84 96 00 00 00    	je     80042036ee <_dwarf_read_msb+0xe0>
  8004203658:	e9 40 01 00 00       	jmpq   800420379d <_dwarf_read_msb+0x18f>
	case 1:
		ret = src[0];
  800420365d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203661:	0f b6 00             	movzbl (%rax),%eax
  8004203664:	0f b6 c0             	movzbl %al,%eax
  8004203667:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  800420366b:	e9 34 01 00 00       	jmpq   80042037a4 <_dwarf_read_msb+0x196>
	case 2:
		ret = src[1] | ((uint64_t) src[0]) << 8;
  8004203670:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203674:	48 83 c0 01          	add    $0x1,%rax
  8004203678:	0f b6 00             	movzbl (%rax),%eax
  800420367b:	0f b6 d0             	movzbl %al,%edx
  800420367e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203682:	0f b6 00             	movzbl (%rax),%eax
  8004203685:	0f b6 c0             	movzbl %al,%eax
  8004203688:	48 c1 e0 08          	shl    $0x8,%rax
  800420368c:	48 09 d0             	or     %rdx,%rax
  800420368f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  8004203693:	e9 0c 01 00 00       	jmpq   80042037a4 <_dwarf_read_msb+0x196>
	case 4:
		ret = src[3] | ((uint64_t) src[2]) << 8;
  8004203698:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420369c:	48 83 c0 03          	add    $0x3,%rax
  80042036a0:	0f b6 00             	movzbl (%rax),%eax
  80042036a3:	0f b6 c0             	movzbl %al,%eax
  80042036a6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042036aa:	48 83 c2 02          	add    $0x2,%rdx
  80042036ae:	0f b6 12             	movzbl (%rdx),%edx
  80042036b1:	0f b6 d2             	movzbl %dl,%edx
  80042036b4:	48 c1 e2 08          	shl    $0x8,%rdx
  80042036b8:	48 09 d0             	or     %rdx,%rax
  80042036bb:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 16 | ((uint64_t) src[0]) << 24;
  80042036bf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042036c3:	48 83 c0 01          	add    $0x1,%rax
  80042036c7:	0f b6 00             	movzbl (%rax),%eax
  80042036ca:	0f b6 c0             	movzbl %al,%eax
  80042036cd:	48 c1 e0 10          	shl    $0x10,%rax
  80042036d1:	48 89 c2             	mov    %rax,%rdx
  80042036d4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042036d8:	0f b6 00             	movzbl (%rax),%eax
  80042036db:	0f b6 c0             	movzbl %al,%eax
  80042036de:	48 c1 e0 18          	shl    $0x18,%rax
  80042036e2:	48 09 d0             	or     %rdx,%rax
  80042036e5:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  80042036e9:	e9 b6 00 00 00       	jmpq   80042037a4 <_dwarf_read_msb+0x196>
	case 8:
		ret = src[7] | ((uint64_t) src[6]) << 8;
  80042036ee:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042036f2:	48 83 c0 07          	add    $0x7,%rax
  80042036f6:	0f b6 00             	movzbl (%rax),%eax
  80042036f9:	0f b6 c0             	movzbl %al,%eax
  80042036fc:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203700:	48 83 c2 06          	add    $0x6,%rdx
  8004203704:	0f b6 12             	movzbl (%rdx),%edx
  8004203707:	0f b6 d2             	movzbl %dl,%edx
  800420370a:	48 c1 e2 08          	shl    $0x8,%rdx
  800420370e:	48 09 d0             	or     %rdx,%rax
  8004203711:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[5]) << 16 | ((uint64_t) src[4]) << 24;
  8004203715:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203719:	48 83 c0 05          	add    $0x5,%rax
  800420371d:	0f b6 00             	movzbl (%rax),%eax
  8004203720:	0f b6 c0             	movzbl %al,%eax
  8004203723:	48 c1 e0 10          	shl    $0x10,%rax
  8004203727:	48 89 c2             	mov    %rax,%rdx
  800420372a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420372e:	48 83 c0 04          	add    $0x4,%rax
  8004203732:	0f b6 00             	movzbl (%rax),%eax
  8004203735:	0f b6 c0             	movzbl %al,%eax
  8004203738:	48 c1 e0 18          	shl    $0x18,%rax
  800420373c:	48 09 d0             	or     %rdx,%rax
  800420373f:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[3]) << 32 | ((uint64_t) src[2]) << 40;
  8004203743:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203747:	48 83 c0 03          	add    $0x3,%rax
  800420374b:	0f b6 00             	movzbl (%rax),%eax
  800420374e:	0f b6 c0             	movzbl %al,%eax
  8004203751:	48 c1 e0 20          	shl    $0x20,%rax
  8004203755:	48 89 c2             	mov    %rax,%rdx
  8004203758:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420375c:	48 83 c0 02          	add    $0x2,%rax
  8004203760:	0f b6 00             	movzbl (%rax),%eax
  8004203763:	0f b6 c0             	movzbl %al,%eax
  8004203766:	48 c1 e0 28          	shl    $0x28,%rax
  800420376a:	48 09 d0             	or     %rdx,%rax
  800420376d:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 48 | ((uint64_t) src[0]) << 56;
  8004203771:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203775:	48 83 c0 01          	add    $0x1,%rax
  8004203779:	0f b6 00             	movzbl (%rax),%eax
  800420377c:	0f b6 c0             	movzbl %al,%eax
  800420377f:	48 c1 e0 30          	shl    $0x30,%rax
  8004203783:	48 89 c2             	mov    %rax,%rdx
  8004203786:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420378a:	0f b6 00             	movzbl (%rax),%eax
  800420378d:	0f b6 c0             	movzbl %al,%eax
  8004203790:	48 c1 e0 38          	shl    $0x38,%rax
  8004203794:	48 09 d0             	or     %rdx,%rax
  8004203797:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  800420379b:	eb 07                	jmp    80042037a4 <_dwarf_read_msb+0x196>
	default:
		return (0);
  800420379d:	b8 00 00 00 00       	mov    $0x0,%eax
  80042037a2:	eb 1a                	jmp    80042037be <_dwarf_read_msb+0x1b0>
	}

	*offsetp += bytes_to_read;
  80042037a4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042037a8:	48 8b 10             	mov    (%rax),%rdx
  80042037ab:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042037ae:	48 98                	cltq   
  80042037b0:	48 01 c2             	add    %rax,%rdx
  80042037b3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042037b7:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  80042037ba:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  80042037be:	c9                   	leaveq 
  80042037bf:	c3                   	retq   

00000080042037c0 <_dwarf_decode_msb>:

uint64_t
_dwarf_decode_msb(uint8_t **data, int bytes_to_read)
{
  80042037c0:	55                   	push   %rbp
  80042037c1:	48 89 e5             	mov    %rsp,%rbp
  80042037c4:	48 83 ec 20          	sub    $0x20,%rsp
  80042037c8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042037cc:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = *data;
  80042037cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042037d3:	48 8b 00             	mov    (%rax),%rax
  80042037d6:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	ret = 0;
  80042037da:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  80042037e1:	00 
	switch (bytes_to_read) {
  80042037e2:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042037e5:	83 f8 02             	cmp    $0x2,%eax
  80042037e8:	74 35                	je     800420381f <_dwarf_decode_msb+0x5f>
  80042037ea:	83 f8 02             	cmp    $0x2,%eax
  80042037ed:	7f 0a                	jg     80042037f9 <_dwarf_decode_msb+0x39>
  80042037ef:	83 f8 01             	cmp    $0x1,%eax
  80042037f2:	74 18                	je     800420380c <_dwarf_decode_msb+0x4c>
  80042037f4:	e9 53 01 00 00       	jmpq   800420394c <_dwarf_decode_msb+0x18c>
  80042037f9:	83 f8 04             	cmp    $0x4,%eax
  80042037fc:	74 49                	je     8004203847 <_dwarf_decode_msb+0x87>
  80042037fe:	83 f8 08             	cmp    $0x8,%eax
  8004203801:	0f 84 96 00 00 00    	je     800420389d <_dwarf_decode_msb+0xdd>
  8004203807:	e9 40 01 00 00       	jmpq   800420394c <_dwarf_decode_msb+0x18c>
	case 1:
		ret = src[0];
  800420380c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203810:	0f b6 00             	movzbl (%rax),%eax
  8004203813:	0f b6 c0             	movzbl %al,%eax
  8004203816:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  800420381a:	e9 34 01 00 00       	jmpq   8004203953 <_dwarf_decode_msb+0x193>
	case 2:
		ret = src[1] | ((uint64_t) src[0]) << 8;
  800420381f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203823:	48 83 c0 01          	add    $0x1,%rax
  8004203827:	0f b6 00             	movzbl (%rax),%eax
  800420382a:	0f b6 d0             	movzbl %al,%edx
  800420382d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203831:	0f b6 00             	movzbl (%rax),%eax
  8004203834:	0f b6 c0             	movzbl %al,%eax
  8004203837:	48 c1 e0 08          	shl    $0x8,%rax
  800420383b:	48 09 d0             	or     %rdx,%rax
  800420383e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  8004203842:	e9 0c 01 00 00       	jmpq   8004203953 <_dwarf_decode_msb+0x193>
	case 4:
		ret = src[3] | ((uint64_t) src[2]) << 8;
  8004203847:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420384b:	48 83 c0 03          	add    $0x3,%rax
  800420384f:	0f b6 00             	movzbl (%rax),%eax
  8004203852:	0f b6 c0             	movzbl %al,%eax
  8004203855:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203859:	48 83 c2 02          	add    $0x2,%rdx
  800420385d:	0f b6 12             	movzbl (%rdx),%edx
  8004203860:	0f b6 d2             	movzbl %dl,%edx
  8004203863:	48 c1 e2 08          	shl    $0x8,%rdx
  8004203867:	48 09 d0             	or     %rdx,%rax
  800420386a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 16 | ((uint64_t) src[0]) << 24;
  800420386e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203872:	48 83 c0 01          	add    $0x1,%rax
  8004203876:	0f b6 00             	movzbl (%rax),%eax
  8004203879:	0f b6 c0             	movzbl %al,%eax
  800420387c:	48 c1 e0 10          	shl    $0x10,%rax
  8004203880:	48 89 c2             	mov    %rax,%rdx
  8004203883:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203887:	0f b6 00             	movzbl (%rax),%eax
  800420388a:	0f b6 c0             	movzbl %al,%eax
  800420388d:	48 c1 e0 18          	shl    $0x18,%rax
  8004203891:	48 09 d0             	or     %rdx,%rax
  8004203894:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  8004203898:	e9 b6 00 00 00       	jmpq   8004203953 <_dwarf_decode_msb+0x193>
	case 8:
		ret = src[7] | ((uint64_t) src[6]) << 8;
  800420389d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042038a1:	48 83 c0 07          	add    $0x7,%rax
  80042038a5:	0f b6 00             	movzbl (%rax),%eax
  80042038a8:	0f b6 c0             	movzbl %al,%eax
  80042038ab:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042038af:	48 83 c2 06          	add    $0x6,%rdx
  80042038b3:	0f b6 12             	movzbl (%rdx),%edx
  80042038b6:	0f b6 d2             	movzbl %dl,%edx
  80042038b9:	48 c1 e2 08          	shl    $0x8,%rdx
  80042038bd:	48 09 d0             	or     %rdx,%rax
  80042038c0:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[5]) << 16 | ((uint64_t) src[4]) << 24;
  80042038c4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042038c8:	48 83 c0 05          	add    $0x5,%rax
  80042038cc:	0f b6 00             	movzbl (%rax),%eax
  80042038cf:	0f b6 c0             	movzbl %al,%eax
  80042038d2:	48 c1 e0 10          	shl    $0x10,%rax
  80042038d6:	48 89 c2             	mov    %rax,%rdx
  80042038d9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042038dd:	48 83 c0 04          	add    $0x4,%rax
  80042038e1:	0f b6 00             	movzbl (%rax),%eax
  80042038e4:	0f b6 c0             	movzbl %al,%eax
  80042038e7:	48 c1 e0 18          	shl    $0x18,%rax
  80042038eb:	48 09 d0             	or     %rdx,%rax
  80042038ee:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[3]) << 32 | ((uint64_t) src[2]) << 40;
  80042038f2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042038f6:	48 83 c0 03          	add    $0x3,%rax
  80042038fa:	0f b6 00             	movzbl (%rax),%eax
  80042038fd:	0f b6 c0             	movzbl %al,%eax
  8004203900:	48 c1 e0 20          	shl    $0x20,%rax
  8004203904:	48 89 c2             	mov    %rax,%rdx
  8004203907:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420390b:	48 83 c0 02          	add    $0x2,%rax
  800420390f:	0f b6 00             	movzbl (%rax),%eax
  8004203912:	0f b6 c0             	movzbl %al,%eax
  8004203915:	48 c1 e0 28          	shl    $0x28,%rax
  8004203919:	48 09 d0             	or     %rdx,%rax
  800420391c:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 48 | ((uint64_t) src[0]) << 56;
  8004203920:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203924:	48 83 c0 01          	add    $0x1,%rax
  8004203928:	0f b6 00             	movzbl (%rax),%eax
  800420392b:	0f b6 c0             	movzbl %al,%eax
  800420392e:	48 c1 e0 30          	shl    $0x30,%rax
  8004203932:	48 89 c2             	mov    %rax,%rdx
  8004203935:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203939:	0f b6 00             	movzbl (%rax),%eax
  800420393c:	0f b6 c0             	movzbl %al,%eax
  800420393f:	48 c1 e0 38          	shl    $0x38,%rax
  8004203943:	48 09 d0             	or     %rdx,%rax
  8004203946:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  800420394a:	eb 07                	jmp    8004203953 <_dwarf_decode_msb+0x193>
	default:
		return (0);
  800420394c:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203951:	eb 1a                	jmp    800420396d <_dwarf_decode_msb+0x1ad>
		break;
	}

	*data += bytes_to_read;
  8004203953:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203957:	48 8b 10             	mov    (%rax),%rdx
  800420395a:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  800420395d:	48 98                	cltq   
  800420395f:	48 01 c2             	add    %rax,%rdx
  8004203962:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203966:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203969:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  800420396d:	c9                   	leaveq 
  800420396e:	c3                   	retq   

000000800420396f <_dwarf_read_sleb128>:

int64_t
_dwarf_read_sleb128(uint8_t *data, uint64_t *offsetp)
{
  800420396f:	55                   	push   %rbp
  8004203970:	48 89 e5             	mov    %rsp,%rbp
  8004203973:	48 83 ec 30          	sub    $0x30,%rsp
  8004203977:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  800420397b:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
	int64_t ret = 0;
  800420397f:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203986:	00 
	uint8_t b;
	int shift = 0;
  8004203987:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
	uint8_t *src;

	src = data + *offsetp;
  800420398e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203992:	48 8b 10             	mov    (%rax),%rdx
  8004203995:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203999:	48 01 d0             	add    %rdx,%rax
  800420399c:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	do {
		b = *src++;
  80042039a0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042039a4:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80042039a8:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80042039ac:	0f b6 00             	movzbl (%rax),%eax
  80042039af:	88 45 e7             	mov    %al,-0x19(%rbp)
		ret |= ((b & 0x7f) << shift);
  80042039b2:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  80042039b6:	83 e0 7f             	and    $0x7f,%eax
  80042039b9:	89 c2                	mov    %eax,%edx
  80042039bb:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042039be:	89 c1                	mov    %eax,%ecx
  80042039c0:	d3 e2                	shl    %cl,%edx
  80042039c2:	89 d0                	mov    %edx,%eax
  80042039c4:	48 98                	cltq   
  80042039c6:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		(*offsetp)++;
  80042039ca:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042039ce:	48 8b 00             	mov    (%rax),%rax
  80042039d1:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80042039d5:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042039d9:	48 89 10             	mov    %rdx,(%rax)
		shift += 7;
  80042039dc:	83 45 f4 07          	addl   $0x7,-0xc(%rbp)
	} while ((b & 0x80) != 0);
  80042039e0:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  80042039e4:	84 c0                	test   %al,%al
  80042039e6:	78 b8                	js     80042039a0 <_dwarf_read_sleb128+0x31>

	if (shift < 32 && (b & 0x40) != 0)
  80042039e8:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%rbp)
  80042039ec:	7f 1f                	jg     8004203a0d <_dwarf_read_sleb128+0x9e>
  80042039ee:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  80042039f2:	83 e0 40             	and    $0x40,%eax
  80042039f5:	85 c0                	test   %eax,%eax
  80042039f7:	74 14                	je     8004203a0d <_dwarf_read_sleb128+0x9e>
		ret |= (-1 << shift);
  80042039f9:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042039fc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  8004203a01:	89 c1                	mov    %eax,%ecx
  8004203a03:	d3 e2                	shl    %cl,%edx
  8004203a05:	89 d0                	mov    %edx,%eax
  8004203a07:	48 98                	cltq   
  8004203a09:	48 09 45 f8          	or     %rax,-0x8(%rbp)

	return (ret);
  8004203a0d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004203a11:	c9                   	leaveq 
  8004203a12:	c3                   	retq   

0000008004203a13 <_dwarf_read_uleb128>:

uint64_t
_dwarf_read_uleb128(uint8_t *data, uint64_t *offsetp)
{
  8004203a13:	55                   	push   %rbp
  8004203a14:	48 89 e5             	mov    %rsp,%rbp
  8004203a17:	48 83 ec 30          	sub    $0x30,%rsp
  8004203a1b:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004203a1f:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
	uint64_t ret = 0;
  8004203a23:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203a2a:	00 
	uint8_t b;
	int shift = 0;
  8004203a2b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
	uint8_t *src;

	src = data + *offsetp;
  8004203a32:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203a36:	48 8b 10             	mov    (%rax),%rdx
  8004203a39:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203a3d:	48 01 d0             	add    %rdx,%rax
  8004203a40:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	do {
		b = *src++;
  8004203a44:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203a48:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203a4c:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8004203a50:	0f b6 00             	movzbl (%rax),%eax
  8004203a53:	88 45 e7             	mov    %al,-0x19(%rbp)
		ret |= ((b & 0x7f) << shift);
  8004203a56:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203a5a:	83 e0 7f             	and    $0x7f,%eax
  8004203a5d:	89 c2                	mov    %eax,%edx
  8004203a5f:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004203a62:	89 c1                	mov    %eax,%ecx
  8004203a64:	d3 e2                	shl    %cl,%edx
  8004203a66:	89 d0                	mov    %edx,%eax
  8004203a68:	48 98                	cltq   
  8004203a6a:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		(*offsetp)++;
  8004203a6e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203a72:	48 8b 00             	mov    (%rax),%rax
  8004203a75:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203a79:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203a7d:	48 89 10             	mov    %rdx,(%rax)
		shift += 7;
  8004203a80:	83 45 f4 07          	addl   $0x7,-0xc(%rbp)
	} while ((b & 0x80) != 0);
  8004203a84:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203a88:	84 c0                	test   %al,%al
  8004203a8a:	78 b8                	js     8004203a44 <_dwarf_read_uleb128+0x31>

	return (ret);
  8004203a8c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004203a90:	c9                   	leaveq 
  8004203a91:	c3                   	retq   

0000008004203a92 <_dwarf_decode_sleb128>:

int64_t
_dwarf_decode_sleb128(uint8_t **dp)
{
  8004203a92:	55                   	push   %rbp
  8004203a93:	48 89 e5             	mov    %rsp,%rbp
  8004203a96:	48 83 ec 28          	sub    $0x28,%rsp
  8004203a9a:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
	int64_t ret = 0;
  8004203a9e:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203aa5:	00 
	uint8_t b;
	int shift = 0;
  8004203aa6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)

	uint8_t *src = *dp;
  8004203aad:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203ab1:	48 8b 00             	mov    (%rax),%rax
  8004203ab4:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	do {
		b = *src++;
  8004203ab8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203abc:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203ac0:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8004203ac4:	0f b6 00             	movzbl (%rax),%eax
  8004203ac7:	88 45 e7             	mov    %al,-0x19(%rbp)
		ret |= ((b & 0x7f) << shift);
  8004203aca:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203ace:	83 e0 7f             	and    $0x7f,%eax
  8004203ad1:	89 c2                	mov    %eax,%edx
  8004203ad3:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004203ad6:	89 c1                	mov    %eax,%ecx
  8004203ad8:	d3 e2                	shl    %cl,%edx
  8004203ada:	89 d0                	mov    %edx,%eax
  8004203adc:	48 98                	cltq   
  8004203ade:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		shift += 7;
  8004203ae2:	83 45 f4 07          	addl   $0x7,-0xc(%rbp)
	} while ((b & 0x80) != 0);
  8004203ae6:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203aea:	84 c0                	test   %al,%al
  8004203aec:	78 ca                	js     8004203ab8 <_dwarf_decode_sleb128+0x26>

	if (shift < 32 && (b & 0x40) != 0)
  8004203aee:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%rbp)
  8004203af2:	7f 1f                	jg     8004203b13 <_dwarf_decode_sleb128+0x81>
  8004203af4:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203af8:	83 e0 40             	and    $0x40,%eax
  8004203afb:	85 c0                	test   %eax,%eax
  8004203afd:	74 14                	je     8004203b13 <_dwarf_decode_sleb128+0x81>
		ret |= (-1 << shift);
  8004203aff:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004203b02:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  8004203b07:	89 c1                	mov    %eax,%ecx
  8004203b09:	d3 e2                	shl    %cl,%edx
  8004203b0b:	89 d0                	mov    %edx,%eax
  8004203b0d:	48 98                	cltq   
  8004203b0f:	48 09 45 f8          	or     %rax,-0x8(%rbp)

	*dp = src;
  8004203b13:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b17:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203b1b:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203b1e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004203b22:	c9                   	leaveq 
  8004203b23:	c3                   	retq   

0000008004203b24 <_dwarf_decode_uleb128>:

uint64_t
_dwarf_decode_uleb128(uint8_t **dp)
{
  8004203b24:	55                   	push   %rbp
  8004203b25:	48 89 e5             	mov    %rsp,%rbp
  8004203b28:	48 83 ec 28          	sub    $0x28,%rsp
  8004203b2c:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
	uint64_t ret = 0;
  8004203b30:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203b37:	00 
	uint8_t b;
	int shift = 0;
  8004203b38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)

	uint8_t *src = *dp;
  8004203b3f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b43:	48 8b 00             	mov    (%rax),%rax
  8004203b46:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	do {
		b = *src++;
  8004203b4a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203b4e:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203b52:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8004203b56:	0f b6 00             	movzbl (%rax),%eax
  8004203b59:	88 45 e7             	mov    %al,-0x19(%rbp)
		ret |= ((b & 0x7f) << shift);
  8004203b5c:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203b60:	83 e0 7f             	and    $0x7f,%eax
  8004203b63:	89 c2                	mov    %eax,%edx
  8004203b65:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004203b68:	89 c1                	mov    %eax,%ecx
  8004203b6a:	d3 e2                	shl    %cl,%edx
  8004203b6c:	89 d0                	mov    %edx,%eax
  8004203b6e:	48 98                	cltq   
  8004203b70:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		shift += 7;
  8004203b74:	83 45 f4 07          	addl   $0x7,-0xc(%rbp)
	} while ((b & 0x80) != 0);
  8004203b78:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004203b7c:	84 c0                	test   %al,%al
  8004203b7e:	78 ca                	js     8004203b4a <_dwarf_decode_uleb128+0x26>

	*dp = src;
  8004203b80:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b84:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203b88:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203b8b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004203b8f:	c9                   	leaveq 
  8004203b90:	c3                   	retq   

0000008004203b91 <_dwarf_read_string>:

#define Dwarf_Unsigned uint64_t

char *
_dwarf_read_string(void *data, Dwarf_Unsigned size, uint64_t *offsetp)
{
  8004203b91:	55                   	push   %rbp
  8004203b92:	48 89 e5             	mov    %rsp,%rbp
  8004203b95:	48 83 ec 28          	sub    $0x28,%rsp
  8004203b99:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203b9d:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203ba1:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	char *ret, *src;

	ret = src = (char *) data + *offsetp;
  8004203ba5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203ba9:	48 8b 10             	mov    (%rax),%rdx
  8004203bac:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203bb0:	48 01 d0             	add    %rdx,%rax
  8004203bb3:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004203bb7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203bbb:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	while (*src != '\0' && *offsetp < size) {
  8004203bbf:	eb 17                	jmp    8004203bd8 <_dwarf_read_string+0x47>
		src++;
  8004203bc1:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
		(*offsetp)++;
  8004203bc6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203bca:	48 8b 00             	mov    (%rax),%rax
  8004203bcd:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203bd1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203bd5:	48 89 10             	mov    %rdx,(%rax)
	while (*src != '\0' && *offsetp < size) {
  8004203bd8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203bdc:	0f b6 00             	movzbl (%rax),%eax
  8004203bdf:	84 c0                	test   %al,%al
  8004203be1:	74 0d                	je     8004203bf0 <_dwarf_read_string+0x5f>
  8004203be3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203be7:	48 8b 00             	mov    (%rax),%rax
  8004203bea:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004203bee:	77 d1                	ja     8004203bc1 <_dwarf_read_string+0x30>
	}

	if (*src == '\0' && *offsetp < size)
  8004203bf0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203bf4:	0f b6 00             	movzbl (%rax),%eax
  8004203bf7:	84 c0                	test   %al,%al
  8004203bf9:	75 1f                	jne    8004203c1a <_dwarf_read_string+0x89>
  8004203bfb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203bff:	48 8b 00             	mov    (%rax),%rax
  8004203c02:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004203c06:	76 12                	jbe    8004203c1a <_dwarf_read_string+0x89>
		(*offsetp)++;
  8004203c08:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203c0c:	48 8b 00             	mov    (%rax),%rax
  8004203c0f:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203c13:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203c17:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203c1a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203c1e:	c9                   	leaveq 
  8004203c1f:	c3                   	retq   

0000008004203c20 <_dwarf_read_block>:

uint8_t *
_dwarf_read_block(void *data, uint64_t *offsetp, uint64_t length)
{
  8004203c20:	55                   	push   %rbp
  8004203c21:	48 89 e5             	mov    %rsp,%rbp
  8004203c24:	48 83 ec 28          	sub    $0x28,%rsp
  8004203c28:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203c2c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203c30:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	uint8_t *ret, *src;

	ret = src = (uint8_t *) data + *offsetp;
  8004203c34:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203c38:	48 8b 10             	mov    (%rax),%rdx
  8004203c3b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203c3f:	48 01 d0             	add    %rdx,%rax
  8004203c42:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004203c46:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203c4a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	(*offsetp) += length;
  8004203c4e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203c52:	48 8b 10             	mov    (%rax),%rdx
  8004203c55:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203c59:	48 01 c2             	add    %rax,%rdx
  8004203c5c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203c60:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203c63:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203c67:	c9                   	leaveq 
  8004203c68:	c3                   	retq   

0000008004203c69 <_dwarf_elf_get_byte_order>:

Dwarf_Endianness
_dwarf_elf_get_byte_order(void *obj)
{
  8004203c69:	55                   	push   %rbp
  8004203c6a:	48 89 e5             	mov    %rsp,%rbp
  8004203c6d:	48 83 ec 20          	sub    $0x20,%rsp
  8004203c71:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	Elf *e;

	e = (Elf *)obj;
  8004203c75:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203c79:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	assert(e != NULL);
  8004203c7d:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004203c82:	75 35                	jne    8004203cb9 <_dwarf_elf_get_byte_order+0x50>
  8004203c84:	48 b9 00 9d 20 04 80 	movabs $0x8004209d00,%rcx
  8004203c8b:	00 00 00 
  8004203c8e:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004203c95:	00 00 00 
  8004203c98:	be 29 01 00 00       	mov    $0x129,%esi
  8004203c9d:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004203ca4:	00 00 00 
  8004203ca7:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203cac:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004203cb3:	00 00 00 
  8004203cb6:	41 ff d0             	callq  *%r8

//TODO: Need to check for 64bit here. Because currently Elf header for
//      64bit doesn't have any memeber e_ident. But need to see what is
//      similar in 64bit.
	switch (e->e_ident[EI_DATA]) {
  8004203cb9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203cbd:	0f b6 40 05          	movzbl 0x5(%rax),%eax
  8004203cc1:	0f b6 c0             	movzbl %al,%eax
  8004203cc4:	83 f8 02             	cmp    $0x2,%eax
  8004203cc7:	75 07                	jne    8004203cd0 <_dwarf_elf_get_byte_order+0x67>
	case ELFDATA2MSB:
		return (DW_OBJECT_MSB);
  8004203cc9:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203cce:	eb 05                	jmp    8004203cd5 <_dwarf_elf_get_byte_order+0x6c>

	case ELFDATA2LSB:
	case ELFDATANONE:
	default:
		return (DW_OBJECT_LSB);
  8004203cd0:	b8 01 00 00 00       	mov    $0x1,%eax
	}
}
  8004203cd5:	c9                   	leaveq 
  8004203cd6:	c3                   	retq   

0000008004203cd7 <_dwarf_elf_get_pointer_size>:

Dwarf_Small
_dwarf_elf_get_pointer_size(void *obj)
{
  8004203cd7:	55                   	push   %rbp
  8004203cd8:	48 89 e5             	mov    %rsp,%rbp
  8004203cdb:	48 83 ec 20          	sub    $0x20,%rsp
  8004203cdf:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	Elf *e;

	e = (Elf *) obj;
  8004203ce3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203ce7:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	assert(e != NULL);
  8004203ceb:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004203cf0:	75 35                	jne    8004203d27 <_dwarf_elf_get_pointer_size+0x50>
  8004203cf2:	48 b9 00 9d 20 04 80 	movabs $0x8004209d00,%rcx
  8004203cf9:	00 00 00 
  8004203cfc:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004203d03:	00 00 00 
  8004203d06:	be 3f 01 00 00       	mov    $0x13f,%esi
  8004203d0b:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004203d12:	00 00 00 
  8004203d15:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203d1a:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004203d21:	00 00 00 
  8004203d24:	41 ff d0             	callq  *%r8

	if (e->e_ident[4] == ELFCLASS32)
  8004203d27:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d2b:	0f b6 40 04          	movzbl 0x4(%rax),%eax
  8004203d2f:	3c 01                	cmp    $0x1,%al
  8004203d31:	75 07                	jne    8004203d3a <_dwarf_elf_get_pointer_size+0x63>
		return (4);
  8004203d33:	b8 04 00 00 00       	mov    $0x4,%eax
  8004203d38:	eb 05                	jmp    8004203d3f <_dwarf_elf_get_pointer_size+0x68>
	else
		return (8);
  8004203d3a:	b8 08 00 00 00       	mov    $0x8,%eax
}
  8004203d3f:	c9                   	leaveq 
  8004203d40:	c3                   	retq   

0000008004203d41 <_dwarf_init>:

//Return 0 on success
int _dwarf_init(Dwarf_Debug dbg, void *obj)
{
  8004203d41:	55                   	push   %rbp
  8004203d42:	48 89 e5             	mov    %rsp,%rbp
  8004203d45:	48 83 ec 10          	sub    $0x10,%rsp
  8004203d49:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004203d4d:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	memset(dbg, 0, sizeof(struct _Dwarf_Debug));
  8004203d51:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d55:	ba 60 00 00 00       	mov    $0x60,%edx
  8004203d5a:	be 00 00 00 00       	mov    $0x0,%esi
  8004203d5f:	48 89 c7             	mov    %rax,%rdi
  8004203d62:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  8004203d69:	00 00 00 
  8004203d6c:	ff d0                	callq  *%rax
	dbg->curr_off_dbginfo = 0;
  8004203d6e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d72:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
	dbg->dbg_info_size = 0;
  8004203d79:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d7d:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
  8004203d84:	00 
	dbg->dbg_pointer_size = _dwarf_elf_get_pointer_size(obj); 
  8004203d85:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203d89:	48 89 c7             	mov    %rax,%rdi
  8004203d8c:	48 b8 d7 3c 20 04 80 	movabs $0x8004203cd7,%rax
  8004203d93:	00 00 00 
  8004203d96:	ff d0                	callq  *%rax
  8004203d98:	0f b6 d0             	movzbl %al,%edx
  8004203d9b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d9f:	89 50 28             	mov    %edx,0x28(%rax)

	if (_dwarf_elf_get_byte_order(obj) == DW_OBJECT_MSB) {
  8004203da2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203da6:	48 89 c7             	mov    %rax,%rdi
  8004203da9:	48 b8 69 3c 20 04 80 	movabs $0x8004203c69,%rax
  8004203db0:	00 00 00 
  8004203db3:	ff d0                	callq  *%rax
  8004203db5:	85 c0                	test   %eax,%eax
  8004203db7:	75 26                	jne    8004203ddf <_dwarf_init+0x9e>
		dbg->read = _dwarf_read_msb;
  8004203db9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203dbd:	48 b9 0e 36 20 04 80 	movabs $0x800420360e,%rcx
  8004203dc4:	00 00 00 
  8004203dc7:	48 89 48 18          	mov    %rcx,0x18(%rax)
		dbg->decode = _dwarf_decode_msb;
  8004203dcb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203dcf:	48 b9 c0 37 20 04 80 	movabs $0x80042037c0,%rcx
  8004203dd6:	00 00 00 
  8004203dd9:	48 89 48 20          	mov    %rcx,0x20(%rax)
  8004203ddd:	eb 24                	jmp    8004203e03 <_dwarf_init+0xc2>
	} else {
		dbg->read = _dwarf_read_lsb;
  8004203ddf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203de3:	48 be c1 33 20 04 80 	movabs $0x80042033c1,%rsi
  8004203dea:	00 00 00 
  8004203ded:	48 89 70 18          	mov    %rsi,0x18(%rax)
		dbg->decode = _dwarf_decode_lsb;
  8004203df1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203df5:	48 ba ed 34 20 04 80 	movabs $0x80042034ed,%rdx
  8004203dfc:	00 00 00 
  8004203dff:	48 89 50 20          	mov    %rdx,0x20(%rax)
	}
	_dwarf_frame_params_init(dbg);
  8004203e03:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203e07:	48 89 c7             	mov    %rax,%rdi
  8004203e0a:	48 b8 4d 52 20 04 80 	movabs $0x800420524d,%rax
  8004203e11:	00 00 00 
  8004203e14:	ff d0                	callq  *%rax
	return 0;
  8004203e16:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004203e1b:	c9                   	leaveq 
  8004203e1c:	c3                   	retq   

0000008004203e1d <_get_next_cu>:

//Return 0 on success
int _get_next_cu(Dwarf_Debug dbg, Dwarf_CU *cu)
{
  8004203e1d:	55                   	push   %rbp
  8004203e1e:	48 89 e5             	mov    %rsp,%rbp
  8004203e21:	48 83 ec 20          	sub    $0x20,%rsp
  8004203e25:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203e29:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	uint32_t length;
	uint64_t offset;
	uint8_t dwarf_size;

	if(dbg->curr_off_dbginfo > dbg->dbg_info_size)
  8004203e2d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e31:	48 8b 10             	mov    (%rax),%rdx
  8004203e34:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e38:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004203e3c:	48 39 c2             	cmp    %rax,%rdx
  8004203e3f:	76 0a                	jbe    8004203e4b <_get_next_cu+0x2e>
		return -1;
  8004203e41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004203e46:	e9 71 01 00 00       	jmpq   8004203fbc <_get_next_cu+0x19f>

	offset = dbg->curr_off_dbginfo;
  8004203e4b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e4f:	48 8b 00             	mov    (%rax),%rax
  8004203e52:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	cu->cu_offset = offset;
  8004203e56:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203e5a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203e5e:	48 89 50 30          	mov    %rdx,0x30(%rax)

	length = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset,4);
  8004203e62:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e66:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004203e6a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203e6e:	48 8b 52 08          	mov    0x8(%rdx),%rdx
  8004203e72:	48 89 d7             	mov    %rdx,%rdi
  8004203e75:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203e79:	ba 04 00 00 00       	mov    $0x4,%edx
  8004203e7e:	48 89 ce             	mov    %rcx,%rsi
  8004203e81:	ff d0                	callq  *%rax
  8004203e83:	89 45 fc             	mov    %eax,-0x4(%rbp)
	if (length == 0xffffffff) {
  8004203e86:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%rbp)
  8004203e8a:	75 2a                	jne    8004203eb6 <_get_next_cu+0x99>
		length = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, 8);
  8004203e8c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e90:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004203e94:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203e98:	48 8b 52 08          	mov    0x8(%rdx),%rdx
  8004203e9c:	48 89 d7             	mov    %rdx,%rdi
  8004203e9f:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203ea3:	ba 08 00 00 00       	mov    $0x8,%edx
  8004203ea8:	48 89 ce             	mov    %rcx,%rsi
  8004203eab:	ff d0                	callq  *%rax
  8004203ead:	89 45 fc             	mov    %eax,-0x4(%rbp)
		dwarf_size = 8;
  8004203eb0:	c6 45 fb 08          	movb   $0x8,-0x5(%rbp)
  8004203eb4:	eb 04                	jmp    8004203eba <_get_next_cu+0x9d>
	} else {
		dwarf_size = 4;
  8004203eb6:	c6 45 fb 04          	movb   $0x4,-0x5(%rbp)
	}

	cu->cu_dwarf_size = dwarf_size;
  8004203eba:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203ebe:	0f b6 55 fb          	movzbl -0x5(%rbp),%edx
  8004203ec2:	88 50 19             	mov    %dl,0x19(%rax)
	 if (length > ds->ds_size - offset) {
	 return (DW_DLE_CU_LENGTH_ERROR);
	 }*/

	/* Compute the offset to the next compilation unit: */
	dbg->curr_off_dbginfo = offset + length;
  8004203ec5:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004203ec8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203ecc:	48 01 c2             	add    %rax,%rdx
  8004203ecf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203ed3:	48 89 10             	mov    %rdx,(%rax)
	cu->cu_next_offset   = dbg->curr_off_dbginfo;
  8004203ed6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203eda:	48 8b 10             	mov    (%rax),%rdx
  8004203edd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203ee1:	48 89 50 20          	mov    %rdx,0x20(%rax)

	/* Initialise the compilation unit. */
	cu->cu_length = (uint64_t)length;
  8004203ee5:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004203ee8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203eec:	48 89 10             	mov    %rdx,(%rax)

	cu->cu_length_size   = (dwarf_size == 4 ? 4 : 12);
  8004203eef:	80 7d fb 04          	cmpb   $0x4,-0x5(%rbp)
  8004203ef3:	75 07                	jne    8004203efc <_get_next_cu+0xdf>
  8004203ef5:	ba 04 00 00 00       	mov    $0x4,%edx
  8004203efa:	eb 05                	jmp    8004203f01 <_get_next_cu+0xe4>
  8004203efc:	ba 0c 00 00 00       	mov    $0xc,%edx
  8004203f01:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f05:	88 50 18             	mov    %dl,0x18(%rax)
	cu->version              = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, 2);
  8004203f08:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203f0c:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004203f10:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203f14:	48 8b 52 08          	mov    0x8(%rdx),%rdx
  8004203f18:	48 89 d7             	mov    %rdx,%rdi
  8004203f1b:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203f1f:	ba 02 00 00 00       	mov    $0x2,%edx
  8004203f24:	48 89 ce             	mov    %rcx,%rsi
  8004203f27:	ff d0                	callq  *%rax
  8004203f29:	89 c2                	mov    %eax,%edx
  8004203f2b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f2f:	66 89 50 08          	mov    %dx,0x8(%rax)
	cu->debug_abbrev_offset  = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, dwarf_size);
  8004203f33:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203f37:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004203f3b:	0f b6 55 fb          	movzbl -0x5(%rbp),%edx
  8004203f3f:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004203f43:	48 8b 49 08          	mov    0x8(%rcx),%rcx
  8004203f47:	48 89 cf             	mov    %rcx,%rdi
  8004203f4a:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203f4e:	48 89 ce             	mov    %rcx,%rsi
  8004203f51:	ff d0                	callq  *%rax
  8004203f53:	48 89 c2             	mov    %rax,%rdx
  8004203f56:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f5a:	48 89 50 10          	mov    %rdx,0x10(%rax)
	//cu->cu_abbrev_offset_cur = cu->cu_abbrev_offset;
	cu->addr_size  = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, 1);
  8004203f5e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203f62:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004203f66:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203f6a:	48 8b 52 08          	mov    0x8(%rdx),%rdx
  8004203f6e:	48 89 d7             	mov    %rdx,%rdi
  8004203f71:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203f75:	ba 01 00 00 00       	mov    $0x1,%edx
  8004203f7a:	48 89 ce             	mov    %rcx,%rsi
  8004203f7d:	ff d0                	callq  *%rax
  8004203f7f:	89 c2                	mov    %eax,%edx
  8004203f81:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f85:	88 50 0a             	mov    %dl,0xa(%rax)

	if (cu->version < 2 || cu->version > 4) {
  8004203f88:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f8c:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8004203f90:	66 83 f8 01          	cmp    $0x1,%ax
  8004203f94:	76 0e                	jbe    8004203fa4 <_get_next_cu+0x187>
  8004203f96:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f9a:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8004203f9e:	66 83 f8 04          	cmp    $0x4,%ax
  8004203fa2:	76 07                	jbe    8004203fab <_get_next_cu+0x18e>
		return -1;
  8004203fa4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004203fa9:	eb 11                	jmp    8004203fbc <_get_next_cu+0x19f>
	}

	cu->cu_die_offset = offset;
  8004203fab:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203faf:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203fb3:	48 89 50 28          	mov    %rdx,0x28(%rax)

	return 0;
  8004203fb7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004203fbc:	c9                   	leaveq 
  8004203fbd:	c3                   	retq   

0000008004203fbe <print_cu>:

void print_cu(Dwarf_CU cu)
{
  8004203fbe:	55                   	push   %rbp
  8004203fbf:	48 89 e5             	mov    %rsp,%rbp
	cprintf("%ld---%du--%d\n",cu.cu_length,cu.version,cu.addr_size);
  8004203fc2:	0f b6 45 1a          	movzbl 0x1a(%rbp),%eax
  8004203fc6:	0f b6 c8             	movzbl %al,%ecx
  8004203fc9:	0f b7 45 18          	movzwl 0x18(%rbp),%eax
  8004203fcd:	0f b7 d0             	movzwl %ax,%edx
  8004203fd0:	48 8b 45 10          	mov    0x10(%rbp),%rax
  8004203fd4:	48 89 c6             	mov    %rax,%rsi
  8004203fd7:	48 bf 32 9d 20 04 80 	movabs $0x8004209d32,%rdi
  8004203fde:	00 00 00 
  8004203fe1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203fe6:	49 b8 29 14 20 04 80 	movabs $0x8004201429,%r8
  8004203fed:	00 00 00 
  8004203ff0:	41 ff d0             	callq  *%r8
}
  8004203ff3:	90                   	nop
  8004203ff4:	5d                   	pop    %rbp
  8004203ff5:	c3                   	retq   

0000008004203ff6 <_dwarf_abbrev_parse>:

//Return 0 on success
int
_dwarf_abbrev_parse(Dwarf_Debug dbg, Dwarf_CU cu, Dwarf_Unsigned *offset,
		    Dwarf_Abbrev *abp, Dwarf_Section *ds)
{
  8004203ff6:	55                   	push   %rbp
  8004203ff7:	48 89 e5             	mov    %rsp,%rbp
  8004203ffa:	48 83 ec 60          	sub    $0x60,%rsp
  8004203ffe:	48 89 7d b8          	mov    %rdi,-0x48(%rbp)
  8004204002:	48 89 75 b0          	mov    %rsi,-0x50(%rbp)
  8004204006:	48 89 55 a8          	mov    %rdx,-0x58(%rbp)
  800420400a:	48 89 4d a0          	mov    %rcx,-0x60(%rbp)
	uint64_t tag;
	uint8_t children;
	uint64_t abbr_addr;
	int ret;

	assert(abp != NULL);
  800420400e:	48 83 7d a8 00       	cmpq   $0x0,-0x58(%rbp)
  8004204013:	75 35                	jne    800420404a <_dwarf_abbrev_parse+0x54>
  8004204015:	48 b9 41 9d 20 04 80 	movabs $0x8004209d41,%rcx
  800420401c:	00 00 00 
  800420401f:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204026:	00 00 00 
  8004204029:	be a4 01 00 00       	mov    $0x1a4,%esi
  800420402e:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204035:	00 00 00 
  8004204038:	b8 00 00 00 00       	mov    $0x0,%eax
  800420403d:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204044:	00 00 00 
  8004204047:	41 ff d0             	callq  *%r8
	assert(ds != NULL);
  800420404a:	48 83 7d a0 00       	cmpq   $0x0,-0x60(%rbp)
  800420404f:	75 35                	jne    8004204086 <_dwarf_abbrev_parse+0x90>
  8004204051:	48 b9 4d 9d 20 04 80 	movabs $0x8004209d4d,%rcx
  8004204058:	00 00 00 
  800420405b:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204062:	00 00 00 
  8004204065:	be a5 01 00 00       	mov    $0x1a5,%esi
  800420406a:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204071:	00 00 00 
  8004204074:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204079:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204080:	00 00 00 
  8004204083:	41 ff d0             	callq  *%r8

	if (*offset >= ds->ds_size)
  8004204086:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420408a:	48 8b 10             	mov    (%rax),%rdx
  800420408d:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004204091:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204095:	48 39 c2             	cmp    %rax,%rdx
  8004204098:	72 0a                	jb     80042040a4 <_dwarf_abbrev_parse+0xae>
        	return (DW_DLE_NO_ENTRY);
  800420409a:	b8 04 00 00 00       	mov    $0x4,%eax
  800420409f:	e9 d3 01 00 00       	jmpq   8004204277 <_dwarf_abbrev_parse+0x281>

	aboff = *offset;
  80042040a4:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042040a8:	48 8b 00             	mov    (%rax),%rax
  80042040ab:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

	abbr_addr = (uint64_t)ds->ds_data; //(uint64_t)((uint8_t *)elf_base_ptr + ds->sh_offset);
  80042040af:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042040b3:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042040b7:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	entry = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  80042040bb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042040bf:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042040c3:	48 89 d6             	mov    %rdx,%rsi
  80042040c6:	48 89 c7             	mov    %rax,%rdi
  80042040c9:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  80042040d0:	00 00 00 
  80042040d3:	ff d0                	callq  *%rax
  80042040d5:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	if (entry == 0) {
  80042040d9:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80042040de:	75 15                	jne    80042040f5 <_dwarf_abbrev_parse+0xff>
		/* Last entry. */
		//Need to make connection from below function
		abp->ab_entry = 0;
  80042040e0:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042040e4:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
		return DW_DLE_NONE;
  80042040eb:	b8 00 00 00 00       	mov    $0x0,%eax
  80042040f0:	e9 82 01 00 00       	jmpq   8004204277 <_dwarf_abbrev_parse+0x281>
	}

	tag = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  80042040f5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042040f9:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042040fd:	48 89 d6             	mov    %rdx,%rsi
  8004204100:	48 89 c7             	mov    %rax,%rdi
  8004204103:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  800420410a:	00 00 00 
  800420410d:	ff d0                	callq  *%rax
  800420410f:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	children = dbg->read((uint8_t *)abbr_addr, offset, 1);
  8004204113:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004204117:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420411b:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  800420411f:	48 8b 75 b0          	mov    -0x50(%rbp),%rsi
  8004204123:	ba 01 00 00 00       	mov    $0x1,%edx
  8004204128:	48 89 cf             	mov    %rcx,%rdi
  800420412b:	ff d0                	callq  *%rax
  800420412d:	88 45 df             	mov    %al,-0x21(%rbp)

	abp->ab_entry    = entry;
  8004204130:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204134:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004204138:	48 89 10             	mov    %rdx,(%rax)
	abp->ab_tag      = tag;
  800420413b:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420413f:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004204143:	48 89 50 08          	mov    %rdx,0x8(%rax)
	abp->ab_children = children;
  8004204147:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420414b:	0f b6 55 df          	movzbl -0x21(%rbp),%edx
  800420414f:	88 50 10             	mov    %dl,0x10(%rax)
	abp->ab_offset   = aboff;
  8004204152:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204156:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420415a:	48 89 50 18          	mov    %rdx,0x18(%rax)
	abp->ab_length   = 0;    /* fill in later. */
  800420415e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204162:	48 c7 40 20 00 00 00 	movq   $0x0,0x20(%rax)
  8004204169:	00 
	abp->ab_atnum    = 0;
  800420416a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420416e:	48 c7 40 28 00 00 00 	movq   $0x0,0x28(%rax)
  8004204175:	00 

	/* Parse attribute definitions. */
	do {
		adoff = *offset;
  8004204176:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420417a:	48 8b 00             	mov    (%rax),%rax
  800420417d:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
		attr = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  8004204181:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004204185:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  8004204189:	48 89 d6             	mov    %rdx,%rsi
  800420418c:	48 89 c7             	mov    %rax,%rdi
  800420418f:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004204196:	00 00 00 
  8004204199:	ff d0                	callq  *%rax
  800420419b:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
		form = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  800420419f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042041a3:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042041a7:	48 89 d6             	mov    %rdx,%rsi
  80042041aa:	48 89 c7             	mov    %rax,%rdi
  80042041ad:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  80042041b4:	00 00 00 
  80042041b7:	ff d0                	callq  *%rax
  80042041b9:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
		if (attr != 0)
  80042041bd:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  80042041c2:	0f 84 89 00 00 00    	je     8004204251 <_dwarf_abbrev_parse+0x25b>
		{
			/* Initialise the attribute definition structure. */
			abp->ab_attrdef[abp->ab_atnum].ad_attrib = attr;
  80042041c8:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042041cc:	48 8b 50 28          	mov    0x28(%rax),%rdx
  80042041d0:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  80042041d4:	48 89 d0             	mov    %rdx,%rax
  80042041d7:	48 01 c0             	add    %rax,%rax
  80042041da:	48 01 d0             	add    %rdx,%rax
  80042041dd:	48 c1 e0 03          	shl    $0x3,%rax
  80042041e1:	48 01 c8             	add    %rcx,%rax
  80042041e4:	48 8d 50 30          	lea    0x30(%rax),%rdx
  80042041e8:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042041ec:	48 89 02             	mov    %rax,(%rdx)
			abp->ab_attrdef[abp->ab_atnum].ad_form   = form;
  80042041ef:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042041f3:	48 8b 50 28          	mov    0x28(%rax),%rdx
  80042041f7:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  80042041fb:	48 89 d0             	mov    %rdx,%rax
  80042041fe:	48 01 c0             	add    %rax,%rax
  8004204201:	48 01 d0             	add    %rdx,%rax
  8004204204:	48 c1 e0 03          	shl    $0x3,%rax
  8004204208:	48 01 c8             	add    %rcx,%rax
  800420420b:	48 8d 50 38          	lea    0x38(%rax),%rdx
  800420420f:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204213:	48 89 02             	mov    %rax,(%rdx)
			abp->ab_attrdef[abp->ab_atnum].ad_offset = adoff;
  8004204216:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420421a:	48 8b 50 28          	mov    0x28(%rax),%rdx
  800420421e:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8004204222:	48 89 d0             	mov    %rdx,%rax
  8004204225:	48 01 c0             	add    %rax,%rax
  8004204228:	48 01 d0             	add    %rdx,%rax
  800420422b:	48 c1 e0 03          	shl    $0x3,%rax
  800420422f:	48 01 c8             	add    %rcx,%rax
  8004204232:	48 8d 50 40          	lea    0x40(%rax),%rdx
  8004204236:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420423a:	48 89 02             	mov    %rax,(%rdx)
			abp->ab_atnum++;
  800420423d:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204241:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004204245:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004204249:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420424d:	48 89 50 28          	mov    %rdx,0x28(%rax)
		}
	} while (attr != 0);
  8004204251:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004204256:	0f 85 1a ff ff ff    	jne    8004204176 <_dwarf_abbrev_parse+0x180>

	//(*abp)->ab_length = *offset - aboff;
	abp->ab_length = (uint64_t)(*offset - aboff);
  800420425c:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004204260:	48 8b 00             	mov    (%rax),%rax
  8004204263:	48 2b 45 f8          	sub    -0x8(%rbp),%rax
  8004204267:	48 89 c2             	mov    %rax,%rdx
  800420426a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420426e:	48 89 50 20          	mov    %rdx,0x20(%rax)

	return DW_DLV_OK;
  8004204272:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004204277:	c9                   	leaveq 
  8004204278:	c3                   	retq   

0000008004204279 <_dwarf_abbrev_find>:

//Return 0 on success
int
_dwarf_abbrev_find(Dwarf_Debug dbg, Dwarf_CU cu, uint64_t entry, Dwarf_Abbrev *abp)
{
  8004204279:	55                   	push   %rbp
  800420427a:	48 89 e5             	mov    %rsp,%rbp
  800420427d:	48 83 ec 40          	sub    $0x40,%rsp
  8004204281:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004204285:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8004204289:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
	Dwarf_Section *ds;
	uint64_t offset;
	int ret;

	if (entry == 0)
  800420428d:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  8004204292:	75 0a                	jne    800420429e <_dwarf_abbrev_find+0x25>
	{
		return (DW_DLE_NO_ENTRY);
  8004204294:	b8 04 00 00 00       	mov    $0x4,%eax
  8004204299:	e9 e3 00 00 00       	jmpq   8004204381 <_dwarf_abbrev_find+0x108>
	}

	/* Load and search the abbrev table. */
	ds = _dwarf_find_section(".debug_abbrev");
  800420429e:	48 bf 58 9d 20 04 80 	movabs $0x8004209d58,%rdi
  80042042a5:	00 00 00 
  80042042a8:	48 b8 1b 85 20 04 80 	movabs $0x800420851b,%rax
  80042042af:	00 00 00 
  80042042b2:	ff d0                	callq  *%rax
  80042042b4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	assert(ds != NULL);
  80042042b8:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  80042042bd:	75 35                	jne    80042042f4 <_dwarf_abbrev_find+0x7b>
  80042042bf:	48 b9 4d 9d 20 04 80 	movabs $0x8004209d4d,%rcx
  80042042c6:	00 00 00 
  80042042c9:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  80042042d0:	00 00 00 
  80042042d3:	be e5 01 00 00       	mov    $0x1e5,%esi
  80042042d8:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  80042042df:	00 00 00 
  80042042e2:	b8 00 00 00 00       	mov    $0x0,%eax
  80042042e7:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042042ee:	00 00 00 
  80042042f1:	41 ff d0             	callq  *%r8

	//TODO: We are starting offset from 0, however libdwarf logic
	//      is keeping a counter for current offset. Ok. let use
	//      that. I relent, but this will be done in Phase 2. :)
	//offset = 0; //cu->cu_abbrev_offset_cur;
	offset = cu.debug_abbrev_offset; //cu->cu_abbrev_offset_cur;
  80042042f4:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042042f8:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	while (offset < ds->ds_size) {
  80042042fc:	eb 6a                	jmp    8004204368 <_dwarf_abbrev_find+0xef>
		ret = _dwarf_abbrev_parse(dbg, cu, &offset, abp, ds);
  80042042fe:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
  8004204302:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004204306:	48 8d 75 e8          	lea    -0x18(%rbp),%rsi
  800420430a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420430e:	48 83 ec 08          	sub    $0x8,%rsp
  8004204312:	ff 75 40             	pushq  0x40(%rbp)
  8004204315:	ff 75 38             	pushq  0x38(%rbp)
  8004204318:	ff 75 30             	pushq  0x30(%rbp)
  800420431b:	ff 75 28             	pushq  0x28(%rbp)
  800420431e:	ff 75 20             	pushq  0x20(%rbp)
  8004204321:	ff 75 18             	pushq  0x18(%rbp)
  8004204324:	ff 75 10             	pushq  0x10(%rbp)
  8004204327:	48 89 c7             	mov    %rax,%rdi
  800420432a:	48 b8 f6 3f 20 04 80 	movabs $0x8004203ff6,%rax
  8004204331:	00 00 00 
  8004204334:	ff d0                	callq  *%rax
  8004204336:	48 83 c4 40          	add    $0x40,%rsp
  800420433a:	89 45 f4             	mov    %eax,-0xc(%rbp)
		if (ret != DW_DLE_NONE)
  800420433d:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8004204341:	74 05                	je     8004204348 <_dwarf_abbrev_find+0xcf>
			return (ret);
  8004204343:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004204346:	eb 39                	jmp    8004204381 <_dwarf_abbrev_find+0x108>
		if (abp->ab_entry == entry) {
  8004204348:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420434c:	48 8b 00             	mov    (%rax),%rax
  800420434f:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004204353:	75 07                	jne    800420435c <_dwarf_abbrev_find+0xe3>
			//cu->cu_abbrev_offset_cur = offset;
			return DW_DLE_NONE;
  8004204355:	b8 00 00 00 00       	mov    $0x0,%eax
  800420435a:	eb 25                	jmp    8004204381 <_dwarf_abbrev_find+0x108>
		}
		if (abp->ab_entry == 0) {
  800420435c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004204360:	48 8b 00             	mov    (%rax),%rax
  8004204363:	48 85 c0             	test   %rax,%rax
  8004204366:	74 13                	je     800420437b <_dwarf_abbrev_find+0x102>
	while (offset < ds->ds_size) {
  8004204368:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420436c:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004204370:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204374:	48 39 c2             	cmp    %rax,%rdx
  8004204377:	77 85                	ja     80042042fe <_dwarf_abbrev_find+0x85>
  8004204379:	eb 01                	jmp    800420437c <_dwarf_abbrev_find+0x103>
			//cu->cu_abbrev_offset_cur = offset;
			//cu->cu_abbrev_loaded = 1;
			break;
  800420437b:	90                   	nop
		}
	}

	return DW_DLE_NO_ENTRY;
  800420437c:	b8 04 00 00 00       	mov    $0x4,%eax
}
  8004204381:	c9                   	leaveq 
  8004204382:	c3                   	retq   

0000008004204383 <_dwarf_attr_init>:

//Return 0 on success
int
_dwarf_attr_init(Dwarf_Debug dbg, uint64_t *offsetp, Dwarf_CU *cu, Dwarf_Die *ret_die, Dwarf_AttrDef *ad,
		 uint64_t form, int indirect)
{
  8004204383:	55                   	push   %rbp
  8004204384:	48 89 e5             	mov    %rsp,%rbp
  8004204387:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  800420438e:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  8004204395:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  800420439c:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  80042043a3:	48 89 8d 50 ff ff ff 	mov    %rcx,-0xb0(%rbp)
  80042043aa:	4c 89 85 48 ff ff ff 	mov    %r8,-0xb8(%rbp)
  80042043b1:	4c 89 8d 40 ff ff ff 	mov    %r9,-0xc0(%rbp)
	struct _Dwarf_Attribute atref;
	Dwarf_Section *str;
	int ret;
	Dwarf_Section *ds = _dwarf_find_section(".debug_info");
  80042043b8:	48 bf 66 9d 20 04 80 	movabs $0x8004209d66,%rdi
  80042043bf:	00 00 00 
  80042043c2:	48 b8 1b 85 20 04 80 	movabs $0x800420851b,%rax
  80042043c9:	00 00 00 
  80042043cc:	ff d0                	callq  *%rax
  80042043ce:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	uint8_t *ds_data = (uint8_t *)ds->ds_data; //(uint8_t *)dbg->dbg_info_offset_elf;
  80042043d2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042043d6:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042043da:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	uint8_t dwarf_size = cu->cu_dwarf_size;
  80042043de:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  80042043e5:	0f b6 40 19          	movzbl 0x19(%rax),%eax
  80042043e9:	88 45 e7             	mov    %al,-0x19(%rbp)

	ret = DW_DLE_NONE;
  80042043ec:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	memset(&atref, 0, sizeof(atref));
  80042043f3:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  80042043fa:	ba 60 00 00 00       	mov    $0x60,%edx
  80042043ff:	be 00 00 00 00       	mov    $0x0,%esi
  8004204404:	48 89 c7             	mov    %rax,%rdi
  8004204407:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  800420440e:	00 00 00 
  8004204411:	ff d0                	callq  *%rax
	atref.at_die = ret_die;
  8004204413:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  800420441a:	48 89 85 70 ff ff ff 	mov    %rax,-0x90(%rbp)
	atref.at_attrib = ad->ad_attrib;
  8004204421:	48 8b 85 48 ff ff ff 	mov    -0xb8(%rbp),%rax
  8004204428:	48 8b 00             	mov    (%rax),%rax
  800420442b:	48 89 45 80          	mov    %rax,-0x80(%rbp)
	atref.at_form = ad->ad_form;
  800420442f:	48 8b 85 48 ff ff ff 	mov    -0xb8(%rbp),%rax
  8004204436:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420443a:	48 89 45 88          	mov    %rax,-0x78(%rbp)
	atref.at_indirect = indirect;
  800420443e:	8b 45 10             	mov    0x10(%rbp),%eax
  8004204441:	89 45 90             	mov    %eax,-0x70(%rbp)
	atref.at_ld = NULL;
  8004204444:	48 c7 45 b8 00 00 00 	movq   $0x0,-0x48(%rbp)
  800420444b:	00 

	switch (form) {
  800420444c:	48 83 bd 40 ff ff ff 	cmpq   $0x20,-0xc0(%rbp)
  8004204453:	20 
  8004204454:	0f 87 87 04 00 00    	ja     80042048e1 <_dwarf_attr_init+0x55e>
  800420445a:	48 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%rax
  8004204461:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  8004204468:	00 
  8004204469:	48 b8 90 9d 20 04 80 	movabs $0x8004209d90,%rax
  8004204470:	00 00 00 
  8004204473:	48 01 d0             	add    %rdx,%rax
  8004204476:	48 8b 00             	mov    (%rax),%rax
  8004204479:	ff e0                	jmpq   *%rax
	case DW_FORM_addr:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, cu->addr_size);
  800420447b:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204482:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204486:	48 8b 95 58 ff ff ff 	mov    -0xa8(%rbp),%rdx
  800420448d:	0f b6 52 0a          	movzbl 0xa(%rdx),%edx
  8004204491:	0f b6 d2             	movzbl %dl,%edx
  8004204494:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  800420449b:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420449f:	48 89 cf             	mov    %rcx,%rdi
  80042044a2:	ff d0                	callq  *%rax
  80042044a4:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  80042044a8:	e9 3e 04 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_block:
	case DW_FORM_exprloc:
		atref.u[0].u64 = _dwarf_read_uleb128(ds_data, offsetp);
  80042044ad:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  80042044b4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042044b8:	48 89 d6             	mov    %rdx,%rsi
  80042044bb:	48 89 c7             	mov    %rax,%rdi
  80042044be:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  80042044c5:	00 00 00 
  80042044c8:	ff d0                	callq  *%rax
  80042044ca:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  80042044ce:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  80042044d2:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042044d9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042044dd:	48 89 ce             	mov    %rcx,%rsi
  80042044e0:	48 89 c7             	mov    %rax,%rdi
  80042044e3:	48 b8 20 3c 20 04 80 	movabs $0x8004203c20,%rax
  80042044ea:	00 00 00 
  80042044ed:	ff d0                	callq  *%rax
  80042044ef:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
		break;
  80042044f3:	e9 f3 03 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_block1:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 1);
  80042044f8:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042044ff:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204503:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  800420450a:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420450e:	ba 01 00 00 00       	mov    $0x1,%edx
  8004204513:	48 89 cf             	mov    %rcx,%rdi
  8004204516:	ff d0                	callq  *%rax
  8004204518:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  800420451c:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  8004204520:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204527:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420452b:	48 89 ce             	mov    %rcx,%rsi
  800420452e:	48 89 c7             	mov    %rax,%rdi
  8004204531:	48 b8 20 3c 20 04 80 	movabs $0x8004203c20,%rax
  8004204538:	00 00 00 
  800420453b:	ff d0                	callq  *%rax
  800420453d:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
		break;
  8004204541:	e9 a5 03 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_block2:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 2);
  8004204546:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420454d:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204551:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  8004204558:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420455c:	ba 02 00 00 00       	mov    $0x2,%edx
  8004204561:	48 89 cf             	mov    %rcx,%rdi
  8004204564:	ff d0                	callq  *%rax
  8004204566:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  800420456a:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  800420456e:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204575:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204579:	48 89 ce             	mov    %rcx,%rsi
  800420457c:	48 89 c7             	mov    %rax,%rdi
  800420457f:	48 b8 20 3c 20 04 80 	movabs $0x8004203c20,%rax
  8004204586:	00 00 00 
  8004204589:	ff d0                	callq  *%rax
  800420458b:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
		break;
  800420458f:	e9 57 03 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_block4:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 4);
  8004204594:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420459b:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420459f:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  80042045a6:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  80042045aa:	ba 04 00 00 00       	mov    $0x4,%edx
  80042045af:	48 89 cf             	mov    %rcx,%rdi
  80042045b2:	ff d0                	callq  *%rax
  80042045b4:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  80042045b8:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  80042045bc:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042045c3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042045c7:	48 89 ce             	mov    %rcx,%rsi
  80042045ca:	48 89 c7             	mov    %rax,%rdi
  80042045cd:	48 b8 20 3c 20 04 80 	movabs $0x8004203c20,%rax
  80042045d4:	00 00 00 
  80042045d7:	ff d0                	callq  *%rax
  80042045d9:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
		break;
  80042045dd:	e9 09 03 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_data1:
	case DW_FORM_flag:
	case DW_FORM_ref1:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 1);
  80042045e2:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042045e9:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042045ed:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  80042045f4:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  80042045f8:	ba 01 00 00 00       	mov    $0x1,%edx
  80042045fd:	48 89 cf             	mov    %rcx,%rdi
  8004204600:	ff d0                	callq  *%rax
  8004204602:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  8004204606:	e9 e0 02 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_data2:
	case DW_FORM_ref2:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 2);
  800420460b:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204612:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204616:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  800420461d:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204621:	ba 02 00 00 00       	mov    $0x2,%edx
  8004204626:	48 89 cf             	mov    %rcx,%rdi
  8004204629:	ff d0                	callq  *%rax
  800420462b:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  800420462f:	e9 b7 02 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_data4:
	case DW_FORM_ref4:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 4);
  8004204634:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420463b:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420463f:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  8004204646:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420464a:	ba 04 00 00 00       	mov    $0x4,%edx
  800420464f:	48 89 cf             	mov    %rcx,%rdi
  8004204652:	ff d0                	callq  *%rax
  8004204654:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  8004204658:	e9 8e 02 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_data8:
	case DW_FORM_ref8:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, 8);
  800420465d:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204664:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204668:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  800420466f:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204673:	ba 08 00 00 00       	mov    $0x8,%edx
  8004204678:	48 89 cf             	mov    %rcx,%rdi
  800420467b:	ff d0                	callq  *%rax
  800420467d:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  8004204681:	e9 65 02 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_indirect:
		form = _dwarf_read_uleb128(ds_data, offsetp);
  8004204686:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  800420468d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204691:	48 89 d6             	mov    %rdx,%rsi
  8004204694:	48 89 c7             	mov    %rax,%rdi
  8004204697:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  800420469e:	00 00 00 
  80042046a1:	ff d0                	callq  *%rax
  80042046a3:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
		return (_dwarf_attr_init(dbg, offsetp, cu, ret_die, ad, form, 1));
  80042046aa:	4c 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%r8
  80042046b1:	48 8b bd 48 ff ff ff 	mov    -0xb8(%rbp),%rdi
  80042046b8:	48 8b 8d 50 ff ff ff 	mov    -0xb0(%rbp),%rcx
  80042046bf:	48 8b 95 58 ff ff ff 	mov    -0xa8(%rbp),%rdx
  80042046c6:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  80042046cd:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042046d4:	48 83 ec 08          	sub    $0x8,%rsp
  80042046d8:	6a 01                	pushq  $0x1
  80042046da:	4d 89 c1             	mov    %r8,%r9
  80042046dd:	49 89 f8             	mov    %rdi,%r8
  80042046e0:	48 89 c7             	mov    %rax,%rdi
  80042046e3:	48 b8 83 43 20 04 80 	movabs $0x8004204383,%rax
  80042046ea:	00 00 00 
  80042046ed:	ff d0                	callq  *%rax
  80042046ef:	48 83 c4 10          	add    $0x10,%rsp
  80042046f3:	e9 23 03 00 00       	jmpq   8004204a1b <_dwarf_attr_init+0x698>
	case DW_FORM_ref_addr:
		if (cu->version == 2)
  80042046f8:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  80042046ff:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8004204703:	66 83 f8 02          	cmp    $0x2,%ax
  8004204707:	75 32                	jne    800420473b <_dwarf_attr_init+0x3b8>
			atref.u[0].u64 = dbg->read(ds_data, offsetp, cu->addr_size);
  8004204709:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204710:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204714:	48 8b 95 58 ff ff ff 	mov    -0xa8(%rbp),%rdx
  800420471b:	0f b6 52 0a          	movzbl 0xa(%rdx),%edx
  800420471f:	0f b6 d2             	movzbl %dl,%edx
  8004204722:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  8004204729:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420472d:	48 89 cf             	mov    %rcx,%rdi
  8004204730:	ff d0                	callq  *%rax
  8004204732:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		else if (cu->version == 3)
			atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
		break;
  8004204736:	e9 af 01 00 00       	jmpq   80042048ea <_dwarf_attr_init+0x567>
		else if (cu->version == 3)
  800420473b:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  8004204742:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8004204746:	66 83 f8 03          	cmp    $0x3,%ax
  800420474a:	0f 85 9a 01 00 00    	jne    80042048ea <_dwarf_attr_init+0x567>
			atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
  8004204750:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204757:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420475b:	0f b6 55 e7          	movzbl -0x19(%rbp),%edx
  800420475f:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  8004204766:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420476a:	48 89 cf             	mov    %rcx,%rdi
  800420476d:	ff d0                	callq  *%rax
  800420476f:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  8004204773:	e9 72 01 00 00       	jmpq   80042048ea <_dwarf_attr_init+0x567>
	case DW_FORM_ref_udata:
	case DW_FORM_udata:
		atref.u[0].u64 = _dwarf_read_uleb128(ds_data, offsetp);
  8004204778:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  800420477f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204783:	48 89 d6             	mov    %rdx,%rsi
  8004204786:	48 89 c7             	mov    %rax,%rdi
  8004204789:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004204790:	00 00 00 
  8004204793:	ff d0                	callq  *%rax
  8004204795:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  8004204799:	e9 4d 01 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_sdata:
		atref.u[0].s64 = _dwarf_read_sleb128(ds_data, offsetp);
  800420479e:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  80042047a5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042047a9:	48 89 d6             	mov    %rdx,%rsi
  80042047ac:	48 89 c7             	mov    %rax,%rdi
  80042047af:	48 b8 6f 39 20 04 80 	movabs $0x800420396f,%rax
  80042047b6:	00 00 00 
  80042047b9:	ff d0                	callq  *%rax
  80042047bb:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  80042047bf:	e9 27 01 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_sec_offset:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
  80042047c4:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042047cb:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042047cf:	0f b6 55 e7          	movzbl -0x19(%rbp),%edx
  80042047d3:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  80042047da:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  80042047de:	48 89 cf             	mov    %rcx,%rdi
  80042047e1:	ff d0                	callq  *%rax
  80042047e3:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  80042047e7:	e9 ff 00 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_string:
		atref.u[0].s =(char*) _dwarf_read_string(ds_data, (uint64_t)ds->ds_size, offsetp);
  80042047ec:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042047f0:	48 8b 48 18          	mov    0x18(%rax),%rcx
  80042047f4:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  80042047fb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042047ff:	48 89 ce             	mov    %rcx,%rsi
  8004204802:	48 89 c7             	mov    %rax,%rdi
  8004204805:	48 b8 91 3b 20 04 80 	movabs $0x8004203b91,%rax
  800420480c:	00 00 00 
  800420480f:	ff d0                	callq  *%rax
  8004204811:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		break;
  8004204815:	e9 d1 00 00 00       	jmpq   80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_strp:
		atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
  800420481a:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204821:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204825:	0f b6 55 e7          	movzbl -0x19(%rbp),%edx
  8004204829:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  8004204830:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204834:	48 89 cf             	mov    %rcx,%rdi
  8004204837:	ff d0                	callq  *%rax
  8004204839:	48 89 45 98          	mov    %rax,-0x68(%rbp)
		str = _dwarf_find_section(".debug_str");
  800420483d:	48 bf 72 9d 20 04 80 	movabs $0x8004209d72,%rdi
  8004204844:	00 00 00 
  8004204847:	48 b8 1b 85 20 04 80 	movabs $0x800420851b,%rax
  800420484e:	00 00 00 
  8004204851:	ff d0                	callq  *%rax
  8004204853:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
		assert(str != NULL);
  8004204857:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  800420485c:	75 35                	jne    8004204893 <_dwarf_attr_init+0x510>
  800420485e:	48 b9 7d 9d 20 04 80 	movabs $0x8004209d7d,%rcx
  8004204865:	00 00 00 
  8004204868:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  800420486f:	00 00 00 
  8004204872:	be 51 02 00 00       	mov    $0x251,%esi
  8004204877:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  800420487e:	00 00 00 
  8004204881:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204886:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  800420488d:	00 00 00 
  8004204890:	41 ff d0             	callq  *%r8
		//atref.u[1].s = (char *)(elf_base_ptr + str->sh_offset) + atref.u[0].u64;
		atref.u[1].s = (char *)str->ds_data + atref.u[0].u64;
  8004204893:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004204897:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800420489b:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420489f:	48 01 d0             	add    %rdx,%rax
  80042048a2:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
		break;
  80042048a6:	eb 43                	jmp    80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_ref_sig8:
		atref.u[0].u64 = 8;
  80042048a8:	48 c7 45 98 08 00 00 	movq   $0x8,-0x68(%rbp)
  80042048af:	00 
		atref.u[1].u8p = (uint8_t*)(_dwarf_read_block(ds_data, offsetp, atref.u[0].u64));
  80042048b0:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  80042048b4:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042048bb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042048bf:	48 89 ce             	mov    %rcx,%rsi
  80042048c2:	48 89 c7             	mov    %rax,%rdi
  80042048c5:	48 b8 20 3c 20 04 80 	movabs $0x8004203c20,%rax
  80042048cc:	00 00 00 
  80042048cf:	ff d0                	callq  *%rax
  80042048d1:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
		break;
  80042048d5:	eb 14                	jmp    80042048eb <_dwarf_attr_init+0x568>
	case DW_FORM_flag_present:
		/* This form has no value encoded in the DIE. */
		atref.u[0].u64 = 1;
  80042048d7:	48 c7 45 98 01 00 00 	movq   $0x1,-0x68(%rbp)
  80042048de:	00 
		break;
  80042048df:	eb 0a                	jmp    80042048eb <_dwarf_attr_init+0x568>
	default:
		//DWARF_SET_ERROR(dbg, error, DW_DLE_ATTR_FORM_BAD);
		ret = DW_DLE_ATTR_FORM_BAD;
  80042048e1:	c7 45 fc 0e 00 00 00 	movl   $0xe,-0x4(%rbp)
		break;
  80042048e8:	eb 01                	jmp    80042048eb <_dwarf_attr_init+0x568>
		break;
  80042048ea:	90                   	nop
	}

	if (ret == DW_DLE_NONE) {
  80042048eb:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80042048ef:	0f 85 23 01 00 00    	jne    8004204a18 <_dwarf_attr_init+0x695>
		if (form == DW_FORM_block || form == DW_FORM_block1 ||
  80042048f5:	48 83 bd 40 ff ff ff 	cmpq   $0x9,-0xc0(%rbp)
  80042048fc:	09 
  80042048fd:	74 1e                	je     800420491d <_dwarf_attr_init+0x59a>
  80042048ff:	48 83 bd 40 ff ff ff 	cmpq   $0xa,-0xc0(%rbp)
  8004204906:	0a 
  8004204907:	74 14                	je     800420491d <_dwarf_attr_init+0x59a>
  8004204909:	48 83 bd 40 ff ff ff 	cmpq   $0x3,-0xc0(%rbp)
  8004204910:	03 
  8004204911:	74 0a                	je     800420491d <_dwarf_attr_init+0x59a>
		    form == DW_FORM_block2 || form == DW_FORM_block4) {
  8004204913:	48 83 bd 40 ff ff ff 	cmpq   $0x4,-0xc0(%rbp)
  800420491a:	04 
  800420491b:	75 10                	jne    800420492d <_dwarf_attr_init+0x5aa>
			atref.at_block.bl_len = atref.u[0].u64;
  800420491d:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004204921:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
			atref.at_block.bl_data = atref.u[1].u8p;
  8004204925:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004204929:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
		}
		//ret = _dwarf_attr_add(die, &atref, NULL, error);
		if (atref.at_attrib == DW_AT_name) {
  800420492d:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  8004204931:	48 83 f8 03          	cmp    $0x3,%rax
  8004204935:	75 3a                	jne    8004204971 <_dwarf_attr_init+0x5ee>
			switch (atref.at_form) {
  8004204937:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  800420493b:	48 83 f8 08          	cmp    $0x8,%rax
  800420493f:	74 1c                	je     800420495d <_dwarf_attr_init+0x5da>
  8004204941:	48 83 f8 0e          	cmp    $0xe,%rax
  8004204945:	74 02                	je     8004204949 <_dwarf_attr_init+0x5c6>
				break;
			case DW_FORM_string:
				ret_die->die_name = atref.u[0].s;
				break;
			default:
				break;
  8004204947:	eb 29                	jmp    8004204972 <_dwarf_attr_init+0x5ef>
				ret_die->die_name = atref.u[1].s;
  8004204949:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800420494d:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  8004204954:	48 89 90 50 03 00 00 	mov    %rdx,0x350(%rax)
				break;
  800420495b:	eb 15                	jmp    8004204972 <_dwarf_attr_init+0x5ef>
				ret_die->die_name = atref.u[0].s;
  800420495d:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  8004204961:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  8004204968:	48 89 90 50 03 00 00 	mov    %rdx,0x350(%rax)
				break;
  800420496f:	eb 01                	jmp    8004204972 <_dwarf_attr_init+0x5ef>
			}
		}
  8004204971:	90                   	nop
		ret_die->die_attr[ret_die->die_attr_count++] = atref;
  8004204972:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  8004204979:	0f b6 80 58 03 00 00 	movzbl 0x358(%rax),%eax
  8004204980:	8d 48 01             	lea    0x1(%rax),%ecx
  8004204983:	48 8b 95 50 ff ff ff 	mov    -0xb0(%rbp),%rdx
  800420498a:	88 8a 58 03 00 00    	mov    %cl,0x358(%rdx)
  8004204990:	0f b6 c0             	movzbl %al,%eax
  8004204993:	48 8b 8d 50 ff ff ff 	mov    -0xb0(%rbp),%rcx
  800420499a:	48 63 d0             	movslq %eax,%rdx
  800420499d:	48 89 d0             	mov    %rdx,%rax
  80042049a0:	48 01 c0             	add    %rax,%rax
  80042049a3:	48 01 d0             	add    %rdx,%rax
  80042049a6:	48 c1 e0 05          	shl    $0x5,%rax
  80042049aa:	48 01 c8             	add    %rcx,%rax
  80042049ad:	48 05 70 03 00 00    	add    $0x370,%rax
  80042049b3:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  80042049ba:	48 8b 8d 78 ff ff ff 	mov    -0x88(%rbp),%rcx
  80042049c1:	48 89 10             	mov    %rdx,(%rax)
  80042049c4:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80042049c8:	48 8b 55 80          	mov    -0x80(%rbp),%rdx
  80042049cc:	48 8b 4d 88          	mov    -0x78(%rbp),%rcx
  80042049d0:	48 89 50 10          	mov    %rdx,0x10(%rax)
  80042049d4:	48 89 48 18          	mov    %rcx,0x18(%rax)
  80042049d8:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  80042049dc:	48 8b 4d 98          	mov    -0x68(%rbp),%rcx
  80042049e0:	48 89 50 20          	mov    %rdx,0x20(%rax)
  80042049e4:	48 89 48 28          	mov    %rcx,0x28(%rax)
  80042049e8:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80042049ec:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  80042049f0:	48 89 50 30          	mov    %rdx,0x30(%rax)
  80042049f4:	48 89 48 38          	mov    %rcx,0x38(%rax)
  80042049f8:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042049fc:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004204a00:	48 89 50 40          	mov    %rdx,0x40(%rax)
  8004204a04:	48 89 48 48          	mov    %rcx,0x48(%rax)
  8004204a08:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004204a0c:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  8004204a10:	48 89 50 50          	mov    %rdx,0x50(%rax)
  8004204a14:	48 89 48 58          	mov    %rcx,0x58(%rax)
	}

	return (ret);
  8004204a18:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004204a1b:	c9                   	leaveq 
  8004204a1c:	c3                   	retq   

0000008004204a1d <dwarf_search_die_within_cu>:

int
dwarf_search_die_within_cu(Dwarf_Debug dbg, Dwarf_CU cu, uint64_t offset, Dwarf_Die *ret_die, int search_sibling)
{
  8004204a1d:	55                   	push   %rbp
  8004204a1e:	48 89 e5             	mov    %rsp,%rbp
  8004204a21:	48 81 ec 90 03 00 00 	sub    $0x390,%rsp
  8004204a28:	48 89 bd 88 fc ff ff 	mov    %rdi,-0x378(%rbp)
  8004204a2f:	48 89 b5 80 fc ff ff 	mov    %rsi,-0x380(%rbp)
  8004204a36:	48 89 95 78 fc ff ff 	mov    %rdx,-0x388(%rbp)
  8004204a3d:	89 8d 74 fc ff ff    	mov    %ecx,-0x38c(%rbp)
	uint64_t abnum;
	uint64_t die_offset;
	int ret, level;
	int i;

	assert(dbg);
  8004204a43:	48 83 bd 88 fc ff ff 	cmpq   $0x0,-0x378(%rbp)
  8004204a4a:	00 
  8004204a4b:	75 35                	jne    8004204a82 <dwarf_search_die_within_cu+0x65>
  8004204a4d:	48 b9 98 9e 20 04 80 	movabs $0x8004209e98,%rcx
  8004204a54:	00 00 00 
  8004204a57:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204a5e:	00 00 00 
  8004204a61:	be 86 02 00 00       	mov    $0x286,%esi
  8004204a66:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204a6d:	00 00 00 
  8004204a70:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204a75:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204a7c:	00 00 00 
  8004204a7f:	41 ff d0             	callq  *%r8
	//assert(cu);
	assert(ret_die);
  8004204a82:	48 83 bd 78 fc ff ff 	cmpq   $0x0,-0x388(%rbp)
  8004204a89:	00 
  8004204a8a:	75 35                	jne    8004204ac1 <dwarf_search_die_within_cu+0xa4>
  8004204a8c:	48 b9 9c 9e 20 04 80 	movabs $0x8004209e9c,%rcx
  8004204a93:	00 00 00 
  8004204a96:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204a9d:	00 00 00 
  8004204aa0:	be 88 02 00 00       	mov    $0x288,%esi
  8004204aa5:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204aac:	00 00 00 
  8004204aaf:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204ab4:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204abb:	00 00 00 
  8004204abe:	41 ff d0             	callq  *%r8

	level = 1;
  8004204ac1:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)

	while (offset < cu.cu_next_offset && offset < dbg->dbg_info_size) {
  8004204ac8:	e9 fa 01 00 00       	jmpq   8004204cc7 <dwarf_search_die_within_cu+0x2aa>

		die_offset = offset;
  8004204acd:	48 8b 85 80 fc ff ff 	mov    -0x380(%rbp),%rax
  8004204ad4:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

		abnum = _dwarf_read_uleb128((uint8_t *)dbg->dbg_info_offset_elf, &offset);
  8004204ad8:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204adf:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004204ae3:	48 89 c2             	mov    %rax,%rdx
  8004204ae6:	48 8d 85 80 fc ff ff 	lea    -0x380(%rbp),%rax
  8004204aed:	48 89 c6             	mov    %rax,%rsi
  8004204af0:	48 89 d7             	mov    %rdx,%rdi
  8004204af3:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004204afa:	00 00 00 
  8004204afd:	ff d0                	callq  *%rax
  8004204aff:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

		if (abnum == 0) {
  8004204b03:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004204b08:	75 22                	jne    8004204b2c <dwarf_search_die_within_cu+0x10f>
			if (level == 0 || !search_sibling) {
  8004204b0a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004204b0e:	74 09                	je     8004204b19 <dwarf_search_die_within_cu+0xfc>
  8004204b10:	83 bd 74 fc ff ff 00 	cmpl   $0x0,-0x38c(%rbp)
  8004204b17:	75 0a                	jne    8004204b23 <dwarf_search_die_within_cu+0x106>
				//No more entry
				return (DW_DLE_NO_ENTRY);
  8004204b19:	b8 04 00 00 00       	mov    $0x4,%eax
  8004204b1e:	e9 d4 01 00 00       	jmpq   8004204cf7 <dwarf_search_die_within_cu+0x2da>
			}
			/*
			 * Return to previous DIE level.
			 */
			level--;
  8004204b23:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
			continue;
  8004204b27:	e9 9b 01 00 00       	jmpq   8004204cc7 <dwarf_search_die_within_cu+0x2aa>
		}

		if ((ret = _dwarf_abbrev_find(dbg, cu, abnum, &ab)) != DW_DLE_NONE)
  8004204b2c:	48 8d 95 b0 fc ff ff 	lea    -0x350(%rbp),%rdx
  8004204b33:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204b37:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204b3e:	48 83 ec 08          	sub    $0x8,%rsp
  8004204b42:	ff 75 40             	pushq  0x40(%rbp)
  8004204b45:	ff 75 38             	pushq  0x38(%rbp)
  8004204b48:	ff 75 30             	pushq  0x30(%rbp)
  8004204b4b:	ff 75 28             	pushq  0x28(%rbp)
  8004204b4e:	ff 75 20             	pushq  0x20(%rbp)
  8004204b51:	ff 75 18             	pushq  0x18(%rbp)
  8004204b54:	ff 75 10             	pushq  0x10(%rbp)
  8004204b57:	48 89 ce             	mov    %rcx,%rsi
  8004204b5a:	48 89 c7             	mov    %rax,%rdi
  8004204b5d:	48 b8 79 42 20 04 80 	movabs $0x8004204279,%rax
  8004204b64:	00 00 00 
  8004204b67:	ff d0                	callq  *%rax
  8004204b69:	48 83 c4 40          	add    $0x40,%rsp
  8004204b6d:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  8004204b70:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004204b74:	74 08                	je     8004204b7e <dwarf_search_die_within_cu+0x161>
			return (ret);
  8004204b76:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004204b79:	e9 79 01 00 00       	jmpq   8004204cf7 <dwarf_search_die_within_cu+0x2da>
		ret_die->die_offset = die_offset;
  8004204b7e:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204b85:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004204b89:	48 89 10             	mov    %rdx,(%rax)
		ret_die->die_abnum  = abnum;
  8004204b8c:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204b93:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004204b97:	48 89 50 10          	mov    %rdx,0x10(%rax)
		ret_die->die_ab  = ab;
  8004204b9b:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204ba2:	48 8d 50 20          	lea    0x20(%rax),%rdx
  8004204ba6:	48 8d 85 b0 fc ff ff 	lea    -0x350(%rbp),%rax
  8004204bad:	b9 66 00 00 00       	mov    $0x66,%ecx
  8004204bb2:	48 89 d7             	mov    %rdx,%rdi
  8004204bb5:	48 89 c6             	mov    %rax,%rsi
  8004204bb8:	f3 48 a5             	rep movsq %ds:(%rsi),%es:(%rdi)
		ret_die->die_attr_count = 0;
  8004204bbb:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204bc2:	c6 80 58 03 00 00 00 	movb   $0x0,0x358(%rax)
		ret_die->die_tag = ab.ab_tag;
  8004204bc9:	48 8b 95 b8 fc ff ff 	mov    -0x348(%rbp),%rdx
  8004204bd0:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204bd7:	48 89 50 18          	mov    %rdx,0x18(%rax)
		//ret_die->die_cu  = cu;
		//ret_die->die_dbg = cu->cu_dbg;

		for(i=0; i < ab.ab_atnum; i++)
  8004204bdb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
  8004204be2:	e9 91 00 00 00       	jmpq   8004204c78 <dwarf_search_die_within_cu+0x25b>
		{
			if ((ret = _dwarf_attr_init(dbg, &offset, &cu, ret_die, &ab.ab_attrdef[i], ab.ab_attrdef[i].ad_form, 0)) != DW_DLE_NONE)
  8004204be7:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004204bea:	48 63 d0             	movslq %eax,%rdx
  8004204bed:	48 89 d0             	mov    %rdx,%rax
  8004204bf0:	48 01 c0             	add    %rax,%rax
  8004204bf3:	48 01 d0             	add    %rdx,%rax
  8004204bf6:	48 c1 e0 03          	shl    $0x3,%rax
  8004204bfa:	48 01 e8             	add    %rbp,%rax
  8004204bfd:	48 2d 18 03 00 00    	sub    $0x318,%rax
  8004204c03:	48 8b 08             	mov    (%rax),%rcx
  8004204c06:	48 8d b5 b0 fc ff ff 	lea    -0x350(%rbp),%rsi
  8004204c0d:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004204c10:	48 63 d0             	movslq %eax,%rdx
  8004204c13:	48 89 d0             	mov    %rdx,%rax
  8004204c16:	48 01 c0             	add    %rax,%rax
  8004204c19:	48 01 d0             	add    %rdx,%rax
  8004204c1c:	48 c1 e0 03          	shl    $0x3,%rax
  8004204c20:	48 83 c0 30          	add    $0x30,%rax
  8004204c24:	48 8d 3c 06          	lea    (%rsi,%rax,1),%rdi
  8004204c28:	48 8b 95 78 fc ff ff 	mov    -0x388(%rbp),%rdx
  8004204c2f:	48 8d b5 80 fc ff ff 	lea    -0x380(%rbp),%rsi
  8004204c36:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204c3d:	48 83 ec 08          	sub    $0x8,%rsp
  8004204c41:	6a 00                	pushq  $0x0
  8004204c43:	49 89 c9             	mov    %rcx,%r9
  8004204c46:	49 89 f8             	mov    %rdi,%r8
  8004204c49:	48 89 d1             	mov    %rdx,%rcx
  8004204c4c:	48 8d 55 10          	lea    0x10(%rbp),%rdx
  8004204c50:	48 89 c7             	mov    %rax,%rdi
  8004204c53:	48 b8 83 43 20 04 80 	movabs $0x8004204383,%rax
  8004204c5a:	00 00 00 
  8004204c5d:	ff d0                	callq  *%rax
  8004204c5f:	48 83 c4 10          	add    $0x10,%rsp
  8004204c63:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  8004204c66:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004204c6a:	74 08                	je     8004204c74 <dwarf_search_die_within_cu+0x257>
				return (ret);
  8004204c6c:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004204c6f:	e9 83 00 00 00       	jmpq   8004204cf7 <dwarf_search_die_within_cu+0x2da>
		for(i=0; i < ab.ab_atnum; i++)
  8004204c74:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
  8004204c78:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004204c7b:	48 63 d0             	movslq %eax,%rdx
  8004204c7e:	48 8b 85 d8 fc ff ff 	mov    -0x328(%rbp),%rax
  8004204c85:	48 39 c2             	cmp    %rax,%rdx
  8004204c88:	0f 82 59 ff ff ff    	jb     8004204be7 <dwarf_search_die_within_cu+0x1ca>
		}

		ret_die->die_next_off = offset;
  8004204c8e:	48 8b 95 80 fc ff ff 	mov    -0x380(%rbp),%rdx
  8004204c95:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204c9c:	48 89 50 08          	mov    %rdx,0x8(%rax)
		if (search_sibling && level > 0) {
  8004204ca0:	83 bd 74 fc ff ff 00 	cmpl   $0x0,-0x38c(%rbp)
  8004204ca7:	74 17                	je     8004204cc0 <dwarf_search_die_within_cu+0x2a3>
  8004204ca9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004204cad:	7e 11                	jle    8004204cc0 <dwarf_search_die_within_cu+0x2a3>
			//dwarf_dealloc(dbg, die, DW_DLA_DIE);
			if (ab.ab_children == DW_CHILDREN_yes) {
  8004204caf:	0f b6 85 c0 fc ff ff 	movzbl -0x340(%rbp),%eax
  8004204cb6:	3c 01                	cmp    $0x1,%al
  8004204cb8:	75 0d                	jne    8004204cc7 <dwarf_search_die_within_cu+0x2aa>
				/* Advance to next DIE level. */
				level++;
  8004204cba:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
			if (ab.ab_children == DW_CHILDREN_yes) {
  8004204cbe:	eb 07                	jmp    8004204cc7 <dwarf_search_die_within_cu+0x2aa>
			}
		} else {
			//*ret_die = die;
			return (DW_DLE_NONE);
  8004204cc0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204cc5:	eb 30                	jmp    8004204cf7 <dwarf_search_die_within_cu+0x2da>
	while (offset < cu.cu_next_offset && offset < dbg->dbg_info_size) {
  8004204cc7:	48 8b 55 30          	mov    0x30(%rbp),%rdx
  8004204ccb:	48 8b 85 80 fc ff ff 	mov    -0x380(%rbp),%rax
  8004204cd2:	48 39 c2             	cmp    %rax,%rdx
  8004204cd5:	76 1b                	jbe    8004204cf2 <dwarf_search_die_within_cu+0x2d5>
  8004204cd7:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204cde:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004204ce2:	48 8b 85 80 fc ff ff 	mov    -0x380(%rbp),%rax
  8004204ce9:	48 39 c2             	cmp    %rax,%rdx
  8004204cec:	0f 87 db fd ff ff    	ja     8004204acd <dwarf_search_die_within_cu+0xb0>
		}
	}

	return (DW_DLE_NO_ENTRY);
  8004204cf2:	b8 04 00 00 00       	mov    $0x4,%eax
}
  8004204cf7:	c9                   	leaveq 
  8004204cf8:	c3                   	retq   

0000008004204cf9 <dwarf_offdie>:

//Return 0 on success
int
dwarf_offdie(Dwarf_Debug dbg, uint64_t offset, Dwarf_Die *ret_die, Dwarf_CU cu)
{
  8004204cf9:	55                   	push   %rbp
  8004204cfa:	48 89 e5             	mov    %rsp,%rbp
  8004204cfd:	48 83 ec 30          	sub    $0x30,%rsp
  8004204d01:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004204d05:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004204d09:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	int ret;

	assert(dbg);
  8004204d0d:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004204d12:	75 35                	jne    8004204d49 <dwarf_offdie+0x50>
  8004204d14:	48 b9 98 9e 20 04 80 	movabs $0x8004209e98,%rcx
  8004204d1b:	00 00 00 
  8004204d1e:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204d25:	00 00 00 
  8004204d28:	be c4 02 00 00       	mov    $0x2c4,%esi
  8004204d2d:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204d34:	00 00 00 
  8004204d37:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204d3c:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204d43:	00 00 00 
  8004204d46:	41 ff d0             	callq  *%r8
	assert(ret_die);
  8004204d49:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004204d4e:	75 35                	jne    8004204d85 <dwarf_offdie+0x8c>
  8004204d50:	48 b9 9c 9e 20 04 80 	movabs $0x8004209e9c,%rcx
  8004204d57:	00 00 00 
  8004204d5a:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204d61:	00 00 00 
  8004204d64:	be c5 02 00 00       	mov    $0x2c5,%esi
  8004204d69:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204d70:	00 00 00 
  8004204d73:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204d78:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204d7f:	00 00 00 
  8004204d82:	41 ff d0             	callq  *%r8

	/* First search the current CU. */
	if (offset < cu.cu_next_offset) {
  8004204d85:	48 8b 45 30          	mov    0x30(%rbp),%rax
  8004204d89:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004204d8d:	73 45                	jae    8004204dd4 <dwarf_offdie+0xdb>
		ret = dwarf_search_die_within_cu(dbg, cu, offset, ret_die, 0);
  8004204d8f:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004204d93:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  8004204d97:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204d9b:	48 83 ec 08          	sub    $0x8,%rsp
  8004204d9f:	ff 75 40             	pushq  0x40(%rbp)
  8004204da2:	ff 75 38             	pushq  0x38(%rbp)
  8004204da5:	ff 75 30             	pushq  0x30(%rbp)
  8004204da8:	ff 75 28             	pushq  0x28(%rbp)
  8004204dab:	ff 75 20             	pushq  0x20(%rbp)
  8004204dae:	ff 75 18             	pushq  0x18(%rbp)
  8004204db1:	ff 75 10             	pushq  0x10(%rbp)
  8004204db4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8004204db9:	48 89 c7             	mov    %rax,%rdi
  8004204dbc:	48 b8 1d 4a 20 04 80 	movabs $0x8004204a1d,%rax
  8004204dc3:	00 00 00 
  8004204dc6:	ff d0                	callq  *%rax
  8004204dc8:	48 83 c4 40          	add    $0x40,%rsp
  8004204dcc:	89 45 fc             	mov    %eax,-0x4(%rbp)
		return ret;
  8004204dcf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004204dd2:	eb 05                	jmp    8004204dd9 <dwarf_offdie+0xe0>
	}

	/*TODO: Search other CU*/
	return DW_DLV_OK;
  8004204dd4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004204dd9:	c9                   	leaveq 
  8004204dda:	c3                   	retq   

0000008004204ddb <_dwarf_attr_find>:

Dwarf_Attribute*
_dwarf_attr_find(Dwarf_Die *die, uint16_t attr)
{
  8004204ddb:	55                   	push   %rbp
  8004204ddc:	48 89 e5             	mov    %rsp,%rbp
  8004204ddf:	48 83 ec 20          	sub    $0x20,%rsp
  8004204de3:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004204de7:	89 f0                	mov    %esi,%eax
  8004204de9:	66 89 45 e4          	mov    %ax,-0x1c(%rbp)
	Dwarf_Attribute *myat = NULL;
  8004204ded:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004204df4:	00 
	int i;
    
	for(i=0; i < die->die_attr_count; i++)
  8004204df5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004204dfc:	eb 57                	jmp    8004204e55 <_dwarf_attr_find+0x7a>
	{
		if (die->die_attr[i].at_attrib == attr)
  8004204dfe:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204e02:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004204e05:	48 63 d0             	movslq %eax,%rdx
  8004204e08:	48 89 d0             	mov    %rdx,%rax
  8004204e0b:	48 01 c0             	add    %rax,%rax
  8004204e0e:	48 01 d0             	add    %rdx,%rax
  8004204e11:	48 c1 e0 05          	shl    $0x5,%rax
  8004204e15:	48 01 c8             	add    %rcx,%rax
  8004204e18:	48 05 80 03 00 00    	add    $0x380,%rax
  8004204e1e:	48 8b 10             	mov    (%rax),%rdx
  8004204e21:	0f b7 45 e4          	movzwl -0x1c(%rbp),%eax
  8004204e25:	48 39 c2             	cmp    %rax,%rdx
  8004204e28:	75 27                	jne    8004204e51 <_dwarf_attr_find+0x76>
		{
			myat = &(die->die_attr[i]);
  8004204e2a:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004204e2d:	48 63 d0             	movslq %eax,%rdx
  8004204e30:	48 89 d0             	mov    %rdx,%rax
  8004204e33:	48 01 c0             	add    %rax,%rax
  8004204e36:	48 01 d0             	add    %rdx,%rax
  8004204e39:	48 c1 e0 05          	shl    $0x5,%rax
  8004204e3d:	48 8d 90 70 03 00 00 	lea    0x370(%rax),%rdx
  8004204e44:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204e48:	48 01 d0             	add    %rdx,%rax
  8004204e4b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
			break;
  8004204e4f:	eb 17                	jmp    8004204e68 <_dwarf_attr_find+0x8d>
	for(i=0; i < die->die_attr_count; i++)
  8004204e51:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  8004204e55:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204e59:	0f b6 80 58 03 00 00 	movzbl 0x358(%rax),%eax
  8004204e60:	0f b6 c0             	movzbl %al,%eax
  8004204e63:	39 45 f4             	cmp    %eax,-0xc(%rbp)
  8004204e66:	7c 96                	jl     8004204dfe <_dwarf_attr_find+0x23>
		}
	}

	return myat;
  8004204e68:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004204e6c:	c9                   	leaveq 
  8004204e6d:	c3                   	retq   

0000008004204e6e <dwarf_siblingof>:

//Return 0 on success
int
dwarf_siblingof(Dwarf_Debug dbg, Dwarf_Die *die, Dwarf_Die *ret_die,
		Dwarf_CU *cu)
{
  8004204e6e:	55                   	push   %rbp
  8004204e6f:	48 89 e5             	mov    %rsp,%rbp
  8004204e72:	48 83 ec 40          	sub    $0x40,%rsp
  8004204e76:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004204e7a:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8004204e7e:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  8004204e82:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
	Dwarf_Attribute *at;
	uint64_t offset;
	int ret, search_sibling;

	assert(dbg);
  8004204e86:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004204e8b:	75 35                	jne    8004204ec2 <dwarf_siblingof+0x54>
  8004204e8d:	48 b9 98 9e 20 04 80 	movabs $0x8004209e98,%rcx
  8004204e94:	00 00 00 
  8004204e97:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204e9e:	00 00 00 
  8004204ea1:	be ec 02 00 00       	mov    $0x2ec,%esi
  8004204ea6:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204ead:	00 00 00 
  8004204eb0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204eb5:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204ebc:	00 00 00 
  8004204ebf:	41 ff d0             	callq  *%r8
	assert(ret_die);
  8004204ec2:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004204ec7:	75 35                	jne    8004204efe <dwarf_siblingof+0x90>
  8004204ec9:	48 b9 9c 9e 20 04 80 	movabs $0x8004209e9c,%rcx
  8004204ed0:	00 00 00 
  8004204ed3:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204eda:	00 00 00 
  8004204edd:	be ed 02 00 00       	mov    $0x2ed,%esi
  8004204ee2:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204ee9:	00 00 00 
  8004204eec:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204ef1:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204ef8:	00 00 00 
  8004204efb:	41 ff d0             	callq  *%r8
	assert(cu);
  8004204efe:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
  8004204f03:	75 35                	jne    8004204f3a <dwarf_siblingof+0xcc>
  8004204f05:	48 b9 a4 9e 20 04 80 	movabs $0x8004209ea4,%rcx
  8004204f0c:	00 00 00 
  8004204f0f:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004204f16:	00 00 00 
  8004204f19:	be ee 02 00 00       	mov    $0x2ee,%esi
  8004204f1e:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004204f25:	00 00 00 
  8004204f28:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204f2d:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004204f34:	00 00 00 
  8004204f37:	41 ff d0             	callq  *%r8

	/* Application requests the first DIE in this CU. */
	if (die == NULL)
  8004204f3a:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  8004204f3f:	75 44                	jne    8004204f85 <dwarf_siblingof+0x117>
		return (dwarf_offdie(dbg, cu->cu_die_offset, ret_die, *cu));
  8004204f41:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204f45:	48 8b 70 28          	mov    0x28(%rax),%rsi
  8004204f49:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004204f4d:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004204f51:	48 83 ec 08          	sub    $0x8,%rsp
  8004204f55:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204f59:	ff 70 30             	pushq  0x30(%rax)
  8004204f5c:	ff 70 28             	pushq  0x28(%rax)
  8004204f5f:	ff 70 20             	pushq  0x20(%rax)
  8004204f62:	ff 70 18             	pushq  0x18(%rax)
  8004204f65:	ff 70 10             	pushq  0x10(%rax)
  8004204f68:	ff 70 08             	pushq  0x8(%rax)
  8004204f6b:	ff 30                	pushq  (%rax)
  8004204f6d:	48 89 cf             	mov    %rcx,%rdi
  8004204f70:	48 b8 f9 4c 20 04 80 	movabs $0x8004204cf9,%rax
  8004204f77:	00 00 00 
  8004204f7a:	ff d0                	callq  *%rax
  8004204f7c:	48 83 c4 40          	add    $0x40,%rsp
  8004204f80:	e9 e9 00 00 00       	jmpq   800420506e <dwarf_siblingof+0x200>

	/*
	 * If the DIE doesn't have any children, its sibling sits next
	 * right to it.
	 */
	search_sibling = 0;
  8004204f85:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
	if (die->die_ab.ab_children == DW_CHILDREN_no)
  8004204f8c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004204f90:	0f b6 40 30          	movzbl 0x30(%rax),%eax
  8004204f94:	84 c0                	test   %al,%al
  8004204f96:	75 0e                	jne    8004204fa6 <dwarf_siblingof+0x138>
		offset = die->die_next_off;
  8004204f98:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004204f9c:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004204fa0:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004204fa4:	eb 6b                	jmp    8004205011 <dwarf_siblingof+0x1a3>
	else {
		/*
		 * Look for DW_AT_sibling attribute for the offset of
		 * its sibling.
		 */
		if ((at = _dwarf_attr_find(die, DW_AT_sibling)) != NULL) {
  8004204fa6:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004204faa:	be 01 00 00 00       	mov    $0x1,%esi
  8004204faf:	48 89 c7             	mov    %rax,%rdi
  8004204fb2:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  8004204fb9:	00 00 00 
  8004204fbc:	ff d0                	callq  *%rax
  8004204fbe:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8004204fc2:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004204fc7:	74 35                	je     8004204ffe <dwarf_siblingof+0x190>
			if (at->at_form != DW_FORM_ref_addr)
  8004204fc9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204fcd:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204fd1:	48 83 f8 10          	cmp    $0x10,%rax
  8004204fd5:	74 19                	je     8004204ff0 <dwarf_siblingof+0x182>
				offset = at->u[0].u64 + cu->cu_offset;
  8004204fd7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204fdb:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8004204fdf:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204fe3:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004204fe7:	48 01 d0             	add    %rdx,%rax
  8004204fea:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004204fee:	eb 21                	jmp    8004205011 <dwarf_siblingof+0x1a3>
			else
				offset = at->u[0].u64;
  8004204ff0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204ff4:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004204ff8:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004204ffc:	eb 13                	jmp    8004205011 <dwarf_siblingof+0x1a3>
		} else {
			offset = die->die_next_off;
  8004204ffe:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004205002:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004205006:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
			search_sibling = 1;
  800420500a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%rbp)
		}
	}

	ret = dwarf_search_die_within_cu(dbg, *cu, offset, ret_die, search_sibling);
  8004205011:	8b 4d f4             	mov    -0xc(%rbp),%ecx
  8004205014:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004205018:	48 8b 75 f8          	mov    -0x8(%rbp),%rsi
  800420501c:	48 8b 7d d8          	mov    -0x28(%rbp),%rdi
  8004205020:	48 83 ec 08          	sub    $0x8,%rsp
  8004205024:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004205028:	ff 70 30             	pushq  0x30(%rax)
  800420502b:	ff 70 28             	pushq  0x28(%rax)
  800420502e:	ff 70 20             	pushq  0x20(%rax)
  8004205031:	ff 70 18             	pushq  0x18(%rax)
  8004205034:	ff 70 10             	pushq  0x10(%rax)
  8004205037:	ff 70 08             	pushq  0x8(%rax)
  800420503a:	ff 30                	pushq  (%rax)
  800420503c:	48 b8 1d 4a 20 04 80 	movabs $0x8004204a1d,%rax
  8004205043:	00 00 00 
  8004205046:	ff d0                	callq  *%rax
  8004205048:	48 83 c4 40          	add    $0x40,%rsp
  800420504c:	89 45 e4             	mov    %eax,-0x1c(%rbp)


	if (ret == DW_DLE_NO_ENTRY) {
  800420504f:	83 7d e4 04          	cmpl   $0x4,-0x1c(%rbp)
  8004205053:	75 07                	jne    800420505c <dwarf_siblingof+0x1ee>
		return (DW_DLV_NO_ENTRY);
  8004205055:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420505a:	eb 12                	jmp    800420506e <dwarf_siblingof+0x200>
	} else if (ret != DW_DLE_NONE)
  800420505c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004205060:	74 07                	je     8004205069 <dwarf_siblingof+0x1fb>
		return (DW_DLV_ERROR);
  8004205062:	b8 01 00 00 00       	mov    $0x1,%eax
  8004205067:	eb 05                	jmp    800420506e <dwarf_siblingof+0x200>


	return (DW_DLV_OK);
  8004205069:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420506e:	c9                   	leaveq 
  800420506f:	c3                   	retq   

0000008004205070 <dwarf_child>:

int
dwarf_child(Dwarf_Debug dbg, Dwarf_CU *cu, Dwarf_Die *die, Dwarf_Die *ret_die)
{
  8004205070:	55                   	push   %rbp
  8004205071:	48 89 e5             	mov    %rsp,%rbp
  8004205074:	48 83 ec 30          	sub    $0x30,%rsp
  8004205078:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420507c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004205080:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004205084:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
	int ret;

	assert(die);
  8004205088:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  800420508d:	75 35                	jne    80042050c4 <dwarf_child+0x54>
  800420508f:	48 b9 a7 9e 20 04 80 	movabs $0x8004209ea7,%rcx
  8004205096:	00 00 00 
  8004205099:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  80042050a0:	00 00 00 
  80042050a3:	be 1c 03 00 00       	mov    $0x31c,%esi
  80042050a8:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  80042050af:	00 00 00 
  80042050b2:	b8 00 00 00 00       	mov    $0x0,%eax
  80042050b7:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042050be:	00 00 00 
  80042050c1:	41 ff d0             	callq  *%r8
	assert(ret_die);
  80042050c4:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  80042050c9:	75 35                	jne    8004205100 <dwarf_child+0x90>
  80042050cb:	48 b9 9c 9e 20 04 80 	movabs $0x8004209e9c,%rcx
  80042050d2:	00 00 00 
  80042050d5:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  80042050dc:	00 00 00 
  80042050df:	be 1d 03 00 00       	mov    $0x31d,%esi
  80042050e4:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  80042050eb:	00 00 00 
  80042050ee:	b8 00 00 00 00       	mov    $0x0,%eax
  80042050f3:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042050fa:	00 00 00 
  80042050fd:	41 ff d0             	callq  *%r8
	assert(dbg);
  8004205100:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004205105:	75 35                	jne    800420513c <dwarf_child+0xcc>
  8004205107:	48 b9 98 9e 20 04 80 	movabs $0x8004209e98,%rcx
  800420510e:	00 00 00 
  8004205111:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004205118:	00 00 00 
  800420511b:	be 1e 03 00 00       	mov    $0x31e,%esi
  8004205120:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004205127:	00 00 00 
  800420512a:	b8 00 00 00 00       	mov    $0x0,%eax
  800420512f:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004205136:	00 00 00 
  8004205139:	41 ff d0             	callq  *%r8
	assert(cu);
  800420513c:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004205141:	75 35                	jne    8004205178 <dwarf_child+0x108>
  8004205143:	48 b9 a4 9e 20 04 80 	movabs $0x8004209ea4,%rcx
  800420514a:	00 00 00 
  800420514d:	48 ba 0a 9d 20 04 80 	movabs $0x8004209d0a,%rdx
  8004205154:	00 00 00 
  8004205157:	be 1f 03 00 00       	mov    $0x31f,%esi
  800420515c:	48 bf 1f 9d 20 04 80 	movabs $0x8004209d1f,%rdi
  8004205163:	00 00 00 
  8004205166:	b8 00 00 00 00       	mov    $0x0,%eax
  800420516b:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004205172:	00 00 00 
  8004205175:	41 ff d0             	callq  *%r8

	if (die->die_ab.ab_children == DW_CHILDREN_no)
  8004205178:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420517c:	0f b6 40 30          	movzbl 0x30(%rax),%eax
  8004205180:	84 c0                	test   %al,%al
  8004205182:	75 07                	jne    800420518b <dwarf_child+0x11b>
		return (DW_DLE_NO_ENTRY);
  8004205184:	b8 04 00 00 00       	mov    $0x4,%eax
  8004205189:	eb 63                	jmp    80042051ee <dwarf_child+0x17e>

	ret = dwarf_search_die_within_cu(dbg, *cu, die->die_next_off, ret_die, 0);
  800420518b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420518f:	48 8b 70 08          	mov    0x8(%rax),%rsi
  8004205193:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205197:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  800420519b:	48 83 ec 08          	sub    $0x8,%rsp
  800420519f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042051a3:	ff 70 30             	pushq  0x30(%rax)
  80042051a6:	ff 70 28             	pushq  0x28(%rax)
  80042051a9:	ff 70 20             	pushq  0x20(%rax)
  80042051ac:	ff 70 18             	pushq  0x18(%rax)
  80042051af:	ff 70 10             	pushq  0x10(%rax)
  80042051b2:	ff 70 08             	pushq  0x8(%rax)
  80042051b5:	ff 30                	pushq  (%rax)
  80042051b7:	b9 00 00 00 00       	mov    $0x0,%ecx
  80042051bc:	48 b8 1d 4a 20 04 80 	movabs $0x8004204a1d,%rax
  80042051c3:	00 00 00 
  80042051c6:	ff d0                	callq  *%rax
  80042051c8:	48 83 c4 40          	add    $0x40,%rsp
  80042051cc:	89 45 fc             	mov    %eax,-0x4(%rbp)

	if (ret == DW_DLE_NO_ENTRY) {
  80042051cf:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
  80042051d3:	75 07                	jne    80042051dc <dwarf_child+0x16c>
		DWARF_SET_ERROR(dbg, error, DW_DLE_NO_ENTRY);
		return (DW_DLV_NO_ENTRY);
  80042051d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  80042051da:	eb 12                	jmp    80042051ee <dwarf_child+0x17e>
	} else if (ret != DW_DLE_NONE)
  80042051dc:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80042051e0:	74 07                	je     80042051e9 <dwarf_child+0x179>
		return (DW_DLV_ERROR);
  80042051e2:	b8 01 00 00 00       	mov    $0x1,%eax
  80042051e7:	eb 05                	jmp    80042051ee <dwarf_child+0x17e>

	return (DW_DLV_OK);
  80042051e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042051ee:	c9                   	leaveq 
  80042051ef:	c3                   	retq   

00000080042051f0 <_dwarf_find_section_enhanced>:


int  _dwarf_find_section_enhanced(Dwarf_Section *ds)
{
  80042051f0:	55                   	push   %rbp
  80042051f1:	48 89 e5             	mov    %rsp,%rbp
  80042051f4:	48 83 ec 20          	sub    $0x20,%rsp
  80042051f8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	Dwarf_Section *secthdr = _dwarf_find_section(ds->ds_name);
  80042051fc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205200:	48 8b 00             	mov    (%rax),%rax
  8004205203:	48 89 c7             	mov    %rax,%rdi
  8004205206:	48 b8 1b 85 20 04 80 	movabs $0x800420851b,%rax
  800420520d:	00 00 00 
  8004205210:	ff d0                	callq  *%rax
  8004205212:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	ds->ds_data = secthdr->ds_data;//(Dwarf_Small*)((uint8_t *)elf_base_ptr + secthdr->sh_offset);
  8004205216:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420521a:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800420521e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205222:	48 89 50 08          	mov    %rdx,0x8(%rax)
	ds->ds_addr = secthdr->ds_addr;
  8004205226:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420522a:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800420522e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205232:	48 89 50 10          	mov    %rdx,0x10(%rax)
	ds->ds_size = secthdr->ds_size;
  8004205236:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420523a:	48 8b 50 18          	mov    0x18(%rax),%rdx
  800420523e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205242:	48 89 50 18          	mov    %rdx,0x18(%rax)
	return 0;
  8004205246:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420524b:	c9                   	leaveq 
  800420524c:	c3                   	retq   

000000800420524d <_dwarf_frame_params_init>:

extern int  _dwarf_find_section_enhanced(Dwarf_Section *ds);

void
_dwarf_frame_params_init(Dwarf_Debug dbg)
{
  800420524d:	55                   	push   %rbp
  800420524e:	48 89 e5             	mov    %rsp,%rbp
  8004205251:	48 83 ec 08          	sub    $0x8,%rsp
  8004205255:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
	/* Initialise call frame related parameters. */
	dbg->dbg_frame_rule_table_size = DW_FRAME_LAST_REG_NUM;
  8004205259:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420525d:	66 c7 40 48 42 00    	movw   $0x42,0x48(%rax)
	dbg->dbg_frame_rule_initial_value = DW_FRAME_REG_INITIAL_VALUE;
  8004205263:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205267:	66 c7 40 4a 0b 04    	movw   $0x40b,0x4a(%rax)
	dbg->dbg_frame_cfa_value = DW_FRAME_CFA_COL3;
  800420526d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205271:	66 c7 40 4c 9c 05    	movw   $0x59c,0x4c(%rax)
	dbg->dbg_frame_same_value = DW_FRAME_SAME_VAL;
  8004205277:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420527b:	66 c7 40 4e 0b 04    	movw   $0x40b,0x4e(%rax)
	dbg->dbg_frame_undefined_value = DW_FRAME_UNDEFINED_VAL;
  8004205281:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205285:	66 c7 40 50 0a 04    	movw   $0x40a,0x50(%rax)
}
  800420528b:	90                   	nop
  800420528c:	c9                   	leaveq 
  800420528d:	c3                   	retq   

000000800420528e <dwarf_get_fde_at_pc>:

int
dwarf_get_fde_at_pc(Dwarf_Debug dbg, Dwarf_Addr pc,
		    struct _Dwarf_Fde *ret_fde, Dwarf_Cie cie,
		    Dwarf_Error *error)
{
  800420528e:	55                   	push   %rbp
  800420528f:	48 89 e5             	mov    %rsp,%rbp
  8004205292:	48 83 ec 40          	sub    $0x40,%rsp
  8004205296:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420529a:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  800420529e:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80042052a2:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  80042052a6:	4c 89 45 c8          	mov    %r8,-0x38(%rbp)
	Dwarf_Fde fde = ret_fde;
  80042052aa:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042052ae:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	memset(fde, 0, sizeof(struct _Dwarf_Fde));
  80042052b2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052b6:	ba 80 00 00 00       	mov    $0x80,%edx
  80042052bb:	be 00 00 00 00       	mov    $0x0,%esi
  80042052c0:	48 89 c7             	mov    %rax,%rdi
  80042052c3:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  80042052ca:	00 00 00 
  80042052cd:	ff d0                	callq  *%rax
	fde->fde_cie = cie;
  80042052cf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052d3:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042052d7:	48 89 50 08          	mov    %rdx,0x8(%rax)
	
	if (ret_fde == NULL)
  80042052db:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80042052e0:	75 60                	jne    8004205342 <dwarf_get_fde_at_pc+0xb4>
		return (DW_DLV_ERROR);
  80042052e2:	b8 01 00 00 00       	mov    $0x1,%eax
  80042052e7:	eb 73                	jmp    800420535c <dwarf_get_fde_at_pc+0xce>

	while(dbg->curr_off_eh < dbg->dbg_eh_size) {
		if (_dwarf_get_next_fde(dbg, true, error, fde) < 0)
  80042052e9:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
  80042052ed:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042052f1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042052f5:	be 01 00 00 00       	mov    $0x1,%esi
  80042052fa:	48 89 c7             	mov    %rax,%rdi
  80042052fd:	48 b8 10 75 20 04 80 	movabs $0x8004207510,%rax
  8004205304:	00 00 00 
  8004205307:	ff d0                	callq  *%rax
  8004205309:	85 c0                	test   %eax,%eax
  800420530b:	79 07                	jns    8004205314 <dwarf_get_fde_at_pc+0x86>
		{
			return DW_DLV_NO_ENTRY;
  800420530d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004205312:	eb 48                	jmp    800420535c <dwarf_get_fde_at_pc+0xce>
		}
		if (pc >= fde->fde_initloc && pc < fde->fde_initloc +
  8004205314:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205318:	48 8b 40 30          	mov    0x30(%rax),%rax
  800420531c:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004205320:	72 20                	jb     8004205342 <dwarf_get_fde_at_pc+0xb4>
  8004205322:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205326:	48 8b 50 30          	mov    0x30(%rax),%rdx
		    fde->fde_adrange)
  800420532a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420532e:	48 8b 40 38          	mov    0x38(%rax),%rax
		if (pc >= fde->fde_initloc && pc < fde->fde_initloc +
  8004205332:	48 01 d0             	add    %rdx,%rax
  8004205335:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004205339:	73 07                	jae    8004205342 <dwarf_get_fde_at_pc+0xb4>
			return (DW_DLV_OK);
  800420533b:	b8 00 00 00 00       	mov    $0x0,%eax
  8004205340:	eb 1a                	jmp    800420535c <dwarf_get_fde_at_pc+0xce>
	while(dbg->curr_off_eh < dbg->dbg_eh_size) {
  8004205342:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205346:	48 8b 50 30          	mov    0x30(%rax),%rdx
  800420534a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420534e:	48 8b 40 40          	mov    0x40(%rax),%rax
  8004205352:	48 39 c2             	cmp    %rax,%rdx
  8004205355:	72 92                	jb     80042052e9 <dwarf_get_fde_at_pc+0x5b>
	}

	DWARF_SET_ERROR(dbg, error, DW_DLE_NO_ENTRY);
	return (DW_DLV_NO_ENTRY);
  8004205357:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  800420535c:	c9                   	leaveq 
  800420535d:	c3                   	retq   

000000800420535e <_dwarf_frame_regtable_copy>:

int
_dwarf_frame_regtable_copy(Dwarf_Debug dbg, Dwarf_Regtable3 **dest,
			   Dwarf_Regtable3 *src, Dwarf_Error *error)
{
  800420535e:	55                   	push   %rbp
  800420535f:	48 89 e5             	mov    %rsp,%rbp
  8004205362:	48 83 ec 30          	sub    $0x30,%rsp
  8004205366:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420536a:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  800420536e:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004205372:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
	int i;

	assert(dest != NULL);
  8004205376:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  800420537b:	75 35                	jne    80042053b2 <_dwarf_frame_regtable_copy+0x54>
  800420537d:	48 b9 ba 9e 20 04 80 	movabs $0x8004209eba,%rcx
  8004205384:	00 00 00 
  8004205387:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  800420538e:	00 00 00 
  8004205391:	be 57 00 00 00       	mov    $0x57,%esi
  8004205396:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  800420539d:	00 00 00 
  80042053a0:	b8 00 00 00 00       	mov    $0x0,%eax
  80042053a5:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042053ac:	00 00 00 
  80042053af:	41 ff d0             	callq  *%r8
	assert(src != NULL);
  80042053b2:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80042053b7:	75 35                	jne    80042053ee <_dwarf_frame_regtable_copy+0x90>
  80042053b9:	48 b9 f2 9e 20 04 80 	movabs $0x8004209ef2,%rcx
  80042053c0:	00 00 00 
  80042053c3:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  80042053ca:	00 00 00 
  80042053cd:	be 58 00 00 00       	mov    $0x58,%esi
  80042053d2:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  80042053d9:	00 00 00 
  80042053dc:	b8 00 00 00 00       	mov    $0x0,%eax
  80042053e1:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042053e8:	00 00 00 
  80042053eb:	41 ff d0             	callq  *%r8

	if (*dest == NULL) {
  80042053ee:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042053f2:	48 8b 00             	mov    (%rax),%rax
  80042053f5:	48 85 c0             	test   %rax,%rax
  80042053f8:	75 39                	jne    8004205433 <_dwarf_frame_regtable_copy+0xd5>
		*dest = &global_rt_table_shadow;
  80042053fa:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042053fe:	48 bf 20 bd 21 04 80 	movabs $0x800421bd20,%rdi
  8004205405:	00 00 00 
  8004205408:	48 89 38             	mov    %rdi,(%rax)
		(*dest)->rt3_reg_table_size = src->rt3_reg_table_size;
  800420540b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420540f:	48 8b 00             	mov    (%rax),%rax
  8004205412:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004205416:	0f b7 52 18          	movzwl 0x18(%rdx),%edx
  800420541a:	66 89 50 18          	mov    %dx,0x18(%rax)
		(*dest)->rt3_rules = global_rules_shadow;
  800420541e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004205422:	48 8b 00             	mov    (%rax),%rax
  8004205425:	48 be c0 be 21 04 80 	movabs $0x800421bec0,%rsi
  800420542c:	00 00 00 
  800420542f:	48 89 70 20          	mov    %rsi,0x20(%rax)
	}

	memcpy(&(*dest)->rt3_cfa_rule, &src->rt3_cfa_rule,
  8004205433:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004205437:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  800420543b:	48 8b 12             	mov    (%rdx),%rdx
  800420543e:	48 89 d1             	mov    %rdx,%rcx
  8004205441:	ba 18 00 00 00       	mov    $0x18,%edx
  8004205446:	48 89 c6             	mov    %rax,%rsi
  8004205449:	48 89 cf             	mov    %rcx,%rdi
  800420544c:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  8004205453:	00 00 00 
  8004205456:	ff d0                	callq  *%rax
	       sizeof(Dwarf_Regtable_Entry3));

	for (i = 0; i < (*dest)->rt3_reg_table_size &&
  8004205458:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  800420545f:	eb 5a                	jmp    80042054bb <_dwarf_frame_regtable_copy+0x15d>
		     i < src->rt3_reg_table_size; i++)
		memcpy(&(*dest)->rt3_rules[i], &src->rt3_rules[i],
  8004205461:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004205465:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205469:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420546c:	48 63 d0             	movslq %eax,%rdx
  800420546f:	48 89 d0             	mov    %rdx,%rax
  8004205472:	48 01 c0             	add    %rax,%rax
  8004205475:	48 01 d0             	add    %rdx,%rax
  8004205478:	48 c1 e0 03          	shl    $0x3,%rax
  800420547c:	48 01 c1             	add    %rax,%rcx
  800420547f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004205483:	48 8b 00             	mov    (%rax),%rax
  8004205486:	48 8b 70 20          	mov    0x20(%rax),%rsi
  800420548a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420548d:	48 63 d0             	movslq %eax,%rdx
  8004205490:	48 89 d0             	mov    %rdx,%rax
  8004205493:	48 01 c0             	add    %rax,%rax
  8004205496:	48 01 d0             	add    %rdx,%rax
  8004205499:	48 c1 e0 03          	shl    $0x3,%rax
  800420549d:	48 01 f0             	add    %rsi,%rax
  80042054a0:	ba 18 00 00 00       	mov    $0x18,%edx
  80042054a5:	48 89 ce             	mov    %rcx,%rsi
  80042054a8:	48 89 c7             	mov    %rax,%rdi
  80042054ab:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  80042054b2:	00 00 00 
  80042054b5:	ff d0                	callq  *%rax
		     i < src->rt3_reg_table_size; i++)
  80042054b7:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
	for (i = 0; i < (*dest)->rt3_reg_table_size &&
  80042054bb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042054bf:	48 8b 00             	mov    (%rax),%rax
  80042054c2:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042054c6:	0f b7 c0             	movzwl %ax,%eax
  80042054c9:	39 45 fc             	cmp    %eax,-0x4(%rbp)
  80042054cc:	7d 44                	jge    8004205512 <_dwarf_frame_regtable_copy+0x1b4>
		     i < src->rt3_reg_table_size; i++)
  80042054ce:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042054d2:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042054d6:	0f b7 c0             	movzwl %ax,%eax
	for (i = 0; i < (*dest)->rt3_reg_table_size &&
  80042054d9:	39 45 fc             	cmp    %eax,-0x4(%rbp)
  80042054dc:	7c 83                	jl     8004205461 <_dwarf_frame_regtable_copy+0x103>
		       sizeof(Dwarf_Regtable_Entry3));

	for (; i < (*dest)->rt3_reg_table_size; i++)
  80042054de:	eb 32                	jmp    8004205512 <_dwarf_frame_regtable_copy+0x1b4>
		(*dest)->rt3_rules[i].dw_regnum =
  80042054e0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042054e4:	48 8b 00             	mov    (%rax),%rax
  80042054e7:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042054eb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042054ee:	48 63 d0             	movslq %eax,%rdx
  80042054f1:	48 89 d0             	mov    %rdx,%rax
  80042054f4:	48 01 c0             	add    %rax,%rax
  80042054f7:	48 01 d0             	add    %rdx,%rax
  80042054fa:	48 c1 e0 03          	shl    $0x3,%rax
  80042054fe:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
			dbg->dbg_frame_undefined_value;
  8004205502:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205506:	0f b7 40 50          	movzwl 0x50(%rax),%eax
		(*dest)->rt3_rules[i].dw_regnum =
  800420550a:	66 89 42 02          	mov    %ax,0x2(%rdx)
	for (; i < (*dest)->rt3_reg_table_size; i++)
  800420550e:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004205512:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004205516:	48 8b 00             	mov    (%rax),%rax
  8004205519:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  800420551d:	0f b7 c0             	movzwl %ax,%eax
  8004205520:	39 45 fc             	cmp    %eax,-0x4(%rbp)
  8004205523:	7c bb                	jl     80042054e0 <_dwarf_frame_regtable_copy+0x182>

	return (DW_DLE_NONE);
  8004205525:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420552a:	c9                   	leaveq 
  800420552b:	c3                   	retq   

000000800420552c <_dwarf_frame_run_inst>:

static int
_dwarf_frame_run_inst(Dwarf_Debug dbg, Dwarf_Regtable3 *rt, uint8_t *insts,
		      Dwarf_Unsigned len, Dwarf_Unsigned caf, Dwarf_Signed daf, Dwarf_Addr pc,
		      Dwarf_Addr pc_req, Dwarf_Addr *row_pc, Dwarf_Error *error)
{
  800420552c:	55                   	push   %rbp
  800420552d:	48 89 e5             	mov    %rsp,%rbp
  8004205530:	53                   	push   %rbx
  8004205531:	48 81 ec 88 00 00 00 	sub    $0x88,%rsp
  8004205538:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
  800420553c:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
  8004205540:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
  8004205544:	48 89 4d 80          	mov    %rcx,-0x80(%rbp)
  8004205548:	4c 89 85 78 ff ff ff 	mov    %r8,-0x88(%rbp)
  800420554f:	4c 89 8d 70 ff ff ff 	mov    %r9,-0x90(%rbp)
			ret = DW_DLE_DF_REG_NUM_TOO_HIGH;               \
			goto program_done;                              \
		}                                                       \
	} while(0)

	ret = DW_DLE_NONE;
  8004205556:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
	init_rt = saved_rt = NULL;
  800420555d:	48 c7 45 a8 00 00 00 	movq   $0x0,-0x58(%rbp)
  8004205564:	00 
  8004205565:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004205569:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
	*row_pc = pc;
  800420556d:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205571:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205575:	48 89 10             	mov    %rdx,(%rax)

	/* Save a copy of the table as initial state. */
	_dwarf_frame_regtable_copy(dbg, &init_rt, rt, error);
  8004205578:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  800420557c:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004205580:	48 8d 75 b0          	lea    -0x50(%rbp),%rsi
  8004205584:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205588:	48 89 c7             	mov    %rax,%rdi
  800420558b:	48 b8 5e 53 20 04 80 	movabs $0x800420535e,%rax
  8004205592:	00 00 00 
  8004205595:	ff d0                	callq  *%rax
	p = insts;
  8004205597:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  800420559b:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
	pe = p + len;
  800420559f:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80042055a3:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  80042055a7:	48 01 d0             	add    %rdx,%rax
  80042055aa:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	while (p < pe) {
  80042055ae:	e9 47 0d 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		if (*p == DW_CFA_nop) {
  80042055b3:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042055b7:	0f b6 00             	movzbl (%rax),%eax
  80042055ba:	84 c0                	test   %al,%al
  80042055bc:	75 11                	jne    80042055cf <_dwarf_frame_run_inst+0xa3>
			p++;
  80042055be:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042055c2:	48 83 c0 01          	add    $0x1,%rax
  80042055c6:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
			continue;
  80042055ca:	e9 2b 0d 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		}

		high2 = *p & 0xc0;
  80042055cf:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042055d3:	0f b6 00             	movzbl (%rax),%eax
  80042055d6:	83 e0 c0             	and    $0xffffffc0,%eax
  80042055d9:	88 45 df             	mov    %al,-0x21(%rbp)
		low6 = *p & 0x3f;
  80042055dc:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042055e0:	0f b6 00             	movzbl (%rax),%eax
  80042055e3:	83 e0 3f             	and    $0x3f,%eax
  80042055e6:	88 45 de             	mov    %al,-0x22(%rbp)
		p++;
  80042055e9:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042055ed:	48 83 c0 01          	add    $0x1,%rax
  80042055f1:	48 89 45 a0          	mov    %rax,-0x60(%rbp)

		if (high2 > 0) {
  80042055f5:	80 7d df 00          	cmpb   $0x0,-0x21(%rbp)
  80042055f9:	0f 84 a7 01 00 00    	je     80042057a6 <_dwarf_frame_run_inst+0x27a>
			switch (high2) {
  80042055ff:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004205603:	3d 80 00 00 00       	cmp    $0x80,%eax
  8004205608:	74 37                	je     8004205641 <_dwarf_frame_run_inst+0x115>
  800420560a:	3d c0 00 00 00       	cmp    $0xc0,%eax
  800420560f:	0f 84 06 01 00 00    	je     800420571b <_dwarf_frame_run_inst+0x1ef>
  8004205615:	83 f8 40             	cmp    $0x40,%eax
  8004205618:	0f 85 76 01 00 00    	jne    8004205794 <_dwarf_frame_run_inst+0x268>
			case DW_CFA_advance_loc:
			        pc += low6 * caf;
  800420561e:	0f b6 45 de          	movzbl -0x22(%rbp),%eax
  8004205622:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  8004205629:	ff 
  800420562a:	48 01 45 10          	add    %rax,0x10(%rbp)
			        if (pc_req < pc)
  800420562e:	48 8b 45 18          	mov    0x18(%rbp),%rax
  8004205632:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  8004205636:	0f 83 64 01 00 00    	jae    80042057a0 <_dwarf_frame_run_inst+0x274>
			                goto program_done;
  800420563c:	e9 d3 0c 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			        break;
			case DW_CFA_offset:
			        *row_pc = pc;
  8004205641:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205645:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205649:	48 89 10             	mov    %rdx,(%rax)
			        CHECK_TABLE_SIZE(low6);
  800420564c:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205650:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205654:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205658:	66 39 c2             	cmp    %ax,%dx
  800420565b:	72 0c                	jb     8004205669 <_dwarf_frame_run_inst+0x13d>
  800420565d:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205664:	e9 ab 0c 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			        RL[low6].dw_offset_relevant = 1;
  8004205669:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420566d:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205671:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205675:	48 89 d0             	mov    %rdx,%rax
  8004205678:	48 01 c0             	add    %rax,%rax
  800420567b:	48 01 d0             	add    %rdx,%rax
  800420567e:	48 c1 e0 03          	shl    $0x3,%rax
  8004205682:	48 01 c8             	add    %rcx,%rax
  8004205685:	c6 00 01             	movb   $0x1,(%rax)
			        RL[low6].dw_value_type = DW_EXPR_OFFSET;
  8004205688:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420568c:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205690:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205694:	48 89 d0             	mov    %rdx,%rax
  8004205697:	48 01 c0             	add    %rax,%rax
  800420569a:	48 01 d0             	add    %rdx,%rax
  800420569d:	48 c1 e0 03          	shl    $0x3,%rax
  80042056a1:	48 01 c8             	add    %rcx,%rax
  80042056a4:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			        RL[low6].dw_regnum = dbg->dbg_frame_cfa_value;
  80042056a8:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042056ac:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042056b0:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  80042056b4:	48 89 d0             	mov    %rdx,%rax
  80042056b7:	48 01 c0             	add    %rax,%rax
  80042056ba:	48 01 d0             	add    %rdx,%rax
  80042056bd:	48 c1 e0 03          	shl    $0x3,%rax
  80042056c1:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042056c5:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042056c9:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  80042056cd:	66 89 42 02          	mov    %ax,0x2(%rdx)
			        RL[low6].dw_offset_or_block_len =
					_dwarf_decode_uleb128(&p) * daf;
  80042056d1:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042056d5:	48 89 c7             	mov    %rax,%rdi
  80042056d8:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  80042056df:	00 00 00 
  80042056e2:	ff d0                	callq  *%rax
  80042056e4:	48 89 c7             	mov    %rax,%rdi
  80042056e7:	48 8b 8d 70 ff ff ff 	mov    -0x90(%rbp),%rcx
			        RL[low6].dw_offset_or_block_len =
  80042056ee:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042056f2:	48 8b 70 20          	mov    0x20(%rax),%rsi
  80042056f6:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  80042056fa:	48 89 d0             	mov    %rdx,%rax
  80042056fd:	48 01 c0             	add    %rax,%rax
  8004205700:	48 01 d0             	add    %rdx,%rax
  8004205703:	48 c1 e0 03          	shl    $0x3,%rax
  8004205707:	48 8d 14 06          	lea    (%rsi,%rax,1),%rdx
					_dwarf_decode_uleb128(&p) * daf;
  800420570b:	48 89 f8             	mov    %rdi,%rax
  800420570e:	48 0f af c1          	imul   %rcx,%rax
			        RL[low6].dw_offset_or_block_len =
  8004205712:	48 89 42 08          	mov    %rax,0x8(%rdx)
			        break;
  8004205716:	e9 86 00 00 00       	jmpq   80042057a1 <_dwarf_frame_run_inst+0x275>
			case DW_CFA_restore:
			        *row_pc = pc;
  800420571b:	48 8b 45 20          	mov    0x20(%rbp),%rax
  800420571f:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205723:	48 89 10             	mov    %rdx,(%rax)
			        CHECK_TABLE_SIZE(low6);
  8004205726:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  800420572a:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420572e:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205732:	66 39 c2             	cmp    %ax,%dx
  8004205735:	72 0c                	jb     8004205743 <_dwarf_frame_run_inst+0x217>
  8004205737:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  800420573e:	e9 d1 0b 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			        memcpy(&RL[low6], &INITRL[low6],
  8004205743:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004205747:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420574b:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  800420574f:	48 89 d0             	mov    %rdx,%rax
  8004205752:	48 01 c0             	add    %rax,%rax
  8004205755:	48 01 d0             	add    %rdx,%rax
  8004205758:	48 c1 e0 03          	shl    $0x3,%rax
  800420575c:	48 01 c1             	add    %rax,%rcx
  800420575f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205763:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004205767:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  800420576b:	48 89 d0             	mov    %rdx,%rax
  800420576e:	48 01 c0             	add    %rax,%rax
  8004205771:	48 01 d0             	add    %rdx,%rax
  8004205774:	48 c1 e0 03          	shl    $0x3,%rax
  8004205778:	48 01 f0             	add    %rsi,%rax
  800420577b:	ba 18 00 00 00       	mov    $0x18,%edx
  8004205780:	48 89 ce             	mov    %rcx,%rsi
  8004205783:	48 89 c7             	mov    %rax,%rdi
  8004205786:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  800420578d:	00 00 00 
  8004205790:	ff d0                	callq  *%rax
				       sizeof(Dwarf_Regtable_Entry3));
			        break;
  8004205792:	eb 0d                	jmp    80042057a1 <_dwarf_frame_run_inst+0x275>
			default:
			        DWARF_SET_ERROR(dbg, error,
						DW_DLE_FRAME_INSTR_EXEC_ERROR);
			        ret = DW_DLE_FRAME_INSTR_EXEC_ERROR;
  8004205794:	c7 45 ec 15 00 00 00 	movl   $0x15,-0x14(%rbp)
			        goto program_done;
  800420579b:	e9 74 0b 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			        break;
  80042057a0:	90                   	nop
			}

			continue;
  80042057a1:	e9 54 0b 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		}

		switch (low6) {
  80042057a6:	0f b6 45 de          	movzbl -0x22(%rbp),%eax
  80042057aa:	83 f8 16             	cmp    $0x16,%eax
  80042057ad:	0f 87 3e 0b 00 00    	ja     80042062f1 <_dwarf_frame_run_inst+0xdc5>
  80042057b3:	89 c0                	mov    %eax,%eax
  80042057b5:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  80042057bc:	00 
  80042057bd:	48 b8 00 9f 20 04 80 	movabs $0x8004209f00,%rax
  80042057c4:	00 00 00 
  80042057c7:	48 01 d0             	add    %rdx,%rax
  80042057ca:	48 8b 00             	mov    (%rax),%rax
  80042057cd:	ff e0                	jmpq   *%rax
		case DW_CFA_set_loc:
			pc = dbg->decode(&p, dbg->dbg_pointer_size);
  80042057cf:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042057d3:	48 8b 40 20          	mov    0x20(%rax),%rax
  80042057d7:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  80042057db:	8b 4a 28             	mov    0x28(%rdx),%ecx
  80042057de:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
  80042057e2:	89 ce                	mov    %ecx,%esi
  80042057e4:	48 89 d7             	mov    %rdx,%rdi
  80042057e7:	ff d0                	callq  *%rax
  80042057e9:	48 89 45 10          	mov    %rax,0x10(%rbp)
			if (pc_req < pc)
  80042057ed:	48 8b 45 18          	mov    0x18(%rbp),%rax
  80042057f1:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  80042057f5:	0f 82 0f 0b 00 00    	jb     800420630a <_dwarf_frame_run_inst+0xdde>
			        goto program_done;
			break;
  80042057fb:	e9 fa 0a 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_advance_loc1:
			pc += dbg->decode(&p, 1) * caf;
  8004205800:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205804:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004205808:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
  800420580c:	be 01 00 00 00       	mov    $0x1,%esi
  8004205811:	48 89 d7             	mov    %rdx,%rdi
  8004205814:	ff d0                	callq  *%rax
  8004205816:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  800420581d:	ff 
  800420581e:	48 01 45 10          	add    %rax,0x10(%rbp)
			if (pc_req < pc)
  8004205822:	48 8b 45 18          	mov    0x18(%rbp),%rax
  8004205826:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  800420582a:	0f 82 dd 0a 00 00    	jb     800420630d <_dwarf_frame_run_inst+0xde1>
			        goto program_done;
			break;
  8004205830:	e9 c5 0a 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_advance_loc2:
			pc += dbg->decode(&p, 2) * caf;
  8004205835:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205839:	48 8b 40 20          	mov    0x20(%rax),%rax
  800420583d:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
  8004205841:	be 02 00 00 00       	mov    $0x2,%esi
  8004205846:	48 89 d7             	mov    %rdx,%rdi
  8004205849:	ff d0                	callq  *%rax
  800420584b:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  8004205852:	ff 
  8004205853:	48 01 45 10          	add    %rax,0x10(%rbp)
			if (pc_req < pc)
  8004205857:	48 8b 45 18          	mov    0x18(%rbp),%rax
  800420585b:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  800420585f:	0f 82 ab 0a 00 00    	jb     8004206310 <_dwarf_frame_run_inst+0xde4>
			        goto program_done;
			break;
  8004205865:	e9 90 0a 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_advance_loc4:
			pc += dbg->decode(&p, 4) * caf;
  800420586a:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420586e:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004205872:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
  8004205876:	be 04 00 00 00       	mov    $0x4,%esi
  800420587b:	48 89 d7             	mov    %rdx,%rdi
  800420587e:	ff d0                	callq  *%rax
  8004205880:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  8004205887:	ff 
  8004205888:	48 01 45 10          	add    %rax,0x10(%rbp)
			if (pc_req < pc)
  800420588c:	48 8b 45 18          	mov    0x18(%rbp),%rax
  8004205890:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  8004205894:	0f 82 79 0a 00 00    	jb     8004206313 <_dwarf_frame_run_inst+0xde7>
			        goto program_done;
			break;
  800420589a:	e9 5b 0a 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_offset_extended:
			*row_pc = pc;
  800420589f:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042058a3:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042058a7:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  80042058aa:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042058ae:	48 89 c7             	mov    %rax,%rdi
  80042058b1:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  80042058b8:	00 00 00 
  80042058bb:	ff d0                	callq  *%rax
  80042058bd:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			uoff = _dwarf_decode_uleb128(&p);
  80042058c1:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042058c5:	48 89 c7             	mov    %rax,%rdi
  80042058c8:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  80042058cf:	00 00 00 
  80042058d2:	ff d0                	callq  *%rax
  80042058d4:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
			CHECK_TABLE_SIZE(reg);
  80042058d8:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042058dc:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042058e0:	0f b7 c0             	movzwl %ax,%eax
  80042058e3:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  80042058e7:	72 0c                	jb     80042058f5 <_dwarf_frame_run_inst+0x3c9>
  80042058e9:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  80042058f0:	e9 1f 0a 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 1;
  80042058f5:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042058f9:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042058fd:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205901:	48 89 d0             	mov    %rdx,%rax
  8004205904:	48 01 c0             	add    %rax,%rax
  8004205907:	48 01 d0             	add    %rdx,%rax
  800420590a:	48 c1 e0 03          	shl    $0x3,%rax
  800420590e:	48 01 c8             	add    %rcx,%rax
  8004205911:	c6 00 01             	movb   $0x1,(%rax)
			RL[reg].dw_value_type = DW_EXPR_OFFSET;
  8004205914:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205918:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420591c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205920:	48 89 d0             	mov    %rdx,%rax
  8004205923:	48 01 c0             	add    %rax,%rax
  8004205926:	48 01 d0             	add    %rdx,%rax
  8004205929:	48 c1 e0 03          	shl    $0x3,%rax
  800420592d:	48 01 c8             	add    %rcx,%rax
  8004205930:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  8004205934:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205938:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420593c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205940:	48 89 d0             	mov    %rdx,%rax
  8004205943:	48 01 c0             	add    %rax,%rax
  8004205946:	48 01 d0             	add    %rdx,%rax
  8004205949:	48 c1 e0 03          	shl    $0x3,%rax
  800420594d:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205951:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205955:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  8004205959:	66 89 42 02          	mov    %ax,0x2(%rdx)
			RL[reg].dw_offset_or_block_len = uoff * daf;
  800420595d:	48 8b 8d 70 ff ff ff 	mov    -0x90(%rbp),%rcx
  8004205964:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205968:	48 8b 70 20          	mov    0x20(%rax),%rsi
  800420596c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205970:	48 89 d0             	mov    %rdx,%rax
  8004205973:	48 01 c0             	add    %rax,%rax
  8004205976:	48 01 d0             	add    %rdx,%rax
  8004205979:	48 c1 e0 03          	shl    $0x3,%rax
  800420597d:	48 8d 14 06          	lea    (%rsi,%rax,1),%rdx
  8004205981:	48 89 c8             	mov    %rcx,%rax
  8004205984:	48 0f af 45 c0       	imul   -0x40(%rbp),%rax
  8004205989:	48 89 42 08          	mov    %rax,0x8(%rdx)
			break;
  800420598d:	e9 68 09 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_restore_extended:
			*row_pc = pc;
  8004205992:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205996:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  800420599a:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  800420599d:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042059a1:	48 89 c7             	mov    %rax,%rdi
  80042059a4:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  80042059ab:	00 00 00 
  80042059ae:	ff d0                	callq  *%rax
  80042059b0:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			CHECK_TABLE_SIZE(reg);
  80042059b4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042059b8:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042059bc:	0f b7 c0             	movzwl %ax,%eax
  80042059bf:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  80042059c3:	72 0c                	jb     80042059d1 <_dwarf_frame_run_inst+0x4a5>
  80042059c5:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  80042059cc:	e9 43 09 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			memcpy(&RL[reg], &INITRL[reg],
  80042059d1:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042059d5:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042059d9:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042059dd:	48 89 d0             	mov    %rdx,%rax
  80042059e0:	48 01 c0             	add    %rax,%rax
  80042059e3:	48 01 d0             	add    %rdx,%rax
  80042059e6:	48 c1 e0 03          	shl    $0x3,%rax
  80042059ea:	48 01 c1             	add    %rax,%rcx
  80042059ed:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042059f1:	48 8b 70 20          	mov    0x20(%rax),%rsi
  80042059f5:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042059f9:	48 89 d0             	mov    %rdx,%rax
  80042059fc:	48 01 c0             	add    %rax,%rax
  80042059ff:	48 01 d0             	add    %rdx,%rax
  8004205a02:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a06:	48 01 f0             	add    %rsi,%rax
  8004205a09:	ba 18 00 00 00       	mov    $0x18,%edx
  8004205a0e:	48 89 ce             	mov    %rcx,%rsi
  8004205a11:	48 89 c7             	mov    %rax,%rdi
  8004205a14:	48 b8 a3 30 20 04 80 	movabs $0x80042030a3,%rax
  8004205a1b:	00 00 00 
  8004205a1e:	ff d0                	callq  *%rax
			       sizeof(Dwarf_Regtable_Entry3));
			break;
  8004205a20:	e9 d5 08 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_undefined:
			*row_pc = pc;
  8004205a25:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205a29:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205a2d:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205a30:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205a34:	48 89 c7             	mov    %rax,%rdi
  8004205a37:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205a3e:	00 00 00 
  8004205a41:	ff d0                	callq  *%rax
  8004205a43:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004205a47:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205a4b:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205a4f:	0f b7 c0             	movzwl %ax,%eax
  8004205a52:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004205a56:	72 0c                	jb     8004205a64 <_dwarf_frame_run_inst+0x538>
  8004205a58:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205a5f:	e9 b0 08 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 0;
  8004205a64:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205a68:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205a6c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205a70:	48 89 d0             	mov    %rdx,%rax
  8004205a73:	48 01 c0             	add    %rax,%rax
  8004205a76:	48 01 d0             	add    %rdx,%rax
  8004205a79:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a7d:	48 01 c8             	add    %rcx,%rax
  8004205a80:	c6 00 00             	movb   $0x0,(%rax)
			RL[reg].dw_regnum = dbg->dbg_frame_undefined_value;
  8004205a83:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205a87:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205a8b:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205a8f:	48 89 d0             	mov    %rdx,%rax
  8004205a92:	48 01 c0             	add    %rax,%rax
  8004205a95:	48 01 d0             	add    %rdx,%rax
  8004205a98:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a9c:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205aa0:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205aa4:	0f b7 40 50          	movzwl 0x50(%rax),%eax
  8004205aa8:	66 89 42 02          	mov    %ax,0x2(%rdx)
			break;
  8004205aac:	e9 49 08 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_same_value:
			reg = _dwarf_decode_uleb128(&p);
  8004205ab1:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205ab5:	48 89 c7             	mov    %rax,%rdi
  8004205ab8:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205abf:	00 00 00 
  8004205ac2:	ff d0                	callq  *%rax
  8004205ac4:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004205ac8:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205acc:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205ad0:	0f b7 c0             	movzwl %ax,%eax
  8004205ad3:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004205ad7:	72 0c                	jb     8004205ae5 <_dwarf_frame_run_inst+0x5b9>
  8004205ad9:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205ae0:	e9 2f 08 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 0;
  8004205ae5:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ae9:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205aed:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205af1:	48 89 d0             	mov    %rdx,%rax
  8004205af4:	48 01 c0             	add    %rax,%rax
  8004205af7:	48 01 d0             	add    %rdx,%rax
  8004205afa:	48 c1 e0 03          	shl    $0x3,%rax
  8004205afe:	48 01 c8             	add    %rcx,%rax
  8004205b01:	c6 00 00             	movb   $0x0,(%rax)
			RL[reg].dw_regnum = dbg->dbg_frame_same_value;
  8004205b04:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205b08:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205b0c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205b10:	48 89 d0             	mov    %rdx,%rax
  8004205b13:	48 01 c0             	add    %rax,%rax
  8004205b16:	48 01 d0             	add    %rdx,%rax
  8004205b19:	48 c1 e0 03          	shl    $0x3,%rax
  8004205b1d:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205b21:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205b25:	0f b7 40 4e          	movzwl 0x4e(%rax),%eax
  8004205b29:	66 89 42 02          	mov    %ax,0x2(%rdx)
			break;
  8004205b2d:	e9 c8 07 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_register:
			*row_pc = pc;
  8004205b32:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205b36:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205b3a:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205b3d:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205b41:	48 89 c7             	mov    %rax,%rdi
  8004205b44:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205b4b:	00 00 00 
  8004205b4e:	ff d0                	callq  *%rax
  8004205b50:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			reg2 = _dwarf_decode_uleb128(&p);
  8004205b54:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205b58:	48 89 c7             	mov    %rax,%rdi
  8004205b5b:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205b62:	00 00 00 
  8004205b65:	ff d0                	callq  *%rax
  8004205b67:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004205b6b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205b6f:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205b73:	0f b7 c0             	movzwl %ax,%eax
  8004205b76:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004205b7a:	72 0c                	jb     8004205b88 <_dwarf_frame_run_inst+0x65c>
  8004205b7c:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205b83:	e9 8c 07 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 0;
  8004205b88:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205b8c:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205b90:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205b94:	48 89 d0             	mov    %rdx,%rax
  8004205b97:	48 01 c0             	add    %rax,%rax
  8004205b9a:	48 01 d0             	add    %rdx,%rax
  8004205b9d:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ba1:	48 01 c8             	add    %rcx,%rax
  8004205ba4:	c6 00 00             	movb   $0x0,(%rax)
			RL[reg].dw_regnum = reg2;
  8004205ba7:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205bab:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205baf:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205bb3:	48 89 d0             	mov    %rdx,%rax
  8004205bb6:	48 01 c0             	add    %rax,%rax
  8004205bb9:	48 01 d0             	add    %rdx,%rax
  8004205bbc:	48 c1 e0 03          	shl    $0x3,%rax
  8004205bc0:	48 01 c8             	add    %rcx,%rax
  8004205bc3:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8004205bc7:	66 89 50 02          	mov    %dx,0x2(%rax)
			break;
  8004205bcb:	e9 2a 07 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_remember_state:
			_dwarf_frame_regtable_copy(dbg, &saved_rt, rt, error);
  8004205bd0:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  8004205bd4:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004205bd8:	48 8d 75 a8          	lea    -0x58(%rbp),%rsi
  8004205bdc:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205be0:	48 89 c7             	mov    %rax,%rdi
  8004205be3:	48 b8 5e 53 20 04 80 	movabs $0x800420535e,%rax
  8004205bea:	00 00 00 
  8004205bed:	ff d0                	callq  *%rax
			break;
  8004205bef:	e9 06 07 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_restore_state:
			*row_pc = pc;
  8004205bf4:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205bf8:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205bfc:	48 89 10             	mov    %rdx,(%rax)
			_dwarf_frame_regtable_copy(dbg, &rt, saved_rt, error);
  8004205bff:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004205c03:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004205c07:	48 8d 75 90          	lea    -0x70(%rbp),%rsi
  8004205c0b:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205c0f:	48 89 c7             	mov    %rax,%rdi
  8004205c12:	48 b8 5e 53 20 04 80 	movabs $0x800420535e,%rax
  8004205c19:	00 00 00 
  8004205c1c:	ff d0                	callq  *%rax
			break;
  8004205c1e:	e9 d7 06 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_def_cfa:
			*row_pc = pc;
  8004205c23:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205c27:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205c2b:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205c2e:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205c32:	48 89 c7             	mov    %rax,%rdi
  8004205c35:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205c3c:	00 00 00 
  8004205c3f:	ff d0                	callq  *%rax
  8004205c41:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			uoff = _dwarf_decode_uleb128(&p);
  8004205c45:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205c49:	48 89 c7             	mov    %rax,%rdi
  8004205c4c:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205c53:	00 00 00 
  8004205c56:	ff d0                	callq  *%rax
  8004205c58:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
			CFA.dw_offset_relevant = 1;
  8004205c5c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c60:	c6 00 01             	movb   $0x1,(%rax)
			CFA.dw_value_type = DW_EXPR_OFFSET;
  8004205c63:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c67:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			CFA.dw_regnum = reg;
  8004205c6b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c6f:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205c73:	66 89 50 02          	mov    %dx,0x2(%rax)
			CFA.dw_offset_or_block_len = uoff;
  8004205c77:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c7b:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004205c7f:	48 89 50 08          	mov    %rdx,0x8(%rax)
			break;
  8004205c83:	e9 72 06 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_def_cfa_register:
			*row_pc = pc;
  8004205c88:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205c8c:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205c90:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205c93:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205c97:	48 89 c7             	mov    %rax,%rdi
  8004205c9a:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205ca1:	00 00 00 
  8004205ca4:	ff d0                	callq  *%rax
  8004205ca6:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			CFA.dw_regnum = reg;
  8004205caa:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205cae:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205cb2:	66 89 50 02          	mov    %dx,0x2(%rax)
			 * Note that DW_CFA_def_cfa_register change the CFA
			 * rule register while keep the old offset. So we
			 * should not touch the CFA.dw_offset_relevant flag
			 * here.
			 */
			break;
  8004205cb6:	e9 3f 06 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_def_cfa_offset:
			*row_pc = pc;
  8004205cbb:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205cbf:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205cc3:	48 89 10             	mov    %rdx,(%rax)
			uoff = _dwarf_decode_uleb128(&p);
  8004205cc6:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205cca:	48 89 c7             	mov    %rax,%rdi
  8004205ccd:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205cd4:	00 00 00 
  8004205cd7:	ff d0                	callq  *%rax
  8004205cd9:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
			CFA.dw_offset_relevant = 1;
  8004205cdd:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ce1:	c6 00 01             	movb   $0x1,(%rax)
			CFA.dw_value_type = DW_EXPR_OFFSET;
  8004205ce4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ce8:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			CFA.dw_offset_or_block_len = uoff;
  8004205cec:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205cf0:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004205cf4:	48 89 50 08          	mov    %rdx,0x8(%rax)
			break;
  8004205cf8:	e9 fd 05 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_def_cfa_expression:
			*row_pc = pc;
  8004205cfd:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205d01:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205d05:	48 89 10             	mov    %rdx,(%rax)
			CFA.dw_offset_relevant = 0;
  8004205d08:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d0c:	c6 00 00             	movb   $0x0,(%rax)
			CFA.dw_value_type = DW_EXPR_EXPRESSION;
  8004205d0f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d13:	c6 40 01 02          	movb   $0x2,0x1(%rax)
			CFA.dw_offset_or_block_len = _dwarf_decode_uleb128(&p);
  8004205d17:	48 8b 5d 90          	mov    -0x70(%rbp),%rbx
  8004205d1b:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205d1f:	48 89 c7             	mov    %rax,%rdi
  8004205d22:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205d29:	00 00 00 
  8004205d2c:	ff d0                	callq  *%rax
  8004205d2e:	48 89 43 08          	mov    %rax,0x8(%rbx)
			CFA.dw_block_ptr = p;
  8004205d32:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d36:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004205d3a:	48 89 50 10          	mov    %rdx,0x10(%rax)
			p += CFA.dw_offset_or_block_len;
  8004205d3e:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004205d42:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d46:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004205d4a:	48 01 d0             	add    %rdx,%rax
  8004205d4d:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
			break;
  8004205d51:	e9 a4 05 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_expression:
			*row_pc = pc;
  8004205d56:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205d5a:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205d5e:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205d61:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205d65:	48 89 c7             	mov    %rax,%rdi
  8004205d68:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205d6f:	00 00 00 
  8004205d72:	ff d0                	callq  *%rax
  8004205d74:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004205d78:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d7c:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205d80:	0f b7 c0             	movzwl %ax,%eax
  8004205d83:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004205d87:	72 0c                	jb     8004205d95 <_dwarf_frame_run_inst+0x869>
  8004205d89:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205d90:	e9 7f 05 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 0;
  8004205d95:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d99:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205d9d:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205da1:	48 89 d0             	mov    %rdx,%rax
  8004205da4:	48 01 c0             	add    %rax,%rax
  8004205da7:	48 01 d0             	add    %rdx,%rax
  8004205daa:	48 c1 e0 03          	shl    $0x3,%rax
  8004205dae:	48 01 c8             	add    %rcx,%rax
  8004205db1:	c6 00 00             	movb   $0x0,(%rax)
			RL[reg].dw_value_type = DW_EXPR_EXPRESSION;
  8004205db4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205db8:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205dbc:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205dc0:	48 89 d0             	mov    %rdx,%rax
  8004205dc3:	48 01 c0             	add    %rax,%rax
  8004205dc6:	48 01 d0             	add    %rdx,%rax
  8004205dc9:	48 c1 e0 03          	shl    $0x3,%rax
  8004205dcd:	48 01 c8             	add    %rcx,%rax
  8004205dd0:	c6 40 01 02          	movb   $0x2,0x1(%rax)
			RL[reg].dw_offset_or_block_len =
  8004205dd4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205dd8:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205ddc:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205de0:	48 89 d0             	mov    %rdx,%rax
  8004205de3:	48 01 c0             	add    %rax,%rax
  8004205de6:	48 01 d0             	add    %rdx,%rax
  8004205de9:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ded:	48 8d 1c 01          	lea    (%rcx,%rax,1),%rbx
				_dwarf_decode_uleb128(&p);
  8004205df1:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205df5:	48 89 c7             	mov    %rax,%rdi
  8004205df8:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205dff:	00 00 00 
  8004205e02:	ff d0                	callq  *%rax
			RL[reg].dw_offset_or_block_len =
  8004205e04:	48 89 43 08          	mov    %rax,0x8(%rbx)
			RL[reg].dw_block_ptr = p;
  8004205e08:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e0c:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205e10:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205e14:	48 89 d0             	mov    %rdx,%rax
  8004205e17:	48 01 c0             	add    %rax,%rax
  8004205e1a:	48 01 d0             	add    %rdx,%rax
  8004205e1d:	48 c1 e0 03          	shl    $0x3,%rax
  8004205e21:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205e25:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004205e29:	48 89 42 10          	mov    %rax,0x10(%rdx)
			p += RL[reg].dw_offset_or_block_len;
  8004205e2d:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  8004205e31:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e35:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004205e39:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205e3d:	48 89 d0             	mov    %rdx,%rax
  8004205e40:	48 01 c0             	add    %rax,%rax
  8004205e43:	48 01 d0             	add    %rdx,%rax
  8004205e46:	48 c1 e0 03          	shl    $0x3,%rax
  8004205e4a:	48 01 f0             	add    %rsi,%rax
  8004205e4d:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004205e51:	48 01 c8             	add    %rcx,%rax
  8004205e54:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
			break;
  8004205e58:	e9 9d 04 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_offset_extended_sf:
			*row_pc = pc;
  8004205e5d:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205e61:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205e65:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205e68:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205e6c:	48 89 c7             	mov    %rax,%rdi
  8004205e6f:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205e76:	00 00 00 
  8004205e79:	ff d0                	callq  *%rax
  8004205e7b:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			soff = _dwarf_decode_sleb128(&p);
  8004205e7f:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205e83:	48 89 c7             	mov    %rax,%rdi
  8004205e86:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  8004205e8d:	00 00 00 
  8004205e90:	ff d0                	callq  *%rax
  8004205e92:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004205e96:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e9a:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205e9e:	0f b7 c0             	movzwl %ax,%eax
  8004205ea1:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004205ea5:	72 0c                	jb     8004205eb3 <_dwarf_frame_run_inst+0x987>
  8004205ea7:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205eae:	e9 61 04 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 1;
  8004205eb3:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205eb7:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205ebb:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205ebf:	48 89 d0             	mov    %rdx,%rax
  8004205ec2:	48 01 c0             	add    %rax,%rax
  8004205ec5:	48 01 d0             	add    %rdx,%rax
  8004205ec8:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ecc:	48 01 c8             	add    %rcx,%rax
  8004205ecf:	c6 00 01             	movb   $0x1,(%rax)
			RL[reg].dw_value_type = DW_EXPR_OFFSET;
  8004205ed2:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ed6:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205eda:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205ede:	48 89 d0             	mov    %rdx,%rax
  8004205ee1:	48 01 c0             	add    %rax,%rax
  8004205ee4:	48 01 d0             	add    %rdx,%rax
  8004205ee7:	48 c1 e0 03          	shl    $0x3,%rax
  8004205eeb:	48 01 c8             	add    %rcx,%rax
  8004205eee:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  8004205ef2:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ef6:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205efa:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205efe:	48 89 d0             	mov    %rdx,%rax
  8004205f01:	48 01 c0             	add    %rax,%rax
  8004205f04:	48 01 d0             	add    %rdx,%rax
  8004205f07:	48 c1 e0 03          	shl    $0x3,%rax
  8004205f0b:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205f0f:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205f13:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  8004205f17:	66 89 42 02          	mov    %ax,0x2(%rdx)
			RL[reg].dw_offset_or_block_len = soff * daf;
  8004205f1b:	48 8b 8d 70 ff ff ff 	mov    -0x90(%rbp),%rcx
  8004205f22:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f26:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004205f2a:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205f2e:	48 89 d0             	mov    %rdx,%rax
  8004205f31:	48 01 c0             	add    %rax,%rax
  8004205f34:	48 01 d0             	add    %rdx,%rax
  8004205f37:	48 c1 e0 03          	shl    $0x3,%rax
  8004205f3b:	48 8d 14 06          	lea    (%rsi,%rax,1),%rdx
  8004205f3f:	48 89 c8             	mov    %rcx,%rax
  8004205f42:	48 0f af 45 c8       	imul   -0x38(%rbp),%rax
  8004205f47:	48 89 42 08          	mov    %rax,0x8(%rdx)
			break;
  8004205f4b:	e9 aa 03 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_def_cfa_sf:
			*row_pc = pc;
  8004205f50:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205f54:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205f58:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004205f5b:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205f5f:	48 89 c7             	mov    %rax,%rdi
  8004205f62:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004205f69:	00 00 00 
  8004205f6c:	ff d0                	callq  *%rax
  8004205f6e:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			soff = _dwarf_decode_sleb128(&p);
  8004205f72:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205f76:	48 89 c7             	mov    %rax,%rdi
  8004205f79:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  8004205f80:	00 00 00 
  8004205f83:	ff d0                	callq  *%rax
  8004205f85:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
			CFA.dw_offset_relevant = 1;
  8004205f89:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f8d:	c6 00 01             	movb   $0x1,(%rax)
			CFA.dw_value_type = DW_EXPR_OFFSET;
  8004205f90:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f94:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			CFA.dw_regnum = reg;
  8004205f98:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f9c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205fa0:	66 89 50 02          	mov    %dx,0x2(%rax)
			CFA.dw_offset_or_block_len = soff * daf;
  8004205fa4:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  8004205fab:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205faf:	48 0f af 55 c8       	imul   -0x38(%rbp),%rdx
  8004205fb4:	48 89 50 08          	mov    %rdx,0x8(%rax)
			break;
  8004205fb8:	e9 3d 03 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_def_cfa_offset_sf:
			*row_pc = pc;
  8004205fbd:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205fc1:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205fc5:	48 89 10             	mov    %rdx,(%rax)
			soff = _dwarf_decode_sleb128(&p);
  8004205fc8:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205fcc:	48 89 c7             	mov    %rax,%rdi
  8004205fcf:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  8004205fd6:	00 00 00 
  8004205fd9:	ff d0                	callq  *%rax
  8004205fdb:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
			CFA.dw_offset_relevant = 1;
  8004205fdf:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205fe3:	c6 00 01             	movb   $0x1,(%rax)
			CFA.dw_value_type = DW_EXPR_OFFSET;
  8004205fe6:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205fea:	c6 40 01 00          	movb   $0x0,0x1(%rax)
			CFA.dw_offset_or_block_len = soff * daf;
  8004205fee:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  8004205ff5:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ff9:	48 0f af 55 c8       	imul   -0x38(%rbp),%rdx
  8004205ffe:	48 89 50 08          	mov    %rdx,0x8(%rax)
			break;
  8004206002:	e9 f3 02 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_val_offset:
			*row_pc = pc;
  8004206007:	48 8b 45 20          	mov    0x20(%rbp),%rax
  800420600b:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  800420600f:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004206012:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004206016:	48 89 c7             	mov    %rax,%rdi
  8004206019:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004206020:	00 00 00 
  8004206023:	ff d0                	callq  *%rax
  8004206025:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			uoff = _dwarf_decode_uleb128(&p);
  8004206029:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  800420602d:	48 89 c7             	mov    %rax,%rdi
  8004206030:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004206037:	00 00 00 
  800420603a:	ff d0                	callq  *%rax
  800420603c:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004206040:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206044:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004206048:	0f b7 c0             	movzwl %ax,%eax
  800420604b:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  800420604f:	72 0c                	jb     800420605d <_dwarf_frame_run_inst+0xb31>
  8004206051:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004206058:	e9 b7 02 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 1;
  800420605d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206061:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206065:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206069:	48 89 d0             	mov    %rdx,%rax
  800420606c:	48 01 c0             	add    %rax,%rax
  800420606f:	48 01 d0             	add    %rdx,%rax
  8004206072:	48 c1 e0 03          	shl    $0x3,%rax
  8004206076:	48 01 c8             	add    %rcx,%rax
  8004206079:	c6 00 01             	movb   $0x1,(%rax)
			RL[reg].dw_value_type = DW_EXPR_VAL_OFFSET;
  800420607c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206080:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206084:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206088:	48 89 d0             	mov    %rdx,%rax
  800420608b:	48 01 c0             	add    %rax,%rax
  800420608e:	48 01 d0             	add    %rdx,%rax
  8004206091:	48 c1 e0 03          	shl    $0x3,%rax
  8004206095:	48 01 c8             	add    %rcx,%rax
  8004206098:	c6 40 01 01          	movb   $0x1,0x1(%rax)
			RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  800420609c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042060a0:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042060a4:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042060a8:	48 89 d0             	mov    %rdx,%rax
  80042060ab:	48 01 c0             	add    %rax,%rax
  80042060ae:	48 01 d0             	add    %rdx,%rax
  80042060b1:	48 c1 e0 03          	shl    $0x3,%rax
  80042060b5:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042060b9:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042060bd:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  80042060c1:	66 89 42 02          	mov    %ax,0x2(%rdx)
			RL[reg].dw_offset_or_block_len = uoff * daf;
  80042060c5:	48 8b 8d 70 ff ff ff 	mov    -0x90(%rbp),%rcx
  80042060cc:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042060d0:	48 8b 70 20          	mov    0x20(%rax),%rsi
  80042060d4:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042060d8:	48 89 d0             	mov    %rdx,%rax
  80042060db:	48 01 c0             	add    %rax,%rax
  80042060de:	48 01 d0             	add    %rdx,%rax
  80042060e1:	48 c1 e0 03          	shl    $0x3,%rax
  80042060e5:	48 8d 14 06          	lea    (%rsi,%rax,1),%rdx
  80042060e9:	48 89 c8             	mov    %rcx,%rax
  80042060ec:	48 0f af 45 c0       	imul   -0x40(%rbp),%rax
  80042060f1:	48 89 42 08          	mov    %rax,0x8(%rdx)
			break;
  80042060f5:	e9 00 02 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_val_offset_sf:
			*row_pc = pc;
  80042060fa:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042060fe:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004206102:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  8004206105:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004206109:	48 89 c7             	mov    %rax,%rdi
  800420610c:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004206113:	00 00 00 
  8004206116:	ff d0                	callq  *%rax
  8004206118:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			soff = _dwarf_decode_sleb128(&p);
  800420611c:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004206120:	48 89 c7             	mov    %rax,%rdi
  8004206123:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  800420612a:	00 00 00 
  800420612d:	ff d0                	callq  *%rax
  800420612f:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
			CHECK_TABLE_SIZE(reg);
  8004206133:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206137:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  800420613b:	0f b7 c0             	movzwl %ax,%eax
  800420613e:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  8004206142:	72 0c                	jb     8004206150 <_dwarf_frame_run_inst+0xc24>
  8004206144:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  800420614b:	e9 c4 01 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 1;
  8004206150:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206154:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206158:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420615c:	48 89 d0             	mov    %rdx,%rax
  800420615f:	48 01 c0             	add    %rax,%rax
  8004206162:	48 01 d0             	add    %rdx,%rax
  8004206165:	48 c1 e0 03          	shl    $0x3,%rax
  8004206169:	48 01 c8             	add    %rcx,%rax
  800420616c:	c6 00 01             	movb   $0x1,(%rax)
			RL[reg].dw_value_type = DW_EXPR_VAL_OFFSET;
  800420616f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206173:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206177:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420617b:	48 89 d0             	mov    %rdx,%rax
  800420617e:	48 01 c0             	add    %rax,%rax
  8004206181:	48 01 d0             	add    %rdx,%rax
  8004206184:	48 c1 e0 03          	shl    $0x3,%rax
  8004206188:	48 01 c8             	add    %rcx,%rax
  800420618b:	c6 40 01 01          	movb   $0x1,0x1(%rax)
			RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  800420618f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206193:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206197:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420619b:	48 89 d0             	mov    %rdx,%rax
  800420619e:	48 01 c0             	add    %rax,%rax
  80042061a1:	48 01 d0             	add    %rdx,%rax
  80042061a4:	48 c1 e0 03          	shl    $0x3,%rax
  80042061a8:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042061ac:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042061b0:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  80042061b4:	66 89 42 02          	mov    %ax,0x2(%rdx)
			RL[reg].dw_offset_or_block_len = soff * daf;
  80042061b8:	48 8b 8d 70 ff ff ff 	mov    -0x90(%rbp),%rcx
  80042061bf:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042061c3:	48 8b 70 20          	mov    0x20(%rax),%rsi
  80042061c7:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042061cb:	48 89 d0             	mov    %rdx,%rax
  80042061ce:	48 01 c0             	add    %rax,%rax
  80042061d1:	48 01 d0             	add    %rdx,%rax
  80042061d4:	48 c1 e0 03          	shl    $0x3,%rax
  80042061d8:	48 8d 14 06          	lea    (%rsi,%rax,1),%rdx
  80042061dc:	48 89 c8             	mov    %rcx,%rax
  80042061df:	48 0f af 45 c8       	imul   -0x38(%rbp),%rax
  80042061e4:	48 89 42 08          	mov    %rax,0x8(%rdx)
			break;
  80042061e8:	e9 0d 01 00 00       	jmpq   80042062fa <_dwarf_frame_run_inst+0xdce>
		case DW_CFA_val_expression:
			*row_pc = pc;
  80042061ed:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042061f1:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042061f5:	48 89 10             	mov    %rdx,(%rax)
			reg = _dwarf_decode_uleb128(&p);
  80042061f8:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042061fc:	48 89 c7             	mov    %rax,%rdi
  80042061ff:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004206206:	00 00 00 
  8004206209:	ff d0                	callq  *%rax
  800420620b:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
			CHECK_TABLE_SIZE(reg);
  800420620f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206213:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004206217:	0f b7 c0             	movzwl %ax,%eax
  800420621a:	48 39 45 d0          	cmp    %rax,-0x30(%rbp)
  800420621e:	72 0c                	jb     800420622c <_dwarf_frame_run_inst+0xd00>
  8004206220:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004206227:	e9 e8 00 00 00       	jmpq   8004206314 <_dwarf_frame_run_inst+0xde8>
			RL[reg].dw_offset_relevant = 0;
  800420622c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206230:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206234:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206238:	48 89 d0             	mov    %rdx,%rax
  800420623b:	48 01 c0             	add    %rax,%rax
  800420623e:	48 01 d0             	add    %rdx,%rax
  8004206241:	48 c1 e0 03          	shl    $0x3,%rax
  8004206245:	48 01 c8             	add    %rcx,%rax
  8004206248:	c6 00 00             	movb   $0x0,(%rax)
			RL[reg].dw_value_type = DW_EXPR_VAL_EXPRESSION;
  800420624b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420624f:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206253:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206257:	48 89 d0             	mov    %rdx,%rax
  800420625a:	48 01 c0             	add    %rax,%rax
  800420625d:	48 01 d0             	add    %rdx,%rax
  8004206260:	48 c1 e0 03          	shl    $0x3,%rax
  8004206264:	48 01 c8             	add    %rcx,%rax
  8004206267:	c6 40 01 03          	movb   $0x3,0x1(%rax)
			RL[reg].dw_offset_or_block_len =
  800420626b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420626f:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206273:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206277:	48 89 d0             	mov    %rdx,%rax
  800420627a:	48 01 c0             	add    %rax,%rax
  800420627d:	48 01 d0             	add    %rdx,%rax
  8004206280:	48 c1 e0 03          	shl    $0x3,%rax
  8004206284:	48 8d 1c 01          	lea    (%rcx,%rax,1),%rbx
				_dwarf_decode_uleb128(&p);
  8004206288:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  800420628c:	48 89 c7             	mov    %rax,%rdi
  800420628f:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004206296:	00 00 00 
  8004206299:	ff d0                	callq  *%rax
			RL[reg].dw_offset_or_block_len =
  800420629b:	48 89 43 08          	mov    %rax,0x8(%rbx)
			RL[reg].dw_block_ptr = p;
  800420629f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042062a3:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042062a7:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042062ab:	48 89 d0             	mov    %rdx,%rax
  80042062ae:	48 01 c0             	add    %rax,%rax
  80042062b1:	48 01 d0             	add    %rdx,%rax
  80042062b4:	48 c1 e0 03          	shl    $0x3,%rax
  80042062b8:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042062bc:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042062c0:	48 89 42 10          	mov    %rax,0x10(%rdx)
			p += RL[reg].dw_offset_or_block_len;
  80042062c4:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  80042062c8:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042062cc:	48 8b 70 20          	mov    0x20(%rax),%rsi
  80042062d0:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042062d4:	48 89 d0             	mov    %rdx,%rax
  80042062d7:	48 01 c0             	add    %rax,%rax
  80042062da:	48 01 d0             	add    %rdx,%rax
  80042062dd:	48 c1 e0 03          	shl    $0x3,%rax
  80042062e1:	48 01 f0             	add    %rsi,%rax
  80042062e4:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042062e8:	48 01 c8             	add    %rcx,%rax
  80042062eb:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
			break;
  80042062ef:	eb 09                	jmp    80042062fa <_dwarf_frame_run_inst+0xdce>
		default:
			DWARF_SET_ERROR(dbg, error,
					DW_DLE_FRAME_INSTR_EXEC_ERROR);
			ret = DW_DLE_FRAME_INSTR_EXEC_ERROR;
  80042062f1:	c7 45 ec 15 00 00 00 	movl   $0x15,-0x14(%rbp)
			goto program_done;
  80042062f8:	eb 1a                	jmp    8004206314 <_dwarf_frame_run_inst+0xde8>
	while (p < pe) {
  80042062fa:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042062fe:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004206302:	0f 87 ab f2 ff ff    	ja     80042055b3 <_dwarf_frame_run_inst+0x87>
		}
	}

program_done:
  8004206308:	eb 0a                	jmp    8004206314 <_dwarf_frame_run_inst+0xde8>
			        goto program_done;
  800420630a:	90                   	nop
  800420630b:	eb 07                	jmp    8004206314 <_dwarf_frame_run_inst+0xde8>
			        goto program_done;
  800420630d:	90                   	nop
  800420630e:	eb 04                	jmp    8004206314 <_dwarf_frame_run_inst+0xde8>
			        goto program_done;
  8004206310:	90                   	nop
  8004206311:	eb 01                	jmp    8004206314 <_dwarf_frame_run_inst+0xde8>
			        goto program_done;
  8004206313:	90                   	nop
	return (ret);
  8004206314:	8b 45 ec             	mov    -0x14(%rbp),%eax
#undef  CFA
#undef  INITCFA
#undef  RL
#undef  INITRL
#undef  CHECK_TABLE_SIZE
}
  8004206317:	48 81 c4 88 00 00 00 	add    $0x88,%rsp
  800420631e:	5b                   	pop    %rbx
  800420631f:	5d                   	pop    %rbp
  8004206320:	c3                   	retq   

0000008004206321 <_dwarf_frame_get_internal_table>:
int
_dwarf_frame_get_internal_table(Dwarf_Debug dbg, Dwarf_Fde fde,
				Dwarf_Addr pc_req, Dwarf_Regtable3 **ret_rt,
				Dwarf_Addr *ret_row_pc,
				Dwarf_Error *error)
{
  8004206321:	55                   	push   %rbp
  8004206322:	48 89 e5             	mov    %rsp,%rbp
  8004206325:	48 83 ec 60          	sub    $0x60,%rsp
  8004206329:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  800420632d:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  8004206331:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004206335:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  8004206339:	4c 89 45 a8          	mov    %r8,-0x58(%rbp)
  800420633d:	4c 89 4d a0          	mov    %r9,-0x60(%rbp)
	Dwarf_Cie cie;
	Dwarf_Regtable3 *rt;
	Dwarf_Addr row_pc;
	int i, ret;

	assert(ret_rt != NULL);
  8004206341:	48 83 7d b0 00       	cmpq   $0x0,-0x50(%rbp)
  8004206346:	75 35                	jne    800420637d <_dwarf_frame_get_internal_table+0x5c>
  8004206348:	48 b9 b8 9f 20 04 80 	movabs $0x8004209fb8,%rcx
  800420634f:	00 00 00 
  8004206352:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  8004206359:	00 00 00 
  800420635c:	be 83 01 00 00       	mov    $0x183,%esi
  8004206361:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  8004206368:	00 00 00 
  800420636b:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206370:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004206377:	00 00 00 
  800420637a:	41 ff d0             	callq  *%r8

	//dbg = fde->fde_dbg;
	assert(dbg != NULL);
  800420637d:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004206382:	75 35                	jne    80042063b9 <_dwarf_frame_get_internal_table+0x98>
  8004206384:	48 b9 c7 9f 20 04 80 	movabs $0x8004209fc7,%rcx
  800420638b:	00 00 00 
  800420638e:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  8004206395:	00 00 00 
  8004206398:	be 86 01 00 00       	mov    $0x186,%esi
  800420639d:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  80042063a4:	00 00 00 
  80042063a7:	b8 00 00 00 00       	mov    $0x0,%eax
  80042063ac:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042063b3:	00 00 00 
  80042063b6:	41 ff d0             	callq  *%r8

	rt = dbg->dbg_internal_reg_table;
  80042063b9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042063bd:	48 8b 40 58          	mov    0x58(%rax),%rax
  80042063c1:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	/* Clear the content of regtable from previous run. */
	memset(&rt->rt3_cfa_rule, 0, sizeof(Dwarf_Regtable_Entry3));
  80042063c5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042063c9:	ba 18 00 00 00       	mov    $0x18,%edx
  80042063ce:	be 00 00 00 00       	mov    $0x0,%esi
  80042063d3:	48 89 c7             	mov    %rax,%rdi
  80042063d6:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  80042063dd:	00 00 00 
  80042063e0:	ff d0                	callq  *%rax
	memset(rt->rt3_rules, 0, rt->rt3_reg_table_size *
  80042063e2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042063e6:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042063ea:	0f b7 d0             	movzwl %ax,%edx
  80042063ed:	48 89 d0             	mov    %rdx,%rax
  80042063f0:	48 01 c0             	add    %rax,%rax
  80042063f3:	48 01 d0             	add    %rdx,%rax
  80042063f6:	48 c1 e0 03          	shl    $0x3,%rax
  80042063fa:	48 89 c2             	mov    %rax,%rdx
  80042063fd:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206401:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004206405:	be 00 00 00 00       	mov    $0x0,%esi
  800420640a:	48 89 c7             	mov    %rax,%rdi
  800420640d:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  8004206414:	00 00 00 
  8004206417:	ff d0                	callq  *%rax
	       sizeof(Dwarf_Regtable_Entry3));

	/* Set rules to initial values. */
	for (i = 0; i < rt->rt3_reg_table_size; i++)
  8004206419:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004206420:	eb 2f                	jmp    8004206451 <_dwarf_frame_get_internal_table+0x130>
		rt->rt3_rules[i].dw_regnum = dbg->dbg_frame_rule_initial_value;
  8004206422:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206426:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420642a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420642d:	48 63 d0             	movslq %eax,%rdx
  8004206430:	48 89 d0             	mov    %rdx,%rax
  8004206433:	48 01 c0             	add    %rax,%rax
  8004206436:	48 01 d0             	add    %rdx,%rax
  8004206439:	48 c1 e0 03          	shl    $0x3,%rax
  800420643d:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004206441:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206445:	0f b7 40 4a          	movzwl 0x4a(%rax),%eax
  8004206449:	66 89 42 02          	mov    %ax,0x2(%rdx)
	for (i = 0; i < rt->rt3_reg_table_size; i++)
  800420644d:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004206451:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206455:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004206459:	0f b7 c0             	movzwl %ax,%eax
  800420645c:	39 45 fc             	cmp    %eax,-0x4(%rbp)
  800420645f:	7c c1                	jl     8004206422 <_dwarf_frame_get_internal_table+0x101>

	/* Run initial instructions in CIE. */
	cie = fde->fde_cie;
  8004206461:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206465:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206469:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	assert(cie != NULL);
  800420646d:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004206472:	75 35                	jne    80042064a9 <_dwarf_frame_get_internal_table+0x188>
  8004206474:	48 b9 d3 9f 20 04 80 	movabs $0x8004209fd3,%rcx
  800420647b:	00 00 00 
  800420647e:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  8004206485:	00 00 00 
  8004206488:	be 95 01 00 00       	mov    $0x195,%esi
  800420648d:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  8004206494:	00 00 00 
  8004206497:	b8 00 00 00 00       	mov    $0x0,%eax
  800420649c:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042064a3:	00 00 00 
  80042064a6:	41 ff d0             	callq  *%r8
	ret = _dwarf_frame_run_inst(dbg, rt, cie->cie_initinst,
  80042064a9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042064ad:	4c 8b 48 40          	mov    0x40(%rax),%r9
  80042064b1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042064b5:	4c 8b 40 38          	mov    0x38(%rax),%r8
  80042064b9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042064bd:	48 8b 48 70          	mov    0x70(%rax),%rcx
  80042064c1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042064c5:	48 8b 50 68          	mov    0x68(%rax),%rdx
  80042064c9:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  80042064cd:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042064d1:	ff 75 a0             	pushq  -0x60(%rbp)
  80042064d4:	48 8d 7d d8          	lea    -0x28(%rbp),%rdi
  80042064d8:	57                   	push   %rdi
  80042064d9:	6a ff                	pushq  $0xffffffffffffffff
  80042064db:	6a 00                	pushq  $0x0
  80042064dd:	48 89 c7             	mov    %rax,%rdi
  80042064e0:	48 b8 2c 55 20 04 80 	movabs $0x800420552c,%rax
  80042064e7:	00 00 00 
  80042064ea:	ff d0                	callq  *%rax
  80042064ec:	48 83 c4 20          	add    $0x20,%rsp
  80042064f0:	89 45 e4             	mov    %eax,-0x1c(%rbp)
				    cie->cie_instlen, cie->cie_caf,
				    cie->cie_daf, 0, ~0ULL,
				    &row_pc, error);
	if (ret != DW_DLE_NONE)
  80042064f3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  80042064f7:	74 08                	je     8004206501 <_dwarf_frame_get_internal_table+0x1e0>
		return (ret);
  80042064f9:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042064fc:	e9 8a 00 00 00       	jmpq   800420658b <_dwarf_frame_get_internal_table+0x26a>
	/* Run instructions in FDE. */
	if (pc_req >= fde->fde_initloc) {
  8004206501:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206505:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004206509:	48 39 45 b8          	cmp    %rax,-0x48(%rbp)
  800420650d:	72 61                	jb     8004206570 <_dwarf_frame_get_internal_table+0x24f>
		ret = _dwarf_frame_run_inst(dbg, rt, fde->fde_inst,
  800420650f:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206513:	48 8b 78 30          	mov    0x30(%rax),%rdi
  8004206517:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420651b:	4c 8b 48 40          	mov    0x40(%rax),%r9
  800420651f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206523:	4c 8b 50 38          	mov    0x38(%rax),%r10
  8004206527:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420652b:	48 8b 48 58          	mov    0x58(%rax),%rcx
  800420652f:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206533:	48 8b 50 50          	mov    0x50(%rax),%rdx
  8004206537:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  800420653b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420653f:	ff 75 a0             	pushq  -0x60(%rbp)
  8004206542:	4c 8d 45 d8          	lea    -0x28(%rbp),%r8
  8004206546:	41 50                	push   %r8
  8004206548:	ff 75 b8             	pushq  -0x48(%rbp)
  800420654b:	57                   	push   %rdi
  800420654c:	4d 89 d0             	mov    %r10,%r8
  800420654f:	48 89 c7             	mov    %rax,%rdi
  8004206552:	48 b8 2c 55 20 04 80 	movabs $0x800420552c,%rax
  8004206559:	00 00 00 
  800420655c:	ff d0                	callq  *%rax
  800420655e:	48 83 c4 20          	add    $0x20,%rsp
  8004206562:	89 45 e4             	mov    %eax,-0x1c(%rbp)
					    fde->fde_instlen, cie->cie_caf,
					    cie->cie_daf,
					    fde->fde_initloc, pc_req,
					    &row_pc, error);
		if (ret != DW_DLE_NONE)
  8004206565:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004206569:	74 05                	je     8004206570 <_dwarf_frame_get_internal_table+0x24f>
			return (ret);
  800420656b:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  800420656e:	eb 1b                	jmp    800420658b <_dwarf_frame_get_internal_table+0x26a>
	}

	*ret_rt = rt;
  8004206570:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004206574:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004206578:	48 89 10             	mov    %rdx,(%rax)
	*ret_row_pc = row_pc;
  800420657b:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  800420657f:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004206583:	48 89 10             	mov    %rdx,(%rax)

	return (DW_DLE_NONE);
  8004206586:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420658b:	c9                   	leaveq 
  800420658c:	c3                   	retq   

000000800420658d <dwarf_get_fde_info_for_all_regs>:
int
dwarf_get_fde_info_for_all_regs(Dwarf_Debug dbg, Dwarf_Fde fde,
				Dwarf_Addr pc_requested,
				Dwarf_Regtable *reg_table, Dwarf_Addr *row_pc,
				Dwarf_Error *error)
{
  800420658d:	55                   	push   %rbp
  800420658e:	48 89 e5             	mov    %rsp,%rbp
  8004206591:	48 83 ec 50          	sub    $0x50,%rsp
  8004206595:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004206599:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  800420659d:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  80042065a1:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
  80042065a5:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  80042065a9:	4c 89 4d b0          	mov    %r9,-0x50(%rbp)
	Dwarf_Regtable3 *rt;
	Dwarf_Addr pc;
	Dwarf_Half cfa;
	int i, ret;

	if (fde == NULL || reg_table == NULL) {
  80042065ad:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  80042065b2:	74 07                	je     80042065bb <dwarf_get_fde_info_for_all_regs+0x2e>
  80042065b4:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
  80042065b9:	75 0a                	jne    80042065c5 <dwarf_get_fde_info_for_all_regs+0x38>
		DWARF_SET_ERROR(dbg, error, DW_DLE_ARGUMENT);
		return (DW_DLV_ERROR);
  80042065bb:	b8 01 00 00 00       	mov    $0x1,%eax
  80042065c0:	e9 f9 02 00 00       	jmpq   80042068be <dwarf_get_fde_info_for_all_regs+0x331>
	}

	assert(dbg != NULL);
  80042065c5:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80042065ca:	75 35                	jne    8004206601 <dwarf_get_fde_info_for_all_regs+0x74>
  80042065cc:	48 b9 c7 9f 20 04 80 	movabs $0x8004209fc7,%rcx
  80042065d3:	00 00 00 
  80042065d6:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  80042065dd:	00 00 00 
  80042065e0:	be bf 01 00 00       	mov    $0x1bf,%esi
  80042065e5:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  80042065ec:	00 00 00 
  80042065ef:	b8 00 00 00 00       	mov    $0x0,%eax
  80042065f4:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  80042065fb:	00 00 00 
  80042065fe:	41 ff d0             	callq  *%r8

	if (pc_requested < fde->fde_initloc ||
  8004206601:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004206605:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004206609:	48 39 45 c8          	cmp    %rax,-0x38(%rbp)
  800420660d:	72 19                	jb     8004206628 <dwarf_get_fde_info_for_all_regs+0x9b>
	    pc_requested >= fde->fde_initloc + fde->fde_adrange) {
  800420660f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004206613:	48 8b 50 30          	mov    0x30(%rax),%rdx
  8004206617:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420661b:	48 8b 40 38          	mov    0x38(%rax),%rax
  800420661f:	48 01 d0             	add    %rdx,%rax
	if (pc_requested < fde->fde_initloc ||
  8004206622:	48 39 45 c8          	cmp    %rax,-0x38(%rbp)
  8004206626:	72 0a                	jb     8004206632 <dwarf_get_fde_info_for_all_regs+0xa5>
		DWARF_SET_ERROR(dbg, error, DW_DLE_PC_NOT_IN_FDE_RANGE);
		return (DW_DLV_ERROR);
  8004206628:	b8 01 00 00 00       	mov    $0x1,%eax
  800420662d:	e9 8c 02 00 00       	jmpq   80042068be <dwarf_get_fde_info_for_all_regs+0x331>
	}

	ret = _dwarf_frame_get_internal_table(dbg, fde, pc_requested, &rt, &pc,
  8004206632:	4c 8b 45 b0          	mov    -0x50(%rbp),%r8
  8004206636:	48 8d 7d e0          	lea    -0x20(%rbp),%rdi
  800420663a:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  800420663e:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206642:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8004206646:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420664a:	4d 89 c1             	mov    %r8,%r9
  800420664d:	49 89 f8             	mov    %rdi,%r8
  8004206650:	48 89 c7             	mov    %rax,%rdi
  8004206653:	48 b8 21 63 20 04 80 	movabs $0x8004206321,%rax
  800420665a:	00 00 00 
  800420665d:	ff d0                	callq  *%rax
  800420665f:	89 45 f8             	mov    %eax,-0x8(%rbp)
					      error);
	if (ret != DW_DLE_NONE)
  8004206662:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004206666:	74 0a                	je     8004206672 <dwarf_get_fde_info_for_all_regs+0xe5>
		return (DW_DLV_ERROR);
  8004206668:	b8 01 00 00 00       	mov    $0x1,%eax
  800420666d:	e9 4c 02 00 00       	jmpq   80042068be <dwarf_get_fde_info_for_all_regs+0x331>
	/*
	 * Copy the CFA rule to the column intended for holding the CFA,
	 * if it's within the range of regtable.
	 */
#define CFA rt->rt3_cfa_rule
	cfa = dbg->dbg_frame_cfa_value;
  8004206672:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206676:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  800420667a:	66 89 45 f6          	mov    %ax,-0xa(%rbp)
	if (cfa < DW_REG_TABLE_SIZE) {
  800420667e:	66 83 7d f6 41       	cmpw   $0x41,-0xa(%rbp)
  8004206683:	0f 87 b7 00 00 00    	ja     8004206740 <dwarf_get_fde_info_for_all_regs+0x1b3>
		reg_table->rules[cfa].dw_offset_relevant =
			CFA.dw_offset_relevant;
  8004206689:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
		reg_table->rules[cfa].dw_offset_relevant =
  800420668d:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
			CFA.dw_offset_relevant;
  8004206691:	0f b6 00             	movzbl (%rax),%eax
		reg_table->rules[cfa].dw_offset_relevant =
  8004206694:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004206698:	48 63 c9             	movslq %ecx,%rcx
  800420669b:	48 83 c1 01          	add    $0x1,%rcx
  800420669f:	48 c1 e1 04          	shl    $0x4,%rcx
  80042066a3:	48 01 ca             	add    %rcx,%rdx
  80042066a6:	88 02                	mov    %al,(%rdx)
		reg_table->rules[cfa].dw_value_type = CFA.dw_value_type;
  80042066a8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042066ac:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
  80042066b0:	0f b6 40 01          	movzbl 0x1(%rax),%eax
  80042066b4:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042066b8:	48 63 c9             	movslq %ecx,%rcx
  80042066bb:	48 83 c1 01          	add    $0x1,%rcx
  80042066bf:	48 c1 e1 04          	shl    $0x4,%rcx
  80042066c3:	48 01 ca             	add    %rcx,%rdx
  80042066c6:	48 83 c2 01          	add    $0x1,%rdx
  80042066ca:	88 02                	mov    %al,(%rdx)
		reg_table->rules[cfa].dw_regnum = CFA.dw_regnum;
  80042066cc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042066d0:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
  80042066d4:	0f b7 40 02          	movzwl 0x2(%rax),%eax
  80042066d8:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042066dc:	48 63 c9             	movslq %ecx,%rcx
  80042066df:	48 83 c1 01          	add    $0x1,%rcx
  80042066e3:	48 c1 e1 04          	shl    $0x4,%rcx
  80042066e7:	48 01 ca             	add    %rcx,%rdx
  80042066ea:	48 83 c2 02          	add    $0x2,%rdx
  80042066ee:	66 89 02             	mov    %ax,(%rdx)
		reg_table->rules[cfa].dw_offset = CFA.dw_offset_or_block_len;
  80042066f1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042066f5:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
  80042066f9:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042066fd:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004206701:	48 63 c9             	movslq %ecx,%rcx
  8004206704:	48 83 c1 01          	add    $0x1,%rcx
  8004206708:	48 c1 e1 04          	shl    $0x4,%rcx
  800420670c:	48 01 ca             	add    %rcx,%rdx
  800420670f:	48 83 c2 08          	add    $0x8,%rdx
  8004206713:	48 89 02             	mov    %rax,(%rdx)
		reg_table->cfa_rule = reg_table->rules[cfa];
  8004206716:	0f b7 55 f6          	movzwl -0xa(%rbp),%edx
  800420671a:	48 8b 4d c0          	mov    -0x40(%rbp),%rcx
  800420671e:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206722:	48 63 d2             	movslq %edx,%rdx
  8004206725:	48 83 c2 01          	add    $0x1,%rdx
  8004206729:	48 c1 e2 04          	shl    $0x4,%rdx
  800420672d:	48 01 d0             	add    %rdx,%rax
  8004206730:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004206734:	48 8b 00             	mov    (%rax),%rax
  8004206737:	48 89 01             	mov    %rax,(%rcx)
  800420673a:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  800420673e:	eb 3c                	jmp    800420677c <dwarf_get_fde_info_for_all_regs+0x1ef>
	} else {
		reg_table->cfa_rule.dw_offset_relevant =
		    CFA.dw_offset_relevant;
  8004206740:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206744:	0f b6 10             	movzbl (%rax),%edx
		reg_table->cfa_rule.dw_offset_relevant =
  8004206747:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420674b:	88 10                	mov    %dl,(%rax)
		reg_table->cfa_rule.dw_value_type = CFA.dw_value_type;
  800420674d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206751:	0f b6 50 01          	movzbl 0x1(%rax),%edx
  8004206755:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206759:	88 50 01             	mov    %dl,0x1(%rax)
		reg_table->cfa_rule.dw_regnum = CFA.dw_regnum;
  800420675c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206760:	0f b7 50 02          	movzwl 0x2(%rax),%edx
  8004206764:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206768:	66 89 50 02          	mov    %dx,0x2(%rax)
		reg_table->cfa_rule.dw_offset = CFA.dw_offset_or_block_len;
  800420676c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206770:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004206774:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206778:	48 89 50 08          	mov    %rdx,0x8(%rax)
	}

	/*
	 * Copy other columns.
	 */
	for (i = 0; i < DW_REG_TABLE_SIZE && i < dbg->dbg_frame_rule_table_size;
  800420677c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004206783:	e9 05 01 00 00       	jmpq   800420688d <dwarf_get_fde_info_for_all_regs+0x300>
	     i++) {

		/* Do not overwrite CFA column */
		if (i == cfa)
  8004206788:	0f b7 45 f6          	movzwl -0xa(%rbp),%eax
  800420678c:	39 45 fc             	cmp    %eax,-0x4(%rbp)
  800420678f:	0f 84 f3 00 00 00    	je     8004206888 <dwarf_get_fde_info_for_all_regs+0x2fb>
			continue;

		reg_table->rules[i].dw_offset_relevant =
			rt->rt3_rules[i].dw_offset_relevant;
  8004206795:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206799:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420679d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042067a0:	48 63 d0             	movslq %eax,%rdx
  80042067a3:	48 89 d0             	mov    %rdx,%rax
  80042067a6:	48 01 c0             	add    %rax,%rax
  80042067a9:	48 01 d0             	add    %rdx,%rax
  80042067ac:	48 c1 e0 03          	shl    $0x3,%rax
  80042067b0:	48 01 c8             	add    %rcx,%rax
  80042067b3:	0f b6 00             	movzbl (%rax),%eax
		reg_table->rules[i].dw_offset_relevant =
  80042067b6:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042067ba:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  80042067bd:	48 63 c9             	movslq %ecx,%rcx
  80042067c0:	48 83 c1 01          	add    $0x1,%rcx
  80042067c4:	48 c1 e1 04          	shl    $0x4,%rcx
  80042067c8:	48 01 ca             	add    %rcx,%rdx
  80042067cb:	88 02                	mov    %al,(%rdx)
		reg_table->rules[i].dw_value_type =
			rt->rt3_rules[i].dw_value_type;
  80042067cd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042067d1:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042067d5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042067d8:	48 63 d0             	movslq %eax,%rdx
  80042067db:	48 89 d0             	mov    %rdx,%rax
  80042067de:	48 01 c0             	add    %rax,%rax
  80042067e1:	48 01 d0             	add    %rdx,%rax
  80042067e4:	48 c1 e0 03          	shl    $0x3,%rax
  80042067e8:	48 01 c8             	add    %rcx,%rax
  80042067eb:	0f b6 40 01          	movzbl 0x1(%rax),%eax
		reg_table->rules[i].dw_value_type =
  80042067ef:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042067f3:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  80042067f6:	48 63 c9             	movslq %ecx,%rcx
  80042067f9:	48 83 c1 01          	add    $0x1,%rcx
  80042067fd:	48 c1 e1 04          	shl    $0x4,%rcx
  8004206801:	48 01 ca             	add    %rcx,%rdx
  8004206804:	48 83 c2 01          	add    $0x1,%rdx
  8004206808:	88 02                	mov    %al,(%rdx)
		reg_table->rules[i].dw_regnum = rt->rt3_rules[i].dw_regnum;
  800420680a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420680e:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206812:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004206815:	48 63 d0             	movslq %eax,%rdx
  8004206818:	48 89 d0             	mov    %rdx,%rax
  800420681b:	48 01 c0             	add    %rax,%rax
  800420681e:	48 01 d0             	add    %rdx,%rax
  8004206821:	48 c1 e0 03          	shl    $0x3,%rax
  8004206825:	48 01 c8             	add    %rcx,%rax
  8004206828:	0f b7 40 02          	movzwl 0x2(%rax),%eax
  800420682c:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004206830:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  8004206833:	48 63 c9             	movslq %ecx,%rcx
  8004206836:	48 83 c1 01          	add    $0x1,%rcx
  800420683a:	48 c1 e1 04          	shl    $0x4,%rcx
  800420683e:	48 01 ca             	add    %rcx,%rdx
  8004206841:	48 83 c2 02          	add    $0x2,%rdx
  8004206845:	66 89 02             	mov    %ax,(%rdx)
		reg_table->rules[i].dw_offset =
			rt->rt3_rules[i].dw_offset_or_block_len;
  8004206848:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420684c:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206850:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004206853:	48 63 d0             	movslq %eax,%rdx
  8004206856:	48 89 d0             	mov    %rdx,%rax
  8004206859:	48 01 c0             	add    %rax,%rax
  800420685c:	48 01 d0             	add    %rdx,%rax
  800420685f:	48 c1 e0 03          	shl    $0x3,%rax
  8004206863:	48 01 c8             	add    %rcx,%rax
  8004206866:	48 8b 40 08          	mov    0x8(%rax),%rax
		reg_table->rules[i].dw_offset =
  800420686a:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800420686e:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  8004206871:	48 63 c9             	movslq %ecx,%rcx
  8004206874:	48 83 c1 01          	add    $0x1,%rcx
  8004206878:	48 c1 e1 04          	shl    $0x4,%rcx
  800420687c:	48 01 ca             	add    %rcx,%rdx
  800420687f:	48 83 c2 08          	add    $0x8,%rdx
  8004206883:	48 89 02             	mov    %rax,(%rdx)
  8004206886:	eb 01                	jmp    8004206889 <dwarf_get_fde_info_for_all_regs+0x2fc>
			continue;
  8004206888:	90                   	nop
	     i++) {
  8004206889:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
	for (i = 0; i < DW_REG_TABLE_SIZE && i < dbg->dbg_frame_rule_table_size;
  800420688d:	83 7d fc 41          	cmpl   $0x41,-0x4(%rbp)
  8004206891:	7f 14                	jg     80042068a7 <dwarf_get_fde_info_for_all_regs+0x31a>
  8004206893:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206897:	0f b7 40 48          	movzwl 0x48(%rax),%eax
  800420689b:	0f b7 c0             	movzwl %ax,%eax
  800420689e:	39 45 fc             	cmp    %eax,-0x4(%rbp)
  80042068a1:	0f 8c e1 fe ff ff    	jl     8004206788 <dwarf_get_fde_info_for_all_regs+0x1fb>
	}

	if (row_pc) *row_pc = pc;
  80042068a7:	48 83 7d b8 00       	cmpq   $0x0,-0x48(%rbp)
  80042068ac:	74 0b                	je     80042068b9 <dwarf_get_fde_info_for_all_regs+0x32c>
  80042068ae:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042068b2:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042068b6:	48 89 10             	mov    %rdx,(%rax)
	return (DW_DLV_OK);
  80042068b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042068be:	c9                   	leaveq 
  80042068bf:	c3                   	retq   

00000080042068c0 <_dwarf_frame_read_lsb_encoded>:

static int
_dwarf_frame_read_lsb_encoded(Dwarf_Debug dbg, uint64_t *val, uint8_t *data,
			      uint64_t *offsetp, uint8_t encode, Dwarf_Addr pc, Dwarf_Error *error)
{
  80042068c0:	55                   	push   %rbp
  80042068c1:	48 89 e5             	mov    %rsp,%rbp
  80042068c4:	48 83 ec 40          	sub    $0x40,%rsp
  80042068c8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042068cc:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80042068d0:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80042068d4:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  80042068d8:	44 89 c0             	mov    %r8d,%eax
  80042068db:	4c 89 4d c0          	mov    %r9,-0x40(%rbp)
  80042068df:	88 45 cc             	mov    %al,-0x34(%rbp)
	uint8_t application;

	if (encode == DW_EH_PE_omit)
  80042068e2:	80 7d cc ff          	cmpb   $0xff,-0x34(%rbp)
  80042068e6:	75 0a                	jne    80042068f2 <_dwarf_frame_read_lsb_encoded+0x32>
		return (DW_DLE_NONE);
  80042068e8:	b8 00 00 00 00       	mov    $0x0,%eax
  80042068ed:	e9 fb 01 00 00       	jmpq   8004206aed <_dwarf_frame_read_lsb_encoded+0x22d>

	application = encode & 0xf0;
  80042068f2:	0f b6 45 cc          	movzbl -0x34(%rbp),%eax
  80042068f6:	83 e0 f0             	and    $0xfffffff0,%eax
  80042068f9:	88 45 ff             	mov    %al,-0x1(%rbp)
	encode &= 0x0f;
  80042068fc:	80 65 cc 0f          	andb   $0xf,-0x34(%rbp)

	switch (encode) {
  8004206900:	0f b6 45 cc          	movzbl -0x34(%rbp),%eax
  8004206904:	83 f8 0c             	cmp    $0xc,%eax
  8004206907:	0f 87 84 01 00 00    	ja     8004206a91 <_dwarf_frame_read_lsb_encoded+0x1d1>
  800420690d:	89 c0                	mov    %eax,%eax
  800420690f:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  8004206916:	00 
  8004206917:	48 b8 e0 9f 20 04 80 	movabs $0x8004209fe0,%rax
  800420691e:	00 00 00 
  8004206921:	48 01 d0             	add    %rdx,%rax
  8004206924:	48 8b 00             	mov    (%rax),%rax
  8004206927:	ff e0                	jmpq   *%rax
	case DW_EH_PE_absptr:
		*val = dbg->read(data, offsetp, dbg->dbg_pointer_size);
  8004206929:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420692d:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206931:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004206935:	8b 52 28             	mov    0x28(%rdx),%edx
  8004206938:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  800420693c:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004206940:	48 89 cf             	mov    %rcx,%rdi
  8004206943:	ff d0                	callq  *%rax
  8004206945:	48 89 c2             	mov    %rax,%rdx
  8004206948:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420694c:	48 89 10             	mov    %rdx,(%rax)
		break;
  800420694f:	e9 44 01 00 00       	jmpq   8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_uleb128:
		*val = _dwarf_read_uleb128(data, offsetp);
  8004206954:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206958:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420695c:	48 89 d6             	mov    %rdx,%rsi
  800420695f:	48 89 c7             	mov    %rax,%rdi
  8004206962:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004206969:	00 00 00 
  800420696c:	ff d0                	callq  *%rax
  800420696e:	48 89 c2             	mov    %rax,%rdx
  8004206971:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206975:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206978:	e9 1b 01 00 00       	jmpq   8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_udata2:
		*val = dbg->read(data, offsetp, 2);
  800420697d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206981:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206985:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8004206989:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  800420698d:	ba 02 00 00 00       	mov    $0x2,%edx
  8004206992:	48 89 cf             	mov    %rcx,%rdi
  8004206995:	ff d0                	callq  *%rax
  8004206997:	48 89 c2             	mov    %rax,%rdx
  800420699a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420699e:	48 89 10             	mov    %rdx,(%rax)
		break;
  80042069a1:	e9 f2 00 00 00       	jmpq   8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_udata4:
		*val = dbg->read(data, offsetp, 4);
  80042069a6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042069aa:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042069ae:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  80042069b2:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  80042069b6:	ba 04 00 00 00       	mov    $0x4,%edx
  80042069bb:	48 89 cf             	mov    %rcx,%rdi
  80042069be:	ff d0                	callq  *%rax
  80042069c0:	48 89 c2             	mov    %rax,%rdx
  80042069c3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042069c7:	48 89 10             	mov    %rdx,(%rax)
		break;
  80042069ca:	e9 c9 00 00 00       	jmpq   8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_udata8:
		*val = dbg->read(data, offsetp, 8);
  80042069cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042069d3:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042069d7:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  80042069db:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  80042069df:	ba 08 00 00 00       	mov    $0x8,%edx
  80042069e4:	48 89 cf             	mov    %rcx,%rdi
  80042069e7:	ff d0                	callq  *%rax
  80042069e9:	48 89 c2             	mov    %rax,%rdx
  80042069ec:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042069f0:	48 89 10             	mov    %rdx,(%rax)
		break;
  80042069f3:	e9 a0 00 00 00       	jmpq   8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_sleb128:
		*val = _dwarf_read_sleb128(data, offsetp);
  80042069f8:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042069fc:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206a00:	48 89 d6             	mov    %rdx,%rsi
  8004206a03:	48 89 c7             	mov    %rax,%rdi
  8004206a06:	48 b8 6f 39 20 04 80 	movabs $0x800420396f,%rax
  8004206a0d:	00 00 00 
  8004206a10:	ff d0                	callq  *%rax
  8004206a12:	48 89 c2             	mov    %rax,%rdx
  8004206a15:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206a19:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206a1c:	eb 7a                	jmp    8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_sdata2:
		*val = (int16_t) dbg->read(data, offsetp, 2);
  8004206a1e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206a22:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206a26:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8004206a2a:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004206a2e:	ba 02 00 00 00       	mov    $0x2,%edx
  8004206a33:	48 89 cf             	mov    %rcx,%rdi
  8004206a36:	ff d0                	callq  *%rax
  8004206a38:	48 0f bf d0          	movswq %ax,%rdx
  8004206a3c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206a40:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206a43:	eb 53                	jmp    8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_sdata4:
		*val = (int32_t) dbg->read(data, offsetp, 4);
  8004206a45:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206a49:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206a4d:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8004206a51:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004206a55:	ba 04 00 00 00       	mov    $0x4,%edx
  8004206a5a:	48 89 cf             	mov    %rcx,%rdi
  8004206a5d:	ff d0                	callq  *%rax
  8004206a5f:	48 63 d0             	movslq %eax,%rdx
  8004206a62:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206a66:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206a69:	eb 2d                	jmp    8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	case DW_EH_PE_sdata8:
		*val = dbg->read(data, offsetp, 8);
  8004206a6b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206a6f:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206a73:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8004206a77:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004206a7b:	ba 08 00 00 00       	mov    $0x8,%edx
  8004206a80:	48 89 cf             	mov    %rcx,%rdi
  8004206a83:	ff d0                	callq  *%rax
  8004206a85:	48 89 c2             	mov    %rax,%rdx
  8004206a88:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206a8c:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206a8f:	eb 07                	jmp    8004206a98 <_dwarf_frame_read_lsb_encoded+0x1d8>
	default:
		DWARF_SET_ERROR(dbg, error, DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
		return (DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
  8004206a91:	b8 14 00 00 00       	mov    $0x14,%eax
  8004206a96:	eb 55                	jmp    8004206aed <_dwarf_frame_read_lsb_encoded+0x22d>
	}

	if (application == DW_EH_PE_pcrel) {
  8004206a98:	80 7d ff 10          	cmpb   $0x10,-0x1(%rbp)
  8004206a9c:	75 46                	jne    8004206ae4 <_dwarf_frame_read_lsb_encoded+0x224>
		/*
		 * Value is relative to .eh_frame section virtual addr.
		 */
		switch (encode) {
  8004206a9e:	0f b6 45 cc          	movzbl -0x34(%rbp),%eax
  8004206aa2:	83 f8 01             	cmp    $0x1,%eax
  8004206aa5:	7c 40                	jl     8004206ae7 <_dwarf_frame_read_lsb_encoded+0x227>
  8004206aa7:	83 f8 04             	cmp    $0x4,%eax
  8004206aaa:	7e 0a                	jle    8004206ab6 <_dwarf_frame_read_lsb_encoded+0x1f6>
  8004206aac:	83 e8 09             	sub    $0x9,%eax
  8004206aaf:	83 f8 03             	cmp    $0x3,%eax
  8004206ab2:	77 33                	ja     8004206ae7 <_dwarf_frame_read_lsb_encoded+0x227>
  8004206ab4:	eb 17                	jmp    8004206acd <_dwarf_frame_read_lsb_encoded+0x20d>
		case DW_EH_PE_uleb128:
		case DW_EH_PE_udata2:
		case DW_EH_PE_udata4:
		case DW_EH_PE_udata8:
			*val += pc;
  8004206ab6:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206aba:	48 8b 10             	mov    (%rax),%rdx
  8004206abd:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206ac1:	48 01 c2             	add    %rax,%rdx
  8004206ac4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206ac8:	48 89 10             	mov    %rdx,(%rax)
			break;
  8004206acb:	eb 1b                	jmp    8004206ae8 <_dwarf_frame_read_lsb_encoded+0x228>
		case DW_EH_PE_sleb128:
		case DW_EH_PE_sdata2:
		case DW_EH_PE_sdata4:
		case DW_EH_PE_sdata8:
			*val = pc + (int64_t) *val;
  8004206acd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206ad1:	48 8b 10             	mov    (%rax),%rdx
  8004206ad4:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206ad8:	48 01 c2             	add    %rax,%rdx
  8004206adb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206adf:	48 89 10             	mov    %rdx,(%rax)
			break;
  8004206ae2:	eb 04                	jmp    8004206ae8 <_dwarf_frame_read_lsb_encoded+0x228>
		default:
			/* DW_EH_PE_absptr is absolute value. */
			break;
		}
	}
  8004206ae4:	90                   	nop
  8004206ae5:	eb 01                	jmp    8004206ae8 <_dwarf_frame_read_lsb_encoded+0x228>
			break;
  8004206ae7:	90                   	nop

	/* XXX Applications other than DW_EH_PE_pcrel are not handled. */

	return (DW_DLE_NONE);
  8004206ae8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004206aed:	c9                   	leaveq 
  8004206aee:	c3                   	retq   

0000008004206aef <_dwarf_frame_parse_lsb_cie_augment>:

static int
_dwarf_frame_parse_lsb_cie_augment(Dwarf_Debug dbg, Dwarf_Cie cie,
				   Dwarf_Error *error)
{
  8004206aef:	55                   	push   %rbp
  8004206af0:	48 89 e5             	mov    %rsp,%rbp
  8004206af3:	48 83 ec 50          	sub    $0x50,%rsp
  8004206af7:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004206afb:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  8004206aff:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
	uint8_t *aug_p, *augdata_p;
	uint64_t val, offset;
	uint8_t encode;
	int ret;

	assert(cie->cie_augment != NULL && *cie->cie_augment == 'z');
  8004206b03:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206b07:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206b0b:	48 85 c0             	test   %rax,%rax
  8004206b0e:	74 0f                	je     8004206b1f <_dwarf_frame_parse_lsb_cie_augment+0x30>
  8004206b10:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206b14:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206b18:	0f b6 00             	movzbl (%rax),%eax
  8004206b1b:	3c 7a                	cmp    $0x7a,%al
  8004206b1d:	74 35                	je     8004206b54 <_dwarf_frame_parse_lsb_cie_augment+0x65>
  8004206b1f:	48 b9 48 a0 20 04 80 	movabs $0x800420a048,%rcx
  8004206b26:	00 00 00 
  8004206b29:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  8004206b30:	00 00 00 
  8004206b33:	be 4a 02 00 00       	mov    $0x24a,%esi
  8004206b38:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  8004206b3f:	00 00 00 
  8004206b42:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206b47:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004206b4e:	00 00 00 
  8004206b51:	41 ff d0             	callq  *%r8
	/*
	 * Here we're only interested in the presence of augment 'R'
	 * and associated CIE augment data, which describes the
	 * encoding scheme of FDE PC begin and range.
	 */
	aug_p = &cie->cie_augment[1];
  8004206b54:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206b58:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206b5c:	48 83 c0 01          	add    $0x1,%rax
  8004206b60:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	augdata_p = cie->cie_augdata;
  8004206b64:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206b68:	48 8b 40 58          	mov    0x58(%rax),%rax
  8004206b6c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	while (*aug_p != '\0') {
  8004206b70:	e9 b4 00 00 00       	jmpq   8004206c29 <_dwarf_frame_parse_lsb_cie_augment+0x13a>
		switch (*aug_p) {
  8004206b75:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004206b79:	0f b6 00             	movzbl (%rax),%eax
  8004206b7c:	0f b6 c0             	movzbl %al,%eax
  8004206b7f:	83 f8 50             	cmp    $0x50,%eax
  8004206b82:	74 18                	je     8004206b9c <_dwarf_frame_parse_lsb_cie_augment+0xad>
  8004206b84:	83 f8 52             	cmp    $0x52,%eax
  8004206b87:	74 7c                	je     8004206c05 <_dwarf_frame_parse_lsb_cie_augment+0x116>
  8004206b89:	83 f8 4c             	cmp    $0x4c,%eax
  8004206b8c:	0f 85 8b 00 00 00    	jne    8004206c1d <_dwarf_frame_parse_lsb_cie_augment+0x12e>
		case 'L':
			/* Skip one augment in augment data. */
			augdata_p++;
  8004206b92:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
			break;
  8004206b97:	e9 88 00 00 00       	jmpq   8004206c24 <_dwarf_frame_parse_lsb_cie_augment+0x135>
		case 'P':
			/* Skip two augments in augment data. */
			encode = *augdata_p++;
  8004206b9c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206ba0:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004206ba4:	48 89 55 f0          	mov    %rdx,-0x10(%rbp)
  8004206ba8:	0f b6 00             	movzbl (%rax),%eax
  8004206bab:	88 45 ef             	mov    %al,-0x11(%rbp)
			offset = 0;
  8004206bae:	48 c7 45 d8 00 00 00 	movq   $0x0,-0x28(%rbp)
  8004206bb5:	00 
			ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  8004206bb6:	0f b6 7d ef          	movzbl -0x11(%rbp),%edi
  8004206bba:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  8004206bbe:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004206bc2:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
  8004206bc6:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206bca:	48 83 ec 08          	sub    $0x8,%rsp
  8004206bce:	ff 75 b8             	pushq  -0x48(%rbp)
  8004206bd1:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8004206bd7:	41 89 f8             	mov    %edi,%r8d
  8004206bda:	48 89 c7             	mov    %rax,%rdi
  8004206bdd:	48 b8 c0 68 20 04 80 	movabs $0x80042068c0,%rax
  8004206be4:	00 00 00 
  8004206be7:	ff d0                	callq  *%rax
  8004206be9:	48 83 c4 10          	add    $0x10,%rsp
  8004206bed:	89 45 e8             	mov    %eax,-0x18(%rbp)
							    augdata_p, &offset, encode, 0, error);
			if (ret != DW_DLE_NONE)
  8004206bf0:	83 7d e8 00          	cmpl   $0x0,-0x18(%rbp)
  8004206bf4:	74 05                	je     8004206bfb <_dwarf_frame_parse_lsb_cie_augment+0x10c>
				return (ret);
  8004206bf6:	8b 45 e8             	mov    -0x18(%rbp),%eax
  8004206bf9:	eb 42                	jmp    8004206c3d <_dwarf_frame_parse_lsb_cie_augment+0x14e>
			augdata_p += offset;
  8004206bfb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206bff:	48 01 45 f0          	add    %rax,-0x10(%rbp)
			break;
  8004206c03:	eb 1f                	jmp    8004206c24 <_dwarf_frame_parse_lsb_cie_augment+0x135>
		case 'R':
			cie->cie_fde_encode = *augdata_p++;
  8004206c05:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206c09:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004206c0d:	48 89 55 f0          	mov    %rdx,-0x10(%rbp)
  8004206c11:	0f b6 10             	movzbl (%rax),%edx
  8004206c14:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206c18:	88 50 60             	mov    %dl,0x60(%rax)
			break;
  8004206c1b:	eb 07                	jmp    8004206c24 <_dwarf_frame_parse_lsb_cie_augment+0x135>
		default:
			DWARF_SET_ERROR(dbg, error,
					DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
			return (DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
  8004206c1d:	b8 14 00 00 00       	mov    $0x14,%eax
  8004206c22:	eb 19                	jmp    8004206c3d <_dwarf_frame_parse_lsb_cie_augment+0x14e>
		}
		aug_p++;
  8004206c24:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
	while (*aug_p != '\0') {
  8004206c29:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004206c2d:	0f b6 00             	movzbl (%rax),%eax
  8004206c30:	84 c0                	test   %al,%al
  8004206c32:	0f 85 3d ff ff ff    	jne    8004206b75 <_dwarf_frame_parse_lsb_cie_augment+0x86>
	}

	return (DW_DLE_NONE);
  8004206c38:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004206c3d:	c9                   	leaveq 
  8004206c3e:	c3                   	retq   

0000008004206c3f <_dwarf_frame_set_cie>:


static int
_dwarf_frame_set_cie(Dwarf_Debug dbg, Dwarf_Section *ds,
		     Dwarf_Unsigned *off, Dwarf_Cie ret_cie, Dwarf_Error *error)
{
  8004206c3f:	55                   	push   %rbp
  8004206c40:	48 89 e5             	mov    %rsp,%rbp
  8004206c43:	48 83 ec 60          	sub    $0x60,%rsp
  8004206c47:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004206c4b:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  8004206c4f:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004206c53:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  8004206c57:	4c 89 45 a8          	mov    %r8,-0x58(%rbp)
	Dwarf_Cie cie;
	uint64_t length;
	int dwarf_size, ret;
	char *p;

	assert(ret_cie);
  8004206c5b:	48 83 7d b0 00       	cmpq   $0x0,-0x50(%rbp)
  8004206c60:	75 35                	jne    8004206c97 <_dwarf_frame_set_cie+0x58>
  8004206c62:	48 b9 7d a0 20 04 80 	movabs $0x800420a07d,%rcx
  8004206c69:	00 00 00 
  8004206c6c:	48 ba c7 9e 20 04 80 	movabs $0x8004209ec7,%rdx
  8004206c73:	00 00 00 
  8004206c76:	be 7b 02 00 00       	mov    $0x27b,%esi
  8004206c7b:	48 bf dc 9e 20 04 80 	movabs $0x8004209edc,%rdi
  8004206c82:	00 00 00 
  8004206c85:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206c8a:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004206c91:	00 00 00 
  8004206c94:	41 ff d0             	callq  *%r8
	cie = ret_cie;
  8004206c97:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004206c9b:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	cie->cie_dbg = dbg;
  8004206c9f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ca3:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206ca7:	48 89 10             	mov    %rdx,(%rax)
	cie->cie_offset = *off;
  8004206caa:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206cae:	48 8b 10             	mov    (%rax),%rdx
  8004206cb1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206cb5:	48 89 50 10          	mov    %rdx,0x10(%rax)

	length = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 4);
  8004206cb9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206cbd:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206cc1:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206cc5:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004206cc9:	48 89 d7             	mov    %rdx,%rdi
  8004206ccc:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206cd0:	ba 04 00 00 00       	mov    $0x4,%edx
  8004206cd5:	48 89 ce             	mov    %rcx,%rsi
  8004206cd8:	ff d0                	callq  *%rax
  8004206cda:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (length == 0xffffffff) {
  8004206cde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004206ce3:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004206ce7:	75 2e                	jne    8004206d17 <_dwarf_frame_set_cie+0xd8>
		dwarf_size = 8;
  8004206ce9:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
		length = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 8);
  8004206cf0:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206cf4:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206cf8:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206cfc:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004206d00:	48 89 d7             	mov    %rdx,%rdi
  8004206d03:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206d07:	ba 08 00 00 00       	mov    $0x8,%edx
  8004206d0c:	48 89 ce             	mov    %rcx,%rsi
  8004206d0f:	ff d0                	callq  *%rax
  8004206d11:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004206d15:	eb 07                	jmp    8004206d1e <_dwarf_frame_set_cie+0xdf>
	} else
		dwarf_size = 4;
  8004206d17:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

	if (length > dbg->dbg_eh_size - *off) {
  8004206d1e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206d22:	48 8b 50 40          	mov    0x40(%rax),%rdx
  8004206d26:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206d2a:	48 8b 00             	mov    (%rax),%rax
  8004206d2d:	48 29 c2             	sub    %rax,%rdx
  8004206d30:	48 89 d0             	mov    %rdx,%rax
  8004206d33:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004206d37:	76 0a                	jbe    8004206d43 <_dwarf_frame_set_cie+0x104>
		DWARF_SET_ERROR(dbg, error, DW_DLE_DEBUG_FRAME_LENGTH_BAD);
		return (DW_DLE_DEBUG_FRAME_LENGTH_BAD);
  8004206d39:	b8 12 00 00 00       	mov    $0x12,%eax
  8004206d3e:	e9 7e 03 00 00       	jmpq   80042070c1 <_dwarf_frame_set_cie+0x482>
	}

	(void) dbg->read((uint8_t *)dbg->dbg_eh_offset, off, dwarf_size); /* Skip CIE id. */
  8004206d43:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206d47:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206d4b:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206d4f:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004206d53:	48 89 d7             	mov    %rdx,%rdi
  8004206d56:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004206d59:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206d5d:	48 89 ce             	mov    %rcx,%rsi
  8004206d60:	ff d0                	callq  *%rax
	cie->cie_length = length;
  8004206d62:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206d66:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004206d6a:	48 89 50 18          	mov    %rdx,0x18(%rax)

	cie->cie_version = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 1);
  8004206d6e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206d72:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206d76:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206d7a:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004206d7e:	48 89 d7             	mov    %rdx,%rdi
  8004206d81:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206d85:	ba 01 00 00 00       	mov    $0x1,%edx
  8004206d8a:	48 89 ce             	mov    %rcx,%rsi
  8004206d8d:	ff d0                	callq  *%rax
  8004206d8f:	89 c2                	mov    %eax,%edx
  8004206d91:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206d95:	66 89 50 20          	mov    %dx,0x20(%rax)
	if (cie->cie_version != 1 && cie->cie_version != 3 &&
  8004206d99:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206d9d:	0f b7 40 20          	movzwl 0x20(%rax),%eax
  8004206da1:	66 83 f8 01          	cmp    $0x1,%ax
  8004206da5:	74 26                	je     8004206dcd <_dwarf_frame_set_cie+0x18e>
  8004206da7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206dab:	0f b7 40 20          	movzwl 0x20(%rax),%eax
  8004206daf:	66 83 f8 03          	cmp    $0x3,%ax
  8004206db3:	74 18                	je     8004206dcd <_dwarf_frame_set_cie+0x18e>
	    cie->cie_version != 4) {
  8004206db5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206db9:	0f b7 40 20          	movzwl 0x20(%rax),%eax
	if (cie->cie_version != 1 && cie->cie_version != 3 &&
  8004206dbd:	66 83 f8 04          	cmp    $0x4,%ax
  8004206dc1:	74 0a                	je     8004206dcd <_dwarf_frame_set_cie+0x18e>
		DWARF_SET_ERROR(dbg, error, DW_DLE_FRAME_VERSION_BAD);
		return (DW_DLE_FRAME_VERSION_BAD);
  8004206dc3:	b8 16 00 00 00       	mov    $0x16,%eax
  8004206dc8:	e9 f4 02 00 00       	jmpq   80042070c1 <_dwarf_frame_set_cie+0x482>
	}

	cie->cie_augment = (uint8_t *)dbg->dbg_eh_offset + *off;
  8004206dcd:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206dd1:	48 8b 10             	mov    (%rax),%rdx
  8004206dd4:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206dd8:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206ddc:	48 01 d0             	add    %rdx,%rax
  8004206ddf:	48 89 c2             	mov    %rax,%rdx
  8004206de2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206de6:	48 89 50 28          	mov    %rdx,0x28(%rax)
	p = (char *)dbg->dbg_eh_offset;
  8004206dea:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206dee:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206df2:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	while (p[(*off)++] != '\0')
  8004206df6:	90                   	nop
  8004206df7:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206dfb:	48 8b 00             	mov    (%rax),%rax
  8004206dfe:	48 8d 48 01          	lea    0x1(%rax),%rcx
  8004206e02:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8004206e06:	48 89 0a             	mov    %rcx,(%rdx)
  8004206e09:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004206e0d:	48 01 d0             	add    %rdx,%rax
  8004206e10:	0f b6 00             	movzbl (%rax),%eax
  8004206e13:	84 c0                	test   %al,%al
  8004206e15:	75 e0                	jne    8004206df7 <_dwarf_frame_set_cie+0x1b8>
		;

	/* We only recognize normal .dwarf_frame and GNU .eh_frame sections. */
	if (*cie->cie_augment != 0 && *cie->cie_augment != 'z') {
  8004206e17:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e1b:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206e1f:	0f b6 00             	movzbl (%rax),%eax
  8004206e22:	84 c0                	test   %al,%al
  8004206e24:	74 48                	je     8004206e6e <_dwarf_frame_set_cie+0x22f>
  8004206e26:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e2a:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206e2e:	0f b6 00             	movzbl (%rax),%eax
  8004206e31:	3c 7a                	cmp    $0x7a,%al
  8004206e33:	74 39                	je     8004206e6e <_dwarf_frame_set_cie+0x22f>
		*off = cie->cie_offset + ((dwarf_size == 4) ? 4 : 12) +
  8004206e35:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e39:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004206e3d:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  8004206e41:	75 07                	jne    8004206e4a <_dwarf_frame_set_cie+0x20b>
  8004206e43:	ba 04 00 00 00       	mov    $0x4,%edx
  8004206e48:	eb 05                	jmp    8004206e4f <_dwarf_frame_set_cie+0x210>
  8004206e4a:	ba 0c 00 00 00       	mov    $0xc,%edx
  8004206e4f:	48 01 c2             	add    %rax,%rdx
			cie->cie_length;
  8004206e52:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e56:	48 8b 40 18          	mov    0x18(%rax),%rax
		*off = cie->cie_offset + ((dwarf_size == 4) ? 4 : 12) +
  8004206e5a:	48 01 c2             	add    %rax,%rdx
  8004206e5d:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206e61:	48 89 10             	mov    %rdx,(%rax)
		return (DW_DLE_NONE);
  8004206e64:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206e69:	e9 53 02 00 00       	jmpq   80042070c1 <_dwarf_frame_set_cie+0x482>
	}

	/* Optional EH Data field for .eh_frame section. */
	if (strstr((char *)cie->cie_augment, "eh") != NULL)
  8004206e6e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e72:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206e76:	48 be 85 a0 20 04 80 	movabs $0x800420a085,%rsi
  8004206e7d:	00 00 00 
  8004206e80:	48 89 c7             	mov    %rax,%rdi
  8004206e83:	48 b8 26 33 20 04 80 	movabs $0x8004203326,%rax
  8004206e8a:	00 00 00 
  8004206e8d:	ff d0                	callq  *%rax
  8004206e8f:	48 85 c0             	test   %rax,%rax
  8004206e92:	74 2e                	je     8004206ec2 <_dwarf_frame_set_cie+0x283>
		cie->cie_ehdata = dbg->read((uint8_t *)dbg->dbg_eh_offset, off,
  8004206e94:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206e98:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206e9c:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206ea0:	8b 52 28             	mov    0x28(%rdx),%edx
  8004206ea3:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  8004206ea7:	48 8b 49 38          	mov    0x38(%rcx),%rcx
  8004206eab:	48 89 cf             	mov    %rcx,%rdi
  8004206eae:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206eb2:	48 89 ce             	mov    %rcx,%rsi
  8004206eb5:	ff d0                	callq  *%rax
  8004206eb7:	48 89 c2             	mov    %rax,%rdx
  8004206eba:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ebe:	48 89 50 30          	mov    %rdx,0x30(%rax)
					    dbg->dbg_pointer_size);

	cie->cie_caf = _dwarf_read_uleb128((uint8_t *)dbg->dbg_eh_offset, off);
  8004206ec2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206ec6:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206eca:	48 89 c2             	mov    %rax,%rdx
  8004206ecd:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206ed1:	48 89 c6             	mov    %rax,%rsi
  8004206ed4:	48 89 d7             	mov    %rdx,%rdi
  8004206ed7:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004206ede:	00 00 00 
  8004206ee1:	ff d0                	callq  *%rax
  8004206ee3:	48 89 c2             	mov    %rax,%rdx
  8004206ee6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206eea:	48 89 50 38          	mov    %rdx,0x38(%rax)
	cie->cie_daf = _dwarf_read_sleb128((uint8_t *)dbg->dbg_eh_offset, off);
  8004206eee:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206ef2:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206ef6:	48 89 c2             	mov    %rax,%rdx
  8004206ef9:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206efd:	48 89 c6             	mov    %rax,%rsi
  8004206f00:	48 89 d7             	mov    %rdx,%rdi
  8004206f03:	48 b8 6f 39 20 04 80 	movabs $0x800420396f,%rax
  8004206f0a:	00 00 00 
  8004206f0d:	ff d0                	callq  *%rax
  8004206f0f:	48 89 c2             	mov    %rax,%rdx
  8004206f12:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206f16:	48 89 50 40          	mov    %rdx,0x40(%rax)

	/* Return address register. */
	if (cie->cie_version == 1)
  8004206f1a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206f1e:	0f b7 40 20          	movzwl 0x20(%rax),%eax
  8004206f22:	66 83 f8 01          	cmp    $0x1,%ax
  8004206f26:	75 2e                	jne    8004206f56 <_dwarf_frame_set_cie+0x317>
		cie->cie_ra = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 1);
  8004206f28:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206f2c:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004206f30:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206f34:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004206f38:	48 89 d7             	mov    %rdx,%rdi
  8004206f3b:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206f3f:	ba 01 00 00 00       	mov    $0x1,%edx
  8004206f44:	48 89 ce             	mov    %rcx,%rsi
  8004206f47:	ff d0                	callq  *%rax
  8004206f49:	48 89 c2             	mov    %rax,%rdx
  8004206f4c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206f50:	48 89 50 48          	mov    %rdx,0x48(%rax)
  8004206f54:	eb 2c                	jmp    8004206f82 <_dwarf_frame_set_cie+0x343>
	else
		cie->cie_ra = _dwarf_read_uleb128((uint8_t *)dbg->dbg_eh_offset, off);
  8004206f56:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206f5a:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206f5e:	48 89 c2             	mov    %rax,%rdx
  8004206f61:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206f65:	48 89 c6             	mov    %rax,%rsi
  8004206f68:	48 89 d7             	mov    %rdx,%rdi
  8004206f6b:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004206f72:	00 00 00 
  8004206f75:	ff d0                	callq  *%rax
  8004206f77:	48 89 c2             	mov    %rax,%rdx
  8004206f7a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206f7e:	48 89 50 48          	mov    %rdx,0x48(%rax)

	/* Optional CIE augmentation data for .eh_frame section. */
	if (*cie->cie_augment == 'z') {
  8004206f82:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206f86:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206f8a:	0f b6 00             	movzbl (%rax),%eax
  8004206f8d:	3c 7a                	cmp    $0x7a,%al
  8004206f8f:	0f 85 99 00 00 00    	jne    800420702e <_dwarf_frame_set_cie+0x3ef>
		cie->cie_auglen = _dwarf_read_uleb128((uint8_t *)dbg->dbg_eh_offset, off);
  8004206f95:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206f99:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206f9d:	48 89 c2             	mov    %rax,%rdx
  8004206fa0:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206fa4:	48 89 c6             	mov    %rax,%rsi
  8004206fa7:	48 89 d7             	mov    %rdx,%rdi
  8004206faa:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  8004206fb1:	00 00 00 
  8004206fb4:	ff d0                	callq  *%rax
  8004206fb6:	48 89 c2             	mov    %rax,%rdx
  8004206fb9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206fbd:	48 89 50 50          	mov    %rdx,0x50(%rax)
		cie->cie_augdata = (uint8_t *)dbg->dbg_eh_offset + *off;
  8004206fc1:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206fc5:	48 8b 10             	mov    (%rax),%rdx
  8004206fc8:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206fcc:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206fd0:	48 01 d0             	add    %rdx,%rax
  8004206fd3:	48 89 c2             	mov    %rax,%rdx
  8004206fd6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206fda:	48 89 50 58          	mov    %rdx,0x58(%rax)
		*off += cie->cie_auglen;
  8004206fde:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206fe2:	48 8b 10             	mov    (%rax),%rdx
  8004206fe5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206fe9:	48 8b 40 50          	mov    0x50(%rax),%rax
  8004206fed:	48 01 c2             	add    %rax,%rdx
  8004206ff0:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206ff4:	48 89 10             	mov    %rdx,(%rax)
		/*
		 * XXX Use DW_EH_PE_absptr for default FDE PC start/range,
		 * in case _dwarf_frame_parse_lsb_cie_augment fails to
		 * find out the real encode.
		 */
		cie->cie_fde_encode = DW_EH_PE_absptr;
  8004206ff7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ffb:	c6 40 60 00          	movb   $0x0,0x60(%rax)
		ret = _dwarf_frame_parse_lsb_cie_augment(dbg, cie, error);
  8004206fff:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004207003:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004207007:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420700b:	48 89 ce             	mov    %rcx,%rsi
  800420700e:	48 89 c7             	mov    %rax,%rdi
  8004207011:	48 b8 ef 6a 20 04 80 	movabs $0x8004206aef,%rax
  8004207018:	00 00 00 
  800420701b:	ff d0                	callq  *%rax
  800420701d:	89 45 dc             	mov    %eax,-0x24(%rbp)
		if (ret != DW_DLE_NONE)
  8004207020:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004207024:	74 08                	je     800420702e <_dwarf_frame_set_cie+0x3ef>
			return (ret);
  8004207026:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004207029:	e9 93 00 00 00       	jmpq   80042070c1 <_dwarf_frame_set_cie+0x482>
	}

	/* CIE Initial instructions. */
	cie->cie_initinst = (uint8_t *)dbg->dbg_eh_offset + *off;
  800420702e:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207032:	48 8b 10             	mov    (%rax),%rdx
  8004207035:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207039:	48 8b 40 38          	mov    0x38(%rax),%rax
  800420703d:	48 01 d0             	add    %rdx,%rax
  8004207040:	48 89 c2             	mov    %rax,%rdx
  8004207043:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207047:	48 89 50 68          	mov    %rdx,0x68(%rax)
	if (dwarf_size == 4)
  800420704b:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  800420704f:	75 2a                	jne    800420707b <_dwarf_frame_set_cie+0x43c>
		cie->cie_instlen = cie->cie_offset + 4 + length - *off;
  8004207051:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207055:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004207059:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420705d:	48 01 c2             	add    %rax,%rdx
  8004207060:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207064:	48 8b 00             	mov    (%rax),%rax
  8004207067:	48 f7 d8             	neg    %rax
  800420706a:	48 01 d0             	add    %rdx,%rax
  800420706d:	48 8d 50 04          	lea    0x4(%rax),%rdx
  8004207071:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207075:	48 89 50 70          	mov    %rdx,0x70(%rax)
  8004207079:	eb 28                	jmp    80042070a3 <_dwarf_frame_set_cie+0x464>
	else
		cie->cie_instlen = cie->cie_offset + 12 + length - *off;
  800420707b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420707f:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004207083:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207087:	48 01 c2             	add    %rax,%rdx
  800420708a:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  800420708e:	48 8b 00             	mov    (%rax),%rax
  8004207091:	48 f7 d8             	neg    %rax
  8004207094:	48 01 d0             	add    %rdx,%rax
  8004207097:	48 8d 50 0c          	lea    0xc(%rax),%rdx
  800420709b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420709f:	48 89 50 70          	mov    %rdx,0x70(%rax)

	*off += cie->cie_instlen;
  80042070a3:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042070a7:	48 8b 10             	mov    (%rax),%rdx
  80042070aa:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042070ae:	48 8b 40 70          	mov    0x70(%rax),%rax
  80042070b2:	48 01 c2             	add    %rax,%rdx
  80042070b5:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042070b9:	48 89 10             	mov    %rdx,(%rax)
	return (DW_DLE_NONE);
  80042070bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042070c1:	c9                   	leaveq 
  80042070c2:	c3                   	retq   

00000080042070c3 <_dwarf_frame_set_fde>:

static int
_dwarf_frame_set_fde(Dwarf_Debug dbg, Dwarf_Fde ret_fde, Dwarf_Section *ds,
		     Dwarf_Unsigned *off, int eh_frame, Dwarf_Cie cie, Dwarf_Error *error)
{
  80042070c3:	55                   	push   %rbp
  80042070c4:	48 89 e5             	mov    %rsp,%rbp
  80042070c7:	48 83 ec 60          	sub    $0x60,%rsp
  80042070cb:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  80042070cf:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  80042070d3:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  80042070d7:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  80042070db:	44 89 45 ac          	mov    %r8d,-0x54(%rbp)
  80042070df:	4c 89 4d a0          	mov    %r9,-0x60(%rbp)
	Dwarf_Fde fde;
	Dwarf_Unsigned cieoff;
	uint64_t length, val;
	int dwarf_size, ret;

	fde = ret_fde;
  80042070e3:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042070e7:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	fde->fde_dbg = dbg;
  80042070eb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042070ef:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042070f3:	48 89 10             	mov    %rdx,(%rax)
	fde->fde_addr = (uint8_t *)dbg->dbg_eh_offset + *off;
  80042070f6:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042070fa:	48 8b 10             	mov    (%rax),%rdx
  80042070fd:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207101:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004207105:	48 01 d0             	add    %rdx,%rax
  8004207108:	48 89 c2             	mov    %rax,%rdx
  800420710b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420710f:	48 89 50 10          	mov    %rdx,0x10(%rax)
	fde->fde_offset = *off;
  8004207113:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207117:	48 8b 10             	mov    (%rax),%rdx
  800420711a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420711e:	48 89 50 18          	mov    %rdx,0x18(%rax)

	length = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 4);
  8004207122:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207126:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420712a:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420712e:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004207132:	48 89 d7             	mov    %rdx,%rdi
  8004207135:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  8004207139:	ba 04 00 00 00       	mov    $0x4,%edx
  800420713e:	48 89 ce             	mov    %rcx,%rsi
  8004207141:	ff d0                	callq  *%rax
  8004207143:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (length == 0xffffffff) {
  8004207147:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420714c:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004207150:	75 2e                	jne    8004207180 <_dwarf_frame_set_fde+0xbd>
		dwarf_size = 8;
  8004207152:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
		length = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 8);
  8004207159:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420715d:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207161:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004207165:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004207169:	48 89 d7             	mov    %rdx,%rdi
  800420716c:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  8004207170:	ba 08 00 00 00       	mov    $0x8,%edx
  8004207175:	48 89 ce             	mov    %rcx,%rsi
  8004207178:	ff d0                	callq  *%rax
  800420717a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800420717e:	eb 07                	jmp    8004207187 <_dwarf_frame_set_fde+0xc4>
	} else
		dwarf_size = 4;
  8004207180:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

	if (length > dbg->dbg_eh_size - *off) {
  8004207187:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420718b:	48 8b 50 40          	mov    0x40(%rax),%rdx
  800420718f:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207193:	48 8b 00             	mov    (%rax),%rax
  8004207196:	48 29 c2             	sub    %rax,%rdx
  8004207199:	48 89 d0             	mov    %rdx,%rax
  800420719c:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  80042071a0:	76 0a                	jbe    80042071ac <_dwarf_frame_set_fde+0xe9>
		DWARF_SET_ERROR(dbg, error, DW_DLE_DEBUG_FRAME_LENGTH_BAD);
		return (DW_DLE_DEBUG_FRAME_LENGTH_BAD);
  80042071a2:	b8 12 00 00 00       	mov    $0x12,%eax
  80042071a7:	e9 fb 02 00 00       	jmpq   80042074a7 <_dwarf_frame_set_fde+0x3e4>
	}

	fde->fde_length = length;
  80042071ac:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042071b0:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042071b4:	48 89 50 20          	mov    %rdx,0x20(%rax)

	if (eh_frame) {
  80042071b8:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  80042071bc:	74 61                	je     800420721f <_dwarf_frame_set_fde+0x15c>
		fde->fde_cieoff = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, 4);
  80042071be:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042071c2:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042071c6:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042071ca:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  80042071ce:	48 89 d7             	mov    %rdx,%rdi
  80042071d1:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042071d5:	ba 04 00 00 00       	mov    $0x4,%edx
  80042071da:	48 89 ce             	mov    %rcx,%rsi
  80042071dd:	ff d0                	callq  *%rax
  80042071df:	48 89 c2             	mov    %rax,%rdx
  80042071e2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042071e6:	48 89 50 28          	mov    %rdx,0x28(%rax)
		cieoff = *off - (4 + fde->fde_cieoff);
  80042071ea:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042071ee:	48 8b 10             	mov    (%rax),%rdx
  80042071f1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042071f5:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042071f9:	48 29 c2             	sub    %rax,%rdx
  80042071fc:	48 89 d0             	mov    %rdx,%rax
  80042071ff:	48 83 e8 04          	sub    $0x4,%rax
  8004207203:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
		/* This delta should never be 0. */
		if (cieoff == fde->fde_offset) {
  8004207207:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420720b:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420720f:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004207213:	75 40                	jne    8004207255 <_dwarf_frame_set_fde+0x192>
			DWARF_SET_ERROR(dbg, error, DW_DLE_NO_CIE_FOR_FDE);
			return (DW_DLE_NO_CIE_FOR_FDE);
  8004207215:	b8 13 00 00 00       	mov    $0x13,%eax
  800420721a:	e9 88 02 00 00       	jmpq   80042074a7 <_dwarf_frame_set_fde+0x3e4>
		}
	} else {
		fde->fde_cieoff = dbg->read((uint8_t *)dbg->dbg_eh_offset, off, dwarf_size);
  800420721f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207223:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207227:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420722b:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  800420722f:	48 89 d7             	mov    %rdx,%rdi
  8004207232:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004207235:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  8004207239:	48 89 ce             	mov    %rcx,%rsi
  800420723c:	ff d0                	callq  *%rax
  800420723e:	48 89 c2             	mov    %rax,%rdx
  8004207241:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207245:	48 89 50 28          	mov    %rdx,0x28(%rax)
		cieoff = fde->fde_cieoff;
  8004207249:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420724d:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004207251:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	}

	if (eh_frame) {
  8004207255:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  8004207259:	0f 84 e2 00 00 00    	je     8004207341 <_dwarf_frame_set_fde+0x27e>
		 * The FDE PC start/range for .eh_frame is encoded according
		 * to the LSB spec's extension to DWARF2.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
						    (uint8_t *)dbg->dbg_eh_offset,
						    off, cie->cie_fde_encode, ds->ds_addr + *off, error);
  800420725f:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207263:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004207267:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420726b:	48 8b 00             	mov    (%rax),%rax
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  800420726e:	48 8d 3c 02          	lea    (%rdx,%rax,1),%rdi
						    off, cie->cie_fde_encode, ds->ds_addr + *off, error);
  8004207272:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004207276:	0f b6 40 60          	movzbl 0x60(%rax),%eax
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  800420727a:	0f b6 c8             	movzbl %al,%ecx
						    (uint8_t *)dbg->dbg_eh_offset,
  800420727d:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207281:	48 8b 40 38          	mov    0x38(%rax),%rax
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  8004207285:	49 89 c2             	mov    %rax,%r10
  8004207288:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  800420728c:	48 8d 75 d0          	lea    -0x30(%rbp),%rsi
  8004207290:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207294:	48 83 ec 08          	sub    $0x8,%rsp
  8004207298:	ff 75 10             	pushq  0x10(%rbp)
  800420729b:	49 89 f9             	mov    %rdi,%r9
  800420729e:	41 89 c8             	mov    %ecx,%r8d
  80042072a1:	48 89 d1             	mov    %rdx,%rcx
  80042072a4:	4c 89 d2             	mov    %r10,%rdx
  80042072a7:	48 89 c7             	mov    %rax,%rdi
  80042072aa:	48 b8 c0 68 20 04 80 	movabs $0x80042068c0,%rax
  80042072b1:	00 00 00 
  80042072b4:	ff d0                	callq  *%rax
  80042072b6:	48 83 c4 10          	add    $0x10,%rsp
  80042072ba:	89 45 dc             	mov    %eax,-0x24(%rbp)
		if (ret != DW_DLE_NONE)
  80042072bd:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  80042072c1:	74 08                	je     80042072cb <_dwarf_frame_set_fde+0x208>
			return (ret);
  80042072c3:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042072c6:	e9 dc 01 00 00       	jmpq   80042074a7 <_dwarf_frame_set_fde+0x3e4>
		fde->fde_initloc = val;
  80042072cb:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042072cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042072d3:	48 89 50 30          	mov    %rdx,0x30(%rax)
		 * FDE PC range should not be relative value to anything.
		 * So pass 0 for pc value.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
						    (uint8_t *)dbg->dbg_eh_offset,
						    off, cie->cie_fde_encode, 0, error);
  80042072d7:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042072db:	0f b6 40 60          	movzbl 0x60(%rax),%eax
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  80042072df:	0f b6 c8             	movzbl %al,%ecx
						    (uint8_t *)dbg->dbg_eh_offset,
  80042072e2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042072e6:	48 8b 40 38          	mov    0x38(%rax),%rax
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  80042072ea:	48 89 c7             	mov    %rax,%rdi
  80042072ed:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042072f1:	48 8d 75 d0          	lea    -0x30(%rbp),%rsi
  80042072f5:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042072f9:	48 83 ec 08          	sub    $0x8,%rsp
  80042072fd:	ff 75 10             	pushq  0x10(%rbp)
  8004207300:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8004207306:	41 89 c8             	mov    %ecx,%r8d
  8004207309:	48 89 d1             	mov    %rdx,%rcx
  800420730c:	48 89 fa             	mov    %rdi,%rdx
  800420730f:	48 89 c7             	mov    %rax,%rdi
  8004207312:	48 b8 c0 68 20 04 80 	movabs $0x80042068c0,%rax
  8004207319:	00 00 00 
  800420731c:	ff d0                	callq  *%rax
  800420731e:	48 83 c4 10          	add    $0x10,%rsp
  8004207322:	89 45 dc             	mov    %eax,-0x24(%rbp)
		if (ret != DW_DLE_NONE)
  8004207325:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004207329:	74 08                	je     8004207333 <_dwarf_frame_set_fde+0x270>
			return (ret);
  800420732b:	8b 45 dc             	mov    -0x24(%rbp),%eax
  800420732e:	e9 74 01 00 00       	jmpq   80042074a7 <_dwarf_frame_set_fde+0x3e4>
		fde->fde_adrange = val;
  8004207333:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004207337:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420733b:	48 89 50 38          	mov    %rdx,0x38(%rax)
  800420733f:	eb 5c                	jmp    800420739d <_dwarf_frame_set_fde+0x2da>
	} else {
		fde->fde_initloc = dbg->read((uint8_t *)dbg->dbg_eh_offset, off,
  8004207341:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207345:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207349:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420734d:	8b 52 28             	mov    0x28(%rdx),%edx
  8004207350:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  8004207354:	48 8b 49 38          	mov    0x38(%rcx),%rcx
  8004207358:	48 89 cf             	mov    %rcx,%rdi
  800420735b:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  800420735f:	48 89 ce             	mov    %rcx,%rsi
  8004207362:	ff d0                	callq  *%rax
  8004207364:	48 89 c2             	mov    %rax,%rdx
  8004207367:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420736b:	48 89 50 30          	mov    %rdx,0x30(%rax)
					     dbg->dbg_pointer_size);
		fde->fde_adrange = dbg->read((uint8_t *)dbg->dbg_eh_offset, off,
  800420736f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207373:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207377:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420737b:	8b 52 28             	mov    0x28(%rdx),%edx
  800420737e:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  8004207382:	48 8b 49 38          	mov    0x38(%rcx),%rcx
  8004207386:	48 89 cf             	mov    %rcx,%rdi
  8004207389:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  800420738d:	48 89 ce             	mov    %rcx,%rsi
  8004207390:	ff d0                	callq  *%rax
  8004207392:	48 89 c2             	mov    %rax,%rdx
  8004207395:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207399:	48 89 50 38          	mov    %rdx,0x38(%rax)
					     dbg->dbg_pointer_size);
	}

	/* Optional FDE augmentation data for .eh_frame section. (ignored) */
	if (eh_frame && *cie->cie_augment == 'z') {
  800420739d:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  80042073a1:	74 71                	je     8004207414 <_dwarf_frame_set_fde+0x351>
  80042073a3:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042073a7:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042073ab:	0f b6 00             	movzbl (%rax),%eax
  80042073ae:	3c 7a                	cmp    $0x7a,%al
  80042073b0:	75 62                	jne    8004207414 <_dwarf_frame_set_fde+0x351>
		fde->fde_auglen = _dwarf_read_uleb128((uint8_t *)dbg->dbg_eh_offset, off);
  80042073b2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042073b6:	48 8b 40 38          	mov    0x38(%rax),%rax
  80042073ba:	48 89 c2             	mov    %rax,%rdx
  80042073bd:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042073c1:	48 89 c6             	mov    %rax,%rsi
  80042073c4:	48 89 d7             	mov    %rdx,%rdi
  80042073c7:	48 b8 13 3a 20 04 80 	movabs $0x8004203a13,%rax
  80042073ce:	00 00 00 
  80042073d1:	ff d0                	callq  *%rax
  80042073d3:	48 89 c2             	mov    %rax,%rdx
  80042073d6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042073da:	48 89 50 40          	mov    %rdx,0x40(%rax)
		fde->fde_augdata = (uint8_t *)dbg->dbg_eh_offset + *off;
  80042073de:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042073e2:	48 8b 10             	mov    (%rax),%rdx
  80042073e5:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042073e9:	48 8b 40 38          	mov    0x38(%rax),%rax
  80042073ed:	48 01 d0             	add    %rdx,%rax
  80042073f0:	48 89 c2             	mov    %rax,%rdx
  80042073f3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042073f7:	48 89 50 48          	mov    %rdx,0x48(%rax)
		*off += fde->fde_auglen;
  80042073fb:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042073ff:	48 8b 10             	mov    (%rax),%rdx
  8004207402:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207406:	48 8b 40 40          	mov    0x40(%rax),%rax
  800420740a:	48 01 c2             	add    %rax,%rdx
  800420740d:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207411:	48 89 10             	mov    %rdx,(%rax)
	}

	fde->fde_inst = (uint8_t *)dbg->dbg_eh_offset + *off;
  8004207414:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207418:	48 8b 10             	mov    (%rax),%rdx
  800420741b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420741f:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004207423:	48 01 d0             	add    %rdx,%rax
  8004207426:	48 89 c2             	mov    %rax,%rdx
  8004207429:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420742d:	48 89 50 50          	mov    %rdx,0x50(%rax)
	if (dwarf_size == 4)
  8004207431:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  8004207435:	75 2a                	jne    8004207461 <_dwarf_frame_set_fde+0x39e>
		fde->fde_instlen = fde->fde_offset + 4 + length - *off;
  8004207437:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420743b:	48 8b 50 18          	mov    0x18(%rax),%rdx
  800420743f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207443:	48 01 c2             	add    %rax,%rdx
  8004207446:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420744a:	48 8b 00             	mov    (%rax),%rax
  800420744d:	48 f7 d8             	neg    %rax
  8004207450:	48 01 d0             	add    %rdx,%rax
  8004207453:	48 8d 50 04          	lea    0x4(%rax),%rdx
  8004207457:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420745b:	48 89 50 58          	mov    %rdx,0x58(%rax)
  800420745f:	eb 28                	jmp    8004207489 <_dwarf_frame_set_fde+0x3c6>
	else
		fde->fde_instlen = fde->fde_offset + 12 + length - *off;
  8004207461:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207465:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004207469:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420746d:	48 01 c2             	add    %rax,%rdx
  8004207470:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207474:	48 8b 00             	mov    (%rax),%rax
  8004207477:	48 f7 d8             	neg    %rax
  800420747a:	48 01 d0             	add    %rdx,%rax
  800420747d:	48 8d 50 0c          	lea    0xc(%rax),%rdx
  8004207481:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207485:	48 89 50 58          	mov    %rdx,0x58(%rax)

	*off += fde->fde_instlen;
  8004207489:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420748d:	48 8b 10             	mov    (%rax),%rdx
  8004207490:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207494:	48 8b 40 58          	mov    0x58(%rax),%rax
  8004207498:	48 01 c2             	add    %rax,%rdx
  800420749b:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420749f:	48 89 10             	mov    %rdx,(%rax)
	return (DW_DLE_NONE);
  80042074a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042074a7:	c9                   	leaveq 
  80042074a8:	c3                   	retq   

00000080042074a9 <_dwarf_frame_interal_table_init>:


int
_dwarf_frame_interal_table_init(Dwarf_Debug dbg, Dwarf_Error *error)
{
  80042074a9:	55                   	push   %rbp
  80042074aa:	48 89 e5             	mov    %rsp,%rbp
  80042074ad:	48 83 ec 20          	sub    $0x20,%rsp
  80042074b1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042074b5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	Dwarf_Regtable3 *rt = &global_rt_table;
  80042074b9:	48 b8 e0 bc 21 04 80 	movabs $0x800421bce0,%rax
  80042074c0:	00 00 00 
  80042074c3:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

	if (dbg->dbg_internal_reg_table != NULL)
  80042074c7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042074cb:	48 8b 40 58          	mov    0x58(%rax),%rax
  80042074cf:	48 85 c0             	test   %rax,%rax
  80042074d2:	74 07                	je     80042074db <_dwarf_frame_interal_table_init+0x32>
		return (DW_DLE_NONE);
  80042074d4:	b8 00 00 00 00       	mov    $0x0,%eax
  80042074d9:	eb 33                	jmp    800420750e <_dwarf_frame_interal_table_init+0x65>

	rt->rt3_reg_table_size = dbg->dbg_frame_rule_table_size;
  80042074db:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042074df:	0f b7 50 48          	movzwl 0x48(%rax),%edx
  80042074e3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042074e7:	66 89 50 18          	mov    %dx,0x18(%rax)
	rt->rt3_rules = global_rules;
  80042074eb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042074ef:	48 b9 00 c5 21 04 80 	movabs $0x800421c500,%rcx
  80042074f6:	00 00 00 
  80042074f9:	48 89 48 20          	mov    %rcx,0x20(%rax)

	dbg->dbg_internal_reg_table = rt;
  80042074fd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207501:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207505:	48 89 50 58          	mov    %rdx,0x58(%rax)

	return (DW_DLE_NONE);
  8004207509:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420750e:	c9                   	leaveq 
  800420750f:	c3                   	retq   

0000008004207510 <_dwarf_get_next_fde>:

static int
_dwarf_get_next_fde(Dwarf_Debug dbg,
		    int eh_frame, Dwarf_Error *error, Dwarf_Fde ret_fde)
{
  8004207510:	55                   	push   %rbp
  8004207511:	48 89 e5             	mov    %rsp,%rbp
  8004207514:	48 83 ec 50          	sub    $0x50,%rsp
  8004207518:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  800420751c:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  800420751f:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004207523:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
	Dwarf_Section *ds = &debug_frame_sec; 
  8004207527:	48 b8 e0 b5 21 04 80 	movabs $0x800421b5e0,%rax
  800420752e:	00 00 00 
  8004207531:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	uint64_t length, offset, cie_id, entry_off;
	int dwarf_size, i, ret=-1;
  8004207535:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%rbp)

	offset = dbg->curr_off_eh;
  800420753c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207540:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004207544:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	if (offset < dbg->dbg_eh_size) {
  8004207548:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420754c:	48 8b 50 40          	mov    0x40(%rax),%rdx
  8004207550:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004207554:	48 39 c2             	cmp    %rax,%rdx
  8004207557:	0f 86 04 02 00 00    	jbe    8004207761 <_dwarf_get_next_fde+0x251>
		entry_off = offset;
  800420755d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004207561:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
		length = dbg->read((uint8_t *)dbg->dbg_eh_offset, &offset, 4);
  8004207565:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207569:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420756d:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004207571:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004207575:	48 89 d7             	mov    %rdx,%rdi
  8004207578:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  800420757c:	ba 04 00 00 00       	mov    $0x4,%edx
  8004207581:	48 89 ce             	mov    %rcx,%rsi
  8004207584:	ff d0                	callq  *%rax
  8004207586:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		if (length == 0xffffffff) {
  800420758a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420758f:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004207593:	75 2e                	jne    80042075c3 <_dwarf_get_next_fde+0xb3>
			dwarf_size = 8;
  8004207595:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
			length = dbg->read((uint8_t *)dbg->dbg_eh_offset, &offset, 8);
  800420759c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042075a0:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042075a4:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042075a8:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  80042075ac:	48 89 d7             	mov    %rdx,%rdi
  80042075af:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  80042075b3:	ba 08 00 00 00       	mov    $0x8,%edx
  80042075b8:	48 89 ce             	mov    %rcx,%rsi
  80042075bb:	ff d0                	callq  *%rax
  80042075bd:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042075c1:	eb 07                	jmp    80042075ca <_dwarf_get_next_fde+0xba>
		} else
			dwarf_size = 4;
  80042075c3:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

		if (length > dbg->dbg_eh_size - offset || (length == 0 && !eh_frame)) {
  80042075ca:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042075ce:	48 8b 50 40          	mov    0x40(%rax),%rdx
  80042075d2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042075d6:	48 29 c2             	sub    %rax,%rdx
  80042075d9:	48 89 d0             	mov    %rdx,%rax
  80042075dc:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  80042075e0:	77 0d                	ja     80042075ef <_dwarf_get_next_fde+0xdf>
  80042075e2:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  80042075e7:	75 10                	jne    80042075f9 <_dwarf_get_next_fde+0xe9>
  80042075e9:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  80042075ed:	75 0a                	jne    80042075f9 <_dwarf_get_next_fde+0xe9>
			DWARF_SET_ERROR(dbg, error,
					DW_DLE_DEBUG_FRAME_LENGTH_BAD);
			return (DW_DLE_DEBUG_FRAME_LENGTH_BAD);
  80042075ef:	b8 12 00 00 00       	mov    $0x12,%eax
  80042075f4:	e9 6d 01 00 00       	jmpq   8004207766 <_dwarf_get_next_fde+0x256>
		}

		/* Check terminator for .eh_frame */
		if (eh_frame && length == 0)
  80042075f9:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  80042075fd:	74 11                	je     8004207610 <_dwarf_get_next_fde+0x100>
  80042075ff:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004207604:	75 0a                	jne    8004207610 <_dwarf_get_next_fde+0x100>
			return(-1);
  8004207606:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420760b:	e9 56 01 00 00       	jmpq   8004207766 <_dwarf_get_next_fde+0x256>

		cie_id = dbg->read((uint8_t *)dbg->dbg_eh_offset, &offset, dwarf_size);
  8004207610:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207614:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207618:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420761c:	48 8b 52 38          	mov    0x38(%rdx),%rdx
  8004207620:	48 89 d7             	mov    %rdx,%rdi
  8004207623:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004207626:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  800420762a:	48 89 ce             	mov    %rcx,%rsi
  800420762d:	ff d0                	callq  *%rax
  800420762f:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

		if (eh_frame) {
  8004207633:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  8004207637:	74 7c                	je     80042076b5 <_dwarf_get_next_fde+0x1a5>
			/* GNU .eh_frame use CIE id 0. */
			if (cie_id == 0)
  8004207639:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  800420763e:	75 32                	jne    8004207672 <_dwarf_get_next_fde+0x162>
				ret = _dwarf_frame_set_cie(dbg, ds,
  8004207640:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207644:	48 8b 48 08          	mov    0x8(%rax),%rcx
  8004207648:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  800420764c:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
  8004207650:	48 8b 75 e8          	mov    -0x18(%rbp),%rsi
  8004207654:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207658:	49 89 f8             	mov    %rdi,%r8
  800420765b:	48 89 c7             	mov    %rax,%rdi
  800420765e:	48 b8 3f 6c 20 04 80 	movabs $0x8004206c3f,%rax
  8004207665:	00 00 00 
  8004207668:	ff d0                	callq  *%rax
  800420766a:	89 45 f0             	mov    %eax,-0x10(%rbp)
  800420766d:	e9 ce 00 00 00       	jmpq   8004207740 <_dwarf_get_next_fde+0x230>
							   &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg,ret_fde, ds,
  8004207672:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207676:	48 8b 78 08          	mov    0x8(%rax),%rdi
  800420767a:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
  800420767e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207682:	48 8b 75 b0          	mov    -0x50(%rbp),%rsi
  8004207686:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420768a:	48 83 ec 08          	sub    $0x8,%rsp
  800420768e:	ff 75 b8             	pushq  -0x48(%rbp)
  8004207691:	49 89 f9             	mov    %rdi,%r9
  8004207694:	41 b8 01 00 00 00    	mov    $0x1,%r8d
  800420769a:	48 89 c7             	mov    %rax,%rdi
  800420769d:	48 b8 c3 70 20 04 80 	movabs $0x80042070c3,%rax
  80042076a4:	00 00 00 
  80042076a7:	ff d0                	callq  *%rax
  80042076a9:	48 83 c4 10          	add    $0x10,%rsp
  80042076ad:	89 45 f0             	mov    %eax,-0x10(%rbp)
  80042076b0:	e9 8b 00 00 00       	jmpq   8004207740 <_dwarf_get_next_fde+0x230>
							   &entry_off, 1, ret_fde->fde_cie, error);
		} else {
			/* .dwarf_frame use CIE id ~0 */
			if ((dwarf_size == 4 && cie_id == ~0U) ||
  80042076b5:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  80042076b9:	75 0b                	jne    80042076c6 <_dwarf_get_next_fde+0x1b6>
  80042076bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  80042076c0:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  80042076c4:	74 0d                	je     80042076d3 <_dwarf_get_next_fde+0x1c3>
  80042076c6:	83 7d f4 08          	cmpl   $0x8,-0xc(%rbp)
  80042076ca:	75 36                	jne    8004207702 <_dwarf_get_next_fde+0x1f2>
			    (dwarf_size == 8 && cie_id == ~0ULL))
  80042076cc:	48 83 7d e0 ff       	cmpq   $0xffffffffffffffff,-0x20(%rbp)
  80042076d1:	75 2f                	jne    8004207702 <_dwarf_get_next_fde+0x1f2>
				ret = _dwarf_frame_set_cie(dbg, ds,
  80042076d3:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042076d7:	48 8b 48 08          	mov    0x8(%rax),%rcx
  80042076db:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  80042076df:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
  80042076e3:	48 8b 75 e8          	mov    -0x18(%rbp),%rsi
  80042076e7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042076eb:	49 89 f8             	mov    %rdi,%r8
  80042076ee:	48 89 c7             	mov    %rax,%rdi
  80042076f1:	48 b8 3f 6c 20 04 80 	movabs $0x8004206c3f,%rax
  80042076f8:	00 00 00 
  80042076fb:	ff d0                	callq  *%rax
  80042076fd:	89 45 f0             	mov    %eax,-0x10(%rbp)
  8004207700:	eb 3e                	jmp    8004207740 <_dwarf_get_next_fde+0x230>
							   &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg, ret_fde, ds,
  8004207702:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207706:	48 8b 78 08          	mov    0x8(%rax),%rdi
  800420770a:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
  800420770e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207712:	48 8b 75 b0          	mov    -0x50(%rbp),%rsi
  8004207716:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420771a:	48 83 ec 08          	sub    $0x8,%rsp
  800420771e:	ff 75 b8             	pushq  -0x48(%rbp)
  8004207721:	49 89 f9             	mov    %rdi,%r9
  8004207724:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  800420772a:	48 89 c7             	mov    %rax,%rdi
  800420772d:	48 b8 c3 70 20 04 80 	movabs $0x80042070c3,%rax
  8004207734:	00 00 00 
  8004207737:	ff d0                	callq  *%rax
  8004207739:	48 83 c4 10          	add    $0x10,%rsp
  800420773d:	89 45 f0             	mov    %eax,-0x10(%rbp)
							   &entry_off, 0, ret_fde->fde_cie, error);
		}

		if (ret != DW_DLE_NONE)
  8004207740:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
  8004207744:	74 07                	je     800420774d <_dwarf_get_next_fde+0x23d>
			return(-1);
  8004207746:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420774b:	eb 19                	jmp    8004207766 <_dwarf_get_next_fde+0x256>

		offset = entry_off;
  800420774d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004207751:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
		dbg->curr_off_eh = offset;
  8004207755:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004207759:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420775d:	48 89 50 30          	mov    %rdx,0x30(%rax)
	}

	return (0);
  8004207761:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004207766:	c9                   	leaveq 
  8004207767:	c3                   	retq   

0000008004207768 <dwarf_set_frame_cfa_value>:

Dwarf_Half
dwarf_set_frame_cfa_value(Dwarf_Debug dbg, Dwarf_Half value)
{
  8004207768:	55                   	push   %rbp
  8004207769:	48 89 e5             	mov    %rsp,%rbp
  800420776c:	48 83 ec 20          	sub    $0x20,%rsp
  8004207770:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004207774:	89 f0                	mov    %esi,%eax
  8004207776:	66 89 45 e4          	mov    %ax,-0x1c(%rbp)
	Dwarf_Half old_value;

	old_value = dbg->dbg_frame_cfa_value;
  800420777a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420777e:	0f b7 40 4c          	movzwl 0x4c(%rax),%eax
  8004207782:	66 89 45 fe          	mov    %ax,-0x2(%rbp)
	dbg->dbg_frame_cfa_value = value;
  8004207786:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420778a:	0f b7 55 e4          	movzwl -0x1c(%rbp),%edx
  800420778e:	66 89 50 4c          	mov    %dx,0x4c(%rax)

	return (old_value);
  8004207792:	0f b7 45 fe          	movzwl -0x2(%rbp),%eax
}
  8004207796:	c9                   	leaveq 
  8004207797:	c3                   	retq   

0000008004207798 <dwarf_init_eh_section>:

int dwarf_init_eh_section(Dwarf_Debug dbg, Dwarf_Error *error)
{
  8004207798:	55                   	push   %rbp
  8004207799:	48 89 e5             	mov    %rsp,%rbp
  800420779c:	48 83 ec 10          	sub    $0x10,%rsp
  80042077a0:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80042077a4:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	Dwarf_Section *section;

	if (dbg == NULL) {
  80042077a8:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  80042077ad:	75 0a                	jne    80042077b9 <dwarf_init_eh_section+0x21>
		DWARF_SET_ERROR(dbg, error, DW_DLE_ARGUMENT);
		return (DW_DLV_ERROR);
  80042077af:	b8 01 00 00 00       	mov    $0x1,%eax
  80042077b4:	e9 85 00 00 00       	jmpq   800420783e <dwarf_init_eh_section+0xa6>
	}

	if (dbg->dbg_internal_reg_table == NULL) {
  80042077b9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042077bd:	48 8b 40 58          	mov    0x58(%rax),%rax
  80042077c1:	48 85 c0             	test   %rax,%rax
  80042077c4:	75 25                	jne    80042077eb <dwarf_init_eh_section+0x53>
		if (_dwarf_frame_interal_table_init(dbg, error) != DW_DLE_NONE)
  80042077c6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042077ca:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042077ce:	48 89 d6             	mov    %rdx,%rsi
  80042077d1:	48 89 c7             	mov    %rax,%rdi
  80042077d4:	48 b8 a9 74 20 04 80 	movabs $0x80042074a9,%rax
  80042077db:	00 00 00 
  80042077de:	ff d0                	callq  *%rax
  80042077e0:	85 c0                	test   %eax,%eax
  80042077e2:	74 07                	je     80042077eb <dwarf_init_eh_section+0x53>
			return (DW_DLV_ERROR);
  80042077e4:	b8 01 00 00 00       	mov    $0x1,%eax
  80042077e9:	eb 53                	jmp    800420783e <dwarf_init_eh_section+0xa6>
	}

	_dwarf_find_section_enhanced(&debug_frame_sec);
  80042077eb:	48 bf e0 b5 21 04 80 	movabs $0x800421b5e0,%rdi
  80042077f2:	00 00 00 
  80042077f5:	48 b8 f0 51 20 04 80 	movabs $0x80042051f0,%rax
  80042077fc:	00 00 00 
  80042077ff:	ff d0                	callq  *%rax

	dbg->curr_off_eh = 0;
  8004207801:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207805:	48 c7 40 30 00 00 00 	movq   $0x0,0x30(%rax)
  800420780c:	00 
	dbg->dbg_eh_offset = debug_frame_sec.ds_addr;
  800420780d:	48 b8 e0 b5 21 04 80 	movabs $0x800421b5e0,%rax
  8004207814:	00 00 00 
  8004207817:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800420781b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420781f:	48 89 50 38          	mov    %rdx,0x38(%rax)
	dbg->dbg_eh_size = debug_frame_sec.ds_size;
  8004207823:	48 b8 e0 b5 21 04 80 	movabs $0x800421b5e0,%rax
  800420782a:	00 00 00 
  800420782d:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004207831:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207835:	48 89 50 40          	mov    %rdx,0x40(%rax)

	return (DW_DLV_OK);
  8004207839:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420783e:	c9                   	leaveq 
  800420783f:	c3                   	retq   

0000008004207840 <_dwarf_lineno_run_program>:
int  _dwarf_find_section_enhanced(Dwarf_Section *ds);

static int
_dwarf_lineno_run_program(Dwarf_CU *cu, Dwarf_LineInfo li, uint8_t *p,
			  uint8_t *pe, Dwarf_Addr pc, Dwarf_Error *error)
{
  8004207840:	55                   	push   %rbp
  8004207841:	48 89 e5             	mov    %rsp,%rbp
  8004207844:	48 81 ec 90 00 00 00 	sub    $0x90,%rsp
  800420784b:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
  800420784f:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
  8004207853:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
  8004207857:	48 89 4d 80          	mov    %rcx,-0x80(%rbp)
  800420785b:	4c 89 85 78 ff ff ff 	mov    %r8,-0x88(%rbp)
  8004207862:	4c 89 8d 70 ff ff ff 	mov    %r9,-0x90(%rbp)
	uint64_t address, file, line, column, isa, opsize;
	int is_stmt, basic_block, end_sequence;
	int prologue_end, epilogue_begin;
	int ret;

	ln = &li->li_line;
  8004207869:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420786d:	48 83 c0 48          	add    $0x48,%rax
  8004207871:	48 89 45 c8          	mov    %rax,-0x38(%rbp)

	/*
	 *   ln->ln_li     = li;             \
	 * Set registers to their default values.
	 */
	RESET_REGISTERS;
  8004207875:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  800420787c:	00 
  800420787d:	48 c7 45 f0 01 00 00 	movq   $0x1,-0x10(%rbp)
  8004207884:	00 
  8004207885:	48 c7 45 e8 01 00 00 	movq   $0x1,-0x18(%rbp)
  800420788c:	00 
  800420788d:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
  8004207894:	00 
  8004207895:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207899:	0f b6 40 19          	movzbl 0x19(%rax),%eax
  800420789d:	0f b6 c0             	movzbl %al,%eax
  80042078a0:	89 45 dc             	mov    %eax,-0x24(%rbp)
  80042078a3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  80042078aa:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  80042078b1:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
  80042078b8:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)

	/*
	 * Start line number program.
	 */
	while (p < pe) {
  80042078bf:	e9 b4 04 00 00       	jmpq   8004207d78 <_dwarf_lineno_run_program+0x538>
		if (*p == 0) {
  80042078c4:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  80042078c8:	0f b6 00             	movzbl (%rax),%eax
  80042078cb:	84 c0                	test   %al,%al
  80042078cd:	0f 85 4c 01 00 00    	jne    8004207a1f <_dwarf_lineno_run_program+0x1df>

			/*
			 * Extended Opcodes.
			 */

			p++;
  80042078d3:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  80042078d7:	48 83 c0 01          	add    $0x1,%rax
  80042078db:	48 89 45 88          	mov    %rax,-0x78(%rbp)
			opsize = _dwarf_decode_uleb128(&p);
  80042078df:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  80042078e3:	48 89 c7             	mov    %rax,%rdi
  80042078e6:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  80042078ed:	00 00 00 
  80042078f0:	ff d0                	callq  *%rax
  80042078f2:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
			switch (*p) {
  80042078f6:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  80042078fa:	0f b6 00             	movzbl (%rax),%eax
  80042078fd:	0f b6 c0             	movzbl %al,%eax
  8004207900:	83 f8 02             	cmp    $0x2,%eax
  8004207903:	74 74                	je     8004207979 <_dwarf_lineno_run_program+0x139>
  8004207905:	83 f8 03             	cmp    $0x3,%eax
  8004207908:	0f 84 a7 00 00 00    	je     80042079b5 <_dwarf_lineno_run_program+0x175>
  800420790e:	83 f8 01             	cmp    $0x1,%eax
  8004207911:	0f 85 ee 00 00 00    	jne    8004207a05 <_dwarf_lineno_run_program+0x1c5>
			case DW_LNE_end_sequence:
				p++;
  8004207917:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  800420791b:	48 83 c0 01          	add    $0x1,%rax
  800420791f:	48 89 45 88          	mov    %rax,-0x78(%rbp)
				end_sequence = 1;
  8004207923:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
				RESET_REGISTERS;
  800420792a:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004207931:	00 
  8004207932:	48 c7 45 f0 01 00 00 	movq   $0x1,-0x10(%rbp)
  8004207939:	00 
  800420793a:	48 c7 45 e8 01 00 00 	movq   $0x1,-0x18(%rbp)
  8004207941:	00 
  8004207942:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
  8004207949:	00 
  800420794a:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420794e:	0f b6 40 19          	movzbl 0x19(%rax),%eax
  8004207952:	0f b6 c0             	movzbl %al,%eax
  8004207955:	89 45 dc             	mov    %eax,-0x24(%rbp)
  8004207958:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  800420795f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  8004207966:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
  800420796d:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)
				break;
  8004207974:	e9 ff 03 00 00       	jmpq   8004207d78 <_dwarf_lineno_run_program+0x538>
			case DW_LNE_set_address:
				p++;
  8004207979:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  800420797d:	48 83 c0 01          	add    $0x1,%rax
  8004207981:	48 89 45 88          	mov    %rax,-0x78(%rbp)
				address = dbg->decode(&p, cu->addr_size);
  8004207985:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  800420798c:	00 00 00 
  800420798f:	48 8b 00             	mov    (%rax),%rax
  8004207992:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004207996:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  800420799a:	0f b6 52 0a          	movzbl 0xa(%rdx),%edx
  800420799e:	0f b6 ca             	movzbl %dl,%ecx
  80042079a1:	48 8d 55 88          	lea    -0x78(%rbp),%rdx
  80042079a5:	89 ce                	mov    %ecx,%esi
  80042079a7:	48 89 d7             	mov    %rdx,%rdi
  80042079aa:	ff d0                	callq  *%rax
  80042079ac:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
				break;
  80042079b0:	e9 c3 03 00 00       	jmpq   8004207d78 <_dwarf_lineno_run_program+0x538>
			case DW_LNE_define_file:
				p++;
  80042079b5:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  80042079b9:	48 83 c0 01          	add    $0x1,%rax
  80042079bd:	48 89 45 88          	mov    %rax,-0x78(%rbp)
				ret = _dwarf_lineno_add_file(li, &p, NULL,
  80042079c1:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  80042079c8:	00 00 00 
  80042079cb:	48 8b 08             	mov    (%rax),%rcx
  80042079ce:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  80042079d5:	48 8d 75 88          	lea    -0x78(%rbp),%rsi
  80042079d9:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042079dd:	49 89 c8             	mov    %rcx,%r8
  80042079e0:	48 89 d1             	mov    %rdx,%rcx
  80042079e3:	ba 00 00 00 00       	mov    $0x0,%edx
  80042079e8:	48 89 c7             	mov    %rax,%rdi
  80042079eb:	48 b8 92 7d 20 04 80 	movabs $0x8004207d92,%rax
  80042079f2:	00 00 00 
  80042079f5:	ff d0                	callq  *%rax
  80042079f7:	89 45 ac             	mov    %eax,-0x54(%rbp)
							     error, dbg);
				if (ret != DW_DLE_NONE)
  80042079fa:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  80042079fe:	74 19                	je     8004207a19 <_dwarf_lineno_run_program+0x1d9>
					goto prog_fail;
  8004207a00:	e9 88 03 00 00       	jmpq   8004207d8d <_dwarf_lineno_run_program+0x54d>
				break;
			default:
				/* Unrecognized extened opcodes. */
				p += opsize;
  8004207a05:	48 8b 55 88          	mov    -0x78(%rbp),%rdx
  8004207a09:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207a0d:	48 01 d0             	add    %rdx,%rax
  8004207a10:	48 89 45 88          	mov    %rax,-0x78(%rbp)
  8004207a14:	e9 5f 03 00 00       	jmpq   8004207d78 <_dwarf_lineno_run_program+0x538>
				break;
  8004207a19:	90                   	nop
  8004207a1a:	e9 59 03 00 00       	jmpq   8004207d78 <_dwarf_lineno_run_program+0x538>
			}

		} else if (*p > 0 && *p < li->li_opbase) {
  8004207a1f:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207a23:	0f b6 00             	movzbl (%rax),%eax
  8004207a26:	84 c0                	test   %al,%al
  8004207a28:	0f 84 24 02 00 00    	je     8004207c52 <_dwarf_lineno_run_program+0x412>
  8004207a2e:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207a32:	0f b6 10             	movzbl (%rax),%edx
  8004207a35:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207a39:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207a3d:	38 c2                	cmp    %al,%dl
  8004207a3f:	0f 83 0d 02 00 00    	jae    8004207c52 <_dwarf_lineno_run_program+0x412>

			/*
			 * Standard Opcodes.
			 */

			switch (*p++) {
  8004207a45:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207a49:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004207a4d:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
  8004207a51:	0f b6 00             	movzbl (%rax),%eax
  8004207a54:	0f b6 c0             	movzbl %al,%eax
  8004207a57:	83 f8 0c             	cmp    $0xc,%eax
  8004207a5a:	0f 87 ec 01 00 00    	ja     8004207c4c <_dwarf_lineno_run_program+0x40c>
  8004207a60:	89 c0                	mov    %eax,%eax
  8004207a62:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  8004207a69:	00 
  8004207a6a:	48 b8 88 a0 20 04 80 	movabs $0x800420a088,%rax
  8004207a71:	00 00 00 
  8004207a74:	48 01 d0             	add    %rdx,%rax
  8004207a77:	48 8b 00             	mov    (%rax),%rax
  8004207a7a:	ff e0                	jmpq   *%rax
			case DW_LNS_copy:
				APPEND_ROW;
  8004207a7c:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
  8004207a83:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8004207a87:	73 0a                	jae    8004207a93 <_dwarf_lineno_run_program+0x253>
  8004207a89:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207a8e:	e9 fd 02 00 00       	jmpq   8004207d90 <_dwarf_lineno_run_program+0x550>
  8004207a93:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207a97:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207a9b:	48 89 10             	mov    %rdx,(%rax)
  8004207a9e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207aa2:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
  8004207aa9:	00 
  8004207aaa:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207aae:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207ab2:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8004207ab6:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207aba:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207abe:	48 89 50 18          	mov    %rdx,0x18(%rax)
  8004207ac2:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207ac6:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207aca:	48 89 50 20          	mov    %rdx,0x20(%rax)
  8004207ace:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207ad2:	8b 55 d8             	mov    -0x28(%rbp),%edx
  8004207ad5:	89 50 28             	mov    %edx,0x28(%rax)
  8004207ad8:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207adc:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004207adf:	89 50 2c             	mov    %edx,0x2c(%rax)
  8004207ae2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207ae6:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004207ae9:	89 50 30             	mov    %edx,0x30(%rax)
  8004207aec:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207af0:	48 8b 80 80 00 00 00 	mov    0x80(%rax),%rax
  8004207af7:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004207afb:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207aff:	48 89 90 80 00 00 00 	mov    %rdx,0x80(%rax)
				basic_block = 0;
  8004207b06:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
				prologue_end = 0;
  8004207b0d:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
				epilogue_begin = 0;
  8004207b14:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)
				break;
  8004207b1b:	e9 2d 01 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_advance_pc:
				address += _dwarf_decode_uleb128(&p) *
  8004207b20:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207b24:	48 89 c7             	mov    %rax,%rdi
  8004207b27:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207b2e:	00 00 00 
  8004207b31:	ff d0                	callq  *%rax
  8004207b33:	48 89 c2             	mov    %rax,%rdx
					li->li_minlen;
  8004207b36:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207b3a:	0f b6 40 18          	movzbl 0x18(%rax),%eax
  8004207b3e:	0f b6 c0             	movzbl %al,%eax
				address += _dwarf_decode_uleb128(&p) *
  8004207b41:	48 0f af c2          	imul   %rdx,%rax
  8004207b45:	48 01 45 f8          	add    %rax,-0x8(%rbp)
				break;
  8004207b49:	e9 ff 00 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_advance_line:
				line += _dwarf_decode_sleb128(&p);
  8004207b4e:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207b52:	48 89 c7             	mov    %rax,%rdi
  8004207b55:	48 b8 92 3a 20 04 80 	movabs $0x8004203a92,%rax
  8004207b5c:	00 00 00 
  8004207b5f:	ff d0                	callq  *%rax
  8004207b61:	48 01 45 e8          	add    %rax,-0x18(%rbp)
				break;
  8004207b65:	e9 e3 00 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_set_file:
				file = _dwarf_decode_uleb128(&p);
  8004207b6a:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207b6e:	48 89 c7             	mov    %rax,%rdi
  8004207b71:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207b78:	00 00 00 
  8004207b7b:	ff d0                	callq  *%rax
  8004207b7d:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
				break;
  8004207b81:	e9 c7 00 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_set_column:
				column = _dwarf_decode_uleb128(&p);
  8004207b86:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207b8a:	48 89 c7             	mov    %rax,%rdi
  8004207b8d:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207b94:	00 00 00 
  8004207b97:	ff d0                	callq  *%rax
  8004207b99:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
				break;
  8004207b9d:	e9 ab 00 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_negate_stmt:
				is_stmt = !is_stmt;
  8004207ba2:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004207ba6:	0f 94 c0             	sete   %al
  8004207ba9:	0f b6 c0             	movzbl %al,%eax
  8004207bac:	89 45 dc             	mov    %eax,-0x24(%rbp)
				break;
  8004207baf:	e9 99 00 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_set_basic_block:
				basic_block = 1;
  8004207bb4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%rbp)
				break;
  8004207bbb:	e9 8d 00 00 00       	jmpq   8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_const_add_pc:
				address += ADDRESS(255);
  8004207bc0:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207bc4:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207bc8:	0f b6 c0             	movzbl %al,%eax
  8004207bcb:	ba ff 00 00 00       	mov    $0xff,%edx
  8004207bd0:	89 d1                	mov    %edx,%ecx
  8004207bd2:	29 c1                	sub    %eax,%ecx
  8004207bd4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207bd8:	0f b6 40 1b          	movzbl 0x1b(%rax),%eax
  8004207bdc:	0f b6 f0             	movzbl %al,%esi
  8004207bdf:	89 c8                	mov    %ecx,%eax
  8004207be1:	99                   	cltd   
  8004207be2:	f7 fe                	idiv   %esi
  8004207be4:	89 c2                	mov    %eax,%edx
  8004207be6:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207bea:	0f b6 40 18          	movzbl 0x18(%rax),%eax
  8004207bee:	0f b6 c0             	movzbl %al,%eax
  8004207bf1:	0f af c2             	imul   %edx,%eax
  8004207bf4:	48 98                	cltq   
  8004207bf6:	48 01 45 f8          	add    %rax,-0x8(%rbp)
				break;
  8004207bfa:	eb 51                	jmp    8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_fixed_advance_pc:
				address += dbg->decode(&p, 2);
  8004207bfc:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004207c03:	00 00 00 
  8004207c06:	48 8b 00             	mov    (%rax),%rax
  8004207c09:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004207c0d:	48 8d 55 88          	lea    -0x78(%rbp),%rdx
  8004207c11:	be 02 00 00 00       	mov    $0x2,%esi
  8004207c16:	48 89 d7             	mov    %rdx,%rdi
  8004207c19:	ff d0                	callq  *%rax
  8004207c1b:	48 01 45 f8          	add    %rax,-0x8(%rbp)
				break;
  8004207c1f:	eb 2c                	jmp    8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_set_prologue_end:
				prologue_end = 1;
  8004207c21:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%rbp)
				break;
  8004207c28:	eb 23                	jmp    8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_set_epilogue_begin:
				epilogue_begin = 1;
  8004207c2a:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%rbp)
				break;
  8004207c31:	eb 1a                	jmp    8004207c4d <_dwarf_lineno_run_program+0x40d>
			case DW_LNS_set_isa:
				isa = _dwarf_decode_uleb128(&p);
  8004207c33:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207c37:	48 89 c7             	mov    %rax,%rdi
  8004207c3a:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207c41:	00 00 00 
  8004207c44:	ff d0                	callq  *%rax
  8004207c46:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
				break;
  8004207c4a:	eb 01                	jmp    8004207c4d <_dwarf_lineno_run_program+0x40d>
			default:
				/* Unrecognized extened opcodes. What to do? */
				break;
  8004207c4c:	90                   	nop
			}

		} else {
  8004207c4d:	e9 26 01 00 00       	jmpq   8004207d78 <_dwarf_lineno_run_program+0x538>

			/*
			 * Special Opcodes.
			 */

			line += LINE(*p);
  8004207c52:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c56:	0f b6 40 1a          	movzbl 0x1a(%rax),%eax
  8004207c5a:	0f be c8             	movsbl %al,%ecx
  8004207c5d:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207c61:	0f b6 00             	movzbl (%rax),%eax
  8004207c64:	0f b6 d0             	movzbl %al,%edx
  8004207c67:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c6b:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207c6f:	0f b6 c0             	movzbl %al,%eax
  8004207c72:	29 c2                	sub    %eax,%edx
  8004207c74:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c78:	0f b6 40 1b          	movzbl 0x1b(%rax),%eax
  8004207c7c:	0f b6 f0             	movzbl %al,%esi
  8004207c7f:	89 d0                	mov    %edx,%eax
  8004207c81:	99                   	cltd   
  8004207c82:	f7 fe                	idiv   %esi
  8004207c84:	89 d0                	mov    %edx,%eax
  8004207c86:	01 c8                	add    %ecx,%eax
  8004207c88:	48 98                	cltq   
  8004207c8a:	48 01 45 e8          	add    %rax,-0x18(%rbp)
			address += ADDRESS(*p);
  8004207c8e:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207c92:	0f b6 00             	movzbl (%rax),%eax
  8004207c95:	0f b6 d0             	movzbl %al,%edx
  8004207c98:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c9c:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207ca0:	0f b6 c0             	movzbl %al,%eax
  8004207ca3:	89 d1                	mov    %edx,%ecx
  8004207ca5:	29 c1                	sub    %eax,%ecx
  8004207ca7:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207cab:	0f b6 40 1b          	movzbl 0x1b(%rax),%eax
  8004207caf:	0f b6 f0             	movzbl %al,%esi
  8004207cb2:	89 c8                	mov    %ecx,%eax
  8004207cb4:	99                   	cltd   
  8004207cb5:	f7 fe                	idiv   %esi
  8004207cb7:	89 c2                	mov    %eax,%edx
  8004207cb9:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207cbd:	0f b6 40 18          	movzbl 0x18(%rax),%eax
  8004207cc1:	0f b6 c0             	movzbl %al,%eax
  8004207cc4:	0f af c2             	imul   %edx,%eax
  8004207cc7:	48 98                	cltq   
  8004207cc9:	48 01 45 f8          	add    %rax,-0x8(%rbp)
			APPEND_ROW;
  8004207ccd:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
  8004207cd4:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8004207cd8:	73 0a                	jae    8004207ce4 <_dwarf_lineno_run_program+0x4a4>
  8004207cda:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207cdf:	e9 ac 00 00 00       	jmpq   8004207d90 <_dwarf_lineno_run_program+0x550>
  8004207ce4:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207ce8:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207cec:	48 89 10             	mov    %rdx,(%rax)
  8004207cef:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207cf3:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
  8004207cfa:	00 
  8004207cfb:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207cff:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207d03:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8004207d07:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d0b:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207d0f:	48 89 50 18          	mov    %rdx,0x18(%rax)
  8004207d13:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207d17:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d1b:	48 89 50 20          	mov    %rdx,0x20(%rax)
  8004207d1f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d23:	8b 55 d8             	mov    -0x28(%rbp),%edx
  8004207d26:	89 50 28             	mov    %edx,0x28(%rax)
  8004207d29:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d2d:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004207d30:	89 50 2c             	mov    %edx,0x2c(%rax)
  8004207d33:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d37:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004207d3a:	89 50 30             	mov    %edx,0x30(%rax)
  8004207d3d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207d41:	48 8b 80 80 00 00 00 	mov    0x80(%rax),%rax
  8004207d48:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004207d4c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207d50:	48 89 90 80 00 00 00 	mov    %rdx,0x80(%rax)
			basic_block = 0;
  8004207d57:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
			prologue_end = 0;
  8004207d5e:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
			epilogue_begin = 0;
  8004207d65:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)
			p++;
  8004207d6c:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207d70:	48 83 c0 01          	add    $0x1,%rax
  8004207d74:	48 89 45 88          	mov    %rax,-0x78(%rbp)
	while (p < pe) {
  8004207d78:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207d7c:	48 39 45 80          	cmp    %rax,-0x80(%rbp)
  8004207d80:	0f 87 3e fb ff ff    	ja     80042078c4 <_dwarf_lineno_run_program+0x84>
		}
	}

	return (DW_DLE_NONE);
  8004207d86:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207d8b:	eb 03                	jmp    8004207d90 <_dwarf_lineno_run_program+0x550>

prog_fail:

	return (ret);
  8004207d8d:	8b 45 ac             	mov    -0x54(%rbp),%eax

#undef  RESET_REGISTERS
#undef  APPEND_ROW
#undef  LINE
#undef  ADDRESS
}
  8004207d90:	c9                   	leaveq 
  8004207d91:	c3                   	retq   

0000008004207d92 <_dwarf_lineno_add_file>:

static int
_dwarf_lineno_add_file(Dwarf_LineInfo li, uint8_t **p, const char *compdir,
		       Dwarf_Error *error, Dwarf_Debug dbg)
{
  8004207d92:	55                   	push   %rbp
  8004207d93:	48 89 e5             	mov    %rsp,%rbp
  8004207d96:	48 83 ec 40          	sub    $0x40,%rsp
  8004207d9a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004207d9e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004207da2:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004207da6:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  8004207daa:	4c 89 45 c8          	mov    %r8,-0x38(%rbp)
	char *fname;
	//const char *dirname;
	uint8_t *src;
	int slen;

	src = *p;
  8004207dae:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004207db2:	48 8b 00             	mov    (%rax),%rax
  8004207db5:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  DWARF_SET_ERROR(dbg, error, DW_DLE_MEMORY);
  return (DW_DLE_MEMORY);
  }
*/  
	//lf->lf_fullpath = NULL;
	fname = (char *) src;
  8004207db9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004207dbd:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	src += strlen(fname) + 1;
  8004207dc1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207dc5:	48 89 c7             	mov    %rax,%rdi
  8004207dc8:	48 b8 fb 2b 20 04 80 	movabs $0x8004202bfb,%rax
  8004207dcf:	00 00 00 
  8004207dd2:	ff d0                	callq  *%rax
  8004207dd4:	83 c0 01             	add    $0x1,%eax
  8004207dd7:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207ddb:	48 98                	cltq   
  8004207ddd:	48 01 d0             	add    %rdx,%rax
  8004207de0:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	_dwarf_decode_uleb128(&src);
  8004207de4:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  8004207de8:	48 89 c7             	mov    %rax,%rdi
  8004207deb:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207df2:	00 00 00 
  8004207df5:	ff d0                	callq  *%rax
	   snprintf(lf->lf_fullpath, slen, "%s/%s", dirname,
	   lf->lf_fname);
	   }
	   }
	*/
	_dwarf_decode_uleb128(&src);
  8004207df7:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  8004207dfb:	48 89 c7             	mov    %rax,%rdi
  8004207dfe:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207e05:	00 00 00 
  8004207e08:	ff d0                	callq  *%rax
	_dwarf_decode_uleb128(&src);
  8004207e0a:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  8004207e0e:	48 89 c7             	mov    %rax,%rdi
  8004207e11:	48 b8 24 3b 20 04 80 	movabs $0x8004203b24,%rax
  8004207e18:	00 00 00 
  8004207e1b:	ff d0                	callq  *%rax
	//STAILQ_INSERT_TAIL(&li->li_lflist, lf, lf_next);
	//li->li_lflen++;

	*p = src;
  8004207e1d:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207e21:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004207e25:	48 89 10             	mov    %rdx,(%rax)

	return (DW_DLE_NONE);
  8004207e28:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004207e2d:	c9                   	leaveq 
  8004207e2e:	c3                   	retq   

0000008004207e2f <_dwarf_lineno_init>:

int     
_dwarf_lineno_init(Dwarf_Die *die, uint64_t offset, Dwarf_LineInfo linfo, Dwarf_Addr pc, Dwarf_Error *error)
{   
  8004207e2f:	55                   	push   %rbp
  8004207e30:	48 89 e5             	mov    %rsp,%rbp
  8004207e33:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  8004207e3a:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  8004207e41:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  8004207e48:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  8004207e4f:	48 89 8d 10 ff ff ff 	mov    %rcx,-0xf0(%rbp)
  8004207e56:	4c 89 85 08 ff ff ff 	mov    %r8,-0xf8(%rbp)
	Dwarf_Section myds = {.ds_name = ".debug_line"};
  8004207e5d:	48 c7 45 a0 00 00 00 	movq   $0x0,-0x60(%rbp)
  8004207e64:	00 
  8004207e65:	48 c7 45 a8 00 00 00 	movq   $0x0,-0x58(%rbp)
  8004207e6c:	00 
  8004207e6d:	48 c7 45 b0 00 00 00 	movq   $0x0,-0x50(%rbp)
  8004207e74:	00 
  8004207e75:	48 c7 45 b8 00 00 00 	movq   $0x0,-0x48(%rbp)
  8004207e7c:	00 
  8004207e7d:	48 b8 f0 a0 20 04 80 	movabs $0x800420a0f0,%rax
  8004207e84:	00 00 00 
  8004207e87:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
	Dwarf_Section *ds = &myds;
  8004207e8b:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004207e8f:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	//Dwarf_LineFile lf, tlf;
	uint64_t length, hdroff, endoff;
	uint8_t *p;
	int dwarf_size, i, ret;
            
	cu = die->cu_header;
  8004207e93:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  8004207e9a:	48 8b 80 60 03 00 00 	mov    0x360(%rax),%rax
  8004207ea1:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	assert(cu != NULL); 
  8004207ea5:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004207eaa:	75 35                	jne    8004207ee1 <_dwarf_lineno_init+0xb2>
  8004207eac:	48 b9 fc a0 20 04 80 	movabs $0x800420a0fc,%rcx
  8004207eb3:	00 00 00 
  8004207eb6:	48 ba 07 a1 20 04 80 	movabs $0x800420a107,%rdx
  8004207ebd:	00 00 00 
  8004207ec0:	be 13 01 00 00       	mov    $0x113,%esi
  8004207ec5:	48 bf 1c a1 20 04 80 	movabs $0x800420a11c,%rdi
  8004207ecc:	00 00 00 
  8004207ecf:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207ed4:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004207edb:	00 00 00 
  8004207ede:	41 ff d0             	callq  *%r8
	assert(dbg != NULL);
  8004207ee1:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004207ee8:	00 00 00 
  8004207eeb:	48 8b 00             	mov    (%rax),%rax
  8004207eee:	48 85 c0             	test   %rax,%rax
  8004207ef1:	75 35                	jne    8004207f28 <_dwarf_lineno_init+0xf9>
  8004207ef3:	48 b9 33 a1 20 04 80 	movabs $0x800420a133,%rcx
  8004207efa:	00 00 00 
  8004207efd:	48 ba 07 a1 20 04 80 	movabs $0x800420a107,%rdx
  8004207f04:	00 00 00 
  8004207f07:	be 14 01 00 00       	mov    $0x114,%esi
  8004207f0c:	48 bf 1c a1 20 04 80 	movabs $0x800420a11c,%rdi
  8004207f13:	00 00 00 
  8004207f16:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207f1b:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004207f22:	00 00 00 
  8004207f25:	41 ff d0             	callq  *%r8

	if ((_dwarf_find_section_enhanced(ds)) != 0)
  8004207f28:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004207f2c:	48 89 c7             	mov    %rax,%rdi
  8004207f2f:	48 b8 f0 51 20 04 80 	movabs $0x80042051f0,%rax
  8004207f36:	00 00 00 
  8004207f39:	ff d0                	callq  *%rax
  8004207f3b:	85 c0                	test   %eax,%eax
  8004207f3d:	74 0a                	je     8004207f49 <_dwarf_lineno_init+0x11a>
		return (DW_DLE_NONE);
  8004207f3f:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207f44:	e9 55 04 00 00       	jmpq   800420839e <_dwarf_lineno_init+0x56f>

	li = linfo;
  8004207f49:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
  8004207f50:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
	 break;
	 }
	 }
	*/

	length = dbg->read(ds->ds_data, &offset, 4);
  8004207f54:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004207f5b:	00 00 00 
  8004207f5e:	48 8b 00             	mov    (%rax),%rax
  8004207f61:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207f65:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207f69:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004207f6d:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  8004207f74:	ba 04 00 00 00       	mov    $0x4,%edx
  8004207f79:	48 89 cf             	mov    %rcx,%rdi
  8004207f7c:	ff d0                	callq  *%rax
  8004207f7e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (length == 0xffffffff) {
  8004207f82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004207f87:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004207f8b:	75 37                	jne    8004207fc4 <_dwarf_lineno_init+0x195>
		dwarf_size = 8;
  8004207f8d:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
		length = dbg->read(ds->ds_data, &offset, 8);
  8004207f94:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004207f9b:	00 00 00 
  8004207f9e:	48 8b 00             	mov    (%rax),%rax
  8004207fa1:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004207fa5:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207fa9:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004207fad:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  8004207fb4:	ba 08 00 00 00       	mov    $0x8,%edx
  8004207fb9:	48 89 cf             	mov    %rcx,%rdi
  8004207fbc:	ff d0                	callq  *%rax
  8004207fbe:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004207fc2:	eb 07                	jmp    8004207fcb <_dwarf_lineno_init+0x19c>
	} else
		dwarf_size = 4;
  8004207fc4:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

	if (length > ds->ds_size - offset) {
  8004207fcb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004207fcf:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004207fd3:	48 8b 85 20 ff ff ff 	mov    -0xe0(%rbp),%rax
  8004207fda:	48 29 c2             	sub    %rax,%rdx
  8004207fdd:	48 89 d0             	mov    %rdx,%rax
  8004207fe0:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004207fe4:	76 0a                	jbe    8004207ff0 <_dwarf_lineno_init+0x1c1>
		DWARF_SET_ERROR(dbg, error, DW_DLE_DEBUG_LINE_LENGTH_BAD);
		return (DW_DLE_DEBUG_LINE_LENGTH_BAD);
  8004207fe6:	b8 0f 00 00 00       	mov    $0xf,%eax
  8004207feb:	e9 ae 03 00 00       	jmpq   800420839e <_dwarf_lineno_init+0x56f>
	}
	/*
	 * Read in line number program header.
	 */
	li->li_length = length;
  8004207ff0:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004207ff4:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207ff8:	48 89 10             	mov    %rdx,(%rax)
	endoff = offset + length;
  8004207ffb:	48 8b 95 20 ff ff ff 	mov    -0xe0(%rbp),%rdx
  8004208002:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004208006:	48 01 d0             	add    %rdx,%rax
  8004208009:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
	li->li_version = dbg->read(ds->ds_data, &offset, 2); /* FIXME: verify version */
  800420800d:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004208014:	00 00 00 
  8004208017:	48 8b 00             	mov    (%rax),%rax
  800420801a:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420801e:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004208022:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004208026:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  800420802d:	ba 02 00 00 00       	mov    $0x2,%edx
  8004208032:	48 89 cf             	mov    %rcx,%rdi
  8004208035:	ff d0                	callq  *%rax
  8004208037:	89 c2                	mov    %eax,%edx
  8004208039:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420803d:	66 89 50 08          	mov    %dx,0x8(%rax)
	li->li_hdrlen = dbg->read(ds->ds_data, &offset, dwarf_size);
  8004208041:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004208048:	00 00 00 
  800420804b:	48 8b 00             	mov    (%rax),%rax
  800420804e:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208052:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004208056:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800420805a:	8b 55 f4             	mov    -0xc(%rbp),%edx
  800420805d:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  8004208064:	48 89 cf             	mov    %rcx,%rdi
  8004208067:	ff d0                	callq  *%rax
  8004208069:	48 89 c2             	mov    %rax,%rdx
  800420806c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208070:	48 89 50 10          	mov    %rdx,0x10(%rax)
	hdroff = offset;
  8004208074:	48 8b 85 20 ff ff ff 	mov    -0xe0(%rbp),%rax
  800420807b:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
	li->li_minlen = dbg->read(ds->ds_data, &offset, 1);
  800420807f:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004208086:	00 00 00 
  8004208089:	48 8b 00             	mov    (%rax),%rax
  800420808c:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208090:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004208094:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004208098:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  800420809f:	ba 01 00 00 00       	mov    $0x1,%edx
  80042080a4:	48 89 cf             	mov    %rcx,%rdi
  80042080a7:	ff d0                	callq  *%rax
  80042080a9:	89 c2                	mov    %eax,%edx
  80042080ab:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042080af:	88 50 18             	mov    %dl,0x18(%rax)
	li->li_defstmt = dbg->read(ds->ds_data, &offset, 1);
  80042080b2:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  80042080b9:	00 00 00 
  80042080bc:	48 8b 00             	mov    (%rax),%rax
  80042080bf:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042080c3:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042080c7:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042080cb:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  80042080d2:	ba 01 00 00 00       	mov    $0x1,%edx
  80042080d7:	48 89 cf             	mov    %rcx,%rdi
  80042080da:	ff d0                	callq  *%rax
  80042080dc:	89 c2                	mov    %eax,%edx
  80042080de:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042080e2:	88 50 19             	mov    %dl,0x19(%rax)
	li->li_lbase = dbg->read(ds->ds_data, &offset, 1);
  80042080e5:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  80042080ec:	00 00 00 
  80042080ef:	48 8b 00             	mov    (%rax),%rax
  80042080f2:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042080f6:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042080fa:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042080fe:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  8004208105:	ba 01 00 00 00       	mov    $0x1,%edx
  800420810a:	48 89 cf             	mov    %rcx,%rdi
  800420810d:	ff d0                	callq  *%rax
  800420810f:	89 c2                	mov    %eax,%edx
  8004208111:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208115:	88 50 1a             	mov    %dl,0x1a(%rax)
	li->li_lrange = dbg->read(ds->ds_data, &offset, 1);
  8004208118:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  800420811f:	00 00 00 
  8004208122:	48 8b 00             	mov    (%rax),%rax
  8004208125:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208129:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  800420812d:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004208131:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  8004208138:	ba 01 00 00 00       	mov    $0x1,%edx
  800420813d:	48 89 cf             	mov    %rcx,%rdi
  8004208140:	ff d0                	callq  *%rax
  8004208142:	89 c2                	mov    %eax,%edx
  8004208144:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208148:	88 50 1b             	mov    %dl,0x1b(%rax)
	li->li_opbase = dbg->read(ds->ds_data, &offset, 1);
  800420814b:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  8004208152:	00 00 00 
  8004208155:	48 8b 00             	mov    (%rax),%rax
  8004208158:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420815c:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004208160:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004208164:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  800420816b:	ba 01 00 00 00       	mov    $0x1,%edx
  8004208170:	48 89 cf             	mov    %rcx,%rdi
  8004208173:	ff d0                	callq  *%rax
  8004208175:	89 c2                	mov    %eax,%edx
  8004208177:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420817b:	88 50 1c             	mov    %dl,0x1c(%rax)
	//STAILQ_INIT(&li->li_lflist);
	//STAILQ_INIT(&li->li_lnlist);

	if ((int)li->li_hdrlen - 5 < li->li_opbase - 1) {
  800420817e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208182:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004208186:	8d 50 fb             	lea    -0x5(%rax),%edx
  8004208189:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420818d:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004208191:	0f b6 c0             	movzbl %al,%eax
  8004208194:	83 e8 01             	sub    $0x1,%eax
  8004208197:	39 c2                	cmp    %eax,%edx
  8004208199:	7d 0c                	jge    80042081a7 <_dwarf_lineno_init+0x378>
		ret = DW_DLE_DEBUG_LINE_LENGTH_BAD;
  800420819b:	c7 45 ec 0f 00 00 00 	movl   $0xf,-0x14(%rbp)
		DWARF_SET_ERROR(dbg, error, ret);
		goto fail_cleanup;
  80042081a2:	e9 f4 01 00 00       	jmpq   800420839b <_dwarf_lineno_init+0x56c>
	}

	li->li_oplen = global_std_op;
  80042081a7:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042081ab:	48 bf 40 cb 21 04 80 	movabs $0x800421cb40,%rdi
  80042081b2:	00 00 00 
  80042081b5:	48 89 78 20          	mov    %rdi,0x20(%rax)

	/*
	 * Read in std opcode arg length list. Note that the first
	 * element is not used.
	 */
	for (i = 1; i < li->li_opbase; i++)
  80042081b9:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%rbp)
  80042081c0:	eb 45                	jmp    8004208207 <_dwarf_lineno_init+0x3d8>
		li->li_oplen[i] = dbg->read(ds->ds_data, &offset, 1);
  80042081c2:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  80042081c9:	00 00 00 
  80042081cc:	48 8b 00             	mov    (%rax),%rax
  80042081cf:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042081d3:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042081d7:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042081db:	48 8d b5 20 ff ff ff 	lea    -0xe0(%rbp),%rsi
  80042081e2:	ba 01 00 00 00       	mov    $0x1,%edx
  80042081e7:	48 89 cf             	mov    %rcx,%rdi
  80042081ea:	ff d0                	callq  *%rax
  80042081ec:	48 89 c1             	mov    %rax,%rcx
  80042081ef:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042081f3:	48 8b 50 20          	mov    0x20(%rax),%rdx
  80042081f7:	8b 45 f0             	mov    -0x10(%rbp),%eax
  80042081fa:	48 98                	cltq   
  80042081fc:	48 01 d0             	add    %rdx,%rax
  80042081ff:	89 ca                	mov    %ecx,%edx
  8004208201:	88 10                	mov    %dl,(%rax)
	for (i = 1; i < li->li_opbase; i++)
  8004208203:	83 45 f0 01          	addl   $0x1,-0x10(%rbp)
  8004208207:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420820b:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  800420820f:	0f b6 c0             	movzbl %al,%eax
  8004208212:	39 45 f0             	cmp    %eax,-0x10(%rbp)
  8004208215:	7c ab                	jl     80042081c2 <_dwarf_lineno_init+0x393>

	/*
	 * Check how many strings in the include dir string array.
	 */
	length = 0;
  8004208217:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  800420821e:	00 
	p = ds->ds_data + offset;
  800420821f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004208223:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004208227:	48 8b 85 20 ff ff ff 	mov    -0xe0(%rbp),%rax
  800420822e:	48 01 d0             	add    %rdx,%rax
  8004208231:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
	while (*p != '\0') {
  8004208238:	eb 1f                	jmp    8004208259 <_dwarf_lineno_init+0x42a>
		while (*p++ != '\0')
  800420823a:	90                   	nop
  800420823b:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  8004208242:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004208246:	48 89 95 38 ff ff ff 	mov    %rdx,-0xc8(%rbp)
  800420824d:	0f b6 00             	movzbl (%rax),%eax
  8004208250:	84 c0                	test   %al,%al
  8004208252:	75 e7                	jne    800420823b <_dwarf_lineno_init+0x40c>
			;
		length++;
  8004208254:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
	while (*p != '\0') {
  8004208259:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  8004208260:	0f b6 00             	movzbl (%rax),%eax
  8004208263:	84 c0                	test   %al,%al
  8004208265:	75 d3                	jne    800420823a <_dwarf_lineno_init+0x40b>
	}
	li->li_inclen = length;
  8004208267:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420826b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420826f:	48 89 50 30          	mov    %rdx,0x30(%rax)

	/* Sanity check. */
	if (p - ds->ds_data > (int) ds->ds_size) {
  8004208273:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  800420827a:	48 89 c2             	mov    %rax,%rdx
  800420827d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004208281:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208285:	48 29 c2             	sub    %rax,%rdx
  8004208288:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420828c:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208290:	48 98                	cltq   
  8004208292:	48 39 c2             	cmp    %rax,%rdx
  8004208295:	7e 0c                	jle    80042082a3 <_dwarf_lineno_init+0x474>
		ret = DW_DLE_DEBUG_LINE_LENGTH_BAD;
  8004208297:	c7 45 ec 0f 00 00 00 	movl   $0xf,-0x14(%rbp)
		DWARF_SET_ERROR(dbg, error, ret);
		goto fail_cleanup;
  800420829e:	e9 f8 00 00 00       	jmpq   800420839b <_dwarf_lineno_init+0x56c>
	}
	p++;
  80042082a3:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  80042082aa:	48 83 c0 01          	add    $0x1,%rax
  80042082ae:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)

	/*
	 * Process file list.
	 */
	while (*p != '\0') {
  80042082b5:	eb 3c                	jmp    80042082f3 <_dwarf_lineno_init+0x4c4>
		ret = _dwarf_lineno_add_file(li, &p, NULL, error, dbg);
  80042082b7:	48 b8 c0 b5 21 04 80 	movabs $0x800421b5c0,%rax
  80042082be:	00 00 00 
  80042082c1:	48 8b 08             	mov    (%rax),%rcx
  80042082c4:	48 8b 95 08 ff ff ff 	mov    -0xf8(%rbp),%rdx
  80042082cb:	48 8d b5 38 ff ff ff 	lea    -0xc8(%rbp),%rsi
  80042082d2:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042082d6:	49 89 c8             	mov    %rcx,%r8
  80042082d9:	48 89 d1             	mov    %rdx,%rcx
  80042082dc:	ba 00 00 00 00       	mov    $0x0,%edx
  80042082e1:	48 89 c7             	mov    %rax,%rdi
  80042082e4:	48 b8 92 7d 20 04 80 	movabs $0x8004207d92,%rax
  80042082eb:	00 00 00 
  80042082ee:	ff d0                	callq  *%rax
  80042082f0:	89 45 ec             	mov    %eax,-0x14(%rbp)
	while (*p != '\0') {
  80042082f3:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  80042082fa:	0f b6 00             	movzbl (%rax),%eax
  80042082fd:	84 c0                	test   %al,%al
  80042082ff:	75 b6                	jne    80042082b7 <_dwarf_lineno_init+0x488>
		//p++;
	}

	p++;
  8004208301:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  8004208308:	48 83 c0 01          	add    $0x1,%rax
  800420830c:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
	/* Sanity check. */
	if (p - ds->ds_data - hdroff != li->li_hdrlen) {
  8004208313:	48 8b 85 38 ff ff ff 	mov    -0xc8(%rbp),%rax
  800420831a:	48 89 c2             	mov    %rax,%rdx
  800420831d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004208321:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208325:	48 29 c2             	sub    %rax,%rdx
  8004208328:	48 89 d0             	mov    %rdx,%rax
  800420832b:	48 2b 45 c0          	sub    -0x40(%rbp),%rax
  800420832f:	48 89 c2             	mov    %rax,%rdx
  8004208332:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208336:	48 8b 40 10          	mov    0x10(%rax),%rax
  800420833a:	48 39 c2             	cmp    %rax,%rdx
  800420833d:	74 09                	je     8004208348 <_dwarf_lineno_init+0x519>
		ret = DW_DLE_DEBUG_LINE_LENGTH_BAD;
  800420833f:	c7 45 ec 0f 00 00 00 	movl   $0xf,-0x14(%rbp)
		DWARF_SET_ERROR(dbg, error, ret);
		goto fail_cleanup;
  8004208346:	eb 53                	jmp    800420839b <_dwarf_lineno_init+0x56c>
	}

	/*
	 * Process line number program.
	 */
	ret = _dwarf_lineno_run_program(cu, li, p, ds->ds_data + endoff, pc,
  8004208348:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420834c:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004208350:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004208354:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  8004208358:	48 8b 95 38 ff ff ff 	mov    -0xc8(%rbp),%rdx
  800420835f:	4c 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%r8
  8004208366:	48 8b bd 10 ff ff ff 	mov    -0xf0(%rbp),%rdi
  800420836d:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8004208371:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004208375:	4d 89 c1             	mov    %r8,%r9
  8004208378:	49 89 f8             	mov    %rdi,%r8
  800420837b:	48 89 c7             	mov    %rax,%rdi
  800420837e:	48 b8 40 78 20 04 80 	movabs $0x8004207840,%rax
  8004208385:	00 00 00 
  8004208388:	ff d0                	callq  *%rax
  800420838a:	89 45 ec             	mov    %eax,-0x14(%rbp)
					error);
	if (ret != DW_DLE_NONE)
  800420838d:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8004208391:	75 07                	jne    800420839a <_dwarf_lineno_init+0x56b>
		goto fail_cleanup;

	//cu->cu_lineinfo = li;

	return (DW_DLE_NONE);
  8004208393:	b8 00 00 00 00       	mov    $0x0,%eax
  8004208398:	eb 04                	jmp    800420839e <_dwarf_lineno_init+0x56f>
		goto fail_cleanup;
  800420839a:	90                   	nop
fail_cleanup:

	/*if (li->li_oplen)
	  free(li->li_oplen);*/

	return (ret);
  800420839b:	8b 45 ec             	mov    -0x14(%rbp),%eax
}
  800420839e:	c9                   	leaveq 
  800420839f:	c3                   	retq   

00000080042083a0 <dwarf_srclines>:

int
dwarf_srclines(Dwarf_Die *die, Dwarf_Line linebuf, Dwarf_Addr pc, Dwarf_Error *error)
{
  80042083a0:	55                   	push   %rbp
  80042083a1:	48 89 e5             	mov    %rsp,%rbp
  80042083a4:	48 81 ec b0 00 00 00 	sub    $0xb0,%rsp
  80042083ab:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  80042083b2:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  80042083b9:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  80042083c0:	48 89 8d 50 ff ff ff 	mov    %rcx,-0xb0(%rbp)
	_Dwarf_LineInfo li;
	Dwarf_Attribute *at;

	assert(die);
  80042083c7:	48 83 bd 68 ff ff ff 	cmpq   $0x0,-0x98(%rbp)
  80042083ce:	00 
  80042083cf:	75 35                	jne    8004208406 <dwarf_srclines+0x66>
  80042083d1:	48 b9 3f a1 20 04 80 	movabs $0x800420a13f,%rcx
  80042083d8:	00 00 00 
  80042083db:	48 ba 07 a1 20 04 80 	movabs $0x800420a107,%rdx
  80042083e2:	00 00 00 
  80042083e5:	be 9a 01 00 00       	mov    $0x19a,%esi
  80042083ea:	48 bf 1c a1 20 04 80 	movabs $0x800420a11c,%rdi
  80042083f1:	00 00 00 
  80042083f4:	b8 00 00 00 00       	mov    $0x0,%eax
  80042083f9:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004208400:	00 00 00 
  8004208403:	41 ff d0             	callq  *%r8
	assert(linebuf);
  8004208406:	48 83 bd 60 ff ff ff 	cmpq   $0x0,-0xa0(%rbp)
  800420840d:	00 
  800420840e:	75 35                	jne    8004208445 <dwarf_srclines+0xa5>
  8004208410:	48 b9 43 a1 20 04 80 	movabs $0x800420a143,%rcx
  8004208417:	00 00 00 
  800420841a:	48 ba 07 a1 20 04 80 	movabs $0x800420a107,%rdx
  8004208421:	00 00 00 
  8004208424:	be 9b 01 00 00       	mov    $0x19b,%esi
  8004208429:	48 bf 1c a1 20 04 80 	movabs $0x800420a11c,%rdi
  8004208430:	00 00 00 
  8004208433:	b8 00 00 00 00       	mov    $0x0,%eax
  8004208438:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  800420843f:	00 00 00 
  8004208442:	41 ff d0             	callq  *%r8

	memset(&li, 0, sizeof(_Dwarf_LineInfo));
  8004208445:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  800420844c:	ba 88 00 00 00       	mov    $0x88,%edx
  8004208451:	be 00 00 00 00       	mov    $0x0,%esi
  8004208456:	48 89 c7             	mov    %rax,%rdi
  8004208459:	48 b8 01 2f 20 04 80 	movabs $0x8004202f01,%rax
  8004208460:	00 00 00 
  8004208463:	ff d0                	callq  *%rax

	if ((at = _dwarf_attr_find(die, DW_AT_stmt_list)) == NULL) {
  8004208465:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420846c:	be 10 00 00 00       	mov    $0x10,%esi
  8004208471:	48 89 c7             	mov    %rax,%rdi
  8004208474:	48 b8 db 4d 20 04 80 	movabs $0x8004204ddb,%rax
  800420847b:	00 00 00 
  800420847e:	ff d0                	callq  *%rax
  8004208480:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004208484:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004208489:	75 0a                	jne    8004208495 <dwarf_srclines+0xf5>
		DWARF_SET_ERROR(dbg, error, DW_DLE_NO_ENTRY);
		return (DW_DLV_NO_ENTRY);
  800420848b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004208490:	e9 84 00 00 00       	jmpq   8004208519 <dwarf_srclines+0x179>
	}

	if (_dwarf_lineno_init(die, at->u[0].u64, &li, pc, error) !=
  8004208495:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004208499:	48 8b 70 28          	mov    0x28(%rax),%rsi
  800420849d:	48 8b bd 50 ff ff ff 	mov    -0xb0(%rbp),%rdi
  80042084a4:	48 8b 8d 58 ff ff ff 	mov    -0xa8(%rbp),%rcx
  80042084ab:	48 8d 95 70 ff ff ff 	lea    -0x90(%rbp),%rdx
  80042084b2:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042084b9:	49 89 f8             	mov    %rdi,%r8
  80042084bc:	48 89 c7             	mov    %rax,%rdi
  80042084bf:	48 b8 2f 7e 20 04 80 	movabs $0x8004207e2f,%rax
  80042084c6:	00 00 00 
  80042084c9:	ff d0                	callq  *%rax
  80042084cb:	85 c0                	test   %eax,%eax
  80042084cd:	74 07                	je     80042084d6 <dwarf_srclines+0x136>
	    DW_DLE_NONE)
	{
		return (DW_DLV_ERROR);
  80042084cf:	b8 01 00 00 00       	mov    $0x1,%eax
  80042084d4:	eb 43                	jmp    8004208519 <dwarf_srclines+0x179>
	}
	*linebuf = li.li_line;
  80042084d6:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042084dd:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042084e1:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042084e5:	48 89 01             	mov    %rax,(%rcx)
  80042084e8:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  80042084ec:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042084f0:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042084f4:	48 89 41 10          	mov    %rax,0x10(%rcx)
  80042084f8:	48 89 51 18          	mov    %rdx,0x18(%rcx)
  80042084fc:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004208500:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004208504:	48 89 41 20          	mov    %rax,0x20(%rcx)
  8004208508:	48 89 51 28          	mov    %rdx,0x28(%rcx)
  800420850c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004208510:	48 89 41 30          	mov    %rax,0x30(%rcx)

	return (DW_DLV_OK);
  8004208514:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004208519:	c9                   	leaveq 
  800420851a:	c3                   	retq   

000000800420851b <_dwarf_find_section>:
uintptr_t
read_section_headers(uintptr_t, uintptr_t);

Dwarf_Section *
_dwarf_find_section(const char *name)
{
  800420851b:	55                   	push   %rbp
  800420851c:	48 89 e5             	mov    %rsp,%rbp
  800420851f:	48 83 ec 20          	sub    $0x20,%rsp
  8004208523:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	Dwarf_Section *ret=NULL;
  8004208527:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  800420852e:	00 
	int i;

	for(i=0; i < NDEBUG_SECT; i++) {
  800420852f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004208536:	eb 57                	jmp    800420858f <_dwarf_find_section+0x74>
		if(!strcmp(section_info[i].ds_name, name)) {
  8004208538:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420853f:	00 00 00 
  8004208542:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004208545:	48 63 d2             	movslq %edx,%rdx
  8004208548:	48 c1 e2 05          	shl    $0x5,%rdx
  800420854c:	48 01 d0             	add    %rdx,%rax
  800420854f:	48 8b 00             	mov    (%rax),%rax
  8004208552:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004208556:	48 89 d6             	mov    %rdx,%rsi
  8004208559:	48 89 c7             	mov    %rax,%rdi
  800420855c:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208563:	00 00 00 
  8004208566:	ff d0                	callq  *%rax
  8004208568:	85 c0                	test   %eax,%eax
  800420856a:	75 1f                	jne    800420858b <_dwarf_find_section+0x70>
			ret = (section_info + i);
  800420856c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800420856f:	48 98                	cltq   
  8004208571:	48 c1 e0 05          	shl    $0x5,%rax
  8004208575:	48 89 c2             	mov    %rax,%rdx
  8004208578:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420857f:	00 00 00 
  8004208582:	48 01 d0             	add    %rdx,%rax
  8004208585:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
			break;
  8004208589:	eb 0a                	jmp    8004208595 <_dwarf_find_section+0x7a>
	for(i=0; i < NDEBUG_SECT; i++) {
  800420858b:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  800420858f:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  8004208593:	7e a3                	jle    8004208538 <_dwarf_find_section+0x1d>
		}
	}

	return ret;
  8004208595:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004208599:	c9                   	leaveq 
  800420859a:	c3                   	retq   

000000800420859b <find_debug_sections>:

void find_debug_sections(uintptr_t elf) 
{
  800420859b:	55                   	push   %rbp
  800420859c:	48 89 e5             	mov    %rsp,%rbp
  800420859f:	48 83 ec 40          	sub    $0x40,%rsp
  80042085a3:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
	Elf *ehdr = (Elf *)elf;
  80042085a7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042085ab:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	uintptr_t debug_address = USTABDATA;
  80042085af:	48 c7 45 f8 00 00 20 	movq   $0x200000,-0x8(%rbp)
  80042085b6:	00 
	Secthdr *sh = (Secthdr *)(((uint8_t *)ehdr + ehdr->e_shoff));
  80042085b7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042085bb:	48 8b 50 28          	mov    0x28(%rax),%rdx
  80042085bf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042085c3:	48 01 d0             	add    %rdx,%rax
  80042085c6:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	Secthdr *shstr_tab = sh + ehdr->e_shstrndx;
  80042085ca:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042085ce:	0f b7 40 3e          	movzwl 0x3e(%rax),%eax
  80042085d2:	0f b7 c0             	movzwl %ax,%eax
  80042085d5:	48 c1 e0 06          	shl    $0x6,%rax
  80042085d9:	48 89 c2             	mov    %rax,%rdx
  80042085dc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042085e0:	48 01 d0             	add    %rdx,%rax
  80042085e3:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	Secthdr* esh = sh + ehdr->e_shnum;
  80042085e7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042085eb:	0f b7 40 3c          	movzwl 0x3c(%rax),%eax
  80042085ef:	0f b7 c0             	movzwl %ax,%eax
  80042085f2:	48 c1 e0 06          	shl    $0x6,%rax
  80042085f6:	48 89 c2             	mov    %rax,%rdx
  80042085f9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042085fd:	48 01 d0             	add    %rdx,%rax
  8004208600:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	for(;sh < esh; sh++) {
  8004208604:	e9 4b 02 00 00       	jmpq   8004208854 <find_debug_sections+0x2b9>
		char* name = (char*)((uint8_t*)elf + shstr_tab->sh_offset) + sh->sh_name;
  8004208609:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420860d:	8b 00                	mov    (%rax),%eax
  800420860f:	89 c1                	mov    %eax,%ecx
  8004208611:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004208615:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208619:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420861d:	48 01 d0             	add    %rdx,%rax
  8004208620:	48 01 c8             	add    %rcx,%rax
  8004208623:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
		if(!strcmp(name, ".debug_info")) {
  8004208627:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420862b:	48 be 4b a1 20 04 80 	movabs $0x800420a14b,%rsi
  8004208632:	00 00 00 
  8004208635:	48 89 c7             	mov    %rax,%rdi
  8004208638:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  800420863f:	00 00 00 
  8004208642:	ff d0                	callq  *%rax
  8004208644:	85 c0                	test   %eax,%eax
  8004208646:	75 4b                	jne    8004208693 <find_debug_sections+0xf8>
			section_info[DEBUG_INFO].ds_data = (uint8_t*)debug_address;
  8004208648:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420864c:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208653:	00 00 00 
  8004208656:	48 89 50 08          	mov    %rdx,0x8(%rax)
			section_info[DEBUG_INFO].ds_addr = debug_address;
  800420865a:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208661:	00 00 00 
  8004208664:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208668:	48 89 50 10          	mov    %rdx,0x10(%rax)
			section_info[DEBUG_INFO].ds_size = sh->sh_size;
  800420866c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208670:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208674:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420867b:	00 00 00 
  800420867e:	48 89 50 18          	mov    %rdx,0x18(%rax)
			debug_address += sh->sh_size;
  8004208682:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208686:	48 8b 40 20          	mov    0x20(%rax),%rax
  800420868a:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  800420868e:	e9 bc 01 00 00       	jmpq   800420884f <find_debug_sections+0x2b4>
		} else if(!strcmp(name, ".debug_abbrev")) {
  8004208693:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208697:	48 be 57 a1 20 04 80 	movabs $0x800420a157,%rsi
  800420869e:	00 00 00 
  80042086a1:	48 89 c7             	mov    %rax,%rdi
  80042086a4:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  80042086ab:	00 00 00 
  80042086ae:	ff d0                	callq  *%rax
  80042086b0:	85 c0                	test   %eax,%eax
  80042086b2:	75 4b                	jne    80042086ff <find_debug_sections+0x164>
			section_info[DEBUG_ABBREV].ds_data = (uint8_t*)debug_address;
  80042086b4:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042086b8:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  80042086bf:	00 00 00 
  80042086c2:	48 89 50 28          	mov    %rdx,0x28(%rax)
			section_info[DEBUG_ABBREV].ds_addr = debug_address;
  80042086c6:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  80042086cd:	00 00 00 
  80042086d0:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042086d4:	48 89 50 30          	mov    %rdx,0x30(%rax)
			section_info[DEBUG_ABBREV].ds_size = sh->sh_size;
  80042086d8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042086dc:	48 8b 50 20          	mov    0x20(%rax),%rdx
  80042086e0:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  80042086e7:	00 00 00 
  80042086ea:	48 89 50 38          	mov    %rdx,0x38(%rax)
			debug_address += sh->sh_size;
  80042086ee:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042086f2:	48 8b 40 20          	mov    0x20(%rax),%rax
  80042086f6:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  80042086fa:	e9 50 01 00 00       	jmpq   800420884f <find_debug_sections+0x2b4>
		} else if(!strcmp(name, ".debug_line")){
  80042086ff:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208703:	48 be 6f a1 20 04 80 	movabs $0x800420a16f,%rsi
  800420870a:	00 00 00 
  800420870d:	48 89 c7             	mov    %rax,%rdi
  8004208710:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208717:	00 00 00 
  800420871a:	ff d0                	callq  *%rax
  800420871c:	85 c0                	test   %eax,%eax
  800420871e:	75 4b                	jne    800420876b <find_debug_sections+0x1d0>
			section_info[DEBUG_LINE].ds_data = (uint8_t*)debug_address;
  8004208720:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208724:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420872b:	00 00 00 
  800420872e:	48 89 50 68          	mov    %rdx,0x68(%rax)
			section_info[DEBUG_LINE].ds_addr = debug_address;
  8004208732:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208739:	00 00 00 
  800420873c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208740:	48 89 50 70          	mov    %rdx,0x70(%rax)
			section_info[DEBUG_LINE].ds_size = sh->sh_size;
  8004208744:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208748:	48 8b 50 20          	mov    0x20(%rax),%rdx
  800420874c:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208753:	00 00 00 
  8004208756:	48 89 50 78          	mov    %rdx,0x78(%rax)
			debug_address += sh->sh_size;
  800420875a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420875e:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208762:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  8004208766:	e9 e4 00 00 00       	jmpq   800420884f <find_debug_sections+0x2b4>
		} else if(!strcmp(name, ".eh_frame")){
  800420876b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420876f:	48 be 65 a1 20 04 80 	movabs $0x800420a165,%rsi
  8004208776:	00 00 00 
  8004208779:	48 89 c7             	mov    %rax,%rdi
  800420877c:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208783:	00 00 00 
  8004208786:	ff d0                	callq  *%rax
  8004208788:	85 c0                	test   %eax,%eax
  800420878a:	75 53                	jne    80042087df <find_debug_sections+0x244>
			section_info[DEBUG_FRAME].ds_data = (uint8_t*)sh->sh_addr;
  800420878c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208790:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004208794:	48 89 c2             	mov    %rax,%rdx
  8004208797:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420879e:	00 00 00 
  80042087a1:	48 89 50 48          	mov    %rdx,0x48(%rax)
			section_info[DEBUG_FRAME].ds_addr = sh->sh_addr;
  80042087a5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042087a9:	48 8b 50 10          	mov    0x10(%rax),%rdx
  80042087ad:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  80042087b4:	00 00 00 
  80042087b7:	48 89 50 50          	mov    %rdx,0x50(%rax)
			section_info[DEBUG_FRAME].ds_size = sh->sh_size;
  80042087bb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042087bf:	48 8b 50 20          	mov    0x20(%rax),%rdx
  80042087c3:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  80042087ca:	00 00 00 
  80042087cd:	48 89 50 58          	mov    %rdx,0x58(%rax)
			debug_address += sh->sh_size;
  80042087d1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042087d5:	48 8b 40 20          	mov    0x20(%rax),%rax
  80042087d9:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  80042087dd:	eb 70                	jmp    800420884f <find_debug_sections+0x2b4>
		} else if(!strcmp(name, ".debug_str")) {
  80042087df:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042087e3:	48 be 7b a1 20 04 80 	movabs $0x800420a17b,%rsi
  80042087ea:	00 00 00 
  80042087ed:	48 89 c7             	mov    %rax,%rdi
  80042087f0:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  80042087f7:	00 00 00 
  80042087fa:	ff d0                	callq  *%rax
  80042087fc:	85 c0                	test   %eax,%eax
  80042087fe:	75 4f                	jne    800420884f <find_debug_sections+0x2b4>
			section_info[DEBUG_STR].ds_data = (uint8_t*)debug_address;
  8004208800:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208804:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420880b:	00 00 00 
  800420880e:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
			section_info[DEBUG_STR].ds_addr = debug_address;
  8004208815:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420881c:	00 00 00 
  800420881f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208823:	48 89 90 90 00 00 00 	mov    %rdx,0x90(%rax)
			section_info[DEBUG_STR].ds_size = sh->sh_size;
  800420882a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420882e:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208832:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208839:	00 00 00 
  800420883c:	48 89 90 98 00 00 00 	mov    %rdx,0x98(%rax)
			debug_address += sh->sh_size;
  8004208843:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208847:	48 8b 40 20          	mov    0x20(%rax),%rax
  800420884b:	48 01 45 f8          	add    %rax,-0x8(%rbp)
	for(;sh < esh; sh++) {
  800420884f:	48 83 45 f0 40       	addq   $0x40,-0x10(%rbp)
  8004208854:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208858:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  800420885c:	0f 82 a7 fd ff ff    	jb     8004208609 <find_debug_sections+0x6e>
		}
	}

}
  8004208862:	90                   	nop
  8004208863:	c9                   	leaveq 
  8004208864:	c3                   	retq   

0000008004208865 <read_section_headers>:

uint64_t
read_section_headers(uintptr_t elfhdr, uintptr_t to_va)
{
  8004208865:	55                   	push   %rbp
  8004208866:	48 89 e5             	mov    %rsp,%rbp
  8004208869:	48 81 ec 60 01 00 00 	sub    $0x160,%rsp
  8004208870:	48 89 bd a8 fe ff ff 	mov    %rdi,-0x158(%rbp)
  8004208877:	48 89 b5 a0 fe ff ff 	mov    %rsi,-0x160(%rbp)
	Secthdr* secthdr_ptr[20] = {0};
  800420887e:	48 8d 95 c0 fe ff ff 	lea    -0x140(%rbp),%rdx
  8004208885:	b8 00 00 00 00       	mov    $0x0,%eax
  800420888a:	b9 14 00 00 00       	mov    $0x14,%ecx
  800420888f:	48 89 d7             	mov    %rdx,%rdi
  8004208892:	f3 48 ab             	rep stos %rax,%es:(%rdi)
	char* kvbase = ROUNDUP((char*)to_va, SECTSIZE);
  8004208895:	48 c7 45 e8 00 02 00 	movq   $0x200,-0x18(%rbp)
  800420889c:	00 
  800420889d:	48 8b 95 a0 fe ff ff 	mov    -0x160(%rbp),%rdx
  80042088a4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042088a8:	48 01 d0             	add    %rdx,%rax
  80042088ab:	48 83 e8 01          	sub    $0x1,%rax
  80042088af:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  80042088b3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042088b7:	ba 00 00 00 00       	mov    $0x0,%edx
  80042088bc:	48 f7 75 e8          	divq   -0x18(%rbp)
  80042088c0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042088c4:	48 29 d0             	sub    %rdx,%rax
  80042088c7:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	uint64_t kvoffset = 0;
  80042088cb:	48 c7 85 b8 fe ff ff 	movq   $0x0,-0x148(%rbp)
  80042088d2:	00 00 00 00 
	char *orig_secthdr = (char*)kvbase;
  80042088d6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042088da:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
	char * secthdr = NULL;
  80042088de:	48 c7 45 c8 00 00 00 	movq   $0x0,-0x38(%rbp)
  80042088e5:	00 
	uint64_t offset;
	if(elfhdr == KELFHDR)
  80042088e6:	48 b8 00 00 01 04 80 	movabs $0x8004010000,%rax
  80042088ed:	00 00 00 
  80042088f0:	48 39 85 a8 fe ff ff 	cmp    %rax,-0x158(%rbp)
  80042088f7:	75 11                	jne    800420890a <read_section_headers+0xa5>
		offset = ((Elf*)elfhdr)->e_shoff;
  80042088f9:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208900:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004208904:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004208908:	eb 26                	jmp    8004208930 <read_section_headers+0xcb>
	else
		offset = ((Elf*)elfhdr)->e_shoff + (elfhdr - KERNBASE);
  800420890a:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208911:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8004208915:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  800420891c:	48 01 c2             	add    %rax,%rdx
  800420891f:	48 b8 00 00 00 fc 7f 	movabs $0xffffff7ffc000000,%rax
  8004208926:	ff ff ff 
  8004208929:	48 01 d0             	add    %rdx,%rax
  800420892c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

	int numSectionHeaders = ((Elf*)elfhdr)->e_shnum;
  8004208930:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208937:	0f b7 40 3c          	movzwl 0x3c(%rax),%eax
  800420893b:	0f b7 c0             	movzwl %ax,%eax
  800420893e:	89 45 c4             	mov    %eax,-0x3c(%rbp)
	int sizeSections = ((Elf*)elfhdr)->e_shentsize;
  8004208941:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208948:	0f b7 40 3a          	movzwl 0x3a(%rax),%eax
  800420894c:	0f b7 c0             	movzwl %ax,%eax
  800420894f:	89 45 c0             	mov    %eax,-0x40(%rbp)
	char *nametab;
	int i;
	uint64_t temp;
	char *name;

	Elf *ehdr = (Elf *)elfhdr;
  8004208952:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208959:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
	Secthdr *sec_name;  

	readseg((uint64_t)orig_secthdr , numSectionHeaders * sizeSections,
  800420895d:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  8004208960:	0f af 45 c0          	imul   -0x40(%rbp),%eax
  8004208964:	48 63 f0             	movslq %eax,%rsi
  8004208967:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420896b:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208972:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208976:	48 89 c7             	mov    %rax,%rdi
  8004208979:	48 b8 be 8f 20 04 80 	movabs $0x8004208fbe,%rax
  8004208980:	00 00 00 
  8004208983:	ff d0                	callq  *%rax
		offset, &kvoffset);
	secthdr = (char*)orig_secthdr + (offset - ROUNDDOWN(offset, SECTSIZE));
  8004208985:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004208989:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
  800420898d:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004208991:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208997:	48 89 c2             	mov    %rax,%rdx
  800420899a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420899e:	48 29 d0             	sub    %rdx,%rax
  80042089a1:	48 89 c2             	mov    %rax,%rdx
  80042089a4:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042089a8:	48 01 d0             	add    %rdx,%rax
  80042089ab:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
	for (i = 0; i < numSectionHeaders; i++)
  80042089af:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  80042089b6:	eb 24                	jmp    80042089dc <read_section_headers+0x177>
	{
		secthdr_ptr[i] = (Secthdr*)(secthdr) + i;
  80042089b8:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042089bb:	48 98                	cltq   
  80042089bd:	48 c1 e0 06          	shl    $0x6,%rax
  80042089c1:	48 89 c2             	mov    %rax,%rdx
  80042089c4:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042089c8:	48 01 c2             	add    %rax,%rdx
  80042089cb:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042089ce:	48 98                	cltq   
  80042089d0:	48 89 94 c5 c0 fe ff 	mov    %rdx,-0x140(%rbp,%rax,8)
  80042089d7:	ff 
	for (i = 0; i < numSectionHeaders; i++)
  80042089d8:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  80042089dc:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042089df:	3b 45 c4             	cmp    -0x3c(%rbp),%eax
  80042089e2:	7c d4                	jl     80042089b8 <read_section_headers+0x153>
	}
	
	sec_name = secthdr_ptr[ehdr->e_shstrndx]; 
  80042089e4:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042089e8:	0f b7 40 3e          	movzwl 0x3e(%rax),%eax
  80042089ec:	0f b7 c0             	movzwl %ax,%eax
  80042089ef:	48 98                	cltq   
  80042089f1:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  80042089f8:	ff 
  80042089f9:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
	temp = kvoffset;
  80042089fd:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208a04:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
	readseg((uint64_t)((char *)kvbase + kvoffset), sec_name->sh_size,
  8004208a08:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208a0c:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208a10:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208a14:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208a18:	48 8b b5 b8 fe ff ff 	mov    -0x148(%rbp),%rsi
  8004208a1f:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004208a23:	48 01 f1             	add    %rsi,%rcx
  8004208a26:	48 89 cf             	mov    %rcx,%rdi
  8004208a29:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208a30:	48 89 c6             	mov    %rax,%rsi
  8004208a33:	48 b8 be 8f 20 04 80 	movabs $0x8004208fbe,%rax
  8004208a3a:	00 00 00 
  8004208a3d:	ff d0                	callq  *%rax
		sec_name->sh_offset, &kvoffset);
	nametab = (char *)((char *)kvbase + temp) + OFFSET_CORRECT(sec_name->sh_offset);	
  8004208a3f:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208a43:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208a47:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208a4b:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208a4f:	48 89 45 98          	mov    %rax,-0x68(%rbp)
  8004208a53:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004208a57:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208a5d:	48 29 c2             	sub    %rax,%rdx
  8004208a60:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004208a64:	48 01 c2             	add    %rax,%rdx
  8004208a67:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004208a6b:	48 01 d0             	add    %rdx,%rax
  8004208a6e:	48 89 45 90          	mov    %rax,-0x70(%rbp)

	for (i = 0; i < numSectionHeaders; i++)
  8004208a72:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004208a79:	e9 24 05 00 00       	jmpq   8004208fa2 <read_section_headers+0x73d>
	{
		name = (char *)(nametab + secthdr_ptr[i]->sh_name);
  8004208a7e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208a81:	48 98                	cltq   
  8004208a83:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208a8a:	ff 
  8004208a8b:	8b 00                	mov    (%rax),%eax
  8004208a8d:	89 c2                	mov    %eax,%edx
  8004208a8f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004208a93:	48 01 d0             	add    %rdx,%rax
  8004208a96:	48 89 45 88          	mov    %rax,-0x78(%rbp)
		assert(kvoffset % SECTSIZE == 0);
  8004208a9a:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208aa1:	25 ff 01 00 00       	and    $0x1ff,%eax
  8004208aa6:	48 85 c0             	test   %rax,%rax
  8004208aa9:	74 35                	je     8004208ae0 <read_section_headers+0x27b>
  8004208aab:	48 b9 86 a1 20 04 80 	movabs $0x800420a186,%rcx
  8004208ab2:	00 00 00 
  8004208ab5:	48 ba 9f a1 20 04 80 	movabs $0x800420a19f,%rdx
  8004208abc:	00 00 00 
  8004208abf:	be 86 00 00 00       	mov    $0x86,%esi
  8004208ac4:	48 bf b4 a1 20 04 80 	movabs $0x800420a1b4,%rdi
  8004208acb:	00 00 00 
  8004208ace:	b8 00 00 00 00       	mov    $0x0,%eax
  8004208ad3:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  8004208ada:	00 00 00 
  8004208add:	41 ff d0             	callq  *%r8
		temp = kvoffset;
  8004208ae0:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208ae7:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
#ifdef DWARF_DEBUG
		cprintf("SectName: %s\n", name);
#endif
		if(!strcmp(name, ".debug_info"))
  8004208aeb:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208aef:	48 be 4b a1 20 04 80 	movabs $0x800420a14b,%rsi
  8004208af6:	00 00 00 
  8004208af9:	48 89 c7             	mov    %rax,%rdi
  8004208afc:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208b03:	00 00 00 
  8004208b06:	ff d0                	callq  *%rax
  8004208b08:	85 c0                	test   %eax,%eax
  8004208b0a:	0f 85 e6 00 00 00    	jne    8004208bf6 <read_section_headers+0x391>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
				secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208b10:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208b13:	48 98                	cltq   
  8004208b15:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208b1c:	ff 
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208b1d:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208b21:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208b24:	48 98                	cltq   
  8004208b26:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208b2d:	ff 
  8004208b2e:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208b32:	48 8b b5 b8 fe ff ff 	mov    -0x148(%rbp),%rsi
  8004208b39:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004208b3d:	48 01 f1             	add    %rsi,%rcx
  8004208b40:	48 89 cf             	mov    %rcx,%rdi
  8004208b43:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208b4a:	48 89 c6             	mov    %rax,%rsi
  8004208b4d:	48 b8 be 8f 20 04 80 	movabs $0x8004208fbe,%rax
  8004208b54:	00 00 00 
  8004208b57:	ff d0                	callq  *%rax
			section_info[DEBUG_INFO].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208b59:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004208b5d:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004208b61:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  8004208b65:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208b68:	48 98                	cltq   
  8004208b6a:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208b71:	ff 
  8004208b72:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208b76:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208b79:	48 98                	cltq   
  8004208b7b:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208b82:	ff 
  8004208b83:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208b87:	48 89 85 68 ff ff ff 	mov    %rax,-0x98(%rbp)
  8004208b8e:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004208b95:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208b9b:	48 29 c2             	sub    %rax,%rdx
  8004208b9e:	48 89 d0             	mov    %rdx,%rax
  8004208ba1:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004208ba5:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208bac:	00 00 00 
  8004208baf:	48 89 50 08          	mov    %rdx,0x8(%rax)
			section_info[DEBUG_INFO].ds_addr = (uintptr_t)section_info[DEBUG_INFO].ds_data;
  8004208bb3:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208bba:	00 00 00 
  8004208bbd:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208bc1:	48 89 c2             	mov    %rax,%rdx
  8004208bc4:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208bcb:	00 00 00 
  8004208bce:	48 89 50 10          	mov    %rdx,0x10(%rax)
			section_info[DEBUG_INFO].ds_size = secthdr_ptr[i]->sh_size;
  8004208bd2:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208bd5:	48 98                	cltq   
  8004208bd7:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208bde:	ff 
  8004208bdf:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208be3:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208bea:	00 00 00 
  8004208bed:	48 89 50 18          	mov    %rdx,0x18(%rax)
  8004208bf1:	e9 a8 03 00 00       	jmpq   8004208f9e <read_section_headers+0x739>
		}
		else if(!strcmp(name, ".debug_abbrev"))
  8004208bf6:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208bfa:	48 be 57 a1 20 04 80 	movabs $0x800420a157,%rsi
  8004208c01:	00 00 00 
  8004208c04:	48 89 c7             	mov    %rax,%rdi
  8004208c07:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208c0e:	00 00 00 
  8004208c11:	ff d0                	callq  *%rax
  8004208c13:	85 c0                	test   %eax,%eax
  8004208c15:	0f 85 e6 00 00 00    	jne    8004208d01 <read_section_headers+0x49c>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
				secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208c1b:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c1e:	48 98                	cltq   
  8004208c20:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c27:	ff 
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208c28:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208c2c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c2f:	48 98                	cltq   
  8004208c31:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c38:	ff 
  8004208c39:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208c3d:	48 8b b5 b8 fe ff ff 	mov    -0x148(%rbp),%rsi
  8004208c44:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004208c48:	48 01 f1             	add    %rsi,%rcx
  8004208c4b:	48 89 cf             	mov    %rcx,%rdi
  8004208c4e:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208c55:	48 89 c6             	mov    %rax,%rsi
  8004208c58:	48 b8 be 8f 20 04 80 	movabs $0x8004208fbe,%rax
  8004208c5f:	00 00 00 
  8004208c62:	ff d0                	callq  *%rax
			section_info[DEBUG_ABBREV].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208c64:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004208c68:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004208c6c:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  8004208c70:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c73:	48 98                	cltq   
  8004208c75:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c7c:	ff 
  8004208c7d:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208c81:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c84:	48 98                	cltq   
  8004208c86:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c8d:	ff 
  8004208c8e:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208c92:	48 89 85 70 ff ff ff 	mov    %rax,-0x90(%rbp)
  8004208c99:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  8004208ca0:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208ca6:	48 29 c2             	sub    %rax,%rdx
  8004208ca9:	48 89 d0             	mov    %rdx,%rax
  8004208cac:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004208cb0:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208cb7:	00 00 00 
  8004208cba:	48 89 50 28          	mov    %rdx,0x28(%rax)
			section_info[DEBUG_ABBREV].ds_addr = (uintptr_t)section_info[DEBUG_ABBREV].ds_data;
  8004208cbe:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208cc5:	00 00 00 
  8004208cc8:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004208ccc:	48 89 c2             	mov    %rax,%rdx
  8004208ccf:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208cd6:	00 00 00 
  8004208cd9:	48 89 50 30          	mov    %rdx,0x30(%rax)
			section_info[DEBUG_ABBREV].ds_size = secthdr_ptr[i]->sh_size;
  8004208cdd:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208ce0:	48 98                	cltq   
  8004208ce2:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208ce9:	ff 
  8004208cea:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208cee:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208cf5:	00 00 00 
  8004208cf8:	48 89 50 38          	mov    %rdx,0x38(%rax)
  8004208cfc:	e9 9d 02 00 00       	jmpq   8004208f9e <read_section_headers+0x739>
		}
		else if(!strcmp(name, ".debug_line"))
  8004208d01:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208d05:	48 be 6f a1 20 04 80 	movabs $0x800420a16f,%rsi
  8004208d0c:	00 00 00 
  8004208d0f:	48 89 c7             	mov    %rax,%rdi
  8004208d12:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208d19:	00 00 00 
  8004208d1c:	ff d0                	callq  *%rax
  8004208d1e:	85 c0                	test   %eax,%eax
  8004208d20:	0f 85 e6 00 00 00    	jne    8004208e0c <read_section_headers+0x5a7>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
				secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208d26:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d29:	48 98                	cltq   
  8004208d2b:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d32:	ff 
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208d33:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208d37:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d3a:	48 98                	cltq   
  8004208d3c:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d43:	ff 
  8004208d44:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208d48:	48 8b b5 b8 fe ff ff 	mov    -0x148(%rbp),%rsi
  8004208d4f:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004208d53:	48 01 f1             	add    %rsi,%rcx
  8004208d56:	48 89 cf             	mov    %rcx,%rdi
  8004208d59:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208d60:	48 89 c6             	mov    %rax,%rsi
  8004208d63:	48 b8 be 8f 20 04 80 	movabs $0x8004208fbe,%rax
  8004208d6a:	00 00 00 
  8004208d6d:	ff d0                	callq  *%rax
			section_info[DEBUG_LINE].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208d6f:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004208d73:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004208d77:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  8004208d7b:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d7e:	48 98                	cltq   
  8004208d80:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d87:	ff 
  8004208d88:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208d8c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d8f:	48 98                	cltq   
  8004208d91:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d98:	ff 
  8004208d99:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208d9d:	48 89 85 78 ff ff ff 	mov    %rax,-0x88(%rbp)
  8004208da4:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
  8004208dab:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208db1:	48 29 c2             	sub    %rax,%rdx
  8004208db4:	48 89 d0             	mov    %rdx,%rax
  8004208db7:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004208dbb:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208dc2:	00 00 00 
  8004208dc5:	48 89 50 68          	mov    %rdx,0x68(%rax)
			section_info[DEBUG_LINE].ds_addr = (uintptr_t)section_info[DEBUG_LINE].ds_data;
  8004208dc9:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208dd0:	00 00 00 
  8004208dd3:	48 8b 40 68          	mov    0x68(%rax),%rax
  8004208dd7:	48 89 c2             	mov    %rax,%rdx
  8004208dda:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208de1:	00 00 00 
  8004208de4:	48 89 50 70          	mov    %rdx,0x70(%rax)
			section_info[DEBUG_LINE].ds_size = secthdr_ptr[i]->sh_size;
  8004208de8:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208deb:	48 98                	cltq   
  8004208ded:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208df4:	ff 
  8004208df5:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208df9:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208e00:	00 00 00 
  8004208e03:	48 89 50 78          	mov    %rdx,0x78(%rax)
  8004208e07:	e9 92 01 00 00       	jmpq   8004208f9e <read_section_headers+0x739>
		}
		else if(!strcmp(name, ".eh_frame"))
  8004208e0c:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208e10:	48 be 65 a1 20 04 80 	movabs $0x800420a165,%rsi
  8004208e17:	00 00 00 
  8004208e1a:	48 89 c7             	mov    %rax,%rdi
  8004208e1d:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208e24:	00 00 00 
  8004208e27:	ff d0                	callq  *%rax
  8004208e29:	85 c0                	test   %eax,%eax
  8004208e2b:	75 65                	jne    8004208e92 <read_section_headers+0x62d>
		{
			section_info[DEBUG_FRAME].ds_data = (uint8_t *)secthdr_ptr[i]->sh_addr;
  8004208e2d:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208e30:	48 98                	cltq   
  8004208e32:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208e39:	ff 
  8004208e3a:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004208e3e:	48 89 c2             	mov    %rax,%rdx
  8004208e41:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208e48:	00 00 00 
  8004208e4b:	48 89 50 48          	mov    %rdx,0x48(%rax)
			section_info[DEBUG_FRAME].ds_addr = (uintptr_t)section_info[DEBUG_FRAME].ds_data;
  8004208e4f:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208e56:	00 00 00 
  8004208e59:	48 8b 40 48          	mov    0x48(%rax),%rax
  8004208e5d:	48 89 c2             	mov    %rax,%rdx
  8004208e60:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208e67:	00 00 00 
  8004208e6a:	48 89 50 50          	mov    %rdx,0x50(%rax)
			section_info[DEBUG_FRAME].ds_size = secthdr_ptr[i]->sh_size;
  8004208e6e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208e71:	48 98                	cltq   
  8004208e73:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208e7a:	ff 
  8004208e7b:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208e7f:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208e86:	00 00 00 
  8004208e89:	48 89 50 58          	mov    %rdx,0x58(%rax)
  8004208e8d:	e9 0c 01 00 00       	jmpq   8004208f9e <read_section_headers+0x739>
		}
		else if(!strcmp(name, ".debug_str"))
  8004208e92:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208e96:	48 be 7b a1 20 04 80 	movabs $0x800420a17b,%rsi
  8004208e9d:	00 00 00 
  8004208ea0:	48 89 c7             	mov    %rax,%rdi
  8004208ea3:	48 b8 c9 2d 20 04 80 	movabs $0x8004202dc9,%rax
  8004208eaa:	00 00 00 
  8004208ead:	ff d0                	callq  *%rax
  8004208eaf:	85 c0                	test   %eax,%eax
  8004208eb1:	0f 85 e7 00 00 00    	jne    8004208f9e <read_section_headers+0x739>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
				secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208eb7:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208eba:	48 98                	cltq   
  8004208ebc:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208ec3:	ff 
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208ec4:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208ec8:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208ecb:	48 98                	cltq   
  8004208ecd:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208ed4:	ff 
  8004208ed5:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208ed9:	48 8b b5 b8 fe ff ff 	mov    -0x148(%rbp),%rsi
  8004208ee0:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004208ee4:	48 01 f1             	add    %rsi,%rcx
  8004208ee7:	48 89 cf             	mov    %rcx,%rdi
  8004208eea:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208ef1:	48 89 c6             	mov    %rax,%rsi
  8004208ef4:	48 b8 be 8f 20 04 80 	movabs $0x8004208fbe,%rax
  8004208efb:	00 00 00 
  8004208efe:	ff d0                	callq  *%rax
			section_info[DEBUG_STR].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208f00:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004208f04:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004208f08:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  8004208f0c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f0f:	48 98                	cltq   
  8004208f11:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f18:	ff 
  8004208f19:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208f1d:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f20:	48 98                	cltq   
  8004208f22:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f29:	ff 
  8004208f2a:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208f2e:	48 89 45 80          	mov    %rax,-0x80(%rbp)
  8004208f32:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  8004208f36:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208f3c:	48 29 c2             	sub    %rax,%rdx
  8004208f3f:	48 89 d0             	mov    %rdx,%rax
  8004208f42:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004208f46:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208f4d:	00 00 00 
  8004208f50:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
			section_info[DEBUG_STR].ds_addr = (uintptr_t)section_info[DEBUG_STR].ds_data;
  8004208f57:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208f5e:	00 00 00 
  8004208f61:	48 8b 80 88 00 00 00 	mov    0x88(%rax),%rax
  8004208f68:	48 89 c2             	mov    %rax,%rdx
  8004208f6b:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208f72:	00 00 00 
  8004208f75:	48 89 90 90 00 00 00 	mov    %rdx,0x90(%rax)
			section_info[DEBUG_STR].ds_size = secthdr_ptr[i]->sh_size;
  8004208f7c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f7f:	48 98                	cltq   
  8004208f81:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f88:	ff 
  8004208f89:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208f8d:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  8004208f94:	00 00 00 
  8004208f97:	48 89 90 98 00 00 00 	mov    %rdx,0x98(%rax)
	for (i = 0; i < numSectionHeaders; i++)
  8004208f9e:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  8004208fa2:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208fa5:	3b 45 c4             	cmp    -0x3c(%rbp),%eax
  8004208fa8:	0f 8c d0 fa ff ff    	jl     8004208a7e <read_section_headers+0x219>
		}
	}
	
	return ((uintptr_t)kvbase + kvoffset);
  8004208fae:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004208fb2:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208fb9:	48 01 d0             	add    %rdx,%rax
}
  8004208fbc:	c9                   	leaveq 
  8004208fbd:	c3                   	retq   

0000008004208fbe <readseg>:

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint64_t pa, uint64_t count, uint64_t offset, uint64_t* kvoffset)
{
  8004208fbe:	55                   	push   %rbp
  8004208fbf:	48 89 e5             	mov    %rsp,%rbp
  8004208fc2:	48 83 ec 30          	sub    $0x30,%rsp
  8004208fc6:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004208fca:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004208fce:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004208fd2:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
	uint64_t end_pa;
	uint64_t orgoff = offset;
  8004208fd6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004208fda:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

	end_pa = pa + count;
  8004208fde:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004208fe2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004208fe6:	48 01 d0             	add    %rdx,%rax
  8004208fe9:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	assert(pa % SECTSIZE == 0);	
  8004208fed:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004208ff1:	25 ff 01 00 00       	and    $0x1ff,%eax
  8004208ff6:	48 85 c0             	test   %rax,%rax
  8004208ff9:	74 35                	je     8004209030 <readseg+0x72>
  8004208ffb:	48 b9 c2 a1 20 04 80 	movabs $0x800420a1c2,%rcx
  8004209002:	00 00 00 
  8004209005:	48 ba 9f a1 20 04 80 	movabs $0x800420a19f,%rdx
  800420900c:	00 00 00 
  800420900f:	be c0 00 00 00       	mov    $0xc0,%esi
  8004209014:	48 bf b4 a1 20 04 80 	movabs $0x800420a1b4,%rdi
  800420901b:	00 00 00 
  800420901e:	b8 00 00 00 00       	mov    $0x0,%eax
  8004209023:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  800420902a:	00 00 00 
  800420902d:	41 ff d0             	callq  *%r8
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);
  8004209030:	48 81 65 e8 00 fe ff 	andq   $0xfffffffffffffe00,-0x18(%rbp)
  8004209037:	ff 

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
  8004209038:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420903c:	48 c1 e8 09          	shr    $0x9,%rax
  8004209040:	48 83 c0 01          	add    $0x1,%rax
  8004209044:	48 89 45 d8          	mov    %rax,-0x28(%rbp)

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
  8004209048:	eb 3c                	jmp    8004209086 <readseg+0xc8>
		readsect((uint8_t*) pa, offset);
  800420904a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420904e:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004209052:	48 89 d6             	mov    %rdx,%rsi
  8004209055:	48 89 c7             	mov    %rax,%rdi
  8004209058:	48 b8 50 91 20 04 80 	movabs $0x8004209150,%rax
  800420905f:	00 00 00 
  8004209062:	ff d0                	callq  *%rax
		pa += SECTSIZE;
  8004209064:	48 81 45 e8 00 02 00 	addq   $0x200,-0x18(%rbp)
  800420906b:	00 
		*kvoffset += SECTSIZE;
  800420906c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004209070:	48 8b 00             	mov    (%rax),%rax
  8004209073:	48 8d 90 00 02 00 00 	lea    0x200(%rax),%rdx
  800420907a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420907e:	48 89 10             	mov    %rdx,(%rax)
		offset++;
  8004209081:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
	while (pa < end_pa) {
  8004209086:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420908a:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  800420908e:	72 ba                	jb     800420904a <readseg+0x8c>
	}

	if(((orgoff % SECTSIZE) + count) > SECTSIZE)
  8004209090:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004209094:	25 ff 01 00 00       	and    $0x1ff,%eax
  8004209099:	48 89 c2             	mov    %rax,%rdx
  800420909c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042090a0:	48 01 d0             	add    %rdx,%rax
  80042090a3:	48 3d 00 02 00 00    	cmp    $0x200,%rax
  80042090a9:	76 2f                	jbe    80042090da <readseg+0x11c>
	{
		readsect((uint8_t*) pa, offset);
  80042090ab:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042090af:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80042090b3:	48 89 d6             	mov    %rdx,%rsi
  80042090b6:	48 89 c7             	mov    %rax,%rdi
  80042090b9:	48 b8 50 91 20 04 80 	movabs $0x8004209150,%rax
  80042090c0:	00 00 00 
  80042090c3:	ff d0                	callq  *%rax
		*kvoffset += SECTSIZE;
  80042090c5:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042090c9:	48 8b 00             	mov    (%rax),%rax
  80042090cc:	48 8d 90 00 02 00 00 	lea    0x200(%rax),%rdx
  80042090d3:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042090d7:	48 89 10             	mov    %rdx,(%rax)
	}
	assert(*kvoffset % SECTSIZE == 0);
  80042090da:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042090de:	48 8b 00             	mov    (%rax),%rax
  80042090e1:	25 ff 01 00 00       	and    $0x1ff,%eax
  80042090e6:	48 85 c0             	test   %rax,%rax
  80042090e9:	74 35                	je     8004209120 <readseg+0x162>
  80042090eb:	48 b9 d5 a1 20 04 80 	movabs $0x800420a1d5,%rcx
  80042090f2:	00 00 00 
  80042090f5:	48 ba 9f a1 20 04 80 	movabs $0x800420a19f,%rdx
  80042090fc:	00 00 00 
  80042090ff:	be d6 00 00 00       	mov    $0xd6,%esi
  8004209104:	48 bf b4 a1 20 04 80 	movabs $0x800420a1b4,%rdi
  800420910b:	00 00 00 
  800420910e:	b8 00 00 00 00       	mov    $0x0,%eax
  8004209113:	49 b8 9c 01 20 04 80 	movabs $0x800420019c,%r8
  800420911a:	00 00 00 
  800420911d:	41 ff d0             	callq  *%r8
}
  8004209120:	90                   	nop
  8004209121:	c9                   	leaveq 
  8004209122:	c3                   	retq   

0000008004209123 <waitdisk>:

void
waitdisk(void)
{
  8004209123:	55                   	push   %rbp
  8004209124:	48 89 e5             	mov    %rsp,%rbp
  8004209127:	48 83 ec 10          	sub    $0x10,%rsp
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
  800420912b:	90                   	nop
  800420912c:	c7 45 fc f7 01 00 00 	movl   $0x1f7,-0x4(%rbp)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004209133:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004209136:	89 c2                	mov    %eax,%edx
  8004209138:	ec                   	in     (%dx),%al
  8004209139:	88 45 fb             	mov    %al,-0x5(%rbp)
	return data;
  800420913c:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8004209140:	0f b6 c0             	movzbl %al,%eax
  8004209143:	25 c0 00 00 00       	and    $0xc0,%eax
  8004209148:	83 f8 40             	cmp    $0x40,%eax
  800420914b:	75 df                	jne    800420912c <waitdisk+0x9>
		/* do nothing */;
}
  800420914d:	90                   	nop
  800420914e:	c9                   	leaveq 
  800420914f:	c3                   	retq   

0000008004209150 <readsect>:

void
readsect(void *dst, uint64_t offset)
{
  8004209150:	55                   	push   %rbp
  8004209151:	48 89 e5             	mov    %rsp,%rbp
  8004209154:	48 83 ec 60          	sub    $0x60,%rsp
  8004209158:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  800420915c:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
	// wait for disk to be ready
	waitdisk();
  8004209160:	48 b8 23 91 20 04 80 	movabs $0x8004209123,%rax
  8004209167:	00 00 00 
  800420916a:	ff d0                	callq  *%rax
  800420916c:	c7 45 c0 f2 01 00 00 	movl   $0x1f2,-0x40(%rbp)
  8004209173:	c6 45 bf 01          	movb   $0x1,-0x41(%rbp)
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004209177:	0f b6 45 bf          	movzbl -0x41(%rbp),%eax
  800420917b:	8b 55 c0             	mov    -0x40(%rbp),%edx
  800420917e:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
  800420917f:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004209183:	0f b6 c0             	movzbl %al,%eax
  8004209186:	c7 45 c8 f3 01 00 00 	movl   $0x1f3,-0x38(%rbp)
  800420918d:	88 45 c7             	mov    %al,-0x39(%rbp)
  8004209190:	0f b6 45 c7          	movzbl -0x39(%rbp),%eax
  8004209194:	8b 55 c8             	mov    -0x38(%rbp),%edx
  8004209197:	ee                   	out    %al,(%dx)
	outb(0x1F4, offset >> 8);
  8004209198:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420919c:	48 c1 e8 08          	shr    $0x8,%rax
  80042091a0:	0f b6 c0             	movzbl %al,%eax
  80042091a3:	c7 45 d0 f4 01 00 00 	movl   $0x1f4,-0x30(%rbp)
  80042091aa:	88 45 cf             	mov    %al,-0x31(%rbp)
  80042091ad:	0f b6 45 cf          	movzbl -0x31(%rbp),%eax
  80042091b1:	8b 55 d0             	mov    -0x30(%rbp),%edx
  80042091b4:	ee                   	out    %al,(%dx)
	outb(0x1F5, offset >> 16);
  80042091b5:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042091b9:	48 c1 e8 10          	shr    $0x10,%rax
  80042091bd:	0f b6 c0             	movzbl %al,%eax
  80042091c0:	c7 45 d8 f5 01 00 00 	movl   $0x1f5,-0x28(%rbp)
  80042091c7:	88 45 d7             	mov    %al,-0x29(%rbp)
  80042091ca:	0f b6 45 d7          	movzbl -0x29(%rbp),%eax
  80042091ce:	8b 55 d8             	mov    -0x28(%rbp),%edx
  80042091d1:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
  80042091d2:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042091d6:	48 c1 e8 18          	shr    $0x18,%rax
  80042091da:	83 c8 e0             	or     $0xffffffe0,%eax
  80042091dd:	0f b6 c0             	movzbl %al,%eax
  80042091e0:	c7 45 e0 f6 01 00 00 	movl   $0x1f6,-0x20(%rbp)
  80042091e7:	88 45 df             	mov    %al,-0x21(%rbp)
  80042091ea:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  80042091ee:	8b 55 e0             	mov    -0x20(%rbp),%edx
  80042091f1:	ee                   	out    %al,(%dx)
  80042091f2:	c7 45 e8 f7 01 00 00 	movl   $0x1f7,-0x18(%rbp)
  80042091f9:	c6 45 e7 20          	movb   $0x20,-0x19(%rbp)
  80042091fd:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004209201:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8004209204:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();
  8004209205:	48 b8 23 91 20 04 80 	movabs $0x8004209123,%rax
  800420920c:	00 00 00 
  800420920f:	ff d0                	callq  *%rax
  8004209211:	c7 45 fc f0 01 00 00 	movl   $0x1f0,-0x4(%rbp)
  8004209218:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420921c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8004209220:	c7 45 ec 80 00 00 00 	movl   $0x80,-0x14(%rbp)
	__asm __volatile("cld\n\trepne\n\tinsl"			:
  8004209227:	8b 55 fc             	mov    -0x4(%rbp),%edx
  800420922a:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  800420922e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004209231:	48 89 ce             	mov    %rcx,%rsi
  8004209234:	48 89 f7             	mov    %rsi,%rdi
  8004209237:	89 c1                	mov    %eax,%ecx
  8004209239:	fc                   	cld    
  800420923a:	f2 6d                	repnz insl (%dx),%es:(%rdi)
  800420923c:	89 c8                	mov    %ecx,%eax
  800420923e:	48 89 fe             	mov    %rdi,%rsi
  8004209241:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8004209245:	89 45 ec             	mov    %eax,-0x14(%rbp)

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
  8004209248:	90                   	nop
  8004209249:	c9                   	leaveq 
  800420924a:	c3                   	retq   
