org 0x8000
[bits 32]
%include "macros.inc"

stagetwostart:
        mov edi, idt_buffer
        mov ecx, 256
.idt_loop:
        mov eax, default_handler
        mov [edi], ax
        mov word [edi + 2], 0x08
        mov byte [edi + 4], 0x00
        mov byte [edi + 5], 0x8E
        shr eax, 16
        mov [edi + 6], ax
        add edi, 8
        loop .idt_loop

        lidt [idt_descriptor]
        sti

mov edi, 
align 16
idt_descriptor:
        dw (256 * 8) - 1
        dw idt_buffer
        
idt_buffer times 2048 db 0       

default_handler:
        iretd
