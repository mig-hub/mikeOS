; ------------------------------------------------------------------
; Machine code monitor -- by Yutaka Saito and Mike Saunders
;
; Accepts code in hex format, ORGed to 36864 (4K after where
; this program is loaded)
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768


	; This line determines where the machine code will
	; be generated -- if you change it, you will need to
	; ORG the code you enter at the new address

	CODELOC	equ 36864


	mov si, helpmsg1		; Print help text
	call os_print_string

	mov si, helpmsg2
	call os_print_string

	mov si, helpmsg3
	call os_print_string

main_loop:
	mov si, helpmsg4
	call os_print_string

.noinput:
	call os_print_newline

	mov si, prompt			; Print prompt
	call os_print_string

	mov ax, input			; Get hex string
	call os_input_string

	mov ax, input
	call os_string_length
	cmp ax, 0
	je .noinput

	mov si, input			; Convert to machine code...
	mov di, run


.more:
	cmp byte [si], '$'		; If char in string is '$', end of code
	je .done
	cmp byte [si], ' '		; If space, move on to next char
	je .space
	cmp byte [si], 'r'		; If 'r' entered, re-run existing code
	je .runprog
	cmp byte [si], 'x'		; Or if 'x' entered, return to OS
	jne .noexit
	call os_print_newline
	ret
.noexit:
	mov al, [si]
	and al, 0F0h
	cmp al, 40h
	je .H_A_to_F
.H_1_to_9:
	mov al, [si]
	sub al, 30h
	mov ah, al
	sal ah, 4
	jmp .H_end
.H_A_to_F:
	mov al, [si]
	sub al, 37h
	mov ah, al
	sal ah, 4
.H_end:
	inc si
	mov al, [si]
	and al, 0F0h
	cmp al, 40h
	je .L_A_to_F
.L_1_to_9:
	mov al, [si]
	sub al, 30h
	jmp .L_end
.L_A_to_F:
	mov al, [si]
	sub al, 37h
.L_end:
	or al, ah
	mov [di], al
	inc di
.space:
	inc si
	jmp .more
.done:
	mov byte [di], 0		; Write terminating zero

	mov si, run			; Copy machine code to location for execution
	mov di, CODELOC
	mov cx, 255
	cld
	rep movsb


.runprog:
	call os_print_newline

	call CODELOC			; Run program

	call os_print_newline

	jmp main_loop


	input		times 255 db 0	; Code entered by user (in ASCII)
	run		times 255 db 0	; Translated machine code to execute

	helpmsg1	db 'MIKEOS MACHINE CODE MONITOR', 10, 13, 0
	helpmsg2	db '(See the User Handbook for a quick guide)', 13, 10, 13, 10, 0
	helpmsg3	db 'Enter instructions in hex, terminated by $ character', 10, 13, 0
	helpmsg4	db 'Commands: r = re-run previous code, x = exit', 10, 13, 0

	prompt		db '= ', 0


; ------------------------------------------------------------------

