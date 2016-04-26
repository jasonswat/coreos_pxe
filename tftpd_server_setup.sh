#!/bin/bash
sudo apt-get install tftpd-hpa inetutils-inetd
#sudo vi /etc/default/tftpd-hpa
# it should look like this:

# /etc/default/tftpd-hpa
#
#TFTP_USERNAME="tftp"
#TFTP_DIRECTORY="/tftpboot"
#TFTP_ADDRESS="0.0.0.0:69"
#TFTP_OPTIONS="--secure"

if [ ! -d /tftpboot/pxelinux.cfg/ ]; then
  sudo mkdir -p /tftpboot/pxelinux.cfg/
fi
function default_setup {
  if [ ! -f /tftpboot/pxelinux.cfg/pxe.conf ]; then
    sudo tee /tftpboot/pxelinux.cfg/pxe.conf <<EOF
MENU TITLE  PXE Server 
MENU BACKGROUND pxelinux.cfg/logo.png
NOESCAPE 1
ALLOWOPTIONS 1
PROMPT 0
menu width 80
menu rows 14
MENU TABMSGROW 24
MENU MARGIN 10
menu color border               30;44      #ffffffff #00000000 std
EOF
  fi
  if [ ! -f /tftpboot/pxelinux.cfg/default ]; then
  sudo tee /tftpboot/pxelinux.cfg/default <<EOF
DEFAULT vesamenu.c32 
TIMEOUT 600
ONTIMEOUT BootLocal
PROMPT 0
MENU INCLUDE pxelinux.cfg/pxe.conf
NOESCAPE 1
LABEL BootLocal
        localboot 0
        TEXT HELP
        Boot to local hard disk
        ENDTEXT
MENU TITLE CoreOS
        LABEL Previous
        MENU LABEL Previous Menu
        TEXT HELP
        Return to previous menu
        ENDTEXT
        MENU EXIT
        MENU SEPARATOR
        MENU INCLUDE coreos/coreos.menu
MENU END
MENU BEGIN Ubuntu
MENU TITLE Ubuntu 
        LABEL Previous
        MENU LABEL Previous Menu
        TEXT HELP
        Return to previous menu
        ENDTEXT
        MENU EXIT
        MENU SEPARATOR
        MENU INCLUDE Ubuntu/Ubuntu.menu
MENU END
MENU TITLE Tools and Utilities
        LABEL Previous
        MENU LABEL Previous Menu
        TEXT HELP
        Return to previous menu
        ENDTEXT
        MENU EXIT
        MENU SEPARATOR
        MENU INCLUDE utilities/utilities.menu
MENU END
EOF
  fi
  if [ ! -f /tftpboot/pxelinux.0 ]; then
    echo "PXE boot image doesn't exist, creating"
    sudo cp /usr/lib/syslinux/pxelinux.0 /tftpboot/
    sudo cp /usr/lib/syslinux/vesamenu.c32 /tftpboot/
    sudo wget https://raw.githubusercontent.com/jasonswat/coreos_pxe/master/logo.png -O /tftpboot/pxelinux.cfg/logo.png 
  fi
  sudo chmod -R 777 /tftpboot
}
# Ubuntu menu setup
function ubuntu_setup {
  if [ ! -f /tftpboot/ubuntu/ubuntu.menu ]; then
    sudo tee /tftpboot/ubuntu/ubuntu.menu <<EOF
LABEL 2
        MENU LABEL Ubuntu xenial (64-bit)
        KERNEL ubuntu/xenial/amd64/vmlinuz
        APPEND boot=xenial initrd=ubuntu/xenial/amd64/initrd.gz
EOF
    if [ ! -f /tftpboot/ubuntu/xenial/amd64/initrd.gz ] || [ ! -f /tftpboot/ubuntu/xenial/amd64/vmlinuz ]; then
      echo "Downloading Ubuntu boot images"
      sudo mkdir -p /tftpboot/ubuntu/xenial/amd64
      cd /tftpboot/ubuntu/xenial/amd64
      wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/cdrom/initrd.gz -O initrd.gz
      wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/cdrom/vmlinuz -O vmlinuz
    fi 
  fi
}
# CoreOS menu setup
function coreos_setup {
  if [ ! -f /tftpboot/coreos/coreos_production_pxe.vmlinuz ] || [ ! -f /tftpboot/coreos/coreos_production_pxe_image.cpio.gz ]; then
  echo "Downloading CoreOS boot files"
    cd /tftpboot/coreos
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
  echo "Creating CoreOS menufile"
  sudo tee /tftpboot/coreos/coreos.menu <<EOF
LABEL 1
        MENU LABEL CoreOS (64-bit)
        KERNEL coreos/coreos_production_pxe.vmlinuz
        INITRD coreos/coreos_production_pxe_image.cpio.gz
        APPEND coreos.autologin=tty1 cloud-config-url=http://192.168.10.184/MyWeb/software/bootstrap.sh
EOF
  fi
}
# Dban menu setup 
function dban_setup {
  if [ ! -f /tftpboot/DBAN/2.0.0/i386/dban.bzi ]; then
    echo "DBAN doesn't exist downloading DBAN iso"
    sudo mkdir -p /tftpboot/utilities/DBAN/2.0/i386
    wget http://sourceforge.net/projects/dban/files/dban/dban-2.3.0/dban-2.3.0_i586.iso/download -O ~/dban-2.3.0_i586.iso
    echo "Mounting DBAN iso"
    sudo mount -o loop -t iso9660 ~/dban-2.3.0_i586.iso /mnt/loop
    sudo cp /mnt/loop/isolinux/dban.bzi /tftpboot/DBAN/2.0.0/i386
    sudo umount /mnt/loop
    sudo touch /tftpboot/utilities/utilities.menu
    sudo tee /tftpboot/utilities/utilities.menu <<EOF
LABEL 18
        MENU LABEL DBAN Boot and Nuke
        KERNEL utilities/dban/dban.bzi
        APPEND nuke="dwipe" silent floppy=0,16,cmos
        TEXT HELP
        Warning - This will erase your hard drive
        ENDTEXT
EOF
  echo "DBAN setup complete"
  fi
  rm ~/dban-2.3.0_i586.iso
}
# Main
ubuntu_setup
coreos_setup
dban_setup
default_setup

sudo service tftpd-hpa restart
