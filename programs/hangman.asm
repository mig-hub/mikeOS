; ------------------------------------------------------------------
; Geography-based hangman game for MikeOS
;
; At the end of this file you'll see a list of 256 cities (in
; lower-case to make the game code simpler). We get one city at
; random from the list and store it in a string.
;
; Next, we create another string of the same size, but with underscore
; characters instead of the real ones. We display this 'work' string to
; the player, who tries to guess characters. If s/he gets a char right,
; it is revealed in the work string.
;
; If s/he gets gets a char wrong, we add it to a list of misses, and
; draw more of the hanging man. Poor bloke.
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "mikedev.inc"
	ORG 32768


start:
	call os_hide_cursor


	; First, reset values in case user is playing multiple games

	mov di, real_string			; Full city name
	mov al, 0
	mov cx, 50
	rep stosb

	mov di, work_string			; String that starts as '_' characters
	mov al, 0
	mov cx, 50
	rep stosb

	mov di, tried_chars			; Chars the user has tried, but aren't in the real string
	mov al, 0
	mov cx, 255
	rep stosb

	mov byte [tried_chars_pos], 0
	mov byte [misses], 1			; First miss is to show the platform


	mov ax, title_msg			; Set up the screen
	mov bx, footer_msg
	mov cx, 01100000b
	call os_draw_background

	mov ax, 0
	mov bx, 255
	call os_get_random			; Get a random number

	mov bl, cl				; Store in BL


	mov si, cities				; Skip number of lines stored in BL
skip_loop:
	cmp bl, 0
	je skip_finished
	dec bl
.inner:
	lodsb					; Find a zero to denote end of line
	cmp al, 0
	jne .inner
	jmp skip_loop


skip_finished:
	mov di, real_string			; Store the string from the city list
	call os_string_copy

	mov ax, si
	call os_string_length

	mov dx, ax				; DX = number of '_' characters to show

	call add_underscores


	cmp dx, 5				; Give first char if it's a short string
	ja no_hint

	mov ax, hint_msg_1			; Tell player about the hint
	mov bx, hint_msg_2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	call os_hide_cursor

	mov ax, title_msg			; Redraw screen
	mov bx, footer_msg
	mov cx, 01100000b
	call os_draw_background

	mov byte al, [real_string]		; Copy first letter over
	mov byte [work_string], al


no_hint:
	call fix_spaces				; Add spaces to working string if necessary

main_loop:
	call show_tried_chars			; Update screen areas
	call show_hangman
	call show_main_box

	cmp byte [misses], 11			; See if the player has lost
	je lost_game

	call os_wait_for_key			; Get input

	cmp al, KEY_ESC
	je finish

	cmp al, 122				; Work with just "a" to "z" keys
	ja main_loop

	cmp al, 97
	jb main_loop

	mov bl, al				; Store character temporarily

	mov cx, 0				; Counter into string
	mov dl, 0				; Flag whether char was found
	mov si, real_string
find_loop:
	lodsb
	cmp al, 0				; End of string?
	je done_find
	cmp al, bl				; Find char entered in string
	je found_char
	inc cx					; Move on to next character
	jmp find_loop



found_char:
	inc dl					; Note that at least one char match was found
	mov di, work_string
	add di, cx				; Update our underscore string with char found
	mov byte [di], bl
	inc cx
	jmp find_loop


done_find:
	mov si, real_string			; If the strings match, the player has won!
	mov di, work_string
	call os_string_compare
	jc won_game

	cmp dl, 0				; If char was found, skip next bit
	jne main_loop

	call update_tried_chars			; Otherwise add char to list of misses

	jmp main_loop


won_game:
	call show_win_msg
.loop:
	call os_wait_for_key			; Wait for keypress
	cmp al, KEY_ESC
	je finish
	cmp al, KEY_ENTER
	jne .loop
	jmp start


lost_game:					; After too many misses...
	call show_lose_msg
.loop:						; Wait for keypress
	call os_wait_for_key
	cmp al, KEY_ESC
	je finish
	cmp al, KEY_ENTER
	jne .loop
	jmp start


finish:
	call os_show_cursor
	call os_clear_screen

	ret




add_underscores:				; Create string of underscores
	mov di, work_string
	mov al, '_'
	mov cx, dx				; Size of string
	rep stosb
	ret



	; Copy any spaces from the real string into the work string

fix_spaces:
	mov si, real_string
	mov di, work_string
.loop:
	lodsb
	cmp al, 0
	je .done
	cmp al, ' '
	jne .no_space
	mov byte [di], ' '
.no_space:
	inc di
	jmp .loop
.done:
	ret



	; Here we check the list of wrong chars that the player entered previously,
	; and see if the latest addition is already in there...

update_tried_chars:
	mov si, tried_chars
	mov al, bl
	call os_find_char_in_string
	cmp ax, 0
	jne .nothing_to_add			; Skip next bit if char was already in list

	mov si, tried_chars
	mov ax, 0
	mov byte al, [tried_chars_pos]		; Move into the list
	add si, ax
	mov byte [si], bl
	inc byte [tried_chars_pos]

	inc byte [misses]			; Knock up the score
.nothing_to_add:
	ret


show_main_box:
	pusha
	mov bl, BLACK_ON_WHITE
	mov dh, 5
	mov dl, 2
	mov si, 36
	mov di, 21
	call os_draw_block

	mov dh, 7
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_1
	call os_print_string

	mov dh, 8
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_2
	call os_print_string

	mov dh, 17
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_3
	call os_print_string

	mov dh, 18
	mov dl, 4
	call os_move_cursor
	mov si, help_msg_4
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, work_string
	call os_print_string

	popa
	ret


show_tried_chars:
	pusha
	mov bl, BLACK_ON_WHITE
	mov dh, 18
	mov dl, 40
	mov si, 39
	mov di, 23
	call os_draw_block

	mov dh, 19
	mov dl, 41
	call os_move_cursor

	mov si, tried_chars_msg
	call os_print_string

	mov dh, 21
	mov dl, 41
	call os_move_cursor

	mov si, tried_chars
	call os_print_string

	popa
	ret



show_win_msg:
	mov bl, WHITE_ON_GREEN
	mov dh, 14
	mov dl, 5
	mov si, 30
	mov di, 15
	call os_draw_block

	mov dh, 14
	mov dl, 6
	call os_move_cursor

	mov si, .win_msg
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, real_string
	call os_print_string

	ret


	.win_msg	db 'Yay! Hit enter to play again', 0



show_lose_msg:
	mov bl, WHITE_ON_LIGHT_RED
	mov dh, 14
	mov dl, 5
	mov si, 30
	mov di, 15
	call os_draw_block

	mov dh, 14
	mov dl, 6
	call os_move_cursor

	mov si, .lose_msg
	call os_print_string

	mov dh, 12
	mov dl, 6
	call os_move_cursor
	mov si, real_string
	call os_print_string

	ret


	.lose_msg	db 'Doh! Hit enter to play again', 0



	; Draw the hangman box and appropriate bits depending on the number of misses

show_hangman:
	pusha

	mov bl, BLACK_ON_WHITE
	mov dh, 2
	mov dl, 42
	mov si, 35
	mov di, 17
	call os_draw_block


	cmp byte [misses], 0
	je near .0
	cmp byte [misses], 1
	je near .1
	cmp byte [misses], 2
	je near .2
	cmp byte [misses], 3
	je near .3
	cmp byte [misses], 4
	je near .4
	cmp byte [misses], 5
	je near .5
	cmp byte [misses], 6
	je near .6
	cmp byte [misses], 7
	je near .7
	cmp byte [misses], 8
	je near .8
	cmp byte [misses], 9
	je near .9
	cmp byte [misses], 10
	je near .10
	cmp byte [misses], 11
	je near .11

.11:					; Right leg
	mov dh, 10
	mov dl, 64
	call os_move_cursor
	mov si, .11_t
	call os_print_string

.10:					; Left leg
	mov dh, 10
	mov dl, 62
	call os_move_cursor
	mov si, .10_t
	call os_print_string

.9:					; Torso
	mov dh, 9
	mov dl, 63
	call os_move_cursor
	mov si, .9_t
	call os_print_string

.8:					; Arms
	mov dh, 8
	mov dl, 62
	call os_move_cursor
	mov si, .8_t
	call os_print_string

.7:					; Head
	mov dh, 7
	mov dl, 63
	call os_move_cursor
	mov si, .7_t
	call os_print_string

.6:					; Rope
	mov dh, 6
	mov dl, 63
	call os_move_cursor
	mov si, .6_t
	call os_print_string

.5:					; Beam
	mov dh, 5
	mov dl, 56
	call os_move_cursor
	mov si, .5_t
	call os_print_string

.4:					; Support for beam
	mov dh, 6
	mov dl, 57
	call os_move_cursor
	mov si, .4_t
	call os_print_string

.3:					; Pole
	mov dh, 12
	mov dl, 56
	call os_move_cursor
	mov si, .3_t
	call os_print_string
	mov dh, 11
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 10
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 9
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 8
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 7
	mov dl, 56
	call os_move_cursor
	call os_print_string
	mov dh, 6
	mov dl, 56
	call os_move_cursor
	call os_print_string

.2:					; Support for pole
	mov dh, 13
	mov dl, 55
	call os_move_cursor
	mov si, .2_t
	call os_print_string

.1:					; Ground
	mov dh, 14
	mov dl, 53
	call os_move_cursor
	mov si, .1_t
	call os_print_string
	

.0:
	popa
	ret


	.1_t		db '-------------', 0
	.2_t		db '/|\', 0
	.3_t		db '|', 0
	.4_t		db '/', 0
	.5_t		db '________', 0
	.6_t		db '|', 0
	.7_t		db 'O', 0
	.8_t		db '---', 0
	.9_t		db '|', 0
	.10_t		db '/', 0
	.11_t		db '\', 0



	title_msg	db 'MikeOS Hangman', 0
	footer_msg	db 'Press Esc to exit', 0

	hint_msg_1	db 'Short word this time, so you', 0
	hint_msg_2	db 'get the first letter for free!', 0

	help_msg_1	db 'Can you guess the city name', 0
	help_msg_2	db 'that fits the spaces beneath?', 0
	help_msg_3	db 'Press keys to guess letters,', 0
	help_msg_4	db 'but you only have 10 chances!', 0

	real_string	times 50 db 0
	work_string	times 50 db 0

	tried_chars_msg	db 'Tried characters...', 0
	tried_chars_pos	db 0
	tried_chars	times 255 db 0

	misses		db 1



cities:

db 'kabul', 0
db 'tirane', 0
db 'algiers', 0
db 'andorra la vella', 0
db 'luanda', 0
db 'saint johns', 0
db 'buenos aires', 0
db 'yerevan', 0
db 'canberra', 0
db 'adelaide', 0
db 'melbourne', 0
db 'vienna', 0
db 'baku', 0
db 'nassau', 0
db 'manama', 0
db 'dhaka', 0
db 'bridgetown', 0
db 'minsk', 0
db 'brussels', 0
db 'belmopan', 0
db 'porto novo', 0
db 'thimpu', 0
db 'sucre', 0
db 'sarajevo', 0
db 'gaborone', 0
db 'brasilia', 0
db 'bandar seri begawan', 0
db 'sofia', 0
db 'ouagadougou', 0
db 'bujumbura', 0
db 'phnom penh', 0
db 'yaounde', 0
db 'ottawa', 0
db 'praia', 0
db 'bangui', 0
db 'ndjamema', 0
db 'santiago', 0
db 'beijing', 0
db 'bogota', 0
db 'moroni', 0
db 'brazzaville', 0
db 'kinshasa', 0
db 'san jose', 0
db 'yamoussoukro', 0
db 'zagreb', 0
db 'havana', 0
db 'nicosia', 0
db 'prague', 0
db 'copenhagen', 0
db 'djibouti', 0
db 'roseau', 0
db 'santo domingo', 0
db 'dili', 0
db 'quito', 0
db 'cairo', 0
db 'san salvador', 0
db 'malabo', 0
db 'asmara', 0
db 'tallinn', 0
db 'addis ababa', 0
db 'suva', 0
db 'helsinki', 0
db 'paris', 0
db 'libreville', 0
db 'banjul', 0
db 'tbilisi', 0
db 'berlin', 0
db 'accra', 0
db 'athens', 0
db 'saint georges', 0
db 'guatemala city', 0
db 'conakry', 0
db 'bissau', 0
db 'georgetown', 0
db 'port au prince', 0
db 'tegucigalpa', 0
db 'budapest', 0
db 'reykjavik', 0
db 'new delhi', 0
db 'jakarta', 0
db 'baghdad', 0
db 'dublin', 0
db 'jerusalem', 0
db 'rome', 0
db 'kingston', 0
db 'tokyo', 0
db 'amman', 0
db 'astana', 0
db 'nairobi', 0
db 'tarawa atoll', 0
db 'pyongyang', 0
db 'seoul', 0
db 'pristina', 0
db 'kuwait city', 0
db 'bishkek', 0
db 'vientiane', 0
db 'riga', 0
db 'beirut', 0
db 'maseru', 0
db 'monrovia', 0
db 'tripoli', 0
db 'vaduz', 0
db 'vilnius', 0
db 'luxembourg', 0
db 'skopje', 0
db 'antananarivo', 0
db 'lilongwe', 0
db 'kuala lumpur', 0
db 'male', 0
db 'bamako', 0
db 'valletta', 0
db 'majuro', 0
db 'nouakchott', 0
db 'port louis', 0
db 'mexico city', 0
db 'palikir', 0
db 'chisinau', 0
db 'monaco', 0
db 'ulaanbaatar', 0
db 'podgorica', 0
db 'rabat', 0
db 'maputo', 0
db 'rangoon', 0
db 'windhoek', 0
db 'yaren district', 0
db 'kathmandu', 0
db 'amsterdam', 0
db 'the hague', 0
db 'wellington', 0
db 'managua', 0
db 'niamey', 0
db 'abuja', 0
db 'lagos', 0
db 'oslo', 0
db 'bergen', 0
db 'stavanger', 0
db 'muscat', 0
db 'islamabad', 0
db 'karachi', 0
db 'melekeok', 0
db 'panama city', 0
db 'port moresby', 0
db 'asuncion', 0
db 'lima', 0
db 'manila', 0
db 'warsaw', 0
db 'lisbon', 0
db 'doha', 0
db 'bucharest', 0
db 'moscow', 0
db 'kigali', 0
db 'basseterre', 0
db 'castries', 0
db 'kingstown', 0
db 'apia', 0
db 'san marino', 0
db 'sao tome', 0
db 'riyadh', 0
db 'dakar', 0
db 'belgrade', 0
db 'victoria', 0
db 'freetown', 0
db 'singapore', 0
db 'bratislava', 0
db 'ljubljana', 0
db 'honiara', 0
db 'mogadishu', 0
db 'pretoria', 0
db 'bloemfontein', 0
db 'madrid', 0
db 'colombo', 0
db 'khartoum', 0
db 'paramaribo', 0
db 'mbabane', 0
db 'stockholm', 0
db 'bern', 0
db 'geneva', 0
db 'zurich', 0
db 'damascus', 0
db 'taipei', 0
db 'dushanbe', 0
db 'dar es salaam', 0
db 'bangkok', 0
db 'lome', 0
db 'nukualofa', 0
db 'port of spain', 0
db 'tunis', 0
db 'ankara', 0
db 'ashgabat', 0
db 'funafuti', 0
db 'kampala', 0
db 'kiev', 0
db 'abu dhabi', 0
db 'dubai', 0
db 'london', 0
db 'washington', 0
db 'montevideo', 0
db 'tashkent', 0
db 'port vila', 0
db 'vatican city', 0
db 'caracas', 0
db 'hanoi', 0
db 'sanaa', 0
db 'lusaka', 0
db 'harare', 0
db 'st petersburg', 0
db 'odessa', 0
db 'manchester', 0
db 'liverpool', 0
db 'birmingham', 0
db 'frankfurt', 0
db 'munich', 0
db 'dortmund', 0
db 'new york', 0
db 'chicago', 0
db 'san francisco', 0
db 'los angeles', 0
db 'las vegas', 0
db 'boston', 0
db 'new jersey', 0
db 'dallas', 0
db 'atlanta', 0
db 'miami', 0
db 'vancouver', 0
db 'toronto', 0
db 'saopaulo', 0
db 'rio de janeiro', 0
db 'vladivostok', 0
db 'glasgow', 0
db 'edinburgh', 0
db 'lyon', 0
db 'venice', 0
db 'torshavn', 0
db 'nuuk', 0
db 'bristol', 0
db 'york', 0
db 'tel aviv', 0
db 'seattle', 0
db 'stuttgart', 0
db 'osaka', 0
db 'kyoto', 0
db 'sapporo', 0
db 'kagoshima', 0
db 'shanghai', 0
db 'chongqing', 0
db 'hong kong', 0
db 'macao', 0
db 'xian', 0
db 'lhasa', 0
db 'warrington', 0
db 'leeds', 0
db 'luxor', 0
db 'timbuktu', 0
db 'honolulu', 0
db 'bordeaux', 0
db 'cupertino', 0


; ------------------------------------------------------------------

