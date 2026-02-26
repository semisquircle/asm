; Program 2: RPN Calculator Program
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P2
INCLUDE Irvine32.inc

stackSize EQU 8

.data
numStack SDWORD stackSize DUP(0)
stackCount DWORD 0
buffer BYTE 32 DUP(0)
prompt BYTE "enter number or operation (+,-,*,/,X,N,U,D,V,C,Q): ", 0
errInvalidMsg BYTE "invalid input!", 0
errFullMsg BYTE "stack is full!", 0
errEmptyMsg BYTE "stack is empty!", 0
errTwoMsg BYTE "need at least two values!", 0

.code
main PROC

MainLoop:
    mov edx, OFFSET prompt
    call WriteString
    mov edx, OFFSET buffer
    mov ecx, 32
    call ReadString
    mov esi, OFFSET buffer
    mov al, [esi]

    ; check for regular positive number (0-9)
    cmp al, '0'
    jl CheckNegOrSub
    cmp al, '9'
    jg CheckNegOrSub
    call PushNumber
    jmp ShowTop

CheckNegOrSub:
    ; check for negative number or subtraction (-)
    cmp al, '-'
    jne CheckCommand
    mov bl, [esi + 1]
    cmp bl, '0'
    jl CheckCommand ; treat as operation
    cmp bl, '9'
    jg CheckCommand ; treat as operation
    call PushNumber
    jmp ShowTop

CheckCommand:
    ; convert lowercase to uppercase
    cmp al, 'a'
    jl ProcessCommand
    cmp al, 'z'
    jg ProcessCommand
    sub al, 32

ProcessCommand:
    cmp al, '+'
    je DoAdd
    cmp al, '-'
    je DoSub
    cmp al, '*'
    je DoMul
    cmp al, '/'
    je DoDiv
    cmp al, 'X'
    je DoExchange
    cmp al, 'N'
    je DoNegate
    cmp al, 'U'
    je DoRollUp
    cmp al, 'D'
    je DoRollDown
    cmp al, 'V'
    je DoView
    cmp al, 'C'
    je DoClear
    cmp al, 'Q'
    je QuitProgram
    jmp InvalidInput

DoAdd:
    call AddProc
    jmp ShowTop
DoSub:
    call SubProc
    jmp ShowTop
DoMul:
    call MulProc
    jmp ShowTop
DoDiv:
    call DivProc
    jmp ShowTop
DoExchange:
    call ExchangeProc
    jmp ShowTop
DoNegate:
    call NegateProc
    jmp ShowTop
DoRollUp:
    call RollUpProc
    jmp ShowTop
DoRollDown:
    call RollDownProc
    jmp ShowTop
DoView:
    call ViewProc
    jmp MainLoop
DoClear:
    call ClearProc
    jmp MainLoop

ShowTop:
    cmp stackCount, 0
    je MainLoop
    mov eax, stackCount
    dec eax
    mov edx, eax
    mov eax, numStack[edx * 4]
    call WriteInt
    call Crlf
    jmp MainLoop

QuitProgram:
    exit

InvalidInput:
    mov edx, OFFSET errInvalidMsg
    call WriteString
    call Crlf
    jmp MainLoop

main ENDP

; post-incrementing
PushNumber PROC
    cmp stackCount, stackSize
    jnc FullError
    mov edx, OFFSET buffer
    call ParseInteger32
    mov ebx, stackCount
    mov edx, ebx
    mov numStack[edx * 4], eax
    inc stackCount
    ret

FullError:
    mov edx, OFFSET errFullMsg
    call WriteString
    call Crlf
    ret
PushNumber ENDP

AddProc PROC
    cmp stackCount, 2
    jc TwoError
    call PopTwo
    add eax, ebx
    call PushResult
    ret
AddProc ENDP

SubProc PROC
    cmp stackCount, 2
    jc TwoError
    call PopTwo
    sub ebx, eax
    mov eax, ebx
    call PushResult
    ret
SubProc ENDP

MulProc PROC
    cmp stackCount, 2
    jc TwoError
    call PopTwo
    imul eax, ebx
    call PushResult
    ret
MulProc ENDP

DivProc PROC
    cmp stackCount, 2
    jc TwoError
    call PopTwo
    cmp eax, 0
    je TwoError ; good ol' divide-by-zero check
    mov edx, 0
    mov ecx, eax
    mov eax, ebx
    idiv ecx
    call PushResult
    ret
DivProc ENDP

ExchangeProc PROC
    cmp stackCount, 2
    jc TwoError
    mov eax, stackCount
    dec eax
    mov edx, eax
    mov ebx, numStack[edx * 4]
    dec eax
    mov edx, eax
    mov ecx, numStack[edx * 4]
    mov numStack[edx * 4], ebx
    inc eax
    mov edx, eax
    mov numStack[edx * 4], ecx
    ret
ExchangeProc ENDP

NegateProc PROC
    cmp stackCount,1
    jc EmptyError
    mov eax, stackCount
    dec eax
    mov edx, eax
    neg numStack[edx * 4]
    ret
NegateProc ENDP

RollUpProc PROC
    cmp stackCount, 1
    jle EmptyError
    mov ecx, stackCount
    dec ecx
    mov edx, ecx
    mov eax, numStack[edx * 4]

RollUpLoop:
    mov edx, ecx
    dec edx
    mov ebx, numStack[edx * 4]
    mov edx, ecx
    mov numStack[edx * 4], ebx
    loop RollUpLoop
    mov numStack[0], eax
    ret
RollUpProc ENDP

RollDownProc PROC
    cmp stackCount, 1
    jle EmptyError
    mov eax, numStack[0]
    mov ecx, 0
    mov edx, stackCount
    dec edx

RollDownLoop:
    cmp ecx, edx
    jge DoneRollDown
    mov ebx, ecx
    inc ebx
    mov esi, ebx
    mov ebx, numStack[esi * 4]
    mov esi, ecx
    mov numStack[esi * 4], ebx
    inc ecx
    jmp RollDownLoop

DoneRollDown:
    mov esi, stackCount
    dec esi
    mov numStack[esi * 4], eax
    ret
RollDownProc ENDP

ViewProc PROC
    cmp stackCount, 0
    je EmptyError
    mov ecx, stackCount
    mov edx, stackCount
    dec ecx

ViewLoop:
    mov eax, numStack[ecx * 4]
    call WriteInt
    call Crlf
    dec ecx
    cmp ecx, -1
    jne ViewLoop
    ret
ViewProc ENDP

ClearProc PROC
    mov stackCount, 0
    ret
ClearProc ENDP

; pre-decrementing (alka seltzer!)
PopTwo PROC
    dec stackCount
    mov edx, stackCount
    mov eax, numStack[edx * 4]
    dec stackCount
    mov edx, stackCount
    mov ebx, numStack[edx * 4]
    ret
PopTwo ENDP

PushResult PROC
    mov ebx, stackCount
    mov edx, ebx
    mov numStack[edx * 4], eax
    inc stackCount
    ret
PushResult ENDP

TwoError:
    mov edx, OFFSET errTwoMsg
    call WriteString
    call Crlf
    ret

EmptyError:
    mov edx, OFFSET errEmptyMsg
    call WriteString
    call Crlf
    ret

END main
