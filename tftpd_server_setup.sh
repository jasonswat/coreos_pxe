#!/bin/bash
sudo apt-get install tftpd-hpa inetutils-inetd syslinux

if [ ! -d /tftpboot/pxelinux.cfg/ ]; then
  sudo mkdir -p /tftpboot/pxelinux.cfg/
fi
function tftpd_config {
  sudo tee /etc/default/tftpd-hpa <<EOF
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF
}
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
  ubuntu_dir="/tftpboot/ubuntu"
  ubuntu_latest_dir="${ubuntu_dir}/xenial/amd64"
  if [ ! -f ${ubuntu_dir}/ubuntu.menu ]; then
    sudo tee ${ubuntu_dir}/ubuntu.menu <<EOF
LABEL 2
        MENU LABEL Ubuntu xenial (64-bit)
        KERNEL ubuntu/xenial/amd64/vmlinuz
        APPEND boot=xenial initrd=ubuntu/xenial/amd64/initrd.gz
EOF
    if [ ! -f ${ubuntu_latest_dir}/initrd.gz ] || [ ! -f ${ubuntu_latest_dir}/vmlinuz ]; then
      echo "Downloading Ubuntu boot images"
      sudo mkdir -p ${ubuntu_latest_dir}
      cd ${ubuntu_latest_dir}
      wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/cdrom/initrd.gz -O initrd.gz
      wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/cdrom/vmlinuz -O vmlinuz
    fi 
  fi
}
# CoreOS menu setup
function coreos_setup {
  coreos_dir="/tftpboot/coreos"
  if [ ! -f ${coreos_dir}/coreos_production_pxe.vmlinuz ] || [ ! -f /tftpboot/coreos/coreos_production_pxe_image.cpio.gz ]; then
  echo "Downloading CoreOS boot files"
    sudo mkdir ${coreos_dir}
    cd ${coreos_dir}
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
  echo "Creating CoreOS menufile"
  sudo tee ${coreos_dir}/coreos.menu <<EOF
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
  utilities_dir="/tftpboot/utilities"
  dban_dir="${utilities_dir}/DBAN/2.0/i386/"
  if [ ! -f ${dban_dir}/dban.bzi ]; then
    echo "DBAN doesn't exist downloading DBAN iso"
    sudo mkdir -p ${dban_dir} /mnt/loop
    wget http://sourceforge.net/projects/dban/files/dban/dban-2.3.0/dban-2.3.0_i586.iso/download -O ~/dban-2.3.0_i586.iso
    echo "Mounting DBAN iso"
    sudo mount -o loop -t iso9660 ~/dban-2.3.0_i586.iso /mnt/loop
    sudo cp /mnt/loop/dban.bzi ${dban_dir}
    sudo umount /mnt/loop
    sudo touch ${utilties_dir}/utilities.menu
    sudo tee ${utilties_dir}/utilities.menu <<EOF
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
tftpd_config
ubuntu_setup
coreos_setup
dban_setup
default_setup

sudo service tftpd-hpa restart
