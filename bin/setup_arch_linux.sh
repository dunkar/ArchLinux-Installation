#!/usr/bin/env bash
__version__=1.00.06
__date__=2017-07-08

# Preferences ##################################################################
target_hostname=ArchLinux-$RANDOM
target_disk_device=sda
GPT=true
linux_filesystem=ext4
grub_timeout=0
timezone=US/Central
default_username=user
default_password=user
install_gui=false                   # Run bin/install_gui.sh
post_install_action=Shutdown        # Shutdown, Reboot, None

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
    # EFI & GPT
    parted -s /dev/${target_disk_device} \
    mktable gpt \
    mkpart p fat32 2048s 201MiB \
    mkpart p ${linux_filesystem} 201MiB 100% \
    set 1 boot on

    mkfs.vfat /dev/${target_disk_device}1
    mkfs.${linux_filesystem} /dev/${target_disk_device}2

    mount /dev/${target_disk_device}2 /mnt
    mkdir /mnt/boot
    mount /dev/${target_disk_device}1 /mnt/boot
elif $GPT; then
    # BIOS & GPT
    parted -s /dev/${target_disk_device} \
    mktable gpt \
    mkpart p 2048s 2MiB \
    mkpart p ${linux_filesystem} 2MiB 100% \
    set 1 bios_grub on \
    set 2 legacy_boot on

    mkfs.${linux_filesystem} /dev/${target_disk_device}2
    mount /dev/${target_disk_device}2 /mnt
else
    # BIOS & MBR
    parted -s /dev/${target_disk_device} \
    mktable msdos \
    mkpart p ${linux_filesystem} 2048s 100% \
    set 1 boot on

    mkfs.${linux_filesystem} /dev/${target_disk_device}1
    mount /dev/${target_disk_device}1 /mnt
fi

# Setup swap file ##############################################################
fallocate -l 2048M /mnt/swapfile
chmod 0600 /mnt/swapfile
mkswap /mnt/swapfile
sysctl -w vm.swappiness=1
swapon /mnt/swapfile

# Configure Pacman #############################################################
mirror_preferences="country=US"
mirror_url="https://www.archlinux.org/mirrorlist/?${mirror_preferences}"
wget -O /etc/pacman.d/mirrorlist ${mirror_url}
sed -i 's/^#Server/Server/g' /etc/pacman.d/mirrorlist

# Install base packages ########################################################
packages='base grub sudo'
$EFI && packages="$packages efibootmgr"
$WIFI && packages="$packages iw wpa_supplicant dialog rfkill"
pacstrap /mnt $packages   #add --no-check-certificate parameter as needed.
genfstab -Up /mnt >> /mnt/etc/fstab

# Configure swap ###############################################################
sed -i 's|/mnt/swapfile|/swapfile|' /mnt/etc/fstab
mkdir -p /mnt/etc/sysctl.d
echo 'vm.swappiness = 1' >> /mnt/etc/sysctl.d/99-sysctl.conf

# Change-root and configuration ################################################
[ -d /tmp/bin ] && cp -r /tmp/bin /mnt/root/

arch-chroot /mnt /bin/bash << EOF
echo "Starting stage 2: Configuration"
echo $target_hostname > /etc/hostname

# Localization #################################################################
sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen
echo LANG="en_US.UTF-8" > /etc/locale.conf
locale-gen
ln -fs /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc --utc

# Autostart daemons ############################################################
systemctl enable dhcpcd

# Install and configure grub ###################################################
if $EFI; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=boot
    mv /boot/EFI/boot/grubx64.efi /boot/EFI/boot/bootx64.efi
else
    grub-install --target=i386-pc /dev/${target_disk_device}
fi
sed -i "s/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=${grub_timeout}/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Setup default user profile ###################################################
mkdir /etc/skel/bin
cp /root/bin/configure_user_*.sh /etc/skel/bin/
cp /root/bin/env.sh /etc/skel/bin/
chmod u+x /etc/skel/bin/*

cat >> /etc/skel/.bashrc << EEOF

[ -f ~/bin/env.sh ] && . ~/bin/env.sh

EEOF

echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/01_wheel_group
useradd -m -s /bin/bash -G wheel,storage,power,adm,disk ${default_username} && \
  echo ${default_username}:${default_password} | chpasswd && \
  usermod -p '!' root

${install_gui} && bash < /root/bin/install_gui.sh

EOF

if [ $post_install_action == 'Shutdown' ]; then
    shutdown -h now
elif [ $post_install_action == 'Reboot' ]; then
    shutdown -r now
else
    echo "Live instance is still running"
fi

# Version History ##############################################################
# 2017-03-11 1.00.00 Added version number and date variables.
# 2017-03-22 1.00.01 Added aliases, cleaned up comments, added prompt formatting.
# 2017-06-05 1.00.02 Updated post_install_action.
# 2017-06-11 1.00.03 Moved env.sh code to external file.
# 2017-07-01 1.00.04 Minor tweaks to Grub, Python and GUI installation.
# 2017-07-07 1.00.05 Added WARNING to readme file, changed default swap size.
# 2017-07-08 1.00.06 Cleared Grub default timeout, added option of no DE or DM to gui.
# 2018-03-17 1.00.07 Removed the productivity apps script references