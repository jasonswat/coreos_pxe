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

sudo mkdir -p /tftpboot/pxelinux.cfg/
sudo cp /usr/lib/syslinux/pxelinux.0 /tftpboot/
sudo tee /tftpboot/pxelinux.cfg/default <<EOF
default coreos
prompt 1
timeout 15

display boot.msg

LABEL coreos
  menu default
  kernel /coreos_production_pxe.vmlinuz
  initrd /coreos_production_pxe_image.cpio.gz
  append coreos.autologin=tty1 cloud-config-url=http://192.168.10.184/MyWeb/software/bootstrap.sh
EOF
cd /tftpboot
wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
sudo chmod -R 777 /tftpboot
sudo service tftpd-hpa restart
