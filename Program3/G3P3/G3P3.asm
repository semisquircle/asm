; Program 3: Multitasking Operating System Simulator
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P3
INCLUDE Irvine32.inc

JName EQU 0
JPriority EQU 8
JStatus EQU 9
JRunTime EQU 10
JLoadTime EQU 12

JobAvailable EQU 0
JobRun EQU 1
JobHold EQU 2

LowestPriority equ 7
SizeOfJob EQU 14
NumberOfJobs EQU 10

.data
Jobs BYTE NumberOfJobs * SizeOfJob DUP(JobAvailable)

jobCount DWORD 0
sysTime DWORD 0

buffer BYTE 64 DUP(0)

cmdQuit BYTE "QUIT", 0
cmdHelp BYTE "HELP", 0
cmdShow BYTE "SHOW", 0
cmdLoad BYTE "LOAD", 0
cmdRun  BYTE "RUN", 0
cmdHold BYTE "HOLD", 0
cmdKill BYTE "KILL", 0
cmdStep BYTE "STEP", 0
cmdChange BYTE "CHANGE", 0

msgHelp BYTE "Commands: LOAD RUN HOLD KILL SHOW STEP CHANGE QUIT", 0
msgPrompt BYTE ">> ", 0
msgInvalid BYTE "Invalid command", 0
msgFull BYTE "Job queue full!", 0
msgExists BYTE "Job already exists!", 0
msgNotFound BYTE "Job not found!", 0
msgRemoved BYTE "Job removed", 0
msgLoaded BYTE "Job loaded", 0
msgRunning BYTE "Job running", 0
msgHolding BYTE "Job holding", 0
msgDone BYTE "Job completed", 0

.code
main PROC
mainLoop:
	mov edx, OFFSET msgPrompt
	call WriteString

	mov edx, OFFSET buffer
	mov ecx, 64
	call ReadString
	call ParseCommand

	jmp mainLoop
main ENDP

ParseCommand PROC
	call SkipSpaces ; NEEDS FIXING
	cld

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdQuit
	mov ecx, SIZEOF cmdQuit
	repe cmpsb
	je DoQuit

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdHelp
	mov ecx, SIZEOF cmdHelp
	repe cmpsb
	je DoHelp

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdShow
	mov ecx, SIZEOF cmdShow
	repe cmpsb
	je DoShow

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdLoad
	mov ecx, SIZEOF cmdLoad
	repe cmpsb
	je DoLoad

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdRun
	mov ecx, SIZEOF cmdRun
	repe cmpsb
	je DoRun

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdHold
	mov ecx, SIZEOF cmdHold
	repe cmpsb
	je DoHold

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdKill
	mov ecx, SIZEOF cmdKill
	repe cmpsb
	je DoKill

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdStep
	mov ecx, SIZEOF cmdStep
	repe cmpsb
	je DoStep

	mov edi, OFFSET buffer
	mov esi, OFFSET cmdChange
	mov ecx, SIZEOF cmdChange
	repe cmpsb
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
	call StepSystem
	ret
DoChange:
	call ChangePriority
	ret
ParseCommand ENDP

LoadJob PROC
	cmp jobCount, NumberOfJobs
	jge fullQueue

	call GetJobName ; NEEDS FIXING
	call FindJob ; NEEDS FIXING
	cmp eax, -1
	jne exists

	mov ebx, jobCount
	imul ebx, SizeOfJob
	mov edi, OFFSET Jobs
	add edi, ebx

	call CopyName ; NEEDS FIXING

	call GetNumber ; NEEDS FIXING
	mov JPriority[edi], al

	call GetNumber ; NEEDS FIXING
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
	call FindJobByInput ; NEEDS FIXING
	cmp eax, -1
	je notFound

	imul eax, SizeOfJob
	mov edi, OFFSET Jobs
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
	call FindJobByInput ; NEEDS FIXING
	cmp eax, -1
	je notFound

	imul eax, SizeOfJob
	mov edi, OFFSET Jobs
	add edi, eax

	mov BYTE PTR JStatus[edi], JobHold

	mov edx, OFFSET msgHolding
	call WriteString
	call Crlf
	ret
HoldJob ENDP

KillJob PROC
	call FindJobByInput ; NEEDS FIXING
	cmp eax, -1
	je notFound

	call RemoveJobIndex

	mov edx, OFFSET msgRemoved
	call WriteString
	call Crlf
	ret
KillJob ENDP

StepSystem PROC
	mov ecx, 1

stepLoop:
	call ProcessNextJob
	inc sysTime
	loop stepLoop
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
	mov edx, OFFSET Jobs
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
	mov edx, OFFSET Jobs
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
	jge done

	mov eax, esi
	imul eax, SizeOfJob
	mov edx, OFFSET Jobs
	add edx, eax

	lea edx, JName[edx] ; NEEDS FIXING, just weird to use lea
	call WriteString
	call Crlf

	inc esi
	jmp showLoop

done:
	ret
ShowJobs ENDP

RemoveJobIndex PROC
	dec jobCount
	ret
RemoveJobIndex ENDP

ShowHelp PROC
	mov edx, OFFSET msgHelp
	call WriteString
	call Crlf
	ret
ShowHelp ENDP

END main
