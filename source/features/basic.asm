; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2010 MikeOS Developers -- see doc/LICENSE.TXT
;
; BASIC CODE INTERPRETER
; ==================================================================

; ------------------------------------------------------------------
; Token types

%DEFINE VARIABLE 1
%DEFINE STRING_VAR 2
%DEFINE NUMBER 3
%DEFINE STRING 4
%DEFINE QUOTE 5
%DEFINE CHAR 6
%DEFINE UNKNOWN 7
%DEFINE LABEL 8


; ------------------------------------------------------------------
; The BASIC intepreter execution starts here...

os_run_basic:
	mov word [orig_stack], sp		; Save stack pointer -- we might jump to the
						; error printing code and quit in the middle
						; some nested loops, and we want to preserve
						; the stack

	mov word [load_point], ax		; AX was passed as starting location of code

	mov word [prog], ax			; prog = pointer to current execution point in code

	add bx, ax				; We were passed the .BAS byte size in BX
	dec bx
	dec bx
	mov word [prog_end], bx			; Make note of program end point


	call clear_ram				; Clear variables etc. from previous run
						; of a BASIC program



mainloop:
	call get_token				; Get a token from the start of the line

	cmp ax, STRING				; Is the type a string of characters?
	je .keyword				; If so, let's see if it's a keyword to process

	cmp ax, VARIABLE			; If it's a variable at the start of the line,
	je near assign				; this is an assign (eg "X = Y + 5")

	cmp ax, STRING_VAR			; Same for a string variable (eg $1)
	je near assign

	cmp ax, LABEL				; Don't need to do anything here - skip
	je mainloop

	mov si, err_syntax			; Otherwise show an error and quit
	jmp error


.keyword:
	mov si, token				; Start trying to match commands

	mov di, alert_cmd
	call os_string_compare
	jc near do_alert

	mov di, call_cmd
	call os_string_compare
	jc near do_call

	mov di, cls_cmd
	call os_string_compare
	jc near do_cls

	mov di, cursor_cmd
	call os_string_compare
	jc near do_cursor

	mov di, curschar_cmd
	call os_string_compare
	jc near do_curschar

	mov di, end_cmd
	call os_string_compare
	jc near do_end

	mov di, for_cmd
	call os_string_compare
	jc near do_for

	mov di, getkey_cmd
	call os_string_compare
	jc near do_getkey

	mov di, gosub_cmd
	call os_string_compare
	jc near do_gosub

	mov di, goto_cmd
	call os_string_compare
	jc near do_goto

	mov di, input_cmd
	call os_string_compare
	jc near do_input

	mov di, if_cmd
	call os_string_compare
	jc near do_if

	mov di, load_cmd
	call os_string_compare
	jc near do_load

	mov di, move_cmd
	call os_string_compare
	jc near do_move

	mov di, next_cmd
	call os_string_compare
	jc near do_next

	mov di, pause_cmd
	call os_string_compare
	jc near do_pause

	mov di, peek_cmd
	call os_string_compare
	jc near do_peek

	mov di, poke_cmd
	call os_string_compare
	jc near do_poke

	mov di, port_cmd
	call os_string_compare
	jc near do_port

	mov di, print_cmd
	call os_string_compare
	jc near do_print

	mov di, rand_cmd
	call os_string_compare
	jc near do_rand

	mov di, rem_cmd
	call os_string_compare
	jc near do_rem

	mov di, return_cmd
	call os_string_compare
	jc near do_return

	mov di, save_cmd
	call os_string_compare
	jc near do_save

	mov di, serial_cmd
	call os_string_compare
	jc near do_serial

	mov di, sound_cmd
	call os_string_compare
	jc near do_sound

	mov di, waitkey_cmd
	call os_string_compare
	jc near do_waitkey

	mov si, err_cmd_unknown			; Command not found?
	jmp error


; ------------------------------------------------------------------
; CLEAR RAM

clear_ram:
	mov al, 0

	mov di, variables
	mov cx, 52
	rep stosb

	mov di, for_variables
	mov cx, 52
	rep stosb

	mov di, for_code_points
	mov cx, 52
	rep stosb

	mov byte [gosub_depth], 0

	mov di, gosub_points
	mov cx, 20
	rep stosb

	mov di, string_vars
	mov cx, 1024
	rep stosb

	ret


; ------------------------------------------------------------------
; ASSIGNMENT

assign:
	cmp ax, VARIABLE			; Are we starting with a number var?
	je .do_num_var

	mov di, string_vars			; Otherwise it's a string var
	mov ax, 128
	mul bx					; (BX = string number, passed back from get_token)
	add di, ax

	push di

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp ax, QUOTE
	je .second_is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars			; Otherwise it's a string var
	mov ax, 128
	mul bx					; (BX = string number, passed back from get_token)
	add si, ax

	pop di
	call os_string_copy

	jmp mainloop


.second_is_quote:
	mov si, token
	pop di
	call os_string_copy

	jmp mainloop


.do_num_var:
	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_variable

	cmp ax, STRING
	je near .second_is_string

	cmp ax, UNKNOWN
	jne near .error

	mov byte al, [token]			; Address of string var?
	cmp al, '&'
	jne near .error

	call get_token				; Let's see if there's a string var
	cmp ax, STRING_VAR
	jne near .error

	mov di, string_vars
	mov ax, 128
	mul bx
	add di, ax

	mov bx, di

	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.second_is_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax				; Number to insert in variable table

	mov ax, 0
	mov byte al, [.tmp]

	call set_var


	; The assignment could be simply "X = 5" etc. Or it could be
	; "X = Y + 5" -- ie more complicated. So here we check to see if
	; there's a delimiter...

.check_for_more:
	mov word ax, [prog]			; Save code location in case there's no delimiter
	mov word [.tmp_loc], ax

	call get_token				; Any more to deal with in this assignment?
	mov byte al, [token]
	cmp al, '+'
	je .theres_more
	cmp al, '-'
	je .theres_more
	cmp al, '*'
	je .theres_more
	cmp al, '/'
	je .theres_more
	cmp al, '%'
	je .theres_more

	mov word ax, [.tmp_loc]			; Not a delimiter, so step back before the token
	mov word [prog], ax			; that we just grabbed

	jmp mainloop				; And go back to the code interpreter!


.theres_more:
	mov byte [.delim], al

	call get_token
	cmp ax, VARIABLE
	je .handle_variable

	mov si, token
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var				; This also points SI at right place in variable table

	cmp byte [.delim], '+'
	jne .not_plus

	add ax, bx
	jmp .finish

.not_plus:
	cmp byte [.delim], '-'
	jne .not_minus

	sub ax, bx
	jmp .finish

.not_minus:
	cmp byte [.delim], '*'
	jne .not_times

	mul bx
	jmp .finish

.not_times:
	cmp byte [.delim], '/'
	jne .not_divide

	mov dx, 0
	div bx
	jmp .finish

.not_divide:
	mov dx, 0
	div bx
	mov ax, dx				; Get remainder

.finish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.handle_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var

	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var

	cmp byte [.delim], '+'
	jne .vnot_plus

	add ax, bx
	jmp .vfinish

.vnot_plus:
	cmp byte [.delim], '-'
	jne .vnot_minus

	sub ax, bx
	jmp .vfinish

.vnot_minus:
	cmp byte [.delim], '*'
	jne .vnot_times

	mul bx
	jmp .vfinish

.vnot_times:
	cmp byte [.delim], '/'
	jne .vnot_divide

	mov dx, 0
	div bx
	jmp .finish

.vnot_divide:
	mov dx, 0
	div bx
	mov ax, dx				; Get remainder

.vfinish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_string:
	mov di, token
	mov si, progstart_keyword
	call os_string_compare
	je .is_progstart

	mov si, ramstart_keyword
	call os_string_compare
	je .is_ramstart

	jmp .error

.is_progstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [load_point]
	call set_var

	jmp mainloop



.is_ramstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [prog_end]
	inc bx
	inc bx
	inc bx
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.tmp		db 0
	.tmp_loc	dw 0
	.delim		db 0


; ==================================================================
; SPECIFIC COMMAND CODE STARTS HERE

; ------------------------------------------------------------------
; ALERT

do_alert:
	call get_token

	cmp ax, QUOTE
	je .is_quote

	mov si, err_syntax
	jmp error

.is_quote:
	mov ax, token				; First string for alert box
	mov bx, 0				; Others are blank
	mov cx, 0
	mov dx, 0				; One-choice box
	call os_dialog_box
	jmp mainloop


; ------------------------------------------------------------------
; CALL

do_call:
	call get_token
	cmp ax, NUMBER
	je .is_number

	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .execute_call

.is_number:
	mov si, token
	call os_string_to_int

.execute_call:
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov di, 0
	mov si, 0

	call ax

	jmp mainloop



; ------------------------------------------------------------------
; CLS

do_cls:
	call os_clear_screen
	jmp mainloop


; ------------------------------------------------------------------
; CURSOR

do_cursor:
	call get_token

	mov si, token
	mov di, .on_str
	call os_string_compare
	jc .turn_on

	mov si, token
	mov di, .off_str
	call os_string_compare
	jc .turn_off

	mov si, err_syntax
	jmp error

.turn_on:
	call os_show_cursor
	jmp mainloop

.turn_off:
	call os_hide_cursor
	jmp mainloop


	.on_str db "ON", 0
	.off_str db "OFF", 0


; ------------------------------------------------------------------
; CURSCHAR

do_curschar:
	call get_token

	cmp ax, VARIABLE
	je .is_ok

	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, 0
	mov byte al, [token]

	push ax				; Store variable we're going to use

	mov ah, 08h
	mov bx, 0
	int 10h				; Get char at current cursor location

	mov bx, 0			; We only want the lower byte (the char, not attribute)
	mov bl, al

	pop ax				; Get the variable back

	call set_var			; And store the value

	jmp mainloop


; ------------------------------------------------------------------
; END

do_end:
	mov word sp, [orig_stack]
	ret


; ------------------------------------------------------------------
; FOR

do_for:
	call get_token				; Get the variable we're using in this loop

	cmp ax, VARIABLE
	jne near .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al			; Store it in a temporary location for now

	call get_token

	mov ax, 0				; Check it's followed up with '='
	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token				; Next we want a number

	cmp ax, NUMBER
	jne .error

	mov si, token				; Convert it
	call os_string_to_int


	; At this stage, we've read something like "FOR X = 1"
	; so let's store that 1 in the variable table

	mov bx, ax
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var


	call get_token				; Next we're looking for "TO"

	cmp ax, STRING
	jne .error

	mov ax, token
	call os_string_uppercase

	mov si, token
	mov di, .to_string
	call os_string_compare
	jnc .error


	; So now we're at "FOR X = 1 TO"

	call get_token

	cmp ax, NUMBER
	jne .error

	mov si, token					; Get target number
	call os_string_to_int

	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					; Store target number in table
	mov di, for_variables
	add di, ax
	add di, ax
	mov ax, bx
	stosw


	; So we've got the variable, assigned it the starting number, and put into
	; our table the limit it should reach. But we also need to store the point in
	; code after the FOR line we should return to if NEXT X doesn't complete the loop...

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					; Store code position to return to in table
	mov di, for_code_points
	add di, ax
	add di, ax
	mov word ax, [prog]
	stosw

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.tmp_var	db 0
	.to_string	db 'TO', 0


; ------------------------------------------------------------------
; GETKEY

do_getkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_check_for_key

	mov bx, 0
	mov bl, al

	pop ax

	call set_var

	jmp mainloop


; ------------------------------------------------------------------
; GOSUB

do_gosub:
	call get_token				; Get the number (label)

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Back up this label
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Add ':' char to end for searching
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	


	inc byte [gosub_depth]

	mov ax, 0
	mov byte al, [gosub_depth]		; Get current GOSUB nest level

	cmp al, 9
	jle .within_limit

	mov si, err_nest_limit
	jmp error


.within_limit:
	mov di, gosub_points			; Move into our table of pointers
	add di, ax				; Table is words (not bytes)
	add di, ax
	mov word ax, [prog]
	stosw					; Store current location before jump


	mov word ax, [load_point]
	mov word [prog], ax			; Return to start of program to find label

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop


.line_loop:					; Go to end of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop


.past_end:
	mov si, err_label_notfound
	jmp error


	.tmp_token	times 30 db 0


; ------------------------------------------------------------------
; GOTO

do_goto:
	call get_token				; Get the next token

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Back up this label
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Add ':' char to end for searching
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	mov word ax, [load_point]
	mov word [prog], ax			; Return to start of program to find label

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop

.line_loop:					; Go to end of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]

	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error


	.tmp_token times	30 db 0


; ------------------------------------------------------------------
; IF

do_if:
	call get_token

	cmp ax, VARIABLE			; If can only be followed by a variable
	je .num_var

	cmp ax, STRING_VAR
	je near .string_var

	mov si, err_syntax
	jmp error

.num_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov dx, ax				; Store value of first part of comparison

	call get_token				; Get the delimiter
	mov byte al, [token]
	cmp al, '='
	je .equals
	cmp al, '>'
	je .greater
	cmp al, '<'
	je .less

	mov si, err_syntax			; If not one of the above, error out
	jmp error

.equals:
	call get_token				; Is this 'X = Y' (equals another variable?)

	cmp ax, CHAR
	je .equals_char

	mov byte al, [token]
	call is_letter
	jc .equals_var

	mov si, token				; Otherwise it's, eg 'X = 1' (a number)
	call os_string_to_int

	cmp ax, dx				; On to the THEN bit if 'X = num' matches
	je near .on_to_then

	jmp .finish_line			; Otherwise skip the rest of the line


.equals_char:
	mov ax, 0
	mov byte al, [token]

	cmp ax, dx
	je near .on_to_then

	jmp .finish_line


.equals_var:
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx				; Do the variables match?
	je near .on_to_then				; On to the THEN bit if so

	jmp .finish_line			; Otherwise skip the rest of the line


.greater:
	call get_token				; Greater than a variable or number?
	mov byte al, [token]
	call is_letter
	jc .greater_var

	mov si, token				; Must be a number here...
	call os_string_to_int

	cmp ax, dx
	jl near .on_to_then

	jmp .finish_line

.greater_var:					; Variable in this case
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx				; Make the comparison!
	jl .on_to_then

	jmp .finish_line

.less:
	call get_token
	mov byte al, [token]
	call is_letter
	jc .less_var

	mov si, token
	call os_string_to_int

	cmp ax, dx
	jg .on_to_then

	jmp .finish_line

.less_var:
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx
	jg .on_to_then

	jmp .finish_line



.string_var:
	mov byte [.tmp_string_var], bl

	call get_token

	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token
	cmp ax, STRING_VAR
	je .second_is_string_var

	cmp ax, QUOTE
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov di, token
	call os_string_compare
	je .on_to_then

	jmp .finish_line


.second_is_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov di, string_vars
	mov bx, 0
	mov byte bl, [.tmp_string_var]
	mov ax, 128
	mul bx
	add di, ax

	call os_string_compare
	jc .on_to_then

	jmp .finish_line


.on_to_then:
	call get_token

	mov si, token
	mov di, then_keyword
	call os_string_compare

	jc .then_present

	mov si, err_syntax
	jmp error

.then_present:				; Continue rest of line like any other command!
	jmp mainloop


.finish_line:				; IF wasn't fulfilled, so skip rest of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10
	jne .finish_line

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.tmp_string_var		db 0


; ------------------------------------------------------------------
; INPUT

do_input:
	mov al, 0				; Clear string from previous usage
	mov di, .tmpstring
	mov cx, 128
	rep stosb

	call get_token

	cmp ax, VARIABLE			; We can only INPUT to variables!
	je .number_var

	cmp ax, STRING_VAR
	je .string_var

	mov si, err_syntax
	jmp error

.number_var:
	mov ax, .tmpstring			; Get input from the user
	call os_input_string

	mov ax, .tmpstring
	call os_string_length
	cmp ax, 0
	jne .char_entered

	mov byte [.tmpstring], '0'		; If enter hit, fill variable with zero
	mov byte [.tmpstring + 1], 0

.char_entered:
	mov si, .tmpstring			; Convert to integer format
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]			; Get the variable where we're storing it...
	call set_var				; ...and store it!

	call os_print_newline

	jmp mainloop


.string_var:
	push bx

	mov ax, .tmpstring
	call os_input_string

	mov si, .tmpstring
	mov di, string_vars

	pop bx

	mov ax, 128
	mul bx

	add di, ax
	call os_string_copy

	call os_print_newline

	jmp mainloop


	.tmpstring	times 128 db 0


; ------------------------------------------------------------------
; LOAD

do_load:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov ax, si
	call os_file_exists
	jc .file_not_exists

	mov dx, ax			; Store for now

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.load_part:
	mov cx, ax

	mov ax, dx

	call os_load_file

	mov ax, 0
	mov byte al, 'S'
	call set_var

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop


.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .load_part


.file_not_exists:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	call get_token				; Skip past the loading point -- unnecessary now

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; MOVE

do_move:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov dl, al
	jmp .onto_second

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dl, al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	mov dh, al
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dh, al

.finish:
	call os_move_cursor

	jmp mainloop


; ------------------------------------------------------------------
; NEXT

do_next:
	call get_token

	cmp ax, VARIABLE			; NEXT must be followed by a variable
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	inc ax					; NEXT increments the variable, of course!

	mov bx, ax

	mov ax, 0
	mov byte al, [token]

	sub al, 65
	mov si, for_variables
	add si, ax
	add si, ax
	lodsw					; Get the target number from the table

	inc ax					; (Make the loop inclusive of target number)
	cmp ax, bx				; Do the variable and target match?
	je .loop_finished

	mov ax, 0				; If not, store the updated variable
	mov byte al, [token]
	call set_var

	mov ax, 0				; Find the code point and go back
	mov byte al, [token]
	sub al, 65
	mov si, for_code_points
	add si, ax
	add si, ax
	lodsw

	mov word [prog], ax
	jmp mainloop


.loop_finished:
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; PAUSE

do_pause:
	call get_token

	cmp ax, VARIABLE
	je .is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	jmp mainloop


; ------------------------------------------------------------------
; PEEK

do_peek:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al

	call get_token

	cmp ax, VARIABLE
	je .dereference

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.store:
	mov si, ax
	mov bx, 0
	mov byte bl, [si]
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var

	jmp mainloop

.dereference:
	mov byte al, [token]
	call get_var
	jmp .store

.error:
	mov si, err_syntax
	jmp error


	.tmp_var	db 0


; ------------------------------------------------------------------
; POKE

do_poke:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

	cmp ax, 255
	jg .error

	mov byte [.first_value], al
	jmp .onto_second


.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov byte [.first_value], al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.got_value:
	mov di, ax
	mov ax, 0
	mov byte al, [.first_value]
	mov byte [di], al

	jmp mainloop

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .got_value

.error:
	mov si, err_syntax
	jmp error


	.first_value	db 0


; ------------------------------------------------------------------
; PORT

do_port:
	call get_token
	mov si, token

	mov di, .out_cmd
	call os_string_compare
	jc .do_out_cmd

	mov di, .in_cmd
	call os_string_compare
	jc .do_in_cmd

	jmp .error


.do_out_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int		; Now AX = port number
	mov dx, ax

	call get_token
	cmp ax, NUMBER
	je .out_is_num

	cmp ax, VARIABLE
	je .out_is_var

	jmp .error

.out_is_num:
	mov si, token
	call os_string_to_int
	call os_port_byte_out
	jmp mainloop

.out_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_port_byte_out
	jmp mainloop


.do_in_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov dx, ax

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte cl, [token]

	call os_port_byte_in
	mov bx, 0
	mov bl, al

	mov al, cl
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.out_cmd	db "OUT", 0
	.in_cmd		db "IN", 0


; ------------------------------------------------------------------
; PRINT

do_print:
	call get_token				; Get part after PRINT

	cmp ax, QUOTE				; What type is it?
	je .print_quote

	cmp ax, VARIABLE			; Numerical variable (eg X)
	je .print_var

	cmp ax, STRING_VAR			; String variable (eg $1)
	je .print_string_var

	cmp ax, STRING				; Special keyword (eg CHR or HEX)
	je .print_keyword

	mov si, err_print_type			; We only print quoted strings and vars!
	jmp error


.print_var:
	mov ax, 0
	mov byte al, [token]
	call get_var				; Get its value

	call os_int_to_string			; Convert to string
	mov si, ax
	call os_print_string

	jmp .newline_or_not


.print_quote:					; If it's quoted text, print it
	mov si, token
	call os_print_string

	jmp .newline_or_not


.print_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	call os_print_string

	jmp .newline_or_not


.print_keyword:
	mov si, token
	mov di, chr_keyword
	call os_string_compare
	jc .is_chr

	mov di, hex_keyword
	call os_string_compare
	jc .is_hex

	mov si, err_syntax
	jmp error

.is_chr:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	mov ah, 0Eh
	int 10h

	jmp .newline_or_not


.is_hex:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_print_2hex

	jmp .newline_or_not

.error:
	mov si, err_syntax
	jmp error



.newline_or_not:
	; We want to see if the command ends with ';' -- which means that
	; we shouldn't print a newline after it finishes. So we store the
	; current program location to pop ahead and see if there's the ';'
	; character -- otherwise we put the program location back and resume
	; the main loop

	mov word ax, [prog]
	mov word [.tmp_loc], ax

	call get_token
	cmp ax, UNKNOWN
	jne .ignore

	mov ax, 0
	mov al, [token]
	cmp al, ';'
	jne .ignore

	jmp mainloop				; And go back to interpreting the code!

.ignore:
	call os_print_newline

	mov word ax, [.tmp_loc]
	mov word [prog], ax

	jmp mainloop


	.tmp_loc	dw 0


; ------------------------------------------------------------------
; RAND

do_rand:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num1], ax

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num2], ax

	mov word ax, [.num1]
	mov word bx, [.num2]
	call os_get_random

	mov bx, cx
	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


	.tmp	db 0
	.num1	dw 0
	.num2	dw 0


.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; REM

do_rem:
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10			; Find end of line after REM
	jne do_rem

	jmp mainloop


; ------------------------------------------------------------------
; RETURN

do_return:
	mov ax, 0
	mov byte al, [gosub_depth]
	cmp al, 0
	jne .is_ok

	mov si, err_return
	jmp error

.is_ok:
	mov si, gosub_points
	add si, ax				; Table is words (not bytes)
	add si, ax
	lodsw
	mov word [prog], ax
	dec byte [gosub_depth]

	jmp mainloop	


; ------------------------------------------------------------------
; SAVE

do_save:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov di, .tmp_filename
	call os_string_copy

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.set_data_loc:
	mov word [.data_loc], ax

	call get_token

	cmp ax, VARIABLE
	je .third_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.set_data_size:
	mov word [.data_size], ax


	mov word ax, .tmp_filename
	mov word bx, [.data_loc]
	mov word cx, [.data_size]

	call os_write_file
	jc .save_failure

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop


.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .set_data_loc


.third_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .set_data_size


.save_failure:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


	.filename_loc	dw 0
	.data_loc	dw 0
	.data_size	dw 0

	.tmp_filename	times 15 db 0


; ------------------------------------------------------------------
; SERIAL

do_serial:
	call get_token
	mov si, token

	mov di, .on_cmd
	call os_string_compare
	jc .do_on_cmd

	mov di, .send_cmd
	call os_string_compare
	jc .do_send_cmd

	mov di, .rec_cmd
	call os_string_compare
	jc .do_rec_cmd

	jmp .error

.do_on_cmd:
	call get_token
	cmp ax, NUMBER
	je .do_on_cmd_ok
	jmp .error

.do_on_cmd_ok:
	mov si, token
	call os_string_to_int
	cmp ax, 1200
	je .on_cmd_slow_mode
	cmp ax, 9600
	je .on_cmd_fast_mode

	jmp .error

.on_cmd_fast_mode:
	mov ax, 0
	call os_serial_port_enable
	jmp mainloop

.on_cmd_slow_mode:
	mov ax, 1
	call os_serial_port_enable
	jmp mainloop


.do_send_cmd:
	call get_token
	cmp ax, NUMBER
	je .send_number

	cmp ax, VARIABLE
	je .send_variable

	jmp .error

.send_number:
	mov si, token
	call os_string_to_int
	call os_send_via_serial
	jmp mainloop

.send_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	call os_send_via_serial
	jmp mainloop


.do_rec_cmd:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]

	mov cx, 0
	mov cl, al
	call os_get_via_serial

	mov bx, 0
	mov bl, al
	mov al, cl
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.on_cmd		db "ON", 0
	.send_cmd	db "SEND", 0
	.rec_cmd	db "REC", 0


; ------------------------------------------------------------------
; SOUND

do_sound:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	jmp .done_first

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.done_first:
	call os_speaker_tone

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	call os_speaker_off

	jmp mainloop


; ------------------------------------------------------------------
; WAITKEY

do_waitkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_wait_for_key

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed

.store:
	mov bx, 0
	mov bl, al

	pop ax

	call set_var

	jmp mainloop


.up_pressed:
	mov ax, 1
	jmp .store

.down_pressed:
	mov ax, 2
	jmp .store

.left_pressed:
	mov ax, 3
	jmp .store

.right_pressed:
	mov ax, 4
	jmp .store


; ==================================================================
; INTERNAL ROUTINES FOR INTERPRETER

; ------------------------------------------------------------------
; Get value of variable character specified in AL (eg 'A')

get_var:
	sub al, 65
	mov si, variables
	add si, ax
	add si, ax
	lodsw
	ret


; ------------------------------------------------------------------
; Set value of variable character specified in AL (eg 'A')
; with number specified in BX

set_var:
	mov ah, 0
	sub al, 65				; Remove ASCII codes before 'A'

	mov di, variables			; Find position in table (of words)
	add di, ax
	add di, ax
	mov ax, bx
	stosw
	ret


; ------------------------------------------------------------------
; Get token from current position in prog

get_token:
	mov word si, [prog]
	lodsb

	cmp al, 10
	je .newline

	cmp al, ' '
	je .newline

	call is_number
	jc get_number_token

	cmp al, '"'
	je get_quote_token

	cmp al, 39			; Quote mark (')
	je get_char_token

	cmp al, '$'
	je near get_string_var_token

	jmp get_string_token


.newline:
	inc word [prog]
	jmp get_token



get_number_token:
	mov word si, [prog]
	mov di, token

.loop:
	lodsb
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	call is_number
	jc .fine

	mov si, err_char_in_num
	jmp error

.fine:
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			; Zero-terminate the token
	stosb

	mov ax, NUMBER			; Pass back the token type
	ret


get_char_token:
	inc word [prog]			; Move past first quote (')

	mov word si, [prog]
	lodsb

	mov byte [token], al

	lodsb
	cmp al, 39			; Needs to finish with another quote
	je .is_ok

	mov si, err_quote_term
	jmp error

.is_ok:
	inc word [prog]
	inc word [prog]

	mov ax, CHAR
	ret


get_quote_token:
	inc word [prog]			; Move past first quote (") char
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, '"'
	je .done
	cmp al, 10
	je .error
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			; Zero-terminate the token
	stosb
	inc word [prog]			; Move past final quote

	mov ax, QUOTE			; Pass back token type
	ret

.error:
	mov si, err_quote_term
	jmp error


get_string_var_token:
	lodsb
	mov bx, 0			; If it's a string var, pass number of string in BX
	mov bl, al
	sub bl, 49

	inc word [prog]
	inc word [prog]

	mov ax, STRING_VAR
	ret
	

get_string_token:
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	stosb
	inc word [prog]
	jmp .loop
.done:
	mov al, 0			; Zero-terminate the token
	stosb

	mov ax, token
	call os_string_uppercase

	mov ax, token
	call os_string_length		; How long was the token?
	cmp ax, 1			; If 1 char, it's a variable or delimiter
	je .is_not_string

	mov si, token			; If the token ends with ':', it's a label
	add si, ax
	dec si
	lodsb
	cmp al, ':'
	je .is_label

	mov ax, STRING			; Otherwise it's a general string of characters
	ret

.is_label:
	mov ax, LABEL
	ret


.is_not_string:
	mov byte al, [token]
	call is_letter
	jc .is_var

	mov ax, UNKNOWN
	ret

.is_var:
	mov ax, VARIABLE		; Otherwise probably a variable
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII number

is_number:
	cmp al, 48
	jl .not_number
	cmp al, 57
	jg .not_number
	stc
	ret
.not_number:
	clc
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII letter

is_letter:
	cmp al, 65
	jl .not_letter
	cmp al, 90
	jg .not_letter
	stc
	ret

.not_letter:
	clc
	ret


; ------------------------------------------------------------------
; Print error message and quit out

error:
	call os_print_newline
	call os_print_string		; Print error message
	call os_print_newline

	mov word sp, [orig_stack]	; Restore the stack to as it was when BASIC started

	ret				; And finish


	; Error messages text...

	err_char_in_num		db "Error: unexpected character in number", 0
	err_quote_term		db "Error: quoted string or character not terminated correctly", 0
	err_print_type		db "Error: PRINT command not followed by quoted text or variable", 0
	err_cmd_unknown		db "Error: unknown command", 0
	err_goto_notlabel	db "Error: GOTO or GOSUB not followed by label", 0
	err_label_notfound	db "Error: GOTO or GOSUB label not found", 0
	err_return		db "Error: RETURN without GOSUB", 0
	err_nest_limit		db "Error: FOR or GOSUB nest limit exceeded", 0
	err_next		db "Error: NEXT without FOR", 0
	err_syntax		db "Error: syntax error", 0



; ==================================================================
; DATA SECTION

	orig_stack		dw 0		; Original stack location when BASIC started

	prog			dw 0		; Pointer to current location in BASIC code
	prog_end		dw 0		; Pointer to final byte of BASIC code

	load_point		dw 0

	token_type		db 0		; Type of last token read (eg NUMBER, VARIABLE)
	token			times 255 db 0	; Storage space for the token

	variables		times 26 dw 0	; Storage space for variables A to Z
	for_variables		times 26 dw 0	; Storage for FOR loops
	for_code_points		times 26 dw 0	; Storage for code positions where FOR loops start

	alert_cmd		db "ALERT", 0
	call_cmd		db "CALL", 0
	cls_cmd			db "CLS", 0
	cursor_cmd		db "CURSOR", 0
	curschar_cmd		db "CURSCHAR", 0
	end_cmd			db "END", 0
	for_cmd 		db "FOR", 0
	gosub_cmd		db "GOSUB", 0
	goto_cmd		db "GOTO", 0
	getkey_cmd		db "GETKEY", 0
	if_cmd 			db "IF", 0
	input_cmd 		db "INPUT", 0
	load_cmd		db "LOAD", 0
	move_cmd 		db "MOVE", 0
	next_cmd 		db "NEXT", 0
	pause_cmd 		db "PAUSE", 0
	peek_cmd		db "PEEK", 0
	poke_cmd		db "POKE", 0
	port_cmd		db "PORT", 0
	print_cmd 		db "PRINT", 0
	rem_cmd			db "REM", 0
	rand_cmd		db "RAND", 0
	return_cmd		db "RETURN", 0
	save_cmd		db "SAVE", 0
	serial_cmd		db "SERIAL", 0
	sound_cmd 		db "SOUND", 0
	waitkey_cmd		db "WAITKEY", 0

	then_keyword		db "THEN", 0
	chr_keyword		db "CHR", 0
	hex_keyword		db "HEX", 0

	progstart_keyword	db "PROGSTART", 0
	ramstart_keyword	db "RAMSTART", 0

	gosub_depth		db 0
	gosub_points		times 10 dw 0	; Points in code to RETURN to

	string_vars		times 1024 db 0	; 8 * 128 byte strings


; ------------------------------------------------------------------

