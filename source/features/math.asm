; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2014 MikeOS Developers -- see doc/LICENSE.TXT
;
; MATH ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_seed_random -- Seed the random number generator based on clock
; IN: Nothing; OUT: Nothing (registers preserved)

os_seed_random:
	push bx
	push ax

	mov bx, 0
	mov al, 0x02			; Minute
	out 0x70, al
	in al, 0x71

	mov bl, al
	shl bx, 8
	mov al, 0			; Second
	out 0x70, al
	in al, 0x71
	mov bl, al

	mov word [os_random_seed], bx	; Seed will be something like 0x4435 (if it
					; were 44 minutes and 35 seconds after the hour)
	pop ax
	pop bx
	ret


	os_random_seed	dw 0


; ------------------------------------------------------------------
; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

os_get_random:
	push dx
	push bx
	push ax

	sub bx, ax			; We want a number between 0 and (high-low)
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax			; Add the low offset back
	ret


.generate_random:
	push dx
	push bx

	mov ax, [os_random_seed]
	mov dx, 0x7383			; The magic number (random.org)
	mul dx				; DX:AX = AX * DX
	mov [os_random_seed], ax

	pop bx
 	pop dx
	ret


; ------------------------------------------------------------------
; os_bcd_to_int -- Converts binary coded decimal number to an integer
; IN: AL = BCD number; OUT: AX = integer value

os_bcd_to_int:
	pusha

	mov bl, al			; Store entire number for now

	and ax, 0Fh			; Zero-out high bits
	mov cx, ax			; CH/CL = lower BCD number, zero extended

	shr bl, 4			; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Add lower BCD to 10*higher
	mov [.tmp], ax

	popa
	mov ax, [.tmp]			; And return it in AX!
	ret


	.tmp	dw 0


; ------------------------------------------------------------------
; os_long_int_negate -- Multiply value in DX:AX by -1
; IN: DX:AX = long integer; OUT: DX:AX = -(initial DX:AX)

os_long_int_negate:
	neg ax
	adc dx, 0
	neg dx
	ret


; ==================================================================

