; Program 2: RPN Calculator Program
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P2
INCLUDE Irvine32.inc

.data
stack SDWORD 8 DUP(0)
stackCount DWORD 0

prompt BYTE "Enter number or operation (+,-,*,/,X,N,U,D,V,C,Q): ", 0
errFull BYTE "Stack is full!", 0
errEmpty BYTE "Stack is empty!", 0
errTwo BYTE "Need at least two values!", 0
newline BYTE 0Dh, 0Ah, 0

.code
main PROC

MainLoop:
    mov edx, OFFSET prompt
    call WriteString
    call ReadString ; read input
    mov esi, edx ; pointer to input buffer

    mov al, [esi]
    cmp al, 'Q'
    je QuitProgram

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

; otherwise treat as number
    call PushNumber
    jmp MainLoop

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
    cmp stackCount,0
    je MainLoop
    mov eax, stackCount
    dec eax
    mov eax, stack[eax * 4]
    call WriteInt
    call Crlf
    jmp MainLoop

QuitProgram:
    exit

main ENDP

PushNumber PROC
    cmp stackCount, 8
    jae FullError

    call ParseInteger
    mov ebx, stackCount
    mov stack[ebx * 4], eax
    inc stackCount
    ret

FullError:
    mov edx, OFFSET errFull
    call WriteString
    call Crlf
    ret
PushNumber ENDP

AddProc PROC
    cmp stackCount, 2
    jb TwoError
    call PopTwo
    add eax, ebx
    call PushResult
    ret
AddProc ENDP

SubProc PROC
    cmp stackCount, 2
    jb TwoError
    call PopTwo
    sub ebx, eax
    mov eax, ebx
    call PushResult
    ret
SubProc ENDP

MulProc PROC
    cmp stackCount, 2
    jb TwoError
    call PopTwo
    imul eax, ebx
    call PushResult
    ret
MulProc ENDP

DivProc PROC
    cmp stackCount, 2
    jb TwoError
    call PopTwo
    mov edx, 0
    mov ecx, eax
    mov eax, ebx
    idiv ecx
    call PushResult
    ret
DivProc ENDP

ExchangeProc PROC
    cmp stackCount, 2
    jb TwoError
    mov eax, stackCount
    dec eax
    mov ebx, stack[eax * 4]
    dec eax
    mov ecx, stack[eax * 4]
    mov stack[eax * 4], ebx
    inc eax
    mov stack[eax * 4], ecx
    ret
ExchangeProc ENDP

NegateProc PROC
    cmp stackCount,1
    jb EmptyError
    mov eax, stackCount
    dec eax
    neg stack[eax * 4]
    ret
NegateProc ENDP

RollUpProc PROC
    cmp stackCount,1
    jbe EmptyError
    mov ecx, stackCount
    dec ecx
    mov eax, stack[ecx * 4] ; save top

RollUpLoop:
    mov ebx, stack[(ecx-1)*4]
    mov stack[ecx * 4], ebx
    loop RollUpLoop

    mov stack[0], eax
    ret
RollUpProc ENDP

RollDownProc PROC
    cmp stackCount,1
    jbe EmptyError
    mov eax, stack[0] ; save bottom
    mov ecx,0

RollDownLoop:
    cmp ecx, stackCount-1
    jge DoneRollDown
    mov ebx, stack[(ecx + 1) * 4]
    mov stack[ecx * 4], ebx
    inc ecx
    jmp RollDownLoop

DoneRollDown:
    mov stack[(stackCount - 1) * 4], eax
    ret
RollDownProc ENDP

ViewProc PROC
    cmp stackCount,0
    je EmptyError
    mov ecx, stackCount
    mov esi,0
ViewLoop:
    mov eax, stack[esi * 4]
    call WriteInt
    call Crlf
    inc esi
    loop ViewLoop
    ret
ViewProc ENDP

ClearProc PROC
    mov stackCount,0
    ret
ClearProc ENDP

PopTwo PROC
    dec stackCount
    mov eax, stack[stackCount * 4]
    dec stackCount
    mov ebx, stack[stackCount * 4]
    ret
PopTwo ENDP

PushResult PROC
    mov ebx, stackCount
    mov stack[ebx * 4], eax
    inc stackCount
    ret
PushResult ENDP

ParseInteger PROC
    call ReadInt
    ret
ParseInteger ENDP

TwoError:
    mov edx, OFFSET errTwo
    call WriteString
    call Crlf
    ret

EmptyError:
    mov edx, OFFSET errEmpty
    call WriteString
    call Crlf
    ret

END main
