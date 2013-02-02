REM >>>MIKEBASIC-PLUS-PLUS-LIBRARY<<<
REM Created by Joshua Beck.
REM Version 3.0.2
REM Released under the GNU General Public Licence revision 3.
REM Requires MikeOS version 4.3 or greater.

REM Send bug reports or feedback to mikeosdeveloper@gmail.com
REM See the wiki at: http://mikebasicplusplus.wikispot.org/

PRINT "This is a library and not for direct use!"
END

ANCITEXT:
  GOSUB SAVEVAR
  ink c
  W = X
  POKE Y 65430
  CURSPOS X Y
  POKE X 65431
  DO
    IF X > W THEN X = 79
    if x > 78 then y = y + 1
    if x > 78 then peek x 65431
    PEEK J 65430
    IF Y > J THEN J = 0
    IF Y > 23 THEN J = 0
    move x y
    IF J > 0 THEN PEEK J V
    IF J = 0 THEN J = 0
    IF J < 20 THEN GOSUB ANCITXTS
    IF J > 1 THEN PRINT CHR J
    IF J > 1 THEN X = X + 1
    v = v + 1
  LOOP UNTIL J = 0
  GOSUB LOADVAR
RETURN
  
ANCITXTS:
  IF J = 0 THEN RETURN
  IF J = 7 THEN J = 255
  IF J = 10 THEN Y = Y + 1
  IF J = 10 THEN PEEK X 65431
  IF J = 10 THEN J = 1
RETURN

aniclose:
  if $Y = "DISABLE" then return
  j = 176
  gosub blockbox
  pause 1
  j = 177
  gosub blockbox
  pause 1
  j = 178
  gosub blockbox
  pause 1
  j = 219
  gosub blockbox
  pause 1
  return

aniend:
  IF $Z = "NOINT" THEN RETURN
  if $Y = "DISABLE" then return
  j = 176
  gosub blockscr
  pause 1
  j = 177
  gosub blockscr
  pause 1
  j = 178
  gosub blockscr
  pause 1
  j = 219
  gosub blockscr
  pause 5
  j = 178
  gosub blockscr
  pause 1
  j = 177
  gosub blockscr
  pause 1
  j = 176
  gosub blockscr
  pause 1
  j = 0
  gosub blockscr
  pause 1
return

aniopen:
  if $Y = "DISABLE" then return
  j = 219
  gosub blockbox
  pause 1
  j = 178
  gosub blockbox
  pause 1
  j = 177 
  gosub blockbox
  pause 1
  j = 176
  gosub blockbox
  pause 1
  return

anistart:
  if $Y = "DISABLE" then return
  j = 176
  gosub blockscr
  pause 1
  j = 177
  gosub blockscr
  pause 1
  j = 178
  gosub blockscr
  pause 1
  j = 219
  gosub blockscr
  pause 1
  j = 178
  gosub blockscr
  j = 219
  gosub blockbor
  pause 2
  j = 177
  gosub blockscr
  j = 219
  gosub blockbor
  pause 2
  j = 176
  gosub blockscr
  j = 219
  gosub blockbor
  pause 2
  j = 0
  gosub blockscr
  move 2 1
  print $T
  j = 219
  gosub blockbor
  pause 2
  j = 178
  gosub blockbor
  pause 1
  j = 177
  gosub blockbor
  pause 1
  j = 176
  gosub blockbor
  return

ARRAYGET:
  POKEINT J 65418
  IF X > 99 THEN $E = "ARRAYGET: Array over maximum"
  IF X > 99 THEN GOTO ERRBOX
  IF X < 0 THEN $E = "ARRAYGET: Number below zero"
  IF X < 0 THEN GOTO ERRBOX
  J = X
  J = J * 2
  J = J + 65000
  PEEKINT V J
  PEEKINT J 65418
RETURN

ARRAYPUT:
  POKEINT 65418
  IF X > 99 THEN $E = "ARRAYGET: Array over maximum"
  IF X > 99 THEN GOTO ERRBOX
  IF X < 0 THEN $E = "ARRAYGET: Number below zero"
  IF X < 0 THEN GOTO ERRBOX
  J = X
  J = J * 2
  J = J + 65000
  POKEINT V J
  PEEKINT J 65418
RETURN

ASKBOX:
  GOSUB OPENBOX
  move 22 11
  print $5
  move 22 12
  print $6
  move 22 13
  print $7
  move 22 14
  print $8
  move 22 15
  print $9
  move 27 16
  print "--Yes--        --No--"
  poke 1 65420
  V = 1
  gosub askdraw
  askloop:
    waitkey j
    if j = 3 then gosub swleft
    if j = 4 then gosub swright
    if j = 13 then goto askend
  goto askloop
askend:
  peek v 65420
  j = v
  if j = 0 then v = 1
  if j = 1 then v = 0
  GOSUB CLOSEBOX
  return
swleft:
  peek v 65420
  if v = 0 then return
  if v = 1 then v = 0
  poke v 65420
  gosub askdraw
  return
swright:
  peek v 65420
  if v = 1 then return
  if v = 0 then v = 1
  poke v 65420
  gosub askdraw
  return
askdraw:
  move 27 16
  if v = 0 then ink h
  if v = 1 then ink c
  print "--Yes--"
  move 42 16
  if v = 0 then ink c
  if v = 1 then ink h
  print "--No--"
return

blockbor:
  INK Z
  for x = 0 to 79
    move x 0
    PRINT CHR J ;
    move x 2
    PRINT CHR J ;
    move x 24
    PRINT CHR J ;
  next x
  for x = 1 to 23
    move 0 x
    PRINT CHR J ;
    move 79 x
    PRINT CHR J ;
  next x
return

BLOCKBOX:
  INK T
  FOR X = 8 TO 17
    MOVE 20 X
    PRINT CHR J
  NEXT X
  FOR X = 21 TO 58
    MOVE X 8
    PRINT CHR J
    MOVE X 10
    PRINT CHR J
    MOVE X 17
    PRINT CHR J
  NEXT X
  FOR X = 8 TO 17
    MOVE 59 X
    PRINT CHR J
  NEXT X
RETURN

BLOCKSCR:
  INK Z
  MOVE 0 0
  FOR X = 0 to 79
    FOR Y = 0 to 24
      PRINT CHR J ;
    NEXT Y
  NEXT X
RETURN

BORDER:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  POKE Z 65439
  INK Z
  J = 1
  Y = 0
  FOR W = 1 TO 2
    FOR X = 0 TO 2
      MOVE Y X
      READ BORDERDATA J V
      PRINT CHR V ;
      J = J + 1
    NEXT X
    Y = 79
  NEXT W
  FOR Y = 3 TO 23
    MOVE 0 Y
    PRINT CHR 179 ;
    MOVE 79 Y
    PRINT CHR 179 ;
  NEXT Y
  FOR X = 1 TO 78
    MOVE X 0
    PRINT CHR 196 ;
    MOVE X 2
    PRINT CHR 196 ;
    MOVE X 24
    PRINT CHR 196 ;
  NEXT X
  MOVE 0 24
  PRINT CHR 192 ;
  MOVE 79 24
  PRINT CHR 217 ;
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN

BORDERDATA:
218 179 195 191 179 180

BOX:
  INK T
  W = 1
  X = 20
  FOR J = 1 TO 2
    FOR Y = 8 TO 17
      MOVE X Y
      READ BOXDATA W V
      PRINT CHR V
      W = W + 1
    NEXT Y
    X = 59
  NEXT J
  V = 205
  FOR X = 21 TO 58
    MOVE X 8
    PRINT CHR V
    MOVE X 10
    PRINT CHR V
    MOVE X 17
    PRINT CHR V
  NEXT X
  INK 7
  move 21 9
  print "                                      "
  for x = 11 to 16
    move 21 x
    print "                                      "
  next x
  INK C
RETURN

BOXDATA:
201 186 204 186 186 186 186 186 186 200
187 186 185 186 186 186 186 186 186 188

BOXSAVE:
  INK 0
  V = 64200
  j = 64600
  for y = 8 to 17
    move 20 y
    for x = 20 to 59
      curschar w
      poke w j
      CURSCOL W
      POKE W V
      print " ";
      j = j + 1
      V = V + 1
    next x
  next y
return

BOXREST:
  V = 64200
  j = 64600
  for y = 8 to 17
    MOVE 20 Y
    for x = 20 to 59
      PEEK W V
      INK W
      peek w j
      print chr w ;
      j = j + 1
      V = V + 1
    next x
  next y
return

CLOSEBOX:
  POKE V 65418
  CURSOR OFF
  GOSUB ANICLOSE
  INK 7
  H = H / 16
  GOSUB BOXREST
  GOSUB LOADLOC
  GOSUB LOADVAR
  PEEK V 65418
RETURN

CONTENT:
RETURN

DINBOX:
  $E = "INPBOX: Invalid input type."
  IF V > 1 THEN GOTO ERRBOX
  IF V < 0 THEN GOTO ERRBOX
  GOSUB OPENBOX
  move 22 11
  print $5
  move 22 12
  print ">"
  move 23 12
  cursor on
  if v = 0 then input a
  if v = 1 then input $7
  move 22 13
  print $6
  move 22 14
  print ">"
  move 23 14
  if v = 0 then input b
  if v = 1 then input $8
  GOSUB CLOSEBOX
return

ENDPROG:
  z = 7
  gosub aniend
  cls
  cursor on
  FOR X = 64000 TO 65535
    POKE 0 X
  NEXT X
end

ERRBOX:
  $J = $T
  $T = "Error"
  GOSUB OPENBOX
  POKEINT V 65418
  LEN $E V
  IF V > 38 THEN $E = "Error text too long!"
  IF V > 38 THEN GOTO FATALERR
  PEEKINT V 65418
  move 22 12
  print $E
  MOVE 22 14
  PRINT "Press escape to end program."
  MOVE 22 15
  print "Press any other key to continue."
  cursor on
  move 53 15
  waitkey j
  if j = 27 then gosub endprog
  GOSUB CLOSEBOX
  $T = $J
return

FATALERR:
  MOVE 2 1
  INK 12
  PRINT "Fatal: " ;
  PRINT $E ;
  WAITKEY K
GOSUB ENDPROG

INPBOX:
  $E = "INPBOX: Invalid input type."
  IF V > 1 THEN GOTO ERRBOX
  IF V < 0 THEN GOTO ERRBOX
  GOSUB OPENBOX
  move 22 12
  print $5
  move 22 13
  print $6
  move 22 14
  print ">"
  move 23 14
  cursor on
  if v = 1 then input $I
  if v = 0 then input v
  GOSUB CLOSEBOX
return

LOADLOC:
  POKEINT X 64164
  POKEINT Y 64166
  PEEK X 65428
  PEEK Y 65429
  MOVE X Y
  PEEK X 65438
  INK X
  PEEKINT X 64164
  PEEKINT Y 64166
RETURN

LOADVAR:
  POKEINT J 65426
  PEEK J 65421
  IF J = 0 THEN $E = "Can't load variables, none stored!"
  IF J = 0 THEN GOSUB FATALERR
  J = J + 65198
  PEEKINT Y J
  J = J - 2
  PEEKINT X J
  J = J - 2
  PEEKINT V J
  J = J - 2
  PEEKINT W J
  J = J - 65202
  POKE J 65421
  J = J + 65200
  PEEKINT J J
RETURN

MENUBOX:
  GOSUB OPENBOX
  V = 11
  GOSUB MENUDRAW
  MENULOOP:
    WAITKEY W
    IF W = 1 AND V = 11 THEN GOTO MENULOOP
    IF W = 2 AND V = 15 THEN GOTO MENULOOP
    IF W = 1 THEN V = V - 1
    IF W = 2 THEN V = V + 1
    IF W < 3 THEN GOSUB MENUDRAW
    IF W = 13 THEN GOTO MENUEND
    IF W = 27 THEN $I = ""
    IF W = 27 THEN RETURN
  GOTO MENULOOP
  MENUDRAW:
    J = W
    W = V
    GOSUB MENUITEM
    IF $J = "" AND J = 1 THEN V = V + 1
    IF $J = "" AND J = 2 THEN V = V - 1
    IF $J = "" THEN W = 0
    IF $J = "" THEN RETURN
    FOR W = 11 TO 15
      INK C
      MOVE 22 W
      IF W = V THEN INK H
      GOSUB MENUITEM
      X = & $J
      Y = INK
      INK 0
      DO
        PEEK J X
        IF J > 32 THEN INK Y
        IF J > 0 THEN PRINT CHR J ;
        X = X + 1
      LOOP UNTIL J = 0
    NEXT W
    MOVE 22 16
    INK C
    PRINT "Press enter to select an option."
  RETURN
  MENUITEM:
    IF W = 11 THEN $J = $5
    IF W = 12 THEN $J = $6
    IF W = 13 THEN $J = $7
    IF W = 14 THEN $J = $8
    IF W = 15 THEN $J = $9
  RETURN
  MENUEND:
    W = V
    GOSUB MENUITEM
    IF $J = "" THEN GOTO MENULOOP
    $I = $J
    V = V - 10
  GOSUB CLOSEBOX
RETURN

MESBOX:
  GOSUB OPENBOX
  move 22 11
  print $5
  move 22 12
  print $6
  move 22 13
  print $7
  move 22 14 
  print $8
  move 22 15
  print $9
  move 22 16
  print "Press any key to continue..."
  waitkey j
  GOSUB CLOSEBOX
return

NUMBOX:
  GOSUB OPENBOX
  if $5 = "" then goto numboxa
  move 22 11
  print $5
  move 22 12
  print a
  numboxa:
  if $6 = "" then goto numboxb
  move 22 13
  print $6
  move 22 14
  print b
  numboxb:
  move 22 16
  print "Press any key to continue..."
  waitkey j
  GOSUB CLOSEBOX
return

OPENBOX:
  IF $T = "Error" THEN GOTO ERRNOVERIFY
  POKEINT V 65418
  LEN $5 V
  IF V > 38 THEN $E = "String $5 too long"
  IF V > 38 THEN GOTO ERRBOX
  LEN $6 V
  IF V > 38 THEN $E = "String $6 too long"
  IF V > 38 THEN GOTO ERRBOX
  LEN $7 V
  IF V > 38 THEN $E = "String $7 too long"
  IF V > 38 THEN GOTO ERRBOX
  LEN $8 V
  IF V > 38 THEN $E = "String $8 too long"
  IF V > 38 THEN GOTO ERRBOX
  LEN $9 V
  IF V > 38 THEN $E = "String $9 too long"
  IF V > 38 THEN GOTO ERRBOX
  PEEKINT V 65418
  ERRNOVERIFY:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  POKEINT V 65418
  GOSUB BOXSAVE
  IF C < 0 THEN C = 7
  IF C > 15 THEN C = 7
  H = H * 16
  H = H + C
  CURSOR OFF
  INK C
  MOVE 22 9
  PRINT $T
  GOSUB ANIOPEN
  GOSUB BOX
  MOVE 22 9
  PRINT $T
  PEEKINT V 65418
RETURN

pictotxt:
  GOSUB SAVEVAR	
  for x = 0 to 19
    for y = 0 to 76
      peek w v
      if w = 0 then w = 32
      poke w v
      v = v + 1
    next y
    poke 10 v
    v = v + 1
    poke 1 v
    v = v + 1
    poke 1 v
    v = v + 1
  next x
  GOSUB LOADVAR
return

REFRESH:
  GOSUB SAVEVAR
  cls
  gosub border
  gosub title
  gosub content
  GOSUB LOADVAR
return

SAVELOC:
  POKEINT X 64164
  POKEINT Y 64166
  CURSPOS X Y
  POKE X 65428
  POKE Y 65429
  X = INK
  POKE X 65438
  PEEKINT X 64164
  PEEKINT Y 64166
RETURN

SAVEVAR:
  POKEINT Y 65426
  PEEK Y 65421
  IF Y > 198 THEN $E = "Variable storage area full!"
  IF Y > 198 THEN GOSUB FATALERR
  Y = Y + 65200
  POKEINT J Y
  Y = Y + 2
  POKEINT W Y
  Y = Y + 2
  POKEINT V Y
  Y = Y + 2
  POKEINT X Y
  Y = Y + 2
  Y = Y - 65200
  POKE Y 65421
  PEEKINT Y 65426
  POKEINT X 65426
  PEEK X 65421
  X = X + 65200
  POKEINT Y X
  X = X + 2
  X = X - 65200
  POKE X 65421
  PEEKINT X 65426
RETURN

SETTITLE:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  LEN $T J
  IF J = 0 THEN RETURN
  IF J > 78 THEN RETURN
  PEEK Z 65439
  INK Z
  MOVE 1 1
  PRINT " " ;
  PRINT $T ;
  FOR X = J TO 76
    PRINT " " ;
  NEXT X
  Y = & $T
  J = J + 65441
  FOR X = 65440 TO J
    PEEK W Y
    POKE W X
    Y = Y + 1
  NEXT X
  FOR X = X TO 65514
    POKE 0 X
  NEXT X
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN

STARTPRG:
  FOR X = 64000 TO 65535
    POKE 0 X
  NEXT X
  GOSUB SAVEVAR
  V = 12288
  GOSUB XMEM
  POKE 7 65439
  C = 7
  H = 14
  T = 7
  INK 7
  GOSUB LOADVAR
RETURN

TITLE:
  GOSUB SAVEVAR
  GOSUB SAVELOC
  PEEK J 65439
  INK J
  MOVE 1 1
  PRINT " " ;
  X = 65440
  DO
    PEEK J X
    IF J < 32 AND J > 0 THEN J = 32
    PRINT CHR J ;
    X = X + 1
  LOOP UNTIL J = 0
  CURSPOS X Y
  FOR X = X TO 78
    PRINT " " ;
  NEXT X
  GOSUB LOADLOC
  GOSUB LOADVAR
RETURN

XMEM:
  GOSUB SAVEVAR
  POKEINT V 65436
  Y = 65168
  FOR X = 1 TO 32
    READ XMEMASM X W
    POKE W Y
    Y = Y + 1
  NEXT X
  GOSUB LOADVAR
RETURN  

XMEMASM:
6 161 156 255 142 192 160 142 255 139 62 144 255 170 7 195
30 139 54 144 255 161 156 255 142 216 172 31 162 142 255 195
    
XGET:
  POKEINT X 65424
  CALL 65184
  PEEK V 65422
RETURN

XPUT:
  POKEINT X 65424
  POKE V 65422
  CALL 65168
RETURN
