; Program 3: Multitasking Operating System Simulator
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P3
INCLUDE Irvine32.inc

JName equ 0
JPriority equ 8
JStatus equ 9
JRunTime equ 10
JLoadTime equ 12

JobAvailable equ 0
JobRun equ 1
JobHold equ 2

LowestPriority equ 7
SizeOfJob equ 14
NumberOfJobs equ 10

.data
jobs BYTE NumberOfJobs * SizeOfJob DUP(0)
endOfJobs DWORD endOfJobs

jobCount DWORD 0
sysTime DWORD 0

buffer BYTE 64 DUP(0)

cmdQuit BYTE "QUIT", 0
cmdHelp BYTE "HELP", 0
cmdShow BYTE "SHOW", 0
cmdLoad BYTE "LOAD", 0
cmdRun BYTE "RUN", 0
cmdHold BYTE "HOLD", 0
cmdKill BYTE "KILL", 0
cmdStep BYTE "STEP", 0
cmdChange BYTE "CHANGE", 0

msgHelp BYTE "Commands: LOAD RUN HOLD KILL SHOW STEP CHANGE QUIT", 0
msgPrompt BYTE "Enter a command: ", 0
msgInvalid BYTE "Invalid command", 0
msgFull BYTE "Job queue full!", 0
msgExists BYTE "Job already exists!", 0
msgNotFound BYTE "Job not found!", 0
msgRemoved BYTE "Job removed", 0
msgLoaded BYTE "Job loaded", 0
msgRunning BYTE "Job running", 0
msgHolding BYTE "Job holding", 0
msgDone BYTE "Job completed", 0
msgChanged BYTE "Job priority changed", 0

.code
main PROC
	cld
mainLoop:
	mov edx, OFFSET msgPrompt
	call WriteString

	mov edx, OFFSET buffer
	mov ecx, 64
	call ReadString

	call ToUpperBuffer
	call ParseCommand

	jmp mainLoop
main ENDP

ToUpperBuffer PROC
	mov edi, OFFSET buffer
UpperLoop:
	mov al, [edi]
	cmp al, 0
	je done

	cmp al, 'a'
	jb next
	cmp al, 'z'
	ja next

	sub al, 32
	mov [edi], al

next:
	inc edi
	jmp UpperLoop
done:
	ret
ToUpperBuffer ENDP

SkipWhitespace PROC
SkipLoop:
	mov al, [edi]
	cmp al, ' '
	jne done
	inc edi
	jmp SkipLoop
done:
	ret
SkipWhitespace ENDP

SkipToken PROC
SkipLoop:
	mov al, [edi]
	cmp al, ' '
	je done
	cmp al, 0
	je done
	inc edi
	jmp SkipLoop
done:
	ret
SkipToken ENDP

GetTokenPtr PROC
	call SkipToken
	call SkipWhitespace
	mov esi, edi
	ret
GetTokenPtr ENDP

ParseNumber PROC
	xor eax, eax
ParseLoop:
	mov bl, [esi]
	cmp bl, '0'
	jb done
	cmp bl, '9'
	ja done

	sub bl, '0'
	imul eax, 10
	add eax, ebx

	inc esi
	jmp ParseLoop
done:
	ret
ParseNumber ENDP

CopyNameFromBuffer PROC
	push edi
	mov ecx, 8
CopyLoop:
	mov al, [esi]
	cmp al, ' '
	je done
	cmp al, 0
	je done

	mov [edi + JName], al
	inc esi
	inc edi
	loop CopyLoop
done:
	mov BYTE PTR [edi], 0
	pop edi
	ret
CopyNameFromBuffer ENDP

FindJobByName PROC
	mov ecx, jobCount
	mov edi, 0

searchLoop:
	cmp edi, ecx
	jge notFound

	mov eax, edi
	imul eax, SizeOfJob
	mov edx, OFFSET jobs
	add edx, eax

	push esi
	push edi

	mov edi, edx
	add edi, JName

	mov ecx, 8
	repe cmpsb

	pop edi
	pop esi

	je found

	inc edi
	jmp searchLoop

found:
	mov eax, edi
	ret

notFound:
	mov eax, -1
	ret
FindJobByName ENDP

ParseCommand PROC
	mov edi, OFFSET buffer
	call SkipWhitespace
	cld

	mov esi, OFFSET cmdQuit
	mov ecx, SIZEOF cmdQuit
	push edi
	repe cmpsb
	pop edi
	je DoQuit

	mov esi, OFFSET cmdHelp
	mov ecx, SIZEOF cmdHelp
	push edi
	repe cmpsb
	pop edi
	je DoHelp

	mov esi, OFFSET cmdShow
	mov ecx, SIZEOF cmdShow
	push edi
	repe cmpsb
	pop edi
	je DoShow

	mov esi, OFFSET cmdLoad
	mov ecx, SIZEOF cmdLoad
	push edi
	repe cmpsb
	pop edi
	je DoLoad

	mov esi, OFFSET cmdRun
	mov ecx, SIZEOF cmdRun
	push edi
	repe cmpsb
	pop edi
	je DoRun

	mov esi, OFFSET cmdHold
	mov ecx, SIZEOF cmdHold
	push edi
	repe cmpsb
	pop edi
	je DoHold

	mov esi, OFFSET cmdKill
	mov ecx, SIZEOF cmdKill
	push edi
	repe cmpsb
	pop edi
	je DoKill

	mov esi, OFFSET cmdStep
	mov ecx, SIZEOF cmdStep
	push edi
	repe cmpsb
	pop edi
	je DoStep

	mov esi, OFFSET cmdChange
	mov ecx, SIZEOF cmdChange
	push edi
	repe cmpsb
	pop edi
	je DoChange

	mov edx, OFFSET msgInvalid
	call WriteString
	call Crlf
	ret

DoQuit:
	exit
DoHelp:
	call ShowHelp
	ret
DoShow:
	call ShowJobs
	ret
DoLoad:
	call LoadJob
	ret
DoRun:
	call RunJob
	ret
DoHold:
	call HoldJob
	ret
DoKill:
	call KillJob
	ret
DoStep:
	mov ecx, 1
	call GetTokenPtr
	cmp BYTE PTR [esi], 0
	je DoStepLoop
	call ParseNumber
	mov ecx, eax
DoStepLoop:
	mov edx, ecx
StepLoop:
	call ProcessNextJob
	inc sysTime
	dec edx
	jnz StepLoop
	ret
DoChange:
	call GetTokenPtr
	call FindJobByName
	cmp eax, -1
	je notFoundChange

	imul eax, SizeOfJob
	mov edi, OFFSET jobs
	add edi, eax

	call GetTokenPtr
	call ParseNumber
	mov al, al
	mov JPriority[edi], al

	mov edx, OFFSET msgChanged
	call WriteString
	call Crlf
	ret
notFoundChange:
	mov edx, OFFSET msgNotFound
	call WriteString
	call Crlf
	ret
ParseCommand ENDP

LoadJob PROC
	cmp jobCount, NumberOfJobs
	jge fullQueue

	call GetTokenPtr
	call FindJobByName
	cmp eax, -1
	jne exists

	mov ebx, jobCount
	imul ebx, SizeOfJob
	mov edi, OFFSET jobs
	add edi, ebx

	call CopyNameFromBuffer

	call GetTokenPtr
	call ParseNumber
	mov JPriority[edi], al

	call GetTokenPtr
	call ParseNumber
	mov JRunTime[edi], al

	mov BYTE PTR JStatus[edi], JobHold

	mov eax, sysTime
	mov JLoadTime[edi], eax

	inc jobCount

	mov edx, OFFSET msgLoaded
	call WriteString
	call Crlf
	ret

fullQueue:
	mov edx, OFFSET msgFull
	call WriteString
	call Crlf
	ret

exists:
	mov edx, OFFSET msgExists
	call WriteString
	call Crlf
	ret
LoadJob ENDP

RunJob PROC
	call GetTokenPtr
	call FindJobByName
	cmp eax, -1
	je notFound

	imul eax, SizeOfJob
	mov edi, OFFSET jobs
	add edi, eax

	mov BYTE PTR JStatus[edi], JobRun

	mov edx, OFFSET msgRunning
	call WriteString
	call Crlf
	ret

notFound:
	mov edx, OFFSET msgNotFound
	call WriteString
	call Crlf
	ret
RunJob ENDP

HoldJob PROC
	call GetTokenPtr
	call FindJobByName
	cmp eax, -1
	je notFound

	imul eax, SizeOfJob
	mov edi, OFFSET jobs
	add edi, eax

	mov BYTE PTR JStatus[edi], JobHold

	mov edx, OFFSET msgHolding
	call WriteString
	call Crlf
	ret
HoldJob ENDP

KillJob PROC
	call GetTokenPtr
	call FindJobByName
	cmp eax, -1
	je notFoundKill

	imul eax, SizeOfJob
	mov esi, OFFSET jobs
	add esi, eax

	call RemoveJobIndex

	mov edx, OFFSET msgRemoved
	call WriteString
	call Crlf
	ret

notFoundKill:
	mov edx, OFFSET msgNotFound
	call WriteString
	call Crlf
	ret
KillJob ENDP

RemoveJobIndex PROC
	mov ecx, jobCount
	cmp ecx, 0
	je doneRemove

	mov edi, esi
nextShift:
	add edi, SizeOfJob
	cmp edi, OFFSET jobs + (jobCount-1)*SizeOfJob
	jae doneShift

	mov eax, SizeOfJob
	mov esi, edi
	sub esi, SizeOfJob
	mov edx, OFFSET jobs
	add edx, esi

	mov ecx, SizeOfJob
	rep movsb

	jmp nextShift
doneShift:
	dec jobCount
doneRemove:
	ret
RemoveJobIndex ENDP

StepSystem PROC
	mov ecx, 1
StepLoop:
	call ProcessNextJob
	inc sysTime
	loop StepLoop
	ret
StepSystem ENDP

ProcessNextJob PROC
	mov ecx, jobCount
	mov esi, 0
	mov bl, LowestPriority
	mov edi, -1

findLoop:
	cmp esi, ecx
	jge done

	mov eax, esi
	imul eax, SizeOfJob
	mov edx, OFFSET jobs
	add edx, eax

	cmp BYTE PTR JStatus[edx], JobRun
	jne next

	mov al, JPriority[edx]
	cmp al, bl
	jg next

	mov bl, al
	mov edi, esi

next:
	inc esi
	jmp findLoop

done:
	cmp edi, -1
	je noJob

	imul edi, SizeOfJob
	mov edx, OFFSET jobs
	add edx, edi

	dec BYTE PTR JRunTime[edx]

	cmp BYTE PTR JRunTime[edx], 0
	jne exitProc

	call RemoveJobIndex

	mov edx, OFFSET msgDone
	call WriteString
	call Crlf

exitProc:
noJob:
	ret
ProcessNextJob ENDP

ShowJobs PROC
	mov ecx, jobCount
	mov esi, 0

showLoop:
	cmp esi, ecx
	jge doneShow

	mov eax, esi
	imul eax, SizeOfJob
	mov edx, OFFSET jobs
	add edx, eax

	add edx, JName
	call WriteString
	call Crlf

	inc esi
	jmp showLoop

doneShow:
	ret
ShowJobs ENDP

ShowHelp PROC
	mov edx, OFFSET msgHelp
	call WriteString
	call Crlf
	ret
ShowHelp ENDP

END main
