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


        mov ah, 0x02 ; read floppy
        mov al, 17 ; 18
        xor ch, ch
        xor dh, dh
        mov cl, 0x02
        mov dl, [bootdrive]
        xor bx, bx
        mov es, bx
        mov bx, 0x7E00
        int 0x13
        jc floppyfail

        mov ah, 0x02
        mov al, 18
        xor ch, ch
        mov dh, 1
        mov cl, 0x01
        mov dl, [bootdrive]
        xor bx, bx
        mov es, bx
        mov bx, 0xA000
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

        mov dx, 0x3F2
        mov al, 0x0C
        out dx, al ; kill floppy

        xor al, al
        out dx, al ; reset floppy reader. 

        mov ecx, (51 * 33)
        mov edi, keybuffer
        xor eax, eax
        rep stosb

        mov byte [keybuffer], "A"
        mov byte [keybuffer + 1], "B"
        mov byte [keybuffer + 2], 0

        sti

        mov esi, printstringtst
        xor ecx, ecx
        mov bh, 1
        mov bl, 1
        call printstring

        mov byte [coordxy], 2
        mov byte [coordxy + 1], 4

        mov esi, cmdprompt
        xor ecx, ecx
        mov bh, 2
        mov bl, 1
        call printstring


        mov bh, 2
        mov bl, 3
        call printcursor
term:
        hlt
        jmp term
        ; MAIN




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
        times 9 dd NULLFAULT ;0x22-0x30

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
        mov ebx, cr2 ; ???
        call reghexprint
        TERMINATE ; I don't yet have paging so who gives a care
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


printchar: ; well mess I guess we're doing it the hard way. character in al, row in bh, column in bl
        ; Printarguments holds offset
        ; printarguments + 4 holds character
        ; if ecx is zero, we can use direct load instead of printarguments
        ; DOES NOT SAVE REGISTERS CALLER SAVED
        ; row bh 1 INDEXED
        ; column bl 1 INDEXED
        pushad
        pushfd
        cli
        push eax
        push ecx
        movzx eax, word [pitch]
        movzx edx, bh
        movzx ecx, bl
        movzx ebx, bh
        dec ecx
        dec ebx
        shl ecx, 4 ; col`
        shl ebx, 4
        shl edx, 1
        add ebx, edx 
        imul ebx, eax ; ecx, eax
        shl ecx, 1 ; ebx
        add ebx, ecx ; find offset
        pop ecx
        pop eax
        test ecx, ecx ; is ECX 0?
        jz .skipload
        movzx eax, byte [printarguments + 4] ; don't overwrite character in al
.skipload:
        sub al, 0x20
.pitchedmaybe:
        mov edi, [framebuffer]
        shl eax, 2
        add edi, ebx ; get actual address
        lea esi, [chars + eax*8] ; get address to char and framebuffer

        xor ecx, ecx ; counter

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
        
        popfd
        popad
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

; need printstring and keyboard driver
; clearscreen, printscreen, cmdparser
; paging :(
; 

printstring: ; string at esi
        pushfd ; count at ecx 
        pushad ; null term if ecx = 0
        cli ; row in bh | column in bl 1 INDEXED
        cld
        test ecx, ecx
        jz .strloopnull
        

.strloopcount:
        lodsb
        movzx eax, al
        cmp al, 0x0D
        je .strcr
        push ecx
        cmp al, 0x0A
        je .newlinecount
        xor ecx, ecx ; ??``
        call printchar
        inc bl
        cmp bl, 50
        pop ecx
        jae .newlinecount
        loop .strloopcount
        
        popad
        popfd
        ret

        
.strloopnull:           
        lodsb
        movzx eax, al
        test al, al
        jz .endstrloop
        cmp al, 0x0D
        je .crnull
        cmp al, 0x0A
        je .newlinenull
        xor ecx, ecx; ??
        call printchar
        inc bl
        cmp bl, 50
        jge .newlinenull
        jmp .strloopnull

.endstrloop:
        popad
        popfd
        ret
.crnull:
        mov bl, 1
        jmp .strloopnull

.newlinecount:
        inc bh
        mov bl, 1
        loop .strloopcount

.newlinenull:
        inc bh
        mov bl, 1
        jmp .strloopnull

.strcr:
        mov bl, 1
        loop .strloopcount
        
        
                
reghexprint: ; first arg in ebx, coords in ecx yes I know it's weird
        pushad
        mov ebp, esp
        sub esp, 9
        xor eax, eax
        mov ecx, 4
        xor edx, edx

.convloop:
        movzx eax, bl
        and al, 0x0F
        mov al, byte [hexlut + eax]
        mov byte [esp + edx], al
        movzx eax, bl
        shr eax, 4
        mov al, byte [hexlut + eax]
        mov byte [esp + edx + 1], al
        add edx, 2
        shr ebx, 8
        loop .convloop
        
        mov esi, esp
        mov bx, cx
        call printstring

        mov esp, ebp
        pop ebp
        popad
        ret


keyboard_handler:
        pushad
        mov edi, [framebuffer]
        mov dword [edi], 0xF2E0FFFF
        in al, 0x60
        cmp al, 0xAA
        je .unshift
        cmp al, 0xB6
        je .unshift
        cmp al, 0x80
        jae .skipkeyboard
        cmp al, 0x2A
        je .shift
        cmp al, 0x36
        je .shift
        cmp al, 0x0E
        je .backspace
        cmp al, 0x1C
        je .enter ; cmp to ENTER
        ;cmp al, 0xE0
        ;je extension
        cmp byte [iscapitol], 0
        jnz .uppercase
        movzx eax, al
        ; cursor movement
        movzx eax, byte [chartab + eax]
 
.possiblyshifted:
        push ebx
        movzx ebx, word [endcoordxy]

        mov byte [keybuffer + ebx], al
        mov byte [keybuffer + ebx + 1], 0
        pop ebx
        inc word [endcoordxy]
        
.skipkeyboard:

        mov al, 0x20 ; Send EOI
        out 0x20, al
        mov word [printarguments + 5], 0xFFFF
        mov bh, byte [cursorxy + 1]
        mov bl, byte [cursorxy]
        dec bl ; why?!??
        call cursorerase
        add bl, 2 ; inc
        cmp bl, -1
        jae .wrong
.wronged:
        inc bh
        xor ecx, ecx
        mov byte [coordxy], 3
        mov byte [coordxy + 1], 2 ; TEMP
        call printscreen ; print characters. We'll see how this goes.
        popad
        ret
.wrong:
        mov bh, 1
        jmp .wronged
.enter:

        movzx ecx, word [endcoordxy]
        mov word [keybuffer + ecx], 0x0A0D
        mov byte [keybuffer + ecx + 2], 0
        inc byte [coordxy]
        add [endcoordxy], 2
        jmp .skipkeyboard

.uppercase:

        movzx eax, al
        movzx eax, byte [chartabshift + eax]
        jmp .possiblyshifted

.extension:
        ; TEMP SO INCREDIBLY TEMP
        in al, 0x60
        cmp al, 0

.shift: ; this has some problems
        mov byte [iscapitol], 1
        jmp .skipkeyboard

.unshift:
        mov byte [iscapitol], 0
        jmp .skipkeyboard

.backspace:
        movzx ecx, word [endcoordxy]
        mov byte [keybuffer + ecx], 0x20
        dec word [endcoordxy]
        mov bl, 1 ; CL
        mov bh, 3
        dec bl
        call cursorerase
        inc bl
        jmp .skipkeyboard

printfullscreen: ; DOES NOT SAVE
        pushad
        xor ecx, ecx
        mov esi, keybuffer
        mov bh, 1
        mov bl, 1
        call printstring
        popad
        ret
        
printscreen: ; DOES NOT SAVE
        mov bh, byte [coordxy]
        xor ecx, ecx
        mov bl, byte [coordxy + 1]
        mov esi, keybuffer
        call printstring
        ret

clearscreen: ; DOES SAVE
        pushfd
        pushad
        cli
        mov esi, keybuffer
        mov ecx, (33 * 51)
        cld
        xor eax, eax
        rep stosb

        mov esi, [framebuffer]
        mov ecx, (800 * 600 * 2)
        xor eax, eax
        rep stosb

        mov byte [strtcoordxy], 1
        mov byte [endcoordxy], 1
        mov byte [coordxy], 1
        mov byte [strtcoordxy + 1], 1
        mov byte [endcoordxy + 1], 1
        mov byte [coordxy + 1], 1

        mov esi, cmdprompt
        mov ecx, 2
        call printstring
        popad
        popfd
        ret

printcursor: ; row, column in bh, bl
        pushad
        pushfd
        cli
        mov edi, [framebuffer]
        push ebx
        movzx ecx, bh ; row
        movzx ebx, bl ; column
        movzx edx, word [pitch]
        dec ecx
        dec ebx
        shl ecx, 4
        shl ebx, 5
        imul ecx, edx
        add edi, ebx
        add edi, ecx
        xor ebx, ebx
.cursorloop:
        mov esi, edi
        mov ecx, 32
        mov eax, 0xFFFFFFFF
        rep stosb

        inc ebx
        mov edi, esi
        add edi, edx
        cmp ebx, 16
        jl .cursorloop

        pop ebx
        mov word [cursorxy], bx       
        popfd
        popad
        ret

cursorerase:
        pushad
        pushfd
        cli
        mov edi, [framebuffer]
        movzx ecx, bh ; row
        movzx ebx, bl ; column
        movzx edx, word [pitch]
        dec ecx
        dec ebx
        shl ecx, 4
        shl ebx, 5
        imul ecx, edx
        add edi, ebx
        add edi, ecx
        xor ebx, ebx
        mov ecx, 32
.cursorerase:
        xor eax, eax
        add eax, esi
        mov esi, edi
        rep stosb
        inc ebx
        mov edi, esi
        add edi, edx
        cmp ebx, 16
        jle .cursorerase
        popfd
        popad
        ret

section .data



align 4
chartab db 0x20, 0x20, "1234567890-=", 0x20, 0x20, "qwertyuiop[]", 0x20, 0x20, "asdfghjkl;'`", 0x20, "\zxcvbnm,./", 0x20, 0x20
chartabshift db 0x20, 0x20, "!@#$%^&*()_+", 0x20, 0x20, "QWERTYUIOP{}", 0x20, 0x20, 'ASDFGHJKL:"~', 0x20, "|ZXCVBNM<>?", 0x20, 0x20

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
iscapitol db 0
hexlut db "0123456789ABCDEF"
cmdprompt db "> "
clocktimer dq 0
printstringtst db "Hello!",0x00

divzeromsg db "DIVISION BY ZERO",0x0D, 0x0A, 0x00

printarguments:
        dd 0
        db 0
        dw 0xFFFF
        db 0

CHARSHEET

strtcoordxy dw 0
endcoordxy dw 0
cursorblink dw 0
cursorxy dw 0

section .bss
coordxy resb 2
keybuffer resb 51 * 33
scratchpad resq 1024 ; 8 KiB scratchpad
filestat resq 256 ; 4KB scratchpad to hold file addresses, names, and sizes in RAM. Directories are files that hold extended addresses.
                        ; 64 bit filename, 32 bit address, 16 bit size; 16 bit attributes. Can have 128 top-directories. 
cmdbuffer resb 32
