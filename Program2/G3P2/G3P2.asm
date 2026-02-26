TITLE G3P2
INCLUDE Irvine32.inc

stackSize EQU 8

.data
numStack SDWORD stackSize DUP(0)
stackCount DWORD 0
inputBuffer BYTE 32 DUP(0)
prompt BYTE "Enter number or operation (+,-,*,/,X,N,U,D,V,C,Q): ", 0
errFull BYTE "Stack is full!", 0
errEmpty BYTE "Stack is empty!", 0
errTwo BYTE "Need at least two values!", 0

.code
main PROC

MainLoop:
    mov edx, OFFSET prompt
    call WriteString
    mov edx, OFFSET inputBuffer
    mov ecx, 32
    call ReadString
    mov esi, OFFSET inputBuffer
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

main ENDP

PushNumber PROC
    cmp stackCount, stackSize
    jae FullError

    mov edx, OFFSET inputBuffer
    call ParseInteger32

    mov ebx, stackCount
    mov edx, ebx
    mov numStack[edx * 4], eax
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
    jb TwoError
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
    jb EmptyError
    mov eax, stackCount
    dec eax
    mov edx, eax
    neg numStack[edx * 4]
    ret
NegateProc ENDP

RollUpProc PROC
    cmp stackCount, 1
    jbe EmptyError
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
    jbe EmptyError
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
    mov esi, 0

ViewLoop:
    mov edx, esi
    mov eax, numStack[edx * 4]
    call WriteInt
    call Crlf
    inc esi
    loop ViewLoop
    ret
ViewProc ENDP

ClearProc PROC
    mov stackCount, 0
    ret
ClearProc ENDP

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
