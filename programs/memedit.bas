rem Memory Manipulator (MEMEDIT.BAS), version 3.1.1
rem An advanced memory modification tool for MikeOS
rem Copyright (C) Joshua Beck
rem Email: mikeosdeveloper@gmail.com
rem Licenced under the GNU General Public Licence v3, see LICENCE

rem Requires the MB++ library, version 3.2.3 recommended
include "mbpp.bas"

parameters:
  if $1 = "" then goto init
  size $1
  if r = 1 then print "File does not exist." 
  if r = 1 then end
  x = ramstart
  x = x / 16
  x = x + 1
  x = x * 16
  y = 65535 - x
  if s > y then print "File too big."
  if s > y then end
  load $1 x
  d = x
  f = x

init:
  gosub startprg
  z = 9
  $T = "Memory Manipulator"
  gosub settitle
  cls
  cursor off
  c = 7
  h = 9
  t = 1
  z = 1
  gosub anistart
  gosub refresh
  
  a = 5
  b = 4
  gosub update_screen
  gosub highlight_on
  
  x = ramstart
  y = progstart
  v = 0 - x
  x = x - y

  $T = "              About"
  $5 = "Memory Manipulator, version 3.1.1"
  $6 = "Copyright (C) Joshua Beck 2012"
  $7 = "Licenced under the GNU GPLv3"
  $8 = "Program Memory: " + x + " bytes"
  $9 = "Avaliable Memory: " + v + " bytes"
  gosub mesbox
goto main

main:
  do
    waitkey k
    if k = 1 then gosub go_up
    if k = 2 then gosub go_down
    if k = 3 then gosub go_left
    if k = 4 then gosub go_right
    if k = 13 then gosub new_value
    if k = 27 then gosub endprog
    if k > 96 and k < 123 then k = k - 32
    if k = 'G' then gosub go_location
    if k = 'L' then gosub load_file
    if k = 'O' then gosub save_file
    if k = 'Q' then gosub page_up
    if k = 'Z' then gosub page_down
  loop endless

go_up:
  if b = 4 then goto scroll_up
  gosub highlight_off
  b = b - 1
  d = d - 16
  gosub highlight_on
return

go_down:
  if b = 19 then goto scroll_down
  gosub highlight_off
  b = b + 1
  d = d + 16
  gosub highlight_on
return

go_left:
  if a = 5 then goto back_line
  gosub highlight_off
  a = a - 3
  d = d - 1
  gosub highlight_on
return

go_right:
  if a = 50 then goto forward_line
  gosub highlight_off
  a = a + 3
  d = d + 1
  gosub highlight_on
return

scroll_up:
  gosub highlight_off
  f = f - 16
  d = d - 16
  gosub update_screen
  gosub highlight_on
return

scroll_down:
  gosub highlight_off
  f = f + 16
  d = d + 16
  gosub update_screen
  gosub highlight_on
return

back_line:
  if b = 4 then goto sback_line
  gosub highlight_off
  b = b - 1
  a = 50
  d = d - 1
  gosub highlight_on
return

forward_line:
  if b = 19 then goto sforward_line
  gosub highlight_off
  b = b + 1
  a = 5
  d = d + 1
  gosub highlight_on
return

sback_line:
  gosub highlight_off
  a = 50
  f = f - 16
  d = d - 1
  gosub update_screen
  gosub highlight_on
return

sforward_line:
  gosub highlight_off
  a = 5
  f = f + 16
  d = d + 1
  gosub update_screen
  gosub highlight_on
return

page_up:
  gosub highlight_off
  f = f - 256
  d = d - 256
  gosub update_screen
  gosub highlight_on
return

page_down:
  gosub highlight_off
  f = f + 256
  d = d + 256
  gosub update_screen
  gosub highlight_on
return

go_location:
  t = 2
  $T = "Goto - Location"
  $5 = "Enter a hexdecimal memory address to"
  $6 = "go to between 0000 and FFFF."
  v = 1
  gosub inpbox
  $4 = $I
  
  if $4 = "" then return
  gosub highlight_off
  gosub hexstr_to_num
  w = d - f
  d = v
  v = v - w
  f = v
  gosub update_screen
  gosub highlight_on
return

new_value:
  gosub highlight_off
  move a b
  print "  "
  move a b
  w = a - 5 / 3 + 59
  move w b
  print " "
  move a b
  v = 0
  cursor on
  
  do
    waitkey k
    if k = 27 then goto bad_number
    v = 16
    if k > 47 and k < 58 then v = k - 48
    if k > 64 and k < 71 then v = k - 55
    if k > 96 and k < 103 then v = k - 87
  loop until v < 16
  print chr k ;
  v = v * 16

  do
    waitkey k
    if k = 27 then goto bad_number
    j = 16
    if k > 47 and k < 58 then j = k - 48
    if k > 64 and k < 71 then j = k - 55
    if k > 96 and k < 103 then j = k - 87
    if j < 16 then print chr k ;
  loop until j < 16
  v = v + j

  poke v d
  cursor off
  gosub update_screen
  gosub highlight_on
return

bad_number:
  loop until k = 27
  getkey k
  cursor off
  gosub update_screen
  gosub highlight_on
return
  
load_file:
  t = 14
  $T = "Load"
  $5 = "Enter a filename to load at the"
  $6 = "selected location (blank to cancel)"
  v = 1
  gosub inpbox
  $4 = $I
  if $4 = "" then return
  
  load $4 d
  if r = 1 then $E = "File does not exist!"
  if r = 1 then goto errbox

  gosub highlight_off
  gosub update_screen
  gosub highlight_on
return

save_file:
  t = 13
  $T = "Save"
  $5 = "What filename do you want to use?"
  $6 = "How many bytes to save (hex)?"
  v = 1
  gosub dinbox
  
  if $8 = "" then return
  $4 = $8
  gosub hexstr_to_num
  delete $7
  save $7 d v
  
  if r = 1 then $E = "Read-only disk!"
  if r = 1 then goto errbox
return

update_screen:
  ink 7
  w = f
  for y = 4 to 19
    move 5 y
    for x = 1 to 16
      peek v w
      w = w + 1
      print hex v ;
      print " " ;
    next x
  next y
  
  w = f
  for y = 4 to 19
    move 59 y
    for x = 1 to 16
      peek v w
      print chr v ;
      w = w + 1
    next x
  next y
return

highlight_on:
  move a b
  ink 232
  curschar v
  print chr v ;
  curschar v
  print chr v ;
  w = a - 5 / 3 + 59
  move w b
  curschar v
  print chr v
  
  ink 9
  move 74 1
  v = d / 256
  print hex v ;
  v = d % 256
  print hex v ;
  move 74 1
  for x = 1 to 4
    curschar v
    print chr v ;
  next x
return

highlight_off:
  move a b
  ink 7
  curschar v
  print chr v ;
  curschar v
  print chr v ;
  w = a - 5 / 3 + 59
  move w b
  curschar v
  print chr v
return

hexstr_to_num:
  w = & $4
  v = 0
  do
    peek j w
    gosub digit_convert
    if j < 16 then v = v * 16
    if j < 16 then v = v + j
    w = w + 1
  loop until j = 16
return
  
digit_convert:
  if j < 16 then j = 16
  if j > 47 and j < 58 then j = j - 48
  if j > 64 and j < 71 then j = j - 55
  if j > 96 and j < 103 then j = j - 87
  if j > 15 then j = 16
return

content:
  gosub savevar
  move 59 1
  ink 9
  print "Selected Byte: 0000"
  ink 3
  move 5 3
  print "0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F        0123456789ABCDEF"
  move 5 20
  print "0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F        0123456789ABCDEF"
  for y = 0 to 15
    v = y * 16
    w = y + 4
    move 2 w
    print hex v
    move 76 w
    print hex v
    move 2 w
    curschar v
    print chr v ;
    curschar v
    print chr v ;
    move 76 w
    curschar v
    print chr v ;
    curschar v
    print chr v ;
  next y
  ink 1
  move 0 21
  print chr 195 ;
  for x = 1 to 78
    print chr 196 ;
  next x
  print chr 180 ;
  ink 3
  move 2 22
  print "Use the arrow keys to move around, G for GOTO, Enter to change a value,"
  move 2 23
  print "Q for page up, Z for page down, O to Save and L to load files into memory."
return


