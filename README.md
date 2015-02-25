# coreos_pxe

## DHCP server setup

I'm using a dd-wrt router with dhcp to release the ip address. I added these options to the DHCP server:

    boot_file pxelinux.0
    siaddr 192.168.10.37
    option tftp 192.168.10.37 
