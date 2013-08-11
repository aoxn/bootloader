#define ROOT_CNT 0x1E0

.code16
.section .text
.globl start
start:	
	jmp _start
	nop
BPB:	
MANUFACTRUE:
	.ascii "DUDU    "
BYTE_PER_SEC:
	.word 0x200
SECS_PER_CLUS:
	.byte 0x1
RSVED_SEC_CNT:
	.word 0x1
FAT_NUMS:
	.byte 0x02
ROOT_ENTRY_CNT:
	.word ROOT_CNT
TLT_SECS:
	.word 0x2fff
MEDIA_DESC:
	.byte 0xF8
SECS_PER_FAT:
	.word 0x10
SECS_PER_TRACK:
	.word 0x32
HEADS_CNT:
	.word 0x02
HIDDEN_SECS:
	.long 0x0
TTL_SECS_32:
	.long 0x0

DRIVE_NUM:
	.byte 0x0
RESERVED:
	.byte 0x0
EXPAND_TAG:
	.byte 0x29
VOL_LABEL:
	.ascii "dudu"
VOL_ID:
	.long 0x0
FILE_SYSTEM_TYPE:
	.ascii "FAT16  "
BOOT_FILE:
	.ascii "MAKEFILETXT"
#define DATA_AREA 0x9000
#define STACK_START 0x7c00
#define ROOT_DIR_SEC_START 21
#define ROOT_DIR_SECS (ROOT_CNT*32+511)/512	
#define DATA_SEC_START (ROOT_DIR_SEC_START+ROOT_DIR_SECS)
#define SETUP_SEG 0x4000

_start:
real_start:	
	mov %cs,%ax
	mov %ax,%es
	mov %ax,%ds
	mov %ax,%ss


	mov $loading,%si
	call print_msg
	
	mov $STACK_START,%bp
 	mov $STACK_START,%sp


	mov $DATA_AREA,%ebx
	mov $ROOT_DIR_SEC_START,%eax
	mov $ROOT_DIR_SECS,%ecx
	call read_secs
	

	mov $DATA_AREA,%esi
	mov $BOOT_FILE,%edi
	xor %ebx,%ebx
	mov $0xb,%cx
	call find_file


	push %eax
	mov $0x1,%eax
	mov $DATA_AREA,%ebx
	mov $0x09,%ecx
	call read_secs
	pop %eax
	

	mov $SETUP_SEG,%ebx
read_loader:
	push %ebx
	push %eax
	cmp $0xffff,%eax
	je 2f
	add $DATA_SEC_START,%eax
	mov $0x1,%ecx
	call read_secs
	pop %eax
	mov $DATA_AREA,%ebx
	call find_next_sec
	pop %ebx
	add $0x200,%ebx
	jmp read_loader
2:
	add $0x08,%esp
	mov $SETUP_SEG,%si
	call print_msg
	jmp .

1:
	mov $0x0e,%ah
	movw $0x0010,%bx
	int $0x10
print_msg:
	lodsb
	cmpb $0,%al
	jne 1b
	ret
2:
	mov $0xb,%cx
	inc %bx
	mov $0x20,%eax
	mul %bx
	add %eax,%esi
	
	cmp $ROOT_CNT,%bx
	jge finish
	mov $BOOT_FILE,%edi
	mov $0x0b,%cx
	jmp find_file
finish:
	mov $0,%ax
	ret
find_file:
	lodsb
	dec %esi
	cmpb %al,(%di)
	jne 2b
	inc %esi
	inc %di
	sub $0x1,%cx
	cmp $0,%cx
	jne find_file
	add $0x0f,%si
	mov (%si),%ax
	ret

find_next_sec:
	mov %eax,%edx
	
	mov $0x03,%ecx
	mul %cl
	inc %eax
	shr $0x01,%eax
	
	mov %eax,%esi
	and $0x01,%edx
	cmp $0,%edx
	je EVEN
	mov (%bx,%si),%ch
	mov -1(%bx,%si),%cl
	shrl $0x04,%ecx
	jmp DONE
EVEN:
	mov (%bx,%si),%cl
	mov -1(%bx,%si),%ch
	
	and $0x00000fff,%ecx
DONE:	
	mov %ecx,%eax
	ret
	
read_secs:
	xor %edx,%edx
	push %cx
	movb SECS_PER_TRACK,%cl
	div %cl

	mov %ah,%cl
	inc %cl

	mov %al,%ch
	shrb $1,%ch

	mov %al,%dh
	andb $0x01,%dh
	xor %dl,%dl
	pop %ax
	
	mov $0x02,%ah
	int $0x13
	jc error
	
	mov $success,%si
	call print_msg
	ret
error:
	
	push %ax
	push %dx
	
	mov $error_msg,%si
	call print_msg
	pop %dx
	pop %ax
	nop
success:	.ascii ".. \0"
loading:	.ascii "SpaceDUDU:loading...\r\n\0"
error_msg: 	.ascii "SpaceDUDU:error ... try again\r\n\0"

.org 510
.word 0xaa55