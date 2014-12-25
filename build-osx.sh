#! /bin/bash

if test "`whoami`" != "root" ; then
 	echo "[halt] Not running with superuser privileges."
 	exit
fi

echo "[okay] Running from superuser"

vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

nasm_version_check () {
    vercomp $nasm_ENV $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [ $op = '=' ] || [ $op = '>' ]
    then
        echo "[okay] nasm version at least 2.10.09"
        nasm_okay=true
    else
        echo "[halt] nasm version is too low"
    fi
}

if [[ ! -f /usr/bin/nasm  &&  ! -f /bin/nasm  && ! -f /usr/sbin/nasm  &&  ! -f /sbin/nasm  &&  ! -f /usr/local/bin/nasm  && ! -f /usr/x11/bin/nasm  && ! -f /opt/local/bin/nasm ]] ; then
	echo [halt] nasm was not found on the system! Make sure it is named nasm and in the right place.
	exit
elif [ -f /opt/local/bin/nasm ] ; then
	nasm_version_string_full=$(/opt/local/bin/nasm -v 2>&1)
	nasm_ENV=${nasm_version_string_full:13:7}
	nasm_version_check $nasm_ENV 2.10.09
	if $nasm_okay
	then
		full_nasm_path="/opt/local/bin/nasm"
	fi
elif [ [ -f /usr/bin/nasm ] -a  [ ! $nasm_okay ] ] ; then
	nasm_version_string_full=$(/usr/bin/nasm -v 2>&1)
	nasm_string_trash=
	nasm_ENV=${nasm_version_string_full:13:7}
	echo $items
	nasm_version_check $nasm_ENV 2.10.09
	if $nasm_okay
	then
		full_nasm_path="/usr/bin/nasm"
	fi
elif [ [ -f /bin/nasm ] -a  [ ! $nasm_okay ] ] ; then
	nasm_version_string_full=$(/bin/nasm -v 2>&1)
	nasm_ENV=${nasm_version_string_full:13:7}
	nasm_version_check $nasm_ENV 2.10.09
	if $nasm_okay
	then
		full_nasm_path="/bin/nasm"
	fi
elif [ [ -f /usr/sbin/nasm ] -a  [ ! $nasm_okay ] ] ; then
	nasm_version_string_full=$(/usr/sbin/nasm -v 2>&1)
	nasm_ENV=${nasm_version_string_full:13:7}
	nasm_version_check $nasm_ENV 2.10.09 '>='
	if $nasm_okay
	then
		full_nasm_path="/usr/sbin/nasm"
	fi
elif [ [ -f /sbin/nasm ] -a  [ ! $nasm_okay ] ] ; then
	nasm_version_string_full=$(/sbin/nasm -v 2>&1)
	nasm_ENV=${nasm_version_string_full:13:7}
	nasm_version_check $nasm_ENV 2.10.09
	if $nasm_okay
	then
		full_nasm_path="/sbin/nasm"
	fi
elif [ [ -f /usr/local/bin/nasm ] -a  [ ! $nasm_okay ] ] ; then
	nasm_version_string_full=$(/usr/local/bin/nasm -v 2>&1)
	nasm_ENV=${nasm_version_string_full:13:7}
	nasm_version_check $nasm_ENV 2.10.09
	if $nasm_okay
	then
		full_nasm_path="/usr/local/bin/nasm"
	fi
elif [ [ -f /usr/x11/bin/nasm ] -a  [ ! $nasm_okay ] ] ; then
	nasm_version_string_full=$(/usr/x11/bin/nasm -v 2>&1)
	nasm_ENV=${nasm_version_string_full:13:7}
	nasm_version_check $nasm_ENV 2.10.09
	if $nasm_okay
	then
		full_nasm_path="/usr/x11/bin/nasm"
	fi
else
	echo "[halt] nasm not found or version is incompatible"
fi
$full_nasm_path -O0 -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit
echo "[okay] Assembled bootloader"
cd source
$full_nasm_path -O0 -f bin -o kernel.bin kernel.asm || exit
cd ..
echo "[okay] Assembled kernel"
cd programs
for i in *.asm
do
	/opt/local/bin/nasm -O0 -f bin $i -o `basename $i .asm`.bin || exit
	echo "[okay] Assembled program: $i"
done
cd ..
cp disk_images/mikeos.flp disk_images/mikeos.dmg
echo "[okay] Copied floppy image"
dd conv=notrunc if=source/bootload/bootload.bin of=disk_images/mikeos.dmg || exit
echo "[okay] Added bootloader to image"
rm -rf tmp-loop
dev=`hdid -nobrowse -nomount disk_images/mikeos.dmg`
mkdir tmp-loop && mount -t msdos ${dev} tmp-loop && cp source/kernel.bin tmp-loop/
cp programs/*.bin programs/*.bas programs/sample.pcx tmp-loop
echo "[okay] Added programs to image"
diskutil umount tmp-loop || exit
hdiutil detach ${dev}
rm -rf tmp-loop
echo "[okay] Unmounted floppy image"
rm -f disk_images/mikeos.iso
mkisofs -quiet -V 'MIKEOS' -input-charset iso8859-1 -o disk_images/mikeos.iso -b mikeos.dmg disk_images/ || exit
echo "[okay] Converted floppy to ISO-8859-1 image"
echo "[done] Build completed"
