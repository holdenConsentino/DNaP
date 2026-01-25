[bits 16]
org 0x7C00
_start:
        xor ax, ax
        mov es, ax
        mov ds, ax
        mov ss, ax
        mov si, msg
        mov ah, 0x0E
        xor al, al
.printloop:
        lodsb
        int 0x10
        test al, al
        jnz .printloop

        xor ax, ax
        int 0x16

        mov ax, 0x0013
        int 0x10

        mov ax, 0xA000
        mov es, ax
        
        mov ax, (320 * 189) ; rows
.colloop:
        xor bx, bx
.rowloop:
        mov cx, ax
        add cx, bx
        mov di, cx
        mov [es:di], 0x0F
        inc bx
        cmp bx, 320
        jle .rowloop
        add ax, 320
        cmp ax, (320 * 200)
        jle .colloop
        xor ax, ax
.nextcolloop:
        xor bx, bx
.nextrowloop:
        mov cx, ax
        add cx, bx
        mov di, cx
        mov [es:di], 0x72
        inc bx
        cmp bx, 320
        jle .nextrowloop
        add ax, 320
        cmp eax, (320 * 189)
        jl .nextcolloop
                
        hlt
        jmp $

msg db "Hello World!", 0x0A, 0x0D, "I have a simple first-stage bootloader", 0x0A, 0x0D, "Also Benny is adorable", 0x0A, 0x0D, "Now press [ENTER]", 0x0A, 0x0D,0x00
times 510 - ($-$$) db 0
dw 0xAA55
        
