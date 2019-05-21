#!/usr/bin/env bash
__version__=2.00.00
__date__=2019-05-14

###############################################################################
# Functions ###################################################################

function detect_system_parameters(){
    # Check boot mode and sync clock ##########################################
    [ -d /sys/firmware/efi/efivars ] && EFI=true || EFI=false
    timedatectl set-ntp true

    # Check for WIFI adapter ##################################################
    pci_wifi_count=$(lspci | egrep -ic 'wifi|wlan|wireless')
    usb_wifi_count=$(lsusb | egrep -ic 'wifi|wlan|wireless')
    wifi_count=$(( $pci_wifi_count + $usb_wifi_count ))
    [ ${wifi_count} -gt 0 ] && WIFI=true || WIFI=false

    # Debugging Information ###################################################
    echo "EFI is ${EFI}"
    echo "WIFI is ${WIFI}"
}

function setup_partitions(){
    # Given the following variables:
    #   EFI
    #   target_disk_device
    #   linux_file_system
    # Create a partition table
    # Create one or more partitions
    # Format the partitions
    # Mount the partitions
    if $EFI; then           # EFI & GPT - 200MB EFI, remaining for linux
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
    elif $GPT; then         # BIOS & GPT - 1MB legacy boot, remaining for linux
        parted -s /dev/${target_disk_device} \
        mktable gpt \
        mkpart p 2048s 2MiB \
        mkpart p ${linux_filesystem} 2MiB 100% \
        set 1 bios_grub on \
        set 2 legacy_boot on

        mkfs.${linux_filesystem} /dev/${target_disk_device}2
        mount /dev/${target_disk_device}2 /mnt
    else                    # BIOS & MBR - 100% for linux
        parted -s /dev/${target_disk_device} \
        mktable msdos \
        mkpart p ${linux_filesystem} 2048s 100% \
        set 1 boot on

        mkfs.${linux_filesystem} /dev/${target_disk_device}1
        mount /dev/${target_disk_device}1 /mnt
    fi

    # Debugging Information ###################################################
    fdisk -l
}

function setup_swap_file(){
    # Configure and activate swap for the current installation process
    # This does not configure swap for the final target system
    fallocate -l ${swap_size} /mnt/swapfile
    chmod 0600 /mnt/swapfile
    mkswap /mnt/swapfile
    sysctl -w vm.swappiness=1
    swapon /mnt/swapfile
}

function setup_package_manager(){
    # Configure the Pacman package manager.
    # This configuration is added to the target system.
    mirror_url="https://www.archlinux.org/mirrorlist/?${mirror_preferences}"
    wget -O /etc/pacman.d/mirrorlist ${mirror_url}
    sed -i 's/^#Server/Server/g' /etc/pacman.d/mirrorlist
    pacman -Sy
}

function install_base_packages(){
    packages="base amd-ucode git grub intel-ucode openssh sudo ufw wget ${additional_packages}"
    $EFI && packages="$packages efibootmgr"
    $WIFI && packages="$packages iw wpa_supplicant dialog rfkill"
    pacstrap /mnt $packages   #add --no-check-certificate parameter as needed.
}

function pre_chroot_configuration(){
    # Configure text files on the target system that do not require scoped execution.
    genfstab -Up /mnt >> /mnt/etc/fstab
    sed -i 's|/mnt/swapfile|/swapfile|' /mnt/etc/fstab
    mkdir -p /mnt/etc/sysctl.d
    echo 'vm.swappiness = 1' >> /mnt/etc/sysctl.d/99-sysctl.conf

    echo $target_hostname > /mnt/etc/hostname
    sed -i 's/#\(en_US.UTF-8\)/\1/' /mnt/etc/locale.gen
    echo LANG="en_US.UTF-8" > /mnt/etc/locale.conf
    ln -fs /mnt/usr/share/zoneinfo/${timezone} /mnt/etc/localtime

    echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/01_wheel_group

    if [ -d /tmp/bin ]; then
        cp -r /tmp/bin /mnt/root/
        cp /tmp/bin/env.sh /mnt/etc/skel/.env.sh
        printf '\n[ -f ~/.env.sh ] && . ~/.env.sh\n\n' >> /mnt/etc/skel/.bashrc
    fi
}

function cleanup(){
    sed -i "s/\(default_password=\)${default_password}/\1REMOVED/" /mnt/root/bin/setup.conf

    if [ $post_install_action == 'Shutdown' ]; then
        shutdown -h now
    elif [ $post_install_action == 'Reboot' ]; then
        shutdown -r now
    else
        echo "Live instance is still running"
    fi
}

###############################################################################
# Main Execution ##############################################################

source /tmp/bin/setup.conf
detect_system_parameters
setup_partitions
setup_swap_file
setup_package_manager
install_base_packages
pre_chroot_configuration


arch-chroot /mnt /bin/bash << EOF
# Localization ################################################################
locale-gen
hwclock --systohc --utc

# Autostart daemons ###########################################################
systemctl enable dhcpcd

# Install and configure grub ##################################################
if $EFI; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=boot
    mv /boot/EFI/boot/grubx64.efi /boot/EFI/boot/bootx64.efi
else
    grub-install --target=i386-pc /dev/${target_disk_device}
fi
sed -i "s/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=${grub_timeout}/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Add the default user ########################################################
useradd -m -s /bin/bash -G wheel,storage,power,adm,disk ${default_username} && \
  echo ${default_username}:${default_password} | chpasswd && \
  usermod -p '!' root

systemctl enable sshd
EOF

cleanup

# Version History ##############################################################
# 2019-05-14 2.00.00 Refactored non-chroot content into functions.
