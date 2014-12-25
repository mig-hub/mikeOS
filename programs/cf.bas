rem Cosmic Flight (CF.BAS)
rem Created by Joshua Beck
rem Version 2.0.2
rem Released under the GNU General Public Licence v3
rem mail: mikeosdeveloper@gmail.com
goto start
    
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

start:
  cls

  rem ***Cool Intro Text***
  gosub intro  

  cls

  rem ***draw the borders***
  gosub drawscreen

  rem ***print the character***
  ink 8
  move 40 24
  print chr 202 ;
  ink 7

  e = 0
  f = 0

  rem ***get the start time***
  t = timer

  rem ***set the character position to the same as we printed***
  p = 40

  rem ***start off with a grey ship***
  c = 8
  cursor off

play:
  do
    rem ***main gameplay loop***
    do
      rem ***we scroll the screen every 0.5 seconds or 10th tick***
      n = timer
      n = n - 6 

      rem ***while waiting we process movement***
      rem ***this makes the character responsive***
      getkey k

      rem ***if the escape key is presses then end***
      if k = 27 then goto endgame

      rem ***if a capital letter is pressed, make it lowercase***
      if k > 64 and k < 91 then k = k + 32

      rem ***if a movement key was pressed move the character***
      if k = 'a' then gosub goleft
      if k = 'd' then gosub goright

      if k = ' ' then gosub fireweapon

      rem ***loop until we need to scroll***
      n = n + 1
    loop until n > t

    rem ***get the next starting time***
    t = timer

    rem ***scroll the game area down a line***
    gosub scrollscreen

    rem ***display the new score and modifiers***
    gosub printscore

    rem ***place a new item on the blank line created***
    y = 0
    gosub placebonus

    rem ***add more depending on the score***
    rem ***note that these will be mostly bad***
    if s > 1999 then gosub placebonus
    if s > 4999 then gosub placebonus
    if s > 9999 then gosub placebonus

    rem ***change colour of character for score***
    gosub colourchange

    rem ***reprint character***
    ink c
    move p 24
    print chr 202 ;
    ink 7

    rem ***reduce benefits (if any)***
    if e > 0 then e = e - 1
    if f > 0 then f = f - 1

    rem ***loop until exited or lost***
  loop endless
  cursor on
end

goleft:
  rem ***make sure character is on the screen***
  if p < 31 then return

  rem ***erase current position*** 
  move p 24
  print " " ;

  rem ***move to new position***
  p = p - 1
  move p 24
  curschar b
  gosub checkbonus

  rem ***print character in correct colour***
  ink c
  print chr 202 ;
  ink 7
return

goright:
  rem ***make sure that character is on the screen***
  if p > 49 then return

  rem ***erase current position***
  move p 24
  print " " ;

  rem ***move to new position***
  p = p + 1
  move p 24

  rem ***check for items there, apply effects***
  curschar b
  gosub checkbonus

  rem ***print character in correct colour***
  ink c
  print chr 202 ;
  ink 7
return

colourchange:
  rem ***set the colour depending on how many point have been scored***
  if s < 100 then c = 8
  if s > 99 then c = 7
  if s > 199 then c = 15
  if s > 499 then c = 14
  if s > 999 then c = 12
  if s > 1999 then c = 9
  if s > 4999 then c = 11
  if s > 9999 then c = 13
return

fireweapon:
  q = 0
  if s > 99 then q = q + 1
  if s > 199 then q = q + 1
  if s > 499 then q = q + 1
  if s > 999 then q = q + 1
  if s > 1999 then q = q + 1
  if s > 4999 then q = q + 1
  if s > 9999 then q = q + 1
  if q = 0 then return
  if e > 0 then q = q + 1
  if e > 0 then e = e - 1
  ink c
  if q = 1 then for r = 0 to 3
  if q = 2 then for r = 0 to 7
  if q = 3 then for r = 0 to 11
  if q > 3 then for r = 0 to 23
    y = 23 - r
    move p y
    print "|" ;
    if q > 4 then gosub extrawp
    y = y % 4
    if y = 3 then pause 1
  next r
  pause 1
  t = timer
  ink 7
  if q = 1 then for r = 0 to 3
  if q = 2 then for r = 0 to 7
  if q = 3 then for r = 0 to 11
  if q > 3 then for r = 0 to 23
    y = 23 - r
    move p y
    print " " ;
    if q > 4 then gosub extrawp
  next r
  move p 24
  gosub colourchange
  ink c
  print chr 202 ;
  ink 7
  if s > 99 then s = s - 100
  if s > 1999 then s = s - 200
  if s > 4999 then s = s - 500
  if s > 9999 then s = s - 1000
  gosub scrollscreen
return

extrawp:
  move p y
  curschar b
  v = p - 1
  move v y
  if v > 29 then print chr b ;
  v = p + 1
  move v y
  if v < 51 then print chr b ;
  if q = 5 then return
  v = p - 2
  move v y
  if v > 29 then print chr b ;
  v = p + 2
  move v y
  if v < 51 then print chr b ;
  if q = 6 then return
  v = p - 3
  move v y
  if v > 29 then print chr b ;
  v = p + 3
  move v y
  if v < 51 then print chr b ; 
  v = p - 4
  move v y
  if v > 29 then print chr b ;
  v = p + 4
  move v y
  if v > 51 then print chr b ;
return

checkbonus:
  rem ***make sure an item exists***
  if b = 0 then return
  if b = 32 then return

  rem ***check the effect of the item***
  i = 0
  j = 0

  rem ***positive items***
  if b = 224 then j = 10
  if b = 225 then j = 20
  if b = 227 then j = 50
  if b = 228 then j = 100
  if b = 172 then j = 250
  if b = 171 then j = 500
  if b = 252 then j = 1000
  if b = 253 then j = 2000

  rem ***negative items***
  if b = 35 then i = 50
  if b = 168 then i = 100
  if b = 254 then i = 200
  if b = 64 then i = 500
  if b = 33 then i = 1000
  if b = 19 then i = 2000

  rem ***change amount for current modifiers***
  if m = 1 then j = j + 10
  if m = 2 then j = j + 20
  if m = 3 then j = j + 50
  if m = 4 then j = j * 2
  if m = 4 then i = i * 3
  if m = 5 then j = j * 2
  if m = 5 then i = i * 3

  rem ***if a modifer is active reduce is by one use***
  if m > 0 then l = l - 1

  rem ***if it gets to zero remove the modifier***
  if l = 0 then m = 0

  rem ***if there is a negative item remove the modifer***
  if i > 0 then m = 0

  rem ***check for new powerups and create modifiers***
  if b = 43 then m = 2
  if b = 43 then l = 10
  if b = 36 then m = 3
  if b = 36 then l = 10
  if b = 42 then m = 5
  if b = 42 then l = 20

  rem ***weapons bonuses***
  if b = 94 then e = e + 5

  rem ***shield bonuses***
  if b = 62 then f = f + 50

  rem ***add positive total to the score***
  if i = 0 then s = s + j

  rem ***check score is more than negative total***
  rem ***if not the player looses***
  if i > s then goto gameover

  rem ***remove negative total from score***
  if i > 0 then s = s - i
return

gameoverani:
  219 178 177 176 32

gameover:
  rem ***display death animation***
  ink 4
  v = p - 1
  p = p + 1
  for t = 1 to 5
    read gameoverani t j
    for w = v to p
      for x = 23 to 24
        move w x
        print chr j ;
      next x
    next w
    pause 1
  next t

  rem ***print game over message***
  ink 7
  move 0 4
  print "Game Over"

  rem ***calculator how far negative the score is***
  i = i - s

  rem ***display it in red***
  move 0 0
  ink 4
  print "Energy : -" ;
  number i $1
  print $1
  waitkey k

  rem ***return everything to normal and exit***
  ink 7
  cls
  cursor on
end

endgame:
  move 0 4
  print "Game Over"
  waitkey k
  ink 7
  cls
  cursor on
end 

scrollscreen:
  rem ***scroll down one line***
  for r = 0 to 23

    rem ***uses lines in opposite direction (23-0)
    y = 23 - r

    for w = 30 to 50
      rem ***collect character***
      move w y
      curschar b
      curscol v
      
      rem ***if it's the player character then don't go over it***
      rem ***also collect the previous character as bonus***
      if w = p and y = 23 then gosub checkbonus
      if w = p and y = 23 then goto noscroll

      rem ***move down one line and print character***
      y = y + 1
      move w y
      ink v
      print chr b ;
      y = y - 1
      noscroll:
    next w

    rem ***blank line after moving***
    move 30 y
    print "                     " ;
  next r
  ink 7
return

drawscreen:
  for y = 0 to 24
    rem ***print borders***
    move 29 y
    print chr 221 ;
    move 51 y
    print chr 222 ;

    rem ***randomly place items***
    rand x 1 5
    if y < 10 and x = 1 then gosub placebonus
  next y

  rem ***print the basic information***
  move 0 0
  print "Energy : 0"
  print "Highest: 0"
  print "Modifier: None"
  print "No Weapon"
return

placebonus:
  rem ***move to a random position on y line***
  rand w 30 50
  move w y

  rem ***vary the amount of good and bad items depending on the score***
  if s = 0 then goto goodbonus
  d = s / 10
  rem ***max out at 80% bad (800 points)***
  if d > 80 then d = 80

  rem ***increase for futher scores***
  if s > 5000 then d = 90
  if s > 10000 then d = 95

  rand w 1 100
  if w < d then goto badbonus

goodbonus:
  rem ***pick a item***
  rem ***the rarer ones are more valueable***
  rem ***if the player has more point, get rarer items***
  rand w 1 88
  if s > 999 then rand w 26 92
  if s > 1999 then rand w 51 100
  if s > 4999 then rand w 76 100
  if s > 4999 and w > 95 then rand w 76 100
  if s > 9999 then rand w 91 100
  if s > 9999 and w > 95 then rand w 91 100
  if s > 9999 and w > 95 then rand w 91 100

  rem ***good bonuses (increasing value)***
  if w < 51 then v = 224
  if w > 50 and w < 76 then v = 225
  if w > 75 and w < 86 then v = 227
  if w > 85 and w < 91 then v = 228
  if w > 90 and w < 93 then v = 172
  if w = 93 then v = 171
  if w = 94 then v = 252
  if w = 95 then v = 253

  rem ***the last five are powerups***
  if w = 96 then v = 43
  if w = 97 then v = 62
  if w = 98 then v = 36
  if w = 99 then v = 94
  if w = 100 then v = 42

  rem ***print good items/powerups in green***
  ink 2
  print chr v ;
  ink 7
return

badbonus:
  rem ***pick an item***
  rem ***the rarer ones are more dangerous***
  rem ***if a player has more point, make more dangerous items***
  rand w 1 50
  if s > 999 then rand w 46 75
  if s > 1999 then rand w 51 100
  if s > 4999 then rand w 76 100
  if s > 9999 then rand w 91 100

  rem ***bad items (increasing energy loss)***
  if w < 51 then v = 35
  if w > 50 and w < 76 then v = 168
  if w > 75 and w < 86 then v = 254
  if w > 85 and w < 96 then v = 15
  if w > 95 and w < 100 then v = 33
  if w = 100 then v = 19

  rem ***print bad items in red***
  ink 4
  print chr v ;
  ink 7
return

printscore:
  rem ***print current score***
  if s > g then ink 2
  if s = g then ink 7
  if s < g then ink 4
  g = s
  move 9 0
  print "     " ;
  move 9 0
  print s
  ink 7
  if s > h then ink 2
  if s > h then h = s
  move 9 1
  print "     " ;
  move 9 1
  print h
  ink 7

  rem ***print current modifier + uses remaining***
  move 10 2
  print "                  " ;
  move 10 2
  if m = 0 then print "None" ;
  if m = 2 then print "+20" ;
  if m = 3 then print "+50" ;
  if m = 5 then print "Double" ;
  if m > 0 then print " (" ;
  if m > 0 then print l ;
  if m > 0 then print " uses)"

  rem ***find out weapon***
  q = 0
  if s > 99 then q = q + 1
  if s > 199 then q = q + 1
  if s > 499 then q = q + 1
  if s > 999 then q = q + 1
  if s > 1999 then q = q + 1
  if s > 4999 then q = q + 1
  if s > 9999 then q = q + 1
  if e > 0 then q = q + 1
  
  rem ***now print it***
  gosub colourchange
  ink c
  move 0 3
  if q = 0 then print "No Weapon      "
  if q = 1 then print "Mini Laser     "
  if q = 2 then print "Standard Laser "
  if q = 3 then print "Power Laser    "
  if q = 4 then print "Fire Laser     "
  if q = 5 then print "Mega Beam      "
  if q = 6 then print "Giga Beam      "
  if q > 6 then ink 71
  if q > 6 then print "Death Ray      "
  if q > 6 then ink 7
  ink 7
return

intro:
  cls
  x = 25
  y = 1
  cursor off
  ink 0
  move x y
  print "#### #### ### ##### ##### ####"
  y = y + 1
  move x y
  print "#    #  # #   # # #   #   #   "
  y = y + 1
  move x y
  print "#    #  # ### # # #   #   #   "
  y = y + 1
  move x y
  print "#    #  #   # # # #   #   #   "
  y = y + 1
  move x y
  print "#### #### ### # # # ##### ####"
  y = y + 2
  move x y
  print "#### #    ##### #### #  # #####"
  y = y + 1
  move x y
  print "#    #      #   #    #  #   #  "
  y = y + 1
  move x y
  print "#### #      #   # ## ####   #  "
  y = y + 1
  move x y
  print "#    #      #   #  # #  #   #  "
  y = y + 1
  move x y
  print "#    #### ##### #### #  #   #  "

  y = y - 10
  v = x + 30
  w = y + 10

  for t = x to v
    for u = y to w
      move t u
      curschar z
      if z = '#' then print chr 219 ;
    next u
  next t

  ink 15
  v = x - 5
  w = x + 35
  for u = 0 to 24
    for t = 0 to v
      move t u
      rand s 1 10
      if s = 10 then print chr 42 ;
    next t
    for t = w to 79
      move t u
      rand s 1 10
      if s = 10 then print chr 42 ;
    next t
  next u

  ink 12
  for s = 1 to 13
    if s = 7 then s = 8
    if s = 8 then y = y + 6
    w = y + 5
    read letterstart s v
    v = v + x
    s = s + 1
    read letterstart s r
    s = s - 1
    r = r - 1 + x
    for t = v to r
      for u = y to w
        move t u
        curschar z
        print chr z ;
      next u
    next t
    if s < 7 then pause 2
    sound 5000 1
  next s

  y = y - 6
  w = x - 3
  u = x + 33
  ink 8
  for v = 0 to 24
    move w v
    print chr 219 ; 
    move u v
    print chr 219 ;
    t = timer
    do 
      z = timer
    loop until z > t
  next v

  ink 28
  w = w + 1
  u = u - 1
  for v = 0 to 24
    for t = w to u
      move t v
      curschar s
      print chr s ;
    next t
  next v

  pause 1

  ink 31
  w = y + 12
  v = x - 1
  move v w
  print "Cosmic Flight is a fast paced"
  gosub newline
  print "adventure game, in which you must"
  gosub newline
  print "guide your small ship through a"
  gosub newline
  print "dangerous galaxy, collecting as"
  gosub newline
  print "much energy as possible."
  gosub newline
  gosub newline
  print "Use 'A' and 'D' to move and space"
  gosub newline
  print "to fire your laser weapon."
  gosub newline
  print "Collect " ;
  ink 18
  print "green" ;
  ink 31 
  print " items and avoid " ;
  ink 20
  print "red" ; 
  ink 31
  gosub newline
  print " ones. As you get more powerful,"
  gosub newline
  print "the game will become much harder."

  v = x - 21
  w = y + 12
  ink 2
  move v w
  print "Good Items:"
  gosub newline
  print chr 224 ;
  print " =   10 Energy"
  gosub newline
  print chr 225 ;
  print " =   20 Energy"
  gosub newline
  print chr 227 ;
  print " =   50 Energy"
  gosub newline
  print chr 228 ;
  print " =  100 Energy"
  gosub newline
  print chr 172 ;
  print " =  250 Energy"
  gosub newline
  print chr 171 ;
  print " =  500 Energy"
  gosub newline
  print chr 252 ;
  print " = 1000 Energy"
  gosub newline
  print chr 253 ;
  print " = 2000 Energy"

  v = x + 36
  w = y + 12
  move v w
  ink 4
  print "Bad Items:"
  gosub newline
  print chr 35 ;
  print " =   -50 Energy"
  gosub newline
  print chr 168 ;
  print " =  -100 Energy"
  gosub newline
  print chr 254 ;
  print " =  -200 Energy"
  gosub newline
  print chr 15 ;
  print " =  -500 Energy"
  gosub newline
  print chr 33 ;
  print " = -1000 Energy"
  gosub newline
  print chr 19 ;
  print " = -2000 Energy"  

  v = x - 1
  w = y + 23
  move v w
  ink 31
  print "Press any key to start... " ;
  v = v + 25
  move v w
  cursor on
  waitkey k

  cls
  ink 7
  r = 0
  s = 0
  t = 0 
  u = 0
  v = 0
  w = 0
  x = 0
  y = 0
  z = 0
return

letterstart:
  0 5 10 14 20 26 31
  0 5 10 16 21 26 32

newline:
  w = w + 1
  move v w
  pause 2
return
