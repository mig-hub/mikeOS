; ------------------------------------------------------------------
; Minicom-like program for MikeOS
; ------------------------------------------------------------------


; With this program and an appropriate serial (null modem) cable, you
; can log in to Linux machines. You will need your Linux box to establish
; a serial terminal in /etc/inittab, with something like this:
;
;	T0:2345:respawn:/sbin/getty/ -L ttyS0 9600 vt100
;
; Connect the serial cable to your MikeOS machine and Linux machine.
; Start MikeOS and run SERIAL.BIN, then start your Linux box with the
; above serial terminal entry. On the MikeOS machine, you will see a
; familiar Linux login prompt -- you're ready to go! Note that very few
; VT100 terminal features are implemented at present, so complicated
; programs (eg Emacs) will not display correctly.
;
; Press the F8 key to exit.


	BITS 16

	%INCLUDE "mikedev.inc"
	ORG 32768


start:
	mov ax, warnmsg_1
	mov bx, warnmsg_2
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	cmp ax, 0
	je .proceed

	call os_clear_screen
	ret


.proceed:
	call os_clear_screen

	mov ax, 0			; 9600 baud mode
	call os_serial_port_enable

	mov si, start_msg
	call os_print_string


main_loop:
	mov dx, 0			; Set port to COM1
	mov ax, 0
	mov ah, 03h			; Check COM1 status
	int 14h

	bt ax, 8			; Data received?
	jc received_byte

	mov ax, 0			; If not, have we something to send?
	call os_check_for_key

	cmp ax, 4200h			; F8 key pressed?
	je finish			; Quit if so

	cmp al, 0			; If no other key pressed, go back
	je main_loop

	call os_send_via_serial		; Otherwise send it
	jmp main_loop

received_byte:				; Print data received
	call os_get_via_serial

	cmp al, 1Bh			; 'Esc' character received?
	je esc_received

	mov ah, 0Eh			; Otherwise print char
	int 10h
	jmp main_loop

finish:
	mov si, finish_msg
	call os_print_string

	call os_wait_for_key

	ret



esc_received:
	call os_get_via_serial		; Get next character...
	cmp al, '['			; Is it a screen control code?
	jne main_loop

	mov bl, al			; Store for now

	call os_get_via_serial		; If control code, parse it

	cmp al, 'H'
	je near move_to_home

	cmp al, 'J'
	je near erase_to_bottom

	cmp al, 'K'
	je near erase_to_end_of_line


					; If it wasn't a control char that
					; we can parse yet, print the whole
					; thing for debugging purposes

	mov cl, al			; Store second char
	mov al, bl			; Get first

	mov ah, 0Eh			; Print them
	int 10h
	mov al, cl
	int 10h

	jmp main_loop



move_to_home:
	mov dx, 0
	call os_move_cursor
	jmp main_loop


erase_to_bottom:
	call os_get_cursor_pos

	push dx				; Store where we are

	call erase_sub

	inc dh				; Move to start of next line
	mov dl, 0
	call os_move_cursor

	mov ah, 0Ah			; Get ready to print 80 spaces
	mov al, ' '
	mov bx, 0
	mov cx, 80
.more:
	int 10h
	inc dh				; Next line...
	call os_move_cursor
	cmp dh, 25			; Reached bottom of screen?
	jne .more

	pop dx				; Put cursor back to where we started
	call os_move_cursor

	jmp main_loop



erase_to_end_of_line:
	call erase_sub
	jmp main_loop


erase_sub:
	call os_get_cursor_pos

	push dx				; Store where we are

	mov ah, 80			; Calculate how many spaces
	sub ah, dl			; we need to print...

	mov cx, 0			; And drop into CL
	mov cl, ah

	mov ah, 0Ah			; Print spaces CL number of times
	mov al, ' '
	mov bx, 0
	int 10h

	pop dx
	call os_move_cursor

	ret


	warnmsg_1	db 'Serial terminal program -- may lock up', 0
	warnmsg_2	db 'if you have no serial ports! Proceed?', 0

	start_msg	db 'MikeOS minicom -- Press F8 to quit', 13, 10, 'Connecting via serial at 9600 baud...', 13, 10, 13, 10, 0
	finish_msg	db 13, 10, 13, 10, 'Exiting MikeOS minicom; press a key to return to MikeOS', 13, 10, 0


; ------------------------------------------------------------------

