#!/usr/bin/env bash

# Boot ArchLinux image (DVD, USB Flash Drive, etc.) on the target system
#   1. Get the IP address of the target and set the variable below:

ip_addr=10.0.3.${1}

#   2. Change the root password. Later, you will be prompted for it twice:
#       passwd

#   3. Install and start SSH:
#       pacman -Sy openssh
#       systemctl start sshd

#   4. Switch to another workstation with the install scripts and type:
ssh_options='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
scp -r $ssh_options bin root@${ip_addr}:/tmp/
time ssh $ssh_options root@${ip_addr} /bin/bash < install.sh
