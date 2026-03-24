; Program 3: Multitasking Operating System Simulator
; Course: Assembly (CMSC 3100)
; Group: 3
; Members:
; 	Shawn Gallagher - GAL82896@pennwest.edu
; 	Lucas Giovannelli - GIO07221@pennwest.edu

TITLE G3P3
INCLUDE Irvine32.inc

; job structure offsets
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
jobCount DWORD 0
sysTime DWORD 0
buffer BYTE 64 DUP(0)

; command strings
cmdQuit BYTE "QUIT", 0
cmdHelp BYTE "HELP", 0
cmdShow BYTE "SHOW", 0
cmdLoad BYTE "LOAD", 0
cmdRun BYTE "RUN", 0
cmdHold BYTE "HOLD", 0
cmdKill BYTE "KILL", 0
cmdStep BYTE "STEP", 0
cmdChange BYTE "CHANGE", 0

; console messages
msgHelp BYTE "Commands: QUIT, HELP, SHOW, LOAD, RUN, HOLD, KILL, STEP, CHANGE", 0
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

; additional console strings
strSystemTime BYTE "System time: ", 0
strShowJobName BYTE "Job name: ", 0
strShowJobPriority BYTE "Priority: ", 0
strShowJobStatus BYTE "Status: ", 0
strShowJobLoadTime BYTE "Load time: ", 0
strShowJobRunTime BYTE "Run time: ", 0
strJobAvailable BYTE "AVAILABLE", 0
strJobRun BYTE "RUN", 0
strJobHold BYTE "HOLD", 0

.code
; main loop: display prompt, read command, process command
main PROC
	cld
mainLoop:
	mov edx, OFFSET msgPrompt
	call WriteString

	mov edx, OFFSET buffer
	mov ecx, SIZEOF buffer
	call ReadString
	
	cmp eax, 0 ; skip empty input
	je mainLoop

	call ToUpperBuffer
	call ProcessCommand

	jmp mainLoop
main ENDP

; convert input command to uppercase
ToUpperBuffer PROC
	mov edi, OFFSET buffer
upperLoop:
	mov al, [edi]
	cmp al, 0
	je done
	cmp al, 'a'
	jl next
	cmp al, 'z'
	jg next
	sub al, 32
	mov [edi], al
next:
	inc edi
	jmp upperLoop
done:
	ret
ToUpperBuffer ENDP

; advance pointer past any leading whitespace
SkipWhitespace PROC
skipLoop:
	mov al, [esi]
	cmp al, ' '
	jne done
	inc esi
	jmp skipLoop
done:
	ret
SkipWhitespace ENDP

; advance pointer past the current token
SkipToken PROC
skipLoop:
	mov al, [esi]
	cmp al, ' '
	je done
	cmp al, 0
	je done
	inc esi
	jmp skipLoop
done:
	ret
SkipToken ENDP

; helper to move esi to the next argument
GetNextArg PROC
	call SkipToken
	call SkipWhitespace
	ret
GetNextArg ENDP

; parse a job name from the input buffer
GetName PROC
	push edi
	mov ecx, 0
parseLoop:
	mov al, [esi]
	cmp al, ' '
	je done
	cmp al, 0
	je done
	cmp ecx, 7
	jae skipChar
	mov [edi], al
	inc edi
	inc ecx
skipChar:
	inc esi
	jmp parseLoop
done:
	mov BYTE PTR [edi], 0
	pop edi
	ret
GetName ENDP

; parse an integer parameter from the input buffer
GetNumber PROC
	mov eax, 0
	mov ebx, 0
parseLoop:
	mov bl, [esi]
	cmp bl, '0'
	jl done
	cmp bl, '9'
	jg done
	sub bl, '0'
	imul eax, 10
	add eax, ebx
	inc esi
	jmp parseLoop
done:
	ret
GetNumber ENDP

; search for a job by name
FindJob PROC
	push ebx
	push ecx
	push edx
	push edi
	push esi
	mov ebx, 0

searchLoop:
	cmp ebx, jobCount
	jge notFound
	
	pop esi ; reset esi to start of name
	push esi
	
	mov eax, ebx
	imul eax, SizeOfJob
	lea edi, jobs[eax]
compareLoop:
	mov al, [esi]
	mov dl, [edi]
	
	cmp al, ' '
	je checkEnd
	cmp al, 0
	je checkEnd
	
	cmp al, dl
	jne nextJob
	
	inc esi
	inc edi
	jmp compareLoop
checkEnd:
	cmp dl, 0
	je found
nextJob:
	inc ebx
	jmp searchLoop
found:
	pop esi
	mov eax, ebx
	jmp exitProc
notFound:
	pop esi
	mov eax, -1
exitProc:
	pop edi
	pop edx
	pop ecx
	pop ebx
	ret
FindJob ENDP

; parse the input command and execute the corresponding action
ProcessCommand PROC
	mov esi, OFFSET buffer
	call SkipWhitespace
	mov edi, esi
	cld

	; quit
	mov esi, OFFSET cmdQuit
	mov ecx, 5
	push edi
	repe cmpsb
	pop edi
	je doQuit

	; help
	mov esi, OFFSET cmdHelp
	mov ecx, 5
	push edi
	repe cmpsb
	pop edi
	je doHelp

	; show
	mov esi, OFFSET cmdShow
	mov ecx, 5
	push edi
	repe cmpsb
	pop edi
	je doShow

	; load
	mov esi, OFFSET cmdLoad
	mov ecx, 4
	push edi
	repe cmpsb
	pop edi
	je doLoad

	; run
	mov esi, OFFSET cmdRun
	mov ecx, 3
	push edi
	repe cmpsb
	pop edi
	je doRun

	; hold
	mov esi, OFFSET cmdHold
	mov ecx, 4
	push edi
	repe cmpsb
	pop edi
	je doHold

	; kill
	mov esi, OFFSET cmdKill
	mov ecx, 4
	push edi
	repe cmpsb
	pop edi
	je doKill

	; step
	mov esi, OFFSET cmdStep
	mov ecx, 4
	push edi
	repe cmpsb
	pop edi
	je doStep

	; change
	mov esi, OFFSET cmdChange
	mov ecx, 6
	push edi
	repe cmpsb
	pop edi
	je doChange

	mov edx, OFFSET msgInvalid
	call WriteString
	call Crlf
	ret

doQuit:
	exit
doHelp:
	call ShowHelp
	ret
doShow:
	call ShowJobs
	ret
doLoad:
	call LoadJob
	ret
doRun:
	call RunJob
	ret
doHold:
	call HoldJob
	ret
doKill:
	call KillJob
	ret
doStep:
	call StepSystem
	ret
doChange:
	call ChangePriority
	ret
ProcessCommand ENDP

; display help message containing command options
ShowHelp PROC
	mov edx, OFFSET msgHelp
	call WriteString
	call Crlf
	ret
ShowHelp ENDP

; display all jobs in the system
ShowJobs PROC
	call Crlf
	mov ecx, jobCount
	mov ebx, 0

showJobLoop:
	cmp ebx, ecx
	jge showDone

	mov eax, ebx
	imul eax, SizeOfJob
	lea edi, jobs[eax]

	; job name
	mov edx, OFFSET strShowJobName
	call WriteString
	lea edx, JName[edi]
	call WriteString
	call Crlf

	; job priority
	mov edx, OFFSET strShowJobPriority
	call WriteString
	movzx eax, BYTE PTR JPriority[edi]
	call WriteInt
	call Crlf

	; job status
	mov edx, OFFSET strShowJobStatus
	call WriteString
	mov al, JStatus[edi]
	.IF al == JobAvailable
		mov edx, OFFSET strJobAvailable
	.ELSEIF al == JobRun
		mov edx, OFFSET strJobRun
	.ELSE
		mov edx, OFFSET strJobHold
	.ENDIF
	call WriteString
	call Crlf

	; job load time
	mov edx, OFFSET strShowJobLoadTime
	call WriteString
	movzx eax, WORD PTR JLoadTime[edi]
	call WriteInt
	call Crlf

	; job run time
	mov edx, OFFSET strShowJobRunTime
	call WriteString
	movzx eax, WORD PTR JRunTime[edi]
	call WriteInt
	call Crlf
	call Crlf

	inc ebx
	jmp showJobLoop
showDone:
	ret
ShowJobs ENDP

; load a new job into the system
LoadJob PROC
	cmp jobCount, NumberOfJobs
	jge fullQueue

	mov esi, OFFSET buffer
	call GetNextArg
	
	push esi
	call FindJob
	pop esi
	cmp eax, -1
	jne exists

	mov ebx, jobCount
	imul ebx, SizeOfJob
	lea edi, jobs[ebx]

	call GetName
	call SkipWhitespace
	call GetNumber
	mov JPriority[edi], al

	call SkipWhitespace
	call GetNumber
	mov JRunTime[edi], ax

	mov BYTE PTR JStatus[edi], JobHold
	mov eax, sysTime
	mov JLoadTime[edi], ax

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

; change a job's status to running
RunJob PROC
	mov esi, OFFSET buffer
	call GetNextArg
	call FindJob
	cmp eax, -1
	je notFound
	imul eax, SizeOfJob
	lea edi, jobs[eax]
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

; change a job's status to holding
HoldJob PROC
	mov esi, OFFSET buffer
	call GetNextArg
	call FindJob
	cmp eax, -1
	je notFound
	imul eax, SizeOfJob
	lea edi, jobs[eax]
	mov BYTE PTR JStatus[edi], JobHold
	mov edx, OFFSET msgHolding
	call WriteString
	call Crlf
	ret

notFound:
	mov edx, OFFSET msgNotFound
	call WriteString
	call Crlf
	ret
HoldJob ENDP

; remove a job from the system
KillJob PROC
	mov esi, OFFSET buffer
	call GetNextArg
	call FindJob
	cmp eax, -1
	je notFoundKill
	imul eax, SizeOfJob
	lea esi, jobs[eax]
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

; update the system time by a certain amount (default 1)
StepSystem PROC
    mov esi, edi
    call GetNextArg
    cmp BYTE PTR [esi], 0
    jne getCount
    mov ecx, 1
    jmp startLoop

getCount:
    call GetNumber
    mov ecx, eax
startLoop:
    jecxz done
stepLoop:
    push ecx
    call ProcessNextJob
    inc sysTime
    pop ecx
    loop stepLoop
done:
    ret
StepSystem ENDP

; change the priority of a job
ChangePriority PROC
    mov esi, edi
    call GetNextArg
    push esi
    call FindJob
    pop esi
    cmp eax, -1
    je notFound
    imul eax, SizeOfJob
    lea edi, jobs[eax]
    call SkipToken
    call SkipWhitespace
    cmp BYTE PTR [esi], 0
    je notFound
    call GetNumber
    mov JPriority[edi], al
    mov edx, OFFSET msgChanged
    call WriteString
    call Crlf
    jmp done

notFound:
    mov edx, OFFSET msgNotFound
    call WriteString
    call Crlf
done:
    ret
ChangePriority ENDP

; shift subsequent jobs up to fill the gap from kill
RemoveJobIndex PROC
	pushad
	mov edi, esi
	lea esi, SizeOfJob[edi]
	
	mov eax, jobCount
	imul eax, SizeOfJob
	add eax, OFFSET jobs
	
	mov ecx, eax
	sub ecx, esi
	jbe skipMove
	
	cld
	rep movsb

skipMove:
	dec jobCount
	popad
	ret
RemoveJobIndex ENDP

; find the highest priority job that is running and process it for one time unit
ProcessNextJob PROC
	mov ecx, jobCount
	mov esi, 0
	mov bl, LowestPriority
	mov edi, -1

findLoop:
	cmp esi, ecx
	jge doneFinding
	mov eax, esi
	imul eax, SizeOfJob
	lea edx, jobs[eax]
	
	cmp BYTE PTR JStatus[edx], JobRun
	jne nextIter
	mov al, JPriority[edx]
	cmp al, bl
	ja nextIter
	mov bl, al
	mov edi, esi
nextIter:
	inc esi
	jmp findLoop
doneFinding:
	cmp edi, -1
	je noJobToRun
	
	imul edi, SizeOfJob
	lea edx, jobs[edi]
	dec WORD PTR JRunTime[edx]
	
	cmp WORD PTR JRunTime[edx], 0
	ja noJobToRun
	
	lea esi, jobs[edi]
	call RemoveJobIndex
	mov edx, OFFSET msgDone
	call WriteString
	call Crlf
noJobToRun:
	ret
ProcessNextJob ENDP

END main
