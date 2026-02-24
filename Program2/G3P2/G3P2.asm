; Program 2: RPN Calculator Program
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P2
INCLUDE Irvine32.inc

.data
sum DWORD ?
count DWORD ?
rem DWORD ?

.code
main PROC

outerLoop:
    mov sum, 0
    mov count, 0

innerLoop:
    jmp innerLoop

endLoop:
    jmp quitProgram

quitProgram:
    exit

main ENDP
END main
