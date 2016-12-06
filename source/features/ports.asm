; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2014 MikeOS Developers -- see doc/LICENSE.TXT
;
; PORT INPUT AND OUTPUT ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_port_byte_out -- Send byte to a port
; IN: DX = port address, AL = byte to send

os_port_byte_out:
	pusha

	out dx, al

	popa
	ret


; ------------------------------------------------------------------
; os_port_byte_in -- Receive byte from a port
; IN: DX = port address
; OUT: AL = byte from port

os_port_byte_in:
	pusha

	in al, dx
	mov word [.tmp], ax

	popa
	mov ax, [.tmp]
	ret


	.tmp dw 0


; ------------------------------------------------------------------
; os_serial_port_enable -- Set up the serial port for transmitting data
; IN: AX = 0 for normal mode (9600 baud), or 1 for slow mode (1200 baud)

os_serial_port_enable:
	pusha

	mov dx, 0			; Configure serial port 1
	cmp ax, 1
	je .slow_mode

	mov ah, 0
	mov al, 11100011b		; 9600 baud, no parity, 8 data bits, 1 stop bit
	jmp .finish

.slow_mode:
	mov ah, 0
	mov al, 10000011b		; 1200 baud, no parity, 8 data bits, 1 stop bit	

.finish:
	int 14h

	popa
	ret


; ------------------------------------------------------------------
; os_send_via_serial -- Send a byte via the serial port
; IN: AL = byte to send via serial; OUT: AH = Bit 7 clear on success

os_send_via_serial:
	pusha

	mov ah, 01h
	mov dx, 0			; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret


	.tmp dw 0


; ------------------------------------------------------------------
; os_get_via_serial -- Get a byte from the serial port
; OUT: AL = byte that was received; OUT: AH = Bit 7 clear on success

os_get_via_serial:
	pusha

	mov ah, 02h
	mov dx, 0			; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret


	.tmp dw 0


; ==================================================================

