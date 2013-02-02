; ------------------------------------------------------------------
; Program to display text files and PCX images (320x200, 8-bit only)
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768


main_start:
	call draw_background

	call os_file_selector		; Get filename

	jc near close			; Quit if Esc pressed in dialog box

	mov bx, ax			; Save filename for now

	mov di, ax

	call os_string_length
	add di, ax			; DI now points to last char in filename

	dec di
	dec di
	dec di				; ...and now to first char of extension!

	mov si, txt_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'TXT'?
	je near valid_txt_extension	; Skip ahead if so

	dec di

	mov si, bas_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'BAS'?
	je near valid_txt_extension	; Skip ahead if so

	dec di

	mov si, pcx_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'PCX'?
	je valid_pcx_extension		; Skip ahead if so

					; Otherwise show error dialog
	mov dx, 0			; One button for dialog box
	mov ax, err_string
	mov bx, 0
	mov cx, 0
	call os_dialog_box

	jmp main_start			; And retry


valid_pcx_extension:
	mov ax, bx
	mov cx, 36864			; Load PCX at 36864 (4K after program start)
	call os_load_file


	mov ah, 0			; Switch to graphics mode
	mov al, 13h
	int 10h


	mov ax, 0A000h			; ES = video memory
	mov es, ax


	mov si, 36864+80h		; Move source to start of image data
					; (First 80h bytes is header)

	mov di, 0			; Start our loop at top of video RAM

decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
single:
	rep stosb			; And show it (or all of them)
	cmp di, 64001
	jb decode


	mov dx, 3c8h			; Palette index register
	mov al, 0			; Start at colour 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

	mov cx, 768			; 256 colours, 3 bytes each
setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop setpal


	call os_wait_for_key

	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	mov ax, 2000h			; Reset ES back to original value
	mov es, ax
	call os_clear_screen
	jmp main_start


draw_background:
	mov ax, title_msg		; Set up screen
	mov bx, footer_msg
	mov cx, BLACK_ON_WHITE
	call os_draw_background
	ret



	; Meanwhile, if it's a text file...

valid_txt_extension:
	mov ax, bx
	mov cx, 36864			; Load file 4K after program start
	call os_load_file


	; Now BX contains the number of bytes in the file, so let's add
	; the load offset to get the last byte of the file in RAM

	add bx, 36864


	mov cx, 0			; Lines to skip when rendering
	mov word [skiplines], 0


	pusha
	mov ax, txt_title_msg		; Set up screen
	mov bx, txt_footer_msg
	mov cx, 11110000b		; Black text on white background
	call os_draw_background
	popa



txt_start:
	pusha

	mov bl, 11110000b		; Black text on white background
	mov dh, 2
	mov dl, 0
	mov si, 80
	mov di, 23
	call os_draw_block		; Overwrite old text for scrolling

	mov dh, 2			; Move cursor to near top
	mov dl, 0
	call os_move_cursor

	popa


	mov si, 36864			; Start of text data
	mov ah, 0Eh			; BIOS char printing routine


redraw:
	cmp cx, 0			; How many lines to skip?
	je loopy
	dec cx

skip_loop:
	lodsb				; Read bytes until newline, to skip a line
	cmp al, 10
	jne skip_loop
	jmp redraw


loopy:
	lodsb				; Get character from file data

	cmp al, 10			; Return to start of line if carriage return character
	jne skip_return
	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

skip_return:
	int 10h				; Print the character

	cmp si, bx			; Have we printed all in the file?
	je finished

	call os_get_cursor_pos		; Are we at the bottom of the display area?
	cmp dh, 23
	je get_input

	jmp loopy


get_input:				; Get cursor keys and Q
	call os_wait_for_key
	cmp ah, KEY_UP
	je go_up
	cmp ah, KEY_DOWN
	je go_down
	cmp al, 'q'
	je main_start
	cmp al, 'Q'
	je main_start
	jmp get_input


go_up:
	cmp word [skiplines], 0		; Don't scroll up if we're at the top
	jle txt_start
	dec word [skiplines]		; Otherwise decrement the lines we need to skip
	mov word cx, [skiplines]
	jmp txt_start

go_down:
	inc word [skiplines]		; Increment the lines we need to skip
	mov word cx, [skiplines]
	jmp txt_start


finished:				; We get here when we've printed the final character
	call os_wait_for_key
	cmp ah, 48h
	je go_up			; Can only scroll up at this point
	cmp al, 'q'
	je main_start
	cmp al, 'Q'
	je main_start
	jmp finished


close:
	call os_clear_screen
	ret


	txt_extension	db 'TXT', 0
	bas_extension	db 'BAS', 0
	pcx_extension	db 'PCX', 0

	err_string	db 'Please select a TXT, BAS or PCX file!', 0

	title_msg	db 'MikeOS File Viewer', 0
	footer_msg	db 'Select a TXT, BAS or PCX file to view, or press Esc to exit', 0

	txt_title_msg	db 'MikeOS Text File Viewer', 0
	txt_footer_msg	db 'Use arrow keys to scroll and Q to quit', 0

	skiplines	dw 0


; ------------------------------------------------------------------

