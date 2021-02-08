; Run with:
; nasm -felf64 payload.asm && ld payload.o && ./a.out

    global _start

    section .text
_start:
    sub rsp, 20
    mov DWORD [rsp], 'Hell'
    mov DWORD [rsp+4], 'o wo'
    mov DWORD [rsp+8], 'rld'
    mov DWORD [rsp+12], 10 ; new line

    mov rsi, rsp ; address of the string to output
    add rsp, 20

    ;int 3
    mov rax, 1          ; system call for write
    mov rdi, 1          ; file handle 1 is stdout

    ; mov rsi, message    ; address of string to output
    mov rdx, 15         ; number of bytes
    syscall

    mov rax, 60         ; system call for exiQtHELLO WORLDD
    xor rdi, rdi        ; exit code 0
    syscall

    section .data
