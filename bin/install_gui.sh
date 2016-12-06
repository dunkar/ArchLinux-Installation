#!/usr/bin/env bash

desktop_environment="xfce4"   #Options: xfce4
display_manager="lightdm"     #Options: lightdm, slim

[[ $(lspci | grep VirtualBox) ]] && VBOX=true || VBOX=false

# Install packages
packages="xorg-server xorg-utils mesa gvfs alsa-utils"
$VBOX && \
    packages="${packages} virtualbox-guest-utils dkms linux-headers" || \
    packages="${packages} xf86-input-all xf86-video-vesa"

if [ "${display_manager}" == "slim" ]; then
    packages="${packages} slim"
    dm_service="slim.service"
fi

if [ "${display_manager}" == "lightdm" ]; then
    packages="${packages} lightdm lightdm-gtk-greeter"
    dm_service="lightdm.service"
fi

if [ "${desktop_environment}" == "xfce4" ]; then
    packages="${packages} xfce4 xfce4-whiskermenu-plugin"
    init_exec="startxfce4"
fi
pacman -S --noconfirm $packages

# Configure packages
$VBOX && \
    systemctl enable vboxservice && \
    systemctl start vboxservice
echo "exec ${init_exec}" >> /etc/skel/.xinitrc && \
    cp /etc/skel/.xinitrc /home/user/

systemctl enable ${dm_service}
amixer sset Master unmute

#xfconf-query --channel thunar --property /misc-full-path-in-title --create --type bool --set true
#xfconf-query --channel thunar --property /default-view --create --type string --set ThunarDetailsView
#xfconf-query --create --channel xfce4-panel --property /plugins/plugin-8/timezone --create --type string --set US/Central
#synclient PalmDetect=1

# reboot
