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

HighestPriority equ 0
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
msgPrompt BYTE "Enter a command: ", 0

msgLoaded BYTE "Job loaded.", 0
msgRunning BYTE "Job set to RUN.", 0
msgHolding BYTE "Job set to HOLD.", 0
msgRemoved BYTE "Job removed.", 0
msgChangedPriority BYTE "Job priority changed.", 0

errInvalidCommand BYTE "Invalid command!", 0
errQueueFull BYTE "Job queue full!", 0
errAlreadyExists BYTE "Job already exists!", 0
errMissingParam BYTE "Missing parameter(s)!", 0
errNotFound BYTE "Job not found!", 0
errOutOfRange BYTE "Priority must be between 0 and 7!", 0

msgSystemTime BYTE "System time: ", 0
msgJobName BYTE "Job name: ", 0
msgJobPriority BYTE "Priority: ", 0
msgJobStatus BYTE "Status: ", 0
msgJobLoadTime BYTE "Load time: ", 0
msgJobRunTime BYTE "Run time: ", 0
msgJobFinished BYTE "Finished at time: ", 0

msgJobAvailable BYTE "AVAILABLE", 0
msgJobRun BYTE "RUN", 0
msgJobHold BYTE "HOLD", 0

msgHelp BYTE "Commands: QUIT, HELP, SHOW, LOAD, RUN, HOLD, KILL, STEP, CHANGE", 0
msgComma BYTE ", ", 0

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

; advance buffer pointer past any whitespace
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

; advance buffer pointer past the current token
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
GetNextParam PROC
	call SkipToken
	call SkipWhitespace
	ret
GetNextParam ENDP

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
	jge skipChar
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
	mov edi, OFFSET jobs
	add edi, eax
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
	jmp done
notFound:
	pop esi
	mov eax, -1
done:
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

	; invalid command
	mov edx, OFFSET errInvalidCommand
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

showLoop:
	cmp ebx, ecx
	jge done

	mov eax, ebx
	imul eax, SizeOfJob
	mov edi, OFFSET jobs
	add edi, eax

	; job name
	mov edx, OFFSET msgJobName
	call WriteString
	mov edx, edi
	add edx, JName
	call WriteString
	call Crlf

	; job priority
	mov edx, OFFSET msgJobPriority
	call WriteString
	mov eax, 0
	mov al, JPriority[edi]
	call WriteInt
	call Crlf

	; job status
	mov edx, OFFSET msgJobStatus
	call WriteString
	mov al, JStatus[edi]
	cmp al, JobAvailable
	je statusAvailable
	cmp al, JobRun
	je statusRun
	cmp al, JobHold
	je statusHold
	statusAvailable:
		mov edx, OFFSET msgJobAvailable
		jmp statusDone
	statusRun:
		mov edx, OFFSET msgJobRun
		jmp statusDone
	statusHold:
		mov edx, OFFSET msgJobHold
		jmp statusDone
	statusDone:
		call WriteString
		call Crlf

	; job load time
	mov edx, OFFSET msgJobLoadTime
	call WriteString
	mov eax, 0
	mov ax, JLoadTime[edi]
	call WriteInt
	call Crlf

	; job run time
	mov edx, OFFSET msgJobRunTime
	call WriteString
	mov eax, 0
	mov ax, JRunTime[edi]
	call WriteInt
	call Crlf

	call Crlf
	inc ebx
	jmp showLoop
done:
	ret
ShowJobs ENDP

; load a new job into the system
LoadJob PROC
	; validate enough room for new job
	cmp jobCount, NumberOfJobs
	jge fullQueue

	mov esi, OFFSET buffer
	call GetNextParam
	
	; validate name parameter
	cmp BYTE PTR [esi], 0
	je missingParam

	; validate job doesn't already exist
	call FindJob
	cmp eax, -1
	jne exists
	mov ebx, jobCount
	imul ebx, SizeOfJob
	mov edi, OFFSET jobs
	add edi, ebx
	call GetName 
	
	; validate priority parameter
	call SkipWhitespace
	cmp BYTE PTR [esi], 0
	je missingParam
	call GetNumber
	mov JPriority[edi], al

	; validate run time parameter
	call SkipWhitespace
	cmp BYTE PTR [esi], 0
	je missingParam
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
	mov edx, OFFSET errQueueFull
	call WriteString
	call Crlf
	ret
missingParam:
	mov edx, OFFSET errMissingParam
	call WriteString
	call Crlf
	ret
exists:
	mov edx, OFFSET errAlreadyExists
	call WriteString
	call Crlf
	ret
LoadJob ENDP

; change a job's status to running
RunJob PROC
	mov esi, OFFSET buffer
	call GetNextParam

	; validate name parameter
	cmp BYTE PTR [esi], 0
	je missingParam

	; validate job exists
	call FindJob
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

missingParam:
	mov edx, OFFSET errMissingParam
	call WriteString
	call Crlf
	ret
notFound:
	mov edx, OFFSET errNotFound
	call WriteString
	call Crlf
	ret
RunJob ENDP

; change a job's status to holding
HoldJob PROC
	mov esi, OFFSET buffer
	call GetNextParam
	call FindJob
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

notFound:
	mov edx, OFFSET errNotFound
	call WriteString
	call Crlf
	ret
HoldJob ENDP

; shift subsequent jobs up to fill the gap from kill
RemoveJobIndex PROC
	pushad
	mov edi, esi
	mov esi, edi
	add esi, SizeOfJob
	
	mov eax, jobCount
	imul eax, SizeOfJob
	add eax, OFFSET jobs
	
	mov ecx, eax
	sub ecx, esi
	jle skipMove
	
	cld
	rep movsb

skipMove:
	dec jobCount
	popad
	ret
RemoveJobIndex ENDP

; remove a job from the system
KillJob PROC
	mov esi, OFFSET buffer
	call GetNextParam

	; validate name parameter
	cmp BYTE PTR [esi], 0
	je missingParam

	; validate job exists
	call FindJob
	cmp eax, -1
	je notFound
	imul eax, SizeOfJob
	mov esi, OFFSET jobs
	add esi, eax
	call RemoveJobIndex

	mov edx, OFFSET msgRemoved
	call WriteString
	call Crlf
	ret

missingParam:
	mov edx, OFFSET errMissingParam
	call WriteString
	call Crlf
	ret
notFound:
	mov edx, OFFSET errNotFound
	call WriteString
	call Crlf
	ret
KillJob ENDP

; update the system time by a certain amount (default 1)
StepSystem PROC
	mov esi, OFFSET buffer
	call GetNextParam
	
	cmp BYTE PTR [esi], 0
	jne getCount
	mov ecx, 1
	jmp startStepLoop

getCount:
	call GetNumber
	mov ecx, eax
startStepLoop:
	cmp ecx, 0
	jbe done
stepLoop:
	push ecx
	inc sysTime
	
	mov edx, OFFSET msgSystemTime
	call WriteString
	mov eax, sysTime
	call WriteInt
	call Crlf

	call ProcessNextJob
	pop ecx
	loop stepLoop
done:
	ret
StepSystem ENDP

; find the highest priority job that is running and process it for one time unit
ProcessNextJob PROC
	pushad
	mov ecx, jobCount
	mov esi, 0
	mov bl, 8
	mov edi, -1

findLoop:
	cmp esi, jobCount
	jge found

	mov eax, esi
	imul eax, SizeOfJob
	add eax, OFFSET jobs
	
	cmp BYTE PTR JStatus[eax], JobRun
	jne nextIter
	
	mov dl, JPriority[eax]
	cmp dl, bl
	jge nextIter
	
	mov bl, dl
	mov edi, esi
nextIter:
	inc esi
	jmp findLoop
found:
	cmp edi, -1
	je done

	mov eax, edi
	imul eax, SizeOfJob
	add eax, OFFSET jobs
	mov ebx, eax
	dec WORD PTR [ebx + JRunTime]

	; display running job status
	mov edx, OFFSET msgJobName
	call WriteString
	lea edx, [ebx + JName]
	call WriteString
	mov edx, OFFSET msgComma
	call WriteString
	mov edx, OFFSET msgJobRunTime
	call WriteString
	movzx eax, WORD PTR [ebx + JRunTime]
	call WriteInt

	; check if job finished
	cmp WORD PTR [ebx + JRunTime], 0
	jne notFinished

	; if job is finished, print finished time and remove it
	mov edx, OFFSET msgComma
	call WriteString
	mov edx, OFFSET msgJobFinished
	call WriteString
	mov eax, sysTime
	call WriteInt
	call Crlf

	mov esi, ebx
	call RemoveJobIndex
	jmp done
notFinished:
	call Crlf
done:
	popad
	ret
ProcessNextJob ENDP

; change the priority of a job
ChangePriority PROC
	mov esi, OFFSET buffer
	call GetNextParam
	
	; validate name parameter
	cmp BYTE PTR [esi], 0
	je missingParam

	; validate job exists
	call FindJob
	cmp eax, -1
	je notFound
	imul eax, SizeOfJob
	mov edi, OFFSET jobs
	add edi, eax

	call SkipToken
	call SkipWhitespace

	; validate priority parameter
	cmp BYTE PTR [esi], 0
	je missingParam
	call GetNumber
	cmp al, HighestPriority 
	jl outOfRange
	cmp al, LowestPriority
	jg outOfRange
	mov JPriority[edi], al

	mov edx, OFFSET msgChangedPriority
	call WriteString
	call Crlf
	ret

missingParam:
	mov edx, OFFSET errMissingParam
	call WriteString
	call Crlf
	ret
outOfRange:
	mov edx, OFFSET errOutOfRange
	call WriteString
	call Crlf
	ret
notFound:
	mov edx, OFFSET errNotFound
	call WriteString
	call Crlf
	ret
ChangePriority ENDP

END main
