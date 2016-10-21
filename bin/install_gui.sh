#!/usr/bin/env bash

[[ $(lspci | grep VirtualBox) ]] && VBOX=true || VBOX=false

# Install packages
packages='xorg-server gvfs alsa-utils xfce4'
$VBOX && \
    packages="$packages virtualbox-guest-utils dkms linux-headers" || \
    packages="$packages xf86-input-all xf86-video-vesa"
pacman -S --noconfirm $packages

# Configure packages
$VBOX && \
    systemctl enable vboxservice && \
    systemctl start vboxservice
echo "exec startxfce4" >> /etc/skel/.xinitrc && \
    cp /etc/skel/.xinitrc /home/user/
