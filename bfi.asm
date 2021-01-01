%include "constants.inc"

section .data
; labels used for output
fopenMsg: 	db "bfi: could not open "
fopenMsgLen: 	equ $-fopenMsg

eUnbalanced	db "bfi: unbalanced brackets", 10
eUnbalancedLen	equ $-eUnbalanced

tmsg		db "", 10
tLen		equ $-tmsg

bufsize		dw      10240

section .bss

buf     	resb    10240
to_print	resb 	10240
finalWord	resb	10240

fwIndex		resb	1
loopCount	resb	1

section .text
  global _start

%define argv		[ebp+4*ecx]
%define fname 		[ebp+12]
%define progname	[ebp+8]
%define argc 		[ebp+4]

%define data		[to_print+edi]
%define code		BYTE [buf+esi]
%define print		[finalWord+eax]
_start:

  push ebp
  mov ebp, esp

;******************************************
; Check if reading from file - one arg
; Check if reading from stdin - zero args
;******************************************

  cmp dword argc, 1
  jne .read_file

;******************************************
; read input from STDIN
;******************************************

  mov eax, SYS_READ
  mov ebx, STDIN
  mov ecx, buf
  mov edx, bufsize
  int 80h

  mov esi, 0
  jmp .instructions
.read_file:

;******************************************
; open file
;******************************************

  mov eax, SYS_OPEN
  mov ebx, fname
  mov ecx, O_RDONLY
  mov edx, S_IRUSR
  int 80h

  ; check file was opened
  cmp eax, 0
  jl .file_not_opened_err


;******************************************
; read file
;******************************************

  mov eax, SYS_READ
  mov ebx, eax
  mov ecx, buf
  mov edx, bufsize
  int 80h

;******************************************
; execute instructions  
;******************************************

.instructions: 

  call loop_error
  cmp byte [loopCount], 0
  jne .brack_error
  call instruc
  jmp .done 


;******************************************
; file not open error 
;******************************************
.brack_error:
  
  mov eax, SYS_WRITE
  mov ebx, STDERR 
  mov ecx, eUnbalanced
  mov edx, eUnbalancedLen
  int 80h
  jmp .done

;******************************************
; file not open error 
;******************************************
.file_not_opened_err:

  mov eax, SYS_WRITE
  mov ebx, STDERR 
  mov ecx, fopenMsg 
  mov edx, fopenMsgLen 
  int 80h

  mov edi, fname
  call strlen

; edx now has length of fname stored

  mov eax, SYS_WRITE
  mov ebx, STDERR 
  mov ecx, fname
  int 80h

  mov eax, SYS_WRITE
  mov ebx, STDERR 
  mov ecx, tmsg 
  mov edx, tLen
  int 80h

;******************************************
; close file and exit
;******************************************
.done:
  mov eax, SYS_CLOSE
  int 80h

  mov eax, SYS_EXIT
  mov ebx, 0
  int 80h
  ret



; ------------------------------------------------------------------------------ 
; strlen: returns the string length of the string pointed to by EDI in EDX
; ------------------------------------------------------------------------------ 
strlen:
  push ecx
  xor ecx, ecx
  not ecx 
  xor eax, eax
  cld
  repne scasb
  neg ecx
  lea edx, [ecx-2]
  pop ecx 
  ret


; ------------------------------------------------------------------------------ 
; excute instructions
; ------------------------------------------------------------------------------ 
instruc:

  jmp .s2
.start_of_code:
  ; >
  cmp code, 0x3e
  jne .n1
  inc edi
  jmp .s1

.n1:
  ; <
  cmp code, 0x3c
  jne .n2
  dec edi
  jmp .s1

.n2:
  ; +
  cmp code, 0x2b
  jne .n3
  inc byte data
  jmp .s1

.n3:
  ; -
  cmp code, 0x2d
  jne .n4
  dec byte data
  jmp .s1

.n4:
  ; . - print current letter
  cmp code, 0x2e
  jne .n5
  mov eax, SYS_WRITE
  mov ebx, STDOUT
  lea ecx, data
  mov edx, 1 
  int 80h 

;***************** problem probably ***************
.n5:
  ; , - take in letter
  cmp code, 0x2c
  jne .n6
  mov eax, SYS_READ
  mov ebx, STDIN
  mov ecx, data
  mov edx, 1 
  int 80h
  jmp .s1

;**************************************************

.n6:
  ; [ - start while loop
  cmp code, 0x5b
  jne .n7
  inc esi
  call in_loop
  jmp .s1  

.n7:
  ; ] - end while loop
  cmp eax, 0x5d
  jne .n8
  ret

.n8:
.s1:
  inc esi
.s2:
  ; while there is still code do excute - do this
  mov al, code
  test al, al
  jne .start_of_code
  ret

; ------------------------------------------------------------------------------ 
; reached the end of while loop, go back to top 
; ------------------------------------------------------------------------------ 

go_back:
  jmp .start_go_back
 
.more_back:
  dec esi

  ; check for unbalanced brackets
  cmp esi, -1
  jne .start_go_back
  ; throw error
  ;mov eax, 

.start_go_back:
  cmp code, 91
  jne .more_back
  inc esi
  ret

; ------------------------------------------------------------------------------ 
; in loop
; ------------------------------------------------------------------------------ 

in_loop:

  ; if while loop is still valid
  jmp .check

.do_while:
  ; check if "]" is found
  cmp code, 93
  jne .not_back

  ; "]" was found
  call go_back
  jmp .check
 
.not_back:
  call instruc

.check:
  cmp byte data, 0
  jne .do_while
  ret

; ------------------------------------------------------------------------------ 
; check for correct brackets
; ------------------------------------------------------------------------------ 
loop_error:
  mov byte [loopCount], 0
  jmp .s1
.ag:

  cmp code, 0x5b
  jne .a1 
  inc byte [loopCount]
  jmp .st
.a1:
  cmp code, 0x5d
  jne .st
  dec byte [loopCount]
.st:
  inc esi
.s1:
  mov al, code
  test al, al
  jne .ag

  mov esi, 0
  ret
