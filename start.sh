#!/usr/bin/env bash

# Boot ArchLinux image (DVD, USB Flash Drive, etc.) on the target system
#   1. Get the IP address of the target and set the variable below or pass it
#       as a parameter.
#   2. Change the root password. Later, you will be prompted for it twice, but
#       this will only be for the live system and will not affect the
#       installation.
#       <<passwd>>
#   3. Start SSH:
#       <<systemctl start sshd>>
#   4. Switch to another workstation with the install scripts and type:
#       <<./start.sh IP.ADDR.OF.TARGET


ip_addr=${1}
ssh_options='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
scp -r $ssh_options bin root@${ip_addr}:/tmp/
time ssh $ssh_options root@${ip_addr} /tmp/bin/setup_arch_linux.sh
