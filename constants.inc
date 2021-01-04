; System calls 

SYS_EXIT   equ 1      ; man 2 exit
SYS_READ   equ 3      ; man 2 read
SYS_WRITE  equ 4      ; man 2 write
SYS_OPEN   equ 5      ; man 2 open
SYS_CLOSE  equ 6      ; man 2 close

STDIN      equ 0      ; standard input
STDOUT     equ 1      ; standard output
STDERR     equ 2      ; standard error

O_RDONLY   equ 0000q  ; read-only

S_IRUSR    equ 0400q  ; user has read permission
