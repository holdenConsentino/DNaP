;Good luck 

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

        mov ax, 0x4F01
        mov cx, 0x114
        mov di, 0x1000
        int 0x10
        cmp ax, 0x004F
        jne vesa_fail

        mov ax, 0x4F02
        mov bx, 0x4114
        int 0x10
        cmp ax, 0x004F
        jne vesa_failtwo
        
        mov eax, [0x1028]
        mov [framebuffer], eax
        mov bx, [0x1010]
        mov [pitch], bx
                
        xor ax, ax
        mov ds, ax
        
        xor ax, ax
        mov dl, [bootdrive]
        int 0x13
        cmp [bootdrive], 0x80
        jae .hdd

        xor ax, ax
        int 0x13
        
        mov ah, 0x02
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
        mov ah, 0x42
        mov dl, [bootdrive]
        mov si, disk_packet
        int 0x13
        jc diskfail
        
.ramloaded:
        cli ; this is it, boys
        lgdt [gdt_descriptor]
        mov eax, cr0
        or eax, 0x1
        mov cr0, eax                
        jmp 0x08:0x7E00

halting:
        mov si, genfail
        mov ah, 0x0E
.looped:
        lodsb
        int 0x10
        test al, al
        jnz .looped
        hlt
        jmp $


floppyfail:
        mov ah, 0x0E
        mov si, flop
.floploop:
        lodsb
        int 0x10
        test al, al
        jnz .floploop
        jmp halting
diskfail:
        mov ah, 0x0E
        mov si, disk
.diskloop:
        lodsb
        int 0x10
        test al, al
        jnz .diskloop
        jmp halting

vesa_fail:
        mov ax, 0x0E
        mov si, vfail
.failit:
        lodsb
        int 0x10
        test al, al
        jnz .failit
        hlt
        jmp $

vesa_failtwo:
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

  stagetwostart:
        mov ax, 0x10
        mov ss, ax
        mov ds, ax
        mov es, ax
        mov gs, ax
        mov fs, ax
        mov esp, 0x08000000
        and esp, 0xFFFFFFF0
        mov ebp, esp
        
        mov edi, idt_buffer
        mov esi, isr_stub
        mov ecx, 256 ; for now. 256 later. 
.idtloop:
        mov eax, [esi]
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

picmap:
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
        movzx eax, word [pitch]
        shl eax, 8
        add eax, 16
        mov bl, 0x20
        mov dx, 0xFADE
        mov ecx, 48

        cld
        mov al, 0x20
.loopeding:
       
        movzx ebx, word [pitch]
        shl ebx, 4
        sti
        
        
        mov eax, 16
        mov esi, testmessage
        add eax, ebx
        mov ebx, 0x001F
        ;mov [currentoffset], eax
        call printstring

        mov dx, 0x3F2
        mov al, 0x0C
        out dx, al ; kill floppy

        xor al, al
        out dx, al ; reset floppy reader. 

        mov esi, idtupmsg
        mov ebx, 0x001F
        mov eax, [initoffset]
        call printstring

        mov esi, cmdprmpt
        mov ebx, 0x001F
        mov eax, [initoffset]
        call printstring
        
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
        dd timer_handler
        dd keyboard_handler
        times 14 dd NULLFAULT

timer_handler:
        add dword [clocktimer], 1
        adc dword [clocktimer + 4], 0
        ret

DivZero:
        mov edi, [framebuffer]
        mov ecx, (800 * 600 * 2) / 4
        mov eax, 0x00000000
        rep stosd
        mov esi, divzeromsg
        xor eax, eax
        mov ebx, 0xFFFF
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
        mov ebx, 0xFFFF
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
        mov ebx, 0xFFFF
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
        mov ebx, 0xFFFF
        call printstring
        hlt
        jmp $

ExceedsBounds:
        SCREENFILL 0x000;00000
        PRINTMSG exceedsboundsmsg, 0, 0xFFFF
        hlt
        jmp $

InvalidOpcode:
        SCREENFILL 0x0000;0000
        PRINTMSG invalidopcodemsg, 0, 0xFFFF
        TERMINATE
DevNotAvail:
        SCREENFILL 0x00000000
        PRINTMSG devnotavailmsg, 0, 0xFFFF
        TERMINATE
DoubleFault:
        SCREENFILL 0x00000000
        PRINTMSG doublefaultmsg, 0, 0xFFFF
        ret ; yes, going back
TSSCorrupt:
        SCREENFILL 0x00000000
        PRINTMSG tsscorruptmsg, 0, 0xFFFF
        TERMINATE
InvalidSegment:
        SCREENFILL 0x00000000
        PRINTMSG invsegmsg, 0, 0xFFFF
        TERMINATE
StackFault:
        SCREENFILL 0x00000000
        PRINTMSG stackfaultmsg, 0, 0xFFFF
        TERMINATE
GPFault:
        SCREENFILL 0x00000000
        PRINTMSG gpfaultmsg, 0, 0xFFFF
        TERMINATE
Page:
        SCREENFILL 0x00000000
        PRINTMSG pagefaultmsg, 0, 0xFFFF
        ret ; I don't yet have paging so who gives a care
FPUError:
        SCREENFILL 0x00000000
        PRINTMSG fpuerrormsg, 0, 0xFFFF
        ret
AlignFault:
        SCREENFILL 0x00000000
        PRINTMSG alignfaultmsg, 0, 0xFFFF
        ret
MachineFault:
        SCREENFILL 0x00000000
        PRINTMSG machinefaultmsg, 0, 0xFFFF
        TERMINATE
SimdFault:
        SCREENFILL 0x00000000
        PRINTMSG simdfaultmsg, 0, 0xFFFF
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
        mov word [edi + edx*2], bx
        pop ebx
        jmp .printed        

.addpitching:
        push edx
        movzx edx, word [pitch]
        shl edx, 16
        add edi, edx
        pop edx
        jmp .pitchedmaybe
printstring: ; takes string in esi, offset in eax, color in ebx, goes to 0x00. Supports 0x0A and 0x0D.
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
.endprint:
        popad
        ret

keyboard_handler:
        in al, 0x60
        cmp al, 128
        jae skipkeyboard
        movzx eax, al
        ; cursor movement
        movzx eax, byte [chartab + eax]
        cmp al, 0x1C
        je skipperkb        
        mov byte [printarguments + 4], al
        call printchar
        add dword [printarguments], 32
        skipkeyboard:
        mov al, 0x20
        out 0x20, al
        ret        
        chartab db 0x00, 0x00, "1234567890-=", 0x00, 0x00, "qwertyuiop[]", 0x00, 0x00, "asdfghjkl;'`", 0x00, "\zxcvbnm,./", 0x00, 0x20
        chartabshift db 0x00, 0x00, "!@#$%^&*()_+", 0x00, 0x00, "QWERTYUIOP{}", 0x00, 0x00, 'ASDFGHKL:"~', 0x00, "|ZXCVBNM<>?", 0x00, 0x20
        skipperkb:
        mov esi, newliner
        mov ebx, 0xFFFF
        call printstring
        jmp skipkeyboard

        errorcodes dd 0 ; jmp over
printarguments: ; qword
        dd 0 ; offset
        db 0 ; ASCII code
        dw 0 ; color
        db 0 ; padding / counter


CHARSHEET
newliner db 0x0D, 0x0A, 0x00
hexlut db "0123456789ABCDEF"
testmessage db "GDT UP", 0x0D, 0x0A, "STACK UP", 0x0D, 0x0A, "ENTERED PROTECTED MODE", 0x0D, 0x0A, "BEGINNING IDT...", 0x0D, 0x0A, 0x00
divzeromsg db "DIVISION BY ZERO",0x0D, 0x0A, 0x00
idtupmsg db "IDT UP LOADING KERNEL...", 0x0D, 0x0A, 0x00
ioflags db 0
cmdprmpt db 0x0D, 0x0A, "> ", 0x00
clocktimer dq 0
section .bss
scratchpad resq 1024 ; 8 KiB scratchpad
initoffset resd 1
currentoffset resd 1
