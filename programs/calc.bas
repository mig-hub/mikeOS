rem Calculator Application (CALC.BAS)
rem A simple calculator application.
rem Version 2.0.1
rem Made by Joshua Beck
rem Released under the GNU General Public Licence version 3
rem Send any bugs, ideas or comments to mikeosdeveloper@gmail.com

rem Uses the MB++ Library version 3.0
rem Avaliable at code.google.com/p/mikebasic-applications
INCLUDE "MBPP.BAS"

START:
  CLS
  REM MB++ initialise function
  GOSUB STARTPRG
  REM set the text colour and highlight (for the menu)
  C = 3
  H = 11
  REM set the box colour
  T = 2
  MOVE 30 13
  PRINT "Calculating..."
GOTO MAIN

MAIN:
  REM main menu
  $T = "Calculator"
  $5 = "Simple Calculations"
  $6 = "Advanced Maths"
  $7 = "Change Colour Scheme"
  $8 = "About"
  $9 = "Exit"
  GOSUB MENUBOX
  IF V = 1 THEN GOSUB BASEMATH
  IF V = 2 THEN GOSUB ADVMATH
  IF V = 3 THEN GOSUB COLCHANGE
  IF V = 4 THEN GOSUB ABOUT
  IF V = 5 THEN GOSUB ENDPROG
GOTO MAIN

COLCHANGE:
  $T = "Change Colour Scheme"
  $5 = "Input a new colour for outline, 1-255"
  $6 = "Input a new text colour, 1-15"
  V = 0
  GOSUB DINBOX
  $E = "Invalid colour"
  IF A < 1 THEN GOTO ERRBOX
  IF A > 255 THEN GOTO ERRBOX
  IF B < 1 THEN GOTO ERRBOX
  IF B > 15 THEN GOTO ERRBOX
  T = A
  C = B
  $5 = "Input a new highlight colour, 1-15"
  $6 = ""
  V = 0
  GOSUB INPBOX
  $E = "Invalid colour"
  IF V < 1 THEN GOTO ERRBOX
  IF V > 15 THEN GOTO ERRBOX
  H = V
RETURN
  
BASEMATH:
  REM start the menu loop
  DO
    REM set the menu title
    $T = "Simple Calculations"
    REM set items in the menu
    $5 = "Addition"
    $6 = "Subtraction"
    $7 = "Multiplication"
    $8 = "Division"
    $9 = "Back"
    REM call a menu
    GOSUB MENUBOX
    REM find out what they selected and gosub there
    IF V = 1 THEN GOSUB ADD
    IF V = 2 THEN GOSUB SUB
    IF V = 3 THEN GOSUB MUL
    IF V = 4 THEN GOSUB DIV
  REM present the menu again unless 'back' was selected
  LOOP UNTIL V = 5
  V = 0
RETURN

ADD:
  REM INPBOX and DINBOX use V to choose between text and numerical input
  REM we want numerical
  V = 0
  REM set the title
  $T = "Addition"
  REM first input prompt
  $5 = "Input first number..."
  REM second input prompt
  $6 = "Input second number..."
  REM DINBOX is similar to INPBOX (Print text and asks for input) but
  REM it asks for two inputs rather than just one.
  GOSUB DINBOX
  REM do the actual calculation
  REM the first input is A and the second is B
  a = a + b
  REM prompt above first number
  $5 = "Answer is:"
  REM prompt about second
  REM this is set to a blank string so it won't print it (we only need one)
  $6 = ""
  REM call a number box to print our answer
  GOSUB NUMBOX
  REM back to main menu
RETURN

SUB:
  v = 0
  $T = "Subtraction"
  $5 = "Input number to subtract from..."
  $6 = "Input number to subtract..."
  GOSUB DINBOX
  A = A - B
  $5 = "Answer is:"
  $6 = ""
  GOSUB NUMBOX
RETURN

MUL:
  v = 0
  $T = "Multiplication"
  $5 = "Input first number..."
  $6 = "Input second number..."
  GOSUB DINBOX
  A = A * B
  $5 = "Answer is:"
  $6 = ""
  GOSUB NUMBOX
RETURN

DIV:
  v = 0
  $T = "Division"
  $5 = "Input number to be divided..."
  $6 = "Input number to divide by..."
  GOSUB DINBOX
  REM define error message
  REM if the divisor is zero then present this error
  $E = "Attempted to divide by zero!"
  IF B = 0 THEN GOTO ERRBOX
  D = A / B
  E = A % B
  A = D
  B = E
  $5 = "Answer is:"
  $6 = "Reminder is:"
  GOSUB NUMBOX
RETURN

ADVMATH:
  DO
    $T = "Advanced Maths"
    $5 = "Square/Cube Number"
    $6 = "Power"
    $7 = "Mass Addition"
    $8 = "Mass Subtraction"
    $9 = "Back"
    GOSUB MENUBOX
    IF V = 1 THEN GOSUB SQUARE
    IF V = 2 THEN GOSUB POWER
    IF V = 3 THEN GOSUB MASSADD
    IF V = 4 THEN GOSUB MASSTAKE
  LOOP UNTIL V = 5
  V = 0
RETURN

SQUARE:
  $T = "Square/Cube Number"
  $5 = ""
  $6 = "Input a number to square and cube"
  V = 0
  GOSUB INPBOX
  A = V
  D = A
  A = A * D
  B = A * D
  $T = "Square/Cube Number"
  $5 = "Number Squared is:"
  $6 = "Number Cubed is:"
  GOSUB NUMBOX
RETURN

POWER:
  $T = "Power"
  $5 = "Input a number"
  $6 = "Input power to raise to"
  V = 0
  GOSUB DINBOX
  D = A
  IF B = 0 THEN A = 1
  IF B = 0 THEN GOTO POWERSKIP
  IF B = 1 THEN GOTO POWERSKIP
  DO
    A = A * D
    B = B - 1
  LOOP UNTIL B = 1
  POWERSKIP:
  $T = "Power"
  $5 = "Answer is:"
  $6 = ""
  GOSUB NUMBOX
RETURN

MASSADD:
  $T = "Mass Add"
  $5 = "Enter the base number"
  $6 = "Enter the first number to add"
  V = 0
  GOSUB DINBOX
  N = A
  N = N + B
ADDMORE:
  $T = "Mass Add"
  $5 = "Enter another number to add"
  $6 = "or zero to finish the sum"
  V = 0
  GOSUB INPBOX
  N = N + V
  IF V > 0 THEN GOTO ADDMORE
  $5 = "The base number was: "
  $6 = "The total was: "
  B = N
  GOSUB NUMBOX
RETURN

MASSTAKE:
  $T = "Mass Subtract"
  $5 = "Enter the base number"
  $6 = "Enter the first number to take"
  V = 0
  GOSUB DINBOX
  N = A
  N = N - B
TAKEMORE:
  $T = "Mass Subtract"
  $5 = "Enter another number to take"
  $6 = "or zero to finish the sum"
  V = 0
  GOSUB INPBOX
  N = N - V
  IF V > 0 THEN GOTO TAKEMORE
  $5 = "The base number was: "
  $6 = "The total was: "
  B = N
  GOSUB NUMBOX
RETURN 

ABOUT:
  $T = "About"
  $5 = "Calculator, version 2.0.1"
  $6 = "An advanced calculator application"
  $7 = "Released under the GNU GPL v3"
  $8 = "Written in MikeOS BASIC"
  $9 = "Thanks to the MikeOS developers"
  GOSUB MESBOX

  $5 = "Uses the MB++ Library, version 3.0"
  $6 = "A great TUI library"
  $7 = "Created by Joshua Beck"
  $8 = "Mail: mikeosdeveloper@gmail.com"
  $9 = "Try the new mass addition/subtraction"
  GOSUB MESBOX
RETURN
