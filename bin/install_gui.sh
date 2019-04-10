#!/usr/bin/env bash
if [ "$(id -u)" != "0" ]; then
    echo "Please execute this as root or with sudo."
    exit 1
fi

desktop_environment="xfce4"   #Options: xfce4, lxde, openbox, None
display_manager="slim"     #Options: lightdm, slim, None

[[ $(lspci | grep VirtualBox) ]] && VBOX=true || VBOX=false

pci_wifi_count=$(lspci | egrep -ic 'wifi|wlan|wireless')
usb_wifi_count=$(lsusb | egrep -ic 'wifi|wlan|wireless')
wifi_count=$(( $pci_wifi_count + $usb_wifi_count ))
[ ${wifi_count} -gt 0 ] && WIFI=true || WIFI=false

# Define packages
packages="xorg-server xdg-utils mesa gvfs alsa-utils xscreensaver"
# Removed packages: xorg-utils
$VBOX && \
    packages="${packages} virtualbox-guest-utils dkms linux-headers" || \
    packages="${packages} xf86-input-libinput xf86-video-vesa"
$WIFI && packages="$packages wicd"

# Setup Display Manager ####################
if [ "${display_manager}" == "slim" ]; then
    packages="${packages} slim"
    dm_service="slim.service"
elif [ "${display_manager}" == "lightdm" ]; then
    packages="${packages} lightdm lightdm-gtk-greeter"
    dm_service="lightdm.service"
elif [ "${display_manager}" == "None" ]; then
    dm_service=false
fi

# Setup Desktop Environment ################
if [ "${desktop_environment}" == "xfce4" ]; then
    packages="${packages} xfce4 xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin mousepad"
    init_exec="startxfce4"
elif [ "${desktop_environment}" == "lxde" ]; then
    packages="${packages} lxde" #lxde-common lxsession openbox are the minimum set, but they aren't working.
    init_exec="startlxde"
elif [ "${desktop_environment}" == "openbox" ]; then
    packages="${packages} openbox"
    init_exec="openbox-session"
elif [ "${desktop_environment}" == "None" ]; then
    init_exec=false
fi
pacman -S --noconfirm $packages

# Configure packages
$VBOX && \
    systemctl enable vboxservice && \
    systemctl start vboxservice
${init_exec} && \
    echo "exec ${init_exec}" >> /etc/skel/.xinitrc && \
    cp /etc/skel/.xinitrc /home/user/

${dm_service} && systemctl enable ${dm_service}
amixer sset Master unmute
