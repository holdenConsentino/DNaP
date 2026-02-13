[bits 16]
org 0x7C00

start:
        xor ax, ax
        mov es, ax
        mov ds, ax
        mov ss, ax
        in al, 0x92
        or al, 2
        out 0x92, al
        mov dword [0x01], 0xDEADBEEF
        mov ah, 0x0E
        mov si, memstringone
.memprint:
        lodsb
        int 0x10
        test al, al
        jnz .memprint
        
        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10

        mov ax, 0xFFFF
        mov es, ax
        push 0x0010
        pop di
        mov dword [es:di], 0xFFFFFFFF
        cmp dword [0x01], 0xDEADBEEF
        xor ax, ax
        mov es, ax
        je .skip
        mov ah, 0x0E
        mov si, atwentyfail
.aprint:
        lodsb
        int 0x10
        test al, al
        jnz .aprint

        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10

        jmp hddtest
.skip:
        mov ah, 0x0E
        mov si, itworked
.skiploop:
        lodsb
        int 0x10
        test al, al
        jnz .skiploop

        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10

hddtest:
        mov ah, 1
        int 0x13
        test ah, ah
        jz .nofail
        mov ah, 0x0E
        mov si, hddfail
.hddloop:
        lodsb
        int 0x10
        test al, al
        jnz .hddloop
        hlt
        jmp $
.nofail:
        mov ah, 0x0E
        mov si, diskup
.nofailloop:
        lodsb
        int 0x10
        test al, al
        jnz .nofailloop

        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10

        
        mov dx, 0x1F7
        
.waitloopinit:
        in al, dx
        test al, 0x80
        jnz .waitloopinit

        mov dx, 0x1F1
        mov al, 0xDA
        out dx, al
        mov dx, 0x1F4
        mov al, 0x4F
        out dx, al
        inc dx
        mov al, 0xC2
        out dx, al
        inc dx
        mov al, 0xA0
        out dx, al
        inc dx
        mov al, 0xB0
        out dx, al

.waitloop:
        mov dx, 0x1F7
        in al, dx
        movzx bx, al
        xor cx, cx
        bt bx, cx
        jc .smartfail
.smarter:
        test al, 0x80
        jnz .waitloop
        mov dx, 0x1F4
        in al, dx
        mov bl, al
        inc dx
        in al, dx
        cmp bl, 0x4F
        jne .drivefail
        cmp al, 0xC2
        jne .drivefail

        mov si, smartclear
        mov ah, 0x0E
.diskgoodloop:
        lodsb
        int 0x10
        test al, al
        jnz .diskgoodloop
        hlt
        jmp $

.drivefail:
        mov ah, 0x0E
        mov si, drivefail
.driveloop:
        lodsb
        int 0x10
        test al, al
        jnz .driveloop

        hlt
        jmp $

.smartfail:
        mov bh, al
        mov dx, 0x1F1
        in al, dx
        cmp al, 0x04
        je .abort
        cmp al, 0x0F
        je .error
        mov si, unknownerror
        mov ah, 0x0E
.smartloop:
        lodsb
        int 0x10
        test al, al
        jnz .smartloop

        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10

        jmp .smarter
        
.abort:
        mov ah, 0x0E
        mov si, abort
.abortloop:
        lodsb
        int 0x10
        test al, al
        jnz .abortloop

        hlt
        jmp $

.error:
        mov ah, 0x0E
        mov si, generror
.errorloop:
        lodsb
        int 0x10
        test al, al
        jnz .errorloop
        hlt
        jmp $
        
memstringone db "ADDRESS 0x01 SET", 0x00
atwentyfail db "ADDRESS 0x01 OVERWRITE", 0x00
itworked db "A20 GATE OPEN", 0x00
hddfail db "DISK HARDWARE FAIL", 0x00
diskup db "NO REPORTED DISK ERRORS", 0x00
smartclear db "SMART REPORT CLEAR", 0x00
drivefail db "SMART REPORT FAIL", 0x00
unknownerror db "UNKNOWN ERROR REPORT", 0x00
abort db "SMART ABORTED", 0x00
generror db "GEN. SMART ERROR", 0x00
times 510 - ($ - $$) db 0
dw 0xAA55
