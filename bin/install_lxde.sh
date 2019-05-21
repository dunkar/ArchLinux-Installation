#!/usr/bin/env bash
if [ "$(id -u)" != "0" ]; then
    echo "Please execute this as root or with sudo."
    exit 1
fi

sudo pacman -S --noconfirm xorg xorg-xinit xdg-utils mesa gvfs alsa-utils xf86-input-libinput xf86-video-vesa lxde-common lxsession
echo 'exec startlxde' >> /etc/skel/.xinitrc

amixer sset Master unmute

if [[ $(lspci | grep VirtualBox) ]]; then
    install_packages "dkms linux-headers"
    echo "TODO: Install Virtualbox Guest Additions"
fi

echo "TODO: Copy /etc/skel/.xinitrc to the users' directory"
