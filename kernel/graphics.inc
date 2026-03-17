; GRAPHICS FILE FOR 800X600 VESA MODE

putpixel: ; Row+1 in EBX, Column+1 in ECX, color in AX ; clobbers EBX EDI EDX ECX
  dec ebx
  dec ecx
  movzx edx, word [pitch]
  shl ecx, 1
  imul ebx, ebx, edx ; get offset
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
  jmp short .y
.invertdy:
  neg ecx
  jmp short .dosxcalc
.xequal:
  mov ebx, dword [esi + 4]
  cmp ebx, dword [esi + 12]
  je .break
  jmp .notequal
.break:
  add esp, 20
  pop ebp
  ret
