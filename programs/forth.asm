; *****************************************************************************
; *
; *               Forth operating system for an IBM Compatible PC
; *                       Copyright (C) 1993-2011 W Nagel
; *         Copyright (C) 2014 MikeOS Developers -- see doc/LICENSE.TXT
; *
; * For the most part it follows the FIG model, Forth-79 standard
; * There are differences, however
; *
; *****************************************************************************
; Some machines use subroutine threading (use SP for R stack) - this is 
;   considered Forth-like, and not true Forth.  Also, the 8086 does not support 
;   [SP] and there are many more PUSH (1 byte) than RPUSH (4 bytes) instructions.
;   This would be a poor choice for this processor.

; CFA = Compilation (or Code) Field Address.
; A Forth header =
;			LFA	address of previous word in chain, last one = 0
;			NFA	count(b4-0)/flags(b7=immediate, b5=smudge) + name
;			CFA	points to executable code for this definition
;			PFA	may contain parameters or code

; converted to nasm's macro processor

bits	16		; nasm, 8086

%include "mikedev.inc"

	cr	equ  13		; carriage return
	lf	equ  10		; line feed
	bell	equ   7		; bell (sort of)
	spc	equ  32		; space
	bs	equ   8		; back space
	del	equ 127		; 'delete' character

%macro NEXT 0			; mov di,[si] + inc si (twice) => couple extra bytes & many cycles
	lodsw
	xchg ax,di		; less bytes than mov, just as fast
	jmp [di]		; 4 bytes
%endmacro

%macro RPUSH 1
	dec bp
	dec bp
	mov word [bp+0],%1
%endmacro

%macro RPOP 1
	mov word %1,[bp+0]
	inc bp
	inc bp
%endmacro

; A vocabulary is specified by a number between 1 and 15. See 'vocabulary' for a short
; discussion. A minimum of (2* highest vocabulary) dictionary threads are needed to 
; prevent 'collisions' among the vocabularies. Initial compilation is entirely in the
; 'FORTH' vocabulary.
  VOC EQU 1				; specify FORTH part of Dictionary for this build

%assign IMM 0				; next word is not IMMEDIATE
%macro IMMEDIATE 0			; the following word is immediate
	%assign IMM 080h
%endmacro

%assign defn 0				; definition counter to create unique label
%define @def0 0				; no definitions yet, mark as end of chain

%macro HEADING 1
	%assign t1 defn		; unique label for chaining definitions
	%assign defn defn+1	; increment label

	%strlen lenstrng %1	; get length of name

	@def %+ defn: dw @def %+ t1	; temporary LFA -- first startup rearranges into chains
	db IMM+lenstrng, %1		; turn name into counted string with immediate indicator

	%assign IMM 0		; next word is not immediate, by default
%endmacro


org	0x8000		; Start 1/2 way through segment for MikeOS

  size		EQU 65536
  first         EQU size & 0xffff	; 65536 or memory end for single segment 8086
  stack0	EQU size - 128		; R Stack & text input buffer

	jmp     do_startup	; maximize use-once code that will be "forgotten"

; Nucleus / Core -- ground 0

; Single precision (16-bit) Arithmetic operators
; CODE used extensively for speed

HEADING '*'			; ( n1 n2 -- n )
  mult:		dw	$ + 2
	pop di
	pop ax
	mul di
	push ax
	NEXT

HEADING '*/'			; ( n1 n2 n3 -- n )
		dw      $ + 2
	pop di
	pop dx
	pop ax
	imul dx
	idiv di
	push ax
	NEXT

HEADING '*/MOD'			; ( u1 u2 u3 -- r q )
		dw      $ + 2
	pop di
	pop dx
	pop ax
	mul dx
	div di
	push dx
	push ax
	NEXT

HEADING '+'			; ( n1 n2 -- n )
  plus:		dw $ + 2
	pop dx
	pop ax
	add ax,dx
	push ax
	NEXT

HEADING '-'			; ( n1 n2 -- n )
  minus:        dw      $ + 2
	pop dx
	pop ax
	sub ax,dx
	push ax
	NEXT

HEADING '/'			; ( n1 n2 -- n )
  divide:       dw      $ + 2
	pop di
	pop ax
	CWD
	idiv di         ; use di register for all divisions
	push ax         ; so that div_0 interrupt will work
	NEXT

HEADING '/MOD'			; ( u1 u2 -- r q )
		dw      $ + 2
	pop di
	pop ax
	sub dx,dx
	div di
	push dx
	push ax
	NEXT

HEADING '1+'			; ( n -- n+1 )
  one_plus:     dw      $ + 2
	pop ax
	inc ax
	push ax
	NEXT

HEADING '1+!'			; ( a -- )
  one_plus_store: dw	$ + 2
	pop di
	inc word [di]
	NEXT

HEADING '1-'			; ( n -- n-1 )
  one_minus:    dw      $ + 2
	pop ax
	dec ax
	push ax
	NEXT

HEADING '1-!'			; ( a -- )
		dw      $ + 2
	pop di
	dec word [di]
	NEXT

HEADING '2*'			; ( n -- 2n )
  two_times:    dw      $ + 2
	pop ax
	shl ax,1
	push ax
	NEXT

HEADING '2**'			; ( n -- 2**N )
		dw      $ + 2
	mov ax,1
	pop cx
	and cx,0Fh
	shl ax,cl
	push ax
	NEXT

HEADING '2+'			; ( n -- n+2 )
  two_plus:     dw      $ + 2
	pop ax
	inc ax
	inc ax
	push ax
	NEXT

HEADING '2-'			; ( n -- n-2 )
  two_minus:    dw      $ + 2
	pop ax
	dec ax
	dec ax
	push ax
	NEXT

HEADING '2/'			; ( n -- n/2 )
		dw      $ + 2
	pop ax
	sar ax,1
	push ax
	NEXT

HEADING '4*'			; ( n -- 4n )
		dw      $ + 2
	pop ax
	shl ax,1
	shl ax,1
	push ax
	NEXT

HEADING '4/'			; ( n -- n/4 )
		dw      $ + 2
	pop ax
	sar ax,1
	sar ax,1
	push ax
	NEXT

HEADING 'MOD'			; ( u1 u2 -- r )
		dw      $ + 2
	pop di
	pop ax
	sub dx,dx
	div di
	push dx
	NEXT

HEADING 'NEGATE'		; ( n -- -n )
		dw      $ + 2
	pop ax
  negate1:
	neg ax
	push ax
	NEXT

HEADING 'ABS'			; ( n -- |n| )
		dw      $ + 2
	pop ax
	or ax,ax
	jl negate1		; not alphabetical, allow short jump
	push ax
	NEXT

; Bit and Logical operators

HEADING 'AND'			; ( n1 n2 -- n )
  cfa_and:	dw	$ + 2
	pop dx
	pop ax
	and ax,dx
	push ax
	NEXT

HEADING 'COM'			; ( n -- !n >> ones complement )
		dw	$ + 2
	pop ax
	not ax
	push ax
	NEXT

HEADING 'LSHIFT'		; ( n c -- n<<c )
		dw	$ + 2
	pop cx
	pop ax
	and cx,0Fh              ; 16-bit word => max of 15 shifts
	shl ax,cl
	push ax
	NEXT

HEADING 'NOT'			; ( f -- \f )
  cfa_not:	dw zero_eq + 2	; similar to an alias

HEADING 'OR'			; ( n1 n2 -- n )
  cfa_or:	dw $ + 2
	pop dx
	pop ax
	or ax,dx
	push ax
	NEXT

HEADING 'RSHIFT'		; ( n c -- n>>c )
		dw $ + 2
	pop cx
	pop ax
	and cx,0Fh
	sar ax,cl
	push ax
	NEXT

HEADING 'XOR'			; ( n1 n2 -- n )
  cfa_xor:	dw $ + 2
	pop dx
	pop ax
	xor ax,dx
	push ax
	NEXT

; Number comparison

HEADING '0<'			; ( n -- f )
  zero_less:    dw $ + 2
	pop cx
	or cx,cx
  do_less:
	mov ax,0
	jge dl1
	inc ax			; '79 true = 1
;	dec ax			; '83 true = -1
  dl1:
	push ax
	NEXT

HEADING '<'			; ( n1 n2 -- f )
  less:         dw $ + 2
	pop dx
	pop cx
	cmp cx,dx
	JMP do_less

HEADING '>'			; ( n1 n2 -- f )
  greater:      dw      $ + 2
	pop cx
	pop dx
	cmp cx,dx
	JMP do_less

HEADING '0='			; ( n -- f )
  zero_eq:      dw      $ + 2
	pop cx
  test0:
	mov ax,1		; '79 true
	jcxz z2
	dec ax			; 1-1 = 0 = FALSE
  z2:
	push ax
	NEXT

HEADING '='			; ( n1 n2 -- f )
  cfa_eq:	dw	$ + 2
	pop dx
	pop cx
	sub cx,dx
	JMP test0

HEADING 'MAX'			; ( n1 n2 -- n )
		dw      $ + 2
	pop ax
	pop dx
	CMP dx,ax
	jge max1
	xchg ax,dx
  max1:
	push dx
	NEXT

HEADING 'MIN'			; ( n1 n2 -- n )
  cfa_min:	dw	$ + 2
	pop ax
	pop dx
	CMP ax,dx
	jge min1
	xchg ax,dx
  min1:
	push dx
	NEXT

HEADING 'U<'			; ( u1 u2 -- f )
  u_less:       dw      $ + 2
	sub cx,cx
	pop dx
	pop ax
	cmp ax,dx
	jnc ul1
	inc cx
  ul1:
	push cx
	NEXT

HEADING 'WITHIN'		; ( n nl nh -- f >> true if nl <= n < nh )
  WITHIN:	dw $ + 2
	sub cx,cx	; flag, default is false
	pop dx		; high limit
	pop di		; low limit
	pop ax		; variable
	cmp ax,dx	; less than (lt) high, continue
	jge w1
	cmp ax,di	; ge low
	jl w1
	inc cx
  w1:
	push cx
	NEXT

; Memory reference, 16 bit

HEADING '!'			; ( n a -- )
  store:        dw      $ + 2
	pop di
	pop ax
	stosw		; less bytes and just as fast as move
	NEXT

HEADING '+!'			; ( n a -- )
  plus_store:   dw      $ + 2
	pop di
	pop ax
	add [di],ax
	NEXT

HEADING '@'			; ( a -- n )
  fetch:        dw      $ + 2
	pop di
	push word [di]
	NEXT

HEADING 'C!'			; ( c a -- )
  c_store:      dw      $ + 2
	pop di
	pop ax
	stosb		; less bytes and just as fast as move
	NEXT

HEADING 'C+!'			; ( c a -- )
	dw      $ + 2
	pop di
	pop ax
	add [di],al
	NEXT

HEADING 'C@'			; ( a -- zxc >> zero extend )
  c_fetch:      dw      $ + 2
	pop di
	sub ax,ax
	mov al,[di]
	push ax
	NEXT

HEADING 'FALSE!'		; ( a -- >> stores 0 in address )
  false_store:  dw      $ + 2
	sub ax,ax
	pop di
	stosw
	NEXT

HEADING 'XFER'			; ( a1 a2 -- >> transfers contents of 1 to 2 )
  XFER:         dw      $ + 2
	pop dx
	pop di
	mov ax,[di]
	mov di,dx
	stosw
	NEXT

; 16-bit Parameter Stack operators

HEADING '-ROT'			; ( n1 n2 n3 -- n3 n1 n2 )
  m_ROT:	dw      $ + 2
	pop di
	pop dx
	pop ax
	push di
	push ax
	push dx
	NEXT

HEADING '?DUP'			; ( n -- 0, n n )
  q_DUP: 	dw      $ + 2
	pop ax
	or ax,ax
	jz qdu1
	push ax
  qdu1:
	push ax
	NEXT

HEADING 'DROP'			; ( n -- )
  DROP:         dw      $ + 2
	pop ax
	NEXT

HEADING 'DUP'			; ( n -- n n )
  cfa_dup:	dw	$ + 2
	pop ax
	push ax
	push ax
	NEXT

HEADING 'OVER'			; ( n1 n2 -- n1 n2 n1 )
  OVER: 	dw      $ + 2
	mov di,sp
	push word [di+2]
	NEXT

HEADING 'PICK'			; ( ... n1 c -- ... nc )
  PICK: 	dw      $ + 2
	pop di
	dec di
	shl di,1
	add di,sp
	push word [di]
	NEXT

HEADING 'ROT'			; ( n1 n2 n3 -- n2 n3 n1 )
  ROT:          dw      $ + 2
	pop di
	pop dx
	pop ax
	push dx
	push di
	push ax
	NEXT

; Note: 'push sp' results vary by processor
HEADING 'SP@'			; ( -- a )
  sp_fetch:     dw      $ + 2
	mov ax,sp
	push ax
	NEXT

HEADING 'SWAP'			; ( n1 n2 -- n2 n1 )
  SWAP:         dw      $ + 2
	pop dx
	pop ax
	push dx
	push ax
	NEXT

; Return stack manipulation

HEADING 'I'			; ( -- n >> [RP] )
  eye:  	dw      $ + 2
	mov ax,[bp+0]
	push ax
	NEXT

HEADING "I'"			; ( -- n >> [RP+2] )
  eye_prime:    dw      $ + 2
	mov ax,[bp+2]
	push ax
	NEXT

HEADING 'J'			; ( -- n >> [RP+4] )
	dw      $ + 2
	mov ax,[bp+4]
	push ax
	NEXT

HEADING "J'"			; ( -- n >> [RP+6] )
	dw      $ + 2
	mov ax,[bp+6]
	push ax
	NEXT

HEADING 'K'			; ( -- n >> [RP+8] )
	dw      $ + 2
	mov ax,[bp+8]
	push ax
	NEXT

HEADING '>R'			; ( n -- >> S stack to R stack )
  to_r:         dw      $ + 2
	pop ax
	RPUSH ax
	NEXT

HEADING 'R>'			; ( -- n >> R stack to S stack )
  r_from:       dw      $ + 2
	RPOP ax
	push ax
	NEXT

; Constant replacements
; CONSTANT takes 66 cycles (8086) to execute

HEADING '0'			; ( -- 0 )
  zero:         dw      $ + 2
	xor ax,ax
	push ax
	NEXT

HEADING '1'			; ( -- 1 )
  one:          dw      $ + 2
	mov ax,1
	push ax
	NEXT

HEADING 'FALSE'			; ( -- 0 )
	dw	zero + 2

HEADING 'TRUE'			; ( -- t )
  truu:	dw $ + 2
	mov ax,1	; '79 value
	push ax
	NEXT


; 32-bit (double cell) - standard option

HEADING '2!'			; ( d a -- )
  two_store:    dw      $ + 2
	pop di
	pop dx		; TOS = high word
	pop ax		; variable low address => low word
	stosw
	mov ax,dx
	stosw
	NEXT

HEADING '2>R'			; ( n n -- >> transfer to R stack )
  two_to_r:     dw      $ + 2
	pop ax
	pop dx
	RPUSH dx
	RPUSH ax
	NEXT

HEADING '2@'			; ( a -- d )
  two_fetch:    dw      $ + 2
	pop di
	push word [di]		; low variable address => low word
	push word [di+2]	; low param stack address (TOS) => high word
	NEXT

HEADING '2DROP'			; ( d -- )
  two_drop:     dw      $ + 2
	pop ax
	pop ax
	NEXT

HEADING '2DUP'			; ( d -- d d )
  two_dup:      dw      $ + 2
	pop dx
	pop ax
	push ax
	push dx
	push ax
	push dx
	NEXT

HEADING '2OVER'			; ( d1 d2 -- d1 d2 d1 )
  two_over:     dw      $ + 2
	mov di,sp
	push word [di+6]
	push word [di+4]
	NEXT

HEADING '2R>'			; ( -- n1 n2 )
  two_r_from:   dw      $ + 2
	RPOP ax
	RPOP dx
	push dx
	push ax
	NEXT

HEADING '2SWAP'			; ( d1 d2 -- d2 d1 )
  two_swap:     dw      $ + 2
	pop dx
	pop di
	pop ax
	pop cx
	push di
	push dx
	push cx
	push ax
	NEXT

HEADING 'D+'			; ( d1 d2 -- d )
  d_plus:       dw      $ + 2
	pop dx
	pop ax
  dplus:
	mov di,sp
	add [di+2],ax
	adc [di],dx
	NEXT

HEADING 'D+!'			; ( d a -- )
		dw      $ + 2
	pop di
	pop dx
	pop ax
	add [di+2],ax
	adc [di],dx
	NEXT

HEADING 'D-'			; ( d1 d2 -- d )
  d_minus:      dw      $ + 2
	pop cx
	pop di
	pop ax
	pop dx
	sub dx,di
	sbb ax,cx
	push dx
	push ax
	NEXT

HEADING 'D0='			; ( d -- f )
  d_zero_eq:    dw      $ + 2
	pop ax
	pop dx
	sub cx,cx
	or ax,dx
	jnz dz1
	inc cx		; 1, F79
;	dec cx		; -1, F83
  dz1:
	push cx
	NEXT

HEADING 'DNEGATE'		; ( d -- -d )
  DNEGATE:      dw      $ + 2
	pop dx
	pop ax
	neg ax
	adc dx,0
	neg dx
	push ax
	push dx
	NEXT

HEADING 'S>D'			; ( n -- d )
  s_to_d:       dw      $ + 2
	pop ax
	CWD
	push ax
	push dx
	NEXT

HEADING 'M*'			; ( n1 n2 -- d )
		dw      $ + 2
	pop ax
	pop dx
	imul dx
	push ax
	push dx
	NEXT

HEADING 'M+'			; ( d1 n -- d )
		dw      $ + 2
	pop ax
	CWD
	jmp dplus

HEADING 'M/'			; ( d n1 -- n )
		dw      $ + 2
	pop di
	pop dx
	pop ax
	idiv di
	push ax
	NEXT

HEADING 'U*'			; ( u1 u2 -- d )
	dw      $ + 2
	pop ax
	pop dx
	mul dx
	push ax
	push dx
	NEXT

HEADING 'U/MOD'			; ( d u -- r q )
	dw      $ + 2
	pop di
	pop dx
	pop ax
	div di
	push dx
	push ax
	NEXT


; Long Structures - more efficient code, but extra byte
; These use a stored address rather than a byte offset

do_branch:	dw $ + 2
  branch:
	lodsw		; ax = goto address
	mov si,ax	; XP = goto
	NEXT

; jump on opposite condition, ie NE IF compiles JE
q_branch:	dw $ + 2	; ( f -- )
	pop ax
	or ax,ax
	je branch	; ignore conditional execution if flag false
  no_branch:
	inc si		; bypass jump address
	inc si
	NEXT		;   and then execute conditional words


do_loop:	dw $ + 2
	mov cx,1	; normal increment
  lp1:
	add cx,[bp+0]	; update counter
	mov [bp+0],cx	; save for next round
	cmp cx,[bp+2]    ; (signed, Forth-79) compare to limit
	jl branch	; not at end of loop count, go again
  lp2:
	add bp,4	; at end, drop cntr & limit from R stack
	inc si		; skip jump/loop address & continue
	inc si
	NEXT

plus_loop:	dw $ + 2	; ( n -- )
	pop cx
	JMP lp1

slant_loop:	dw $ + 2	; ( n -- )
	pop dx
	add [bp+0],dx	; (Forth-83) crossed boundary from below?
	mov ax,[bp+0]
	sub ax,[bp+2]
	xor ax,dx
	jge lp2		; end of loop, exit

	jmp branch	; no, branch back to loop beginning


c_switch:	dw $ + 2	; ( xx c.input -- xx | xx c.input )
	pop dx
	RPUSH si
	ADD si,4
	sub cx,cx
  c_s1:			; BEGIN
	lodsw			; inc si, get address of byte
	mov di,ax
	MOV cl,[di]		; byte to match
	lodsw			; inc si, get possible link
	CMP dl,cl
	je c_s3			; input match this entry ?
	CMP ax,0	; WHILE not last link = 0
	jz c_s2
	mov si,ax
	JMP c_s1	; REPEAT, try next entry
  c_s2:
	push dx 		; no matches
  c_s3:
  	NEXT


do_switch:	dw $ + 2	; ( xx n.input -- xx | xx n.input )
	pop dx			; switch input
	RPUSH si
	ADD si,4		; skip forth branch
  sw1:
	lodsw
	MOV cx,ax		; number to match
	lodsw			; increment I; get possible link
	CMP dx,cx
	je sw3			; input match this entry
	CMP ax,0
	je sw2
	mov si,ax
	JMP sw1			; try next entry
  sw2:
	push dx			; no matches
  sw3:
  	NEXT


; Runtime for literals

bite:   	dw      $ + 2
	lodsb                   ; get data byte
	cbw                     ; sign extend to word
	push ax
	NEXT

cell:   	dw      $ + 2	; code def with no header/ only cfa.
	lodsw                   ; used by literal
	push ax                 ; push data word on param stack
	NEXT

dclit:  	dw      $ + 2	; ( -- sxc1 sxc2 )
	lodsb           ; get first byte
	cbw
	push ax
	lodsb           ; get second byte
	cbw
	push ax
	NEXT

dblwd:		dw       $ + 2	; ( -- d )
	lodsw
	mov dx,ax	; low address => high word when inline
	lodsw
	push ax
	push dx		; lower stack address (TOS) => high word
	NEXT

; Program execution

HEADING 'EXECUTE'
  EXECUTE:      dw      $ + 2
	pop di                  ; ( cfa -- >> runtime )
  exec1:
	or di,di
	jz e001			; no address was given, cannot be 0
	jmp [di]
  e001:
	NEXT

HEADING '@EXECUTE'
  @EXECUTE:     dw      $ + 2
	pop di                  ; ( a -- >> runtime )
	mov di,[di]
	JMP exec1

HEADING 'EXIT'			; LFA + NFA
  EXIT:         dw      $ + 2   ; CFA
  exit1:                        ; R = BP, return stack pointer ( PFA )
	RPOP si
	NEXT

HEADING 'LEAVE-EXIT'
  leave_exit:   dw      $ + 2
	add bp,4		; 2RDROP - count & limit
	jmp exit1

HEADING '2LEAVE-EXIT'
		dw      $ + 2
	add bp,8		; 4RDROP - both counts & limits
	jmp exit1

HEADING 'LEAVE'
  leave_lp:	dw $ + 2
	mov ax,[bp+0]		; next test will => done, count = limit
	mov [bp+2],ax
	NEXT

HEADING 'STAY'			; ( f -- >> exit if false )
  STAY:         dw      $ + 2
	pop ax
	or ax,ax
	jz exit1
	NEXT

; Defining words -- define & execution

HEADING ':'
	dw      colon
	dw      cfa_create, r_bracket
	dw      sem_cod		; sets CFA of daughter to 'colon'
  colon:
	inc di			; cfa -> pfa
	inc di
	RPUSH si		; rpush si = execute ptr => current pfa
	mov si,di		; exec ptr = new pfa
	NEXT

; Note - word copies input to here + 2, in case of a new definition
HEADING 'CREATE'
  cfa_create       dw      colon	; ( -- )
	dw      blnk, cfa_word, cfa_dup		; word adr = string adr = na
	dw      c_fetch, cfa_dup		; ( na count count )
	dw      zero_eq, abortq
	db      ct001 - $ - 1
	db      'No name'
  ct001:
	dw      bite				; ( na count )
	db      31
	dw      greater, abortq
	db      ct002 - $ - 1
	db      'Name too long!'
  ct002:
	dw      CURRENT, c_fetch, HASH, FIND_WD	; ( na v -- na lfa,0 )
	dw      q_DUP, q_branch			; IF name exists in current vocab,
	dw      ct005				;  print redefinition 'warning'
	dw      CR, OVER, COUNT, cfa_type
	dw      dotq
	db      ct003 - $ - 1
	db      ' Redefinition of: '
  ct003:
	dw      cfa_dup, id_dot, dotq
	db      ct004 - $ - 1
	db      'at '
  ct004:
	dw      u_dot
  ct005:					; THEN
	dw      CURRENT, c_fetch, HASH		; ( na link )
	dw      HEADS, plus, HERE		; ( nfa hdx lfa=here )
	dw      cfa_dup, LAST, store		; ( nfa hdx lfa )
	dw      OVER, fetch, comma		; set link field
	dw      SWAP, store			; update heads
	dw      c_fetch				; ( count )
	dw	one_plus, ALLOT			; allot name and count/flags
	dw	SMUDGE
	dw      zero, comma			; code field = 0, ;code will update
	dw      sem_cod
create:				; ( -- pfa )
	inc di                  ; cfa -> pfa
	inc di
	push di                 ; standard def => leave pfa on stack
	NEXT

does:
	RPUSH si		; rpush current (word uses parent) execute ptr
	pop si			; get new (parent) execute ptr
	inc di			; daughter cfa -> pfa
	inc di
	push di			; leave daughter pfa on stack
	NEXT

HEADING 'CONSTANT'
  cfa_constant:	dw	colon		; ( n -- >> compile time )
		dw      cfa_create, comma
		dw	UNSMUDGE, sem_cod
  constant:				; ( -- n >> run time )
	push word [di+2]
	NEXT

HEADING '2CONSTANT'
	dw      colon			; ( d -- )
	dw      SWAP, cfa_constant
	dw	comma, sem_cod
  two_con:				; ( -- d )
	push word [di+2]
	push word [di+4]
	NEXT

; System-wide constants

HEADING '0.'			; ( -- 0 0 >> code def is alternative )
  zero_dot:	dw two_con
	dw      0, 0

HEADING '1.'
	dw      two_con
	dw      1, 0

HEADING '2'
  two:  dw      constant, 2

HEADING 'BL'
  blnk: dw      constant, spc		; <space>

B_HDR:		dw      constant        ; bytes in header, ie, hash lists * 2
		dw      32		; see HEADS and FENCE

L_WIDTH:	dw      constant
		dw      80

HEADING 'S0'
  SP0: 	dw	constant, stack0


; String, text operators

HEADING '-TEXT'			; ( a1 n a2 -- f,t=different )
	dw      $ + 2
	pop di
	pop cx
	pop ax
	xchg ax,si
	REP CMPSB
	je txt1
	mov cx,1
	jnc txt1
	neg cx
  txt1:
	push cx
	mov si,ax
	NEXT

HEADING '-TRAILING'		; ( a n -- a n' )
  m_TRAILING:   dw      $ + 2
	pop cx
	pop di
	push di
	jcxz trl1
	mov al,' '
	add di,cx
	dec di
	STD
	REP scasb
	cld
	je trl1
	inc cx
  trl1:
	push cx
	NEXT

HEADING '<CMOVE'		; ( s d n -- )
  backwards_cmove: dw $ + 2
	pop cx
	pop di
	pop ax
	jcxz bmv1
	xchg ax,si
	add di,cx
	dec di
	add si,cx
	dec si
	STD
	REP movsb

	cld
	mov si,ax
  bmv1:

	NEXT

HEADING 'CMOVE'			; ( s d n -- )
  front_cmove:	dw $ + 2
	pop cx          ; count
	pop di
	pop ax
	xchg ax,si
	rep movsb
	mov si,ax
	NEXT

HEADING 'COUNT'			; ( a -- a+1 n )
  COUNT:	dw $ + 2
	pop di
	sub ax,ax
	mov al,[di]
	inc di
	push di
	push ax
	NEXT


; Memory fills

HEADING 'FILL'			; ( a n c -- )
		dw      $ + 2
	pop ax
  mem_fill:
	pop cx
	pop di
	REP stosb
	NEXT

HEADING 'BLANK'			; ( a n -- )
  BLANK:	dw	$ + 2
	mov al,' '
	JMP mem_fill

HEADING 'ERASE'			; ( a n -- )
  ERASE:        dw      $ + 2
	sub ax,ax
	JMP mem_fill

; Intersegment data moves

HEADING 'L!'			; ( n seg off -- )
		dw      $ + 2
	pop di
	pop ds
	pop ax
	mov [di],ax
	mov dx,cs
	mov ds,dx
	NEXT

HEADING 'L@'			; ( seg off -- n )
		dw      $ + 2
	pop di
	pop ds
	mov ax,[di]
	mov dx,cs
	mov ds,dx
	push ax
	NEXT

HEADING 'LC!'			; ( c seg off -- )
		dw      $ + 2
	pop di
	pop ds
	pop ax
	mov [di],al
	mov dx,cs
	mov ds,dx
	NEXT

HEADING 'LC@'			; ( seg off -- c >> zero extended byte )
		dw      $ + 2
	pop di
	pop ds
	sub ax,ax
	mov al,[di]
	mov dx,cs
	mov ds,dx
	push ax
	NEXT

HEADING 'FORTHSEG'		; ( -- seg )
  FORTHSEG:	dw $ + 2	; not a constant in a PC system
	push cs                 ; changes each time the program is run
	NEXT

HEADING 'STACKSEG'		; ( -- seg )
		dw	$ + 2
	mov ax,cs		; 64K (4K segs) above FORTHSEG
	add ax,4096
	push ax
	NEXT

HEADING 'FIRSTSEG'		; ( -- seg )
		dw	$ + 2
	mov ax,cs		; 128K (8K segs) above FORTHSEG, 64k above stack/buffer seg
	add ax,8192
	push ax
	NEXT

HEADING 'SEGMOVE'		; ( fs fa ts ta #byte -- )
		dw      $ + 2
	pop cx
	pop di
	pop es
	pop ax
	pop ds
	xchg ax,si
	shr cx,1
	jcxz segmv1
	REP MOVSw
  segmv1:
	jnc segmv2
	movsb
  segmv2:
	mov dx,cs
	mov ds,dx
	mov es,dx
	mov si,ax
	NEXT

; Miscellaneous Stuff

HEADING '><'			; ( n -- n' >> bytes interchanged )
		dw      $ + 2
	pop ax
	xchg al,ah
	push ax
	NEXT

HEADING '+@'			; ( a1 a2 -- n )
  plus_fetch:   dw      $ + 2
	pop ax
	pop di
	add di,ax
	push word [di]
	NEXT

HEADING '@+'			; ( n1 a -- n )
  fetch_plus:   dw      $ + 2
	pop di
	pop ax
	add ax,[di]
	push ax
	NEXT

HEADING '@-'			; ( n1 a -- n )
  fetch_minus:  dw      $ + 2
	pop di
	pop ax
	sub ax,[di]
	push ax
	NEXT

HEADING 'CFA'			; ( pfa -- cfa )
  CFA:	dw two_minus + 2	; similar to an alias

HEADING '>BODY'			; ( cfa -- pfa )
  to_body: dw two_plus + 2	; similar to an alias

HEADING 'L>CFA'			; ( lfa -- cfa )
  l_to_cfa:     dw      $ + 2
	pop di
	inc di
	inc di
	mov al,[di]
	AND ax,1Fh		; count only, no flags such as immediate
	add di,ax
	inc di
	push di
	NEXT

HEADING 'L>NFA'			; ( lfa -- nfa )
  l_to_nfa: dw two_plus + 2

HEADING 'L>PFA'			; ( lfa -- pfa )
	dw	colon
	dw	l_to_cfa, to_body, EXIT

; 15-bit Square Root of a 31-bit integer
HEADING 'SQRT'			; ( d -- n )
		dw      $ + 2
	pop dx
	pop ax
	push si
	sub di,di
	mov si,di
	mov cx,16
  lr1:
	shl ax,1
	rcl dx,1
	rcl si,1
	shl ax,1
	rcl dx,1
	rcl si,1
	shl di,1
	shl di,1
	inc di
	CMP si,di
	jc lr2
	sub si,di
	inc di
  lr2:
	shr di,1
	LOOP lr1
	pop si
	push di
	NEXT


; Start Colon Definitions -- non-defining words
; Best for FORTH compiler to create defining words first -- minimizes forward references
; Most of these are used in the base dictionary

HEADING 'D<'			; ( d1 d2 -- f )
  d_less:       dw      colon		; CFA
	dw      d_minus			; PFA
	dw	zero_less, SWAP, DROP
	dw      EXIT			; semicolon

HEADING 'D='			; ( d1 d2 -- f )
	dw      colon
	dw      d_minus
	dw      d_zero_eq
	dw      EXIT

HEADING 'DABS'			; ( d -- |d| )
  DABS: dw      colon
	dw      cfa_dup, zero_less, q_branch	; IF <0 THEN NEGATE
	dw      dab1
	dw      DNEGATE
  dab1:
	dw      EXIT

HEADING 'DMAX'			; ( d1 d2 -- d )
	dw      colon
	dw      two_over, two_over, d_less
	dw      q_branch				; IF 1st < THEN SWAP
	dw      dmax1
	dw      two_swap
  dmax1:
	dw      two_drop
	dw      EXIT

HEADING 'DMIN'			; ( d1 d2 -- d )
  DMIN: dw      colon

	dw      two_over, two_over, d_less
	dw	zero_eq, q_branch			; IF 1st >= THEN SWAP
	dw      dmin1
	dw      two_swap
  dmin1:
	dw      two_drop
	dw      EXIT

HEADING '-LEADING'		; ( addr cnt -- addr' cnt' )
  m_LEADING:    dw      colon
	dw      cfa_dup, zero, two_to_r
  mld1:
	dw      OVER, c_fetch, blnk
	dw      cfa_eq, q_branch		; IF leading = space
	dw      mld2
	dw      SWAP, one_plus
	dw      SWAP, one_minus, do_branch
	dw      mld3
  mld2:
	dw      leave_lp
  mld3:
	dw      do_loop
	dw      mld1
	dw      EXIT

HEADING '0>'			; ( n -- f )
 zero_greater:	dw	colon
	dw	zero, greater
	dw	EXIT

HEADING '3DUP'			; ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
  three_dup:	dw	colon
	dw	cfa_dup, two_over, ROT
	dw	EXIT

HEADING 'ROLL'			; ( ... c -- ... )
	dw      colon
	dw      two_times, to_r, sp_fetch
	dw      eye, two_minus, plus_fetch
	dw      sp_fetch, cfa_dup, two_plus
	dw      r_from, backwards_cmove, DROP
	dw      EXIT

HEADING 'T*'			; ( d n -- t )
  tr_times:     dw      $ + 2
	mov [bp-2],si		; save thread pointer above 'R'
	mov [bp-4],bx		; save user pointer - in case implemented
	pop bx                  ; n
	pop si                  ; d hi
	pop di                  ; d lo
	mov ax,di
	mul bx          ; n * lo
	push ax                 ; bottom (lo) of tripple result
	mov cx,dx
	mov ax,si
	mul bx          ; n * hi
	add cx,ax               ; middle terms
	adc dx,0
	or si,si
	jge tt1         ; correct unsigned mul by n
	sub dx,bx
  tt1:
	or bx,bx
	jge tt2         ; correct unsigned mul by d
	sub cx,di
	sbb dx,si
  tt2:
	push cx			; result mid
	push dx			; result hi
	mov bx,[bp-4]		; restore registers
	mov si,[bp-2]
	NEXT

HEADING 'T/'			; ( t n -- d )
  tr_div:        dw      $ + 2
	pop di                  ; n
	pop dx                  ; hi
	pop ax                  ; med
	pop cx                  ; lo
	push si
	sub si,si
	or di,di
	jge td11
	neg di                  ; |n|
	inc si
  td11:
	or dx,dx
	jge td12
	dec si                 ; poor man's negate
	neg cx                 ; |t|
	adc ax,0
	adc dx,0
	neg ax
	adc dx,0
	neg dx
  td12:
	div di
	xchg ax,cx
	div di
	or si,si               ; sign of results
	jz td13                ; 0 or 2 negatives => positive
	neg ax                 ; dnegate
	adc cx,0
	neg cx
  td13:
	pop si
	push ax
	push cx
	NEXT

HEADING 'M*/'			; ( d1 n1 n2 -- d )
	dw      colon
	dw      to_r, tr_times, r_from, tr_div
	dw      EXIT

; No User variables -- all treated as normal variables for single user system
HEADING 'SPAN'			; actual # chrs rcvd.
  SPAN:	dw	create		; Normal variable
  span1:	dw	0

HEADING 'TIB'			; Text input starts at top of parameter stack
  TIB:		dw	create
  tib1:	dw	stack0

HEADING '#TIB'
  num_tib:      dw      create
  n_tib1:       dw      0

HEADING 'T_FLG'			; serial transmit flags
	dw	create		; cvariable
  tflg1:	db	0

HEADING 'R_FLG'			; serial receive flags
  rcv_flg:	dw	create	; cvariable
  rflg1:	db	0


; User / System variables

HEADING 'CONTEXT'		; ( -- a >> 2variable )
  CONTEXT:      dw      create
		dw      VOC, 0

HEADING 'CURRENT'		; ( -- a >> 2variable )
  CURRENT:      dw      create
		dw      VOC, 0

; Kept variable storage together to make PROTECT and EMPTY easier
HEADING 'HEADS'
  HEADS:	dw      create			; 'Links to remember'
  hds:          times 16 dw 0
  h1:		dw	very_end
  last1:	dw      0			; LFA of last word defined

HEADING 'FENCE'
  FENCE:        dw      create			; GOLDEN (protected)
  links: 	times 16 dw 0
  goldh:	dw      addr_end
  goldl:	dw      GOLDEN_LAST

; Now setup access to array elements as a variable
HEADING 'H'
  H:    dw      constant
	dw	h1      

HEADING 'LAST'
  LAST: dw      constant
	dw	last1

HEADING 'BUF0'                          ; only disk buffer(s), for now
  BUF0:  dw      create
  buf0a: times 1024 db spc		; currently in FORTH seg

HEADING 'BUF1'                          ; break buffer into 2 pieces for IBM
	dw      constant
	dw      BUF0 + 512 + 2


HEADING 'PATH'
  PATH:         dw      create
  path1:        db      'a:\'		; drive
  path2:        times 62 db spc		; path
		db      0

HEADING 'FNAME'
  FNAME:        dw      create
  fname1:       times 64 db spc		; name
		db      0

HEADING "'ABORT"
		dw      create
  abrt_ptr:     dw      QUT1

HEADING 'BASE'
  BASE:         dw      create
  base1:        dw      10		; decimal

T_BASE:         dw      create	; headerless variable
  t_ba:         dw      10

HEADING '>IN'
  tin:          dw      create
  tin1:         dw      0
  hndl1:        dw      0       ; temporary store before transfer to handle
				; used like BLK in normal systems
				; minimum value should be 5, max = FILES - 1
  qend1:        dw      0       ; at end of file for loading

HEADING 'STATE'
  STATE:        dw      create
  state1:       dw      0

HEADING 'HLD'
  HLD:  dw      create
  hld1  dw      0

HEADING 'RMD'
  RMD:  dw      create
	dw      0

HEADING 'ROWS'
		dw      create
  max_rows:     dw      0

; Include stored interrupt vector(s) for convenience
HEADING 'LINES'
		dw      create
  max_col:      dw      0
  _mode:        dw      0	; video setup information
  _page:        dw      0
  d_off:        dw      0       ; save divide 0 vector here
  d_seg:        dw      0
  sp_save:	dw	0	; save original SP
  ss_save:	dw	0

HEADING 'D_VER'			; DOS version for .com generate
  D_VER:        dw      create
  dver1:        dw      0

HEADING 'ABORT'
  ABORT:        dw      $ + 2	; ( x ... x -- )
  abrt: MOV sp,stack0		; clear parameter stack
	mov ax,[base1]		; reset temporary base to current
	mov [t_ba],ax
	sub ax,ax		; mark disk file as ended
	mov [qend1],ax
	push ax			; for parameter stack underflow
	MOV si,[abrt_ptr]	; goto 'quit'
	NEXT

HEADING 'SYSTEM'
  SYSTEM:       dw      $ + 2
	push es
	mov cx,[d_seg]		; restore div 0 vector
	mov dx,[d_off]
	xor ax,ax		; interrupt segment and address of vector 0
	mov es,ax
	mov di,ax
	mov [es:di],dx
	mov [es:di+2],cx
	mov dx,[sp_save]
	mov ax,[ss_save]
	pop es
	cli			; restore original SP
	mov sp,dx
	mov ss,ax
	sti
	ret			; return to MikeOS

HEADING '!CURSOR'		; ( row col -- )
	dw      $ + 2
	pop dx
	pop ax
	mov dh,al
	call os_move_cursor
	NEXT

HEADING '@CURSOR'		; ( -- row col )
  get_cursor:   dw      $ + 2
	call os_get_cursor_pos
	sub ax,ax
	mov al,dh
	push ax
	mov al,dl
	push ax
	NEXT

HEADING 'CLS'			; ( -- )
  CLS:  dw      $ + 2
	call os_clear_screen
	NEXT


; Polled 'type'
; Bits 0-3 of T_FLG control transmission; Bit 0 => XON

HEADING 'TYPE'			; ( a n -- )
  cfa_type:	dw	$ + 2
	pop cx			; character count
	pop di			; ds:di = data pointer
	push bx			; some BIOS destroy BX, DX and/or BP
	push bp
	or cx,cx		; normally 1 to 255 characters, always < 1025
	jle short ty2		; bad data or nothing to print
  ty1:
	test byte [tflg1],0Fh	; output allowed? XON-XOFF
	jne ty1
	mov al,[di]		; get character
	inc di
	mov ah,0x0E		; print to screen, TTY mode
	mov bh,[_page]		; ignored on newer BIOSs
	mov bl,7		; foreground, usually ignored
	int 10h
	loop ty1		; do for input count
  ty2:
	pop bp
	pop bx
	NEXT

HEADING 'EMIT'			; ( c -- )
  EMIT:		dw      $ + 2
	pop ax
	push bx			; some BIOS destroy BX, DX and/or BP
	push bp
	mov ah,0x0E
	mov bh,[_page]
	mov bl,7		; foreground, usually ignored
	int 10h
	pop bp
	pop bx
	NEXT

HEADING '/0'			; heading for generate
	dw      $ + 2
  div_0:                        ; divide zero interrupt
	sub ax,ax
	cwd
	mov di,1		; 80286 will repeat division !
	iret

; TERMINAL -- NON-VECTORED
; Note: buffer must be able to contain one more than expected characters.

HEADING 'EXPECT'		; ( a n -- )
  EXPECT:       dw      $ + 2
	pop cx                  ; count
	pop di                  ; buffer address
	push bx			; some BIOS destroy BX, DX and/or BP
	push bp
	sub ax,ax
	MOV [span1],ax
	or cx,cx                ; > 0, normally < 1025
	jg exp_loop
	jmp exp_end
  exp_loop:
	and byte [rflg1],7Fh	; clear special, b7
	xor ax,ax		; BIOS input, no echo
	int 16h
	cmp al,0		; extended/special ?
	je exp1			; yes
	cmp al,0xE0
	jne exp2
  exp1:
	or byte [rflg1],80h	; set special
	mov al,1		; get extended scan code in al
	xchg al,ah
	jmp short exp_store	; special cannot be a control
  exp2:				; normal input, limited control processing
	TEST byte [rflg1],1	; (b0=raw) skip test specials ?
	jnz exp_store

	CMP al,bs		; <back space> ?
	je exp5
	CMP al,del              ; <delete> ?
	jne exp7
  exp5:
	TEST word [span1],7FFFh	; any chr in buffer ?
	jnz exp6
	mov dl,bell		; echo (warning) bell
	jmp short exp_echo
  exp6:
	DEC word [span1]
	INC cx
	dec di
	test byte [rflg1],10h	; b4, echo allowed ?
	jnz exp10
	mov bh,[_page]
	mov bl,7		; foreground, usually ignored
	mov ax,0x0E08		; BS
	int 10h
	mov ax,0x0E20		; space
	int 10h
	mov ax,0x0E08		; BS
	int 10h
	jmp short exp10
  exp7:
	CMP al,cr		; <cr> ?
	jne exp9
	sub cx,cx               ; no more needed
	mov dl,' '		; echo space
	jmp short exp_echo
  exp9:
	cmp al,lf		; <lf> ?
	jne exp_store
	mov al,' '		; echo & store space
  exp_store:
	mov dl,al               ; echo input
	stosb
	INC word [span1]
	DEC cx
  exp_echo:
	test byte [rflg1],10h	; b4, echo allowed ?
	jnz exp10
	mov al,dl
	mov ah,0x0E		; send to monitor
	mov bh,[_page]
	mov bl,7		; foreground, usually ignored
	int 10h
  exp10:
	jcxz exp_end
	jmp exp_loop
  exp_end:
	sub ax,ax       ; end input marker
	stosb
	pop bp
	pop bx
	NEXT

HEADING 'KEY'			; ( -- c >> high byte = end marker = 0 )
  KEY:  dw      colon
	dw      rcv_flg, c_fetch, cfa_dup, one, cfa_or, rcv_flg, c_store  ; set special
	dw      zero, sp_fetch, one, EXPECT                     ; ( rflg c )
	dw      rcv_flg, c_fetch, bite
	db      80h
	dw      cfa_and, ROT, cfa_or	; extended receive &
	dw      rcv_flg, c_store	; echo flag maintained
	dw      EXIT

cfa_msg:	dw      colon
	dw      cfa_create, UNSMUDGE, sem_cod
  msg:
	db      232			; call pushes execute PFA on parameter stack
	dw      does - $ - 2
	dw      COUNT, cfa_type
	dw      EXIT

; Generic CRT Terminal

HEADING 'BELL'
  BELL: dw      msg
	db      1, bell

HEADING 'CR'
  CR:   dw      msg
	db      2, cr, lf

HEADING 'OK'
  OK:   dw      msg
	db      2, 'ok'

HEADING 'SPACE'
  SPACE:        dw      msg
	db      1, ' '

HEADING 'SPACES'		; ( n -- >> n=0 to 32767 )
  SPACES:       dw      colon
	dw      cfa_dup, zero_greater, q_branch	; IF number positive
	dw      sp2
	dw      cfa_dup, zero, two_to_r
  sp1:
	dw      SPACE, do_loop
	dw      sp1
  sp2:
	dw      DROP
	dw      EXIT

HEADING 'HERE'			; ( -- h )
  HERE:         dw      $ + 2
	PUSH word [h1]
	NEXT

h_p_2:          dw      colon    ; ( -- h+2 )
		dw      HERE, two_plus
		dw      EXIT

HEADING 'PAD'			; ( -- a >> a=here+34, assumes full header )
  PAD:          dw      $ + 2
	mov ax,[h1]
	ADD ax,34		; max NFA size + LFA
	push ax
	NEXT

; Pictured Number output

HEADING 'HOLD'			; ( n -- )
  HOLD:         dw      $ + 2
	DEC word [hld1]
	MOV di,[hld1]
	pop ax
	stosb
	NEXT

dgt1:   dw      $ + 2                   ; ( d -- d' c )
	pop ax
	pop cx
	sub dx,dx
	mov di,[base1]		; no overflow should be possible
	DIV di                  ; just in case base cleared
	xchg ax,cx
	DIV di
	push ax
	push cx
	CMP dl,10               ; dx = Rmd: 0 to Base
	jc dgt2                 ; U<
	add dl,7                ; 'A' - '9'
  dgt2:
	add dl,'0'		; to ASCII
	push dx
	NEXT

HEADING '<#'			; ( d -- d )
  st_num:       dw      colon
	dw      PAD, HLD, store
	dw      EXIT

HEADING '#'			; ( d -- d' )
  add_num:      dw      colon
	dw      dgt1, HOLD
	dw      EXIT

HEADING '#>'			; ( d -- a n )
  nd_num:       dw      colon
	dw      two_drop, HLD, fetch
	dw      PAD, OVER, minus
	dw      EXIT

HEADING 'SIGN'			; ( n d -- d )
  SIGN: dw      colon
	dw      ROT, zero_less, q_branch		; IF negative
	dw      si1
	dw      bite
	db      '-'
	dw      HOLD
  si1:
	dw      EXIT

HEADING '#S'			; ( d -- 0 0 )
  nums:	dw      colon
  nums1:
	dw      add_num, two_dup, d_zero_eq
	dw      q_branch				; UNTIL nothing left
	dw      nums1
	dw      EXIT

HEADING '(D.)'			; ( d -- a n )
  paren_d:      dw      colon
	dw      SWAP, OVER, DABS
	dw      st_num, nums
	dw      SIGN, nd_num
	dw      EXIT

HEADING 'D.R'			; ( d n -- )
  d_dot_r:      dw      colon
	dw      to_r, paren_d, r_from, OVER, minus, SPACES, cfa_type
	dw      EXIT

HEADING 'U.R'			; ( u n -- )
  u_dot_r:      dw      colon
	dw      zero, SWAP, d_dot_r
	dw      EXIT

HEADING '.R'			; ( n n -- )
	dw      colon
	dw      to_r, s_to_d, r_from, d_dot_r
	dw      EXIT

HEADING 'D.'			; ( d -- )
  d_dot:        dw      colon
	dw      paren_d, cfa_type, SPACE
	dw      EXIT

HEADING 'U.'			; ( u -- )
  u_dot:        dw      colon
	dw      zero, d_dot
	dw      EXIT

HEADING '.'			; ( n -- )
  dot:  dw      colon
	dw      s_to_d, d_dot
	dw      EXIT

; String output

; ( f -- a n >> return to caller if true )
; ( f --     >> skip caller if false )
q_COUNT: dw      $ + 2
	MOV di,[bp+0]	; get pointer to forth stream
	sub ax,ax
	mov al,[di]
	inc ax
	ADD [bp+0],ax	; bump pointer past string
	pop dx
	or dx,dx
	jnz cnt_1
	JMP exit1
  cnt_1:
	dec ax          ; restore count
	inc di          ; get address
	push di
	push ax
	NEXT

; ( f --     >> return to caller if false )
abortq: dw      colon
	dw      q_COUNT, h_p_2, COUNT, cfa_type
	dw      SPACE, cfa_type, CR
	dw      ABORT

dotq:   dw      colon
	dw      one, q_COUNT, cfa_type
	dw      EXIT

; 32-bit Number input

q_DIGIT: dw      $ + 2                           ; ( d a -- d a' n f )
	sub dx,dx
	pop di          ; get addr
	inc di          ; next chr
	push di         ; save
	mov al,[di]     ; get this chr
	cmp al,58       ; chr U< '9'+ 1
	jc dgt4
	cmp al,65
	jc bad_dgt
	SUB al,7        ; 'A' - '9'
  dgt4:
	SUB al,'0'
	jc bad_dgt
	CMP al,[t_ba]
	jnc bad_dgt
	cbw
	push ax
	INC dx
  bad_dgt:
	push dx
	NEXT

D_SUM:  dw      $ + 2                           ;  ( d a n -- d' a )
	pop di
	pop dx
	pop ax
	pop cx
	push dx
	MUL word [t_ba]
	xchg ax,cx
	MUL word [t_ba]
	ADD ax,di
	ADC cx,dx
	pop dx
	push ax
	push cx
	push dx
	NEXT

HEADING 'CONVERT'		; ( d a -- d' a' )
  CONVERT:      dw      colon
  dgt8:
	dw      q_DIGIT, q_branch	; IF
	dw      dgt9
	dw      D_SUM, HLD, one_plus_store
	dw      do_branch
	dw      dgt8
  dgt9:
	dw      EXIT

HEADING 'NUMBER'		; ( a -- n, d )
  NUMBER:       dw      colon
	dw      cell, -513, HLD, store			; max length * -1
	dw      cfa_dup, one_plus, c_fetch, bite	; 1st chr '-' ?
	db      '-'
	dw      cfa_eq, cfa_dup, to_r, q_branch	; IF, save sign & pass up
	dw      num1
	dw	one_plus
  num1:
	dw      zero, cfa_dup, ROT			; ( 0. a' )
  num2:
	dw      CONVERT, cfa_dup, c_fetch, cfa_dup    ; ( d end chr[end] )
	dw      dclit
	db      43, 48                          ; chr[end] '+' to '/'
	dw      WITHIN, SWAP, bite
	db      58                              ;       or ':' ?
	dw      cfa_eq, cfa_or, q_branch
	dw      num3
	dw      HLD, false_store, do_branch	; yes = double
	dw      num2
  num3:
	dw      c_fetch, abortq			; word ends zero
	db      1,'?'
	dw      r_from, q_branch		; IF negative, NEGATE
	dw      num4
	dw      DNEGATE
  num4:
	dw      HLD, fetch, zero_less, q_branch
	dw      num5
	dw      RMD, store                      ; single = store high cell
  num5:
	dw      BASE, T_BASE, XFER
	dw      EXIT


; Floppy variables

; Do NOT support DOS functions: Delete or Rename

; This construct turns a memory location into a "variable" that fits in other definitions
HEADING 'HNDL'
  HNDL: dw      constant
	dw      hndl1

HEADING '?END'
  q_END: dw      constant
	dw      qend1

HEADING 'FDSTAT'
  FDSTAT:       dw      create
  fdst1:        dw      0       ; error flag, may be extended later

HEADING 'FDWORK'
  FDWORK:       dw      create

  fdwk1:        dw      0       ; error, handle, or count low
  fdwk2:        dw      0       ; high word of count when applicable

HEADING ".AZ"			; ( a -- )
  dot_az:       dw      colon
	dw      dclit                   ; print ASCII zero terminated string
	db      64, 0
	dw      two_to_r		; DO
  dp1:
	dw      cfa_dup, c_fetch, q_DUP
	dw      q_branch, dp2			; IF
	dw      EMIT, one_plus
	dw      do_branch, dp3			; ELSE
  dp2:
	dw      leave_lp
  dp3:						; THEN
	dw      do_loop, dp1		; LOOP
	dw      DROP
	dw      EXIT

del_lf:		dw      $ + 2           ; ( a n -- )
	pop cx
	pop di
	mov dx,di
	jcxz dlf3
	inc cx          ; results of last comparison not checked
	push cx
	mov ax,200Ah    ; ah = replacement = space, al = search = LineFeed
  dl001:
	repne scasb
	jcxz dlf1
	mov [di-1],ah
	jmp dl001
  dlf1:
	pop cx
	mov di,dx
	mov al,09       ; remove tab characters
  dl002:
	repne scasb
	jcxz dlf2
	mov [di-1],ah
	jmp dl002
  dlf2:
	cmp byte [di-1],26  ; eof marker
	jne dlf3
	mov [di-1],ah
  dlf3:
	NEXT

GET_DISK:       dw      colon   ; ( a n -- )
	dw      BLANK, SPACE, ABORT

; Interpreter

do_wrd01:  dw      $ + 2           ; ( c a n -- a=here+2 )
	pop cx
	pop di
  do_wrd02:		; Entry with just ( c -- ), DI & CX set
	pop ax          ; chr
	push ax
	push si         ; execute pointer
	ADD di,[tin1]
	SUB cx,[tin1]	; number of chrs left
	ADD [tin1],cx	; set pointer to end of input
	SUB si,si       ; set z flag
	REP scasb       ; del leading chrs
	mov si,di       ; save beginning
	je wrd01        ; cx = 0 = no significant chrs
	dec si          ; back up to 1st significant chr
	REPne scasb
	jne wrd01       ; input ended in significant chr
	dec di          ; back up to last significant chr
  wrd01:
	SUB [tin1],cx		; back pointer to end this word
	cmp byte [di-1],cr	; ends in <cr> ?
	jne wrd02		; yes = do not include in word
	dec di
  wrd02:
	SUB di,si       ; number chr in this word
	MOV cx,di
	MOV di,[h1]
	inc di
	inc di
	mov dx,di       ; adr = here + 2
	push cx         ; save count
	MOV ax,cx
	stosb           ; counted string format
	REP movsb       ; count = 0 = do not move anything
	sub ax,ax       ; terminate with bytes 0, 0
	stosw
	pop cx
	pop si          ; retrieve Forth execute pointer
	or cx,cx        ; any chrs ?
	jnz wrd03	; yes = exit WORD
	mov cx,[n_tib1]	; may be empty disk line
	cmp cx,[tin1]	; any more ?
	jg strm2	; yes = try next word
  wrd03:
	pop ax          ; remove test chr
	push dx         ; set here+2
	JMP exit1

STREAM: dw      $ + 2   ; ( c -- c )
	MOV cx,[n_tib1]
	mov di,[hndl1]
	or di,di
	jnz strm2       ; disk is active source
	MOV di,[tib1]	; text input buffer [TIB]
  strm1:
	jmp do_wrd02	; Skip GET DISK buffer & go directly to WORD
  strm2:
	mov di, buf0a	; disk buffer
	mov ax,[tin1]	; still in buf0 ?
	cmp ax,512
	jl strm1		; yes = get next word
	test byte [qend1],0xff	; at end of file ?
	jne strm1
	mov dx,512
	sub ax,dx       ; fix pointers
	mov [tin1],ax	; >IN
	sub cx,dx
	mov [n_tib1],cx	; #TIB
	push di         ; BUF0 for do_wrd01
	push cx         ; n=ctr, position
	mov ax,di
	add ax,512      ; buf1 = buf0 + 512
	push ax         ; BUF1 for get_disk
	push dx         ; count = 512
	xchg si,ax
	mov cx,256
	rep movsw       ; move 512 bytes from buf1 to buf0
	mov si,ax       ; restore FORTH exec pointer
	NEXT            ; ( c a=buf0 n=#tib a=buf1 cnt=512 )

HEADING 'WORD'			; ( c -- a )
  cfa_word:	dw colon
	dw      STREAM			; will go directly to do_wrd02
	dw      GET_DISK		; may abort ( c a0 n )
	dw      do_wrd01		; EXIT not needed

; Dictionary search

HASH:                           ; ( na v -- na offset )
	dw      $ + 2
	pop ax
	AND ax,0Fh      ; must have a vocabulary (1-15) to search, v <> 0
	shl ax,1	; 2* vocab, different chains for each
	pop di
	push di		; hash = 2 * vocab + 1st char of word
	ADD al,[di+1]	; 1st char (not count)
	AND al,1Eh	; (B_HDR - 2) even, mod 32 => 16 chains
	push ax
	NEXT

; Note - no address can be less than 0100h
FIND_WD:			; ( na offset -- na lfa,0 )
	dw      $ + 2
	mov [bp-2],si		; temporary save XP - below return
	pop di			; chain offset
	pop ax			; address of counted string to match
	push ax
	ADD di, hds		; address of beginning of hash chain
	push di
  fnd1:
	pop di			;
	mov di,[di]		; get next link
	push di			; last link in chain = 0
	or di,di
	jz fnd2         ; end of chain, not found
	inc di		; goto count/flags byte
	inc di
	MOV cx,[di]
	AND cx,3Fh      ; count (1F) + smudge (20)
	mov si,ax
	CMP cl,[si]
	jne fnd1        ; wrong count, try next word
	inc di		; to beginning of text
	inc si
	REP CMPSB	; compare the two strings
	jne fnd1        ; not matched, try next word
  fnd2:				; exit - found or chain exhausted
	mov si,[bp-2]		; restore execution pointer
	NEXT

; LFA > 0100h (current lowest value is 0103h), can be used as "found" flag
; HEADING 'FIND'		; ( na -- cfa lfa/f if found || na 0 if not )
  FIND:	dw      colon
	dw      CONTEXT, two_fetch	; ( na v.d )
  find1:						; BEGIN
	dw	two_dup, d_zero_eq, cfa_not, q_branch	; WHILE, still vocab to search
	dw	find3
	dw	two_dup, zero, bite
	db	16
	dw	tr_div, two_to_r, DROP, HASH, FIND_WD 
	dw	two_r_from, ROT, q_DUP
	dw	q_branch, find2			; IF found
	dw	m_ROT, two_drop, SWAP, DROP
	dw	cfa_dup, l_to_cfa, SWAP, EXIT
  find2:						; THEN
	dw	do_branch					; REPEAT, not found yet
	dw	find1
  find3:
	dw      two_drop, zero, EXIT			; not found anywhere

HEADING 'DEPTH'			; ( -- n )
  DEPTH:        dw      $ + 2
	mov ax,stack0
	SUB ax,sp
	sar ax,1
	dec ax			; 0 for underflow protection
	push ax
	NEXT

q_STACK: dw      colon
	dw      DEPTH, zero_less, abortq
	db      qsk2 - $ - 1
	db      'Stack Empty'
  qsk2:
	dw      EXIT


; Interpreter control - notice that this is not reentrant
;  uses variables - #TIB, >IN & HNDL - to manipulate input (text or disk)

HEADING 'INTERPRET'
  INTERPRET:    dw      colon
  ntrp1:					; BEGIN
	dw	blnk, cfa_word
	dw	cfa_dup, c_fetch, q_branch	; WHILE - text left in input buffer
	dw	ntrp6
	dw	FIND, q_DUP, q_branch	; IF found in context vocabulary, process it
	dw	ntrp3
	dw	one_plus, fetch, zero_less		; Immediate flag in high byte for test
	dw	STATE, fetch, cfa_not, cfa_or
	dw	q_branch, nrtp2		; IF Immediate or not compiling ( cfa )
	dw      EXECUTE, q_STACK, do_branch
	dw	ntrp5			; ELSE compiling => put into current word
  nrtp2:
	dw      comma, do_branch
	dw      ntrp5			; THEN
  ntrp3:				; ELSE try a number - may abort ( na )
	dw      NUMBER
	dw	STATE, fetch, q_branch		; IF compiling => put into current word
	dw      ntrp5
	dw	HLD, fetch, zero_less			; IF single precision (includes byte)
	dw      q_branch
	dw      ntrp4
	dw      LITERAL, do_branch			; ELSE double precision
	dw      ntrp5
  ntrp4:
        dw      cell, dblwd, comma, comma, comma        ; COMPILE dblwd
						; THEN	; THEN
  ntrp5:				; THEN
	dw      do_branch, ntrp1			; REPEAT until stream exhausted
  ntrp6:
	dw	DROP, EXIT			; Exit and get more input

HEADING 'QUERY'
  QUERY:        dw      colon			; get input from keyboard or disk stream
	dw      TIB, fetch, L_WIDTH, EXPECT
	dw      SPAN, num_tib, XFER
	dw      zero_dot, tin, two_store
	dw      EXIT

R_RESET:        dw      $ + 2
	MOV bp,first
	NEXT

HEADING 'QUIT'			; ( -- )
  QUIT: dw      colon
  QUT1: dw      STATE, false_store		; start by interpreting user input
  qt02:						; BEGIN
	dw	R_RESET, QUERY, INTERPRET
	dw	OK, CR
	dw	do_branch, qt02		; AGAIN => Endless loop
					; Note no Exit needed


; Vocabulary lists

HEADING 'ID.'			; ( lfa -- >> prints name of word at link addr )
  id_dot:       dw      colon
	dw      l_to_nfa, cfa_dup, c_fetch, bite
	db      1Fh
	dw      cfa_and, zero
	dw      two_to_r		; DO for len of word (some versions do not store whole word)
  id1:
	dw      one_plus, cfa_dup, c_fetch	; ( adr chr )
	dw      cfa_dup, blnk, less, q_branch	; IF control character, print caret
	dw      id2
	dw      dotq
	db      1,'^'
	dw      bite
	db      64
	dw      plus
  id2:						; THEN
	dw      EMIT
	dw      do_loop
	dw      id1			; LOOP
	dw      DROP, SPACE, SPACE
	dw      EXIT


; Compiler

HEADING 'IMMEDIATE'
	dw      colon
	dw      LAST, fetch, l_to_nfa
	dw      cfa_dup, c_fetch, cell, 80h	; set bit 7 of the count-flag byte
	dw      cfa_or, SWAP, c_store
	dw      EXIT

HEADING 'ALLOT'			; ( n -- )
  ALLOT:        dw      colon
	dw	SP0, OVER, HERE, plus, bite
	db	178				; full head(34) + pad(80) + min stack(64)
	dw	plus, u_less, abortq
	db	alt3 - $ - 1
	db	'Dictionary full'
  alt3:
	dw	H, plus_store, EXIT

HEADING 'C,'			; ( uc -- )
  c_comma:      dw      colon
	dw      HERE, c_store, one, ALLOT
	dw      EXIT

HEADING ','			; ( u -- )
  comma:        dw      colon
	dw      HERE, store, two, ALLOT
	dw      EXIT

HEADING '?CELL'			; ( n -- n f,t=word )
  q_CELL:        dw      colon
	dw      cfa_dup, bite
	db      -128
	dw      cell, 128
	dw      WITHIN, zero_eq
	dw      EXIT

IMMEDIATE
HEADING 'LITERAL'		; ( n -- )
  LITERAL:      dw      colon
	dw      q_CELL, q_branch, lit1		; IF
        dw      cell, cell, comma, comma        ; COMPILE cell
	dw      do_branch, lit2			; ELSE
  lit1:
        dw      cell, bite, comma, c_comma      ; COMPILE byte
  lit2:						; THEN
	dw      EXIT

IMMEDIATE
HEADING 'COMPILE'
	dw	colon
	dw	blnk, cfa_word, FIND	; (cfa t || na 0)
	dw	cfa_not, abortq
	db	cmp1 - $ - 1
	db	'?'
  cmp1:
	dw	LITERAL, sem_cod
  COMPILE:
	db      232			; call executes comma (below)
	dw      does - $ - 2
	dw      comma			; puts CFA of next word into dictionary
	dw      EXIT

IMMEDIATE
HEADING "'"			; ( return or compile CFA as literal )
  tic:  dw      colon
	dw	blnk, cfa_word, FIND		; ( na 0 || cfa lfa )
        dw	cfa_not, abortq
	db      1,'?'
	dw      STATE, fetch, STAY
	dw      LITERAL, EXIT			; ( compiling => put in-line )

HEADING ']'			; ( -- >> set STATE for compiling )
  r_bracket:	dw      $ + 2
	mov ax,1  
	mov [state1],ax		; compiling
	NEXT

IMMEDIATE
HEADING '['			; ( -- )
  l_bracket:	dw      $ + 2
	sub ax,ax  
	mov [state1],ax		; interpreting
	NEXT
 
HEADING 'SMUDGE'
  SMUDGE:       dw      colon
        dw      LAST, fetch, l_to_nfa, cfa_dup
        dw      c_fetch, blnk			; set bit 5
        dw      cfa_or, SWAP, c_store
        dw      EXIT
 
HEADING 'UNSMUDGE'
  UNSMUDGE:	dw      colon
	dw	LAST, fetch, l_to_nfa, cfa_dup
	dw	c_fetch, bite			; clear bit 5
	db	0DFh
	dw	cfa_and, SWAP, c_store
	dw	EXIT

IMMEDIATE
HEADING ';'
	dw      colon
	dw      cell, EXIT, comma		; COMPILE EXIT 
	dw	l_bracket, UNSMUDGE
	dw      EXIT

; Chains increase speed of compilation and
;  allow multiple vocabularies without special code.
; User vocabularies can also have separate chains to keep definitions separate.
; 4 chains would be sufficient for a minimum kernel,
;  but vocabularies would be limited to max. of 4
; 8 chains => maximum of 8 vocabularies, good for small systems
; 16 chains best choice for medium to large systems and for cross compiling
; 32 chains are marginally better for larger systems, but more is not always best
; Each vocabulary = nibble size => maximum number of 7 vocabularies,
;  15 (if pre-multiply*2)
; nibble in cell => maximum search path of 4 vocabularies
; dword => 8 nibbles => 8 search vocabularies
; Note: can "seal" portion of dictionary by eliminating FORTH from search string

HEADING 'VOCABULARY'		; ( d -- )
	dw      colon
	dw      cfa_create, SWAP, comma, comma, UNSMUDGE, sem_cod
  vocabulary:
	db      232                     ; call
	dw      does - $ - 2
	dw      two_fetch, CONTEXT, two_store
	dw      EXIT

HEADING 'ASSEMBLER'
  ASSEMBLER:    dw      vocabulary, 0012h, 0	; search order is low adr lsb to high adr msb

HEADING 'EDITOR'
	dw      vocabulary, 0013h, 0

HEADING 'FORTH'
	dw      vocabulary, VOC, 0		; VOC = 00000001

HEADING 'DEFINITIONS'
	dw      colon
	dw      CONTEXT, two_fetch, CURRENT, two_store
	dw      EXIT

HEADING ';code'
  sem_cod:      dw      colon
	dw      r_from
	dw      LAST, fetch, l_to_cfa, store
	dw      EXIT

IMMEDIATE
HEADING ';CODE'
	dw      colon
	dw      cell, sem_cod, comma		; COMPILE ;code
	dw	r_from, DROP, ASSEMBLER
	dw      l_bracket, UNSMUDGE
	dw      EXIT

HEADING 'CVARIABLE'
	dw	colon
	dw	cfa_create, zero, c_comma, UNSMUDGE
	dw	EXIT

HEADING 'VARIABLE'
  VARIABLE:     dw      colon
	dw      cfa_create, zero, comma, UNSMUDGE
	dw      EXIT

HEADING '2VARIABLE'
	dw      colon
	dw      VARIABLE, zero, comma
	dw      EXIT

IMMEDIATE
HEADING 'DCLIT'	; ( c1 c2 -- )
	dw      colon
	dw      cell, dclit, comma	; COMPILE dclit
	dw      SWAP, c_comma, c_comma  ; reverse bytes here instead of
	dw      EXIT                    ;  execution time!

HEADING 'ARRAY'			; ( #bytes -- )
	dw      colon
	dw      cfa_create, HERE, OVER
	dw      ERASE, ALLOT, UNSMUDGE
	dw      EXIT


; Compiler directives - conditionals

; Absolute [long] structures
; Short structures did not save that much space, longer execution time
; Note: the code contains 47 Forth ?branch (IF) statements
;       19 do_branch -- other conditionals such as THEN and REPEAT
;       9 normal loops, 3 /loops and 1 +loop

IMMEDIATE
HEADING 'IF'			; ( -- a )
  cfa_if:	dw	colon
	dw	cell, q_branch, comma	; COMPILE ?branch
	dw      HERE, zero, comma
	dw      EXIT

IMMEDIATE
HEADING 'THEN'			; ( a -- )
  THEN:	dw      colon
	dw      HERE, SWAP, store
	dw      EXIT

IMMEDIATE
HEADING 'ELSE'			; ( a1 -- a2 )
	dw      colon
	dw	cell, do_branch, comma	;  COMPILE branch
	dw      HERE, zero, comma 
	dw      SWAP, THEN, EXIT

IMMEDIATE
HEADING 'BEGIN'			; ( -- a )
	dw      colon
	dw      HERE
	dw      EXIT

IMMEDIATE
HEADING 'UNTIL'			; ( a -- | f -- )
	dw      colon
	dw      cell, q_branch, comma	; COMPILE ?branch
	dw      comma, EXIT

IMMEDIATE
HEADING 'AGAIN'			; ( a -- )
  AGAIN:	dw      colon
	dw      cell, do_branch, comma	; COMPILE branch
	dw      comma, EXIT

IMMEDIATE
HEADING 'WHILE'
	dw      colon
	dw      cfa_if, SWAP
	dw      EXIT

IMMEDIATE
HEADING 'REPEAT'
	dw      colon
	dw      AGAIN, THEN
	dw      EXIT

; Switch Support - part 2 (compiling)

IMMEDIATE
HEADING 'SWITCH'
	dw      colon
	dw      cell, do_switch, comma	; COMPILE switch
	dw      cell, do_branch, comma	; COMPILE branch
	dw      HERE, cfa_dup, zero, comma
	dw      EXIT

IMMEDIATE
HEADING 'C@SWITCH'
	dw      colon
	dw      cell, c_switch, comma	; COMPILE c_switch
	dw      cell, do_branch, comma	; COMPILE branch
	dw      HERE, cfa_dup, zero, comma
	dw      EXIT

IMMEDIATE
HEADING '{'			; ( a1 a2 n -- a1 h[0] )
	dw      colon
	dw      comma, HERE, zero
	dw      comma, cfa_dup, two_minus, ROT
	dw      store, r_bracket
	dw      EXIT

IMMEDIATE
HEADING '}'
	dw      colon
	dw      cell, EXIT, comma	; COMPILE EXIT
	dw      EXIT

IMMEDIATE
HEADING 'ENDSWITCH'
	dw      colon
	dw      DROP, THEN
	dw      EXIT

; Compiler directives - looping

IMMEDIATE
HEADING 'DO'			; ( -- a )
	dw      colon
	dw      cell, two_to_r, comma	; COMPILE 2>R
	dw      HERE, EXIT

IMMEDIATE
HEADING 'LOOP'			; ( a -- )
	dw      colon
	dw      cell, do_loop, comma	; COMPILE loop
	dw      comma, EXIT

IMMEDIATE
HEADING '+LOOP'			; ( a -- )
	dw      colon
	dw      cell, plus_loop, comma	; COMPILE +loop
	dw      comma, EXIT

IMMEDIATE
HEADING '/LOOP'			; ( a -- )
	dw      colon
	dw      cell, slant_loop, comma	; COMPILE /loop
	dw      comma, EXIT


; Miscellaneous

IMMEDIATE
HEADING 'DOES>'
	dw      colon
	dw      cell, sem_cod, comma	; COMPILE ;code
	dw      cell, 232, c_comma	; CALL does - leaves PFA on stack
	dw      cell, does - 2, HERE
	dw      minus, comma
	dw      EXIT

HEADING 'EMPTY'			; ( -- )
  EMPTY:        dw      colon
	dw      FENCE, HEADS, bite
	db      36
	dw      front_cmove
	dw      EXIT

; Updates HERE and HEADS, but not LAST
HEADING 'FORGET'
	dw      colon
	dw      blnk, cfa_word, CURRENT, c_fetch, HASH, FIND_WD	; ( na v -- na lfa,0 )
	dw      q_DUP, cfa_not, abortq
	db      1,'?'
	dw      SWAP, DROP, cfa_dup			; (lfa lfa)
	dw      cell, goldh, fetch
	dw      u_less					; ( protected from deletion )
	dw      abortq
	db      5,"Can't"
	dw      H, store				; new HERE = LFA
	dw      H, HEADS, two_to_r			; DO for 16 chains
  fgt1:
	dw      eye, fetch
  fgt2:						; BEGIN
	dw      cfa_dup, HERE, u_less
	dw      cfa_not, q_branch, fgt3		; WHILE defined after this word, go down chain
	dw      fetch, do_branch, fgt2		; REPEAT
  fgt3:
	dw      eye, store, two, slant_loop, fgt1	; /LOOP update top of chain, do next
	dw      EXIT

HEADING 'PROTECT'		; ( -- )
  PROTECT:      dw      colon
	dw      HEADS, FENCE, bite
	db      36
	dw      front_cmove
	dw      EXIT

HEADING 'STRING'		; ( -- )
  STRING:       dw      colon
	dw      bite
	db      -2
	dw      ALLOT, bite
	db      '"'
	dw      cfa_word, c_fetch, two_plus
	dw      one_plus, ALLOT
	dw      EXIT

HEADING 'MSG'
	dw      colon
	dw      cfa_msg, STRING
	dw      EXIT

IMMEDIATE
HEADING 'ABORT"'
	dw      colon
	dw      STATE, fetch, q_branch, abtq1	; IF ( -- ) compiling
	dw      cell, abortq, comma		; COMPILE abort" and put string into dictionary
	dw      STRING, do_branch, abtq3
  abtq1:
	dw      bite				; ELSE ( f -- ), interpret must have flag
	db      '"'
	dw      cfa_word, SWAP, q_branch, abtq2		; IF flag is true, print string and abort
	dw      COUNT, cfa_type, ABORT
	dw      do_branch, abtq3
  abtq2:						; ELSE drop string address
	dw      DROP
  abtq3:					; THEN	THEN
	dw      EXIT

IMMEDIATE
HEADING '."'
	dw      colon
	dw      STATE, fetch, q_branch, dq1	; IF compiling
	dw      cell, dotq, comma		; COMPILE ." and put string into dictionary
	dw      STRING, do_branch, dq2
  dq1:						; ELSE print following string
	dw      bite
	db      '"'
	dw      cfa_word, COUNT, cfa_type
  dq2:						; THEN
	dw      EXIT

HEADING '?'			; ( a -- )
  question:     dw      colon
	dw      fetch, dot
	dw      EXIT


; Set operating bases

HEADING 'BASE!'			; ( n -- )
  base_store:   dw      colon
	dw      cfa_dup, BASE, store
	dw      T_BASE, store
	dw      EXIT

HEADING '.BASE'			; ( -- >> print current base in decimal )
	dw      colon
	dw      BASE, fetch, cfa_dup, bite
	db      10
	dw      BASE, store, dot
	dw      BASE, store
	dw      EXIT

HEADING 'DECIMAL'
  DECIMAL:      dw      colon
	dw      bite
	db      10
	dw      base_store
	dw      EXIT

HEADING 'HEX'
  HEX:  dw      colon
	dw      bite
	db      16
	dw      base_store
	dw      EXIT

HEADING 'OCTAL'
	dw      colon
	dw      bite
	db      8
	dw      base_store
	dw      EXIT

HEADING 'BINARY'
	dw      colon
	dw      bite
	db      2
	dw      base_store
	dw      EXIT

IMMEDIATE
HEADING '$'
	dw      colon
	dw      bite
	db      16
	dw      T_BASE, store
	dw      EXIT

IMMEDIATE
HEADING 'Q'
	dw      colon
	dw      bite
	db      8
	dw      T_BASE, store
	dw      EXIT

IMMEDIATE
HEADING '%'
	dw      colon
	dw      bite
	db      2
	dw      T_BASE, store
	dw      EXIT

IMMEDIATE
HEADING '('
	dw      colon
	dw      bite
	db      ')'
	dw      cfa_word, DROP
	dw      EXIT


; String operators, help with Screen Editor

HEADING '-MATCH'		; ( a n s n -- a t )
	dw      $ + 2
	pop dx
	pop ax
	pop cx
	pop di
	PUSH bx
	push si
	mov bx,ax
	MOV al,[bx]
	DEC dx
	SUB cx,dx
	jle mat3
	INC bx
  mat1:
	REP scasb
	jne mat3        ; 1st match
	push cx
	push di
	MOV si,bx
	mov cx,dx
	REP CMPSB
	je mat2
	pop di          ; No match
	pop cx
	JMP mat1
  mat2:
	pop ax          ; Match
	pop ax
	sub ax,ax
  mat3:
	pop si
	pop bx
	push di
	push ax
	NEXT

HEADING '?PRINTABLE'		; ( c -- f,t=printable )
  q_PRINTABLE:   dw      colon
	dw      dclit
	db      spc, '~'+1
	dw      WITHIN
	dw      EXIT

IMMEDIATE
HEADING '\'
	dw      colon
	dw      bite
	db      cr
	dw      cfa_word, DROP
	dw      EXIT


; Vocabulary lists

HEADING 'H-LIST'		; ( n -- )
  hlist:	dw      colon
	dw      two_times, HEADS, plus_fetch    ; ( list head )
	dw      CR
  hlst1:					; BEGIN
	dw      q_DUP, q_branch, hlst3		; WHILE
	dw      cfa_dup, id_dot, fetch
	dw      get_cursor, bite		; test column
	db      64
	dw      greater, q_branch, hlst2 ; IF
	dw      CR
  hlst2:				; THEN
	dw      DROP 				; drop row/line
	dw      do_branch, hlst1		; REPEAT
  hlst3:
	dw      EXIT

; Headerless, only used by WORDS below
; returns highest lfa contained in copy of HEADS at PAD
MAX_HEADER:     dw      colon   ; ( -- index max.lfa )
	dw      zero_dot
	dw      B_HDR, zero, two_to_r
  mh1:
	dw      cfa_dup, PAD, eye, plus_fetch
	dw      u_less, q_branch		; ( new max lfa )
	dw      mh2
	dw      two_drop, eye, PAD
	dw      eye, plus_fetch
  mh2:
	dw      two, slant_loop
	dw      mh1
	dw      EXIT

HEADING 'VLIST'			; ( -- >> lists the words in the context vocabulary )
	dw      colon
	dw      HEADS, PAD, B_HDR		; copy HEADS to PAD
	dw      front_cmove, CR
  wds1:						; BEGIN
	dw      MAX_HEADER, cfa_dup, q_branch	; WHILE a valid lfa exists at PAD
	dw      wds4
	dw      two_dup, two_plus		; ( index lfa index nfa )
	dw      CONTEXT, fetch, HASH		; just first vocab
	dw      SWAP, DROP			; ( index lfa index index' )
	dw      cfa_eq, q_branch		; IF in this vocab, display name
	dw      wds2
	dw      cfa_dup, id_dot
  wds2:					; THEN
	dw      fetch, SWAP, PAD
	dw      plus, store			; update PAD, working header
	dw      get_cursor, bite
	db      64
	dw      greater, q_branch		; IF near end of line, send new line
	dw      wds3
	dw      CR
  wds3:					; THEN
	dw      DROP, do_branch
	dw      wds1
  wds4:						; REPEAT
	dw      two_drop
	dw      EXIT


; Miscellaneous extensions

HEADING '.S'
  dot_s:        dw      colon
	dw      q_STACK, DEPTH, CR, q_branch	; IF
	dw      dots2
	dw      sp_fetch, cell, stack0 - 4, two_to_r
  dots1:
	dw      eye, fetch, u_dot, bite
	db      -2
	dw      slant_loop
	dw      dots1
  dots2:
	dw      dotq
	db      dots3 - $ - 1
	db      ' <--Top '
  dots3:
	dw      EXIT

HEADING 'LOWER>UPPER'		; ( k -- k' )
	dw      colon
	dw      cfa_dup, dclit
	db      'a', 'z'+1
	dw      WITHIN, q_branch
	dw      l_u1
	dw      blnk, minus		; if lower case ASCII clear bit 5
  l_u1:
	dw      EXIT

HEADING 'R-DEPTH'
	dw      $ + 2
	MOV ax,first
	SUB ax,bp
	SHR ax,1
	push ax
	NEXT

HEADING 'R>S'
	dw      $ + 2
	MOV cx,first
	SUB cx,bp
	shr cx,1
	MOV ax,cx
  rs1:
	MOV di,cx
	shl di,1
	NEG di
	ADD di,first
	push word [di]
	LOOP rs1
	push ax
	NEXT

HEADING 'DUMP'			; ( a n -- )
  DUMP: dw      colon
	dw      zero, two_to_r			; DO
  du1:
	dw      eye, bite
	db      15
	dw      cfa_and, cfa_not, q_branch		; IF, new line
	dw      du2
	dw      CR, cfa_dup, eye, plus, bite
	db      5
	dw      u_dot_r, SPACE
  du2:							; THEN
	dw      eye, bite
	db      7
	dw      cfa_and, cfa_not, q_branch		; IF, 3 more spaces
	dw      du3
	dw	bite
	db      3
	dw      SPACES
  du3:							; THEN
	dw	cfa_dup, eye
	dw      plus, c_fetch, bite
	db      4
	dw      u_dot_r, do_loop
	dw      du1				; LOOP
	dw      CR, DROP
	dw      EXIT

HEADING 'WDUMP'			; ( a n -- )
	dw      colon
	dw      zero, two_to_r
  wdp1:
	dw      eye, bite
	db      7
	dw      cfa_and, cfa_not, q_branch
	dw      wdp2
	dw      CR, cfa_dup, eye, two_times, plus, bite
	db      5
	dw      u_dot_r, SPACE
  wdp2:
	dw      cfa_dup, eye, two_times
	dw      plus_fetch, bite
	db      7
	dw      u_dot_r, do_loop
	dw      wdp1
	dw      CR, DROP
	dw      EXIT

HEADING '.LINE'			; ( adr n -- )
  dot_line:     dw      colon
	dw      to_r, PAD, eye, front_cmove
	dw      PAD, eye, zero, two_to_r
  dln1:
	dw      cfa_dup, eye, plus, c_fetch, q_PRINTABLE
	dw      cfa_not, q_branch
	dw      dln2
	dw      bite
	db      94
	dw      OVER, eye, plus, c_store
  dln2:
	dw      do_loop
	dw      dln1
	dw      r_from, cfa_type
	dw      EXIT

HEADING 'A-DUMP'		; ( a n -- )
  a_dump:       dw      colon
	dw      zero, two_to_r
  ad1:
	dw      eye, bite
	db      63
	dw      cfa_and, cfa_not, q_branch
	dw      ad2
	dw      CR, cfa_dup, eye, plus, bite
	db      5
	dw      u_dot_r, bite
	db      3
	dw      SPACES
  ad2:
	dw      cfa_dup, eye, plus, bite
	db      64
	dw      eye_prime, cfa_min, dot_line, bite
	db      64
	dw      slant_loop
	dw      ad1
	dw      CR, DROP
	dw      EXIT

IMMEDIATE
HEADING 'ASCII'			; ( -- n )
	dw      colon
	dw      blnk, cfa_word, one_plus
	dw      c_fetch                  ; ( ASCII value of next word )
	dw      STATE, fetch
	dw      STAY, LITERAL
	dw      EXIT

HEADING '?MEM'			; ( -- left )
	dw      colon
	dw      sp_fetch, PAD
	dw      two_plus, minus
	dw      EXIT

msec:   dw      $ + 2
	mov al,06               ; latch counter 0
	out 43h,al
	in al,40h
	mov dl,al
	in al,40h
	mov dh,al
	sub dx,2366             ; (1193.2 - 10 setup)*2/msec
  ms1:
	mov al,06               ; latch counter 0
	out 43h,al
	in al,40h
	mov cl,al
	in al,40h
	mov ch,al
	sub cx,dx
	cmp cx,12       ; uncertainty
	ja ms1          ; U>

HEADING 'MS'			; ( n -- )
	dw      colon
	dw      zero, two_to_r
  ms01:
	dw      msec, do_loop
	dw      ms01
	dw      EXIT
	NEXT

; End of the dictionary (lfa) that will be retained (PROTECTED)
GOLDEN_LAST:		; dictionary 'protected' below this definition

addr_end:		; Used for EMPTY after startup

; Initial program entry and start up code
; If startup modified, modify the GEN.4th script
do_startup:
	mov ax,cs		; init segments
	mov ds,ax
	mov es,ax
	cli
	mov dx,sp		; save original SP
	mov cx,ss
	mov ss,ax       	; init stack
	mov sp,stack0
	sti
	mov [ss_save],cx
	mov [sp_save],dx

	mov ah,0Fh      	; get current display mode from BIOS
	int 10h
	sub dx,dx
	mov dl,ah
	mov [max_col],dx
	mov dl,al
	mov [_mode],dx
	mov dl,bh
	mov [_page],dx

	push ds
	mov ax,40h		; BIOS data segment, ah = 0
	mov ds,ax
	mov si,84h      	; rows - 1
	lodsb
	inc ax
	mov [es:max_rows],ax
	mov si,17h      	; caps lock on (most BIOS)
	mov al,[si]
	or al,40h
	mov [si],al
	pop ds

	call os_get_api_version
	mov ah,al
	xor al,al
	mov [dver1],ax

	mov al,'a'		; get/save current disk
	mov [path1],al

	xor ax,ax		; set current directory
	mov [path2],ax

	push es
	xor ax,ax		; get current, set new div 0 vector
	mov es,ax		; interrupt segment and offset = 0
	mov di,ax
	mov bx,[es:di]
	mov dx,[es:di+2]
	mov [d_off],bx
	mov [d_seg],dx
	mov bx,div_0
	mov dx,ds
	mov [es:di],bx
	mov [es:di+2],dx
	pop es

	mov bp,first            ; R at end of mem - see r_reset
	sub ax,ax		; Top of parameter stack (for underflow)
	push ax
	MOV si, start_forth	; forward reference, may be modified when new GEN.4th
	NEXT			; goto FORTH start, begin following pointers

; When generating a new file, VERSION may be FORGOTTEN and new created
;   Set address of new start_forth in above script
LAST_HERE:			; Last definition that will be 'remembered' (with a header)
HEADING 'VERSION'
  VERSION:      dw      colon
	dw      dotq
	db      vr01 - $ - 1
	db      'V1.5.1, 2011/01/15 '
  vr01:
	dw      EXIT
	
; Break a long, single chain of definitions into separate hash lists
; Generate can save modified dictionary for faster startup
N_HASH: dw      colon				; create hash lists
	dw	PAD, B_HDR, ERASE		; temporary buffer for pointers
	dw	cell, LAST_HERE, cfa_dup	; set last link field to VERSION
	dw	LAST, store
  nh1:					; BEGIN ( lfa )
	dw	q_DUP, q_branch, nh05	; WHILE not start of dictionary
	dw	cfa_dup, fetch, SWAP
	dw	zero, OVER, store		; set chain end, just in case
	dw	cfa_dup, l_to_nfa, bite
	db	VOC				; ( lfa' lfa nfa v )
	dw	HASH, SWAP, DROP		; ( lfa' lfa lnk ) 
	dw	cfa_dup, HEADS, plus_fetch
	dw	cfa_not, q_branch, nh2		; set end of normal chain IF not already
	dw	two_dup, HEADS, plus, store
  nh2:						; THEN
	dw	two_dup, FENCE, plus_fetch, cfa_not
	dw	SWAP, cell, GOLDEN_LAST + 1
	dw	u_less, cfa_and
	dw	q_branch, nh03			; set end of GOLDEN chain IF not already
	dw	two_dup, FENCE, plus, store
  nh03:						; THEN
	dw	PAD, plus, cfa_dup, fetch	; update individual chains
	dw      q_branch, nh04		 	; IF not first, update chain
						; ( lfa' lfa padx )
	dw      two_dup, fetch, store
  nh04:						; THEN
	dw      store				; update pad buffer
	dw      do_branch, nh1		; REPEAT
  nh05:
	dw      EXIT

; High level Start-up
; Headerless. Will be FORGOTTEN. GEN.4th must create a replacement
start_forth:
	dw      CR, CR, dotq
	db      sf01 - $ - 1
	db      'Copyright (C) 2014 MikeOS Developers -- see doc/LICENSE.TXT'
  sf01:
	dw      CR, dotq
	db      sf02 - $ - 1
	db      'FORTH version '
  sf02:
	dw      VERSION
	dw      CR, dotq
	db      sf03 - $ - 1
	db      'DOS version '
  sf03:
	dw      D_VER, one_plus, c_fetch, zero, st_num
	dw      add_num, add_num, cell, 46, HOLD, two_drop
	dw      D_VER, c_fetch, zero, nums, nd_num, cfa_type
	dw      CR, PATH, dot_az
	dw      CR, OK, CR
	dw	N_HASH
	dw      ABORT			; no print on abort

very_end:	dw      0, 0

