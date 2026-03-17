; GRAPHICS FILE FOR 800X600 VESA MODE

putpixel: ; Row+1 in EBX, Column+1 in ECX, color in AX ; clobbers EBX EDI EDX ECX
  dec ebx
  dec ecx
  movzx edx, word [pitch]
  shl ecx, 1
  imul ebx, edx ; get offset
  mov edi, dword [framebuffer]
  add ebx, ecx
  add edi, ebx
  
  ; have offset
  mov word [edi], ax
  ret

putline: ; coordinates at ESI as (ROW+1,COLUMN+1,ROW+1,COLUMN+1), color in AX
  push ebp
  mov ebp, esp
  sub esp, 20 ; ???
  mov ebx, dword [esi + 8] ; dx
  mov ecx, dword [esi + 12] ; dy
  sub ebx, dword [esi]
  js .invertdx
.y:
  mov dword [esp], ebx ; ESP has DX
  sub ecx, dword [esi + 4]
  jns .invertdy
  .dosxcalc:
  mov dword [esp + 4], ecx ; ESP + 4 has DY
  mov ebx, dword [esi + 8]
  mov ecx, dword [esi + 12]
  sub ebx, dword [esi]
  mov edx, 1
  neg ebx
  sbb edx, edx
  or edx, 1
  mov dword [esp + 8], edx ; ESP has SX
  sub ecx, dword [esi + 4]
  mov edx, 1
  neg ecx
  sbb edx, edx
  or edx, 1
  mov dword [esp + 12], edx ; ESP + 4 has SY
  ; get ERROR

  mov edx, dword [esp]
  add edx, dword [esp + 4]
  mov dword [esp + 16], edx

.lineprintloop:
  mov ebx, dword [esi]
  mov ecx, dword [esi + 4]
  dec ebx
  dec ecx
  movzx edx, word [pitch]
  shl ecx, 1
  imul ebx, edx
  mov edi, dword [framebuffer]
  add ebx, ecx
  mov word [edi + ebx], ax

  mov ebx, dword [esi]
  cmp ebx, dword [esi + 8]
  je .xequal
.notequal:
  mov edx, dword [esp + 16]
  lea edx, [edx + edx]
  cmp edx, dword [esp + 4]
  jge .ystep
.ystepped:
  mov ebx, dword [esp]
  cmp edx, ebx
  jle .xstep
.ystep:
  mov ecx, dword [esp + 4]
  mov ebx, dword [esp + 8]
  add dword [esp + 16], ecx
  add dword [esi], ebx
  jmp short .ystepped
.xstep:
  mov ecx, dword [esp + 12]
  add dword [esp + 16], ebx
  add dword [esi + 4], ecx
  jmp .lineprintloop
  
.invertdx:
  neg ebx
  jmp .y
.invertdy:
  neg ecx
  jmp  .dosxcalc
.xequal:
  mov ebx, dword [esi + 4]
  cmp ebx, dword [esi + 12]
  je .break
  jmp .notequal
.break:
  add esp, 20
  pop ebp
  ret


puttriangle: ; ALL VERTICES PUSHED TO STACK ; COLOR IN AX
  mov esi, esp
  
  call putline
  mov edx, dword [esp + 12] ; 0 4 8 12 | 16 20
  mov ebx, dword [esp + 8]
  xchg dword [esp + 20], edx
  xchg dword [esp + 16], ebx ; 0 4 16 20 8 12
  mov dword [esp + 12], edx
  mov dword [esp + 8], ebx
  call putline
  mov edx, dword [esp + 16]
  mov ebx, dword [esp + 20]
  xchg edx, dword [esp]
  xchg ebx, dword [esp + 4]
  call putline
  ret

%macro FRAME 1
  push ebp
  mov ebp, esp
  sub esp, %1
%endmacro

%macro ENDFRAME 1
  add esp, %1
  pop ebp
%endmacro

%macro LINE 5
  push ebp
  mov ebp, esp
  sub esp, 16
  mov esi, esp
  mov dword [esp], %1
  mov dword [esp + 4], %2
  mov dword [esp + 8], %3
  mov dword [esp + 12], %4
  mov ax, %5
  call putline
  add esp, 16
  pop ebp
%endmacro

%macro TRIANGLE 7
  FRAME 24
  mov esi, esp
  mov dword [esp], %1
  mov dword [esp + 4], %2
  mov dword [esp + 8], %3
  mov dword [esp + 12], %4
  mov dword [esp + 16], %5
  mov dword [esp + 20], %6
  mov ax, %7
  call puttriangle
  ENDFRAME 24
%endmacro

blankscreen: ; clearscreen but doesn't kill keybuffer, etc.
  mov edi, dword [framebuffer]
  xor eax, eax
  mov ecx, (800 * 600)
  rep stosw ;??? for some reason stosd keeps throwing a divbyzero exception
  ret
