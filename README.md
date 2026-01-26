Git repo for my operating system/bootloader projects.
So far just the start of the bootloader. GDT, but unfinished IDT, etc. 
Currently not accepting any contributions. This will likely change, thank you for your understanding.
Feel free to test and give feedback though.

Currently running this on a Pentium 2 (Dell Latitude CPi)


To run bootloader:
Download or copy bootloader into file.

nasm -f bin bootloader.asm -o outputfile.bin

sudo dd if=outputfile.bin of=/dev/sdb status=progress && sync

Must have NASM. Replace /dev/sdb with bootable media mount. Floppy disk suggested. 
