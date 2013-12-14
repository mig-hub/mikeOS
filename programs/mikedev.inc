; ------------------------------------------------------------------
; Include file for MikeOS program development (API version 16)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; IMPORTANT LOCATIONS

os_main			equ	0000h	; Where the OS code starts


; ------------------------------------------------------------------
; COLOURS (eg for os_draw_background and os_draw_block)

%DEFINE BLACK_ON_WHITE		11110000b
%DEFINE WHITE_ON_BLACK		00001111b
%DEFINE WHITE_ON_LIGHT_RED	11001111b
%DEFINE WHITE_ON_GREEN		00101111b
%DEFINE RED_ON_LIGHT_GREEN	10100100b


; ------------------------------------------------------------------
; KEYS

%DEFINE KEY_UP		72
%DEFINE KEY_DOWN	80
%DEFINE KEY_LEFT	75
%DEFINE KEY_RIGHT	77

%DEFINE KEY_ESC		27
%DEFINE KEY_ENTER	13


; ------------------------------------------------------------------
; SYSTEM CALLS

; Screen control

os_clear_screen		equ	0009h	; (Nothing used)
os_print_string		equ	0003h	; SI = zero-terminated string location
os_move_cursor		equ	0006h	; DH, DL = row, column
os_print_horiz_line	equ	000Ch	; AX = 1 for double line, else single
os_print_newline	equ	000Fh	; (Nothing used)
os_draw_background	equ	002Ah	; AX, BX = strings, CX = colour
os_draw_block		equ	00B4h	; BL = colour, DH/DL/SI/DI = pos
os_input_dialog		equ	00A8h	; AX = input string, BX = msg string
os_dialog_box		equ	003Ch	; AX, BX, CX = strings, DX = type
					; OUT: AX = 0 for OK, 1 for cancel
					; (only multi choice for DX = 1)
os_list_dialog		equ	00ABh	; IN: AX = comma-separated list of
					; option strings, BX, CX = help to
					; display at top of list
					; OUT: AX = number (starting from 1)
					; of option selected, or carry if Esc
os_file_selector	equ	005Ah	; Returns filename in AX
os_get_cursor_pos	equ	0069h	; OUT: DH = row, DL = column
os_print_space		equ	006Ch	; (Nothing used)
os_dump_string		equ	006Fh	; SI = string location
os_print_digit		equ	0072h	; AX = digit to print
os_print_1hex		equ	0075h	; Display low nibble of AL in hex
os_print_2hex		equ	0078h	; Display AL in hex
os_print_4hex		equ	007Bh	; Display AX in hex
os_show_cursor		equ	008Ah	; (Nothing used)
os_hide_cursor		equ	008Dh	; (Nothing used)
os_dump_registers	equ	0090h	; Shows contents of AX, BX, CX, DX


; Keyboard handling

os_wait_for_key		equ	0012h	; Returns AL = key pressed
os_check_for_key	equ	0015h	; Returns AL = key pressed


; File handling

os_get_file_list	equ	0042h	; AX = string to store filenames
os_load_file		equ	0021h	; IN: AX = filename string location,
					; CX = location to load file
					; OUT: BX = file size in bytes,
					; carry clear if OK, set if missing
os_write_file		equ	0096h	; AX = filename, BX = data location,
					; CX = number of bytes to save
os_file_exists		equ	0099h	; AX = filename, carry clear if exists
os_create_file		equ	009Ch	; AX = filename
os_remove_file		equ	009Fh	; AX = filename
os_rename_file		equ	00A2h	; AX = filename, BX = new filename
os_get_file_size	equ	00A5h	; AX = filename, OUT: BX = bytes
					; (64K max)


; Sound

os_speaker_tone		equ	001Bh	; AX = note frequency
os_speaker_off		equ	001Eh	; (Nothing used)


; String handling

os_int_to_string	equ	0018h	; AX = unsigned integer, out AX = string
os_sint_to_string	equ	00C0h	; AX = signed integer, out AX = string
os_string_reverse	equ	00AEh	; SI = string location
os_string_length	equ	002Dh	; AX = string loc, returns AX = length
os_string_uppercase	equ	0030h	; AX = zero-terminated string
os_string_lowercase	equ	0033h	; AX = zero-terminated string
os_input_string		equ	0036h	; AX = string location
os_string_copy		equ	0039h	; SI = source, DI = dest strings
os_string_join		equ	003Fh	; AX, BX = source strings, CX = dest
os_string_compare	equ	0045h	; SI, DI = strings, carry set if same
os_string_strincmp	equ	0093h	; As above, but with CL = chars to check
os_string_chomp		equ	0048h	; AX = string location
os_string_strip		equ	004Bh	; SI = string, AX = char to remove
os_string_truncate	equ	004Eh	; SI = string, AX = number of chars
os_set_time_fmt		equ	0084h	; AL = format
os_set_date_fmt		equ	0087h	; AX = format
os_get_time_string	equ	0054h	; BX = string location for eg '20:41'
os_get_date_string	equ	005Dh	; BX = string loc for eg '12/31/2007'
os_find_char_in_string	equ	0066h	; IN: SI = string, AL = char to find
os_long_int_to_string	equ	007Eh	; DX:AX = num, BX = base, DI = string
os_string_to_int	equ	00B1h	; SI = string (up to 65535), AX = int
os_string_charchange	equ	00BAh	; SI = string, AL = old char, BL = new
os_string_parse		equ	00C3h	; SI = string; output: AX/BX/CX/DX =
					; substrings (or 0 if not present)
os_string_tokenize	equ	00CFh	; SI = string, AL = sep char; returns
					; DI = next token


; Math routines

os_get_random		equ	00B7h	; IN: AX, BX = low, high; OUT: CX = num
os_bcd_to_int		equ	0051h	; AL = BCD number, returns AX = integer
os_long_int_negate	equ	0081h	; DX:AX = number


; Ports

os_port_byte_out	equ	00C9h	; IN: DX = port, AL = byte
os_port_byte_in		equ	00CCh	; IN: DX = port; OUT: AL = byte
os_serial_port_enable	equ	00BDh	; AX = 0 for 9600 baud, 1 for 1200
os_send_via_serial	equ	0060h	; AL = byte to send
os_get_via_serial	equ	0063h	; Returns AL = byte received
					; OUT: AX = location, or 0 if not found


; Misc OS functions

os_run_basic		equ	00C6h	; AX = code location in RAM, BX = size,
					; SI = parameter string (or 0 if none)
os_get_api_version	equ	0057h	; Returns API version in AL
os_pause		equ	0024h	; AX = 10ths of second to wait
os_fatal_error		equ	0027h	; AX = error string location


; ------------------------------------------------------------------

