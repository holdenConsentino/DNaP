[bits 32]

keyboard_handler:
        in al, 0x60
        movzx eax, al
        ; cursor movement
        movzx eax, byte [chartab + eax]
        mov byte [printarguments + 4], al
        call printchar
        add dword [printarguments], 32
        ret        
        chartab db 0x00, "1234567890-=", 0x00, "qwertyuiop[]", 0x00, "asdfghjkl;'`", 0x00, "\zxcvbnm,./", 0x00, 0x20
        chartabshift db 0x00, "!@#$%^&*()_+", 0x00, 0x00, "QWERTYUIOP{}", 0x00, 'ASDFGHKL:"~', 0x00, "|ZXCVBNM<>?", 0x00, 0x20
        
