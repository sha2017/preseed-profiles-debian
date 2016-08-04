
#!/bin/sh
# Manually create LVM configuration
# Partman does not currently support multi-disk lvm
# Designed to be run after download-installer but before partman-base
# This allows us to modify partman-base.postinst after it's been dropped in by anna
# Partman appears to be entirely an external program, removing the call to partman from partman-base.postinst prevents it from running.

case "$1" in
 installer)
  # we should have d-i downloaded by now.
  # partman comes in a udeb from the network so we have to hook here
  # and replace the partman-base.postinst file
  sed -i 's/partman/\/tmp\/lvm.sh partman/' /var/lib/dpkg/info/partman-base.postinst
  logger lvm.sh modified partman-base.postinst
 ;;
 partman)
  # do filesystem stuff: detect our config, fdisk, lvms, mount /target
  logger lvm.sh partition configuration starting
  modprobe dm_mod

  # FIXME: This is going to be really dirty to handle our configurations. More work will need to be done later.
  #      case1: sda: 1171842048 hda: 125056
  #      case2: sda: 976519168 hda: 58605120
  #      case3: sda: 732389376 hda:
  
  SIZE_SDA=`sed -n 's/.* \([0-9]*\) sda$/\1/p' < /proc/partitions`
  SIZE_HDA=`sed -n 's/.* \([0-9]*\) hda$/\1/p' < /proc/partitions`

  echo sda: $SIZE_SDA hda: $SIZE_HDA
  
  # pvcreate filters (ignored by filtering) if the there's a partition table
  dd if=/dev/zero of=/dev/sda bs=512 count=1
 
  # check for separate physical boot drive
  if [ $SIZE_HDA ] ; then
   # we have the boot disk create a primary partition
   echo ",,83" | sfdisk /dev/hda
  
   
   pvcreate -ff -y /dev/sda
   BOOT=/dev/hda1
   LVM=/dev/sda
  else
   # no separate boot drive
   echo -e ",256,83\n,,8e" | sfdisk -uM /dev/sda

   pvcreate -ff -y /dev/sda2
   BOOT=/dev/sda1
   LVM=/dev/sda2
  fi
  
  mke2fs -q $BOOT
  vgcreate -s 256M system $LVM
  
  if [ $SIZE_SDA -gt 700000000 ] ; then
   COMPLEXFS=1
   lvcreate -L 20G -n stuff1 system
   lvcreate -L 20G -n stuff2 system
   lvcreate -L 8G -n swap system
   lvcreate -L 20G -n stuff3 system
   lvcreate -L 200G -n stuff4 system
   lvcreate -L 200G -n stuff5 system
   lvcreate -L 200G -n stuff6 system

   for fs in stuff1 stuff2 stuff3 stuff4 stuff5 stuff6 ; do mkfs.reiserfs -q /dev/system/$fs 1>/dev/null; done

  else
   # FIXME: swap too big for vmware
   lvcreate -L 8G -n swap system
   lvcreate -l `pvdisplay | sed -n 's/Free PE \([0-9]*\)/\1/p'` -n config1 system

   mkfs.reiserfs -q /dev/system/stuff1 1>/dev/null
  fi

  # setup common swap
  mkswap /dev/system/swap
  swapon /dev/system/swap

  # Create directory structure
  mkdir /target
  mount /dev/system/stuff11 /target -treiserfs
  mkdir /target/boot
  mount $BOOT /target/boot -text2
  if [ $COMPLEXFS ] ; then
   mkdir -p /target/stuff2
   mkdir -p /target/stuff3
   mkdir -p /target/stuff4
   mount /dev/system/stuff2 /target/stuff2
  fi

  # Create fstab 
  mkdir /target/etc
  echo \# /etc/fstab: static file system information. > /target/etc/fstab
  echo \# >> /target/etc/fstab
  echo "#                   " >> /target/etc/fstab
  echo $BOOT     /boot   ext2  defaults  1  2 >> /target/etc/fstab
  echo /dev/system/stuff1       /    reiserfs acl,user_xattr 1  1 >> /target/etc/fstab
  if [ $COMPLEXFS ] ; then
   echo /dev/system/stuff2  /stuff2   reiserfs acl,user_xattr 1  2 >> /target/etc/fstab
   echo /dev/system/stuff3  /stuff3  reiserfs acl,user_xattr 1  2 >> /target/etc/fstab
   echo /dev/system/stuff4  /stuff4  reiserfs acl,user_xattr 1  2 >> /target/etc/fstab
  fi  
  echo /dev/system/swap  none   swap  sw    0  0 >> /target/etc/fstab
  echo proc     /proc   proc     defaults        0       0 >> /target/etc/fstab

  # Secret udev rules hack for network cards
  mkdir -p /target/etc/udev/rules.d
  echo \# on board e100 > /target/etc/udev/rules.d/50-network.rules
  echo KERNELS==\"0000:00:06.0\", NAME=\"eth2\" >> /target/etc/udev/rules.d/50-network.rules
  echo \# on board tg3 \(2x1000\) >> /target/etc/udev/rules.d/50-network.rules
  echo KERNELS==\"0000:02:09.0\", NAME=\"eth0\" >> /target/etc/udev/rules.d/50-network.rules
  echo KERNELS==\"0000:02:09.1\", NAME=\"eth1\" >> /target/etc/udev/rules.d/50-network.rules

 ;;
 *)
  echo $0: This script is destructive and should only be run as part of the debian-installer process
 ;;
esac
