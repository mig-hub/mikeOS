; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2010 MikeOS Developers -- see doc/LICENSE.TXT
;
; COMMAND LINE INTERFACE
; ==================================================================

os_command_line:
	call os_clear_screen

	mov si, version_msg
	call os_print_string
	mov si, help_text
	call os_print_string

get_cmd:
	mov si, prompt			; Main loop; prompt for input
	call os_print_string

	mov ax, input			; Get command string from user
	call os_input_string

	call os_print_newline

	mov ax, input			; Remove trailing spaces
	call os_string_chomp

	mov si, input			; If just enter pressed, prompt again
	cmp byte [si], 0
	je get_cmd

	mov si, input			; Convert to uppercase for comparison
	call os_string_uppercase


	mov si, input

	mov di, exit_string		; 'EXIT' entered?
	call os_string_compare
	jc near exit

	mov di, help_string		; 'HELP' entered?
	call os_string_compare
	jc near print_help

	mov di, cls_string		; 'CLS' entered?
	call os_string_compare
	jc near clear_screen

	mov di, dir_string		; 'DIR' entered?
	call os_string_compare
	jc near list_directory

	mov di, ver_string		; 'VER' entered?
	call os_string_compare
	jc near print_ver

	mov di, time_string		; 'TIME' entered?
	call os_string_compare
	jc near print_time

	mov di, date_string		; 'DATE' entered?
	call os_string_compare
	jc near print_date

	mov di, cat_string		; 'CAT' entered?
	mov cl, 3
	call os_string_strincmp
	jc near cat_file



	; If the user hasn't entered any of the above commands, then we
	; need to check if an executable filename (.BIN) was entered...

	mov si, input			; User entered dot in filename?
	mov al, '.'
	call os_find_char_in_string
	cmp ax, 0
	je suffix

	jmp full_name

suffix:
	mov ax, input
	call os_string_length

	mov si, input
	add si, ax			; Move to end of input string

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0		; Zero-terminate string


full_name:
	mov si, input			; User tried to execute kernel?
	mov di, kern_file_string
	call os_string_compare
	jc near kern_warning

	mov ax, input			; If not, try to load specified program
	mov bx, 0
	mov cx, 32768
	call os_load_file
	mov word [file_size], bx

	jc bin_fail			; Skip next part if program with .BIN not found

	mov ax, input			; Get into right place in filename to check extension
	call os_string_length
	mov si, input
	add si, ax
	sub si, 3

	mov di, bin_extension		; Is it BIN?
	call os_string_compare
	jnc is_basic_file

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, 0
	mov di, 0

	call 32768			; Call the external program

	jmp get_cmd			; When program has finished, start again


is_basic_file:
	mov ax, input
	call os_string_length
	mov si, input
	add si, ax
	sub si, 3

	mov di, bas_extension
	call os_string_compare
	jnc total_fail

	mov ax, 32768
	mov word bx, [file_size]
	call os_run_basic

	jmp get_cmd




bin_fail:
	mov ax, input
	call os_string_length

	mov si, input
	add si, ax			; Move to end of input string
	sub si, 4			; Subtract 4 chars, because we added .BIN to it before!

	mov byte [si], '.'		; See if there's a .BAS extension for this
	mov byte [si+1], 'B'
	mov byte [si+2], 'A'
	mov byte [si+3], 'S'
	mov byte [si+4], 0		; Zero-terminate string

	mov ax, input			; Try to load the .BAS code
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail			; Skip if program not found

	mov ax, 32768
	call os_run_basic		; Otherwise execute the code!

	jmp get_cmd

total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd


; ------------------------------------------------------------------

print_help:
	mov si, help_text
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

clear_screen:
	call os_clear_screen
	jmp get_cmd


; ------------------------------------------------------------------

print_time:
	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_date:
	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_ver:
	mov si, version_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

kern_warning:
	mov si, kern_warn_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

list_directory:
	mov cx,	0			; Counter

	mov ax, dirlist			; Get list of files on disk
	call os_get_file_list

	mov si, dirlist
	mov ah, 0Eh			; BIOS teletype function

.repeat:
	lodsb				; Start printing filenames
	cmp al, 0			; Quit if end of string
	je .done

	cmp al, ','			; If comma in list string, don't print it
	jne .nonewline
	pusha
	call os_print_newline		; But print a newline instead
	popa
	jmp .repeat

.nonewline:
	int 10h
	jmp .repeat

.done:
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

cat_file:
	mov si, input
	call os_string_parse
	cmp bx, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov ax, bx

	call os_file_exists		; Check if file exists
	jc .not_found

	mov cx, 32768			; Load file into second 32K
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			; Nothing in the file?
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			; int 10h teletype function
.loop:
	lodsb				; Get byte from loaded file

	cmp al, 0Ah			; Move to start of line if we get a newline char
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h				; Display it
	dec bx				; Count down file size
	cmp bx, 0			; End of file?
	jne .loop

	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd



; ------------------------------------------------------------------

exit:
	ret


; ------------------------------------------------------------------

	input			times 255 db 0
	dirlist			times 255 db 0
	tmp_string		times 15 db 0
	file_size		dw 0

	bin_extension		db 'BIN', 0
	bas_extension		db 'BAS', 0

	prompt			db '> ', 0
	help_text		db 'Inbuilt commands: DIR, CAT, CLS, HELP, TIME, DATE, VER, EXIT', 13, 10, 0
	invalid_msg		db 'No such command or program', 13, 10, 0
	nofilename_msg		db 'No filename specified', 13, 10, 0
	notfound_msg		db 'File not found', 13, 10, 0
	version_msg		db 'MikeOS ', MIKEOS_VER, 13, 10, 0

	exit_string		db 'EXIT', 0
	help_string		db 'HELP', 0
	cls_string		db 'CLS', 0
	dir_string		db 'DIR', 0
	time_string		db 'TIME', 0
	date_string		db 'DATE', 0
	ver_string		db 'VER', 0
	cat_string		db 'CAT', 0

	kern_file_string	db 'KERNEL.BIN', 0
	kern_warn_msg		db 'Cannot execute kernel file!', 13, 10, 0


; ==================================================================

