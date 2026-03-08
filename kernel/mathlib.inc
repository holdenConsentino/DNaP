
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
  sar eax, ebx
  xor edx, edx
  ret

x87log2: ; data at [ebx] ; clobbers eax ebx FPU ; ret in eax
  fld1
  flds [ebx]
  fyl2x
  fadp eax ; ??
  ret

sx2x87:
  push eax
  flds dword [esp]
  fmuls dword [fp65536]
  fistpl dword [esp]
  pop eax 
  ret
  fp65536 db 65336
  
