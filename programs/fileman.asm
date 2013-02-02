; ------------------------------------------------------------------
; Simple file manager for MikeOS: copy, delete and rename files
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768


	; This is the point used by the disk buffer in the MikeOS kernel
	; code; it's 24K after the kernel start, and therefore 8K before
	; the point where programs are loaded (32K):

	disk_buffer	equ	24576


start:
	call .draw_background

	mov ax, .command_list			; Draw list of disk operations
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog

	jc near .exit				; User pressed Esc?

	cmp ax, 1				; Otherwise respond to choice
	je near .delete_file

	cmp ax, 2
	je near .rename_file

	cmp ax, 3
	je near .copy_file

	cmp ax, 4
	je near .file_size

	cmp ax, 5
	je near .disk_info



.delete_file:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_delete_file_selected		; If Esc pressed, quit out

	push ax					; Save filename for now

	call .draw_background

	mov ax, .delete_confirm_msg		; Confirm delete operation
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 0
	je .ok_to_delete

	pop ax
	jmp .delete_file

.ok_to_delete:
	pop ax
	call os_remove_file
	jc near .writing_error



.no_delete_file_selected:
	jmp start



.rename_file:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_rename_file_selected		; If Esc pressed, quit out

	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

.retry_rename:
	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				; Store it for later
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, di				; Does the second filename already exist?
	call os_file_exists
	jnc .rename_fail			; Quit out if so

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_rename_file
	jc near .writing_error

	jmp start


.rename_fail:
	mov ax, .err_file_exists
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .retry_rename


.no_rename_file_selected:
	jmp start


.copy_file:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_copy_file_selected

	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	mov cx, 36864				; 4K after FILEMAN.BIN load position
	call os_load_file

	cmp bx, 28672				; Is file to copy bigger than 28K?
	jg .copy_file_too_big

	mov cx, bx				; Otherwise write out the copy
	mov bx, 36864
	mov ax, .filename_tmp2
	call os_write_file

	jc near .writing_error

	jmp start

.no_copy_file_selected:
	jmp start

.copy_file_too_big:				; If file bigger than 28K
	call .draw_background
	mov ax, .err_too_large_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start



.file_size:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_rename_file_selected		; If Esc pressed, quit out

	call os_get_file_size

	mov ax, bx				; Move size into AX for conversion
	call os_int_to_string
	mov bx, ax				; Size into second line of dialog box...

	mov ax, .size_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp start


.disk_info:
	mov cx, 1				; Load first disk sector into RAM
	mov dx, 0
	mov bx, disk_buffer

	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS load sector call

	mov si, disk_buffer + 2Bh		; Disk label starts here

	mov di, .tmp_string1
	mov cx, 11				; Copy 11 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov si, disk_buffer + 36h		; Filesystem string starts here

	mov di, .tmp_string2
	mov cx, 8				; Copy 8 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov ax, .label_string_text		; Add results to info strings
	mov bx, .tmp_string1
	mov cx, .label_string_full
	call os_string_join

	mov ax, .fstype_string_text
	mov bx, .tmp_string2
	mov cx, .fstype_string_full
	call os_string_join

	call .draw_background

	mov ax, .label_string_full		; Show the info
	mov bx, .fstype_string_full
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp start


.writing_error:
	call .draw_background
	mov ax, .error_msg
	mov bx, .error_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start


.exit:
	call os_clear_screen
	ret


.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 00100000b
	call os_draw_background
	ret


	.command_list		db 'Delete a file,Rename a file,Copy a file,Show file size,Show disk info', 0

	.help_msg1		db 'Select a file operation to perform,', 0
	.help_msg2		db 'or press the Esc key to exit...', 0

	.title_msg		db 'MikeOS File Manager', 0
	.footer_msg		db 'Copy, rename and delete files', 0

	.label_string_text	db 'Filesystem label: ', 0
	.label_string_full	times 30 db 0

	.fstype_string_text	db 'Filesystem type: ', 0
	.fstype_string_full	times 30 db 0

	.delete_confirm_msg	db 'Are you sure?', 0

	.filename_msg		db 'Enter filename with extension (eg FOO.BAR):', 0
	.filename_input		times 255 db 0
	.filename_tmp1		times 15 db 0
	.filename_tmp2		times 15 db 0

	.size_msg		db 'File size (in bytes):', 0

	.error_msg		db 'Error writing to the disk!', 0
	.error_msg2		db 'Read-only media, or file exists!', 0
	.err_too_large_msg	db 'File too large (max 24K)!', 0
	.err_file_exists	db 'File of that name exists!', 0

	.tmp_string1		times 15 db 0
	.tmp_string2		times 15 db 0


; ------------------------------------------------------------------

