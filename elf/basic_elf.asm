; nasm:
;   - db - byte - 8 bits
;   - dw - 2 bytes - 16 bits - word
;   - dd - 4 bytes - 32 bits
;   - dq - 8 bytes - 64 bits

bits 64

BASE equ 0x400000
VIRTUAL_ENTRY_POINT equ (BASE + code.start)

; Flags for describing segment permissions, i.e. whether it's read / write / executable
PF_X equ 0b001
PF_W equ 0b010
PF_R equ 0b100

; ELF File Structure:
;   Header (1/2)
;       - ELf File Header - Type of ELF file, architecture, locations of tables
;       - Program Header Table / segment information - Runtime Execution information
;   Sections
;       - Contents of the executable.
;           - Code / Data / Section names
;   Section Header table (2/2)
;       - Linking details, ignored when executing
;           - number index, name, type of section program/string, flags (rwx), address, offset, size
;
; Terminology:
;   Segments - Only relevant at runtime. Shows where to load into virtual memory
;       Data - Static memory for state
;       Code - Instruction
;   Sections - Only relevant at link time
; Perfectly valid for an ELF file to hvae only segments, only sections, or both
; The order of the elf file can be somewhat, other than the elf header

; 32 bytes long, identifying the format of the file.

;; readelf -h ./elf
elf_header:
    ;; Start of E_IDENT

    ; 0x00 - Magic bytes - 0x&F followed by ELF
    db 0x7f, "ELF"

    ; 0x04 - Bits - 1 for 32 bit, 2 for 64 bit
    db 0x2

    ; 0x05 - Endian - 1 for little, 2 for big
    db 0x1

    ; 0x06 - Elf version - 1
    db 0x1

    ; 0x07 - Target operating system ABI - Often 0x00 regardless of platform
    db 0x0

    ; 0x08 -ABI Version generally ignored
    db 0x0

    ; 0x09 - Unused - filled with 7 bytes of zeroes. Acts as padding
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    ;; End of E_IDENT

    ; 0x10 - e_type - Object file type
    ;   - ET_CORE core = 4, core dumps
    ;   - ET_DYN shared object file for libraries = 3, and executables with PIE
    ;   - ET_EXEC file for binaries = 2. Doesn't support ASLR
    ;   - ET_REL file before being linked = 1
    dw 0x2

    ; 0x12 - e_machine - Instruction set architecture, 0x3e for amd64
    dw 0x3e

    ; 0x14 - e_version - set to 1 for original ELF version
    dd 0x1

    ; 0x18 - e_entry - Entry address from where to start executing
    ;   64 bit as dictated by the bits flag above
    dq VIRTUAL_ENTRY_POINT

    ; 0x20 - e_phoff - Program header table pointer
    ; Normally immediately follows the file header. Since the file header is static length,
    ; this can be hard coded. 0x34 for 32 bit, 0x40 for 64 bit ELF
    dq 0x40

    ; 0x28 - e_shoff - Start of the section header table;
    ; This value is zero when the file has no program header
    dq 0

    ; 0x30 - e_flags - flags, depends on architecture
    dd 0

    ; 0x34 - e_ehsize - size of the elf header itself, normally 64 for 64, and 52 bytes for 32 bits
    dw 64

    ; 0x36 - e_phentsize - byte size of _one_ entry of the program header table, all sizes are equal.
    ; 64-bit ELF is 64-bit. Note that p_flags are in a different structure location than 32-bit
    dw 56

    ; 0x38 - e_phnum - number of entries in the program header tile
    ; The product of e_phentsize * e_phnum = total size in bytes
    ; TODO: This is smooshed together
    dw 1

    ; 0x3a - e_shentsize - size of the section header table entry
    ; Set to zero as there are no entries, we don't require linking anything
    dw 0

    ; 0x3c - e_shnum - number of entries in the section header
    ; Set to zero as there are no entries, we don't require linking anything
    dw 0

    ; 0x3e - e_shstrndx - index of the section header table entry that contains the section names
    dw 0

    ; 0x40 - marks end of end of header

;; Describes runtime information, pointers to segments
;; readelf --segments ./elf
elf_program_header_table:
    ; 0x00 - Type of segment
    ;   PT_NULL = 0
    ;   PT_LOAD = 1 - segments of this type will be loaded into memory
    ;   PT_DYNAMIC = 2 - Loading shared libraries into memory
    ;   PT_INTERP = 3 - Related to PIE
    ;   PT_NOTE = 4 - Debugging information
    ;   PT_SHLIB = 5 - Undefined and never used
    ;   PT_PHDR = 6 - Program header
    ;   PT_TLS = 7 - thread local storage
    dd 0x1

    ; 0x04 p_flags - segment specific flag - note this is in a different place than 32-ELF files
    ;   PF_X
    ;   PF_W
    ;   PF_R
    ; Data would be RW, code segment would be RE
    ; For PoC we'll mark have the shell code as Read / Write / Executable
    dd (PF_R | PF_X)

    ; 0x08 - p_offset - where the segment in memory
    ; Offset from the beginning of the file
    dq 0 ;; TODO: Reading the _entire_ file within a single program header

    ; 0x10 - p_vaddr - virtual address
    dq BASE

    ; 0x18 - p_paddr - physical address. Not required?
    dq BASE

    ; 0x20 - p_filesz - Number of bytes in the memory image of the segment
    ; Reserved for segment's physical address
    ; May be zero
    dq filesize

    ; 0x28 - p_memsz - number of bytes in the memory image of the segment
    ; May be zero
    dq filesize

    ; 0x30 - p_align - 0 and 1 specify no alignment. Otherwise a power of 2
    ; With o_vaddr  p_offset modulus p_align
    dq 0x1000 ; TODO

    ; 0x38 - end of program header (size)


;; Runtime sections
code:
    .start:

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

    .end:

code.size equ code.end - code.start

;; Linking information - note there's no section header information required for this static binary
elf_section_header_table:

filesize equ $ - $$
