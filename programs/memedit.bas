rem Memory Manipulator (memedit.bas) version 2.4.1
rem An advanced memory modifing tool.
rem Now with command line arguments! Type "memedit help" for details.
rem Requires MikeOS 4.3b7 or better
rem If you fix a bug or add a feature it would be good if you could send it to
rem me at: mikeosdeveloper@gmail.com
rem I like to hear feedback on my programs.
parameters:
  rem >>>process command line parameters
  rem capitalize the string
  j = & $1
  for x = 1 to 128
    peek v j
    if v > 96 and v < 123 then v = v - 32
    poke v j
    j = j + 1 
  next x
  j = & $1
  y = & $2
  w = 0
  getpara:
    peek v j
    j = j + 1
    if v = 0 then goto procpara
    if v = 32 then w = w + 1
    if v = 32 and w = 1 then y = & $3
    if v = 32 and w = 2 then y = & $4
    if v = 32 then goto getpara
    poke v y
    y = y + 1
  goto getpara
  procpara:
    y = 0
    for x = 1 to 3
      if x = 1 then $5 = $2
      if x = 2 then $5 = $3
      if x = 3 then $5 = $4
      if $5 = "NOSND" then y = 1
      if $5 = "NOINFO" then w = 1
      if $5 = "RED" then $6 = "red"
      if $5 = "DBLBORDER" then $7 = "dbl"
      if $5 = "SLDBORDER" then $7 = "sld"
      if $5 = "HELP" then goto cmdhelp
    next x
if w = 1 then cls
if w = 1 then goto prep
goto title
cmdhelp:
  rem response to "memedit help"
  print "Memory Manipulator by Joshua Beck"
  print "Released under the GNU General Public Licence v3"
  print ""
  print "memedit [parameters] (maximum of three)"
  print "Accepts the following parameters (case insensitive):"  
  print ""
  print "Help - Displays this help"
  print "nosnd - No startup sound"
  print "noinfo - Does not display startup screen"
  print "Red - Alternate colour scheme"
  print "DblBorder - Double borders"
  print "SldBorder - Solid borders"
  end
title:
  rem >>>titlescreen
  CLS
  PRINT "Joshua's Memory Editor"
  rem PROGSTART is where the program is loaded to on MikeOS this is 32k+editor 
  rem Some OS's that run MikeBASIC are different. ramstart is the
  rem first free ram. So rs - ps = memory used by the program
  rem available memory is total memory(64K) - rs     simple really
  p = PROGSTART
  r = RAMSTART
  w = r - p
  v = 65535 - r
  print "Program Memory: "
  move 17 1
  print w
  move 0 2
  print "Available Memory: "
  move 19 2
  print v
  print "Version 2.4.1"
  rem nice little tune...
  rem also delays a startup a bit
  goto skipsound
  sound 2000 1
  sound 2200 1
  sound 2400 1
  sound 4000 1
  sound 2000 1
  sound 2200 1
  sound 2400 1
  sound 4000 1
  sound 4500 1
  sound 5000 1
  sound 5500 1
  sound 6000 1
  sound 2000 1
  sound 1000 3
  skipsound:
  print "Colour Edition :-)"
  rem add in colour sub
  gosub defcol
  rem lets make it bursting with colour  
  rem start at colour one and increase the could with every letter 
  v = 0
  for x = 0 to 17
    move x 4
    curschar j
    v = v + 1
    if j = 32 then v = v - 1
    poke v 65525
    poke j 65520
    call 65515
  next x 
  move 0 5
  print "Memory editing is dangerous use at your own risk!"
  print "Press any key to start."
  rem Lets make our warning red for effect
  poke 4 65525
  for x = 0 to 48
    move x 5
    curschar j
    poke j 65520
    call 65515
  next x
  cursor off
  waitkey k
  if k = 'J' then goto varset
  cls
rem Box drawing characters (right to left top, to bottom)
rem and variable that need to be defined before startup
rem we need different ones for different border types

Prep: 
  rem >>>define inital variables... These are explained below
  if $7 = "dbl" then goto border2
  if $7 = "sld" then goto border3
  border1:
  a = 218 
  b = 191
  c = 195
  d = 180
  e = 192
  f = 217
  g = 179
  h = 196
  goto rescon
  border2:
  a = 201
  b = 187
  c = 204
  d = 185
  e = 200
  f = 188
  g = 186
  h = 205
  goto rescon
  border3:
  a = 219
  b = 219
  c = 219
  d = 219
  e = 219
  f = 219
  g = 219
  h = 219
  rescon:
  l = 1
  m = 1
  n = 0
  q = 1
  s = 0
  z = 65515
  $2 = "n"
  $3 = "y"
  cursor off
  goto Border
defcol:
  rem Now for the colour routine, thanks wisecracker for this.
  rem This allows us to print text colours other than white
  rem a text byte is stored at 65520 and a colour at 65525
  poke 156 65515
  poke 80 65516
  poke 83 65517
  poke 81 65518
  poke 184 65519
  poke 32 65520
  poke 9 65521
  poke 183 65522
  poke 0 65523
  poke 179 65524
  poke 7 65525
  poke 185 65526
  poke 1 65527
  poke 0 65528
  poke 205 65529
  poke 16 65530
  poke 89 65531
  poke 91 65532
  poke 88 65533
  poke 157 65534
  poke 195 65535
return

VariableList:
  This should NEVER be executed.
  Since MikeOS doesn't check the file before executing it
  we can use plain text here.
  This is a place where we say what all the variables are used for
  so I can find free ones and in case I forget. 
  'a' - 'h' are for box drawing characters 'i' where peeked byte are put
  'j' is a temp var 'k' is for keyboard bytes 'l' and 'm' are cursor position
  'n' marks the program finished startup 'p' is progstart 
  'o' is used in goleft and goright to mark end or start of line
  'q' is the column 'r' is ramstart 's' is first byte on screen 
  'v' and 'w' are temp var 'x' and 'y' are for loops
  $2 is used in Border as "y" for startup (goto) or "n" for redraw (gosub)
  $3 is used to mark if we need to do movecur after getbytes ("y" or "n")
  notice I didn't put quotes around a text variable, that generates an error
  't' 'u' and 'z' are UNUSED :-)

Border:
  rem Colour the border will be drawn in
  rem currently it is 1 (blue)
  poke 1 65525
  if $6 = "red" then poke 4 65525
  rem using routein
  rem character to print (variable A = box corner)
  poke a 65520
  rem now call it
  call 65515
  rem there! that wasn't too hard
  rem top line
  poke h 65520
  for x = 1 to 78
    move x 0
    call 65515
  next x

  rem the top edges
  move 79 0
  poke b 65520
  call 65515
  move 0 1
  poke g 65520
  call 65515
  move 79 1
  call 65515
  move 0 2
  poke c 65520
  call 65515
  move 79 2
  poke d 65520
  call 65515
  poke h 65520

  rem 2nd line (titlebar)
  for x = 1 to 78
    move x 2
    call 65515
  next x

  rem position text
  move 54 1
  print "Selected Byte: "

  rem top overlay
  move 6 3
  print "0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9"
  move 53 3
  print "01234567890123456789"

  rem now for the bottom
  move 6 19
  print "0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9"
  move 53 19
  print "01234567890123456789"
  v = 0

  rem sides and address number
  poke g 65520 
  for x = 3 to 21
    move 0 x
    call 65515
    move 79 x
    call 65515

    rem to save on variables
    j = x + 1
    move 70 j
    v = v + 20
    w = v - 20

    rem numbers down the size
    rem how many digits will we need? position accordingly then print
    if v < 110 then move 75 j
    if v > 110 then move 74 j
    if w = 0 then move 76 j
    if v < 330 then print w

    rem now the other side
    if v < 110 then move 3 j
    if v > 110 then move 2 j
    if w = 0 then move 4 j
    if v < 310 then print w
  next x

  rem bottom corners
  move 0 22
  poke e 65520
  call 65515
  move 79 22
  poke f 65520
  call 65515

  rem 3rd and bottom line
  poke h 65520  
  for x = 1 to 78
    move x 22
    call 65515
  next x

  rem print the title
  move 2 1
  print "Memory Manipulator"
  rem make it light blue
  poke 9 65525
  if $6 = "red" then poke 12 65525
  for x = 2 to 20
    move x 1
    curschar j
    poke j 65520
    call 65515
  next x

  rem Now the instructions at the bottom
  move 2 20
  print "Use the arrow keys to move around, G for GOTO, Enter to change value," 
  move 2 21
  print "Q for page up and Z for page down. O to Save and L to load files to" ; 
  rem not quite enough screen space in the editor
  print " memory"
  rem and this stuff will be cyan
  poke 3 65525
  if $6 = "red" then poke 12 65525
  for y = 20 to 21
    for x = 2 to 78
      move  x y
      curschar j
      poke j 65520
      call 65515
    next x
  next y
  rem is it expecting to be returned?
  if $2 = "y" then return
  
  rem I put this here because I don't want to make the main loop look ugly
  rem we turn the cursor off before we start the if's because a few of them
  rem redraw the interface and it looks bad

Main:
  rem first time stuff
  if n = 0 then gosub getbytes
  if n = 0 then gosub movecur
  if n = 0 then gosub lightbyte
  if n = 0 then n = 1
  waitkey k
    rem main keyboard loop
    rem what a good structured programer I am!
    cursor off
    if k = 27 then goto endprog
    if k = 1 then gosub goup 
    if k = 2 then gosub godown
    if k = 3 then gosub goleft
    if k = 4 then gosub goright
    if k = 'g' then gosub jumpto
    if k = 'G' then gosub jumpto
    if k = 13 then gosub newval
    if k = 'z' then gosub fastdown
    if k = 'Z' then gosub fastdown
    if k = 'q' then gosub fastup
    if k = 'Q' then gosub fastup
    if k = 'o' then gosub save
    if k = 'O' then gosub save
    if k = 'l' then gosub load
    if k = 'L' then gosub load
goto Main

endprog:
  cls
  print "Thanks for using Memory Manipulator."
  print "Don't forget to fix any bugs you might find!"
  print "E-mail feedback, bugs reports or changes to:"
  print "mikeosdeveloper@gmail.com"
  print "Bye, bye!"
  rem Hahahahaha, I don't write BUGS!
  cursor on
  end

getbytes:
  rem copy the memory we need
  for x = 0 to 299
    v = x + s
    peek i v
    j = x + r + 100
    poke i j
  next x
printbytes:
  rem now lets put it onto the screen
  for y = 4 to 18
    for x = 53 to 72
      move x y
      rem figure out the memory location needed
      w = y - 4
      v = x - 53
      w = w * 20
      j = w + v
      j = j + r + 100
      peek i j
      rem so it doesn't beep, we print a null
      rem this doesn't affect the hex value
      if i = 7 then i = 0
      print chr i
    next x
  next y
goto printhex

printloc:
  rem Print location top of screen
  move 54 1
  print "Selected Byte: "

  rem let's figure out what it is AAAAGH!
  j = m - 1
  j = j * 20
  j = j + l
  j = j - 1
  j = j + s

  rem now position it relative to the length
  move 69 1
  print "    "
  w = 0
  if j < 0 then w = j / 256
  if j < 0 then j = j % 256
  if j > 255 then w = j / 256
  if j > 255 then j = j % 256
  move 69 1
  print hex w ;
  print hex j
return

printhex:
rem same as printbytes but in hex format
  for y = 4 to 18 
    for x = 5 to 24
      rem sigh, figure out location
      w = y - 4
      v = x - 5
      w = w * 20
      j = w + v
      j = j + r + 100
      peek i j
      rem now put it onto the screen
      v = v * 2
      v = v + 6
      move v y
      print hex i
    next x
  next y
  gosub printloc
  rem are we expecting to be returned? if not we'll just go on to movecur
  if $3 = "n" then return

movecur:
  rem selected byte colour
  
  if l > 1 then 
  rem remove previous highlight
  for q = 1 to 2
    gosub dselect
  next q

  rem this highligh colour make it look like it's selected
  poke 224 65525
  if $6 = "red" then poke 111 65525

  rem locate cursor, this can differ depending on the column
  for q = 1 to 2
    if q = 1 then v = l * 2 + 4
    if q = 2 then v = l + 52
    rem if q = 1 then v = v + 5
    w = m + 3
    move v w
 
    rem get the byte and change it
    curschar j
    poke j 65520
    call 65515
    if q = 1 then gosub otherbyte
  next q
  if l = 1 then gosub linefix
  if l = 20 then gosub linefix
return

otherbyte:
  rem do the same to the other character of a hex value
  rem this just takes the colour and location and does it to the next byte
  v = v + 1
  move v w
  curschar j
  poke j 65520
  call 65515
  v = v - 1
  move v w
return 

linefix:
  rem if you go to an address off the screen it highlights
  rem the byte of the other side, this removes that
  if l = 1 then v = v + 19
  if l = 20 then v = v - 19
  move v w
  curschar j
  poke 7 65525
  poke j 65520
  call 65515
  if l = 1 then v = v - 19
  if l = 20 then v = v + 19
  move v w

  rem same as linefix but for the hex column
  if l = 1 then v = v - 9
  if l = 20 then v = v - 66
  for x = 0 to 1
    v = v + x
    move v w
    curschar j
    poke 7 65525
    poke j 65520
    call 65515
  next x
  v = v - 1
  if l = 1 then v = v + 9
  if l = 20 then v = v + 66
  move v w
return

dselect:
  rem change the character back to white
  poke 7 65525
  rem go to last cell
  if k = 1 then m = m + 1
  if k = 2 then m = m - 1
  if k = 3 then l = l + 1
  if k = 4 then l = l - 1
  if l = 0 then m = m - 1
  if l = 0 then l = 20
  if l = 21 then m = m + 1
  if l = 21 then l = 1
  if q = 1 then v = l * 2 - 1  
  if q = 2 then v = l + 52
  if q = 1 then v = v + 5
  w = m + 3
  move v w
  rem now change colour
  curschar j
  poke j 65520
  call 65515
  rem now go back
  rem this is complex because we need to know the location we just went
  if q = 1 then gosub otherbyte
  if k = 1 then m = m - 1
  if k = 2 then m = m + 1
  if k = 3 then l = l - 1
  if k = 4 then l = l + 1
  rem if we go over the start or end go to the next/previous line
  if l = 0 then m = m - 1
  if l = 0 then l = 20
  if l = 21 then m = m + 1
  if l = 21 then l = 1
  rem now move it relative to  the column we are in
  if q = 1 then v = l * 2 - 1
  if q = 2 then v = l + 52
  if q = 1 then v = v + 5
  w = m + 3
  move v w
  return
goup:
  rem Decrease starting point and redraw
  rem there are 20 charaters in a line and the data must be
  rem redraw (getbytes) if it's off the screen
  j = 0
  if m = 1 then s = s - 20
  rem we reload the data only when we need to
  if m = 1 then gosub getbytes
  if m > 1 then j = 1
  if j = 1 then m = m - 1
  if j = 1 then gosub movecur
  gosub printloc
  return  
godown:
  rem Increase starting point and redraw
  j = 0
  if m = 15 then s = s + 20
  if m = 15 then gosub getbytes
  if m < 15 then j = 1
  if j = 1 then m = m + 1
  if j = 1 then gosub movecur
  gosub printloc
  return
box:
  rem lets have fun and draw a box for features!
  move 20 8
  poke a 65520
  call 65515
  move 59 8
  poke b 65520
  call 65515

  rem first line
  poke h 65520
  for x = 21 to 58
    move x 8
    call 65515
  next x

  rem continue edges
  move 20 9
  poke g 65520
  call 65515
  move 59 9
  call 65515
  move 20 10
  poke c 65520
  call 65515
  move 59 10
  poke d 65520
  call 65515

  rem now the sides
  poke g 65520
  for x = 11 to 16
    move 20 x
    call 65515
    move 59 x
    call 65515
  next x

  rem bottom corners
  move 20 17
  poke e 65520
  call 65515
  move 59 17
  poke f 65520
  call 65515

  rem second line
  poke h 65520
  for x = 21 to 58
    move x 10
    call 65515
  next x

  rem third and final line
  poke h 65520
  for x = 21 to 58
    move x 17
    call 65515
  next x

  rem remove text inside box
  move 21 9
  print "                                      "
  move 21 11
  print "                                      "
  move 21 12
  print "                                      "
  move 21 13
  print "                                      "
  move 21 14
  print "                                      "
  move 21 15
  print "                                      "
  move 21 16
  print "                                      "

  rem remove colour from inside
  poke 7 65525
  for x = 21 to 58
    move x 9
    curschar j
    poke j 65520
    call 65515
  next x
  for y = 11 to 16
    for x = 21 to 58
      move x y
      curschar j
      poke j 65520
      call 65515
    next x
  next y

  rem ok, glad that's done. Isn't box drawing fun! :-(
  rem now we can add features without having to do this again
return

jumpto:
  rem goto cell
  rem lets use our box
  rem first set colour
  poke 2 65525
  if $6 = "red" then poke 5 65525
  rem then draw it
  gosub box
  rem lets put some stuff in it
  move 22 9
  print "Goto - Location"
  move 22 12
  print "Enter the number of a memory cell to"
  move 22 13
  print "go to that location. It must be"
  move 22 14
  print "a hex between 0000 and FFFF."
  move 22 16
  print "Press enter to go"
  move 27 15
  print "<"
  move 22 15
  print ">" ;
  cursor on
  rem The value of j isn't important.
  rem We just need to get the four hex characters and convert them.
  input j
  j = 0
  cursor off
  move 23 15
  curschar j
  poke j 65512
  move 24 15
  curschar j
  poke j 65513
  gosub hexconv
  rem if it's invalid, (w = 1 passed) then return
  if w = 1 then goto nvf
  peek j 65514
  x = j * 256
  rem first two down, two more to go
  move 25 15
  curschar j
  poke j 65512
  move 26 15
  curschar j
  poke j 65513
  gosub hexconv
  if w = 1 then goto nvf
  peek j 65514
  s = j + x
  rem take into account current position
  j = m * 20 
  s = s - j - l + 21
  gosub nvf
return

newval:
  rem >>>change value
  poke 4 65525
  if $6 = "red" then poke 6 65525
  gosub box
  move 22 9
  print "Change Cell"
  move 22 12
  print "Enter a new hex value for this"
  move 22 13
  print "cell between 00 and FF."
  move 22 14
  rem we don't want to force people into a dangerous memory edit
  print "Type G0 to cancel."
  move 22 15
  print ">"
  move 25 15
  print "<"
  move 22 16
  print "Press enter to change"
  move 23 15
  x = 256
  cursor on
  input x
  move 23 15
  curschar x
  if x = 'G' then goto nvf
  if x = 'g' then goto nvf
  rem save 2 hex digits
  poke x 65512
  move 24 15
  curschar x
  poke x 65513
  gosub hexconv
  cursor off
  if x = 256 then goto nvf
  if x > 256 then goto newval
  rem now to find out our position
  j = m - 1
  j = j * 20
  j = j + l
  j = j - 1
  j = j + s
  peek x 65514
  poke x j
nvf:
  rem redraw the screen and return to main
  cursor off
  cls
  $2 = "y"
  gosub Border
  gosub getbytes
  $2 = "n"
  gosub lightbyte
  return
goleft:
  $3 = "n"
  o = 0
  if l = 1 then o = 1
  rem did we go past the start?
  if o = 1 then l = 20
  if o = 1 then gosub goup
  if o = 0 then l = l - 1  
  gosub printloc
  gosub movecur
  $3 = "y"
  return
goright:
  $3 = "n"
  o = 0
  rem did we go past the end?
  if l = 20 then o = 1
  if o = 1 then l = 1
  if o = 1 then gosub godown
  if o = 0 then l = l + 1
  gosub printloc
  gosub movecur
  $3 = "y"
  return
fastdown:
  rem there are 300 bytes on the screen
  s = s + 300
  gosub getbytes
  gosub movecur
  gosub lightbyte
  return
fastup:
  s = s - 300
  gosub getbytes
  gosub movecur
  gosub lightbyte
  return
varset:
  rem a gold star to those who found this WITHOUT looking at the code
  cls 
  move 15 10
  print "You dare press the sacred letter of the gods!!!!"
  poke 3 65525
  for x = 2 to 28 
     v = x + 30
     move v 10
     curschar j
     poke j 65520
     call 65515
   next x
   pause 10
   waitkey j
   goto title
lightbyte:
   rem highlight byte when we can't use movecur
   for q = 1 to 2
     if q = 1 then v = l * 2 + 4
     if q = 2 then v = l + 52
     w = m + 3
     move v w
     poke 224 65525
     if $6 = "red" then poke 111 65525
     curschar j
     poke j 65520
     call 65515
     if q = 1 then gosub otherbyte
   next q
   return
error:
   rem I created this later on for errors in load/save
   rem all you need is an error in $5
   rem actually like a lot of stuff in here, it inspired MB++ (APPDEV)
   poke 6 65525
   if $6 = "red" then poke 12 65525
   gosub box
   move 22 9
   print "Error"
   move 22 12
   print $5
   move 22 13
   print "Press any key to continue..."
   waitkey k
   gosub nvf
   return
load:
   rem load a file into memory
   poke 14 65525
   gosub box
   move 22 9
   print "Load"
   move 22 12
   print "Warning! All of the file will be"
   move 22 13
   print "loaded to your location. Sure? Y/N" 
   loadask:
   waitkey k
     if k = 'y' then goto loadcont
     if k = 'Y' then goto loadcont
     if k = 'n' then goto nvf
     if k = 'N' then goto nvf
     goto loadask
   loadcont:
   move 22 14
   print "Input filename to load (ie FOO.BAR)"
   move 22 15
   print ">"
   move 23 15
   cursor on
   input $4
   cursor off
   rem preserve values of r and s in tempvar because they will be changed
   rem by the load command
   v = r
   w = s
   j = m * 20 
   j = j + s 
   j = j + l 
   j = j - 21
   load $4 j
   rem did the load fail?
   j = 0
   if r = 1 then j = 1
   rem restore values
   r = v
   s = w
   $5 = "Cannot load file!"
   if j = 1 then goto error
   goto nvf
   return
save:
   rem create a file from memory
   poke 13 65525
   gosub box
   move 22 9
   print "Save"
   move 22 12
   print "Input filename to save (ie FOO.BAR)" 
   move 22 13
   print ">"
   move 23 13
   cursor on
   input $4
   cursor off
   move 22 14
   print "Enter number of sectors (0 to cancel)"
   move 22 15
   print ">"
   move 23 15
   cursor on
   input x
   move 22 16
   print "Working..." ;
   cursor off
   rem we can't do single bytes, load only does sectors (512 bytes)
   x = x * 512
   j = m * 20
   j = j + s 
   j = j + l
   j = j - 21
   v = r
   w = s
   rem save filename-start-bytes
   save $4 j x
   j = r
   r = v
   s = w
   rem file operation results
   rem return if there's no error
   if j = 0 then goto nvf
   $5 = "Unknown Error"
   if j = 1 then $5 = "File Save Error!"
   if j = 2 then goto overwrite
   goto error
   goto nvf
   
overwrite:
   rem file exists - do they want to overwrite?
   poke 13 65525
   w = x
   gosub box
   x = w
   move 22 9
   print "Save"
   move 22 13
   cursor on
   print "File exists! Overwrite? (Y/N)" ;
   cursor off
   v = 0
   do
      waitkey w
      if w > 96 and w < 123 then w = w - 32
      if w = 'Y' then v = 1
      if w = 'N' then v = 2
   loop until v > 0
   if v = 2 then goto nvf
   move 22 14
   cursor on
   print "Working..." ;
   cursor off
   j = m * 20
   j = j + s 
   j = j + l
   j = j - 21
   v = r
   w = s
   delete $4
   save $4 j x
   r = v
   s = w
   goto nvf

hexconv:
   w = 0
   j = 65512
   gosub digitcon
   i = i * 16
   poke i 65514
   j = 65513
   gosub digitcon
   j = i
   peek i 65514
   i = i + j
   poke i 65514
   return

digitcon:
   peek i j
   rem ===check lowercase letter (a-f)===
   if i > 96 and i < 103 then i = i - 87
   rem ===check number (0-9)===
   if i > 47 and i < 58 then i = i - 48
   rem ===check capital letter (A-F)===
   if i > 64 and i < 71 then i = i - 55
   rem ===set the 'bad number' flag it's none of those===
   if i > 20 then w = 1
   return 
