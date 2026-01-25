
[org 0x8000]
[bits 16]
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

