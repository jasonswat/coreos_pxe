# coreos_pxe

My notes for automating coreos install on baremetal with pxe boot

### DHCP server setup

I'm using a dd-wrt router with dhcp to release the ip address to the pxe boot process.
I added these options to the DHCP server:

    boot_file pxelinux.0
    siaddr 192.168.10.37
    option tftp 192.168.10.37 

### Tftp Server setup script (new instructions)

```
wget https://raw.githubusercontent.com/jasonswat/coreos_pxe/master/tftpd_server_setup.sh
chmod u+x tftpd_server_setup.sh   
./tftpd_server_setup.sh 
```

### Tftp Server setup (old instructions)
I had an ubuntu vm running on my network that I used for the tftp server

    sudo apt-get install tftpd-hpa inetutils-inetd
    sudo vi /etc/default/tftpd-hpa

it should look like this:


    /etc/default/tftpd-hpa

    TFTP_USERNAME="tftp"
    TFTP_DIRECTORY="/tftpboot"
    TFTP_ADDRESS="0.0.0.0:69"
    TFTP_OPTIONS="--secure"

    sudo mkdir -p /tftpboot/pxelinux.cfg/
    sudo cp /usr/lib/syslinux/pxelinux.0 /tftpboot/

Create the pxelinux.cfg/default menu

    sudo vi /tftpboot/pxelinux.cfg/default

It should look like below, the coreos.autologin=tty1 boots to a root login for
troubleshooting. Your tty maybe different.:

    default coreos
    prompt 1
    timeout 15

    display boot.msg

    LABEL coreos
      menu default
      kernel /coreos_production_pxe.vmlinuz
      initrd /coreos_production_pxe_image.cpio.gz
      append coreos.autologin=tty1 cloud-config-url=http://192.168.10.184/MyWeb/software/bootstrap.sh

Setup the tftpd directory:

    cd /tftpboot
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
    sudo chmod -R 777 /tftpboot
    sudo service tftpd-hpa restart
