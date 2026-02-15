;Good luck 
; EAX return ; EBX ECX EDX STACK args ; EDI ESI arrays/stringops ; EBP ESP don't even think about it ; EFLAGS NO ; EIP VERY NO


org 0x7C00
[bits 16]

_start:
        mov ax, 0x0000 ; zero out segments
        mov es, ax
        mov ds, ax ; hi :)
        mov ss, ax

        in al, 0x92 ; enable A20 line
        or al, 2
        out 0x92, al
        
        mov [bootdrive], dl ; save type of bootdrive (hdd, floppy)
        ;mov cs
        mov sp, 0x7C00 ; mov ebp / ss to 0x7C00
        mov ah, 0x0E ; begin to print
        mov si, stackup
.printstack: ; loop confirm stack initialized and all segments zero.
        lodsb
        int 0x10
        test al, al
        jnz .printstack

        mov ax, 0 ; zero out ES
        mov es, ax

        mov ax, 0x4F01 ; Set up VESA
        mov cx, 0x114
        mov di, 0x1000
        int 0x10
        cmp ax, 0x004F
        jne vesa_fail

        mov ax, 0x4F02 ; Change mode to VESA
        mov bx, 0x4114
        int 0x10
        cmp ax, 0x004F
        jne vesa_failtwo
        
        mov eax, [0x1028] ; store VESA details
        mov [framebuffer], eax
        mov bx, [0x1010]
        mov [pitch], bx
                
        xor ax, ax ; zero out DS
        mov ds, ax
        
        xor ax, ax ; Get type of boot medium and prepare to read sectors
        mov dl, [bootdrive]
        int 0x13
        cmp byte [bootdrive], 0x80
        jae .hdd

        xor ax, ax ; zero out ax and prepare floppy
        int 0x13
        
        mov ah, 0x02 ; read 30 sectors
        mov al, 30
        xor ch, ch
        xor dh, dh
        mov cl, 0x02
        mov dl, [bootdrive]
        xor bx, bx
        mov es, bx
        mov bx, 0x7E00
        int 0x13
        jc floppyfail
        jmp .ramloaded
.hdd:
        mov ah, 0x42 ; read from HDD
        mov dl, [bootdrive]
        mov si, disk_packet
        int 0x13
        jc diskfail
        
.ramloaded: ; Load Global Descriptor Table
        cli ; this is it, boys
        lgdt [gdt_descriptor]
        mov eax, cr0
        or eax, 0x1
        mov cr0, eax                
        jmp 0x08:0x7E00

halting:
        mov si, genfail ; print general failure message and halt
        mov ah, 0x0E
.looped:
        lodsb
        int 0x10
        test al, al
        jnz .looped
        hlt
        jmp $


floppyfail: ; floppy read failure and halt
        mov ah, 0x0E
        mov si, flop
.floploop:
        lodsb
        int 0x10
        test al, al
        jnz .floploop
        jmp halting
diskfail: ; disk read failure and halt
        mov ah, 0x0E
        mov si, disk
.diskloop:
        lodsb
        int 0x10
        test al, al
        jnz .diskloop
        jmp halting

vesa_fail: ; vesa fail and halt
        mov ax, 0x0E
        mov si, vfail
.failit:
        lodsb
        int 0x10
        test al, al
        jnz .failit
        hlt
        jmp $

vesa_failtwo: ; vesa modeswitch fail and halt
        mov ax, 0x0E
        mov si, othervfail
.failtwo:
        lodsb
        int 0x10
        test al, al
        jnz .failtwo
        hlt
        jmp $

bootdrive db 0
othervfail db "VESA FAIL 2", 0x0A, 0x0D, 0x00
vfail db "VESA FAIL", 0x0A, 0x0D, 0x00
stackup db "SEGMENT 0 STACK UP", 0x0A, 0x0D, 0x00
flop db "READ FAILURE FLOPPY", 0x0A, 0x0D, 0x00
disk db "READ FAILURE DISK", 0x0A, 0x0D, 0x00
printframebuffers db "FRAMEBUFFER SET", 0x0A, 0x0D, 0x00
genfail db "GENERAL FAILURE",0x0A,0x0D,0x00


gdt_start dq 0x0
gdt_code:
        dw 0xFFFF, 0x0000
        db 0x00, 0x9A, 0xCF, 0x00
gdt_data:
        dw 0xFFFF
        dw 0x0000
        db 0x00, 0x92, 0xCF, 0x00
gdt_end:

gdt_descriptor:
        dw gdt_end - gdt_start - 1
        dd gdt_start

align 4
disk_packet:
        db 0x10
        db 0x00
        dw 1
        dw 0x8000
        dw 0x0000
        dq 95
align 4
framebuffer dd 0
align 4
pitch dw 0
times 510 - ($ - $$) db 0
dw 0xAA55
; starts at 7E00
; 16 BIT SECTION END --




 
; 32 BIT SECTION START --
[bits 32]
%include "macros.inc"


%macro NOERROR 1
isr%1:
        push 0
        push %1
        jmp default_handler
%endmacro

%macro ERRORCODE 1
isr%1:
        push %1
        jmp default_handler
%endmacro


%macro SCREENFILL 1
        mov edi, [framebuffer]
        mov ecx, (800 * 600 * 2)
        mov eax, %1
        rep stosd
%endmacro
%macro PRINTMSG 3
        mov esi, %1
        mov eax, %2
        mov ebx, %3
        call printstring
%endmacro
%macro TERMINATE 0
        hlt
        jmp $
%endmacro

  stagetwostart: ; set segments
        mov ax, 0x10
        mov ss, ax
        mov ds, ax
        mov es, ax
        mov gs, ax
        mov fs, ax
        mov esp, 0x08000000 ; stack at 128 MB
        and esp, 0xFFFFFFF0
        mov ebp, esp
        
        mov edi, idt_buffer
        mov esi, isr_stub
        mov ecx, 256 ; for now. 256 later. 
.idtloop:
        mov eax, [esi] ; generate IDT
        mov [edi], ax
        mov word [edi + 2], 0x08
        mov word [edi + 4], 0x00
        mov byte [edi + 5], 0x8E
        shr eax, 16
        mov word [edi + 6], ax
        add esi, 4
        add edi, 8
        loop .idtloop

        lidt [idt_descriptor]

picmap: ; remap PIC
        mov al, 0x11
        out 0x20, al
        out 0xA0, al
        mov al, 0x20
        out 0x20, al
        mov al, 0x28
        out 0xA0, al
        mov al, 0x04
        out 0x21, al
        mov al, 0x02
        out 0xA1, al
        mov al, 0x01
        out 0x21, al
        out 0xA1, al
        xor al, al
        out 0x21, al
        out 0xA1, al
        ; set timer frequency
        mov al, 36
        out 0x43, al
        mov ax, 0x2E9B
        out 0x40, al
        mov al, ah
        out 0x40, al


        ; paging :)
        mov edi, pagetables
        mov ecx, 32768
        xor eax, eax
.pageloop:
        mov edx, eax
        or edx, 0x3
        mov [edi], edx
        add edi, 4
        add eax, 4096
        loop .pageloop

        mov edi, pagedir
        mov esi, pagetables
        mov ecx, 32
.pagelink:
        mov eax, esi
        or eax, 0x3
        mov [edi], eax
        add edi, 4
        add esi, 4096
        loop .pagelink

        mov eax, pagedir
        mov cr3, eax

        mov eax, cr0
        or eax, 0x80000000
        mov cr0, eax
        
        movzx eax, word [pitch]
        shl eax, 8
        add eax, 16
        mov bl, 0x20
        mov dx, 0xFADE
        mov ecx, 48

        cld
        mov al, 0x20
       
        movzx ebx, word [pitch]
        shl ebx, 4
        sti

        ;call clearscreen ; clear screen
        
        
        mov eax, 16 ; print diagnostic messages
        mov esi, testmessage
        add eax, ebx
        mov ebx, 0x0F80
        ;mov [currentoffset], eax
        call printstring

        mov dx, 0x3F2
        mov al, 0x0C
        out dx, al ; kill floppy

        xor al, al
        out dx, al ; reset floppy reader. 

        mov esi, idtupmsg
        mov ebx, 0x0F80
        mov eax, [initoffset]
        call printstring

        call clearscreen ; clear screen. If all goes well, diagnostic messages needn't be printed.

         
        hlt
        jmp $

align 16
idt_descriptor:
        dw (256 * 8) - 1
        dd idt_buffer
        
idt_buffer times 2048 db 0       

NOERROR 0
NOERROR 1
NOERROR 2
NOERROR 3
NOERROR 4
NOERROR 5
NOERROR 6
NOERROR 7
ERRORCODE 8
NOERROR 9
ERRORCODE 10
ERRORCODE 11
ERRORCODE 12
ERRORCODE 13
ERRORCODE 14
NOERROR 15
NOERROR 16
ERRORCODE 17
NOERROR 18
NOERROR 19
NOERROR 20
ERRORCODE 21
NOERROR 22
NOERROR 23
NOERROR 24
NOERROR 25
NOERROR 26
NOERROR 27
NOERROR 28
NOERROR 29
NOERROR 30
NOERROR 31

%assign i 32
%rep 224
NOERROR i
%assign i i+1
%endrep

isr_stub:
        dd isr0, isr1, isr2, isr3, isr4, isr5, isr6, isr7, isr8, isr9, isr10, isr11, isr12, isr13, isr14, isr15, isr16, isr17, isr18
        dd isr19, isr20, isr21, isr22, isr23, isr24, isr25, isr26, isr27, isr28, isr29, isr30, isr31
        ;dd keyboard_handler
        %assign i 32
        %rep 224
        dd isr%+i
        %assign i i+1
        %endrep

%if ($ - isr_stub) != (256 * 4)
        %error "Guess who messed up the IDT stubs? You did! :)"
%endif



default_handler:
        pushfd
        cli
        pushad
        cld
        ; set up handler
        
        mov eax, [esp + 36] ; get number
        mov ebx, [esp + 40] ; get code

        mov ecx, [handlers + eax * 4]
        call ecx        
        
        cmp eax, 32
        jb .no_eoi
        cmp eax, 47
        ja .no_eoi  
        mov al, 0x20
        out 0x20, al
        out 0xA0, al
        .no_eoi:
        popad
        add esp, 8
        popfd
        iretd

handlers:
        dd DivZero, SingleStep, HardwareFailure, BreakPoint, OverFlow, ExceedsBounds, InvalidOpcode, DevNotAvail, DoubleFault, NULLFAULT, TSSCorrupt, InvalidSegment, StackFault, GPFault, Page, NULLFAULT, FPUError, AlignFault, MachineFault, SimdFault
        times 12 dd NULLFAULT ; 11
        dd timer_handler ; 0x20
        dd keyboard_handler ; 0x21
        times 7 dd NULLFAULT ;0x22-0x28
        dd stdprint ; int 0x29

stdprint:
        ; Atomic wrapper for printstring. Asynchronous. Writes to charbuffer instead of screen, technically
        ; ESI string ECX length (if ecx is -1), goes to null termination
        bt [writeactiveflag], 0
        jc stdprint
        bts [writeactiveflag], 0
        pushad
        mov edi, keyboardringbuffer
        mov ebx, dword [newringoffset]
        mov edx, dword [endoffset]
        add edi, ebx
        cmp ecx, 0xFFFFFFFF
        je .nullterm
        rep movsb
        add dword [newringoffset], ecx
        call printscreen
        mov edx, [newringoffset]
        mov [endoffset], edx
        popad
        btr [writeactiveflag], 0
        ret
.nullterm:
        mov al, byte [esi]
        test al, al
        jz .finish
        inc esi
        mov byte [edi], al
        inc edi
        inc dword [newringoffset]
        jmp .nullterm
.finish:
        call printscreen
        popad
        btr [writeactiveflag], 0
        ret
        

timer_handler:
        add dword [clocktimer], 1
        adc dword [clocktimer + 4], 0
        ;call printscreen ; GET RID OF THIS LATER
        ret

DivZero:
        mov edi, [framebuffer]
        mov ecx, (800 * 600 * 2) / 4
        mov eax, 0x00000000
        rep stosd
        mov esi, divzeromsg
        xor eax, eax
        mov ebx, 0xF800
        call printstring
        hlt
        jmp $ ; CHANGE THIS LATER
SingleStep:
        mov edi, [framebuffer]
        mov ecx, (800 * 600 * 2) / 4
        mov eax, 0x00000000
        rep stosd
        mov esi, singlestepmsg
        xor eax, eax
        mov ebx, 0xF800
        call printstring
        hlt
        jmp $

HardwareFailure:
        mov edi, [framebuffer]
        mov ecx, (800 * 600 * 2) / 4
        mov eax, 0x0000
        rep stosd
        mov esi, hardwarefailuremsg
        xor eax, eax
        mov ebx, 0xF800
        call printstring
        hlt
        jmp $

BreakPoint:
        ret ; ADD SOMETHING MORE HERE TODO
OverFlow:
        mov edi, [framebuffer]
        mov ecx, (800 * 600 * 2) / 4
        mov eax, 0x000;00000
        rep stosd
        mov esi, overflowmsg
        xor eax, eax
        mov ebx, 0xF800
        call printstring
        hlt
        jmp $

ExceedsBounds:
        SCREENFILL 0x000;00000
        PRINTMSG exceedsboundsmsg, 0, 0xF800
        hlt
        jmp $

InvalidOpcode:
        SCREENFILL 0x0000;0000
        PRINTMSG invalidopcodemsg, 0, 0xF800
        TERMINATE
DevNotAvail:
        SCREENFILL 0x00000000
        PRINTMSG devnotavailmsg, 0, 0xF800
        TERMINATE
DoubleFault:
        SCREENFILL 0x00000000
        PRINTMSG doublefaultmsg, 0, 0xF800
        ret ; yes, going back
TSSCorrupt:
        SCREENFILL 0x00000000
        PRINTMSG tsscorruptmsg, 0, 0xF800
        TERMINATE
InvalidSegment:
        SCREENFILL 0x00000000
        PRINTMSG invsegmsg, 0, 0xF800
        TERMINATE
StackFault:
        SCREENFILL 0x00000000
        PRINTMSG stackfaultmsg, 0, 0xF800
        TERMINATE
GPFault:
        SCREENFILL 0x00000000
        PRINTMSG gpfaultmsg, 0, 0xF800
        TERMINATE
Page:
        SCREENFILL 0x00000000
        PRINTMSG pagefaultmsg, 0, 0xF800
        ret ; I don't yet have paging so who gives a care
FPUError:
        SCREENFILL 0x00000000
        PRINTMSG fpuerrormsg, 0, 0xF800
        ret
AlignFault:
        SCREENFILL 0x00000000
        PRINTMSG alignfaultmsg, 0, 0xF800
        ret
MachineFault:
        SCREENFILL 0x00000000
        PRINTMSG machinefaultmsg, 0, 0xF800
        TERMINATE
SimdFault:
        SCREENFILL 0x00000000
        PRINTMSG simdfaultmsg, 0, 0xF800
        ret
NULLFAULT:
        ret
exceedsboundsmsg db "Bounds overflow?!", 0x0D, 0x0A, 0x00
invalidopcodemsg db "Invalid Opcode", 0x0D, 0x0A, 0x00
devnotavailmsg db "Device Not Available", 0x0D, 0x0A, 0x00
doublefaultmsg db "DOUBLE FAULT RETURNING", 0x0D, 0x0A, 0x00
tsscorruptmsg db "Invalid TSS", 0x0D, 0x0A, 0x00
invsegmsg db "Invalid Segment selectors", 0x0D, 0x0A, 0x00
stackfaultmsg db "Bad Stack", 0x0D, 0x0A, 0x00
gpfaultmsg db "General Protection Fault", 0x0D, 0x0A, 0x00
pagefaultmsg db "Page fault", 0x0D, 0x0A, 0x00
fpuerrormsg db "FPU Error", 0x0D, 0x0A, 0x00
alignfaultmsg db "Alignment Fault", 0x0D, 0x0A, 0x00
machinefaultmsg db "Machine Check Fatal Error", 0x0D, 0x0A, "Have fun :)", 0x0D, 0x0A, 0x00
simdfaultmsg db "SIMD fault", 0x0D, 0x0A, 0x00

         
overflowmsg db "Who the actual mess uses INTO?", 0x0D, 0x0A, 0x00

hardwarefailuremsg db "Critical Hardware Failure", 0x0D, 0x0A, 0x00
singlestepmsg db "SingleStep", 0x0D, 0x0A, 0x00

printchar: ; well mess I guess we're doing it the hard way. character in al, frame offset in ebx
        pushfd
        pushad
        cli

        movzx eax, byte [printarguments + 4]
        mov ebx, dword [printarguments]
        sub al, 0x20
.pitchedmaybe:
        mov edi, [framebuffer]
        shl eax, 2
        add edi, ebx
        lea esi, [chars + eax*8] ; get address to char and framebuffer

        xor ecx, ecx

.printsetup:
        xor eax, eax
        xor edx, edx
        mov ax, word [esi + ecx*2]
.byrow:
        ;mov ax, 0xFFFF
        mov ebx, 15
        sub ebx, edx      
        bt eax, ebx ; ? eax, edx
        jc .printpix
.printed:
        inc edx
        cmp edx, 16
        jle .byrow ; JLE
        inc ecx
        cmp ecx, 16
        jle .preseter ; JLE

        popad
        popfd
        ret

.preseter:
        push ebx
        movzx ebx, word [pitch]
        add edi, ebx
        pop ebx
        jmp .printsetup
        

.printpix:
        push ebx
        mov bx, word [printarguments + 5]
        mov word [edi + edx*2], 0xFFFF ;bx
        pop ebx
        jmp .printed        

printstring: ; takes string in esi, offset in eax, color in ebx, goes to 0x00. Supports 0x0A and 0x0D.
        pushfd
        cli
        pushad
        mov dword [printarguments], eax
        cld
        mov [initoffset], eax
        xor ecx, ecx
        mov word [printarguments + 5], bx
.loop:
        lodsb
        test al, al
        jz .endprint
        cmp al, 0x0D
        je .cr
        cmp al, 0x0A
        je .newline
        ;cmp al, 0x20
        ;je .space
        mov byte [printarguments + 4], al
        call printchar
        add dword [printarguments], 32
        jmp .loop
        

.cr:
        mov ecx, [initoffset]
        mov dword [printarguments], ecx
        jmp .loop
.newline:
        movzx ecx, word [pitch]
        movzx edx, word [pitch]
        shl ecx, 4
        shl edx, 1
        add ecx, edx
        add dword [printarguments], ecx
        add dword [initoffset], ecx
        jmp .loop
.space:
        add dword [printarguments], 32
        ;inc esi ; ????
        jmp .loop
.endprint:
        popad
        popfd
        ret

times 16 db 0

keyboard_handler:
        in al, 0x60
        cmp al, 0xAA
        je unshift
        cmp al, 0xB6
        je unshift
        cmp al, 0x80
        jae skipkeyboard
        cmp al, 0x2A
        je shift
        cmp al, 0x36
        je shift
        cmp al, 0x0E
        je backspace
        cmp al, 0x1C
        je skipperkb ; cmp to ENTER
        ;cmp al, 0xE0
        ;je extension
        cmp byte [iscapitol], 0
        jnz uppercase
        movzx eax, al
        ; cursor movement
        movzx eax, byte [chartab + eax]
 
possiblyshifted:
        push ebx
        mov ebx, [newringoffset] ; newringoffset
        mov byte [keyboardringbuffer + ebx], al
        inc dword [newringoffset] ; newringoffset
        mov byte [keyboardringbuffer + ebx + 1], 0
        pop ebx
skipkeyboard:

        mov al, 0x20 ; Send EOI
        out 0x20, al
        mov word [printarguments + 5], 0xFFFF
        call printscreen ; print characters. We'll see how this goes.
        ret
skipperkb:
        mov ebx, [newringoffset] ; newringoffset
	mov byte [keyboardringbuffer + ebx], 0x0D
	mov byte [keyboardringbuffer + ebx + 1], 0x0A
	mov byte [keyboardringbuffer + ebx + 2], 0x00
	add dword [newringoffset], 2
        mov al, 0x20
        out 0x20, al
        call printscreen
        ret

uppercase:
        
        movzx eax, al
        movzx eax, byte [chartabshift + eax]
        push ebx
        mov ebx, [newringoffset] ; newringoffset
        mov byte [keyboardringbuffer + ebx], al
        inc dword [newringoffset] ; newringoffset
        mov byte [keyboardringbuffer + ebx + 1], 0
        pop ebx
        jmp skipkeyboard

extension:
        ; TEMP SO INCREDIBLY TEMP
        in al, 0x60
        cmp al, 0

shift: ; this has some problems
        mov byte [iscapitol], 1
        jmp skipkeyboard

unshift:
        mov byte [iscapitol], 0
        jmp skipkeyboard
backspace:
        push edi
        mov ecx, [newringoffset] ; endoffset 
        mov byte [keyboardringbuffer + ecx  - 1], 0x20 ; overwrite previous byte of kbringbuffer
        ;sub [newringoffset], 32
        dec dword [newringoffset] ; mov newringoffset back one
        sub dword [printarguments], 32 ; no idea
        mov edi, [framebuffer]
        mov ebx, [printarguments]
        xor edx, edx
        add edi, ebx
.backouterloop:
        xor ecx, ecx
.backinnerloop:
        mov dword [edi + ecx * 2], 0x0000
        inc ecx
        cmp ecx, 16
        jle .backinnerloop
        movzx ebx, word [pitch]
        inc edx
        add edi, ebx
        cmp edx, 16
        jle .backouterloop
        pop edi
        mov al, 0x20
        out 0x20, al
        ret        
        
clearscreen:
        pushfd
        cli
        pushad
        mov edi, [framebuffer]
        mov ecx, (600 * 800) / 2
        mov eax, 0x00000000
        rep stosd
        mov dword [newringoffset], 0
        mov dword [endoffset], 0
        mov byte [keyboardringbuffer + 1961], 0
        mov dword [initoffset], 0

        mov edi, keyboardringbuffer
        mov ecx, 1962
        mov eax, 0x00
        rep stosb

        mov esi, cmdprmpt ; print cmdprmpt icon
        mov ebx, 0xF800
        mov eax, 0
        call printstring
        add dword [initoffset], 32
        
        popad
        popfd
        ret

printscreen:
        pushad

        
        
        mov esi, keyboardringbuffer
        ;mov eax, [initoffset] ; ???? initoffset?
        add esi, [endoffset] ; TEMP
        mov ebx, 0x0F80
        call printstring
        mov edi, [endoffset]
        mov [initoffset], edi ; TEMP
        popad
        ret

        errorcodes dd 0 ; jmp over
printarguments: ; qword
        dd 0 ; offset
        db 0 ; ASCII code
        dw 0 ; color
        db 0 ; padding / counter

cmdparser:
        pushad
        test eax, eax
        jnz .entered
        cld
        mov edi, cmdbuffer
        xor eax, eax
        mov ecx, 32
        rep stosb
        
        
        mov esi, keyboardringbuffer
        mov ebx, [endoffset]
        mov ecx, [newringoffset]
        mov edi, cmdbuffer
        add esi, ebx
        sub ecx, ebx
        rep movsb


        
        cmp word [cmdbuffer], "ls"
        je .listcontents
        cmp word [cmdbuffer], "cd"
        je .changedir
        cmp word [cmdbuffer], "mv"
        je .movefile
        cmp word [cmdbuffer], "rm"
        je .delete
        cmp word [cmdbuffer], "wx"
        je .edit
        cmp dword [cmdbuffer], "clrs"
        je .clear
        

        movzx ecx, byte [cmdbuffer]
        mov edi, cmdtable
        ; do funciton table for ecx[table]
        ; Damn this'll take a while to do. 
        mov ecx, [esi + ecx * 4]
        jmp ecx
        
        
                 

CHARSHEET
newlinermsg db " ", 0x0D, 0x0A, 0x00
hexlut db "0123456789ABCDEF"
testmessage db "GDT UP", 0x0D, 0x0A, "STACK UP", 0x0D, 0x0A, "ENTERED PROTECTED MODE", 0x0D, 0x0A, "BEGINNING IDT...", 0x0D, 0x0A, 0x00
divzeromsg db "DIVISION BY ZERO",0x0D, 0x0A, 0x00
idtupmsg db "IDT UP LOADING KERNEL...", 0x0D, 0x0A, 0x00
ioflags db 0
cmdprmpt db "> ", 0x00
clocktimer dq 0
invalidcmd db "Invalid Command :(", 0x0A, 0x0D, "> ", 0x00
dirtest db "Files? What files?", 0x0D, 0x0A, "> ", 0x00
dirtestlen equ $ - dirtest
cdtest db "No other directories. Please add %dir command.", 0x0D, 0x0A, "> ", 0x00
writeactiveflag db 0 ; 0 charbuffer; 1 direct FB; 2 read; 3 open; 4 close; 5 inc; 6 dec; 7 access;

align 4
chartab db 0x20, 0x20, "1234567890-=", 0x20, 0x20, "qwertyuiop[]", 0x20, 0x20, "asdfghjkl;'`", 0x20, "\zxcvbnm,./", 0x20, 0x20
chartabshift db 0x20, 0x20, "!@#$%^&*()_+", 0x20, 0x20, "QWERTYUIOP{}", 0x20, 0x20, 'ASDFGHJKL:"~', 0x20, "|ZXCVBNM<>?", 0x20, 0x20


align 4096
pagedir times 1024 dd 0

align 4096
pagetables times (32 * 1024) db 0
        



section .bss
scratchpad resq 1024 ; 8 KiB scratchpad
filestat resq 256 ; 4KB scratchpad to hold file addresses, names, and sizes in RAM. Directories are files that hold extended addresses.
                        ; 64 bit filename, 32 bit address, 16 bit size; 16 bit attributes. Can have 128 top-directories. 
initoffset resd 1
currentoffset resd 1
keyboardringbuffer resb 1962
newringoffset resd 1
endoffset resd 1
cmdbuffer resb 32
iscapitol resb 1
