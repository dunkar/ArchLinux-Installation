#!/usr/bin/env bash
__version__=1.00.01
__date__=2017-03-22

# Preferences ##################################################################
target_hostname=ArchLinux-$RANDOM
target_disk_device=sda
GPT=true
linux_filesystem=ext4
timezone=US/Central
default_username=user
default_password=user
install_gui=false # Execute the bin/install_gui.sh script
install_productivity_apps=false # Execute the bin/install_productivity_apps.sh script
shutdown_post_install=true # Should the target system shutdown after installation?
reboot_post_install=false # Should the target system reboot after installation?

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
    set 1 bios_grub on
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
fallocate -l 1024M /mnt/swapfile
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
#pacstrap --no-check-certificate /mnt $packages
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
# Configure default user profile
mkdir /etc/skel/bin
cp /root/bin/configure_user_*.sh /etc/skel/bin/
cat >> /etc/skel/bin/env.sh << EEOF
export PS1='\n\u@\h\n${PWD}\n>'
alias ll='ls -l'
alias lla='ls -la'
alias install='sudo pacman -S'
alias uninstall='sudo pacman -R'
alias update='sudo pacman -Syu'
alias reboot='sudo shutdown -r now'
alias shutdown='sudo shutdown -h now'
[[ -f /usr/bin/env.sh ]] && source /usr/bin/env.sh
EEOF
chmod u+x /etc/skel/bin/*

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

${shutdown_post_install} && shutdown -h now
${reboot_post_install} && shutdown -r now

# Version History ##############################################################
# 2017-03-11 1.00.00 Added version number and date variables.
# 2017-03-22 1.00.01 Added aliases, cleaned up comments, added prompt formatting.
