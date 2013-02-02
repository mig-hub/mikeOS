rem *** MikeOS BASIC demo ***

cls

$1 = "Hex dumper,MikeTron"
$2 = "Choose a program to run,"
$3 = "Or press Esc to exit"

listbox $1 $2 $3 a

if a = 1 then goto runhex
if a = 2 then goto runmiketron

cls
end


runhex:

rem *** Hex dumper ***

cls

print "Enter a filename to make a hex dump from:"
input $1

x = RAMSTART

load $1 x
if r = 1 then goto hexerror

hexloop:
  peek a x
  print hex a ;
  print "  " ;
  x = x + 1
  s = s - 1
  if s = 0 then goto hexfinish
  goto hexloop

hexfinish:
print ""
end

hexerror:
print "Could not load file! Does it exist?"
end



runmiketron:

rem *** MikeTron ***

cls

print "You control a vehicle leaving a trail behind it."
print ""
print "It is always moving, and if it crosses any part"
print "of the trail or border (+ characters), the game"
print "is over. Use the Q and A keys to change the direction"
print "to up and down, and O and P for left and right."
print "See how long you can survive! Score at the end."
print ""
print "NOTE: May perform at wrong speed in emulators!"
print ""
print "Hit a key to begin..."

waitkey x


cls
cursor off


rem *** Draw border around screen ***

gosub setupscreen


rem *** Start in the middle of the screen ***

x = 40
y = 12

move x y


rem *** Movement directions: 1 - 4 = up, down, left, right ***
rem *** We start the game moving right ***

d = 4


rem *** S = score variable ***

s = 0


mainloop:
  print "+" ;

  pause 1

  getkey k

  if k = 'q' then d = 1
  if k = 'a' then d = 2
  if k = 'o' then d = 3
  if k = 'p' then d = 4

  if d = 1 then y = y - 1
  if d = 2 then y = y + 1
  if d = 3 then x = x - 1
  if d = 4 then x = x + 1

  move x y

  curschar c
  if c = '+' then goto finish

  s = s + 1
  goto mainloop


finish:
cursor on
cls

print "Your score was: " ;
print s
print "Press Esc to finish"

escloop:
  waitkey x
  if x = 27 then end
  goto escloop


setupscreen:
  move 0 0
  for x = 0 to 78
    print "+" ;
  next x

  move 0 24
  for x = 0 to 78
    print "+" ;
  next x

  move 0 0
  for y = 0 to 24
    move 0 y
    print "+" ;
  next y

  move 78 0
  for y = 0 to 24
    move 78 y
    print "+" ;
  next y

  return

