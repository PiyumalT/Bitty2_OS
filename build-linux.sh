#!/bin/sh

# This script assembles the BITTYOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Linux)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs disk_images/BITTY2_os.flp')


if [ ! -e disk_images/BITTY2_OS.flp ]
then
	echo ">>> Creating new BITTY2_OS floppy image..."
	mkdosfs -C disk_images/BITTY2_OS.flp 1440 || exit
fi


echo ">>> Assembling bootloader..."

nasm -O0 -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit


echo ">>> Assembling BITTY2_OS kernel..."

cd source
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..




echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=disk_images/BITTY2_OS.flp || exit


echo ">>> Copying BITTY2_OS kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/BITTY2_OS.flp tmp-loop && cp source/kernel.bin tmp-loop/


sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/BITTY2_OS.iso
mkisofs -quiet -V 'BITTY2_OS' -input-charset iso8859-1 -o disk_images/BITTY2_OS.iso -b BITTY2_OS.flp disk_images/ || exit

echo '>>> Done!'

qemu-system-x86_64 -cdrom disk_images/BITTY2_OS.iso

