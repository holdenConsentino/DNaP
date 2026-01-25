org 0x7C00
[bits 16]

_start:
        mov ax, 0x0000
        mov es, ax
        mov ds, ax
        mov ss, ax

        in al, 0x92
        or al, 2
        out 0x92, al
        
        mov [bootdrive], dl
        ;mov cs
        mov sp, 0x7C00
        mov ah, 0x0E
        mov si, stackup
.printstack:
        lodsb
        int 0x10
        test al, al
        jnz .printstack

        mov ax, 0x4F01
        mov cx, 0x114
        mov di, 0x9000
        int 0x10
        cmp ax, 0x004F
        jne halting
        mov eax, [0x9028]
        mov [framebuffer], eax
        mov bx, [0x9010]
        mov [pitch], bx
        mov ax, 0x4F02
        mov bx, 0x4114
        int 0x10


        
        xor ax, ax
        mov dl, [bootdrive]
        int 0x13
        cmp [bootdrive], 0x80
        jae .hdd
        mov ah, 0x02
        mov al, 10
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
        
bootdrive db 0
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
framebuffer dd 0
pitch dw 0
times 510 - ($ - $$) db 0
dw 0xAA55
; starts at 7E00
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

stagetwostart:
        mov ax, 0x10
        mov ss, ax
        mov ds, ax
        mov es, ax
        mov esp, 0x90000
        
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

        mov dword [printarguments], 0
        mov byte [printarguments + 4], 0x45
        mov word [printarguments + 5], 0xFFFF
        call printchar
        sti
        
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
        %assign i 32
        %rep 224
        dd isr%+i
        %assign i i+1
        %endrep
        
        

default_handler:
        pusha        
        ; set up handler
        mov al, 0x20
        out 0x20, al
        out 0xA0, al
        popa
        add esp, 8
        iretd
;handlers:
 ;       dd DivZero, SingleStep, HardwareFailure, BreakPoint, OverFlow, ExceedsBounds, InvalidOpcode, DevNotAvail, DoubleFault, CoPOver, TSSCorrupt, InvalidSegment, StackFault, GPFault, Page, NULLFAULT, FPUError, AlignFault, MachineFault, SimdFault
  ;      times 11 dd NULLFAULT
        


;DivZero:

hlt
jmp $

sprintchar:
        mov esi, [framebuffer]
        mov word [esi], 0xFFFF
        ret

printchar:
    pusha
    ; 1. Setup Pointers
    movzx eax, byte [printarguments + 4] ; Get ASCII Char
    sub al, 0x20                         ; Adjust for font offset
    lea esi, [chars + eax*8]             ; Load address of 8-byte font data
    
    mov edi, [framebuffer]
    add edi, [printarguments]            ; Start at X/Y offset

    xor ebx, ebx                         ; EBX = Row counter (0-7)
.row_loop:
    movzx edx, byte [esi + ebx]          ; Load exactly 1 byte (one row of 8 pixels)
    
    xor ecx, ecx                         ; ECX = Bit counter (0-7)
.bit_loop:
    bt dx, cx                            ; Test bit 'cx' in the current row byte
    jnc .skip_pixel
    
    mov ax, word [printarguments + 5]    ; Get Color (0xFFFF)
    mov [edi + ecx*2], ax                ; Draw 16-bit pixel at (CurrentRowStart + X_Offset)
    
.skip_pixel:
    inc ecx
    cmp ecx, 8
    jl .bit_loop

    ; --- Move to the next scanline ---
    add edi, [pitch]                     ; Move EDI down exactly one row
    inc ebx
    cmp ebx, 8                           ; Ensure we only do 8 rows
    jl .row_loop

    popa
    ret

errorcodes dd 0 ; jmp over
printarguments:
        dd 0 ; offset
        db 0 ; ASCII code
        dw 0 ; color
        db 0 ; padding / counter
CHARACTERS

section .bss
scratchpad resq 1024 ; 8 KiB scratchpad
