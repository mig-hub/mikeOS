; ------------------------------------------------------------------
; Music keyboard -- Use the keyboard to play notes via the PC speaker
; Use Z key rightwards for an octave
; ------------------------------------------------------------------


	BITS 16
 	%INCLUDE "mikedev.inc"
	ORG 32768


start:
	call os_hide_cursor

	call os_clear_screen

	mov ax, mus_kbd_title_msg		; Set up screen
	mov bx, mus_kbd_footer_msg
	mov cx, WHITE_ON_LIGHT_RED
	call os_draw_background

	mov bl, BLACK_ON_WHITE			; White block to draw keyboard on
	mov dh, 4
	mov dl, 5
	mov si, 69
	mov di, 21
	call os_draw_block



	; Now lots of loops to draw the keyboard

	mov dl, 24		; Top line of box
	mov dh, 6
	call os_move_cursor

	mov ah, 0Eh
	mov al, 196

	mov cx, 31
.loop1:
	int 10h
	loop .loop1


	mov dl, 24		; Bottom line of box
	mov dh, 18
	call os_move_cursor

	mov ah, 0Eh
	mov al, 196

	mov cx, 31
.loop2:
	int 10h
	loop .loop2



	mov dl, 23		; Top-left corner
	mov dh, 6
	call os_move_cursor

	mov al, 218
	int 10h


	mov dl, 55		; Top-right corner
	mov dh, 6
	call os_move_cursor

	mov al, 191
	int 10h


	mov dl, 23		; Bottom-left corner
	mov dh, 18
	call os_move_cursor

	mov al, 192
	int 10h


	mov dl, 55		; Bottom-right corner
	mov dh, 18
	call os_move_cursor

	mov al, 217
	int 10h


	mov dl, 23		; Left-hand box line
	mov dh, 7
	mov al, 179
.loop3:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 18
	jne .loop3


	mov dl, 55		; Right-hand box line
	mov dh, 7
	mov al, 179
.loop4:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 18
	jne .loop4


	mov dl, 23		; Key-separating lines
.biggerloop:
	add dl, 4
	mov dh, 7
	mov al, 179
.loop5:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 18
	jne .loop5
	cmp dl, 51
	jne .biggerloop


	mov al, 194		; Top of box line joiners
	mov dh, 6
	mov dl, 27
.loop6:
	call os_move_cursor
	int 10h
	add dl, 4
	cmp dl, 55
	jne .loop6


	mov al, 193		; Bottom of box line joiners
	mov dh, 18
	mov dl, 27
.loop7:
	call os_move_cursor
	int 10h
	add dl, 4
	cmp dl, 55
	jne .loop7


	; And now for the black keys...

	mov bl, WHITE_ON_BLACK

	mov dh, 6
	mov dl, 26
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 30
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 38
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 42
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 46
	mov si, 3
	mov di, 13
	call os_draw_block



	; And lastly, draw the labels on the keys indicating which
	; (computer!) keys to press to get notes
	
	mov ah, 0Eh

	mov dh, 17
	mov dl, 25
	call os_move_cursor

	mov al, 'Z'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'X'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'C'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'V'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'B'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'N'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'M'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, ','
	int 10h

	; Now the accidentals...
	
	mov dh, 11
	mov dl, 27
	call os_move_cursor
	mov al, 'S'
	int 10h
	
	add dl, 4
	call os_move_cursor
	mov al, 'D'
	int 10h
	
	add dl, 8
	call os_move_cursor
	mov al, 'G'
	int 10h
	
	add dl, 4
	call os_move_cursor
	mov al, 'H'
	int 10h
	
	add dl, 4
	call os_move_cursor
	mov al, 'J'
	int 10h

	; Phew! We've drawn all the keys now

.retry:
	call os_wait_for_key

.nokey:				; Matching keys with notes
	cmp al, 'z'
	jne .s
	mov ax, 4000
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.s:
	cmp al, 's'
	jne .x
	mov ax, 3800
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.x:
	cmp al, 'x'
	jne .d
	mov ax, 3600
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.d:
	cmp al, 'd'
	jne .c
	mov ax, 3400
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.c:
	cmp al, 'c'
	jne .v
	mov ax, 3200
	mov bx, 0
	call os_speaker_tone
	jmp .retry


.v:
	cmp al, 'v'
	jne .g
	mov ax, 3000
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.g:
	cmp al, 'g'
	jne .b
	mov ax, 2850
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.b:
	cmp al, 'b'
	jne .h
	mov ax, 2700
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.h:
	cmp al, 'h'
	jne .n
	mov ax, 2550
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.n:
	cmp al, 'n'
	jne .j
	mov ax, 2400
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.j:
	cmp al, 'j'
	jne .m
	mov ax, 2250
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.m:
	cmp al, 'm'
	jne .comma
	mov ax, 2100
	mov bx, 0
	call os_speaker_tone
	jmp .retry

.comma:
	cmp al, ','
	jne .space
	mov ax, 2000
	mov bx, 0
	call os_speaker_tone
	jmp .retry

.space:
	cmp al, ' '
	jne .esc
	call os_speaker_off
	jmp .retry

.esc:
	cmp al, 27
	je .end
	jmp .nowt

.nowt:
	jmp .retry

.end:
	call os_speaker_off

	call os_clear_screen

	call os_show_cursor

	ret			; Back to OS


	mus_kbd_title_msg	db 'MikeOS Music Keyboard (PC speaker sound)', 0
	mus_kbd_footer_msg	db 'Hit keys to play notes, space to silence a note, and Esc to quit', 0


; ------------------------------------------------------------------

