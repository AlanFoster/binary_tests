; Run with:
; nasm -felf64 payload.asm && ld payload.o && ./a.out

    global _start

    section .text
_start:
    mov rax, 1          ; system call for write
    mov rdi, 1          ; file handle 1 is stdout
    mov rsi, message    ; address of string to output
    mov rdx, 13         ; number of bytes
    syscall

    mov rax, 60         ; system call for exit
    xor rdi, rdi        ; exit code 0
    syscall

    section .data
message:
    db "hello, world", 10   ; new line at the end is required
