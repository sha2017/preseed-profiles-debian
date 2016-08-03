For usb key preseeding create a single vfat partition on a usb key 
set the type to 6 "FAT16"
install grub to the usb partition using the location $USBKEY/boot/ as the install directory 
then copy a debian ISO to the root of the usbkey and prepend the name debian- to the start of it so the ISO_Scan can find it. 
then you can use the grub.cfg to add more profiles. 
