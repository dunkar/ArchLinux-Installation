#!/usr/bin/env bash

# Preferences ##################################################################
target_hostname=ArchLinux-$RANDOM
target_disk_device=sda
linux_filesystem=ext4
timezone=US/Central
default_username=user
default_password=user
install_gui=true
install_productivity_apps=true

echo "Starting stage 1: Partitioning and Base Packages"

# Check for EFI ################################################################
[ -d /sys/firmware/efi ] && EFI=true || EFI=false

# Check for WIFI adapter #######################################################
pci_wifi_count=$(lspci | egrep -ic 'wifi|wlan|wireless')
usb_wifi_count=$(lsusb | egrep -ic 'wifi|wlan|wireless')
wifi_count=$(( $pci_wifi_count + $usb_wifi_count ))
[ ${wifi_count} -gt 0 ] && WIFI=true || WIFI=false

# Partitioning hard drive ######################################################

if $EFI; then
    parted -s /dev/${target_disk_device} \
    mktable gpt \
    mkpart p fat32 2048s 201MiB \
    mkpart p ${linux_filesystem} 201MiB 100%

    mkfs.vfat /dev/${target_disk_device}1
    mkfs.${linux_filesystem} /dev/${target_disk_device}2

    mount /dev/${target_disk_device}2 /mnt
    mkdir /mnt/boot
    mount /dev/${target_disk_device}1 /mnt/boot
# elif $GPT; then
#     target_disk_size=$(cat /proc/partitions | grep "${target_disk_device}" | awk '{print $3}') # KB
#     linux_size=$(( target_disk_size - 1024 ))
#     ef02_size=1024

else
    parted -s /dev/${target_disk_device} \
    mktable msdos \
    mkpart p ${linux_filesystem} 2048s 100%

    mkfs.${linux_filesystem} /dev/${target_disk_device}1
    mount /dev/${target_disk_device}1 /mnt
fi

# Setup swap file ##############################################################
dd if=/dev/zero of=/mnt/swapfile bs=1M count=1024
#fallocate -l 1024M /mnt/swapfile # This would be much faster, but did not work.
chmod 0600 /mnt/swapfile
mkswap /mnt/swapfile
sysctl -w vm.swappiness=1
swapon /mnt/swapfile

# Configure Pacman #############################################################
mirror_preferences="country=US&protocol=https&ip_version=4&use_mirror_status=on"
mirror_url="https://www.archlinux.org/mirrorlist/?${mirror_preferences}"
wget -O /etc/pacman.d/mirrorlist ${mirror_url}
sed -i 's/^#Server/Server/g' /etc/pacman.d/mirrorlist

# Install base packages ########################################################
packages='base grub sudo'
$EFI && packages="$packages efibootmgr"
$WIFI && packages="$packages iw wpa_supplicant dialog"
pacstrap /mnt $packages
pacstrap --no-check-certificate /mnt $packages
genfstab -Up /mnt >> /mnt/etc/fstab

# Configure swap ###############################################################
sed -i 's|/mnt/swapfile|/swapfile|' /mnt/etc/fstab
mkdir -p /mnt/etc/sysctl.d
echo 'vm.swappiness = 1' >> /mnt/etc/sysctl.d/99-sysctl.conf

# Change-root and configuration ################################################
if [ -d /tmp/bin ]; then
    cp -r /tmp/bin /mnt/root/
fi
arch-chroot /mnt /bin/bash << EOF
echo "Starting stage 2: Configuration"
echo $target_hostname > /etc/hostname

# Localization #################################################################
sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen
echo LANG="en_US.UTF-8" > /etc/locale.conf
locale-gen
ln -fs /usr/share/zoneinfo/${timezone} /etc/localtime

# Autostart daemons ############################################################
systemctl enable dhcpcd

# Install and configure grub ###################################################
if $EFI; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=boot
    mv /boot/EFI/boot/grubx64.efi /boot/EFI/boot/bootx64.efi
else
    grub-install --target=i386-pc /dev/${target_disk_device}
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Setup users ##################################################################
# Configure default user
mkdir /etc/skel/bin

cat >> /etc/skel/bin/env.sh << EEOF
alias ll='ls -l'
alias lla='ls -la'
EEOF

cat >> /etc/skel/.bashrc << EEOF

if [ -f ~/bin/env.sh ]; then
  . ~/bin/env.sh
fi

EEOF

echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/01_wheel_group
useradd -m -s /bin/bash -G wheel,storage,power,adm,disk ${default_username} && \
  echo ${default_username}:${default_password} | chpasswd && \
  usermod -p '!' root

${install_gui} && bash < /root/bin/install_gui.sh
${install_productivity_apps} && bash < /root/bin/install_productivity_apps.sh

EOF

shutdown -h now
