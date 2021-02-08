### ELF flies

Compile assembly:
```
nasm basic_elf.asm
```

Running:
```
chmod +x ./basic_elf
./basic_elf
```

Using nasm to compile, wrapping in elf64 format, and running in gdb:
```
nasm -felf64 ./payload.asm && ld ./payload.o && chmod +x ./a.out && gdb ./a.out
```

Hex dump:
```
xxd basic_elf
```

Easily see individual byte numbers for cross-referencing:
```
$ xxd -cols 1 ./basic_elf
00000000: 7f  .
00000001: 45  E
00000002: 4c  L
00000003: 46  F
00000004: 02  .
00000005: 01  .
00000006: 01  .
00000007: 00  .
00000008: 02  .
00000009: 01  .
0000000a: 00  .f
```

Using xxd to seek to a specific offset and see relative byte numbers, i.e. jumping to 0x40 to see the program header in isolation

```
xxd -plain -seek 0x40 ./basic_elf | xxd -cols 1
```

Compile c program into shared object:
```
gcc hello_world.c
```

Compiling c program into static binary:
```
gcc -static hello_world.c
```

Debug the ELF information with `readelf`:
- `readelf -h basic_elf` - header information
- `readelf --program-header basic_elf` - header information
- `readelf -a basic_elf` - everything

Ghidra will show you the result of loading this program in memory.

Radare can also load instructions:

```
$ nasm -fbin basic_elf.asm && chmod +x ./basic_elf && r2 ./basic_elf
[0x00401000]> pd 5
            ;-- entry0:
            ;-- segment.LOAD0:
            ;-- segment.ehdr:
            ;-- rip:
            0x00401000      4883ec14       sub rsp, 0x14               ; [01] -rw- segment size 64 named ehdr
            0x00401004      c7042448656c.  mov dword [rsp], 0x6c6c6548 ; 'Hell'
                                                                       ; [0x6c6c6548:4]=-1
            0x0040100b      c74424046f20.  mov dword [rsp + 4], 0x6f77206f ; 'o wo'
                                                                       ; [0x6f77206f:4]=-1
            0x00401013      c7442408726c.  mov dword [rsp + 8], 0x646c72 ; 'rld'
                                                                       ; [0x646c72:4]=-1
            0x0040101b      c744240c0a00.  mov dword [rsp + 0xc], 0xa
```

Note: [unicorn-engine](https://www.unicorn-engine.org/) can emulate x86 instructions, but not the surrounding ELF file

## Resources
- [ELF Wiki](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format)
- [ELF Specification](https://refspecs.linuxfoundation.org/elf/elf.pdf)
- [nasm tutorial](https://cs.lmu.edu/~ray/notes/nasmtutorial/)
- [ELF video](https://www.youtube.com/watch?v=nC1U1LJQL8o)
- `man elf`
- [Using radare/r2 to view/edit ELF headers](https://reverseengineering.stackexchange.com/questions/19921/writing-elf-headers-in-radare)
