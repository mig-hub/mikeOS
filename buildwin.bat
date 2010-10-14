@echo off
echo Build script for Windows
echo.

echo Assembling bootloader...
cd source\bootload
nasm -f bin -o bootload.bin bootload.asm
cd ..

echo Assembling MikeOS kernel...
nasm -f bin -o kernel.bin kernel.asm

echo Assembling programs...
cd ..\programs
 for %%i in (*.asm) do nasm -fbin %%i
 for %%i in (*.bin) do del %%i
 for %%i in (*.) do ren %%i %%i.bin
cd ..

echo Adding bootsector to disk image...
cd disk_images
partcopy ..\source\bootload\bootload.bin 0 200 mikeos.flp 0
cd ..

echo Mounting disk image...
imdisk -a -f disk_images\mikeos.flp -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy source\kernel.bin b:\
copy programs\*.bin b:\
copy programs\test.pcx b:\
copy programs\example.bas b:\

echo Dismounting disk image...
imdisk -D -m B:

echo Done!
