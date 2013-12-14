rem *** MikeOS Sudoku 1.0 ***


cls

a = 0
b = 0
c = 78
d = 24
gosub draw_box

$1 = "Easy,Medium,Hard"
$2 = "MikeOS Sudoku"
$3 = "Choose a difficulty level..."
listbox $1 $2 $3 z

if z = 0 then goto finish


rem *** Copy level information into RAM ***
d = RAMSTART
for c = 1 to 81
  if z = 1 then read level_easy c a
  if z = 2 then read level_medium c a
  if z = 3 then read level_hard c a
  poke a d
  d = d + 1
next c


rem *** X and Y vars are cursor position ***
x = 0
y = 0


cursor off
gosub setup_screen

main_loop:
  gosub update_screen

  rem *** Move cursor according to keypresses, skipping divider lines ***
  waitkey k
  if k = 27 then goto finish
  if k = 4 and x < 16 then x = x + 2
  if k = 3 and x > 0 then x = x - 2
  if k = 2 and y < 10 then y = y + 1
  if k = 2 and y = 3 then y = y + 1
  if k = 2 and y = 7 then y = y + 1
  if k = 1 and y > 0 then y = y - 1
  if k = 1 and y = 3 then y = y - 1
  if k = 1 and y = 7 then y = y - 1
  if k = 13 then gosub enter_pressed
  if k = 104 then gosub show_help
  goto main_loop


finish:
  cursor on
  cls
  end


enter_pressed:
  move 40 14
  print "Enter a number: " ;
  input a

  if a > 9 then goto invalid

  rem *** These lines convert our coordinates in the grid into the ***
  rem *** corresponding point in the Sudoku numbers in RAM ***
  b = x / 2
  c = RAMSTART
  c = c + b
  d = y * 9
  c = c + d
  if y > 2 and y < 7 then c = c - 9
  if y > 7 then c = c - 18
  poke a c

  move 40 14
  print "                          "

  gosub check_completed
return

invalid:
  move 40 16
  print "Invalid number!"
  waitkey a
  move 40 14
  print "                          "
  move 40 16
  print "                          "
return


check_completed:
  d = 0
  u = 0

  rem *** First, go through the rows, looking for uniques ***
  a = RAMSTART

  for p = 0 to 8
    z = a

    for b = 1 to 9
      for c = 0 to 8
        peek m a
        if m = b then d = d + 1
        if m = b then goto donehere
        a = a + 1
      next c
      donehere:
      a = z
    next b

    if d = 9 then u = u + 1
    d = 0
    a = a + 9
  next p


  rem *** And then through columns ***
  a = RAMSTART
  d = 0

  for p = 0 to 8
    z = a

    for b = 1 to 9
      for c = 0 to 8
        peek m a
        if m = b then d = d + 1
        if m = b then goto bdonehere2
        a = a + 9
      next c

      bdonehere2:
      a = z
    next b

    if d = 9 then u = u + 1
    d = 0
    a = a + 1
  next p    


  rem *** And through first column of boxes ***

  for g = 0 to 2
    a = RAMSTART
    d = 0
    b = g * 27
    a = a + b

    z = a

    for b = 1 to 9
      for c = 0 to 8
        if c = 3 then a = a + 6
        if c = 6 then a = a + 6
        peek m a
        if m = b then d = d + 1
        if m = b then goto bdonehere3
        a = a + 1
      next c

      bdonehere3:
      a = z
    next b

    if d = 9 then u = u + 1
    d = 0
    a = a + 1
  next g


  rem *** Second column ***
  for g = 0 to 2
    a = RAMSTART
    d = 0
    b = g * 27
    a = a + b
    a = a + 3

    z = a

    for b = 1 to 9
      for c = 0 to 8
        if c = 3 then a = a + 6
        if c = 6 then a = a + 6
        peek m a
        if m = b then d = d + 1
        if m = b then goto bdonehere4
        a = a + 1
      next c

      bdonehere4:
      a = z
    next b

    if d = 9 then u = u + 1
    d = 0
    a = a + 1
  next g


  rem *** Third column ***
  for g = 0 to 2
    a = RAMSTART
    d = 0
    b = g * 27
    a = a + b
    a = a + 6

    z = a

    for b = 1 to 9
      for c = 0 to 8
        if c = 3 then a = a + 6
        if c = 6 then a = a + 6
        peek m a
        if m = b then d = d + 1
        if m = b then goto bdonehere5
        a = a + 1
      next c

      bdonehere5:
      a = z
    next b

    if d = 9 then u = u + 1
    d = 0
    a = a + 1
  next g

  if u = 27 then goto win
return


win:
  move 45 12
  ink 14
  print "PUZZLE COMPLETE!"
  move 44 14
  ink 7
  print "Press a key to end"
  waitkey x
  cursor on
  cls
  end


setup_screen:
  cls

  rem *** Outer border ***
  a = 0
  b = 0
  c = 78
  d = 24
  gosub draw_box


  rem *** Sudoku grid lines ***
  ink 8

  a = 13
  b = 8
  c = 31
  d = 20
  gosub draw_box
  a = 13
  b = 8
  c = 31
  d = 12
  gosub draw_box
  a = 19
  b = 8
  c = 25
  d = 12
  gosub draw_box
  a = 13
  b = 12
  c = 31
  d = 16
  gosub draw_box
  a = 19
  b = 12
  c = 25
  d = 16
  gosub draw_box
  a = 19
  b = 16
  c = 25
  d = 20
  gosub draw_box

  ink 7
  move 3 2
  print "MikeOS Sudoku - Press H for help, or Esc to quit"
  move 3 4
  print "Cursor keys navigate, Enter inputs a number, zero blanks a square"
return


update_screen:
  rem *** Cursor ***
  ink 14

  rem *** First, blank out area where cursor could be ***
  move 14 6
  print "                    "
  move 14 7
  print "                    "

  for a = 9 to 21
    move 11 a
    print "  "
  next a

  a = x + 14
  move a 6
  print "|" ;
  move a 7
  print "v" ;
  b = y + 9
  move 11 b
  print "->" ;
  ink 7


  rem *** Numbers ***
  a = 14
  b = 9

  m = RAMSTART

  for c = 1 to 81
    peek d m

    move a b
    if d > 0 then print d ;
    if d = 0 then print " " ;
    a = a + 2

    rem *** Handle wrapping ***
    if a = 32 then b = b + 1
    if a = 32 then a = 14
    if b = 12 then b = 13
    if b = 16 then b = 17

    m = m + 1
  next c
return


show_help:
  cls

  print ""
  print ""
  print "   Sudoku is a puzzle game. You have a grid of 9 x 9 squares,"
  print "   which is divided into smaller 3 x 3 sections. Your goal is"
  print "   to fill the grid so that every row has the numbers 1 to 9,"
  print "   every column has the numbers 1 to 9, and every small 3 x 3"
  print "   section has the numbers 1 to 9."
  print ""
  print "   Press a key to return to the game..."

  a = 0
  b = 0
  c = 78
  d = 24
  gosub draw_box

  waitkey z
  gosub setup_screen
  return
return


rem *** Level data ***
level_easy:
0 5 0 0 8 1 0 0 7
4 6 0 0 0 0 3 5 0
0 0 1 3 4 0 0 6 0
0 0 4 8 0 6 0 0 9
8 0 7 0 5 0 2 0 6
6 0 0 1 0 2 7 0 0 
0 1 0 0 3 4 6 0 0
0 8 6 0 0 0 0 2 3
2 0 0 7 6 0 0 9 0

level_medium:
0 7 0 0 2 0 0 3 0
8 0 0 0 0 0 0 0 9
0 0 5 0 9 0 4 0 0
0 5 0 0 8 0 0 4 0
3 0 1 9 0 7 6 0 2
0 9 0 0 6 0 0 8 0
0 0 9 0 7 0 8 0 0
1 0 0 0 0 0 0 0 6
0 4 0 0 5 0 0 7 0

level_hard:
0 0 0 1 6 8 0 0 0
0 0 0 4 7 9 1 0 0
0 0 0 0 0 0 0 0 0 
2 0 0 0 0 6 4 0 7
1 0 0 3 0 0 5 0 9
0 0 9 0 0 7 0 8 0
0 0 0 0 0 0 2 0 0
0 0 8 0 0 0 7 0 3
0 0 5 6 4 3 0 0 0


rem *** draw_box routine ***
rem *** Takes coords in A, B, C and D vars. Uses Z internally ***
draw_box:
  move a b
  for z = a to c
    print "-" ;
  next z
  move a d
  for z = a to c
    print "-" ;
  next z
  for z = b to d
    move a z
    print "|" ;
  next z
  for z = b to d
    move c z
    print "|" ;
  next z
  move a b
  print "+" ;
  move a d
  print "+" ;
  move c b
  print "+" ;
  move c d
  print "+" ;
return

