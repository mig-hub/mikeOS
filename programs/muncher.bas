rem ** Muncher for MikeOS **
rem Created by Justin Tokarchuk
rem ------------------------------

rem VARS
rem j = score multiplier
rem x, y = coords
rem e = body
rem s = score
rem i = multipliers
rem n = wallpiece counter, gets reloaded by bonus engine

cursor off
goto logo


waitforenter:
  waitkey x
  if x = 13 then goto pregame
  if x = 27 then cursor on
  if x = 27 then END
  goto waitforenter
   
logo:
  cls
  cursor off
  move 0 7
  print "     ##     ## ##     ## ##    ##  ######  ##     ## ######## ########  ###" 
  print "     ###   ### ##     ## ###   ## ##    ## ##     ## ##       ##     ## ###"
  print "     #### #### ##     ## ####  ## ##       ##     ## ##       ##     ## ###"
  print "     ## ### ## ##     ## ## ## ## ##       ######### ######   ########   # " 
  print "     ##     ## ##     ## ##  #### ##       ##     ## ##       ##   ##       " 
  print "     ##     ## ##     ## ##   ### ##    ## ##     ## ##       ##    ##  ###" 
  print "     ##     ##  #######  ##    ##  ######  ##     ## ######## ##     ## ###" 
  print ""
  print "     ======================================================================"
  print ""
  print "                      Press ENTER to play, ESC to quit.                    "
  gosub changelook

  goto waitforenter
  
changelook:
  for b = 0 to 24
    for a = 0 to 78
      move a b
      curschar c
      if c = '#' then c = 219
      if c = '=' then c = 220
      print chr c ;
    next a
  next b
return

pregame:
  cls
  n = 0
 
  cls
  cursor off
  gosub setwalls


  rem ** Place user in middle of screen. **
  x = 40
  y = 12
  move x y

  rem ** dirs = up (1), down (2), left (3), right (4)
  rem ** start moving left

  d = 3

  rem ** score
  s = 0

  rem ** Body character.
  e = 35


gosub addapple

game:
  print chr e ;
  gosub printscore
  pause 1
  if d = 1 then pause 1
  if d = 2 then pause 1
  
  getkey k
  
  rem ** controls
  if k = 'w' then d = 1
  if k = 'W' then d = 1
  if k = 'a' then d = 3
  if k = 'A' then d = 3
  if k = 's' then d = 2
  if k = 'S' then d = 2
  if k = 'd' then d = 4
  if k = 'D' then d = 4
 
  
  rem if they press ESC exit game
  if k = 27 then goto finish
  
  if d = 1 then gosub moveupdown
  if d = 2 then gosub moveupdown
  if d = 3 then gosub moveleft
  if d = 4 then gosub moveright

  move x y
  
  curschar c
  rem ***did we collide with wall***
  if x = 79 then goto finish
  if c = 'x' then goto finish
  if c = 178 then goto finish
  if c = e then goto finish
  if c = '@' then gosub getbonus
  goto game

moveupdown:
  move x y
  print " "
  if d = 1 then y = y - 1
  if d = 2 then y = y + 1
  return


moveleft:
  print " " ;
  move x y
  print " "
  x = x - 1
  return
  
moveright: 
  if x = q AND y = r then gosub getbonus
  move x y
  print " "
  x = x + 1
  return
  
setwalls:
  a = 178

  move 0 0
  for x = 0 to 78
    print chr a ;
  next x

  move 0 23
  for x = 0 to 78
    print chr a ;
  next x

  for y = 0 to 23
    move 0 y
    print chr a ;
  next y 

  for y = 0 to 23
    move 78 y
    print chr a ;
  next y

  return  

printscore:
  move 0 24
  print "Score: " ;
  print s ;
  move x y
  return
  
addapple:
  rand q 1 77
  rand r 1 22
  g = 64
  if q = x then goto addapple
  if r = y then goto addapple
  move q r
  print chr g

  rem generate random number of wallpieces
  if s < 500 then rand g 1 2
  if s > 499 then rand g 2 5
  if s > 999 then rand g 5 10
  if s > 1999 then rand g 10 20
  morewallz:
  if s > 0 then gosub wallpiece
  g = g - 1
  if g > 0 then goto morewallz
  move x y
  return  

wallpiece:
  rem ** now add a wall piece **
  rand l 1 77
  rand m 1 22
  rem Don't put it on a character or the apple please!
  if l = q then goto wallpiece
  if l = x then goto wallpiece
  if m = r then goto wallpiece
  if m = y then goto wallpiece

  rem is the wall piece too close to the character?
  if l > x then a = l - x
  if l < x then a = x - l
  if m > y then b = m - y
  if m < y then b = y - m
  if a < 7 then goto wallpiece
  if b < 4 then goto wallpiece
  move l m
  if c = 'x' then gosub wallpiece
  print "x" ;
  
  return
  
getbonus:
  move x y
  g = 1
  print chr g
  pause 1
  move x y
  g = 2
  print chr g
  pause 1
  move x y
  g = 1
  print chr g
  pause 1
  move x y
  print " "
  rem *i = intermediate number for score bonus
  if s > 250 then j = 2
  if s > 1000 then j = 3
  if s > 3000 then j = 5
  if s > 5000 then j = 10
  gosub addapple
  j = 1
  i = 150 * j
  s = s + i
  return
  
finish:
  
  cls
  cursor off
  move 0 2
  print "                     ######      ###    ##     ## ####### "
  print "                    ##    ##    ## ##   ###   ### ##      " 
  print "                    ##         ##   ##  #### #### ##      " 
  print "                    ##   #### ##     ## ## ### ## ######  " 
  print "                    ##    ##  ######### ##     ## ##      " 
  print "                    ##    ##  ##     ## ##     ## ##      " 
  print "                     ######   ##     ## ##     ## ####### "
  print ""
  print "                     #######  ##     ## ######## ########  "
  print "                    ##     ## ##     ## ##       ##     ## "
  print "                    ##     ## ##     ## ##       ##     ## "
  print "                    ##     ## ##     ## ######   ########  "
  print "                    ##     ##  ##   ##  ##       ##   ##   "
  print "                    ##     ##   ## ##   ##       ##    ##  "
  print "                     #######     ###    ######## ##     ## "
  print ""
  print "                             Your Score Was: " ;
  print s
  print ""
  print "                               Play Again? (Y/N)"
  gosub changelook

 goto escloop
 
escloop:
  waitkey x
  cursor on
  if x = 'n' then end
  if x = 'N' then end
  if x = 27 then end
  if x = 'y' then goto logo
  if x = 'Y' then goto logo
  goto escloop
  
