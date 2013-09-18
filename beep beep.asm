;sleep.asm
[SECTION .text]

global _start


_start:
mov ecx,5                   ; Loop
loop:
xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx


mov eax, 0x7c837aa7 ;address of Beep
mov bx, 750         ;Frequency
mov dx, 50     ;Duration 
push ebx
push edx
call eax     ;Call Beep

xor eax,eax
xor ebx,ebx
mov ebx, 0x7c802446 ;address of Sleep
mov ax, 20000       ;pause for 20 Seconds
push eax
call ebx            ;

dec ecx
jnz loop
