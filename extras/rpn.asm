org 0x7C00
[bits 16]

_start:
        xor ax, ax
        mov ss, ax
        mov es, ax
        mov ds, ax
        mov sp, 0x7C00

        mov bx, 0x7E00 
        mov ah, 0x02
        mov al, 0x05
        xor cx, cx
        mov cl, 0x02
        mov dh, 0
        int 0x13
        jc .readfail
        jmp 0x0000:0x7E00
.readfail:
        mov ax, 0x0E
        mov si, readfail
.loopit:
        lodsb
        int 0x10
        test al, al
        jnz .loopit

        jmp 0x0000:0x8000
times 510 - ($-$$) db 0
dw 0xAA55
;times 512 - ($ - $$) db 0


.noreadfail:

        xor eax, eax
        cpuid

        mov [namebuffer], ebx
        mov [namebuffer + 4], edx
        mov [namebuffer + 8], ecx

        mov ah, 0x0E
        mov al, 0x20
        int 0x10
        mov al, 'M'
        int 0x10
        mov al, 'O'
        int 0x10
        mov al, 'D'
        int 0x10
        mov al, 'E'
        int 0x10
        mov al, 'L'
        int 0x10
        mov al, 0x20
        int 0x10
        
        mov eax, 1
        cpuid
        mov ebx, eax
        shr ebx, 4
        and ebx, 0x0F
        add bl, 0x30
        mov al, bl
        mov ah, 0x0E
        int 0x10
        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10

        mov ebx, edx
        and ebx, 0x0001
        call hasmath
        mov ebx, edx
        and ebx, 0x00800000
        call hasmmx
        mov ebx, edx
        and bx, 0x0200
        call hasapic
        mov ebx, edx
        and ebx, 0x01000000
        call hasfxsr
        mov ebx, edx
        and ebx, 0x02000000
        call hassse

        mov eax, 0x80000000
        cpuid
        cmp eax, 0x80000004
        jl .nofancyflag

        mov eax, 0x80000002
        cpuid
        mov [longspec], eax
        mov [longspec + 4], ebx
        mov [longspec + 8], ecx
        mov [longspec + 12], edx
        mov eax, 0x80000003
        cpuid
        mov [longspec + 16], eax
        mov [longspec + 20], ebx
        mov [longspec + 24], ecx
        mov [longspec + 28], edx
        mov eax, 0x80000004
        cpuid
        mov [longspec + 32], eax
        mov [longspec + 36], ebx
        mov [longspec + 40], ecx
        mov [longspec + 44], edx
        mov ah, 0x0E
        mov si, longspec
.printlong:
        lodsb
        int 0x10
        test al, al
        jnz .printlong
        mov ah, 0x0E
        mov si, namebuffer
        
.printname:
        lodsb
        int 0x10
        test al, al
        jnz .printname
       
.nofancyflag:
        hlt
        jmp $
        
fsxrspec db "FSXR", 0x0A, 0x0D, 0x00
apicspec db "APIC", 0x0A, 0x0D, 0x00
mmxspec db "MMX", 0x0A, 0x0D, 0x00
mathspec db 0x20, "FPU", 0x0A, 0x0D, 0x00
ssespec db "SSE", 0x0A, 0x0D, 0x00
tscspec db "TSC", 0x0A, 0x0D, 0x00
readfail db "READ FAILURE ON FLOPPY",0x0A, 0x0D, 0x00
vgaspec:
        db "VBE2"
        times 508 db 0
longspec:
        times 48 db 0
        db 0x0A
        db 0x0D
        db 0x00
namebuffer:
        dd 0x00, 0x00, 0x00
        db 0x0A, 0x0D, 0x00

second_start:

hasmath:
        test ebx, ebx
        jz .donemath
        mov ah, 0x0E
        mov si, mathspec
.hasmathloop:
        lodsb
        int 0x10
        test al, al
        jnz .hasmathloop
.donemath:
        ret

hasmmx:
        test ebx, ebx
        jz .donemmx
        mov ah, 0x0E
        mov si, mmxspec
.hasmmxloop:
        lodsb
        int 0x10
        test al, al
        jnz .hasmmxloop
.donemmx:
        ret

hasapic:
        test bx, bx
        jz .doneapic
        mov ah, 0x0E
        mov si, apicspec
.hasapicloop:
        lodsb
        int 0x10
        test al, al
        jnz .hasapicloop
.doneapic:
        ret

hasfxsr:
        test ebx, ebx
        jz .donefxsr
        mov ah, 0x0E
        mov si, fsxrspec
.hasfxsrloop:
        lodsb
        int 0x10
        test al, al
        jnz .hasfxsrloop
.donefxsr:
        ret

hassse:
        test ebx, ebx
        jz .donesse
        mov ah, 0x0E
        mov si, ssespec
.hassseloop:
        lodsb
        int 0x10
        test al, al
        jnz .hassseloop
.donesse:
        ret

