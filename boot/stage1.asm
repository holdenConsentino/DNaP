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




 
