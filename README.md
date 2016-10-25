# Introduction
This project started off as a curiosity to learn more about Arch Linux. Over
time, as I figured out my preferences for how to install Arch, I started to
document the actions in a basic note file. I decided to convert my notes into a
script that I could run remotely once a basic live environment was running.

#### Assumptions, personal choices, and oddities:
 - Resulting target system is NOT secure. This script gets a basic installation
   that should be hardened at your earliest convenience.
 - EFI systems use GPT partitions.
 - BIOS systems use MBR partitions.
 - SWAP is managed in a file rather than a dedicated partition:
   - Since kernel version 2.6.X, performance difference is not significant.
     If you have a process that can detect the difference, this script
     is not for you!
   - On SSDs, writes are spread across the entire partition rather than focused in
     a dedicated partition space.
   - On HDDs, the physical head movement is reduced.
 - Some EFI implementations, including VirtualBox (as of this writing) cannot
   use the default grubx64.efi file so it is renamed to bootx64.efi.


# Instructions
1. Add any desired scripts for the target system in the `bin` folder. They will be copied to the target system during installation.
- Boot target system with an Arch Linux dual iso.
- Identify the IP Address of the target system.
```shell
  ip addr
```
- Set the value in the `start.sh` script.
- Set the password for the root account:
  ```shell
  passwd root
  ```
- Install and start openssh:
  ```shell
  pacman -Sy --noconfirm openssh && systemctl start sshd
  ```
- Execute the `start.sh` script.
- Upon completion of the `start.sh`, the target system will shutdown. Remove the
  installation media and start the target system.
- Login using the root account with the password `root`.
- Run any other desired scripts from the `/root/bin` folder.
