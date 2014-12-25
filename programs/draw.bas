rem ASCII Artist, version 3.0.0 (DRAW.BAS)
rem A text drawing program for MikeOS
rem Copyright (C) Joshua Beck 2002
rem Mail: mikeosdeveloper@gmail.com
rem Licenced under the GNU General Public Licence, see licence.txt

rem Requires the MB++ library, version 3.2.2 or greater
include "mbpp.bas"

initlib:
  gosub startprg
  c = 4
  h = 12
  t = 4
  z = 4
  $T = "ASCII Artist"
  gosub settitle
  gosub anistart
  gosub border
  
preload:
  m = ramstart
  n = 64100 - m

  cursor off

  for w = m to 63999
    poke 0 w
  next w
  
  gosub help_about

  if $1 = "" then goto nofile
  len $1 x
  if x < 5 then goto nofile
  size $1
  if r = 1 then goto nofile
  if s > n then goto nofile
  if s = 0 then goto nofile
  $3 = $1
  load $3 m
  
mainloop:
  rem ***MAIN LOOP***
  
  e = 2
  f = 3
  gosub highlight_on
  gosub render_image
  
  do
    waitkey k
    if k = 1 then gosub moveup
    if k = 2 then gosub movedown
    if k = 3 then gosub moveleft
    if k = 4 then gosub moveright
    if k = 18 then gosub render_image
    if k = 19 then gosub savefile
    if k = 27 then gosub mainmenu
    if k > 31 and k < 127 then gosub inschar
  loop endless
  
  
render_image:
  gosub savevar
  gosub highlight_off
  
  ink 7
  for y = 3 to 23
    move 2 y
    for x = 2 to 77
      print " " ;
    next x
  next y
  
  string load $4 m
  if $4 = "AAP" then rem
  else goto invalid_file
  
  w = m + 4
  peek v w
  if v = 1 then rem
  else goto invalid_file
  w = m + 5
  peek v w
  if v = 0 then goto invalid_file
  if v > 1 then goto invalid_file
  w = m + 6
  peekint d w
  d = d + m

  w = m + 8
  peek a w
  if a = 0 then goto invalid_file
  if a > 76 then goto invalid_file

  w = m + 9
  peek b w
  if b = 0 then goto invalid_file
  if b > 21 then goto invalid_file

  w = m + 200
  string load $4 w
  $T = "ASCII Artist - " + $4
  gosub settitle

  w = d
  move 2 3
  for y = 1 to b
    j = y + 2
    move 2 j
    for x = 1 to a
      peek v w
      ink v
      w = w + 1
      peek v w
      print chr v ;
      w = w + 1
    next x
  next y

  gosub highlight_on
  gosub loadvar
return

invalid_file:
  $E = "Rendering Error: Bad file format"
  gosub errbox
  gosub endprog
  
highlight_on:
  if o = 1 then return
  gosub savevar
  move e f
  curschar v
  curscol j
  x = j % 16
  y = 15 - x
  x = y
  j = j / 16
  y = 15 - j
  j = y * 16 + x
  ink j
  print chr v ;
  o = 1
  gosub loadvar
return

highlight_off:
  if o = 0 then return
  gosub savevar
  move e f
  curschar v
  curscol j
  x = j % 16
  y = 15 - x
  x = y
  j = j / 16
  y = 15 - j
  j = y * 16 + x
  ink j
  print chr v ;
  o = 0
  gosub loadvar
return
  
moveleft:
  if e = 2 then return
  gosub highlight_off
  e = e - 1
  gosub highlight_on
return

moveright:
  gosub savevar
  gosub highlight_off
  x = e - 1
  if a = x then goto invalid_move
  e = e + 1
  gosub highlight_on
  gosub loadvar
return

moveup:
  if f = 3 then return
  gosub highlight_off
  f = f - 1
  gosub highlight_on
return

movedown:
  gosub savevar
  gosub highlight_off
  y = f - 2
  if b = y then goto invalid_move
  f = f + 1
  gosub highlight_on
  gosub loadvar
return
  
invalid_move:
  gosub highlight_on
  gosub loadvar
return

inschar:
  gosub highlight_off
  gosub savevar
  move e f
  gosub find_key_value
  x = k % 256
  ink x
  x = k / 256
  print chr x ;
  q = k
  gosub store_data
  gosub highlight_on
  gosub loadvar
return
  
find_key_value:
  if k < 31 then k = 0
  if k > 126 then k = 0
  if k = 0 then return
  gosub savevar
  x = m + 10
  y = k - 32
  y = y * 2
  x = x + y
  peekint k x
  gosub loadvar
return
  
set_key_value:
  if k < 31 then k = 0
  if k > 126 then k = 0
  if k = 0 then return
  gosub savevar
  x = m + 10
  y = k - 32
  y = y * 2
  x = x + y
  pokeint v x
  gosub loadvar
return
  
load_data:
  gosub savevar
  x = e - 2
  y = f - 3
  j = y * a
  j = j + x
  j = j * 2
  j = j + d
  peekint q j
  gosub loadvar
return

store_data:
  gosub savevar
  x = e - 2
  y = f - 3
  j = y * a
  j = j + x
  j = j * 2
  j = j + d
  pokeint q j
  gosub loadvar
return

nofile:
  $4 = "AAP"
  string store $4 m
  w = m + 4
  poke 1 w
  w = m + 5
  poke 1 w
  w = m + 6
  pokeint 261 w
  w = m + 8
  poke 76 w
  w = m + 9
  poke 21 w
  w = m + 10
  gosub resetkey
  w = m + 200
  $4 = "Untitled Picture"
  string store $4 w
  w = m + 261
  for x = 1 to 1596
    poke 7 w
    w = w + 1
    poke 0 w
    w = w + 1
  next x
goto mainloop

mainmenu:
  do
    $T = "             Main  Menu"
    $5 = "               File"
    $6 = "               Tools"
    $7 = "               Keymap"
    $8 = "               Help"
    $9 = "               Exit"
    gosub menubox
    if v = 1 then gosub filemenu
    if v = 2 then gosub toolsmenu
    if v = 3 then gosub keymapmenu
    if v = 4 then gosub helpmenu
    if v = 5 then gosub endprog
  loop until v = 6
return

filemenu:
  do
    $T = "             File  Menu"
    $5 = "               New"
    $6 = "               Revert"
    $7 = "               Load"
    $8 = "               Save"
    $9 = "               Save As"
    gosub menubox
    if v = 1 then gosub newfile
    if v = 2 then gosub revert
    if v = 3 then gosub loadfile
    if v = 4 then gosub savefile
    if v = 5 then gosub saveas
  loop until v = 6
  v = 0
return

toolsmenu:
  do
    $T = "            Tools  Menu"
    $5 = "               Clear"
    $6 = "               Fill"
    $7 = "               Invert"
    $8 = "        Set all backcolour"
    $9 = "        Set all forecolour"
    gosub menubox
    if v = 1 then gosub clear
    if v = 2 then gosub fill
    if v = 3 then gosub invert
    if v = 4 then gosub setback
    if v = 5 then gosub setfore
  loop until v = 6
  v = 0
return

keymapmenu:
  do
    $T = "            Keymap  Menu"
    $5 = "               Reset"
    $6 = "               Load"
    $7 = "               Save"
    $8 = "             Change Key"
    $9 = "          Set all colours"
    gosub menubox
    if v = 1 then gosub resetkey
    if v = 2 then gosub loadkey
    if v = 3 then gosub savekey
    if v = 4 then gosub changekey
    if v = 5 then gosub setmapcolour
  loop until v = 6
  v = 0
return

helpmenu:
  do
    $T = "             Help  Menu"
    $5 = "               About"
    $6 = "               Basics"
    $7 = "               Files"
    $8 = "               Tools"
    $9 = "               Keymap"
    gosub menubox
    if v = 1 then gosub help_about
    if v = 2 then gosub help_basics
    if v = 3 then gosub help_files
    if v = 4 then gosub help_tools
    if v = 5 then gosub help_keymap
  loop until v = 6
  v = 0
return

newfile:
  gosub savevar
  $4 = "AAP"
  string store $4 m
  w = m + 4
  poke 1 w
  w = m + 5
  poke 1 w
  w = m + 6
  pokeint 261 w
  
  $T = "            New File (title)"
  $5 = "What do you want to call the picture?"
  $6 = "Up to 35 characters."
  v = 1
  gosub inpbox
  $4 = $I
  w = m + 200
  string store $4 w
  
  w = m + 10
  for x = 32 to 126
    poke 7 w
    w = w + 1
    poke x w
    w = w + 1
  next x

  w = m + 261
  for x = 1 to 3192
    poke 0 w
    w = w + 1
  next x
  
  $T = "            New File (size)"
  $5 = "How many columns?"
  $6 = "How many rows?"
  v = 0
  gosub dinbox
  w = m + 8
  pokeint a w
  w = m + 9
  pokeint b w
  
  gosub loadvar
  
  gosub render_image
  $3 = "" 
return

revert:
  if $3 = "" then return
  load $3 m
  gosub render_image
return

loadfile:
  $T = "               Load File"
  $5 = "Which file do you want to load?"
  $6 = "8.3 filenames only, i.e. foo.aap"
  v = 1
  gosub inpbox
  $4 = $I

  size $4
  if r = 1 then $E = "File Load Error: Invalid Filename"
  if r = 1 then goto errbox
  if s = 0 then $E = "File Load Error: Blank File"
  if s = 0 then goto errbox
  if s > n then $E = "File Load Error: Not enough memory"
  if s > n then goto errbox
  load $4 m
  $3 = $4

  string load $4 m
  if $4 = "AAP" then rem
  else $E = "File Load Error: Incorrect Filetype"
  else goto errbox
  w = m + 4
  peek v w
  if v = 0 goto badformat
  if v > 1 then goto futureversion
  w = m + 5
  if v = 0 then goto badformat
  if v > 1 then goto badformat
  w = m + 8
  peek v w
  if v > 76 then $E = "File Test Error: Not enough screen space"
  if v > 76 then goto errbox
  w = m + 9
  peek v w
  if v > 21 then $E = "File Test Error: Not enough screen space"
  if v > 21 then goto errbox

image_okay:
  gosub render_image
  
  gosub highlight_off
  e = 2
  f = 3
  gosub highlight_on
return

badformat:
  $E = "File Test Error: Bad File Format"
  goto errbox
  
futureversion:
  $T = "               Load File"
  $5 = ""
  $6 = "This file appears to have been created"
  $7 = "with a later version of this program."
  $8 = "Try to load anyway?"
  $9 = ""
  gosub askbox
  if v = 1 then goto image_okay
return

savefile:
  if $3 = "" then goto saveas
  delete $3
  
  w = m + 6
  peekint v w
  j = a * b * 2 + v
  save $3 m j
  if r > 0 then $3 = ""
  if r > 0 then $E = "File Save Error: Disk operation failed"
  if r > 0 then goto errbox
return

saveas:
  $T = "            Save File As..."
  $5 = "What filename do you want to save as?"
  $6 = "8.3 filenames only, i.e. foo.aap"
  v = 1
  gosub inpbox
  $3 = $I
goto savefile

clear:
  gosub savevar
  w = d
  for x = 1 to 1596
    poke 7 w
    w = w + 1
    poke 0 w
    w = w + 1
  next x
  
  gosub render_image
  gosub loadvar
return

fill:
  gosub savevar
  $T = "             Fill Image"
  $5 = "What character do you want to use?"
  $6 = "Must be between 0-255"
  v = 0
  gosub inpbox
  w = d + 1
  for x = 1 to 1596
    poke v w
    w = w + 2
  next x
  
  gosub render_image
  gosub loadvar
return

setback:
  gosub savevar
  $T = "         Background Colour"
  $5 = "What colour do you want to set?"
  $6 = "Must be between 0-15"
  v = 0
  gosub inpbox
  w = d
  j = v * 16
  for x = 1 to 1596
    peek v w
    v = v % 16
    v = v + j
    poke v w
    w = w + 2
  next x
  
  gosub render_image
  gosub loadvar
return

setfore:
  gosub savevar
  $T = "         Foreground Colour"
  $5 = "What colour do you want to set?"
  $6 = "Must be between 0-15"
  v = 0
  gosub inpbox
  w = d
  j = v
  for x = 1 to 1596
    peek v w
    v = v / 16
    v = v * 16
    v = v + j
    poke v w
    w = w + 2
  next x
  
  gosub render_image
  gosub loadvar
return

invert:
  gosub savevar
  w = d
  for x = 1 to 1596
    peek v w
    j = v / 16
    y = j
    j = j * 16
    v = v - j
    j = 15 - y
    j = j * 16
    v = v + j
    
    j = v % 16
    y = j
    v = v - j
    j = 15 - y
    v = v + j
    
    poke v w
    w = w + 2
  next x
  
  gosub render_image
  gosub loadvar
return

resetkey:
  gosub savevar
  w = m + 10
  for x = 32 to 126
    poke 7 w
    w = w + 1
    poke x w
    w = w + 1
  next x
  w = m + 200
  gosub loadvar
return
  
loadkey:
  $T = "           Load Keymap"
  $5 = "Which keymap do you want to load?"
  $6 = "8.3 filenames only, i.e. foo.map"
  v = 1
  gosub inpbox
  $4 = $I
  
  size $4
  if r = 1 then $E = "Load Keymap: File not found"
  if r = 1 then goto errbox
  if s > 200 then $E = "Load Keymap: Incorrect size"
  if s > 200 then goto errbox

  w = m + 3500
  load $4 w
  
  string load $4 w
  if $4 = "AAP" then rem
  else goto badformat
  w = w + 4
  peek v w
  if v = 1 then rem
  else goto badformat
  w = w + 1
  peek v w
  if v = 2 then rem
  else goto badformat
  
  w = w + 1
  j = m + 10
  for x = 1 to 190
    peek v w
    poke v j
    w = w + 1
    j = j + 1
  next x
  v = 0
return
  
badformat:
  $E = "Load Keymap: Bad format"
  goto errbox
  
savekey:
  $T = "           Save Keymap"
  $5 = "What do you want to call the keymap?"
  $6 = "8.3 filenames only, i.e. foo.map"
  v = 1
  gosub inpbox

  w = m + 3500
  $4 = "AAP"
  string store $4 w
  w = w + 4
  poke 1 w
  w = w + 1
  poke 2 w

  w = w + 1
  j = m + 10
  for x = 1 to 190
    peek v j
    poke v w
    j = j + 1
    w = w + 1
  next x
  
  w = m + 3500
  $4 = $I
  save $4 w 196
  v = 0
return
  
changekey:
  gosub savevar
  x = a
  y = b
  $T = "          Change Key"
  $5 = "Enter the ASCII value of the key"
  $6 = "Enter the new output value"
  v = 0
  gosub dinbox

  k = a
  w = b * 256
  
  $T = "          Change Key"
  $5 = "Enter the background colour"
  $6 = "Enter the foreground colour"
  v = 0
  gosub dinbox
  
  j = a * 16
  j = j + b
  v = j + w
  gosub set_key_value
  
  a = x
  b = y
  gosub loadvar
  k = 0
return

setmapcolour:
  gosub savevar
  $T = "         Set Background"
  $5 = "What colour do you want to use for"
  $6 = "the key map background (0-15)?"
  v = 0
  gosub inpbox
  if v > 15 then v = 0

  w = m + 10
  for x = 1 to 95
    peek y w
    j = y / 16
    j = j * 16
    y = y - j
    j = v * 16
    y = y + j
    poke y w
    w = w + 2
  next x

  $T = "         Set Foreground"
  $5 = "What colour do you want to use for"
  $6 = "the key map foreground (0-15)?"
  v = 0
  gosub inpbox
  if v > 15 then v = 7
  
  w = m + 10
  for x = 1 to 95
    peek y w
    j = y % 16
    y = y - j
    y = y + v
    poke y w
    w = w + 2
  next x
  gosub loadvar
return
    
help_about:
  $T = "              About"
  $5 = "ASCII Artist, version 3.0.0"
  $6 = "Copyright (C) Joshua Beck 2012"
  $7 = "Email: mikeosdeveloper@gmail.com"
  $8 = "Licenced under the GNU GPL v3"
  $9 = "Uses the MB++ library, version 3.2.2"
  gosub mesbox
return

help_basics:
  $T = "              Basics"
  $5 = "Use the arrow keys to move around."
  $6 = "Letter, word and symbol keys will"
  $7 = "create their corrosponding character"
  $8 = "Use escape to bring up the main menu"
  $9 = "and to exit from menus."
  gosub mesbox
return

help_tools:
  $T = "              Tools"
  $5 = "The tools menu helps you make large"
  $6 = "scale modifications to the picture."
  $7 = "You can clear the picture, fill it"
  $8 = "with a character, invert it and"
  $9 = "change the all the colours."
  gosub mesbox
return

help_keymap:
  $T = "             Keymap"
  $5 = "Each printable key is mapped to a"
  $6 = "character by default this character"
  $7 = "corrosponds to the one on the key"
  $8 = "and uses the colour white but you"
  $9 = "can customize these values."
  gosub mesbox
return

help_files:
  $T = "              Files"
  $5 = "ASCII Artist use its own file format."
  $6 = "This supports titles, colour, custom"
  $7 = "size, keymaps, etc. You can save"
  $8 = "your pictures in the file menu and"
  $9 = "custom key maps in the keymap menu."
  gosub mesbox
return

