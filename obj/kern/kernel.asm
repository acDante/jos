
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f0100055:	e8 34 09 00 00       	call   f010098e <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 3d 08 00 00       	call   f01008c4 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 fc 19 10 f0 	movl   $0xf01019fc,(%esp)
f0100092:	e8 f7 08 00 00       	call   f010098e <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 01 14 00 00       	call   f01014c6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 92 04 00 00       	call   f010055c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 17 1a 10 f0 	movl   $0xf0101a17,(%esp)
f01000d9:	e8 b0 08 00 00       	call   f010098e <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 80 06 00 00       	call   f0100776 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 32 1a 10 f0 	movl   $0xf0101a32,(%esp)
f010012c:	e8 5d 08 00 00       	call   f010098e <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 1e 08 00 00       	call   f010095b <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f0100144:	e8 45 08 00 00       	call   f010098e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 21 06 00 00       	call   f0100776 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 4a 1a 10 f0 	movl   $0xf0101a4a,(%esp)
f0100176:	e8 13 08 00 00       	call   f010098e <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 d1 07 00 00       	call   f010095b <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f0100191:	e8 f8 07 00 00       	call   f010098e <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01001df:	88 82 40 23 11 f0    	mov    %al,-0xfeedcc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 25 11 f0       	mov    %eax,0xf0112544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100217:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100218:	a8 20                	test   $0x20,%al
f010021a:	75 1b                	jne    f0100237 <cons_putc+0x30>
f010021c:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100221:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100226:	e8 75 ff ff ff       	call   f01001a0 <delay>
f010022b:	89 f2                	mov    %esi,%edx
f010022d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010022e:	a8 20                	test   $0x20,%al
f0100230:	75 05                	jne    f0100237 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100232:	83 eb 01             	sub    $0x1,%ebx
f0100235:	75 ef                	jne    f0100226 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010026f:	ee                   	out    %al,(%dx)
f0100270:	b2 7a                	mov    $0x7a,%dl
f0100272:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100277:	ee                   	out    %al,(%dx)
f0100278:	b8 08 00 00 00       	mov    $0x8,%eax
f010027d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010027e:	89 fa                	mov    %edi,%edx
f0100280:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100286:	89 f8                	mov    %edi,%eax
f0100288:	80 cc 07             	or     $0x7,%ah
f010028b:	85 d2                	test   %edx,%edx
f010028d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100290:	89 f8                	mov    %edi,%eax
f0100292:	25 ff 00 00 00       	and    $0xff,%eax
f0100297:	83 f8 09             	cmp    $0x9,%eax
f010029a:	74 7c                	je     f0100318 <cons_putc+0x111>
f010029c:	83 f8 09             	cmp    $0x9,%eax
f010029f:	7f 0b                	jg     f01002ac <cons_putc+0xa5>
f01002a1:	83 f8 08             	cmp    $0x8,%eax
f01002a4:	0f 85 a2 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002aa:	eb 16                	jmp    f01002c2 <cons_putc+0xbb>
f01002ac:	83 f8 0a             	cmp    $0xa,%eax
f01002af:	90                   	nop
f01002b0:	74 40                	je     f01002f2 <cons_putc+0xeb>
f01002b2:	83 f8 0d             	cmp    $0xd,%eax
f01002b5:	0f 85 91 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002bb:	90                   	nop
f01002bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002c0:	eb 38                	jmp    f01002fa <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e4 00 00 00    	je     f01003b6 <cons_putc+0x1af>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	66 81 e7 00 ff       	and    $0xff00,%di
f01002e3:	83 cf 20             	or     $0x20,%edi
f01002e6:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f01002ec:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f0:	eb 77                	jmp    f0100369 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f2:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f01002f9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fa:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100301:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100307:	c1 e8 16             	shr    $0x16,%eax
f010030a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030d:	c1 e0 04             	shl    $0x4,%eax
f0100310:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
f0100316:	eb 51                	jmp    f0100369 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f0100318:	b8 20 00 00 00       	mov    $0x20,%eax
f010031d:	e8 e5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100322:	b8 20 00 00 00       	mov    $0x20,%eax
f0100327:	e8 db fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010032c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100331:	e8 d1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100336:	b8 20 00 00 00       	mov    $0x20,%eax
f010033b:	e8 c7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100340:	b8 20 00 00 00       	mov    $0x20,%eax
f0100345:	e8 bd fe ff ff       	call   f0100207 <cons_putc>
f010034a:	eb 1d                	jmp    f0100369 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034c:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100353:	0f b7 c8             	movzwl %ax,%ecx
f0100356:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f010035c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100360:	83 c0 01             	add    $0x1,%eax
f0100363:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100369:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f0100370:	cf 07 
f0100372:	76 42                	jbe    f01003b6 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 将屏幕第二行到最后一行的内容往上移动一行， 原先第一行内容将被覆盖
f0100374:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f0100379:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100380:	00 
f0100381:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100387:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038b:	89 04 24             	mov    %eax,(%esp)
f010038e:	e8 8e 11 00 00       	call   f0101521 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' '; // 最后一行清0
f0100393:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 将屏幕第二行到最后一行的内容往上移动一行， 原先第一行内容将被覆盖
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100399:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' '; // 最后一行清0
f010039e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 将屏幕第二行到最后一行的内容往上移动一行， 原先第一行内容将被覆盖
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a4:	83 c0 01             	add    $0x1,%eax
f01003a7:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ac:	75 f0                	jne    f010039e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' '; // 最后一行清0
		crt_pos -= CRT_COLS;  // 将光标移动到最后一行开头
f01003ae:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f01003b5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b6:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003bc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c1:	89 ca                	mov    %ecx,%edx
f01003c3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c4:	0f b7 35 54 25 11 f0 	movzwl 0xf0112554,%esi
f01003cb:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003ce:	89 f0                	mov    %esi,%eax
f01003d0:	66 c1 e8 08          	shr    $0x8,%ax
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	ee                   	out    %al,(%dx)
f01003d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dc:	89 ca                	mov    %ecx,%edx
f01003de:	ee                   	out    %al,(%dx)
f01003df:	89 f0                	mov    %esi,%eax
f01003e1:	89 da                	mov    %ebx,%edx
f01003e3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e4:	83 c4 2c             	add    $0x2c,%esp
f01003e7:	5b                   	pop    %ebx
f01003e8:	5e                   	pop    %esi
f01003e9:	5f                   	pop    %edi
f01003ea:	5d                   	pop    %ebp
f01003eb:	c3                   	ret    

f01003ec <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ec:	55                   	push   %ebp
f01003ed:	89 e5                	mov    %esp,%ebp
f01003ef:	53                   	push   %ebx
f01003f0:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003f9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fe:	a8 01                	test   $0x1,%al
f0100400:	0f 84 de 00 00 00    	je     f01004e4 <kbd_proc_data+0xf8>
f0100406:	b2 60                	mov    $0x60,%dl
f0100408:	ec                   	in     (%dx),%al
f0100409:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010040b:	3c e0                	cmp    $0xe0,%al
f010040d:	75 11                	jne    f0100420 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010040f:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f0100416:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041b:	e9 c4 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 37                	jns    f010045b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f010042a:	89 cb                	mov    %ecx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	83 e0 7f             	and    $0x7f,%eax
f0100432:	85 db                	test   %ebx,%ebx
f0100434:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100437:	0f b6 d2             	movzbl %dl,%edx
f010043a:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f0100441:	83 c8 40             	or     $0x40,%eax
f0100444:	0f b6 c0             	movzbl %al,%eax
f0100447:	f7 d0                	not    %eax
f0100449:	21 c1                	and    %eax,%ecx
f010044b:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f0100451:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100456:	e9 89 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010045b:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100461:	f6 c1 40             	test   $0x40,%cl
f0100464:	74 0e                	je     f0100474 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100466:	89 c2                	mov    %eax,%edx
f0100468:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010046b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046e:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f0100474:	0f b6 d2             	movzbl %dl,%edx
f0100477:	0f b6 82 a0 1a 10 f0 	movzbl -0xfefe560(%edx),%eax
f010047e:	0b 05 48 25 11 f0    	or     0xf0112548,%eax
	shift ^= togglecode[data];
f0100484:	0f b6 8a a0 1b 10 f0 	movzbl -0xfefe460(%edx),%ecx
f010048b:	31 c8                	xor    %ecx,%eax
f010048d:	a3 48 25 11 f0       	mov    %eax,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100492:	89 c1                	mov    %eax,%ecx
f0100494:	83 e1 03             	and    $0x3,%ecx
f0100497:	8b 0c 8d a0 1c 10 f0 	mov    -0xfefe360(,%ecx,4),%ecx
f010049e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004a2:	a8 08                	test   $0x8,%al
f01004a4:	74 19                	je     f01004bf <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a6:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004a9:	83 fa 19             	cmp    $0x19,%edx
f01004ac:	77 05                	ja     f01004b3 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004ae:	83 eb 20             	sub    $0x20,%ebx
f01004b1:	eb 0c                	jmp    f01004bf <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b3:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004b6:	8d 53 20             	lea    0x20(%ebx),%edx
f01004b9:	83 f9 19             	cmp    $0x19,%ecx
f01004bc:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004bf:	f7 d0                	not    %eax
f01004c1:	a8 06                	test   $0x6,%al
f01004c3:	75 1f                	jne    f01004e4 <kbd_proc_data+0xf8>
f01004c5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cb:	75 17                	jne    f01004e4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004cd:	c7 04 24 64 1a 10 f0 	movl   $0xf0101a64,(%esp)
f01004d4:	e8 b5 04 00 00       	call   f010098e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004de:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004e4:	89 d8                	mov    %ebx,%eax
f01004e6:	83 c4 14             	add    $0x14,%esp
f01004e9:	5b                   	pop    %ebx
f01004ea:	5d                   	pop    %ebp
f01004eb:	c3                   	ret    

f01004ec <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ec:	55                   	push   %ebp
f01004ed:	89 e5                	mov    %esp,%ebp
f01004ef:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004f2:	83 3d 20 23 11 f0 00 	cmpl   $0x0,0xf0112320
f01004f9:	74 0a                	je     f0100505 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004fb:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100500:	e8 c5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050d:	b8 ec 03 10 f0       	mov    $0xf01003ec,%eax
f0100512:	e8 b3 fc ff ff       	call   f01001ca <cons_intr>
}
f0100517:	c9                   	leave  
f0100518:	c3                   	ret    

f0100519 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100519:	55                   	push   %ebp
f010051a:	89 e5                	mov    %esp,%ebp
f010051c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051f:	e8 c8 ff ff ff       	call   f01004ec <serial_intr>
	kbd_intr();
f0100524:	e8 de ff ff ff       	call   f0100507 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100529:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010052f:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100534:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f010053a:	74 1e                	je     f010055a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053c:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100543:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100546:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100551:	0f 44 d1             	cmove  %ecx,%edx
f0100554:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f010055a:	c9                   	leave  
f010055b:	c3                   	ret    

f010055c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055c:	55                   	push   %ebp
f010055d:	89 e5                	mov    %esp,%ebp
f010055f:	57                   	push   %edi
f0100560:	56                   	push   %esi
f0100561:	53                   	push   %ebx
f0100562:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100565:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100573:	5a a5 
	if (*cp != 0xA55A) {
f0100575:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100580:	74 11                	je     f0100593 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100582:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
f0100589:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100591:	eb 16                	jmp    f01005a9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100593:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059a:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
f01005a1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a9:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01005af:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b4:	89 ca                	mov    %ecx,%edx
f01005b6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b7:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ba:	89 da                	mov    %ebx,%edx
f01005bc:	ec                   	in     (%dx),%al
f01005bd:	0f b6 f8             	movzbl %al,%edi
f01005c0:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c8:	89 ca                	mov    %ecx,%edx
f01005ca:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cb:	89 da                	mov    %ebx,%edx
f01005cd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ce:	89 35 50 25 11 f0    	mov    %esi,0xf0112550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d4:	0f b6 d8             	movzbl %al,%ebx
f01005d7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d9:	66 89 3d 54 25 11 f0 	mov    %di,0xf0112554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 fb                	mov    $0xfb,%dl
f01005ef:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005fa:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 f9                	mov    $0xf9,%dl
f0100604:	b8 00 00 00 00       	mov    $0x0,%eax
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 fb                	mov    $0xfb,%dl
f010060c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 fc                	mov    $0xfc,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 f9                	mov    $0xf9,%dl
f010061c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100621:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100622:	b2 fd                	mov    $0xfd,%dl
f0100624:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100625:	3c ff                	cmp    $0xff,%al
f0100627:	0f 95 c0             	setne  %al
f010062a:	0f b6 c0             	movzbl %al,%eax
f010062d:	89 c6                	mov    %eax,%esi
f010062f:	a3 20 23 11 f0       	mov    %eax,0xf0112320
f0100634:	89 da                	mov    %ebx,%edx
f0100636:	ec                   	in     (%dx),%al
f0100637:	89 ca                	mov    %ecx,%edx
f0100639:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063a:	85 f6                	test   %esi,%esi
f010063c:	75 0c                	jne    f010064a <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f010063e:	c7 04 24 70 1a 10 f0 	movl   $0xf0101a70,(%esp)
f0100645:	e8 44 03 00 00       	call   f010098e <cprintf>
}
f010064a:	83 c4 1c             	add    $0x1c,%esp
f010064d:	5b                   	pop    %ebx
f010064e:	5e                   	pop    %esi
f010064f:	5f                   	pop    %edi
f0100650:	5d                   	pop    %ebp
f0100651:	c3                   	ret    

f0100652 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100652:	55                   	push   %ebp
f0100653:	89 e5                	mov    %esp,%ebp
f0100655:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100658:	8b 45 08             	mov    0x8(%ebp),%eax
f010065b:	e8 a7 fb ff ff       	call   f0100207 <cons_putc>
}
f0100660:	c9                   	leave  
f0100661:	c3                   	ret    

f0100662 <getchar>:

int
getchar(void)
{
f0100662:	55                   	push   %ebp
f0100663:	89 e5                	mov    %esp,%ebp
f0100665:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100668:	e8 ac fe ff ff       	call   f0100519 <cons_getc>
f010066d:	85 c0                	test   %eax,%eax
f010066f:	74 f7                	je     f0100668 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100671:	c9                   	leave  
f0100672:	c3                   	ret    

f0100673 <iscons>:

int
iscons(int fdnum)
{
f0100673:	55                   	push   %ebp
f0100674:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100676:	b8 01 00 00 00       	mov    $0x1,%eax
f010067b:	5d                   	pop    %ebp
f010067c:	c3                   	ret    
f010067d:	00 00                	add    %al,(%eax)
	...

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 b0 1c 10 f0 	movl   $0xf0101cb0,(%esp)
f010068d:	e8 fc 02 00 00       	call   f010098e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100692:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100699:	00 
f010069a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006a1:	f0 
f01006a2:	c7 04 24 68 1d 10 f0 	movl   $0xf0101d68,(%esp)
f01006a9:	e8 e0 02 00 00       	call   f010098e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ae:	c7 44 24 08 c5 19 10 	movl   $0x1019c5,0x8(%esp)
f01006b5:	00 
f01006b6:	c7 44 24 04 c5 19 10 	movl   $0xf01019c5,0x4(%esp)
f01006bd:	f0 
f01006be:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f01006c5:	e8 c4 02 00 00       	call   f010098e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006d1:	00 
f01006d2:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006d9:	f0 
f01006da:	c7 04 24 b0 1d 10 f0 	movl   $0xf0101db0,(%esp)
f01006e1:	e8 a8 02 00 00       	call   f010098e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e6:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f01006ed:	00 
f01006ee:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f01006f5:	f0 
f01006f6:	c7 04 24 d4 1d 10 f0 	movl   $0xf0101dd4,(%esp)
f01006fd:	e8 8c 02 00 00       	call   f010098e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100702:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100707:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010070c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100712:	85 c0                	test   %eax,%eax
f0100714:	0f 48 c2             	cmovs  %edx,%eax
f0100717:	c1 f8 0a             	sar    $0xa,%eax
f010071a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071e:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f0100725:	e8 64 02 00 00       	call   f010098e <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100737:	c7 44 24 08 c9 1c 10 	movl   $0xf0101cc9,0x8(%esp)
f010073e:	f0 
f010073f:	c7 44 24 04 e7 1c 10 	movl   $0xf0101ce7,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 ec 1c 10 f0 	movl   $0xf0101cec,(%esp)
f010074e:	e8 3b 02 00 00       	call   f010098e <cprintf>
f0100753:	c7 44 24 08 24 1e 10 	movl   $0xf0101e24,0x8(%esp)
f010075a:	f0 
f010075b:	c7 44 24 04 f5 1c 10 	movl   $0xf0101cf5,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 ec 1c 10 f0 	movl   $0xf0101cec,(%esp)
f010076a:	e8 1f 02 00 00       	call   f010098e <cprintf>
	return 0;
}
f010076f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100774:	c9                   	leave  
f0100775:	c3                   	ret    

f0100776 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100776:	55                   	push   %ebp
f0100777:	89 e5                	mov    %esp,%ebp
f0100779:	57                   	push   %edi
f010077a:	56                   	push   %esi
f010077b:	53                   	push   %ebx
f010077c:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010077f:	c7 04 24 4c 1e 10 f0 	movl   $0xf0101e4c,(%esp)
f0100786:	e8 03 02 00 00       	call   f010098e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010078b:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f0100792:	e8 f7 01 00 00       	call   f010098e <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100797:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f010079a:	c7 04 24 fe 1c 10 f0 	movl   $0xf0101cfe,(%esp)
f01007a1:	e8 9a 0a 00 00       	call   f0101240 <readline>
f01007a6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007a8:	85 c0                	test   %eax,%eax
f01007aa:	74 ee                	je     f010079a <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ac:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007b3:	be 00 00 00 00       	mov    $0x0,%esi
f01007b8:	eb 06                	jmp    f01007c0 <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007ba:	c6 03 00             	movb   $0x0,(%ebx)
f01007bd:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007c0:	0f b6 03             	movzbl (%ebx),%eax
f01007c3:	84 c0                	test   %al,%al
f01007c5:	74 6a                	je     f0100831 <monitor+0xbb>
f01007c7:	0f be c0             	movsbl %al,%eax
f01007ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ce:	c7 04 24 02 1d 10 f0 	movl   $0xf0101d02,(%esp)
f01007d5:	e8 91 0c 00 00       	call   f010146b <strchr>
f01007da:	85 c0                	test   %eax,%eax
f01007dc:	75 dc                	jne    f01007ba <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f01007de:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007e1:	74 4e                	je     f0100831 <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007e3:	83 fe 0f             	cmp    $0xf,%esi
f01007e6:	75 16                	jne    f01007fe <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007e8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01007ef:	00 
f01007f0:	c7 04 24 07 1d 10 f0 	movl   $0xf0101d07,(%esp)
f01007f7:	e8 92 01 00 00       	call   f010098e <cprintf>
f01007fc:	eb 9c                	jmp    f010079a <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f01007fe:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100802:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100805:	0f b6 03             	movzbl (%ebx),%eax
f0100808:	84 c0                	test   %al,%al
f010080a:	75 0c                	jne    f0100818 <monitor+0xa2>
f010080c:	eb b2                	jmp    f01007c0 <monitor+0x4a>
			buf++;
f010080e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100811:	0f b6 03             	movzbl (%ebx),%eax
f0100814:	84 c0                	test   %al,%al
f0100816:	74 a8                	je     f01007c0 <monitor+0x4a>
f0100818:	0f be c0             	movsbl %al,%eax
f010081b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081f:	c7 04 24 02 1d 10 f0 	movl   $0xf0101d02,(%esp)
f0100826:	e8 40 0c 00 00       	call   f010146b <strchr>
f010082b:	85 c0                	test   %eax,%eax
f010082d:	74 df                	je     f010080e <monitor+0x98>
f010082f:	eb 8f                	jmp    f01007c0 <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f0100831:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100838:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100839:	85 f6                	test   %esi,%esi
f010083b:	0f 84 59 ff ff ff    	je     f010079a <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100841:	c7 44 24 04 e7 1c 10 	movl   $0xf0101ce7,0x4(%esp)
f0100848:	f0 
f0100849:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010084c:	89 04 24             	mov    %eax,(%esp)
f010084f:	e8 9c 0b 00 00       	call   f01013f0 <strcmp>
f0100854:	ba 00 00 00 00       	mov    $0x0,%edx
f0100859:	85 c0                	test   %eax,%eax
f010085b:	74 1c                	je     f0100879 <monitor+0x103>
f010085d:	c7 44 24 04 f5 1c 10 	movl   $0xf0101cf5,0x4(%esp)
f0100864:	f0 
f0100865:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100868:	89 04 24             	mov    %eax,(%esp)
f010086b:	e8 80 0b 00 00       	call   f01013f0 <strcmp>
f0100870:	85 c0                	test   %eax,%eax
f0100872:	75 28                	jne    f010089c <monitor+0x126>
f0100874:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f0100879:	8d 04 12             	lea    (%edx,%edx,1),%eax
f010087c:	01 c2                	add    %eax,%edx
f010087e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100881:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100885:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100889:	89 34 24             	mov    %esi,(%esp)
f010088c:	ff 14 95 a0 1e 10 f0 	call   *-0xfefe160(,%edx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100893:	85 c0                	test   %eax,%eax
f0100895:	78 1d                	js     f01008b4 <monitor+0x13e>
f0100897:	e9 fe fe ff ff       	jmp    f010079a <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010089c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010089f:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a3:	c7 04 24 24 1d 10 f0 	movl   $0xf0101d24,(%esp)
f01008aa:	e8 df 00 00 00       	call   f010098e <cprintf>
f01008af:	e9 e6 fe ff ff       	jmp    f010079a <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008b4:	83 c4 5c             	add    $0x5c,%esp
f01008b7:	5b                   	pop    %ebx
f01008b8:	5e                   	pop    %esi
f01008b9:	5f                   	pop    %edi
f01008ba:	5d                   	pop    %ebp
f01008bb:	c3                   	ret    

f01008bc <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008bc:	55                   	push   %ebp
f01008bd:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008bf:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008c2:	5d                   	pop    %ebp
f01008c3:	c3                   	ret    

f01008c4 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{	
f01008c4:	55                   	push   %ebp
f01008c5:	89 e5                	mov    %esp,%ebp
f01008c7:	56                   	push   %esi
f01008c8:	53                   	push   %ebx
f01008c9:	83 ec 10             	sub    $0x10,%esp
	cprintf("Stack backtrace:\n"); 	
f01008cc:	c7 04 24 3a 1d 10 f0 	movl   $0xf0101d3a,(%esp)
f01008d3:	e8 b6 00 00 00       	call   f010098e <cprintf>
	uint32_t eip=read_eip();  // 获取当前的EIP寄存器的值
f01008d8:	e8 df ff ff ff       	call   f01008bc <read_eip>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008dd:	89 ea                	mov    %ebp,%edx
f01008df:	89 d6                	mov    %edx,%esi
    	uint32_t ebp=read_ebp();  // 获取当前EBP寄存器的值 （作为指针指向的地址处存有外层函数的EBP）
	//uint32_t addr = ebp;
	//uint32_t * ebp = (uint32_t *)read_ebp();
	//uint32_t * eip = (uint32_t *)read_eip();	
	uint32_t addr = ebp ;    	
	while (ebp != 0)	  // 在kernel.asm中 找到ebp初值为0
f01008e1:	85 d2                	test   %edx,%edx
f01008e3:	74 56                	je     f010093b <mon_backtrace+0x77>
       {
	    cprintf("ebp %08x eip %08x ",ebp,eip);
f01008e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008e9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01008ed:	c7 04 24 4c 1d 10 f0 	movl   $0xf0101d4c,(%esp)
f01008f4:	e8 95 00 00 00       	call   f010098e <cprintf>
	    cprintf("args ");
f01008f9:	c7 04 24 5f 1d 10 f0 	movl   $0xf0101d5f,(%esp)
f0100900:	e8 89 00 00 00       	call   f010098e <cprintf>
	    addr = ebp + 8;
	    int i = 0;
f0100905:	bb 00 00 00 00       	mov    $0x0,%ebx
	    for (i ; i <= 4 ; i++) // 打印参数
		{	
		    uint32_t arg = *(uint32_t *)(addr);
		    cprintf("%08x ",arg);
f010090a:	8b 44 9e 08          	mov    0x8(%esi,%ebx,4),%eax
f010090e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100912:	c7 04 24 59 1d 10 f0 	movl   $0xf0101d59,(%esp)
f0100919:	e8 70 00 00 00       	call   f010098e <cprintf>
       {
	    cprintf("ebp %08x eip %08x ",ebp,eip);
	    cprintf("args ");
	    addr = ebp + 8;
	    int i = 0;
	    for (i ; i <= 4 ; i++) // 打印参数
f010091e:	83 c3 01             	add    $0x1,%ebx
f0100921:	83 fb 05             	cmp    $0x5,%ebx
f0100924:	75 e4                	jne    f010090a <mon_backtrace+0x46>
		{	
		    uint32_t arg = *(uint32_t *)(addr);
		    cprintf("%08x ",arg);
		    addr += 4;
		}
	    cprintf("\n");  
f0100926:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f010092d:	e8 5c 00 00 00       	call   f010098e <cprintf>
	    eip = *(uint32_t *)(ebp + 4); 
f0100932:	8b 46 04             	mov    0x4(%esi),%eax
	    ebp = *(uint32_t *)ebp;
f0100935:	8b 36                	mov    (%esi),%esi
    	uint32_t ebp=read_ebp();  // 获取当前EBP寄存器的值 （作为指针指向的地址处存有外层函数的EBP）
	//uint32_t addr = ebp;
	//uint32_t * ebp = (uint32_t *)read_ebp();
	//uint32_t * eip = (uint32_t *)read_eip();	
	uint32_t addr = ebp ;    	
	while (ebp != 0)	  // 在kernel.asm中 找到ebp初值为0
f0100937:	85 f6                	test   %esi,%esi
f0100939:	75 aa                	jne    f01008e5 <mon_backtrace+0x21>
	    eip = *(uint32_t *)(ebp + 4); 
	    ebp = *(uint32_t *)ebp;
	}
	// Your code here.
	return 0;
}
f010093b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100940:	83 c4 10             	add    $0x10,%esp
f0100943:	5b                   	pop    %ebx
f0100944:	5e                   	pop    %esi
f0100945:	5d                   	pop    %ebp
f0100946:	c3                   	ret    
	...

f0100948 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100948:	55                   	push   %ebp
f0100949:	89 e5                	mov    %esp,%ebp
f010094b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010094e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100951:	89 04 24             	mov    %eax,(%esp)
f0100954:	e8 f9 fc ff ff       	call   f0100652 <cputchar>
	*cnt++;
}
f0100959:	c9                   	leave  
f010095a:	c3                   	ret    

f010095b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010095b:	55                   	push   %ebp
f010095c:	89 e5                	mov    %esp,%ebp
f010095e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100961:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100968:	8b 45 0c             	mov    0xc(%ebp),%eax
f010096b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010096f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100972:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100976:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100979:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097d:	c7 04 24 48 09 10 f0 	movl   $0xf0100948,(%esp)
f0100984:	e8 61 04 00 00       	call   f0100dea <vprintfmt>
	return cnt;
}
f0100989:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010098c:	c9                   	leave  
f010098d:	c3                   	ret    

f010098e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010098e:	55                   	push   %ebp
f010098f:	89 e5                	mov    %esp,%ebp
f0100991:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100994:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100997:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099b:	8b 45 08             	mov    0x8(%ebp),%eax
f010099e:	89 04 24             	mov    %eax,(%esp)
f01009a1:	e8 b5 ff ff ff       	call   f010095b <vcprintf>
	va_end(ap);

	return cnt;
} 
f01009a6:	c9                   	leave  
f01009a7:	c3                   	ret    

f01009a8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	57                   	push   %edi
f01009ac:	56                   	push   %esi
f01009ad:	53                   	push   %ebx
f01009ae:	83 ec 10             	sub    $0x10,%esp
f01009b1:	89 c3                	mov    %eax,%ebx
f01009b3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009b6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009b9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009bc:	8b 0a                	mov    (%edx),%ecx
f01009be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009c1:	8b 00                	mov    (%eax),%eax
f01009c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f01009cd:	eb 77                	jmp    f0100a46 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01009cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009d2:	01 c8                	add    %ecx,%eax
f01009d4:	bf 02 00 00 00       	mov    $0x2,%edi
f01009d9:	99                   	cltd   
f01009da:	f7 ff                	idiv   %edi
f01009dc:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009de:	eb 01                	jmp    f01009e1 <stab_binsearch+0x39>
			m--;
f01009e0:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e1:	39 ca                	cmp    %ecx,%edx
f01009e3:	7c 1d                	jl     f0100a02 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009e5:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e8:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f01009ed:	39 f7                	cmp    %esi,%edi
f01009ef:	75 ef                	jne    f01009e0 <stab_binsearch+0x38>
f01009f1:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009f4:	6b fa 0c             	imul   $0xc,%edx,%edi
f01009f7:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f01009fb:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01009fe:	73 18                	jae    f0100a18 <stab_binsearch+0x70>
f0100a00:	eb 05                	jmp    f0100a07 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a02:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100a05:	eb 3f                	jmp    f0100a46 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a07:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a0a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100a0c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a0f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a16:	eb 2e                	jmp    f0100a46 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a18:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a1b:	76 15                	jbe    f0100a32 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100a1d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a20:	4f                   	dec    %edi
f0100a21:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100a24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a27:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a29:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a30:	eb 14                	jmp    f0100a46 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a32:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a35:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a38:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100a3a:	ff 45 0c             	incl   0xc(%ebp)
f0100a3d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a46:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100a49:	7e 84                	jle    f01009cf <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a4b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a4f:	75 0d                	jne    f0100a5e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100a51:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a54:	8b 02                	mov    (%edx),%eax
f0100a56:	48                   	dec    %eax
f0100a57:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a5a:	89 01                	mov    %eax,(%ecx)
f0100a5c:	eb 22                	jmp    f0100a80 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a61:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a63:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a66:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a68:	eb 01                	jmp    f0100a6b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a6a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a6b:	39 c1                	cmp    %eax,%ecx
f0100a6d:	7d 0c                	jge    f0100a7b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a6f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100a72:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100a77:	39 f2                	cmp    %esi,%edx
f0100a79:	75 ef                	jne    f0100a6a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a7b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a7e:	89 02                	mov    %eax,(%edx)
	}
}
f0100a80:	83 c4 10             	add    $0x10,%esp
f0100a83:	5b                   	pop    %ebx
f0100a84:	5e                   	pop    %esi
f0100a85:	5f                   	pop    %edi
f0100a86:	5d                   	pop    %ebp
f0100a87:	c3                   	ret    

f0100a88 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a88:	55                   	push   %ebp
f0100a89:	89 e5                	mov    %esp,%ebp
f0100a8b:	83 ec 38             	sub    $0x38,%esp
f0100a8e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a91:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a94:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a97:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a9a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a9d:	c7 03 b0 1e 10 f0    	movl   $0xf0101eb0,(%ebx)
	info->eip_line = 0;
f0100aa3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aaa:	c7 43 08 b0 1e 10 f0 	movl   $0xf0101eb0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ab1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ab8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100abb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ac2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ac8:	76 12                	jbe    f0100adc <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aca:	b8 60 76 10 f0       	mov    $0xf0107660,%eax
f0100acf:	3d ad 5c 10 f0       	cmp    $0xf0105cad,%eax
f0100ad4:	0f 86 9b 01 00 00    	jbe    f0100c75 <debuginfo_eip+0x1ed>
f0100ada:	eb 1c                	jmp    f0100af8 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100adc:	c7 44 24 08 ba 1e 10 	movl   $0xf0101eba,0x8(%esp)
f0100ae3:	f0 
f0100ae4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100aeb:	00 
f0100aec:	c7 04 24 c7 1e 10 f0 	movl   $0xf0101ec7,(%esp)
f0100af3:	e8 00 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100af8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afd:	80 3d 5f 76 10 f0 00 	cmpb   $0x0,0xf010765f
f0100b04:	0f 85 77 01 00 00    	jne    f0100c81 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b0a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b11:	b8 ac 5c 10 f0       	mov    $0xf0105cac,%eax
f0100b16:	2d e8 20 10 f0       	sub    $0xf01020e8,%eax
f0100b1b:	c1 f8 02             	sar    $0x2,%eax
f0100b1e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b24:	83 e8 01             	sub    $0x1,%eax
f0100b27:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b2a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b2e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b35:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b38:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b3b:	b8 e8 20 10 f0       	mov    $0xf01020e8,%eax
f0100b40:	e8 63 fe ff ff       	call   f01009a8 <stab_binsearch>
	if (lfile == 0)
f0100b45:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100b48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100b4d:	85 d2                	test   %edx,%edx
f0100b4f:	0f 84 2c 01 00 00    	je     f0100c81 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b55:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100b58:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b5b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b5e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b62:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b69:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b6c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b6f:	b8 e8 20 10 f0       	mov    $0xf01020e8,%eax
f0100b74:	e8 2f fe ff ff       	call   f01009a8 <stab_binsearch>

	if (lfun <= rfun) {
f0100b79:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b7c:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b7f:	7f 2e                	jg     f0100baf <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b81:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b84:	8d 90 e8 20 10 f0    	lea    -0xfefdf18(%eax),%edx
f0100b8a:	8b 80 e8 20 10 f0    	mov    -0xfefdf18(%eax),%eax
f0100b90:	b9 60 76 10 f0       	mov    $0xf0107660,%ecx
f0100b95:	81 e9 ad 5c 10 f0    	sub    $0xf0105cad,%ecx
f0100b9b:	39 c8                	cmp    %ecx,%eax
f0100b9d:	73 08                	jae    f0100ba7 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b9f:	05 ad 5c 10 f0       	add    $0xf0105cad,%eax
f0100ba4:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ba7:	8b 42 08             	mov    0x8(%edx),%eax
f0100baa:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bad:	eb 06                	jmp    f0100bb5 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100baf:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bb2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bb5:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bbc:	00 
f0100bbd:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bc0:	89 04 24             	mov    %eax,(%esp)
f0100bc3:	e8 d7 08 00 00       	call   f010149f <strfind>
f0100bc8:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bcb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bce:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100bd1:	39 d7                	cmp    %edx,%edi
f0100bd3:	7c 5f                	jl     f0100c34 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100bd5:	89 f8                	mov    %edi,%eax
f0100bd7:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0100bda:	80 b9 ec 20 10 f0 84 	cmpb   $0x84,-0xfefdf14(%ecx)
f0100be1:	75 18                	jne    f0100bfb <debuginfo_eip+0x173>
f0100be3:	eb 30                	jmp    f0100c15 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100be5:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be8:	39 fa                	cmp    %edi,%edx
f0100bea:	7f 48                	jg     f0100c34 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100bec:	89 f8                	mov    %edi,%eax
f0100bee:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0100bf1:	80 3c 8d ec 20 10 f0 	cmpb   $0x84,-0xfefdf14(,%ecx,4)
f0100bf8:	84 
f0100bf9:	74 1a                	je     f0100c15 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bfb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100bfe:	8d 04 85 e8 20 10 f0 	lea    -0xfefdf18(,%eax,4),%eax
f0100c05:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0100c09:	75 da                	jne    f0100be5 <debuginfo_eip+0x15d>
f0100c0b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c0f:	74 d4                	je     f0100be5 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c11:	39 fa                	cmp    %edi,%edx
f0100c13:	7f 1f                	jg     f0100c34 <debuginfo_eip+0x1ac>
f0100c15:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c18:	8b 87 e8 20 10 f0    	mov    -0xfefdf18(%edi),%eax
f0100c1e:	ba 60 76 10 f0       	mov    $0xf0107660,%edx
f0100c23:	81 ea ad 5c 10 f0    	sub    $0xf0105cad,%edx
f0100c29:	39 d0                	cmp    %edx,%eax
f0100c2b:	73 07                	jae    f0100c34 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c2d:	05 ad 5c 10 f0       	add    $0xf0105cad,%eax
f0100c32:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c34:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c37:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c3a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c3f:	39 ca                	cmp    %ecx,%edx
f0100c41:	7d 3e                	jge    f0100c81 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0100c43:	83 c2 01             	add    $0x1,%edx
f0100c46:	39 d1                	cmp    %edx,%ecx
f0100c48:	7e 37                	jle    f0100c81 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c4a:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100c4d:	80 be ec 20 10 f0 a0 	cmpb   $0xa0,-0xfefdf14(%esi)
f0100c54:	75 2b                	jne    f0100c81 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0100c56:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c5a:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c5d:	39 d1                	cmp    %edx,%ecx
f0100c5f:	7e 1b                	jle    f0100c7c <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c61:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c64:	80 3c 85 ec 20 10 f0 	cmpb   $0xa0,-0xfefdf14(,%eax,4)
f0100c6b:	a0 
f0100c6c:	74 e8                	je     f0100c56 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c73:	eb 0c                	jmp    f0100c81 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c7a:	eb 05                	jmp    f0100c81 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c7c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c81:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100c84:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100c87:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100c8a:	89 ec                	mov    %ebp,%esp
f0100c8c:	5d                   	pop    %ebp
f0100c8d:	c3                   	ret    
	...

f0100c90 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c90:	55                   	push   %ebp
f0100c91:	89 e5                	mov    %esp,%ebp
f0100c93:	57                   	push   %edi
f0100c94:	56                   	push   %esi
f0100c95:	53                   	push   %ebx
f0100c96:	83 ec 3c             	sub    $0x3c,%esp
f0100c99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c9c:	89 d7                	mov    %edx,%edi
f0100c9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ca1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ca4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ca7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100caa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100cad:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cb0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100cb8:	72 11                	jb     f0100ccb <printnum+0x3b>
f0100cba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cbd:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cc0:	76 09                	jbe    f0100ccb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cc2:	83 eb 01             	sub    $0x1,%ebx
f0100cc5:	85 db                	test   %ebx,%ebx
f0100cc7:	7f 51                	jg     f0100d1a <printnum+0x8a>
f0100cc9:	eb 5e                	jmp    f0100d29 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ccb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100ccf:	83 eb 01             	sub    $0x1,%ebx
f0100cd2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cd6:	8b 45 10             	mov    0x10(%ebp),%eax
f0100cd9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cdd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100ce1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100ce5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100cec:	00 
f0100ced:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cf0:	89 04 24             	mov    %eax,(%esp)
f0100cf3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cf6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cfa:	e8 21 0a 00 00       	call   f0101720 <__udivdi3>
f0100cff:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100d03:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d07:	89 04 24             	mov    %eax,(%esp)
f0100d0a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d0e:	89 fa                	mov    %edi,%edx
f0100d10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d13:	e8 78 ff ff ff       	call   f0100c90 <printnum>
f0100d18:	eb 0f                	jmp    f0100d29 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d1a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d1e:	89 34 24             	mov    %esi,(%esp)
f0100d21:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d24:	83 eb 01             	sub    $0x1,%ebx
f0100d27:	75 f1                	jne    f0100d1a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d29:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d2d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d31:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d38:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d3f:	00 
f0100d40:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d43:	89 04 24             	mov    %eax,(%esp)
f0100d46:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d49:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d4d:	e8 fe 0a 00 00       	call   f0101850 <__umoddi3>
f0100d52:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d56:	0f be 80 d5 1e 10 f0 	movsbl -0xfefe12b(%eax),%eax
f0100d5d:	89 04 24             	mov    %eax,(%esp)
f0100d60:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d63:	83 c4 3c             	add    $0x3c,%esp
f0100d66:	5b                   	pop    %ebx
f0100d67:	5e                   	pop    %esi
f0100d68:	5f                   	pop    %edi
f0100d69:	5d                   	pop    %ebp
f0100d6a:	c3                   	ret    

f0100d6b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d6b:	55                   	push   %ebp
f0100d6c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d6e:	83 fa 01             	cmp    $0x1,%edx
f0100d71:	7e 0e                	jle    f0100d81 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d73:	8b 10                	mov    (%eax),%edx
f0100d75:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d78:	89 08                	mov    %ecx,(%eax)
f0100d7a:	8b 02                	mov    (%edx),%eax
f0100d7c:	8b 52 04             	mov    0x4(%edx),%edx
f0100d7f:	eb 22                	jmp    f0100da3 <getuint+0x38>
	else if (lflag)
f0100d81:	85 d2                	test   %edx,%edx
f0100d83:	74 10                	je     f0100d95 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d85:	8b 10                	mov    (%eax),%edx
f0100d87:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d8a:	89 08                	mov    %ecx,(%eax)
f0100d8c:	8b 02                	mov    (%edx),%eax
f0100d8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d93:	eb 0e                	jmp    f0100da3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d95:	8b 10                	mov    (%eax),%edx
f0100d97:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d9a:	89 08                	mov    %ecx,(%eax)
f0100d9c:	8b 02                	mov    (%edx),%eax
f0100d9e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100da3:	5d                   	pop    %ebp
f0100da4:	c3                   	ret    

f0100da5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da5:	55                   	push   %ebp
f0100da6:	89 e5                	mov    %esp,%ebp
f0100da8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dab:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100daf:	8b 10                	mov    (%eax),%edx
f0100db1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100db4:	73 0a                	jae    f0100dc0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100db6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100db9:	88 0a                	mov    %cl,(%edx)
f0100dbb:	83 c2 01             	add    $0x1,%edx
f0100dbe:	89 10                	mov    %edx,(%eax)
}
f0100dc0:	5d                   	pop    %ebp
f0100dc1:	c3                   	ret    

f0100dc2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc2:	55                   	push   %ebp
f0100dc3:	89 e5                	mov    %esp,%ebp
f0100dc5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dc8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dcb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dcf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dd2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dd6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ddd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100de0:	89 04 24             	mov    %eax,(%esp)
f0100de3:	e8 02 00 00 00       	call   f0100dea <vprintfmt>
	va_end(ap);
}
f0100de8:	c9                   	leave  
f0100de9:	c3                   	ret    

f0100dea <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dea:	55                   	push   %ebp
f0100deb:	89 e5                	mov    %esp,%ebp
f0100ded:	57                   	push   %edi
f0100dee:	56                   	push   %esi
f0100def:	53                   	push   %ebx
f0100df0:	83 ec 4c             	sub    $0x4c,%esp
f0100df3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100df6:	8b 75 10             	mov    0x10(%ebp),%esi
f0100df9:	eb 12                	jmp    f0100e0d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dfb:	85 c0                	test   %eax,%eax
f0100dfd:	0f 84 a9 03 00 00    	je     f01011ac <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0100e03:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e07:	89 04 24             	mov    %eax,(%esp)
f0100e0a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e0d:	0f b6 06             	movzbl (%esi),%eax
f0100e10:	83 c6 01             	add    $0x1,%esi
f0100e13:	83 f8 25             	cmp    $0x25,%eax
f0100e16:	75 e3                	jne    f0100dfb <vprintfmt+0x11>
f0100e18:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e1c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e23:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100e28:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e2f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e34:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e37:	eb 2b                	jmp    f0100e64 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e39:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e3c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100e40:	eb 22                	jmp    f0100e64 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e42:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e45:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100e49:	eb 19                	jmp    f0100e64 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100e4e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100e55:	eb 0d                	jmp    f0100e64 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e5a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e5d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e64:	0f b6 06             	movzbl (%esi),%eax
f0100e67:	0f b6 d0             	movzbl %al,%edx
f0100e6a:	8d 7e 01             	lea    0x1(%esi),%edi
f0100e6d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100e70:	83 e8 23             	sub    $0x23,%eax
f0100e73:	3c 55                	cmp    $0x55,%al
f0100e75:	0f 87 0b 03 00 00    	ja     f0101186 <vprintfmt+0x39c>
f0100e7b:	0f b6 c0             	movzbl %al,%eax
f0100e7e:	ff 24 85 64 1f 10 f0 	jmp    *-0xfefe09c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e85:	83 ea 30             	sub    $0x30,%edx
f0100e88:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100e8b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100e8f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e92:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100e95:	83 fa 09             	cmp    $0x9,%edx
f0100e98:	77 4a                	ja     f0100ee4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e9d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100ea0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100ea3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100ea7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100eaa:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100ead:	83 fa 09             	cmp    $0x9,%edx
f0100eb0:	76 eb                	jbe    f0100e9d <vprintfmt+0xb3>
f0100eb2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100eb5:	eb 2d                	jmp    f0100ee4 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100eb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eba:	8d 50 04             	lea    0x4(%eax),%edx
f0100ebd:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec0:	8b 00                	mov    (%eax),%eax
f0100ec2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ec8:	eb 1a                	jmp    f0100ee4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eca:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100ecd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ed1:	79 91                	jns    f0100e64 <vprintfmt+0x7a>
f0100ed3:	e9 73 ff ff ff       	jmp    f0100e4b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100edb:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100ee2:	eb 80                	jmp    f0100e64 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100ee4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ee8:	0f 89 76 ff ff ff    	jns    f0100e64 <vprintfmt+0x7a>
f0100eee:	e9 64 ff ff ff       	jmp    f0100e57 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ef3:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ef9:	e9 66 ff ff ff       	jmp    f0100e64 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100efe:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f01:	8d 50 04             	lea    0x4(%eax),%edx
f0100f04:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f07:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f0b:	8b 00                	mov    (%eax),%eax
f0100f0d:	89 04 24             	mov    %eax,(%esp)
f0100f10:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f13:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f16:	e9 f2 fe ff ff       	jmp    f0100e0d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f21:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f24:	8b 00                	mov    (%eax),%eax
f0100f26:	89 c2                	mov    %eax,%edx
f0100f28:	c1 fa 1f             	sar    $0x1f,%edx
f0100f2b:	31 d0                	xor    %edx,%eax
f0100f2d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f2f:	83 f8 06             	cmp    $0x6,%eax
f0100f32:	7f 0b                	jg     f0100f3f <vprintfmt+0x155>
f0100f34:	8b 14 85 bc 20 10 f0 	mov    -0xfefdf44(,%eax,4),%edx
f0100f3b:	85 d2                	test   %edx,%edx
f0100f3d:	75 23                	jne    f0100f62 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0100f3f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f43:	c7 44 24 08 ed 1e 10 	movl   $0xf0101eed,0x8(%esp)
f0100f4a:	f0 
f0100f4b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f4f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f52:	89 3c 24             	mov    %edi,(%esp)
f0100f55:	e8 68 fe ff ff       	call   f0100dc2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f5d:	e9 ab fe ff ff       	jmp    f0100e0d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100f62:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f66:	c7 44 24 08 f6 1e 10 	movl   $0xf0101ef6,0x8(%esp)
f0100f6d:	f0 
f0100f6e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f72:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f75:	89 3c 24             	mov    %edi,(%esp)
f0100f78:	e8 45 fe ff ff       	call   f0100dc2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f80:	e9 88 fe ff ff       	jmp    f0100e0d <vprintfmt+0x23>
f0100f85:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f8b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f91:	8d 50 04             	lea    0x4(%eax),%edx
f0100f94:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f97:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100f99:	85 f6                	test   %esi,%esi
f0100f9b:	ba e6 1e 10 f0       	mov    $0xf0101ee6,%edx
f0100fa0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0100fa3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100fa7:	7e 06                	jle    f0100faf <vprintfmt+0x1c5>
f0100fa9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100fad:	75 10                	jne    f0100fbf <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100faf:	0f be 06             	movsbl (%esi),%eax
f0100fb2:	83 c6 01             	add    $0x1,%esi
f0100fb5:	85 c0                	test   %eax,%eax
f0100fb7:	0f 85 86 00 00 00    	jne    f0101043 <vprintfmt+0x259>
f0100fbd:	eb 76                	jmp    f0101035 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fbf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fc3:	89 34 24             	mov    %esi,(%esp)
f0100fc6:	e8 60 03 00 00       	call   f010132b <strnlen>
f0100fcb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100fce:	29 c2                	sub    %eax,%edx
f0100fd0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100fd3:	85 d2                	test   %edx,%edx
f0100fd5:	7e d8                	jle    f0100faf <vprintfmt+0x1c5>
					putch(padc, putdat);
f0100fd7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100fdb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100fde:	89 d6                	mov    %edx,%esi
f0100fe0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100fe3:	89 c7                	mov    %eax,%edi
f0100fe5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fe9:	89 3c 24             	mov    %edi,(%esp)
f0100fec:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fef:	83 ee 01             	sub    $0x1,%esi
f0100ff2:	75 f1                	jne    f0100fe5 <vprintfmt+0x1fb>
f0100ff4:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100ff7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100ffa:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0100ffd:	eb b0                	jmp    f0100faf <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fff:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101003:	74 18                	je     f010101d <vprintfmt+0x233>
f0101005:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101008:	83 fa 5e             	cmp    $0x5e,%edx
f010100b:	76 10                	jbe    f010101d <vprintfmt+0x233>
					putch('?', putdat);
f010100d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101011:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101018:	ff 55 08             	call   *0x8(%ebp)
f010101b:	eb 0a                	jmp    f0101027 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010101d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101021:	89 04 24             	mov    %eax,(%esp)
f0101024:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101027:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010102b:	0f be 06             	movsbl (%esi),%eax
f010102e:	83 c6 01             	add    $0x1,%esi
f0101031:	85 c0                	test   %eax,%eax
f0101033:	75 0e                	jne    f0101043 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101035:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101038:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010103c:	7f 16                	jg     f0101054 <vprintfmt+0x26a>
f010103e:	e9 ca fd ff ff       	jmp    f0100e0d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101043:	85 ff                	test   %edi,%edi
f0101045:	78 b8                	js     f0100fff <vprintfmt+0x215>
f0101047:	83 ef 01             	sub    $0x1,%edi
f010104a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101050:	79 ad                	jns    f0100fff <vprintfmt+0x215>
f0101052:	eb e1                	jmp    f0101035 <vprintfmt+0x24b>
f0101054:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101057:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010105a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010105e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101065:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101067:	83 ee 01             	sub    $0x1,%esi
f010106a:	75 ee                	jne    f010105a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010106c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010106f:	e9 99 fd ff ff       	jmp    f0100e0d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101074:	83 f9 01             	cmp    $0x1,%ecx
f0101077:	7e 10                	jle    f0101089 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101079:	8b 45 14             	mov    0x14(%ebp),%eax
f010107c:	8d 50 08             	lea    0x8(%eax),%edx
f010107f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101082:	8b 30                	mov    (%eax),%esi
f0101084:	8b 78 04             	mov    0x4(%eax),%edi
f0101087:	eb 26                	jmp    f01010af <vprintfmt+0x2c5>
	else if (lflag)
f0101089:	85 c9                	test   %ecx,%ecx
f010108b:	74 12                	je     f010109f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010108d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101090:	8d 50 04             	lea    0x4(%eax),%edx
f0101093:	89 55 14             	mov    %edx,0x14(%ebp)
f0101096:	8b 30                	mov    (%eax),%esi
f0101098:	89 f7                	mov    %esi,%edi
f010109a:	c1 ff 1f             	sar    $0x1f,%edi
f010109d:	eb 10                	jmp    f01010af <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010109f:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a2:	8d 50 04             	lea    0x4(%eax),%edx
f01010a5:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a8:	8b 30                	mov    (%eax),%esi
f01010aa:	89 f7                	mov    %esi,%edi
f01010ac:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010af:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010b4:	85 ff                	test   %edi,%edi
f01010b6:	0f 89 8c 00 00 00    	jns    f0101148 <vprintfmt+0x35e>
				putch('-', putdat);
f01010bc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010c7:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01010ca:	f7 de                	neg    %esi
f01010cc:	83 d7 00             	adc    $0x0,%edi
f01010cf:	f7 df                	neg    %edi
			}
			base = 10;
f01010d1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010d6:	eb 70                	jmp    f0101148 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010d8:	89 ca                	mov    %ecx,%edx
f01010da:	8d 45 14             	lea    0x14(%ebp),%eax
f01010dd:	e8 89 fc ff ff       	call   f0100d6b <getuint>
f01010e2:	89 c6                	mov    %eax,%esi
f01010e4:	89 d7                	mov    %edx,%edi
			base = 10;
f01010e6:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01010eb:	eb 5b                	jmp    f0101148 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010ed:	89 ca                	mov    %ecx,%edx
f01010ef:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f2:	e8 74 fc ff ff       	call   f0100d6b <getuint>
f01010f7:	89 c6                	mov    %eax,%esi
f01010f9:	89 d7                	mov    %edx,%edi
			base = 8;         // 改变基数
f01010fb:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101100:	eb 46                	jmp    f0101148 <vprintfmt+0x35e>
			//putch('X', putdat);
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0101102:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101106:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010110d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101110:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101114:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010111b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010111e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101121:	8d 50 04             	lea    0x4(%eax),%edx
f0101124:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101127:	8b 30                	mov    (%eax),%esi
f0101129:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010112e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101133:	eb 13                	jmp    f0101148 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101135:	89 ca                	mov    %ecx,%edx
f0101137:	8d 45 14             	lea    0x14(%ebp),%eax
f010113a:	e8 2c fc ff ff       	call   f0100d6b <getuint>
f010113f:	89 c6                	mov    %eax,%esi
f0101141:	89 d7                	mov    %edx,%edi
			base = 16;
f0101143:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101148:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010114c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101150:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101153:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101157:	89 44 24 08          	mov    %eax,0x8(%esp)
f010115b:	89 34 24             	mov    %esi,(%esp)
f010115e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101162:	89 da                	mov    %ebx,%edx
f0101164:	8b 45 08             	mov    0x8(%ebp),%eax
f0101167:	e8 24 fb ff ff       	call   f0100c90 <printnum>
			break;
f010116c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010116f:	e9 99 fc ff ff       	jmp    f0100e0d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101174:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101178:	89 14 24             	mov    %edx,(%esp)
f010117b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010117e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101181:	e9 87 fc ff ff       	jmp    f0100e0d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101186:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010118a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101191:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101194:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101198:	0f 84 6f fc ff ff    	je     f0100e0d <vprintfmt+0x23>
f010119e:	83 ee 01             	sub    $0x1,%esi
f01011a1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01011a5:	75 f7                	jne    f010119e <vprintfmt+0x3b4>
f01011a7:	e9 61 fc ff ff       	jmp    f0100e0d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01011ac:	83 c4 4c             	add    $0x4c,%esp
f01011af:	5b                   	pop    %ebx
f01011b0:	5e                   	pop    %esi
f01011b1:	5f                   	pop    %edi
f01011b2:	5d                   	pop    %ebp
f01011b3:	c3                   	ret    

f01011b4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011b4:	55                   	push   %ebp
f01011b5:	89 e5                	mov    %esp,%ebp
f01011b7:	83 ec 28             	sub    $0x28,%esp
f01011ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01011bd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011c3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011c7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011d1:	85 c0                	test   %eax,%eax
f01011d3:	74 30                	je     f0101205 <vsnprintf+0x51>
f01011d5:	85 d2                	test   %edx,%edx
f01011d7:	7e 2c                	jle    f0101205 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011e0:	8b 45 10             	mov    0x10(%ebp),%eax
f01011e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011ee:	c7 04 24 a5 0d 10 f0 	movl   $0xf0100da5,(%esp)
f01011f5:	e8 f0 fb ff ff       	call   f0100dea <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011fd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101200:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101203:	eb 05                	jmp    f010120a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101205:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010120a:	c9                   	leave  
f010120b:	c3                   	ret    

f010120c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010120c:	55                   	push   %ebp
f010120d:	89 e5                	mov    %esp,%ebp
f010120f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101212:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101215:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101219:	8b 45 10             	mov    0x10(%ebp),%eax
f010121c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101220:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101223:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101227:	8b 45 08             	mov    0x8(%ebp),%eax
f010122a:	89 04 24             	mov    %eax,(%esp)
f010122d:	e8 82 ff ff ff       	call   f01011b4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101232:	c9                   	leave  
f0101233:	c3                   	ret    
	...

f0101240 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101240:	55                   	push   %ebp
f0101241:	89 e5                	mov    %esp,%ebp
f0101243:	57                   	push   %edi
f0101244:	56                   	push   %esi
f0101245:	53                   	push   %ebx
f0101246:	83 ec 1c             	sub    $0x1c,%esp
f0101249:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010124c:	85 c0                	test   %eax,%eax
f010124e:	74 10                	je     f0101260 <readline+0x20>
		cprintf("%s", prompt);
f0101250:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101254:	c7 04 24 f6 1e 10 f0 	movl   $0xf0101ef6,(%esp)
f010125b:	e8 2e f7 ff ff       	call   f010098e <cprintf>

	i = 0;
	echoing = iscons(0);
f0101260:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101267:	e8 07 f4 ff ff       	call   f0100673 <iscons>
f010126c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010126e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101273:	e8 ea f3 ff ff       	call   f0100662 <getchar>
f0101278:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010127a:	85 c0                	test   %eax,%eax
f010127c:	79 17                	jns    f0101295 <readline+0x55>
			cprintf("read error: %e\n", c);
f010127e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101282:	c7 04 24 d8 20 10 f0 	movl   $0xf01020d8,(%esp)
f0101289:	e8 00 f7 ff ff       	call   f010098e <cprintf>
			return NULL;
f010128e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101293:	eb 6d                	jmp    f0101302 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101295:	83 f8 08             	cmp    $0x8,%eax
f0101298:	74 05                	je     f010129f <readline+0x5f>
f010129a:	83 f8 7f             	cmp    $0x7f,%eax
f010129d:	75 19                	jne    f01012b8 <readline+0x78>
f010129f:	85 f6                	test   %esi,%esi
f01012a1:	7e 15                	jle    f01012b8 <readline+0x78>
			if (echoing)
f01012a3:	85 ff                	test   %edi,%edi
f01012a5:	74 0c                	je     f01012b3 <readline+0x73>
				cputchar('\b');
f01012a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012ae:	e8 9f f3 ff ff       	call   f0100652 <cputchar>
			i--;
f01012b3:	83 ee 01             	sub    $0x1,%esi
f01012b6:	eb bb                	jmp    f0101273 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012b8:	83 fb 1f             	cmp    $0x1f,%ebx
f01012bb:	7e 1f                	jle    f01012dc <readline+0x9c>
f01012bd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012c3:	7f 17                	jg     f01012dc <readline+0x9c>
			if (echoing)
f01012c5:	85 ff                	test   %edi,%edi
f01012c7:	74 08                	je     f01012d1 <readline+0x91>
				cputchar(c);
f01012c9:	89 1c 24             	mov    %ebx,(%esp)
f01012cc:	e8 81 f3 ff ff       	call   f0100652 <cputchar>
			buf[i++] = c;
f01012d1:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f01012d7:	83 c6 01             	add    $0x1,%esi
f01012da:	eb 97                	jmp    f0101273 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012dc:	83 fb 0a             	cmp    $0xa,%ebx
f01012df:	74 05                	je     f01012e6 <readline+0xa6>
f01012e1:	83 fb 0d             	cmp    $0xd,%ebx
f01012e4:	75 8d                	jne    f0101273 <readline+0x33>
			if (echoing)
f01012e6:	85 ff                	test   %edi,%edi
f01012e8:	74 0c                	je     f01012f6 <readline+0xb6>
				cputchar('\n');
f01012ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012f1:	e8 5c f3 ff ff       	call   f0100652 <cputchar>
			buf[i] = 0;
f01012f6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01012fd:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101302:	83 c4 1c             	add    $0x1c,%esp
f0101305:	5b                   	pop    %ebx
f0101306:	5e                   	pop    %esi
f0101307:	5f                   	pop    %edi
f0101308:	5d                   	pop    %ebp
f0101309:	c3                   	ret    
f010130a:	00 00                	add    %al,(%eax)
f010130c:	00 00                	add    %al,(%eax)
	...

f0101310 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101310:	55                   	push   %ebp
f0101311:	89 e5                	mov    %esp,%ebp
f0101313:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101316:	b8 00 00 00 00       	mov    $0x0,%eax
f010131b:	80 3a 00             	cmpb   $0x0,(%edx)
f010131e:	74 09                	je     f0101329 <strlen+0x19>
		n++;
f0101320:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101323:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101327:	75 f7                	jne    f0101320 <strlen+0x10>
		n++;
	return n;
}
f0101329:	5d                   	pop    %ebp
f010132a:	c3                   	ret    

f010132b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010132b:	55                   	push   %ebp
f010132c:	89 e5                	mov    %esp,%ebp
f010132e:	53                   	push   %ebx
f010132f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101332:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101335:	b8 00 00 00 00       	mov    $0x0,%eax
f010133a:	85 c9                	test   %ecx,%ecx
f010133c:	74 1a                	je     f0101358 <strnlen+0x2d>
f010133e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101341:	74 15                	je     f0101358 <strnlen+0x2d>
f0101343:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101348:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010134a:	39 ca                	cmp    %ecx,%edx
f010134c:	74 0a                	je     f0101358 <strnlen+0x2d>
f010134e:	83 c2 01             	add    $0x1,%edx
f0101351:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101356:	75 f0                	jne    f0101348 <strnlen+0x1d>
		n++;
	return n;
}
f0101358:	5b                   	pop    %ebx
f0101359:	5d                   	pop    %ebp
f010135a:	c3                   	ret    

f010135b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010135b:	55                   	push   %ebp
f010135c:	89 e5                	mov    %esp,%ebp
f010135e:	53                   	push   %ebx
f010135f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101362:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101365:	ba 00 00 00 00       	mov    $0x0,%edx
f010136a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010136e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101371:	83 c2 01             	add    $0x1,%edx
f0101374:	84 c9                	test   %cl,%cl
f0101376:	75 f2                	jne    f010136a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101378:	5b                   	pop    %ebx
f0101379:	5d                   	pop    %ebp
f010137a:	c3                   	ret    

f010137b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010137b:	55                   	push   %ebp
f010137c:	89 e5                	mov    %esp,%ebp
f010137e:	56                   	push   %esi
f010137f:	53                   	push   %ebx
f0101380:	8b 45 08             	mov    0x8(%ebp),%eax
f0101383:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101386:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101389:	85 f6                	test   %esi,%esi
f010138b:	74 18                	je     f01013a5 <strncpy+0x2a>
f010138d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101392:	0f b6 1a             	movzbl (%edx),%ebx
f0101395:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101398:	80 3a 01             	cmpb   $0x1,(%edx)
f010139b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010139e:	83 c1 01             	add    $0x1,%ecx
f01013a1:	39 f1                	cmp    %esi,%ecx
f01013a3:	75 ed                	jne    f0101392 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013a5:	5b                   	pop    %ebx
f01013a6:	5e                   	pop    %esi
f01013a7:	5d                   	pop    %ebp
f01013a8:	c3                   	ret    

f01013a9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013a9:	55                   	push   %ebp
f01013aa:	89 e5                	mov    %esp,%ebp
f01013ac:	57                   	push   %edi
f01013ad:	56                   	push   %esi
f01013ae:	53                   	push   %ebx
f01013af:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013b5:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013b8:	89 f8                	mov    %edi,%eax
f01013ba:	85 f6                	test   %esi,%esi
f01013bc:	74 2b                	je     f01013e9 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f01013be:	83 fe 01             	cmp    $0x1,%esi
f01013c1:	74 23                	je     f01013e6 <strlcpy+0x3d>
f01013c3:	0f b6 0b             	movzbl (%ebx),%ecx
f01013c6:	84 c9                	test   %cl,%cl
f01013c8:	74 1c                	je     f01013e6 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01013ca:	83 ee 02             	sub    $0x2,%esi
f01013cd:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013d2:	88 08                	mov    %cl,(%eax)
f01013d4:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013d7:	39 f2                	cmp    %esi,%edx
f01013d9:	74 0b                	je     f01013e6 <strlcpy+0x3d>
f01013db:	83 c2 01             	add    $0x1,%edx
f01013de:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01013e2:	84 c9                	test   %cl,%cl
f01013e4:	75 ec                	jne    f01013d2 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01013e6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013e9:	29 f8                	sub    %edi,%eax
}
f01013eb:	5b                   	pop    %ebx
f01013ec:	5e                   	pop    %esi
f01013ed:	5f                   	pop    %edi
f01013ee:	5d                   	pop    %ebp
f01013ef:	c3                   	ret    

f01013f0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013f0:	55                   	push   %ebp
f01013f1:	89 e5                	mov    %esp,%ebp
f01013f3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013f6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013f9:	0f b6 01             	movzbl (%ecx),%eax
f01013fc:	84 c0                	test   %al,%al
f01013fe:	74 16                	je     f0101416 <strcmp+0x26>
f0101400:	3a 02                	cmp    (%edx),%al
f0101402:	75 12                	jne    f0101416 <strcmp+0x26>
		p++, q++;
f0101404:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101407:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010140b:	84 c0                	test   %al,%al
f010140d:	74 07                	je     f0101416 <strcmp+0x26>
f010140f:	83 c1 01             	add    $0x1,%ecx
f0101412:	3a 02                	cmp    (%edx),%al
f0101414:	74 ee                	je     f0101404 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101416:	0f b6 c0             	movzbl %al,%eax
f0101419:	0f b6 12             	movzbl (%edx),%edx
f010141c:	29 d0                	sub    %edx,%eax
}
f010141e:	5d                   	pop    %ebp
f010141f:	c3                   	ret    

f0101420 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101420:	55                   	push   %ebp
f0101421:	89 e5                	mov    %esp,%ebp
f0101423:	53                   	push   %ebx
f0101424:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101427:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010142a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010142d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101432:	85 d2                	test   %edx,%edx
f0101434:	74 28                	je     f010145e <strncmp+0x3e>
f0101436:	0f b6 01             	movzbl (%ecx),%eax
f0101439:	84 c0                	test   %al,%al
f010143b:	74 24                	je     f0101461 <strncmp+0x41>
f010143d:	3a 03                	cmp    (%ebx),%al
f010143f:	75 20                	jne    f0101461 <strncmp+0x41>
f0101441:	83 ea 01             	sub    $0x1,%edx
f0101444:	74 13                	je     f0101459 <strncmp+0x39>
		n--, p++, q++;
f0101446:	83 c1 01             	add    $0x1,%ecx
f0101449:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010144c:	0f b6 01             	movzbl (%ecx),%eax
f010144f:	84 c0                	test   %al,%al
f0101451:	74 0e                	je     f0101461 <strncmp+0x41>
f0101453:	3a 03                	cmp    (%ebx),%al
f0101455:	74 ea                	je     f0101441 <strncmp+0x21>
f0101457:	eb 08                	jmp    f0101461 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101459:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010145e:	5b                   	pop    %ebx
f010145f:	5d                   	pop    %ebp
f0101460:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101461:	0f b6 01             	movzbl (%ecx),%eax
f0101464:	0f b6 13             	movzbl (%ebx),%edx
f0101467:	29 d0                	sub    %edx,%eax
f0101469:	eb f3                	jmp    f010145e <strncmp+0x3e>

f010146b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010146b:	55                   	push   %ebp
f010146c:	89 e5                	mov    %esp,%ebp
f010146e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101471:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101475:	0f b6 10             	movzbl (%eax),%edx
f0101478:	84 d2                	test   %dl,%dl
f010147a:	74 1c                	je     f0101498 <strchr+0x2d>
		if (*s == c)
f010147c:	38 ca                	cmp    %cl,%dl
f010147e:	75 09                	jne    f0101489 <strchr+0x1e>
f0101480:	eb 1b                	jmp    f010149d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101482:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101485:	38 ca                	cmp    %cl,%dl
f0101487:	74 14                	je     f010149d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101489:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010148d:	84 d2                	test   %dl,%dl
f010148f:	75 f1                	jne    f0101482 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0101491:	b8 00 00 00 00       	mov    $0x0,%eax
f0101496:	eb 05                	jmp    f010149d <strchr+0x32>
f0101498:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010149d:	5d                   	pop    %ebp
f010149e:	c3                   	ret    

f010149f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010149f:	55                   	push   %ebp
f01014a0:	89 e5                	mov    %esp,%ebp
f01014a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014a9:	0f b6 10             	movzbl (%eax),%edx
f01014ac:	84 d2                	test   %dl,%dl
f01014ae:	74 14                	je     f01014c4 <strfind+0x25>
		if (*s == c)
f01014b0:	38 ca                	cmp    %cl,%dl
f01014b2:	75 06                	jne    f01014ba <strfind+0x1b>
f01014b4:	eb 0e                	jmp    f01014c4 <strfind+0x25>
f01014b6:	38 ca                	cmp    %cl,%dl
f01014b8:	74 0a                	je     f01014c4 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014ba:	83 c0 01             	add    $0x1,%eax
f01014bd:	0f b6 10             	movzbl (%eax),%edx
f01014c0:	84 d2                	test   %dl,%dl
f01014c2:	75 f2                	jne    f01014b6 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01014c4:	5d                   	pop    %ebp
f01014c5:	c3                   	ret    

f01014c6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014c6:	55                   	push   %ebp
f01014c7:	89 e5                	mov    %esp,%ebp
f01014c9:	83 ec 0c             	sub    $0xc,%esp
f01014cc:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01014cf:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01014d2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01014d5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014db:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014de:	85 c9                	test   %ecx,%ecx
f01014e0:	74 30                	je     f0101512 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014e2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014e8:	75 25                	jne    f010150f <memset+0x49>
f01014ea:	f6 c1 03             	test   $0x3,%cl
f01014ed:	75 20                	jne    f010150f <memset+0x49>
		c &= 0xFF;
f01014ef:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014f2:	89 d3                	mov    %edx,%ebx
f01014f4:	c1 e3 08             	shl    $0x8,%ebx
f01014f7:	89 d6                	mov    %edx,%esi
f01014f9:	c1 e6 18             	shl    $0x18,%esi
f01014fc:	89 d0                	mov    %edx,%eax
f01014fe:	c1 e0 10             	shl    $0x10,%eax
f0101501:	09 f0                	or     %esi,%eax
f0101503:	09 d0                	or     %edx,%eax
f0101505:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101507:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010150a:	fc                   	cld    
f010150b:	f3 ab                	rep stos %eax,%es:(%edi)
f010150d:	eb 03                	jmp    f0101512 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010150f:	fc                   	cld    
f0101510:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101512:	89 f8                	mov    %edi,%eax
f0101514:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101517:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010151a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010151d:	89 ec                	mov    %ebp,%esp
f010151f:	5d                   	pop    %ebp
f0101520:	c3                   	ret    

f0101521 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101521:	55                   	push   %ebp
f0101522:	89 e5                	mov    %esp,%ebp
f0101524:	83 ec 08             	sub    $0x8,%esp
f0101527:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010152a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010152d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101530:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101533:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101536:	39 c6                	cmp    %eax,%esi
f0101538:	73 36                	jae    f0101570 <memmove+0x4f>
f010153a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010153d:	39 d0                	cmp    %edx,%eax
f010153f:	73 2f                	jae    f0101570 <memmove+0x4f>
		s += n;
		d += n;
f0101541:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101544:	f6 c2 03             	test   $0x3,%dl
f0101547:	75 1b                	jne    f0101564 <memmove+0x43>
f0101549:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010154f:	75 13                	jne    f0101564 <memmove+0x43>
f0101551:	f6 c1 03             	test   $0x3,%cl
f0101554:	75 0e                	jne    f0101564 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101556:	83 ef 04             	sub    $0x4,%edi
f0101559:	8d 72 fc             	lea    -0x4(%edx),%esi
f010155c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010155f:	fd                   	std    
f0101560:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101562:	eb 09                	jmp    f010156d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101564:	83 ef 01             	sub    $0x1,%edi
f0101567:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010156a:	fd                   	std    
f010156b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010156d:	fc                   	cld    
f010156e:	eb 20                	jmp    f0101590 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101570:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101576:	75 13                	jne    f010158b <memmove+0x6a>
f0101578:	a8 03                	test   $0x3,%al
f010157a:	75 0f                	jne    f010158b <memmove+0x6a>
f010157c:	f6 c1 03             	test   $0x3,%cl
f010157f:	75 0a                	jne    f010158b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101581:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101584:	89 c7                	mov    %eax,%edi
f0101586:	fc                   	cld    
f0101587:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101589:	eb 05                	jmp    f0101590 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010158b:	89 c7                	mov    %eax,%edi
f010158d:	fc                   	cld    
f010158e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101590:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101593:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101596:	89 ec                	mov    %ebp,%esp
f0101598:	5d                   	pop    %ebp
f0101599:	c3                   	ret    

f010159a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010159a:	55                   	push   %ebp
f010159b:	89 e5                	mov    %esp,%ebp
f010159d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015a0:	8b 45 10             	mov    0x10(%ebp),%eax
f01015a3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015aa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b1:	89 04 24             	mov    %eax,(%esp)
f01015b4:	e8 68 ff ff ff       	call   f0101521 <memmove>
}
f01015b9:	c9                   	leave  
f01015ba:	c3                   	ret    

f01015bb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015bb:	55                   	push   %ebp
f01015bc:	89 e5                	mov    %esp,%ebp
f01015be:	57                   	push   %edi
f01015bf:	56                   	push   %esi
f01015c0:	53                   	push   %ebx
f01015c1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015c4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015c7:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015ca:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015cf:	85 ff                	test   %edi,%edi
f01015d1:	74 37                	je     f010160a <memcmp+0x4f>
		if (*s1 != *s2)
f01015d3:	0f b6 03             	movzbl (%ebx),%eax
f01015d6:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015d9:	83 ef 01             	sub    $0x1,%edi
f01015dc:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01015e1:	38 c8                	cmp    %cl,%al
f01015e3:	74 1c                	je     f0101601 <memcmp+0x46>
f01015e5:	eb 10                	jmp    f01015f7 <memcmp+0x3c>
f01015e7:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01015ec:	83 c2 01             	add    $0x1,%edx
f01015ef:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01015f3:	38 c8                	cmp    %cl,%al
f01015f5:	74 0a                	je     f0101601 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01015f7:	0f b6 c0             	movzbl %al,%eax
f01015fa:	0f b6 c9             	movzbl %cl,%ecx
f01015fd:	29 c8                	sub    %ecx,%eax
f01015ff:	eb 09                	jmp    f010160a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101601:	39 fa                	cmp    %edi,%edx
f0101603:	75 e2                	jne    f01015e7 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101605:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010160a:	5b                   	pop    %ebx
f010160b:	5e                   	pop    %esi
f010160c:	5f                   	pop    %edi
f010160d:	5d                   	pop    %ebp
f010160e:	c3                   	ret    

f010160f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010160f:	55                   	push   %ebp
f0101610:	89 e5                	mov    %esp,%ebp
f0101612:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101615:	89 c2                	mov    %eax,%edx
f0101617:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010161a:	39 d0                	cmp    %edx,%eax
f010161c:	73 15                	jae    f0101633 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f010161e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101622:	38 08                	cmp    %cl,(%eax)
f0101624:	75 06                	jne    f010162c <memfind+0x1d>
f0101626:	eb 0b                	jmp    f0101633 <memfind+0x24>
f0101628:	38 08                	cmp    %cl,(%eax)
f010162a:	74 07                	je     f0101633 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010162c:	83 c0 01             	add    $0x1,%eax
f010162f:	39 d0                	cmp    %edx,%eax
f0101631:	75 f5                	jne    f0101628 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101633:	5d                   	pop    %ebp
f0101634:	c3                   	ret    

f0101635 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101635:	55                   	push   %ebp
f0101636:	89 e5                	mov    %esp,%ebp
f0101638:	57                   	push   %edi
f0101639:	56                   	push   %esi
f010163a:	53                   	push   %ebx
f010163b:	8b 55 08             	mov    0x8(%ebp),%edx
f010163e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101641:	0f b6 02             	movzbl (%edx),%eax
f0101644:	3c 20                	cmp    $0x20,%al
f0101646:	74 04                	je     f010164c <strtol+0x17>
f0101648:	3c 09                	cmp    $0x9,%al
f010164a:	75 0e                	jne    f010165a <strtol+0x25>
		s++;
f010164c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010164f:	0f b6 02             	movzbl (%edx),%eax
f0101652:	3c 20                	cmp    $0x20,%al
f0101654:	74 f6                	je     f010164c <strtol+0x17>
f0101656:	3c 09                	cmp    $0x9,%al
f0101658:	74 f2                	je     f010164c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010165a:	3c 2b                	cmp    $0x2b,%al
f010165c:	75 0a                	jne    f0101668 <strtol+0x33>
		s++;
f010165e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101661:	bf 00 00 00 00       	mov    $0x0,%edi
f0101666:	eb 10                	jmp    f0101678 <strtol+0x43>
f0101668:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010166d:	3c 2d                	cmp    $0x2d,%al
f010166f:	75 07                	jne    f0101678 <strtol+0x43>
		s++, neg = 1;
f0101671:	83 c2 01             	add    $0x1,%edx
f0101674:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101678:	85 db                	test   %ebx,%ebx
f010167a:	0f 94 c0             	sete   %al
f010167d:	74 05                	je     f0101684 <strtol+0x4f>
f010167f:	83 fb 10             	cmp    $0x10,%ebx
f0101682:	75 15                	jne    f0101699 <strtol+0x64>
f0101684:	80 3a 30             	cmpb   $0x30,(%edx)
f0101687:	75 10                	jne    f0101699 <strtol+0x64>
f0101689:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010168d:	75 0a                	jne    f0101699 <strtol+0x64>
		s += 2, base = 16;
f010168f:	83 c2 02             	add    $0x2,%edx
f0101692:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101697:	eb 13                	jmp    f01016ac <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101699:	84 c0                	test   %al,%al
f010169b:	74 0f                	je     f01016ac <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010169d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016a2:	80 3a 30             	cmpb   $0x30,(%edx)
f01016a5:	75 05                	jne    f01016ac <strtol+0x77>
		s++, base = 8;
f01016a7:	83 c2 01             	add    $0x1,%edx
f01016aa:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01016ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01016b1:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016b3:	0f b6 0a             	movzbl (%edx),%ecx
f01016b6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01016b9:	80 fb 09             	cmp    $0x9,%bl
f01016bc:	77 08                	ja     f01016c6 <strtol+0x91>
			dig = *s - '0';
f01016be:	0f be c9             	movsbl %cl,%ecx
f01016c1:	83 e9 30             	sub    $0x30,%ecx
f01016c4:	eb 1e                	jmp    f01016e4 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01016c6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01016c9:	80 fb 19             	cmp    $0x19,%bl
f01016cc:	77 08                	ja     f01016d6 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01016ce:	0f be c9             	movsbl %cl,%ecx
f01016d1:	83 e9 57             	sub    $0x57,%ecx
f01016d4:	eb 0e                	jmp    f01016e4 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01016d6:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01016d9:	80 fb 19             	cmp    $0x19,%bl
f01016dc:	77 14                	ja     f01016f2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01016de:	0f be c9             	movsbl %cl,%ecx
f01016e1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016e4:	39 f1                	cmp    %esi,%ecx
f01016e6:	7d 0e                	jge    f01016f6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01016e8:	83 c2 01             	add    $0x1,%edx
f01016eb:	0f af c6             	imul   %esi,%eax
f01016ee:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01016f0:	eb c1                	jmp    f01016b3 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01016f2:	89 c1                	mov    %eax,%ecx
f01016f4:	eb 02                	jmp    f01016f8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01016f6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01016f8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016fc:	74 05                	je     f0101703 <strtol+0xce>
		*endptr = (char *) s;
f01016fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101701:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101703:	89 ca                	mov    %ecx,%edx
f0101705:	f7 da                	neg    %edx
f0101707:	85 ff                	test   %edi,%edi
f0101709:	0f 45 c2             	cmovne %edx,%eax
}
f010170c:	5b                   	pop    %ebx
f010170d:	5e                   	pop    %esi
f010170e:	5f                   	pop    %edi
f010170f:	5d                   	pop    %ebp
f0101710:	c3                   	ret    
	...

f0101720 <__udivdi3>:
f0101720:	83 ec 1c             	sub    $0x1c,%esp
f0101723:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101727:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010172b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010172f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101733:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101737:	8b 74 24 24          	mov    0x24(%esp),%esi
f010173b:	85 ff                	test   %edi,%edi
f010173d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101741:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101745:	89 cd                	mov    %ecx,%ebp
f0101747:	89 44 24 04          	mov    %eax,0x4(%esp)
f010174b:	75 33                	jne    f0101780 <__udivdi3+0x60>
f010174d:	39 f1                	cmp    %esi,%ecx
f010174f:	77 57                	ja     f01017a8 <__udivdi3+0x88>
f0101751:	85 c9                	test   %ecx,%ecx
f0101753:	75 0b                	jne    f0101760 <__udivdi3+0x40>
f0101755:	b8 01 00 00 00       	mov    $0x1,%eax
f010175a:	31 d2                	xor    %edx,%edx
f010175c:	f7 f1                	div    %ecx
f010175e:	89 c1                	mov    %eax,%ecx
f0101760:	89 f0                	mov    %esi,%eax
f0101762:	31 d2                	xor    %edx,%edx
f0101764:	f7 f1                	div    %ecx
f0101766:	89 c6                	mov    %eax,%esi
f0101768:	8b 44 24 04          	mov    0x4(%esp),%eax
f010176c:	f7 f1                	div    %ecx
f010176e:	89 f2                	mov    %esi,%edx
f0101770:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101774:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101778:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010177c:	83 c4 1c             	add    $0x1c,%esp
f010177f:	c3                   	ret    
f0101780:	31 d2                	xor    %edx,%edx
f0101782:	31 c0                	xor    %eax,%eax
f0101784:	39 f7                	cmp    %esi,%edi
f0101786:	77 e8                	ja     f0101770 <__udivdi3+0x50>
f0101788:	0f bd cf             	bsr    %edi,%ecx
f010178b:	83 f1 1f             	xor    $0x1f,%ecx
f010178e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101792:	75 2c                	jne    f01017c0 <__udivdi3+0xa0>
f0101794:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101798:	76 04                	jbe    f010179e <__udivdi3+0x7e>
f010179a:	39 f7                	cmp    %esi,%edi
f010179c:	73 d2                	jae    f0101770 <__udivdi3+0x50>
f010179e:	31 d2                	xor    %edx,%edx
f01017a0:	b8 01 00 00 00       	mov    $0x1,%eax
f01017a5:	eb c9                	jmp    f0101770 <__udivdi3+0x50>
f01017a7:	90                   	nop
f01017a8:	89 f2                	mov    %esi,%edx
f01017aa:	f7 f1                	div    %ecx
f01017ac:	31 d2                	xor    %edx,%edx
f01017ae:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017b2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017b6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017ba:	83 c4 1c             	add    $0x1c,%esp
f01017bd:	c3                   	ret    
f01017be:	66 90                	xchg   %ax,%ax
f01017c0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01017ca:	89 ea                	mov    %ebp,%edx
f01017cc:	2b 44 24 04          	sub    0x4(%esp),%eax
f01017d0:	d3 e7                	shl    %cl,%edi
f01017d2:	89 c1                	mov    %eax,%ecx
f01017d4:	d3 ea                	shr    %cl,%edx
f01017d6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017db:	09 fa                	or     %edi,%edx
f01017dd:	89 f7                	mov    %esi,%edi
f01017df:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017e3:	89 f2                	mov    %esi,%edx
f01017e5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01017e9:	d3 e5                	shl    %cl,%ebp
f01017eb:	89 c1                	mov    %eax,%ecx
f01017ed:	d3 ef                	shr    %cl,%edi
f01017ef:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017f4:	d3 e2                	shl    %cl,%edx
f01017f6:	89 c1                	mov    %eax,%ecx
f01017f8:	d3 ee                	shr    %cl,%esi
f01017fa:	09 d6                	or     %edx,%esi
f01017fc:	89 fa                	mov    %edi,%edx
f01017fe:	89 f0                	mov    %esi,%eax
f0101800:	f7 74 24 0c          	divl   0xc(%esp)
f0101804:	89 d7                	mov    %edx,%edi
f0101806:	89 c6                	mov    %eax,%esi
f0101808:	f7 e5                	mul    %ebp
f010180a:	39 d7                	cmp    %edx,%edi
f010180c:	72 22                	jb     f0101830 <__udivdi3+0x110>
f010180e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101812:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101817:	d3 e5                	shl    %cl,%ebp
f0101819:	39 c5                	cmp    %eax,%ebp
f010181b:	73 04                	jae    f0101821 <__udivdi3+0x101>
f010181d:	39 d7                	cmp    %edx,%edi
f010181f:	74 0f                	je     f0101830 <__udivdi3+0x110>
f0101821:	89 f0                	mov    %esi,%eax
f0101823:	31 d2                	xor    %edx,%edx
f0101825:	e9 46 ff ff ff       	jmp    f0101770 <__udivdi3+0x50>
f010182a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101830:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101833:	31 d2                	xor    %edx,%edx
f0101835:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101839:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010183d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101841:	83 c4 1c             	add    $0x1c,%esp
f0101844:	c3                   	ret    
	...

f0101850 <__umoddi3>:
f0101850:	83 ec 1c             	sub    $0x1c,%esp
f0101853:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101857:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010185b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010185f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101863:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101867:	8b 74 24 24          	mov    0x24(%esp),%esi
f010186b:	85 ed                	test   %ebp,%ebp
f010186d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101871:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101875:	89 cf                	mov    %ecx,%edi
f0101877:	89 04 24             	mov    %eax,(%esp)
f010187a:	89 f2                	mov    %esi,%edx
f010187c:	75 1a                	jne    f0101898 <__umoddi3+0x48>
f010187e:	39 f1                	cmp    %esi,%ecx
f0101880:	76 4e                	jbe    f01018d0 <__umoddi3+0x80>
f0101882:	f7 f1                	div    %ecx
f0101884:	89 d0                	mov    %edx,%eax
f0101886:	31 d2                	xor    %edx,%edx
f0101888:	8b 74 24 10          	mov    0x10(%esp),%esi
f010188c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101890:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101894:	83 c4 1c             	add    $0x1c,%esp
f0101897:	c3                   	ret    
f0101898:	39 f5                	cmp    %esi,%ebp
f010189a:	77 54                	ja     f01018f0 <__umoddi3+0xa0>
f010189c:	0f bd c5             	bsr    %ebp,%eax
f010189f:	83 f0 1f             	xor    $0x1f,%eax
f01018a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a6:	75 60                	jne    f0101908 <__umoddi3+0xb8>
f01018a8:	3b 0c 24             	cmp    (%esp),%ecx
f01018ab:	0f 87 07 01 00 00    	ja     f01019b8 <__umoddi3+0x168>
f01018b1:	89 f2                	mov    %esi,%edx
f01018b3:	8b 34 24             	mov    (%esp),%esi
f01018b6:	29 ce                	sub    %ecx,%esi
f01018b8:	19 ea                	sbb    %ebp,%edx
f01018ba:	89 34 24             	mov    %esi,(%esp)
f01018bd:	8b 04 24             	mov    (%esp),%eax
f01018c0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018c4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018c8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018cc:	83 c4 1c             	add    $0x1c,%esp
f01018cf:	c3                   	ret    
f01018d0:	85 c9                	test   %ecx,%ecx
f01018d2:	75 0b                	jne    f01018df <__umoddi3+0x8f>
f01018d4:	b8 01 00 00 00       	mov    $0x1,%eax
f01018d9:	31 d2                	xor    %edx,%edx
f01018db:	f7 f1                	div    %ecx
f01018dd:	89 c1                	mov    %eax,%ecx
f01018df:	89 f0                	mov    %esi,%eax
f01018e1:	31 d2                	xor    %edx,%edx
f01018e3:	f7 f1                	div    %ecx
f01018e5:	8b 04 24             	mov    (%esp),%eax
f01018e8:	f7 f1                	div    %ecx
f01018ea:	eb 98                	jmp    f0101884 <__umoddi3+0x34>
f01018ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018f0:	89 f2                	mov    %esi,%edx
f01018f2:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018f6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018fa:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018fe:	83 c4 1c             	add    $0x1c,%esp
f0101901:	c3                   	ret    
f0101902:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101908:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010190d:	89 e8                	mov    %ebp,%eax
f010190f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101914:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101918:	89 fa                	mov    %edi,%edx
f010191a:	d3 e0                	shl    %cl,%eax
f010191c:	89 e9                	mov    %ebp,%ecx
f010191e:	d3 ea                	shr    %cl,%edx
f0101920:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101925:	09 c2                	or     %eax,%edx
f0101927:	8b 44 24 08          	mov    0x8(%esp),%eax
f010192b:	89 14 24             	mov    %edx,(%esp)
f010192e:	89 f2                	mov    %esi,%edx
f0101930:	d3 e7                	shl    %cl,%edi
f0101932:	89 e9                	mov    %ebp,%ecx
f0101934:	d3 ea                	shr    %cl,%edx
f0101936:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010193b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010193f:	d3 e6                	shl    %cl,%esi
f0101941:	89 e9                	mov    %ebp,%ecx
f0101943:	d3 e8                	shr    %cl,%eax
f0101945:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010194a:	09 f0                	or     %esi,%eax
f010194c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101950:	f7 34 24             	divl   (%esp)
f0101953:	d3 e6                	shl    %cl,%esi
f0101955:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101959:	89 d6                	mov    %edx,%esi
f010195b:	f7 e7                	mul    %edi
f010195d:	39 d6                	cmp    %edx,%esi
f010195f:	89 c1                	mov    %eax,%ecx
f0101961:	89 d7                	mov    %edx,%edi
f0101963:	72 3f                	jb     f01019a4 <__umoddi3+0x154>
f0101965:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101969:	72 35                	jb     f01019a0 <__umoddi3+0x150>
f010196b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010196f:	29 c8                	sub    %ecx,%eax
f0101971:	19 fe                	sbb    %edi,%esi
f0101973:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101978:	89 f2                	mov    %esi,%edx
f010197a:	d3 e8                	shr    %cl,%eax
f010197c:	89 e9                	mov    %ebp,%ecx
f010197e:	d3 e2                	shl    %cl,%edx
f0101980:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101985:	09 d0                	or     %edx,%eax
f0101987:	89 f2                	mov    %esi,%edx
f0101989:	d3 ea                	shr    %cl,%edx
f010198b:	8b 74 24 10          	mov    0x10(%esp),%esi
f010198f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101993:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101997:	83 c4 1c             	add    $0x1c,%esp
f010199a:	c3                   	ret    
f010199b:	90                   	nop
f010199c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a0:	39 d6                	cmp    %edx,%esi
f01019a2:	75 c7                	jne    f010196b <__umoddi3+0x11b>
f01019a4:	89 d7                	mov    %edx,%edi
f01019a6:	89 c1                	mov    %eax,%ecx
f01019a8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f01019ac:	1b 3c 24             	sbb    (%esp),%edi
f01019af:	eb ba                	jmp    f010196b <__umoddi3+0x11b>
f01019b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019b8:	39 f5                	cmp    %esi,%ebp
f01019ba:	0f 82 f1 fe ff ff    	jb     f01018b1 <__umoddi3+0x61>
f01019c0:	e9 f8 fe ff ff       	jmp    f01018bd <__umoddi3+0x6d>
