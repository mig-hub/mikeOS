
REM ------------------------------------------------
REM ADVENTURE 2.3 -- By Justin Tokarchuk
REM For MikeOS and MikeBasic Derivatives
REM ------------------------------------------------

REM VARS:
REM $1 = Player Name
REM a = room number
REM b = got note
REM c = got candle
REM d = opened treasure chest
REM e = got key

a = 1
b = 0
c = 0
d = 0
e = 0
f = 0
$1 = ""

LOGO:
  CLS
  PRINT "          _______     __                     __                     __ " 
  PRINT "         |   _   |.--|  |.--.--.-----.-----.|  |_.--.--.----.-----.|  |"
  PRINT "         |       ||  _  ||  |  |  -__|     ||   _|  |  |   _|  -__||__|"
  PRINT "         |___|___||_____| \___/|_____|__|__||____|_____|__| |_____||__|"
  PRINT " "
  PRINT "         --------------------------------------------------------------"
  PRINT "                        |  A Text-Based Adventure Game  |              "
  PRINT "                         -------------------------------               "
  PRINT ""
  PRINT ""
  PRINT ""
  PRINT ""

GETNAME:
  PRINT ""
  PRINT " What do you call yourself?: " ;
  INPUT $1
  IF $1 = "" THEN GOTO GETNAME

GETNAMEREMARK:
  RAND X 1 3
  PRINT ""
  PRINT " " ;
  PRINT $1 ;
  if x = 1 then PRINT "! Did your mother even love you? Oh well, it's your name."
  if x = 2 then PRINT "? What kind of name is that! Oh well, not like we can change it."
  if x = 3 then PRINT "!? You aren't from around here, are you?"
  GOSUB PRESSAKEY
  
GOTO GAMEINTRO

HELP:
  PRINT ""  
  PRINT " The following are valid commands ingame:"
  PRINT ""
  PRINT " CLS                       - CLEARS THE SCREEN"
  PRINT " LOOK                      - REPRINTS ROOM DESCRIPTION"
  PRINT " INVENTORY                 - VIEW WHAT YOU ARE CARRYING"
  PRINT " NORTH, WEST, SOUTH, EAST  - MOVES TO INPUTTED DIRECTION"
  PRINT " EXAMINE (OBJECT)          - EXAMINES AN OBJECT"
  PRINT " USE (OBJECT)              - USES AN OBJECT"
  PRINT " TAKE (OBJECT)             - TAKES AN OBJECT"
  PRINT " OPEN (OBJECT)             - OPENS A CONTAINER"
  PRINT " UNLOCK (OBJECT)           - ATTEMPTS TO UNLOCK AN OBJECT"
  PRINT " HELP                      - VIEW THESE COMMANDS AGAIN"
  PRINT " EXIT                      - QUITS THE GAME"
  RETURN

LOWERCASE:
  J = & $2
  FOR X = 1 TO 20
    PEEK K J
    IF K < 65 THEN GOTO NOTCAPITAL
    IF K > 90 THEN GOTO NOTCAPITAL
    K = K + 32
    POKE K J
    NOTCAPITAL:
    J = J + 1
  NEXT X
RETURN

GAMEINTRO:
  PRINT ""
  PRINT " HALLOWEEN NIGHT. The spookiest night of the year! Not very spooky"
  PRINT " in your cruddy room, though. So what if toilet paper takes hours"
  PRINT " to clean off of MR. RAUL's house. Why did I have to get grounded?"
  GOSUB PRESSAKEY
  PRINT " SCREW IT. I am " ;
  PRINT $1 ;
  PRINT ", I am mighty! I will not be held down by parents!"
  PRINT " I'm going to sneak out, and prove to everyone that MR. RAUL's house"
  PRINT " is not haunted!"
  GOSUB PRESSAKEY
  PRINT " You sneak down the stairs from your room, and notice your mother is"
  PRINT " fast asleep on the couch! Opportunity is knocking! You dart through"
  PRINT " your front door and across the street to MR. RAUL's house."
  GOSUB PRESSAKEY
  PRINT " You notice the door is cracked open, you push the door open and walk"
  PRINT " inside."
  GOSUB PRESSAKEY
  PRINT " -- SLAM!! -- Oh no! The door swings shut behind you! -- CLICK! --"
  PRINT " You examine the door to find a padlock holding it shut!"
  GOSUB PRESSAKEY
  GOSUB MOVEROOM
  GOTO PARSER   
 
MOVEROOM:
  IF a = 1 THEN GOSUB R1
  IF a = 2 THEN GOSUB R2
  IF a = 3 THEN GOSUB R3
  IF a = 4 THEN GOSUB R4
  IF a = 5 THEN GOSUB R5
  IF a = 6 THEN GOSUB R6
  RETURN

R1:
  PRINT ""
  PRINT " -- The House Entrance -- "
  PRINT " The entrance of the house."
  PRINT " There is a large padlock behind you, barring your freedom." 
  RETURN

R2:
  PRINT ""
  PRINT " -- The Dining Room -- "
  PRINT " There is a large table in the middle of the room. There are multiple"
  PRINT " doors going out of this room. You see a large painting."
  RETURN

R3:
  PRINT ""
  PRINT " -- The Kitchen -- "
  PRINT " There is a doorway in this room, with the door ripped off of the"
  PRINT " hinges. Odd, you think. The rest of the kitchen seems immaculate."
  RETURN

R4:
  PRINT ""
  PRINT " -- The Bathroom -- "
  PRINT " Odd, for being a bathroom there are no windows or methods of"
  PRINT " ventilation."
  IF c = 0 THEN PRINT " There is a candle sitting atop the sink."
  RETURN

R5:
  PRINT ""
  PRINT " -- The Bedroom -- "
  PRINT " A door leads back to the dining room." 
  RETURN

R6:
  PRINT ""
  PRINT " -- The Basement -- "
  IF c = 1 THEN PRINT " + You light your candle."
  IF c = 1 THEN PRINT " There is a treasure Chest on the floor."
  IF c = 0 THEN PRINT " It is too dark to see anything in here."
  RETURN

PARSER:
  x = 0
  PRINT ""
  PRINT "> " ;
  INPUT $2
  GOSUB LOWERCASE
  IF $2 = "cls" THEN CLS
  IF $2 = "help" THEN GOSUB HELP
  IF $2 = "north" THEN GOSUB NORTH
  IF $2 = "n" THEN GOSUB NORTH
  IF $2 = "south" THEN GOSUB SOUTH
  IF $2 = "s" THEN GOSUB SOUTH
  IF $2 = "west" THEN GOSUB WEST
  IF $2 = "w" THEN GOSUB WEST
  IF $2 = "east" THEN GOSUB EAST
  IF $2 = "e" THEN GOSUB EAST
  IF $2 = "look" THEN GOSUB MOVEROOM
  IF $2 = "inventory" THEN GOSUB INVENTORY
  IF $2 = "examine rug" AND a = 1 THEN PRINT " A worn-out, stained old rug."
  IF $2 = "examine table" AND a = 2 THEN PRINT " A grandiose hardwood table."
  IF $2 = "examine table" AND a = 2 AND b = 0 THEN PRINT " A note sits atop it."
  IF $2 = "examine painting" AND a = 2 THEN PRINT " It is a picture of MR. RAUL"
  IF $2 = "take note" AND a = 2 AND b = 0 THEN b = 1
  IF $2 = "take note" AND a = 2 AND b = 1 THEN PRINT " You've taken the note."
  IF $2 = "open treasure chest" THEN GOSUB TREASURECHEST
  IF $2 = "unlock door" AND a = 1 AND e = 1 THEN GOTO GAMEEND
  IF $2 = "use note" THEN GOSUB NOTE
  IF $2 = "read note" THEN GOSUB NOTE
  IF $2 = "take candle" AND a = 4 AND c = 0 THEN GOSUB CANDLE
  IF $2 = "exit" THEN END
  IF $2 = "" THEN PRINT " Confused? Need a hand? Type HELP for a list of commands!"
  GOTO PARSER

CANDLE:
  PRINT " + You take the candle from the sink."
  c = 1
  RETURN

TREASURECHEST:
  IF a = 6 AND c = 1 THEN e = 1
  IF a = 6 AND e = 1 AND f = 0 THEN PRINT " + You open the treasure chest and take a KEY out of it."
  IF f = 1 THEN PRINT " You already have the treasure!" 
  f = 1
  RETURN    

NOTE:
  IF b = 1 THEN PRINT " The note reads:"
  IF b = 1 THEN PRINT " The secret to your freedom lies in a box!"
  RETURN

GAMEEND:
  PRINT " You unlock the door and rush outside as you gasp the free air!"
  PRINT " Nightfall is close and you almost had to spend the night! You "
  PRINT " decide that it would be wise to run home before mom wakes."
  PRINT " GAME OVER! Thanks for playing!"
  END

INVENTORY:
  PRINT ""
  IF b = 0 AND c = 0 AND e = 0 THEN GOSUB EMPTY
  IF b = 1 THEN PRINT " NOTE"   
  IF c = 1 THEN PRINT " CANDLE"  
  IF e = 1 THEN PRINT " KEY"
  RETURN

EMPTY:
  RAND X 1 5
  IF X = 1 THEN PRINT " Nothing. Not even so much as a fly out of your packsack."
  IF X = 2 THEN PRINT " You wonder why your packsack is so light, it's empty."
  IF X = 3 THEN PRINT " Your packsack has a surprising emptyness."
  IF X = 4 THEN PRINT " Apart from several dead flies in your packsack, it's empty."
  IF X = 5 THEN PRINT " You're packsack is full of loot!"
  IF X = 5 THEN PRINT " Not really, it's empty."
  RETURN

NODIR:
  RAND X 1 3
  IF x = 1 THEN PRINT " ..So that's how the wall feels on my face. Excellent."
  IF x = 2 THEN PRINT " You cannot go that way."
  IF x = 3 THEN PRINT " You win!"
  IF x = 3 THEN PRINT " .... Just kidding." 
  RETURN

NORTH:
  REM -- ENTRANCE TO DINING ROOM --
  IF a = 1 THEN x = 1
  IF a = 1 THEN a = 2
  IF x = 1 THEN GOSUB MOVEROOM
  IF x = 1 THEN RETURN
  REM -- DINING ROOM TO KITCHEN --
  IF a = 2 THEN x = 2
  IF a = 2 THEN a = 3
  IF x = 2 THEN GOSUB MOVEROOM
  IF x = 2 THEN RETURN
  GOSUB NODIR  
  RETURN

WEST:
  REM -- ENTRANCE TO BEDROOM --
  IF a = 1 THEN x = 1
  IF a = 1 THEN a = 5
  IF x = 1 THEN GOSUB MOVEROOM
  IF x = 1 THEN RETURN
  REM -- DINING ROOM TO BASEMENT --
  IF a = 2 THEN x = 2
  IF a = 2 THEN a = 6
  IF x = 2 THEN GOSUB MOVEROOM
  IF x = 2 THEN RETURN
  REM -- KITCHEN TO BATHROOM
  IF a = 3 THEN x = 3
  IF a = 3 THEN a = 4
  IF x = 3 THEN GOSUB MOVEROOM
  IF x = 3 THEN RETURN
  GOSUB NODIR
  RETURN

SOUTH:
  REM -- DINING ROOM TO ENTRANCE
  IF a = 2 THEN x = 2
  IF a = 2 THEN a = 1
  IF x = 2 THEN GOSUB MOVEROOM
  IF x = 2 THEN RETURN
  REM -- KITCHEN TO DINING ROOM --
  IF a = 3 THEN x = 3
  IF a = 3 THEN a = 2
  IF x = 3 THEN GOSUB MOVEROOM
  IF x = 3 THEN RETURN
  GOSUB NODIR
  RETURN

EAST:
  REM -- BATHROOM TO KITCHEN --
  IF a = 4 THEN x = 4
  IF a = 4 THEN a = 3
  IF x = 4 THEN GOSUB MOVEROOM
  IF x = 4 THEN RETURN
  REM -- BEDROOM TO ENTRANCE --
  IF a = 5 THEN x = 5
  IF a = 5 THEN a = 1
  IF x = 5 THEN GOSUB MOVEROOM
  IF x = 5 THEN RETURN
  REM -- BASEMENT TO DINING ROOM --
  IF a = 6 THEN x = 6
  IF a = 6 then a = 2
  IF x = 6 THEN GOSUB MOVEROOM
  IF x = 6 THEN RETURN
  GOSUB NODIR
  RETURN

PRESSAKEY:
  PRINT ""
  PRINT " -- Press any key to continue. --"
  WAITKEY X
  PRINT ""
  RETURN



