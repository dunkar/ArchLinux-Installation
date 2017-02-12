# Introduction
This project started off as a curiosity to learn more about Arch Linux. Over
time, as I figured out my preferences for how to install Arch, I started to
document the actions in a basic note file. I decided to convert my notes into a
script that I could run once a basic live environment was running. I have since
modified the script to allow execution locally (from a usb stick) or remotly via
an SSH session.

#### Assumptions, personal choices, and oddities:
 - The install script was originally designed to run remotely because scripted
     installations are often not using a comfortable or ergonomic seating
     arrangement. Think server rack, secondary KVM, or virtual machine with the
     default screen size. I have added an option to run it locally by simply
     passing `local` as the ip address in the start.sh script.
 - The resulting target system is NOT secure. This script gets a basic
    installation that should be hardened at your earliest convenience.
    - The default user is `user` with a password of `user`. This is configurable.
    - default user account has sudo access
    - root account is disabled
 - Linux partitions are formatted as ext4. This is configurable.
 - EFI systems use GPT partitions.
   - Some EFI implementations, including VirtualBox (as of this writing) cannot
     use the default grubx64.efi file so the file is renamed to bootx64.efi.
 - BIOS systems use MBR partitions, but this can be overridden by setting the
    GPT variable to `true`.
 - SWAP is managed in a file rather than a dedicated partition:
   - Since kernel version 2.6.X, performance difference is not significant.
     If you have a process that can detect the difference, this script
     is not for you!
   - On SSDs, writes are spread across the entire partition rather than
     focused in a dedicated partition space.
   - On HDDs, the physical head movement is reduced, improving performance.
 - The `bin` folder contains scripts that are copied to the /root/bin folder
   on the target system. You can add any additional scripts needed before
   installation.
   - The script named setup_arch_linux.sh will be executed to perform the
   installation. The script will remain post-installation for reference.
   - Scripts named `configure_user_*.sh` will be copied to the `/etc/skel/bin/`
   folder so each new user will automatically have access.


# Instructions
1. Add any desired scripts for the target system in the `bin` folder.
  - The install_gui and install_productivity_apps scripts will be executed if
    the respective variables are set to true in the setup_arch_linux.sh script.
- Boot target system with an Arch Linux dual iso (available [here](http://mirror.rackspace.com/archlinux/iso/latest/)).
- Identify the IP Address of the target system.
```shell
ip addr
```
- Set the `ip_addr` variable in the `start.sh` script.
  - Note: You can also pass the ip address as a parameter.
- Start openssh:
```shell
systemctl start sshd
```
- Set the password for the root account in the TEMPORARY live instance.
    This password will not survive the post-installation reboot:
```shell
passwd
```
- From a working computer with a bash shell and network access to the target system, execute the `start.sh` script.
  Remember to configure or pass the target system IP Address.
- Upon completion of the `start.sh`, the target system will shutdown. Remove
  the installation media and start the target system.
- Login using the default user account.
- Run any other desired scripts from the `/root/bin` folder with `sudo`.
- Perform any other hardening and configuration steps you desire.
