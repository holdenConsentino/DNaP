%line 5+1 bootloader.asm
[org 0x7C00]
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

 mov sp, 0x7C00
 mov ah, 0x0E
 mov si, stackup
.printstack:
 lodsb
 int 0x10
 test al, al
 jnz .printstack

 mov ax, 0
 mov es, ax

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
 cmp byte [bootdrive], 0x80
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
 cli
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

[sectalign 4]
%line 166+0 bootloader.asm
times (((4) - (($-$$) % (4))) % (4)) nop
%line 167+1 bootloader.asm
disk_packet:
 db 0x10
 db 0x00
 dw 1
 dw 0x8000
 dw 0x0000
 dq 95
[sectalign 4]
%line 174+0 bootloader.asm
times (((4) - (($-$$) % (4))) % (4)) nop
%line 175+1 bootloader.asm
framebuffer dd 0
[sectalign 4]
%line 176+0 bootloader.asm
times (((4) - (($-$$) % (4))) % (4)) nop
%line 177+1 bootloader.asm
pitch dw 0
times 510 - ($ - $$) db 0
dw 0xAA55








[bits 32]



%line 198+1 bootloader.asm

%line 204+1 bootloader.asm


%line 222+1 bootloader.asm

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
 mov ecx, 256
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

 mov al, 36
 out 0x43, al
 mov ax, 0x2E9B
 out 0x40, al
 mov al, ah
 out 0x40, al



 mov edi, pagetables
 mov ecx, 32768
 xor eax, eax
.pageloop:
 mov edx, eax
 or edx, 0x3
 mov [edi], edx
 add edi, 4
 add eax, 4096
 loop .pageloop

 mov edi, pagedir
 mov esi, pagetables
 mov ecx, 32
.pagelink:
 mov eax, esi
 or eax, 0x3
 mov [edi], eax
 add edi, 4
 add esi, 4096
 loop .pagelink

 mov eax, pagedir
 mov cr3, eax

 mov eax, cr0
 or eax, 0x80000000
 mov cr0, eax

 movzx eax, word [pitch]
 shl eax, 8
 add eax, 16
 mov bl, 0x20
 mov dx, 0xFADE
 mov ecx, 48

 cld
 mov al, 0x20

 movzx ebx, word [pitch]
 shl ebx, 4
 sti




 mov eax, 16
 mov esi, testmessage
 add eax, ebx
 mov ebx, 0x0F80

 call printstring

 mov dx, 0x3F2
 mov al, 0x0C
 out dx, al

 xor al, al
 out dx, al

 mov esi, idtupmsg
 mov ebx, 0x0F80
 mov eax, [initoffset]
 call printstring

 call clearscreen


 hlt
 jmp $

[sectalign 16]
%line 350+0 bootloader.asm
times (((16) - (($-$$) % (16))) % (16)) nop
%line 351+1 bootloader.asm
idt_descriptor:
 dw (256 * 8) - 1
 dd idt_buffer

idt_buffer times 2048 db 0

%line 193+1 bootloader.asm
isr0:
 push 0
 push 0
 jmp default_handler
%line 193+1 bootloader.asm
isr1:
 push 0
 push 1
 jmp default_handler
%line 193+1 bootloader.asm
isr2:
 push 0
 push 2
 jmp default_handler
%line 193+1 bootloader.asm
isr3:
 push 0
 push 3
 jmp default_handler
%line 193+1 bootloader.asm
isr4:
 push 0
 push 4
 jmp default_handler
%line 193+1 bootloader.asm
isr5:
 push 0
 push 5
 jmp default_handler
%line 193+1 bootloader.asm
isr6:
 push 0
 push 6
 jmp default_handler
%line 193+1 bootloader.asm
isr7:
 push 0
 push 7
 jmp default_handler
%line 200+1 bootloader.asm
isr8:
 push 8
 jmp default_handler
%line 193+1 bootloader.asm
isr9:
 push 0
 push 9
 jmp default_handler
%line 200+1 bootloader.asm
isr10:
 push 10
 jmp default_handler
%line 200+1 bootloader.asm
isr11:
 push 11
 jmp default_handler
%line 200+1 bootloader.asm
isr12:
 push 12
 jmp default_handler
%line 200+1 bootloader.asm
isr13:
 push 13
 jmp default_handler
%line 200+1 bootloader.asm
isr14:
 push 14
 jmp default_handler
%line 193+1 bootloader.asm
isr15:
 push 0
 push 15
 jmp default_handler
%line 193+1 bootloader.asm
isr16:
 push 0
 push 16
 jmp default_handler
%line 200+1 bootloader.asm
isr17:
 push 17
 jmp default_handler
%line 193+1 bootloader.asm
isr18:
 push 0
 push 18
 jmp default_handler
%line 193+1 bootloader.asm
isr19:
 push 0
 push 19
 jmp default_handler
%line 193+1 bootloader.asm
isr20:
 push 0
 push 20
 jmp default_handler
%line 200+1 bootloader.asm
isr21:
 push 21
 jmp default_handler
%line 193+1 bootloader.asm
isr22:
 push 0
 push 22
 jmp default_handler
%line 193+1 bootloader.asm
isr23:
 push 0
 push 23
 jmp default_handler
%line 193+1 bootloader.asm
isr24:
 push 0
 push 24
 jmp default_handler
%line 193+1 bootloader.asm
isr25:
 push 0
 push 25
 jmp default_handler
%line 193+1 bootloader.asm
isr26:
 push 0
 push 26
 jmp default_handler
%line 193+1 bootloader.asm
isr27:
 push 0
 push 27
 jmp default_handler
%line 193+1 bootloader.asm
isr28:
 push 0
 push 28
 jmp default_handler
%line 193+1 bootloader.asm
isr29:
 push 0
 push 29
 jmp default_handler
%line 193+1 bootloader.asm
isr30:
 push 0
 push 30
 jmp default_handler
%line 193+1 bootloader.asm
isr31:
 push 0
 push 31
 jmp default_handler
%line 389+1 bootloader.asm

%line 193+1 bootloader.asm
isr32:
 push 0
 push 32
 jmp default_handler
%line 193+1 bootloader.asm
isr33:
 push 0
 push 33
 jmp default_handler
%line 193+1 bootloader.asm
isr34:
 push 0
 push 34
 jmp default_handler
%line 193+1 bootloader.asm
isr35:
 push 0
 push 35
 jmp default_handler
%line 193+1 bootloader.asm
isr36:
 push 0
 push 36
 jmp default_handler
%line 193+1 bootloader.asm
isr37:
 push 0
 push 37
 jmp default_handler
%line 193+1 bootloader.asm
isr38:
 push 0
 push 38
 jmp default_handler
%line 193+1 bootloader.asm
isr39:
 push 0
 push 39
 jmp default_handler
%line 193+1 bootloader.asm
isr40:
 push 0
 push 40
 jmp default_handler
%line 193+1 bootloader.asm
isr41:
 push 0
 push 41
 jmp default_handler
%line 193+1 bootloader.asm
isr42:
 push 0
 push 42
 jmp default_handler
%line 193+1 bootloader.asm
isr43:
 push 0
 push 43
 jmp default_handler
%line 193+1 bootloader.asm
isr44:
 push 0
 push 44
 jmp default_handler
%line 193+1 bootloader.asm
isr45:
 push 0
 push 45
 jmp default_handler
%line 193+1 bootloader.asm
isr46:
 push 0
 push 46
 jmp default_handler
%line 193+1 bootloader.asm
isr47:
 push 0
 push 47
 jmp default_handler
%line 193+1 bootloader.asm
isr48:
 push 0
 push 48
 jmp default_handler
%line 193+1 bootloader.asm
isr49:
 push 0
 push 49
 jmp default_handler
%line 193+1 bootloader.asm
isr50:
 push 0
 push 50
 jmp default_handler
%line 193+1 bootloader.asm
isr51:
 push 0
 push 51
 jmp default_handler
%line 193+1 bootloader.asm
isr52:
 push 0
 push 52
 jmp default_handler
%line 193+1 bootloader.asm
isr53:
 push 0
 push 53
 jmp default_handler
%line 193+1 bootloader.asm
isr54:
 push 0
 push 54
 jmp default_handler
%line 193+1 bootloader.asm
isr55:
 push 0
 push 55
 jmp default_handler
%line 193+1 bootloader.asm
isr56:
 push 0
 push 56
 jmp default_handler
%line 193+1 bootloader.asm
isr57:
 push 0
 push 57
 jmp default_handler
%line 193+1 bootloader.asm
isr58:
 push 0
 push 58
 jmp default_handler
%line 193+1 bootloader.asm
isr59:
 push 0
 push 59
 jmp default_handler
%line 193+1 bootloader.asm
isr60:
 push 0
 push 60
 jmp default_handler
%line 193+1 bootloader.asm
isr61:
 push 0
 push 61
 jmp default_handler
%line 193+1 bootloader.asm
isr62:
 push 0
 push 62
 jmp default_handler
%line 193+1 bootloader.asm
isr63:
 push 0
 push 63
 jmp default_handler
%line 193+1 bootloader.asm
isr64:
 push 0
 push 64
 jmp default_handler
%line 193+1 bootloader.asm
isr65:
 push 0
 push 65
 jmp default_handler
%line 193+1 bootloader.asm
isr66:
 push 0
 push 66
 jmp default_handler
%line 193+1 bootloader.asm
isr67:
 push 0
 push 67
 jmp default_handler
%line 193+1 bootloader.asm
isr68:
 push 0
 push 68
 jmp default_handler
%line 193+1 bootloader.asm
isr69:
 push 0
 push 69
 jmp default_handler
%line 193+1 bootloader.asm
isr70:
 push 0
 push 70
 jmp default_handler
%line 193+1 bootloader.asm
isr71:
 push 0
 push 71
 jmp default_handler
%line 193+1 bootloader.asm
isr72:
 push 0
 push 72
 jmp default_handler
%line 193+1 bootloader.asm
isr73:
 push 0
 push 73
 jmp default_handler
%line 193+1 bootloader.asm
isr74:
 push 0
 push 74
 jmp default_handler
%line 193+1 bootloader.asm
isr75:
 push 0
 push 75
 jmp default_handler
%line 193+1 bootloader.asm
isr76:
 push 0
 push 76
 jmp default_handler
%line 193+1 bootloader.asm
isr77:
 push 0
 push 77
 jmp default_handler
%line 193+1 bootloader.asm
isr78:
 push 0
 push 78
 jmp default_handler
%line 193+1 bootloader.asm
isr79:
 push 0
 push 79
 jmp default_handler
%line 193+1 bootloader.asm
isr80:
 push 0
 push 80
 jmp default_handler
%line 193+1 bootloader.asm
isr81:
 push 0
 push 81
 jmp default_handler
%line 193+1 bootloader.asm
isr82:
 push 0
 push 82
 jmp default_handler
%line 193+1 bootloader.asm
isr83:
 push 0
 push 83
 jmp default_handler
%line 193+1 bootloader.asm
isr84:
 push 0
 push 84
 jmp default_handler
%line 193+1 bootloader.asm
isr85:
 push 0
 push 85
 jmp default_handler
%line 193+1 bootloader.asm
isr86:
 push 0
 push 86
 jmp default_handler
%line 193+1 bootloader.asm
isr87:
 push 0
 push 87
 jmp default_handler
%line 193+1 bootloader.asm
isr88:
 push 0
 push 88
 jmp default_handler
%line 193+1 bootloader.asm
isr89:
 push 0
 push 89
 jmp default_handler
%line 193+1 bootloader.asm
isr90:
 push 0
 push 90
 jmp default_handler
%line 193+1 bootloader.asm
isr91:
 push 0
 push 91
 jmp default_handler
%line 193+1 bootloader.asm
isr92:
 push 0
 push 92
 jmp default_handler
%line 193+1 bootloader.asm
isr93:
 push 0
 push 93
 jmp default_handler
%line 193+1 bootloader.asm
isr94:
 push 0
 push 94
 jmp default_handler
%line 193+1 bootloader.asm
isr95:
 push 0
 push 95
 jmp default_handler
%line 193+1 bootloader.asm
isr96:
 push 0
 push 96
 jmp default_handler
%line 193+1 bootloader.asm
isr97:
 push 0
 push 97
 jmp default_handler
%line 193+1 bootloader.asm
isr98:
 push 0
 push 98
 jmp default_handler
%line 193+1 bootloader.asm
isr99:
 push 0
 push 99
 jmp default_handler
%line 193+1 bootloader.asm
isr100:
 push 0
 push 100
 jmp default_handler
%line 193+1 bootloader.asm
isr101:
 push 0
 push 101
 jmp default_handler
%line 193+1 bootloader.asm
isr102:
 push 0
 push 102
 jmp default_handler
%line 193+1 bootloader.asm
isr103:
 push 0
 push 103
 jmp default_handler
%line 193+1 bootloader.asm
isr104:
 push 0
 push 104
 jmp default_handler
%line 193+1 bootloader.asm
isr105:
 push 0
 push 105
 jmp default_handler
%line 193+1 bootloader.asm
isr106:
 push 0
 push 106
 jmp default_handler
%line 193+1 bootloader.asm
isr107:
 push 0
 push 107
 jmp default_handler
%line 193+1 bootloader.asm
isr108:
 push 0
 push 108
 jmp default_handler
%line 193+1 bootloader.asm
isr109:
 push 0
 push 109
 jmp default_handler
%line 193+1 bootloader.asm
isr110:
 push 0
 push 110
 jmp default_handler
%line 193+1 bootloader.asm
isr111:
 push 0
 push 111
 jmp default_handler
%line 193+1 bootloader.asm
isr112:
 push 0
 push 112
 jmp default_handler
%line 193+1 bootloader.asm
isr113:
 push 0
 push 113
 jmp default_handler
%line 193+1 bootloader.asm
isr114:
 push 0
 push 114
 jmp default_handler
%line 193+1 bootloader.asm
isr115:
 push 0
 push 115
 jmp default_handler
%line 193+1 bootloader.asm
isr116:
 push 0
 push 116
 jmp default_handler
%line 193+1 bootloader.asm
isr117:
 push 0
 push 117
 jmp default_handler
%line 193+1 bootloader.asm
isr118:
 push 0
 push 118
 jmp default_handler
%line 193+1 bootloader.asm
isr119:
 push 0
 push 119
 jmp default_handler
%line 193+1 bootloader.asm
isr120:
 push 0
 push 120
 jmp default_handler
%line 193+1 bootloader.asm
isr121:
 push 0
 push 121
 jmp default_handler
%line 193+1 bootloader.asm
isr122:
 push 0
 push 122
 jmp default_handler
%line 193+1 bootloader.asm
isr123:
 push 0
 push 123
 jmp default_handler
%line 193+1 bootloader.asm
isr124:
 push 0
 push 124
 jmp default_handler
%line 193+1 bootloader.asm
isr125:
 push 0
 push 125
 jmp default_handler
%line 193+1 bootloader.asm
isr126:
 push 0
 push 126
 jmp default_handler
%line 193+1 bootloader.asm
isr127:
 push 0
 push 127
 jmp default_handler
%line 193+1 bootloader.asm
isr128:
 push 0
 push 128
 jmp default_handler
%line 193+1 bootloader.asm
isr129:
 push 0
 push 129
 jmp default_handler
%line 193+1 bootloader.asm
isr130:
 push 0
 push 130
 jmp default_handler
%line 193+1 bootloader.asm
isr131:
 push 0
 push 131
 jmp default_handler
%line 193+1 bootloader.asm
isr132:
 push 0
 push 132
 jmp default_handler
%line 193+1 bootloader.asm
isr133:
 push 0
 push 133
 jmp default_handler
%line 193+1 bootloader.asm
isr134:
 push 0
 push 134
 jmp default_handler
%line 193+1 bootloader.asm
isr135:
 push 0
 push 135
 jmp default_handler
%line 193+1 bootloader.asm
isr136:
 push 0
 push 136
 jmp default_handler
%line 193+1 bootloader.asm
isr137:
 push 0
 push 137
 jmp default_handler
%line 193+1 bootloader.asm
isr138:
 push 0
 push 138
 jmp default_handler
%line 193+1 bootloader.asm
isr139:
 push 0
 push 139
 jmp default_handler
%line 193+1 bootloader.asm
isr140:
 push 0
 push 140
 jmp default_handler
%line 193+1 bootloader.asm
isr141:
 push 0
 push 141
 jmp default_handler
%line 193+1 bootloader.asm
isr142:
 push 0
 push 142
 jmp default_handler
%line 193+1 bootloader.asm
isr143:
 push 0
 push 143
 jmp default_handler
%line 193+1 bootloader.asm
isr144:
 push 0
 push 144
 jmp default_handler
%line 193+1 bootloader.asm
isr145:
 push 0
 push 145
 jmp default_handler
%line 193+1 bootloader.asm
isr146:
 push 0
 push 146
 jmp default_handler
%line 193+1 bootloader.asm
isr147:
 push 0
 push 147
 jmp default_handler
%line 193+1 bootloader.asm
isr148:
 push 0
 push 148
 jmp default_handler
%line 193+1 bootloader.asm
isr149:
 push 0
 push 149
 jmp default_handler
%line 193+1 bootloader.asm
isr150:
 push 0
 push 150
 jmp default_handler
%line 193+1 bootloader.asm
isr151:
 push 0
 push 151
 jmp default_handler
%line 193+1 bootloader.asm
isr152:
 push 0
 push 152
 jmp default_handler
%line 193+1 bootloader.asm
isr153:
 push 0
 push 153
 jmp default_handler
%line 193+1 bootloader.asm
isr154:
 push 0
 push 154
 jmp default_handler
%line 193+1 bootloader.asm
isr155:
 push 0
 push 155
 jmp default_handler
%line 193+1 bootloader.asm
isr156:
 push 0
 push 156
 jmp default_handler
%line 193+1 bootloader.asm
isr157:
 push 0
 push 157
 jmp default_handler
%line 193+1 bootloader.asm
isr158:
 push 0
 push 158
 jmp default_handler
%line 193+1 bootloader.asm
isr159:
 push 0
 push 159
 jmp default_handler
%line 193+1 bootloader.asm
isr160:
 push 0
 push 160
 jmp default_handler
%line 193+1 bootloader.asm
isr161:
 push 0
 push 161
 jmp default_handler
%line 193+1 bootloader.asm
isr162:
 push 0
 push 162
 jmp default_handler
%line 193+1 bootloader.asm
isr163:
 push 0
 push 163
 jmp default_handler
%line 193+1 bootloader.asm
isr164:
 push 0
 push 164
 jmp default_handler
%line 193+1 bootloader.asm
isr165:
 push 0
 push 165
 jmp default_handler
%line 193+1 bootloader.asm
isr166:
 push 0
 push 166
 jmp default_handler
%line 193+1 bootloader.asm
isr167:
 push 0
 push 167
 jmp default_handler
%line 193+1 bootloader.asm
isr168:
 push 0
 push 168
 jmp default_handler
%line 193+1 bootloader.asm
isr169:
 push 0
 push 169
 jmp default_handler
%line 193+1 bootloader.asm
isr170:
 push 0
 push 170
 jmp default_handler
%line 193+1 bootloader.asm
isr171:
 push 0
 push 171
 jmp default_handler
%line 193+1 bootloader.asm
isr172:
 push 0
 push 172
 jmp default_handler
%line 193+1 bootloader.asm
isr173:
 push 0
 push 173
 jmp default_handler
%line 193+1 bootloader.asm
isr174:
 push 0
 push 174
 jmp default_handler
%line 193+1 bootloader.asm
isr175:
 push 0
 push 175
 jmp default_handler
%line 193+1 bootloader.asm
isr176:
 push 0
 push 176
 jmp default_handler
%line 193+1 bootloader.asm
isr177:
 push 0
 push 177
 jmp default_handler
%line 193+1 bootloader.asm
isr178:
 push 0
 push 178
 jmp default_handler
%line 193+1 bootloader.asm
isr179:
 push 0
 push 179
 jmp default_handler
%line 193+1 bootloader.asm
isr180:
 push 0
 push 180
 jmp default_handler
%line 193+1 bootloader.asm
isr181:
 push 0
 push 181
 jmp default_handler
%line 193+1 bootloader.asm
isr182:
 push 0
 push 182
 jmp default_handler
%line 193+1 bootloader.asm
isr183:
 push 0
 push 183
 jmp default_handler
%line 193+1 bootloader.asm
isr184:
 push 0
 push 184
 jmp default_handler
%line 193+1 bootloader.asm
isr185:
 push 0
 push 185
 jmp default_handler
%line 193+1 bootloader.asm
isr186:
 push 0
 push 186
 jmp default_handler
%line 193+1 bootloader.asm
isr187:
 push 0
 push 187
 jmp default_handler
%line 193+1 bootloader.asm
isr188:
 push 0
 push 188
 jmp default_handler
%line 193+1 bootloader.asm
isr189:
 push 0
 push 189
 jmp default_handler
%line 193+1 bootloader.asm
isr190:
 push 0
 push 190
 jmp default_handler
%line 193+1 bootloader.asm
isr191:
 push 0
 push 191
 jmp default_handler
%line 193+1 bootloader.asm
isr192:
 push 0
 push 192
 jmp default_handler
%line 193+1 bootloader.asm
isr193:
 push 0
 push 193
 jmp default_handler
%line 193+1 bootloader.asm
isr194:
 push 0
 push 194
 jmp default_handler
%line 193+1 bootloader.asm
isr195:
 push 0
 push 195
 jmp default_handler
%line 193+1 bootloader.asm
isr196:
 push 0
 push 196
 jmp default_handler
%line 193+1 bootloader.asm
isr197:
 push 0
 push 197
 jmp default_handler
%line 193+1 bootloader.asm
isr198:
 push 0
 push 198
 jmp default_handler
%line 193+1 bootloader.asm
isr199:
 push 0
 push 199
 jmp default_handler
%line 193+1 bootloader.asm
isr200:
 push 0
 push 200
 jmp default_handler
%line 193+1 bootloader.asm
isr201:
 push 0
 push 201
 jmp default_handler
%line 193+1 bootloader.asm
isr202:
 push 0
 push 202
 jmp default_handler
%line 193+1 bootloader.asm
isr203:
 push 0
 push 203
 jmp default_handler
%line 193+1 bootloader.asm
isr204:
 push 0
 push 204
 jmp default_handler
%line 193+1 bootloader.asm
isr205:
 push 0
 push 205
 jmp default_handler
%line 193+1 bootloader.asm
isr206:
 push 0
 push 206
 jmp default_handler
%line 193+1 bootloader.asm
isr207:
 push 0
 push 207
 jmp default_handler
%line 193+1 bootloader.asm
isr208:
 push 0
 push 208
 jmp default_handler
%line 193+1 bootloader.asm
isr209:
 push 0
 push 209
 jmp default_handler
%line 193+1 bootloader.asm
isr210:
 push 0
 push 210
 jmp default_handler
%line 193+1 bootloader.asm
isr211:
 push 0
 push 211
 jmp default_handler
%line 193+1 bootloader.asm
isr212:
 push 0
 push 212
 jmp default_handler
%line 193+1 bootloader.asm
isr213:
 push 0
 push 213
 jmp default_handler
%line 193+1 bootloader.asm
isr214:
 push 0
 push 214
 jmp default_handler
%line 193+1 bootloader.asm
isr215:
 push 0
 push 215
 jmp default_handler
%line 193+1 bootloader.asm
isr216:
 push 0
 push 216
 jmp default_handler
%line 193+1 bootloader.asm
isr217:
 push 0
 push 217
 jmp default_handler
%line 193+1 bootloader.asm
isr218:
 push 0
 push 218
 jmp default_handler
%line 193+1 bootloader.asm
isr219:
 push 0
 push 219
 jmp default_handler
%line 193+1 bootloader.asm
isr220:
 push 0
 push 220
 jmp default_handler
%line 193+1 bootloader.asm
isr221:
 push 0
 push 221
 jmp default_handler
%line 193+1 bootloader.asm
isr222:
 push 0
 push 222
 jmp default_handler
%line 193+1 bootloader.asm
isr223:
 push 0
 push 223
 jmp default_handler
%line 193+1 bootloader.asm
isr224:
 push 0
 push 224
 jmp default_handler
%line 193+1 bootloader.asm
isr225:
 push 0
 push 225
 jmp default_handler
%line 193+1 bootloader.asm
isr226:
 push 0
 push 226
 jmp default_handler
%line 193+1 bootloader.asm
isr227:
 push 0
 push 227
 jmp default_handler
%line 193+1 bootloader.asm
isr228:
 push 0
 push 228
 jmp default_handler
%line 193+1 bootloader.asm
isr229:
 push 0
 push 229
 jmp default_handler
%line 193+1 bootloader.asm
isr230:
 push 0
 push 230
 jmp default_handler
%line 193+1 bootloader.asm
isr231:
 push 0
 push 231
 jmp default_handler
%line 193+1 bootloader.asm
isr232:
 push 0
 push 232
 jmp default_handler
%line 193+1 bootloader.asm
isr233:
 push 0
 push 233
 jmp default_handler
%line 193+1 bootloader.asm
isr234:
 push 0
 push 234
 jmp default_handler
%line 193+1 bootloader.asm
isr235:
 push 0
 push 235
 jmp default_handler
%line 193+1 bootloader.asm
isr236:
 push 0
 push 236
 jmp default_handler
%line 193+1 bootloader.asm
isr237:
 push 0
 push 237
 jmp default_handler
%line 193+1 bootloader.asm
isr238:
 push 0
 push 238
 jmp default_handler
%line 193+1 bootloader.asm
isr239:
 push 0
 push 239
 jmp default_handler
%line 193+1 bootloader.asm
isr240:
 push 0
 push 240
 jmp default_handler
%line 193+1 bootloader.asm
isr241:
 push 0
 push 241
 jmp default_handler
%line 193+1 bootloader.asm
isr242:
 push 0
 push 242
 jmp default_handler
%line 193+1 bootloader.asm
isr243:
 push 0
 push 243
 jmp default_handler
%line 193+1 bootloader.asm
isr244:
 push 0
 push 244
 jmp default_handler
%line 193+1 bootloader.asm
isr245:
 push 0
 push 245
 jmp default_handler
%line 193+1 bootloader.asm
isr246:
 push 0
 push 246
 jmp default_handler
%line 193+1 bootloader.asm
isr247:
 push 0
 push 247
 jmp default_handler
%line 193+1 bootloader.asm
isr248:
 push 0
 push 248
 jmp default_handler
%line 193+1 bootloader.asm
isr249:
 push 0
 push 249
 jmp default_handler
%line 193+1 bootloader.asm
isr250:
 push 0
 push 250
 jmp default_handler
%line 193+1 bootloader.asm
isr251:
 push 0
 push 251
 jmp default_handler
%line 193+1 bootloader.asm
isr252:
 push 0
 push 252
 jmp default_handler
%line 193+1 bootloader.asm
isr253:
 push 0
 push 253
 jmp default_handler
%line 193+1 bootloader.asm
isr254:
 push 0
 push 254
 jmp default_handler
%line 193+1 bootloader.asm
isr255:
 push 0
 push 255
 jmp default_handler
%line 395+1 bootloader.asm

isr_stub:
 dd isr0, isr1, isr2, isr3, isr4, isr5, isr6, isr7, isr8, isr9, isr10, isr11, isr12, isr13, isr14, isr15, isr16, isr17, isr18
 dd isr19, isr20, isr21, isr22, isr23, isr24, isr25, isr26, isr27, isr28, isr29, isr30, isr31

%line 402+1 bootloader.asm
 dd isr32
%line 402+0 bootloader.asm
 dd isr33
 dd isr34
 dd isr35
 dd isr36
 dd isr37
 dd isr38
 dd isr39
 dd isr40
 dd isr41
 dd isr42
 dd isr43
 dd isr44
 dd isr45
 dd isr46
 dd isr47
 dd isr48
 dd isr49
 dd isr50
 dd isr51
 dd isr52
 dd isr53
 dd isr54
 dd isr55
 dd isr56
 dd isr57
 dd isr58
 dd isr59
 dd isr60
 dd isr61
 dd isr62
 dd isr63
 dd isr64
 dd isr65
 dd isr66
 dd isr67
 dd isr68
 dd isr69
 dd isr70
 dd isr71
 dd isr72
 dd isr73
 dd isr74
 dd isr75
 dd isr76
 dd isr77
 dd isr78
 dd isr79
 dd isr80
 dd isr81
 dd isr82
 dd isr83
 dd isr84
 dd isr85
 dd isr86
 dd isr87
 dd isr88
 dd isr89
 dd isr90
 dd isr91
 dd isr92
 dd isr93
 dd isr94
 dd isr95
 dd isr96
 dd isr97
 dd isr98
 dd isr99
 dd isr100
 dd isr101
 dd isr102
 dd isr103
 dd isr104
 dd isr105
 dd isr106
 dd isr107
 dd isr108
 dd isr109
 dd isr110
 dd isr111
 dd isr112
 dd isr113
 dd isr114
 dd isr115
 dd isr116
 dd isr117
 dd isr118
 dd isr119
 dd isr120
 dd isr121
 dd isr122
 dd isr123
 dd isr124
 dd isr125
 dd isr126
 dd isr127
 dd isr128
 dd isr129
 dd isr130
 dd isr131
 dd isr132
 dd isr133
 dd isr134
 dd isr135
 dd isr136
 dd isr137
 dd isr138
 dd isr139
 dd isr140
 dd isr141
 dd isr142
 dd isr143
 dd isr144
 dd isr145
 dd isr146
 dd isr147
 dd isr148
 dd isr149
 dd isr150
 dd isr151
 dd isr152
 dd isr153
 dd isr154
 dd isr155
 dd isr156
 dd isr157
 dd isr158
 dd isr159
 dd isr160
 dd isr161
 dd isr162
 dd isr163
 dd isr164
 dd isr165
 dd isr166
 dd isr167
 dd isr168
 dd isr169
 dd isr170
 dd isr171
 dd isr172
 dd isr173
 dd isr174
 dd isr175
 dd isr176
 dd isr177
 dd isr178
 dd isr179
 dd isr180
 dd isr181
 dd isr182
 dd isr183
 dd isr184
 dd isr185
 dd isr186
 dd isr187
 dd isr188
 dd isr189
 dd isr190
 dd isr191
 dd isr192
 dd isr193
 dd isr194
 dd isr195
 dd isr196
 dd isr197
 dd isr198
 dd isr199
 dd isr200
 dd isr201
 dd isr202
 dd isr203
 dd isr204
 dd isr205
 dd isr206
 dd isr207
 dd isr208
 dd isr209
 dd isr210
 dd isr211
 dd isr212
 dd isr213
 dd isr214
 dd isr215
 dd isr216
 dd isr217
 dd isr218
 dd isr219
 dd isr220
 dd isr221
 dd isr222
 dd isr223
 dd isr224
 dd isr225
 dd isr226
 dd isr227
 dd isr228
 dd isr229
 dd isr230
 dd isr231
 dd isr232
 dd isr233
 dd isr234
 dd isr235
 dd isr236
 dd isr237
 dd isr238
 dd isr239
 dd isr240
 dd isr241
 dd isr242
 dd isr243
 dd isr244
 dd isr245
 dd isr246
 dd isr247
 dd isr248
 dd isr249
 dd isr250
 dd isr251
 dd isr252
 dd isr253
 dd isr254
 dd isr255
%line 405+0 bootloader.asm

%line 406+1 bootloader.asm






default_handler:
 pushfd
 cli
 pushad
 cld


 mov eax, [esp + 36]
 mov ebx, [esp + 40]

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
 times 12 dd NULLFAULT
 dd timer_handler
 dd keyboard_handler
 times 7 dd NULLFAULT
 dd stdprint

stdprint:


 bt [writeactiveflag], 0
 jc stdprint
 bts [writeactiveflag], 0
 pushad
 mov edi, keyboardringbuffer
 mov ebx, dword [newringoffset]
 mov edx, dword [endoffset]
 add edi, ebx
 cmp ecx, 0xFFFFFFFF
 je .nullterm
 rep movsb
 add dword [newringoffset], ecx
 call printscreen
 mov edx, [newringoffset]
 mov [endoffset], edx
 popad
 btr [writeactiveflag], 0
 ret
.nullterm:
 mov al, byte [esi]
 test al, al
 jz .finish
 inc esi
 mov byte [edi], al
 inc edi
 inc dword [newringoffset]
 jmp .nullterm
.finish:
 call printscreen
 popad
 btr [writeactiveflag], 0
 ret


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
 jmp $
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
 ret
OverFlow:
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2) / 4
 mov eax, 0x000
 rep stosd
 mov esi, overflowmsg
 xor eax, eax
 mov ebx, 0xF800
 call printstring
 hlt
 jmp $

ExceedsBounds:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, exceedsboundsmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 541+1 bootloader.asm
 hlt
 jmp $

InvalidOpcode:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x0000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, invalidopcodemsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 548+1 bootloader.asm
DevNotAvail:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, devnotavailmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 552+1 bootloader.asm
DoubleFault:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, doublefaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 555+1 bootloader.asm
 ret
TSSCorrupt:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, tsscorruptmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 560+1 bootloader.asm
InvalidSegment:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, invsegmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 564+1 bootloader.asm
StackFault:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, stackfaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 568+1 bootloader.asm
GPFault:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, gpfaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 572+1 bootloader.asm
Page:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, pagefaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 575+1 bootloader.asm
 ret
FPUError:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, fpuerrormsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 579+1 bootloader.asm
 ret
AlignFault:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, alignfaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 583+1 bootloader.asm
 ret
MachineFault:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, machinefaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 219+1 bootloader.asm
 hlt
 jmp $
%line 588+1 bootloader.asm
SimdFault:
%line 207+1 bootloader.asm
 mov edi, [framebuffer]
 mov ecx, (800 * 600 * 2)
 mov eax, 0x00000000
 rep stosd
%line 213+1 bootloader.asm
 mov esi, simdfaultmsg
 mov eax, 0
 mov ebx, 0xF800
 call printstring
%line 591+1 bootloader.asm
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

printchar:
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
 lea esi, [chars + eax*8]

 xor ecx, ecx

.printsetup:
 xor eax, eax
 xor edx, edx
 mov ax, word [esi + ecx*2]
.byrow:

 mov ebx, 15
 sub ebx, edx
 bt eax, ebx
 jc .printpix
.printed:
 inc edx
 cmp edx, 16
 jle .byrow
 inc ecx
 cmp ecx, 16
 jle .preseter

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
 mov word [edi + edx*2], 0xFFFF
 pop ebx
 jmp .printed

printstring:
 pushfd
 cli
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
.space:
 add dword [printarguments], 32

 jmp .loop
.endprint:
 popad
 popfd
 ret

times 16 db 0

keyboard_handler:
 in al, 0x60
 cmp al, 0xAA
 je unshift
 cmp al, 0xB6
 je unshift
 cmp al, 0x80
 jae skipkeyboard
 cmp al, 0x2A
 je shift
 cmp al, 0x36
 je shift
 cmp al, 0x0E
 je backspace
 cmp al, 0x1C
 je skipperkb


 cmp byte [iscapitol], 0
 jnz uppercase
 movzx eax, al

 movzx eax, byte [chartab + eax]

possiblyshifted:
 push ebx
 mov ebx, [newringoffset]
 mov byte [keyboardringbuffer + ebx], al
 inc dword [newringoffset]
 mov byte [keyboardringbuffer + ebx + 1], 0
 pop ebx
skipkeyboard:

 mov al, 0x20
 out 0x20, al
 mov word [printarguments + 5], 0xFFFF
 call printscreen
 ret
skipperkb:
 mov ebx, [newringoffset]
 mov byte [keyboardringbuffer + ebx], 0x0D
 mov byte [keyboardringbuffer + ebx + 1], 0x0A
 mov byte [keyboardringbuffer + ebx + 2], 0x00
 add dword [newringoffset], 2
 mov al, 0x20
 out 0x20, al
 call printscreen
 ret

uppercase:

 movzx eax, al
 movzx eax, byte [chartabshift + eax]
 push ebx
 mov ebx, [newringoffset]
 mov byte [keyboardringbuffer + ebx], al
 inc dword [newringoffset]
 mov byte [keyboardringbuffer + ebx + 1], 0
 pop ebx
 jmp skipkeyboard

extension:

 in al, 0x60
 cmp al, 0

shift:
 mov byte [iscapitol], 1
 jmp skipkeyboard

unshift:
 mov byte [iscapitol], 0
 jmp skipkeyboard
backspace:
 push edi
 mov ecx, [newringoffset]
 mov byte [keyboardringbuffer + ecx - 1], 0x20

 dec dword [newringoffset]
 sub dword [printarguments], 32
 mov edi, [framebuffer]
 mov ebx, [printarguments]
 xor edx, edx
 add edi, ebx
.backouterloop:
 xor ecx, ecx
.backinnerloop:
 mov dword [edi + ecx * 2], 0x0000
 inc ecx
 cmp ecx, 16
 jle .backinnerloop
 movzx ebx, word [pitch]
 inc edx
 add edi, ebx
 cmp edx, 16
 jle .backouterloop
 pop edi
 mov al, 0x20
 out 0x20, al
 ret

clearscreen:
 pushfd
 cli
 pushad
 mov edi, [framebuffer]
 mov ecx, (600 * 800) / 2
 mov eax, 0x00000000
 rep stosd
 mov dword [newringoffset], 0
 mov dword [endoffset], 0
 mov byte [keyboardringbuffer + 1961], 0
 mov dword [initoffset], 0

 mov edi, keyboardringbuffer
 mov ecx, 1962
 mov eax, 0x00
 rep stosb

 mov esi, cmdprmpt
 mov ebx, 0xF800
 mov eax, 0
 call printstring
 add dword [initoffset], 32

 popad
 popfd
 ret

printscreen:
 pushad



 mov esi, keyboardringbuffer

 add esi, [endoffset]
 mov ebx, 0x0F80
 call printstring
 mov edi, [endoffset]
 mov [initoffset], edi
 popad
 ret

 errorcodes dd 0
printarguments:
 dd 0
 db 0
 dw 0
 db 0

cmdparser:
 pushad
 test eax, eax
 jnz .entered
 cld
 mov edi, cmdbuffer
 xor eax, eax
 mov ecx, 32
 rep stosb


 mov esi, keyboardringbuffer
 mov ebx, [endoffset]
 mov ecx, [newringoffset]
 mov edi, cmdbuffer
 add esi, ebx
 sub ecx, ebx
 rep movsb



 cmp word [cmdbuffer], "ls"
 je .listcontents
 cmp word [cmdbuffer], "cd"
 je .changedir
 cmp word [cmdbuffer], "mv"
 je .movefile
 cmp word [cmdbuffer], "rm"
 je .delete
 cmp word [cmdbuffer], "wx"
 je .edit
 cmp dword [cmdbuffer], "clrs"
 je .clear


 movzx ecx, byte [cmdbuffer]
 mov edi, cmdtable


 mov ecx, [esi + ecx * 4]
 jmp ecx




%line 4+1 macros.inc
chars:
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_exclam:
 dw 0x0000,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180
 dw 0x0180,0x0000,0x0180,0x0180,0x0000,0x0000,0x0000,0x0000


c_quote:
 dw 0x0000,0x0C30,0x0C30,0x0C30,0x0C30,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_hash:
 dw 0x0000,0x0660,0x0660,0x7FFE,0x0660,0x0660,0x0660,0x7FFE
 dw 0x0660,0x0660,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_dollar:
 dw 0x0000,0x0FF0,0x1818,0x1818,0x0FF0,0x0600,0x0600,0x0FF0
 dw 0x0180,0x0180,0x0FF0,0x0000,0x0000,0x0000,0x0000,0x0000


c_percent:
 dw 0x0000,0x3060,0x3060,0x0060,0x00C0,0x0180,0x0300,0x0600
 dw 0x0C30,0x0C30,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_amp:
 dw 0x0000,0x0180,0x03C0,0x0660,0x0660,0x03C0,0x1B98,0x3366
 dw 0x3306,0x1FFC,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_apostrophe:
 dw 0x0000,0x0180,0x0180,0x0180,0x0000,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_l_paren:
 dw 0x0000,0x0180,0x0C00,0x1800,0x1800,0x1800,0x1800,0x1800
 dw 0x1800,0x1800,0x0C00,0x0180,0x0000,0x0000,0x0000,0x0000


c_r_paren:
 dw 0x0000,0x0C00,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180
 dw 0x0180,0x0180,0x0180,0x0C00,0x0000,0x0000,0x0000,0x0000


c_asterisk:
 dw 0x0000,0x0000,0x0180,0x0FF0,0x03C0,0x0FF0,0x0180,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_plus:
 dw 0x0000,0x0000,0x0180,0x0180,0x7FFE,0x0180,0x0180,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_comma:
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x03C0,0x03C0,0x0300,0x0C00,0x0000,0x0000


c_dash:
 dw 0x0000,0x0000,0x0000,0x0000,0x7FFE,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_point:
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x03C0,0x03C0,0x03C0,0x03C0,0x0000,0x0000


c_slash:
 dw 0x0000,0x0006,0x000C,0x0018,0x0030,0x0060,0x00C0,0x0180
 dw 0x0300,0x0600,0x0C00,0x1800,0x3000,0x6000,0x0000,0x0000


c_0:
 dw 0x0000,0x1FF8,0x3FFC,0x6006,0x6006,0x6006,0x6006,0x6006
 dw 0x6006,0x6006,0x6006,0x6006,0x3FFC,0x1FF8,0x0000,0x0000


c_1:
 dw 0x0000,0x0180,0x0380,0x0780,0x0F80,0x0180,0x0180,0x0180
 dw 0x0180,0x0180,0x0180,0x0180,0x1FF8,0x1FF8,0x0000,0x0000


c_2:
 dw 0x0000,0x3FF0,0x7FF8,0x600C,0x600C,0x000C,0x0018,0x0030
 dw 0x0060,0x00C0,0x0180,0x0300,0x7FFE,0x7FFE,0x0000,0x0000


c_3:
 dw 0x0000,0x7FFE,0x7FFE,0x000C,0x0018,0x0030,0x01F0,0x01F0
 dw 0x0030,0x0018,0x000C,0x600C,0x7FF8,0x3FF0,0x0000,0x0000


c_4:
 dw 0x0000,0x0018,0x0038,0x0078,0x00D8,0x0198,0x0318,0x0618
 dw 0x0C18,0x1818,0x7FFE,0x7FFE,0x0018,0x0018,0x0000,0x0000


c_5:
 dw 0x0000,0x7FFE,0x7FFE,0x6000,0x6000,0x7FF8,0x7FFC,0x000E
 dw 0x0006,0x0006,0x0006,0x6006,0x7FFC,0x3FF8,0x0000,0x0000


c_6:
 dw 0x0000,0x1FF0,0x3FF8,0x6000,0x6000,0x7FF0,0x7FFC,0x600E
 dw 0x6006,0x6006,0x6006,0x6006,0x3FFC,0x1FF8,0x0000,0x0000


c_7:
 dw 0x0000,0x7FFE,0x7FFE,0x0006,0x000C,0x0018,0x0030,0x0060
 dw 0x00C0,0x0180,0x0300,0x0600,0x0C00,0x1800,0x0000,0x0000


c_8:
 dw 0x0000,0x1FF0,0x3FF8,0x600C,0x600C,0x3FF0,0x1FF0,0x3FF8
 dw 0x600C,0x600C,0x600C,0x600C,0x3FF8,0x1FF0,0x0000,0x0000


c_9:
 dw 0x0000,0x1FF0,0x3FF8,0x6006,0x6006,0x6006,0x3FFC,0x1FFC
 dw 0x000C,0x000C,0x000C,0x600C,0x7FF8,0x3FF0,0x0000,0x0000


c_colon:
 dw 0x0000,0x0000,0x0180,0x0180,0x0000,0x0000,0x0180,0x0180
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_semicolon:
 dw 0x0000,0x0000,0x0180,0x0180,0x0000,0x0000,0x0180,0x0180
 dw 0x0000,0x0000,0x03C0,0x03C0,0x0300,0x0C00,0x0000,0x0000


c_l_than:
 dw 0x0000,0x0000,0x0006,0x000C,0x0018,0x0030,0x0060,0x00C0
 dw 0x0060,0x0030,0x0018,0x000C,0x0006,0x0000,0x0000,0x0000


c_equal:
 dw 0x0000,0x0000,0x0000,0x7FFE,0x0000,0x0000,0x7FFE,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_r_than:
 dw 0x0000,0x0000,0x0600,0x0300,0x0180,0x00C0,0x0060,0x0030
 dw 0x0060,0x00C0,0x0180,0x0300,0x0600,0x0000,0x0000,0x0000


c_question:
 dw 0x0000,0x3FF0,0x6018,0x6018,0x0018,0x0030,0x0060,0x0180
 dw 0x0180,0x0000,0x0180,0x0180,0x0000,0x0000,0x0000,0x0000


c_at:
 dw 0x0000,0x1FF8,0x3FFC,0x6006,0x601E,0x6036,0x6C36,0x6C36
 dw 0x6036,0x601E,0x6000,0x6006,0x3FFC,0x1FF8,0x0000,0x0000

 c_A dw 0x0000, 0x0180, 0x03C0, 0x0660, 0x0C30, 0x1818, 0x300C, 0x6006, 0x7FFE, 0x7FFE, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x0000
 c_B dw 0x0000, 0x7FF8, 0x7FF8, 0x600C, 0x600C, 0x600C, 0x600C, 0x7FF8, 0x7FF8, 0x600C, 0x6006, 0x6006, 0x6006, 0x7FFC, 0x7FFC, 0x0000
 c_C dw 0x0000, 0x1FF8, 0x3FFC, 0x3006, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x3006, 0x3FFC, 0x1FF8, 0x0000
 c_D dw 0x0000, 0x7FE0, 0x7FE0, 0x6030, 0x6018, 0x600C, 0x6006, 0x6006, 0x6006, 0x6006, 0x600C, 0x6018, 0x6030, 0x7FE0, 0x7FE0, 0x0000
 c_E dw 0x0000, 0x7FFE, 0x7FFE, 0x6000, 0x6000, 0x6000, 0x6000, 0x7FFC, 0x7FFC, 0x6000, 0x6000, 0x6000, 0x6000, 0x7FFE, 0x7FFE, 0x0000
 c_F dw 0x0000, 0x7FFE, 0x7FFE, 0x6000, 0x6000, 0x6000, 0x6000, 0x7FFC, 0x7FFC, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x0000
 c_G dw 0x0000, 0x1FF8, 0x1FF8, 0x3000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x603F, 0x6006, 0x6006, 0x6006, 0x1FFE, 0x1FFE, 0x0000
 c_H dw 0x0000, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x7FFE, 0x7FFE, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x0000
 c_I dw 0x0000, 0x7FFE, 0x7FFE, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x7FFE, 0x7FFE, 0x0000
 c_J dw 0x0000, 0x0006, 0x0006, 0x0006, 0x0006, 0x0006, 0x0006, 0x0006, 0x0006, 0x0006, 0x0006, 0x300C, 0x180C, 0x0C30, 0x07E0, 0x0000

 c_K:
 dw 0x0000
 dw 0x6030, 0x6060, 0x60C0, 0x6180, 0x6300, 0x6600, 0x7C00
 dw 0x7C00, 0x6600, 0x6300, 0x6180, 0x60C0, 0x6060, 0x6030
 dw 0x0000

c_L:
 dw 0x0000
 dw 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000
 dw 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x7FFE, 0x7FFE
 dw 0x0000

c_M:
 dw 0x0000
 dw 0x6006, 0x700E, 0x781E, 0x6C36, 0x6666, 0x63C6, 0x6186
 dw 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006
 dw 0x0000

c_N:
 dw 0x0000
 dw 0x6006, 0x7006, 0x7806, 0x6C06, 0x6606, 0x6306, 0x6186
 dw 0x60C6, 0x6066, 0x6036, 0x601E, 0x600E, 0x6006, 0x6006
 dw 0x0000

c_O:
 dw 0x0000
 dw 0x1FF8, 0x3FFC, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006
 dw 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x3FFC, 0x1FF8
 dw 0x0000

c_P:
 dw 0x0000
 dw 0x7FF8, 0x7FFC, 0x600E, 0x600E, 0x600E, 0x7FFC, 0x7FF8
 dw 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000, 0x6000
 dw 0x0000

c_Q:
 dw 0x0000
 dw 0x1FF8, 0x3FFC, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006
 dw 0x6006, 0x6006, 0x6006, 0x6006, 0x3FFC, 0x1FF8, 0x001E
 dw 0x0000

c_R:
 dw 0x0000
 dw 0x7FF8, 0x7FFC, 0x600E, 0x600E, 0x7FFC, 0x7FF8, 0x6600
 dw 0x6300, 0x6180, 0x60C0, 0x6060, 0x6030, 0x6018, 0x600C
 dw 0x0000

c_S:
 dw 0x0000
 dw 0x3FFC, 0x7FFE, 0x6000, 0x6000, 0x3FF0, 0x1FF8, 0x001E
 dw 0x001E, 0x001E, 0x001E, 0x001E, 0x601E, 0x7FFE, 0x3FFC
 dw 0x0000

c_T:
 dw 0x0000
 dw 0x7FFE, 0x7FFE, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180
 dw 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180
 dw 0x0000

c_U:
 dw 0x0000
 dw 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6006
 dw 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x3FFC, 0x1FF8
 dw 0x0000

c_V:
 dw 0x0000
 dw 0x6006, 0x6006, 0x6006, 0x300C, 0x300C, 0x300C, 0x1818
 dw 0x1818, 0x1818, 0x0C30, 0x0C30, 0x0660, 0x03C0, 0x0180
 dw 0x0000

c_W:
 dw 0x0000
 dw 0x6006, 0x6006, 0x6006, 0x6006, 0x6006, 0x6996, 0x6996
 dw 0x6996, 0x6996, 0x366C, 0x366C, 0x366C, 0x1818, 0x1818
 dw 0x0000

c_X:
 dw 0x0000
 dw 0x6006, 0x6006, 0x300C, 0x1818, 0x0C30, 0x0660, 0x03C0
 dw 0x03C0, 0x0660, 0x0C30, 0x1818, 0x300C, 0x6006, 0x6006
 dw 0x0000

c_Y:
 dw 0x0000
 dw 0x6006, 0x6006, 0x300C, 0x1818, 0x0C30, 0x0660, 0x03C0
 dw 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180, 0x0180
 dw 0x0000

c_Z:
 dw 0x0000
 dw 0x7FFE, 0x7FFE, 0x000C, 0x0018, 0x0030, 0x0060, 0x00C0
 dw 0x0180, 0x0300, 0x0600, 0x0C00, 0x1800, 0x7FFE, 0x7FFE
 dw 0x0000


c_l_bracket:
 dw 0x0000,0x3FC0,0x3000,0x3000,0x3000,0x3000,0x3000,0x3000
 dw 0x3000,0x3000,0x3000,0x3000,0x3000,0x3FC0,0x0000,0x0000


c_backslash:
 dw 0x0000,0x6000,0x3000,0x1800,0x0C00,0x0600,0x0300,0x0180
 dw 0x00C0,0x0060,0x0030,0x0018,0x000C,0x0006,0x0000,0x0000


c_r_bracket:
 dw 0x0000,0x03FC,0x000C,0x000C,0x000C,0x000C,0x000C,0x000C
 dw 0x000C,0x000C,0x000C,0x000C,0x000C,0x03FC,0x0000,0x0000


c_caret:
 dw 0x0000,0x0180,0x03C0,0x0660,0x0C30,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_underscore:
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFE,0x0000,0x0000


c_grave:
 dw 0x0000,0x0180,0x00C0,0x0060,0x0000,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000


c_a:
 dw 0x0000,0x0000,0x0000,0x0FF0,0x0FF8,0x000C,0x0FFC,0x0FFC
 dw 0x600C,0x600C,0x3FFC,0x3FFC,0x0000,0x0000,0x0000,0x0000


c_b:
 dw 0x0000,0x6000,0x6000,0x6000,0x7FF0,0x7FFC,0x600C,0x600C
 dw 0x600C,0x600C,0x7FFC,0x7FF0,0x0000,0x0000,0x0000,0x0000


c_c:
 dw 0x0000,0x0000,0x0000,0x1FF8,0x3FFC,0x6006,0x6000,0x6000
 dw 0x6000,0x6006,0x3FFC,0x1FF8,0x0000,0x0000,0x0000,0x0000


c_d:
 dw 0x0000,0x000C,0x000C,0x000C,0x1FFC,0x3FFC,0x600C,0x600C
 dw 0x600C,0x600C,0x3FFC,0x1FFC,0x0000,0x0000,0x0000,0x0000


c_e:
 dw 0x0000,0x0000,0x0000,0x1FF8,0x3FFC,0x6006,0x7FFE,0x7FFE
 dw 0x6000,0x6006,0x3FFC,0x1FF8,0x0000,0x0000,0x0000,0x0000


c_f:
 dw 0x0000,0x0FF8,0x0FF8,0x0180,0x0180,0x07F8,0x07F0,0x0180
 dw 0x0180,0x0180,0x0180,0x0180,0x0000,0x0000,0x0000,0x0000


c_g:
 dw 0x0000,0x0000,0x0000,0x1FFC,0x3FFC,0x600C,0x600C,0x600C
 dw 0x3FFC,0x1FFC,0x000C,0x600C,0x3FF8,0x1FF0,0x0000,0x0000


c_h:
 dw 0x0000,0x6000,0x6000,0x6000,0x7FF0,0x7FFC,0x600C,0x600C
 dw 0x600C,0x600C,0x600C,0x600C,0x0000,0x0000,0x0000,0x0000


c_i:
 dw 0x0000,0x0180,0x0180,0x0000,0x0180,0x0180,0x0180,0x0180
 dw 0x0180,0x0180,0x0180,0x0180,0x0000,0x0000,0x0000,0x0000


c_j:
 dw 0x0000,0x0006,0x0006,0x0000,0x0006,0x0006,0x0006,0x0006
 dw 0x0006,0x0006,0x0006,0x300C,0x180C,0x0C30,0x0000,0x0000


c_k:
 dw 0x0000,0x6000,0x6000,0x6000,0x6030,0x6060,0x60C0,0x6180
 dw 0x6300,0x6600,0x7C00,0x7C00,0x6600,0x6300,0x0000,0x0000


c_l:
 dw 0x0000,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180
 dw 0x0180,0x0180,0x01F8,0x01F8,0x0000,0x0000,0x0000,0x0000


c_m:
 dw 0x0000,0x0000,0x0000,0x6C6C,0x7FFE,0x7FFE,0x6636,0x6030
 dw 0x6030,0x6030,0x6030,0x6030,0x0000,0x0000,0x0000,0x0000


c_n:
 dw 0x0000,0x0000,0x0000,0x7FF0,0x7FFC,0x600C,0x600C,0x600C
 dw 0x600C,0x600C,0x600C,0x600C,0x0000,0x0000,0x0000,0x0000


c_o:
 dw 0x0000,0x0000,0x0000,0x1FF8,0x3FFC,0x6006,0x6006,0x6006
 dw 0x6006,0x6006,0x3FFC,0x1FF8,0x0000,0x0000,0x0000,0x0000


c_p:
 dw 0x0000,0x0000,0x0000,0x7FF0,0x7FFC,0x600C,0x600C,0x600C
 dw 0x7FFC,0x7FF0,0x6000,0x6000,0x0000,0x0000,0x0000,0x0000


c_q:
 dw 0x0000,0x0000,0x0000,0x1FFC,0x3FFC,0x600C,0x600C,0x600C
 dw 0x3FFC,0x1FFC,0x000C,0x000C,0x0000,0x0000,0x0000,0x0000


c_r:
 dw 0x0000,0x0000,0x0000,0x6FF0,0x6FFC,0x600C,0x6000,0x6000
 dw 0x6000,0x6000,0x6000,0x6000,0x0000,0x0000,0x0000,0x0000


c_s:
 dw 0x0000,0x0000,0x0000,0x3FF0,0x7FFC,0x6000,0x3FF0,0x1FF8
 dw 0x000C,0x000C,0x7FF8,0x3FF0,0x0000,0x0000,0x0000,0x0000


c_t:
 dw 0x0000,0x0180,0x0180,0x07F8,0x07F8,0x0180,0x0180,0x0180
 dw 0x0180,0x0180,0x00F8,0x00F0,0x0000,0x0000,0x0000,0x0000


c_u:
 dw 0x0000,0x0000,0x0000,0x600C,0x600C,0x600C,0x600C,0x600C
 dw 0x600C,0x600C,0x3FFC,0x1FFC,0x0000,0x0000,0x0000,0x0000


c_v:
 dw 0x0000,0x0000,0x0000,0x6006,0x6006,0x300C,0x300C,0x1818
 dw 0x0C30,0x0C30,0x0660,0x03C0,0x0180,0x0000,0x0000,0x0000


c_w:
 dw 0x0000,0x0000,0x0000,0x6006,0x6996,0x6996,0x6996,0x366C
 dw 0x366C,0x366C,0x1818,0x1818,0x0000,0x0000,0x0000,0x0000


c_x:
 dw 0x0000,0x0000,0x0000,0x6006,0x300C,0x1818,0x0C30,0x0660
 dw 0x0C30,0x1818,0x300C,0x6006,0x0000,0x0000,0x0000,0x0000


c_y:
 dw 0x0000,0x0000,0x0000,0x6006,0x300C,0x1818,0x0C30,0x0660
 dw 0x0180,0x0180,0x0180,0x0180,0x0000,0x0000,0x0000,0x0000


c_z:
 dw 0x0000,0x0000,0x0000,0x7FFE,0x000C,0x0018,0x0030,0x0060
 dw 0x00C0,0x0180,0x7FFE,0x7FFE,0x0000,0x0000,0x0000,0x0000


c_l_brace:
 dw 0x0000,0x01E0,0x0180,0x0180,0x0180,0x0F00,0x0E00,0x0180
 dw 0x0180,0x0180,0x0180,0x01E0,0x0000,0x0000,0x0000,0x0000


c_pipe:
 dw 0x0000,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180,0x0180
 dw 0x0180,0x0180,0x0180,0x0180,0x0180,0x0180,0x0000,0x0000


c_r_brace:
 dw 0x0000,0x0E00,0x0F00,0x0180,0x0180,0x0180,0x01E0,0x0180
 dw 0x0180,0x0180,0x0180,0x0E00,0x0E00,0x0000,0x0000,0x0000


c_tilde:
 dw 0x0000,0x0000,0x0000,0x0F18,0x1F30,0x0000,0x0000,0x0000
 dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
%line 913+1 bootloader.asm
newlinermsg db " ", 0x0D, 0x0A, 0x00
hexlut db "0123456789ABCDEF"
testmessage db "GDT UP", 0x0D, 0x0A, "STACK UP", 0x0D, 0x0A, "ENTERED PROTECTED MODE", 0x0D, 0x0A, "BEGINNING IDT...", 0x0D, 0x0A, 0x00
divzeromsg db "DIVISION BY ZERO",0x0D, 0x0A, 0x00
idtupmsg db "IDT UP LOADING KERNEL...", 0x0D, 0x0A, 0x00
ioflags db 0
cmdprmpt db "> ", 0x00
clocktimer dq 0
invalidcmd db "Invalid Command :(", 0x0A, 0x0D, "> ", 0x00
dirtest db "Files? What files?", 0x0D, 0x0A, "> ", 0x00
dirtestlen equ $ - dirtest
cdtest db "No other directories. Please add %dir command.", 0x0D, 0x0A, "> ", 0x00
writeactiveflag db 0

[sectalign 4]
%line 927+0 bootloader.asm
times (((4) - (($-$$) % (4))) % (4)) nop
%line 928+1 bootloader.asm
chartab db 0x20, 0x20, "1234567890-=", 0x20, 0x20, "qwertyuiop[]", 0x20, 0x20, "asdfghjkl;'`", 0x20, "\zxcvbnm,./", 0x20, 0x20
chartabshift db 0x20, 0x20, "!@#$%^&*()_+", 0x20, 0x20, "QWERTYUIOP{}", 0x20, 0x20, 'ASDFGHJKL:"~', 0x20, "|ZXCVBNM<>?", 0x20, 0x20


[sectalign 4096]
%line 932+0 bootloader.asm
times (((4096) - (($-$$) % (4096))) % (4096)) nop
%line 933+1 bootloader.asm
pagedir times 1024 dd 0

[sectalign 4096]
%line 935+0 bootloader.asm
times (((4096) - (($-$$) % (4096))) % (4096)) nop
%line 936+1 bootloader.asm
pagetables times (32 * 1024) db 0




[section .bss]
scratchpad resq 1024
filestat resq 256

initoffset resd 1
currentoffset resd 1
keyboardringbuffer resb 1962
newringoffset resd 1
endoffset resd 1
cmdbuffer resb 32
iscapitol resb 1
