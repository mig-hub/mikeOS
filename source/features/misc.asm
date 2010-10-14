; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2010 MikeOS Developers -- see doc/LICENSE.TXT
;
; MISCELLANEOUS ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_get_api_version -- Return current version of MikeOS API
; IN: Nothing; OUT: AL = API version number

os_get_api_version:
	mov al, MIKEOS_API_VER
	ret


; ------------------------------------------------------------------
; os_pause -- Delay execution for specified microseconds
; IN: AX = number of tenths of a second to wait (so 10 = 1 second)

os_pause:
	pusha

	mov bx, ax

	mov cx, 1h
	mov dx, 86A0h
	mov ax, 0
	mov ah, 86h

.loop:
	int 15h
	dec bx
	jne .loop

	popa
	ret


; ------------------------------------------------------------------
; os_fatal_error -- Display error message and halt execution
; IN: AX = error message string location

os_fatal_error:
	mov bx, ax			; Store string location for now

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	pusha
	mov ah, 09h			; Draw red bar at top
	mov bh, 0
	mov cx, 240
	mov bl, 01001111b
	mov al, ' '
	int 10h
	popa

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	mov si, .msg_inform		; Inform of fatal error
	call os_print_string

	mov si, bx			; Program-supplied error message
	call os_print_string

	jmp $				; Halt execution

	
	.msg_inform		db '>>> FATAL OPERATING SYSTEM ERROR', 13, 10, 0


; ==================================================================

