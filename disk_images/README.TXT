These are floppy disk and CD-ROM images containing MikeOS and accompanying
programs. mikeos.flp and mikeos.dmg are identical -- the latter can be used
on Mac OS X without having to change the extension.

You can use 'dd' on Linux or RAWRITE on Windows to write the floppy disk
image to a real floppy. Alternatively, you can burn the .iso to a CD-R and
boot from it in your CD burning utility.

Note that the CD image is generated automatically from the build scripts,
and uses the floppy image as a boot block (a virtual floppy disk).

In Linux/Unix, you can create a new floppy image with this command:

  mkdosfs -C mikeos.flp 1440

The build-linux.sh script does this if it doesn't find mikeos.flp.

