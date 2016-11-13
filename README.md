# Introduction
This project started off as a curiosity to learn more about Arch Linux. Over
time, as I figured out my preferences for how to install Arch, I started to
document the actions in a basic note file. I decided to convert my notes into a
script that I could run remotely once a basic live environment was running.

#### Assumptions, personal choices, and oddities:
 - Resulting target system is NOT secure. This script gets a basic installation
   that should be hardened at your earliest convenience.
   - root account is disabled
   - user account has sudo access
   - user account password is `user`
 - EFI systems use GPT partitions.
   - Some EFI implementations, including VirtualBox (as of this writing) cannot
     use the default grubx64.efi file so it is renamed to bootx64.efi.
 - BIOS systems use MBR partitions.
 - SWAP is managed in a file rather than a dedicated partition:
   - Since kernel version 2.6.X, performance difference is not significant.
     If you have a process that can detect the difference, this script
     is not for you!
   - On SSDs, writes are spread across the entire partition rather than
     focused in a dedicated partition space.
   - On HDDs, the physical head movement is reduced.


# Instructions
1. Add any desired scripts for the target system in the `bin` folder.
  - Scripts will be copied to the `/root/bin` directory on the target system.
  - Scripts will NOT be executed during installation.
- Boot target system with an Arch Linux dual iso (available [here](http://mirror.rackspace.com/archlinux/iso/latest/)).
- Identify the IP Address of the target system.
```shell
ip addr
```
- Set the `ip_addr` variable in the `start.sh` script.
- Set the password for the root account in the TEMPORARY live instance:
```shell
passwd root
```
- Install and start openssh:
```shell
pacman -Sy --noconfirm openssh && systemctl start sshd
```
- From a networked computer with a bash shell, execute the `start.sh` script.
- Upon completion of the `start.sh`, the target system will shutdown. Remove
  the installation media and start the target system.
- Login using the root account with the password `root`.
- Run any other desired scripts from the `/root/bin` folder.
- Update the passwords for the `root` and `user` accounts.
- Perform any other hardening and configuration steps you desire.
