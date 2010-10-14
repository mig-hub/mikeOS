#!/bin/sh

# This script assembles the MikeOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Mac OS X)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files


echo ">>> MikeOS OS X build script - requires nasm and mkisofs"


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


echo ">>> Assembling bootloader..."

nasm -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit


echo ">>> Assembling MikeOS kernel..."

cd source
nasm -f bin -o kernel.bin kernel.asm || exit
cd ..


echo ">>> Assembling programs..."

cd programs

for i in *.asm
do
	nasm -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..

echo ">>> Creating floppy..."
cp disk_images/mikeos.flp disk_images/mikeos.dmg


echo ">>> Adding bootloader to floppy image..."

dd conv=notrunc if=source/bootload/bootload.bin of=disk_images/mikeos.dmg || exit


echo ">>> Copying MikeOS kernel and programs..."

rm -rf tmp-loop

dev=`hdid -nobrowse -nomount disk_images/mikeos.dmg`
mkdir tmp-loop && mount -t msdos ${dev} tmp-loop && cp source/kernel.bin tmp-loop/

cp programs/*.bin programs/example.bas programs/test.pcx tmp-loop

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit
hdiutil detach ${dev}

rm -rf tmp-loop

echo ">>> MikeOS floppy image is disk_images/mikeos.dmg"


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/mikeos.iso
mkisofs -quiet -V 'MIKEOS' -input-charset iso8859-1 -o disk_images/mikeos.iso -b mikeos.dmg disk_images/ || exit

echo '>>> Done!'

