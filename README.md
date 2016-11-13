# Introduction
This project started off as a curiosity to learn more about Arch Linux. Over
time, as I figured out my preferences for how to install Arch, I started to
document the actions in a basic note file. I decided to convert my notes into a
script that I could run remotely once a basic live environment was running.

#### Assumptions, personal choices, and oddities:
 - The install script is intended to run remotely because scripted installations
   are often not using a comfortable or ergonomic seating arrangement.
 - Resulting target system is NOT secure. This script gets a basic installation
   that should be hardened at your earliest convenience.
   - root account is disabled
   - default user account has sudo access
   - The default user is `user` with a password of `user`. This is configurable.
 - Linux partitions are formatted as ext2 (non-journaling). This is configurable.
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
 - The `bin` folder contains scripts that are copied to the /root/bin folder
   on the target system. You can add any additional scripts needed before
   installation.


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
  Remember to configure the target system IP Address.
- Upon completion of the `start.sh`, the target system will shutdown. Remove
  the installation media and start the target system.
- Login using the default user account.
- Run any other desired scripts from the `/root/bin` folder with `sudo`.
- Perform any other hardening and configuration steps you desire.
