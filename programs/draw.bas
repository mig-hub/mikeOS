rem ASCII Artist (DRAW.BAS)
rem Version 2.2.2
rem Uses MB++ Version 3.0 beta 3
rem Released under the GNU General Public Licence revision 3
rem If you have any comments or changes send them to mikeosdeveloper@gmail.com

INCLUDE "MBPP.BAS"

preload:
  print "loading..."
  cls
  gosub blank
  rem did they specify a filename?
  if $1 = " " then $1 = ""
  if $1 = "" then goto nopara
  rem change any lowercase letters in the parameters to capital
  x = & $1
  gosub capitalise
  rem now load it
  load $1 59999 
  if r = 0 then $2 = $1
  if r = 0 then goto nopara
  print "File '";
  print $1 ;
  print "' not found."
  end
  nopara:
  cursor off
  z = 61990
  for x = 1 to 10
    read keyval x y
    poke y z
    z = z + 1
  next x
  goto config


  rem default values for numbers in asending order
  rem we don't have enough variables so we poke them into memory

  keyval:
  255 178 220 219 221 254 222 176 223 177

  config:
  rem starting position for cursor
  l = 1
  m = 1

start:
  rem MB++ start block (define interface)
  gosub startprg
  $Y = "ENABLE"
  c = 4
  h = 12
  t = 4
  z = 4
  gosub border
  $T = "ASCII Artist Version 2.2.1 for MikeOS"
  gosub settitle
  gosub content
  
titlemsg:
  o = 0
  gosub colchange
  $T = "ASCII Artist for MikeOS"
  $5 = "Created by Joshua Beck"
  $6 = "Version 1.2"
  $7 = "Release under GNU GPLv3"
  $8 = "Uses MB++ version 3.0 beta 4"
  $9 = "Make sure numpad is on!"
  gosub mesbox

keyboard:
  waitkey k
  if k = 1 then gosub keyup
  if k = 2 then gosub keydown
  if k = 3 then gosub keyright
  if k = 4 then gosub keyleft
  if k = 18 then gosub refresh
  if k = 19 then gosub saveover
  if k = 27 then gosub mainmenu
  if k > 47 and k < 58 then gosub numkey
  if k > 47 and k < 58 then goto keyboard
  if k > 31 and k < 127 then gosub otherkey
goto keyboard

mainmenu:
  gosub colchange
  $T = "            Options"
  $5 = "        Return to Editor"
  $6 = "          New/Load/Save"
  $7 = "              Help"
  $8 = "       Change number value"
  $9 = "              Exit"
  gosub menubox
  if v = 1 then gosub colchange
  if v = 1 then return
  if v = 2 then gosub filemenu
  if v = 3 then gosub help
  if v = 4 then gosub change
  if v = 5 then gosub endprog
  o = 0
  gosub colchange
goto mainmenu
 
filemenu:
  $T = "        File Operations"
  $5 = "          New Picture"
  $6 = "          Load Picture"
  $7 = "          Save Picture"
  $8 = "        Save Picture As..."
  $9 = "              Back"
  gosub menubox
  w = v
  v = 0
  if w = 1 then gosub blank
  if w = 1 then gosub refresh
  if w = 2 then gosub loadfile
  if w = 3 then gosub saveover
  if w = 4 then gosub savefile
  if w = 5 then return
goto filemenu

capitalise:
  for y = 1 to 12
    peek z x
    if z > 96 and z < 123 then z = z - 32
    poke z x
    x = x + 1
  next y
return

blank:
  for x = 59999 to 62000
    poke 0 x
  next x
return

colchange:
  rem create red outline or remove it
  x = l + 1
  y = m + 2
  move x y
  if o = 0 then ink 79
  if o = 1 then ink 7
  curschar j
  print chr j ;
  ink c
  j = o
  if j = 1 then o = 0
  if j = 0 then o = 1
return

keyup:
  if m = 1 then return
  gosub colchange
  m = m - 1
  gosub colchange
  return 
keydown:
  if m = 20 then return
  gosub colchange
  m = m + 1
  gosub colchange 
  return
keyright:
  if l = 1 then return
  gosub colchange
  l = l - 1
  gosub colchange
  return
keyleft:
  if l = 77 then return
  gosub colchange
  l = l + 1
  gosub colchange
  return
numkey:
  rem convert ascii to number
  j = k - 48
  rem now goto the memory cell it's stored
  j = j + 61990
  peek i j
  rem move the cursor to the correct position
  e = l + 1
  f = m + 2
  move e f
  print chr i
  rem now save to memory
  j = m - 1
  j = j * 80
  j = j + l + 59998
  poke i j
  o = 0
  gosub colchange
return

otherkey:
  e = l + 1
  f = m + 2
  move e f
  print chr k
  j = m - 1
  j = j * 80
  j = j + l + 59998
  poke k j
  o = 0
  gosub colchange
return

change:
  rem change default keys
  $T = "Change characters"
  $5 = "Enter number key to change."
  $6 = "10 to cancel."
  $E = "Must be  0 - 9!"
  v = 0
  gosub inpbox
  A = V
  rem error uses $E to define the problem
  if a = 10 then return
  if a > 9 then goto errbox
  if a < 0 then goto errbox
  poke a 62000
  $5 = "Input a new decimal value for the key"
  $6 = "between 0 and 255."
  $E = "Must be 0 - 255!"
  v = 0
  gosub inpbox
  b = V
  peek a 62000
  if b > 255 then goto errbox
  if b < 0 then goto errbox
  j = 61990 + a
  poke b j
  return
help:
  $T = "              Help"
  $5 = "Use the arrows to move the cursor"
  $6 = "around the screen."
  $7 = "Use the numbers on the numpad to put "
  $8 = "to write characters to screen." 
  $9 = "You can save your work with Ctl+S."
  gosub mesbox
  $5 = "You can change the character"
  $6 = "value produced by a number key."
  $7 = "You can also use keyboard keys."
  $8 = "Press escape for the menu."
  $9 = "Finally, have fun! :-)"
  gosub mesbox
return

savefile:
  $T = "Save"
  move 26 10 
  $5 = "Enter an 8.3 type filename to save"
  $6 = "picture as (ie foo.bar)."
  $E = "Invalid Filename!"
  v = 1
  gosub inpbox
  $1 = $I
  save $1 59999 2001
  o = 0
  gosub colchange
  rem R is the result code from 'save'
  rem 0 = success, 1 = invalid name, 2 = file exists
  if R = 1 then $E = "Save Failed!"
  if R = 2 then goto overwrite
  if R > 2 then $E = "Unknown Error!"
  if R > 0 then goto errbox
  $2 = $1
return

saveover:
  if $2 = "" then goto savefile
  $E = "File invalid! Did disk change?"
  delete $2
  save $2 59999 2001
  if r = 2 then $E = "Disk is read-only!"
  if r > 0 then goto errbox
return
  
overwrite:
  $T = "Warning!"
  $5 = ""
  $6 = "File already exists."
  $7 = "Do you wish to overwrite it?"
  $8 = ""
  $9 = ""
  gosub askbox
  if v = 0 then goto savefile
  delete $1
  $E = "Unknown Error!"
  if r = 1 then $E = "Read-only Disk!"
  if r = 2 then $E = "Unknown Error!"
  if r > 0 then goto errbox
  save $1 59999 2001
  $2 = $1
return

loadfile:
  $T = "Load"
  $5 = "Enter an 8.3 type filename to load"
  $6 = "from (ie foo.bar)"
  $E = "File does not exist!"
  v = 1
  gosub inpbox
  load $I 59999
  if R > 1 then $E = "Unknown Error!"
  if R > 0 then goto errbox
  $2 = $I
  gosub refresh
  o = 0
  gosub colchange
return

content:
  ink 7
  for y = 3 to 22
    move 1 y
    print " " ;
    j = y - 3
    j = j * 80
    j = j + 59999
    for x = 2 to 78
      peek v j
      print chr v ;
      j = j + 1
    next x
  next y
  ink c
  o = 0
  gosub colchange
return


