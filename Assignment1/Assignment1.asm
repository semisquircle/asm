title Assignment1
; Assignment 1: Average Program
; Group 3 (Shawn Gallagher, Lucas Giovannelli)
INCLUDE Irvine32.inc
.data
message byte "hello world", 0
.code
main PROC
mov edx, OFFSET message
call WriteString
call Crlf
exit
main ENDP
END main
