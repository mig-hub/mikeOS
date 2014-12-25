if $1 = "" then goto help
d = ramstart

main:
  rem >>> Collect command, help if invalid <<<
  gosub collect_parameter
  if $2 = "HELP" then goto help
  if $2 = "CREATE" then goto create_archive
  if $2 = "ADD" then goto add_file
  if $2 = "REMOVE" then goto remove_file
  if $2 = "EXTRACT" then goto extract_file
  if $2 = "EXTRACTALL" then goto extract_all
  if $2 = "LIST" then goto archive_list
goto help

collect_parameter:
  rem >>> Collects a parameter separated by a space to $2 <<<
  rem >>> Offset(P) updated each time <<<
  x = & $1
  x = x + p
  do
    x = x + 1
    peek v x
    if v = 0 then v = 32
  loop until v = 32
  poke 0 x
  x = & $1
  x = x + p
  string load $2 x
  len $2 v
  p = p + v + 1
  case upper $2
return

collect_list_item:
  rem >>> Collect an item from a comma separated list $2 to $3 <<<
  rem >>> offset in Q, returns null if list finished <<<
  if q = 255 then $3 = ""
  if q = 255 then return
  x = & $2
  x = x + q
  do
    x = x + 1
    peek v x
    if v = 0 then v = 44
    if v = 32 then v = 44
  loop until v = 44
  peek v x
  poke 0 x
  x = & $2
  x = x + q
  string load $3 x
  if v < 33 then q = 255
  len $3 v
  if q < 255 then q = q + v + 1
  case upper $3
return

find_free_block:
  rem >>> Find a free block big enough for filesize S <<<
  rem >>> Returns N = block number, M = number of blocks <<<

  if s = 0 then return

  x = d + 14
  peek y x

  rem turn raw size into a number of 512 byte blocks
  m = s / 512
  v = s % 512
  if v > 0 then m = m + 1
  w = 0
  z = 0

  x = d + 5
  peekint v x
  x = d + v

  rem search the allocation map for free space
  do
    peek v x
    x = x + 1
    if v = 0 then w = w + 1
    if v > 0 then w = 0
    z = z + 1
    rem if we exceed the allocation map there is no space
    if z > y then print "There is no area large enough for this file."
    if z > y then end
  loop until w = m

  n = z - m
return

allocate_file_entry:
  rem >>> Create a file entry with filename $3, size S and the used block <<<
  rem >>> Must run find_free_block first to get file area <<<

  rem check the maximum files is not reached
  x = d + 11
  peek v x
  x = d + 12
  peek w x
  if v = w then print "No free file entries."
  if v = w then end
  rem increase files in archive
  v = v + 1
  x = d + 11  
  poke v x
  
  x = d + 7
  peekint v x
  x = v + d
  z = 0
  rem search the file list for blank entries
  do
    peek v x
    x = x + 17
    z = z + 1
    if z > w then print "No free file entries."
    if z > w then end
  loop until v = 0
  x = x - 17

  w = d + 9
  peekint z w
  
  rem store information in entry
  string store $3 x
  x = x + 13
  o = n * 512 + z
  pokeint o x
  x = x + 2
  pokeint s x
return

allocate_free_block:
  rem >>> Allocate free block found with find_free_block <<<

  x = d + 5
  peekint v x
  x = d + v + n

  rem store area as allocated
  w = m
  do
    poke 1 x
    x = x + 1
    w = w - 1
  loop until w = 0

  rem if the last block allocate is more than highest block, update
  w = n + m - 1
  x = d + 13
  peek v x
  if w > v then v = w
  poke v x
return

collect_file_data:
  rem >>> find filename $3 in the file list and get offset(O) and size(S) <<<
  x = d + 12
  peek z x

  x = d + 7
  peekint v x
  x = d + v

  rem search file entries until we find a match
  w = 0
  y = 0
  do
    string load $4 x
    if $4 = $3 then w = 1
    x = x + 17
    y = y + 1
    if y = z then print "File does not exist."
    if y = z then end
  loop until w = 1
  
  rem collect information
  x = x - 17
  x = x + 13
  peekint o x
  x = x + 2
  peekint s x
return

deallocate_block:
  rem >>> Deallocate block used by a file <<<
  rem >>> Run collect_file_info first <<<

  x = d + 9
  peekint v x

  rem figure out block number and amount from offset and size
  n = o - v / 512
  m = s / 512
  v = s % 512
  if v > 0 then m = m + 1
  if m = 0 then return

  x = d + 5
  peekint v x
  x = v + n + d
  y = m
  rem store blocks as unused
  do
    poke 0 x
    x = x + 1
    y = y - 1
  loop until y = 0

  x = d + 14  
  peek z x
  x = d + 5
  peekint v x
  x = d + v + z - 1
  
  rem find the new highest block and update
  z = z + 1
  do
    peek v x
    x = x - 1
    z = z - 1
    if z = 0 then v = 1
  loop until v = 1 

  x = d + 13
  poke z x
return

deallocate_file_entry:
  rem >>> Remove file entry with name $3 <<<
  rem >>> Must run collect_file_data first <<<

  rem reduce files in archive
  x = d + 11
  peek v x
  v = v - 1
  poke v x

  x = d + 7
  peekint v x
  x = d + v
  
  rem find file entry
  w = 0
  do
    string load $4 x
    x = x + 17
    if $4 = $3 then w = 1
  loop until w = 1

  rem blank file entry
  x = x - 17
  for y = 1 to 17
    poke 0 x
    x = x + 1
  next y
return
  
load_archive:
  rem >>> load and verify archive <<<

  print "Opening Archive..."
  rem get name off the commandline parameters
  gosub collect_parameter
  load $2 d
  rem preserve opened name
  $8 = $2

  rem make sure file is valid
  if s = 0 then print "Archive file is blank."
  if s = 0 then end

  if r = 1 then print "Archive file does not exist."
  if r = 1 then end

  rem check for archive header
  string load $4 d
  if $4 = "MFA" then rem
  else print "Not an archive file."
  else end

  rem check version is current
  x = d + 4
  peek v x
  if v > 1 then print "Archive version not supported."
  if v > 1 then end
return

save_archive:
  rem >>> calculate size and store archive <<<

  print "Saving Archive..."
  rem header size
  z = 14
  
  rem allocate block size
  x = d + 14
  peek v x
  z = z + v

  rem file list size
  x = d + 12
  peek v x
  v = v * 17
  z = z + v

  rem save only up to the last allocated block of data
  x = d + 13
  peek v x
  v = v + 1
  v = v * 512
  z = z + v

  rem save per existing name, overwrite
  delete $8
  save $8 d z
return

help:
  rem present is no arguments, help argument or invalid argument
  print "============================"
  print "ARCHIVE: File archiving tool"
  print "============================"
  print "Version 1.0.0"
  print "Copyright (C) Joshua Beck"
  print "Email: mikeosdeveloper@gmail.com"
  print "Licenced under the GNU General Public Licence v3"
  print ""
  print "Syntax: ARCHIVE (command) (archive filename) [comma separated list]"
  print ""
  print "Commands:"
  print "    Create - Create an empty archive"
  print "    Add - Added listed files to archive"
  print "    Remove - Remove listed files from archive"
  print "    Extract - Extract listed files from archive"
  print "    ExtractAll - Extract all files from archive"
  print "    List - List files in an  archive"
  print "    Help - Display this help screen"
  print ""
end

create_archive:
  rem >>> create new archive <<<

  rem file identifier
  d = ramstart
  $4 = "MFA"
  string store $4 d

  rem file version
  x = d + 4
  poke 1 x

  rem allocation map offset
  x = d + 5
  pokeint 15 x

  rem file list offset
  x = d + 7
  pokeint 45 x

  rem data offset
  x = d + 9
  pokeint 385 x

  rem files in archive
  x = d + 11
  poke 0 x

  rem file list entries
  x = d + 12
  poke 20 x

  rem highest allocated block
  x = d + 13
  poke 0 x

  rem blocks (512 bytes) in allocation map
  x = d + 14
  poke 40 x

  rem create blank allocation map
  x = d + 15
  for y = 1 to 40
    poke 0 x
    x = x + 1
  next y

  rem create blank file list
  x = d + 45
  for y = 1 to 340
    poke 0 x
    x = x + 1
  next y

  rem collect filename off parameter list
  gosub collect_parameter
  $8 = $2
  gosub save_archive
  print "File created."
end

add_file:
  gosub load_archive

  gosub collect_parameter
  gosub collect_list_item

  t = 0
  do
    $4 = "Adding file: " + $3
    print $4

    size $3 
    gosub find_free_block
    gosub allocate_file_entry
    gosub allocate_free_block  

    v = d + o
    load $3 v
    if r = 1 then print "File does not exist."
    if r = 1 then end

    gosub collect_list_item
    if $3 = "" then t = 1
  loop until t = 1

  gosub save_archive
  print "All files added successfully."
end

remove_file:
  gosub load_archive

  gosub collect_parameter
  gosub collect_list_item

  t = 0
  do
    $4 = "Removing file: " + $3
    print $4

    gosub collect_file_data
    gosub deallocate_block
    gosub deallocate_file_entry

    gosub collect_list_item
    if $3 = "" then t = 1
  loop until t = 1

  gosub save_archive
  print "All files successfully removed."
end

extract_file:
  gosub load_archive

  gosub collect_parameter
  gosub collect_list_item

  t = 0
  do
    $4 = "Extracting file: " + $3
    print $4

    gosub collect_file_data
    v = o + d
    delete $3
    save $3 v s
    if r > 0 then print "Invalid filename or read-only disk."
    if r > 0 then end

    gosub collect_list_item
    if $3 = "" then t = 1
  loop until t = 1

  print "All files extracted successfully."
end

extract_all:
  gosub load_archive
  
  x = d + 12
  peek w x
  w = w * 17
  x = d + 7
  peekint t x
  t = t + d
  u = t + w

  do
    string load $3 t
    t = t + 17

    $4 = "Extracting file: " + $3
    if $3 = "" then rem
    else print $4

    gosub collect_file_data
    v = o + d
    if $3 = "" then rem
    else delete $3
    else save $3 v s

    if r = 1 then print "Invalid filename or read-only disk."
    if r = 1 then end
  loop until t = u

  print "All files extracted successfully."
end

archive_list:
  gosub load_archive

  x = d + 11
  peek a x
  $4 = "File in archive: " + a
  x = d + 12
  peek b x  

  $4 = "Files in archive:   " + a
  $5 = "Maximum files:      " + b
  $6 = "Archive size:       " + s

  print "Mega File Archive - Version 1"
  print $4
  print $5
  print $6
  print "File list:"
  if v = 0 then end

  x = d + 12
  peek w x
  x = d + 7
  peekint v x
  x = d + v
  
  do
    string load $4 x
    if $4 = "" then rem
    else print $4
    x = x + 17
    w = w - 1
  loop until w = 0
end


