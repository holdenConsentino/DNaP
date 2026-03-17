atoi: ; takes null terminated string at [ESI] outputs dword in eax clobbers eax edx esi ebx
  xor edx, edx
  xor eax, eax
.atoiloop:
  mov bl, byte [esi + edx]
  test bl, bl
  jz .break
  sub bl, 0x30
  lea eax, [eax + eax*4]
  add eax, eax
  movzx ebx, bl
  add eax, ebx
  inc edx
  jmp .atoiloop
.break:
  ret

itoa: ; takes eax and outputs string at EDI [12 byte null terminated buffer]. Signed if ebx = 1, unsigned if ebx = 0
  xor edx, edx
  cld
  mov esi, edi
  mov ecx, 12
  xor eax, eax
  rep stosb
  test ebx, ebx
  jnz signeditoaloop
itoaloop:
  mov ecx, eax
  mov edx, 0xCCCCCCCD
  mul edx
  shr edx, 3
  mov eax, edx
  lea eax, [eax + eax*4]
  add eax, eax
  sub ebx, eax
  mov eax, edx
  mov byte [edi], bl ; DWORD???
  dec edi
  cmp edi, esi
  jge itoaloop
  ret

signeditoaloop:
  cmp ebx, 0
  jge itoaloop
  neg eax
  call itoaloop
  mov byte [esi], "-"
  ret

sx2mul: ; eax * ebx; clobbers eax ebx edx ; returns eax
  imul ebx
  shrd eax, edx, 16
  ret

sx2div: ; eax / ebx ; clobbers eax ebx edx ; you know fdiv exists ; signed ; remainder in edx

  mov edx, ebx
  dec edx
  test eax, edx
  jz .even
.odd:
  cdq
  shld edx, eax, 16
  shl eax, 16
  idiv ebx
  ret
.even:
  bsf ecx, ebx
  sar eax, cl
  xor edx, edx
  ret

x87log2: ; data at [ebx] ; clobbers eax ebx FPU ; ret in eax
  fld1
  fld [ebx]
  fyl2x
  fistp dword [ebx] ; ??
  ret

sx2x87:
  push eax
  fld dword [esp]
  fmul dword [fp65336]
  fistp dword [esp]
  pop eax 
  ret
  fp65336 dd 65336


  
%macro x87INTLOAD 1
  mov eax, %1
  push eax
  fild dword [esp]
  pop eax
%endmacro

%macro x87FLOAD 1
  mov eax, %1
  push eax
  fild dword [esp]
  pop eax
%endmacro

%macro x87IPOP 0
  push eax
  fistp dword [esp]
  pop eax
%endmacro

%macro x87FPOP 0
  push eax
  fistp dword [esp]
  pop eax
%endmacro
