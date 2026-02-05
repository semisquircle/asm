; Program 1: Average Program
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P1
INCLUDE Irvine32.inc

.data
sum DWORD ?
count DWORD ?
grade SDWORD ?
rem DWORD ?

prompt BYTE "Enter a grade (0-100): ", 0
sumMsg BYTE "Sum: ", 0
countMsg BYTE "Count: ", 0
avgMsg BYTE "Average: ", 0
remMsg BYTE " R ", 0

.code
main PROC

outerLoop:
    mov sum, 0
    mov count, 0

innerLoop:
    mov edx, OFFSET prompt
    call WriteString
    call ReadInt
    mov grade, eax

    ; Check range (0 <= grade <= 100)
    cmp eax, 0
    jl endLoop
    cmp eax, 100
    jg endLoop

    ; Valid grade!
    add sum, eax
    inc count
    jmp innerLoop

endLoop:
    ; Quick divide-by-zero check
    cmp count, 0
    je quitProgram

    ; Print sum
    mov edx, OFFSET sumMsg
    call WriteString
    mov eax, sum
    call WriteDec
    call Crlf

    ; Print count
    mov edx, OFFSET countMsg
    call WriteString
    mov eax, count
    call WriteDec
    call Crlf

    ; Calculate average
    mov eax, sum
    mov ebx, count
    xor edx, edx
    div ebx ; eax = quotient, edx = remainder
    mov rem, edx ; save remainder immediately

    ; Print average
    mov edx, OFFSET avgMsg
    call WriteString
    call WriteDec

    ; Print remainder
    mov edx, OFFSET remMsg
    call WriteString
    mov eax, rem
    call WriteDec
    call Crlf

    call Crlf
    jmp outerLoop

quitProgram:
    exit

main ENDP
END main
