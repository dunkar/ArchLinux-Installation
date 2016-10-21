#!/usr/bin/env bash

echo "Starting stage 1: Partitioning and Base Packages"

# Check for EFI ################################################################
[ -d /sys/firmware/efi ] && EFI=true || EFI=false

# Check for WIFI adapter #######################################################
pci_wifi_count=$(lspci | egrep -ic 'wifi|wlan|wireless')
usb_wifi_count=$(lsusb | egrep -ic 'wifi|wlan|wireless')
wifi_count=$(( $pci_wifi_count + $usb_wifi_count ))
[ ${wifi_count} -gt 0 ] && WIFI=true || WIFI=false

# Partitioning hard drive ######################################################
disk_dev=sda
if $EFI; then
    parted -s /dev/${disk_dev} \
    mktable gpt \
    mkpart p fat32 2048s 201MiB \
    mkpart p ext2 201MiB 100%

    mkfs.vfat /dev/${disk_dev}1
    mkfs.ext2 /dev/${disk_dev}2

    mount /dev/${disk_dev}2 /mnt
    mkdir /mnt/boot
    mount /dev/${disk_dev}1 /mnt/boot
else
    parted -s /dev/${disk_dev} \
    mktable msdos \
    mkpart p ext2 2048s 100%

    mkfs.ext2 /dev/${disk_dev}1

    mount /dev/${disk_dev}1 /mnt
fi

# Setup swap file ##############################################################
dd if=/dev/zero of=/mnt/swapfile bs=1M count=1024
chmod 0600 /mnt/swapfile
mkswap /mnt/swapfile
sysctl -w vm.swappiness=1
swapon /mnt/swapfile

# Configure Pacman #############################################################
mirror_preferences='country=US&protocol=https&ip_version=4&use_mirror_status=on'
mirror_url="https://www.archlinux.org/mirrorlist/?${mirror_preferences}"
wget -O /etc/pacman.d/mirrorlist ${mirror_url}
sed -i 's/^#Server/Server/g' /etc/pacman.d/mirrorlist

# Install base packages ########################################################
packages='base grub'
$EFI && packages="$packages efibootmgr"
$WIFI && packages="$packages iw wpa_supplicant dialog"
pacstrap /mnt $packages
genfstab -Up /mnt >> /mnt/etc/fstab

# Configure swap ###############################################################
sed -i 's|/mnt/swapfile|/swapfile|' /mnt/etc/fstab
mkdir -p /mnt/etc/sysctl.d
echo 'vm.swappiness = 1' >> /mnt/etc/sysctl.d/99-sysctl.conf

# Change-root and configuration ################################################
mv /tmp/bin /mnt/root/
arch-chroot /mnt /bin/bash << EOF
echo "Starting stage 2: Configuration"

# Localization #################################################################
sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen
echo LANG="en_US.UTF-8" > /etc/locale.conf
locale-gen
ln -fs /usr/share/zoneinfo/US/Central /etc/localtime

# Autostart daemons ############################################################
systemctl enable dhcpcd
systemctl enable sshd

# Install and configure grub ###################################################
if $EFI; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=boot
    mv /boot/EFI/boot/grubx64.efi /boot/EFI/boot/bootx64.efi
else
    grub-install --target=i386-pc /dev/${disk_dev}
fi
grub-mkconfig -o /boot/grub/grub.cfg

echo "if [ -f /usr/bin/env.sh ]; then" >> /etc/skel/.bashrc
echo "  . /usr/bin/env.sh" >> /etc/skel/.bashrc
echo "fi" >> /etc/skel/.bashrc

# Setup users ##################################################################
echo root:root | chpasswd
useradd -m -s /bin/bash -G wheel,storage,power,adm,disk user
echo user:user | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/01_wheel_group
EOF

shutdown -h now
