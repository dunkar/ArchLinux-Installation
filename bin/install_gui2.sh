#!/usr/bin/env bash
if [ "$(id -u)" != "0" ]; then
    echo "Please execute this as root or with sudo."
    exit 1
fi

desktop_environment="xfce4"   #Options: xfce4, lxde, openbox, None
display_manager="slim"     #Options: lightdm, slim, None
log_file="$(date +%Y%m%d_%H%M)_pacman.log"

function install_packages(){
    packages="${1}"
    echo "${packages}" >> ${log_file}
    pacman -S --noconfirm "${packages}"
}

function install_xorg(){
    echo "Installing xorg...." >> ${log_file}

    install_packages "xorg xorg-xinit xdg-utils mesa gvfs alsa-utils xf86-input-libinput xf86-video-vesa"
    amixer sset Master unmute
 
    if [[ $(lspci | grep VirtualBox) ]]; then
        install_packages "virtualbox-guest-utils dkms linux-headers"
        systemctl enable vboxservice && \
        systemctl start vboxservice
    fi

}

function install_network_tools(){
    echo "Installing network tools...." >> ${log_file}
    network_tools="network-manager"

    pci_wifi_count=$(lspci | egrep -ic 'wifi|wlan|wireless')
    usb_wifi_count=$(lsusb | egrep -ic 'wifi|wlan|wireless')
    wifi_count=$(( $pci_wifi_count + $usb_wifi_count ))
    if [ ${wifi_count} -gt 0 ]; then
        network_tools="$network_tools dialog iw rfkill wpa_supplicant"
    fi
    install_packages ${network_tools}
}

function install_desktop_environment(){
    echo "Installing Desktop Environment...." >> ${log_file}
    executable=${1}
    de_packages=${2}
    install_packages ${de_packages}
    echo "exec ${executable}" >> /etc/skel/.xinitrc
}

function install_display_manager(){
    echo "Installing Display Manager...." >> ${log_file}
    service_name=${1}
    dm_packages=${2}
    install_packages ${dm_packages}
    systemctl enable ${service_name}
}


# Define packages
# packages="xorg-server xdg-utils mesa gvfs alsa-utils xscreensaver"
# Removed packages: xorg-utils
# $VBOX && \
#     packages="${packages} virtualbox-guest-utils dkms linux-headers" || \
#     packages="${packages} xf86-input-libinput xf86-video-vesa"
# $WIFI && packages="$packages wicd"

# Setup Display Manager ####################
# if [ "${display_manager}" == "slim" ]; then
#     packages="${packages} slim"
#     dm_service="slim.service"
# elif [ "${display_manager}" == "lightdm" ]; then
#     packages="${packages} lightdm lightdm-gtk-greeter"
#     dm_service="lightdm.service"
# elif [ "${display_manager}" == "None" ]; then
#     dm_service=false
# fi

# # Setup Desktop Environment ################
# if [ "${desktop_environment}" == "xfce4" ]; then
#     packages="${packages} xfce4 xfce4-goodies"
#     init_exec="startxfce4"
#     install_desktop_environment "startxfce4" "xfce4 xfce4-goodies"
# elif [ "${desktop_environment}" == "lxde" ]; then
#     packages="${packages} lxde" #lxde-common lxsession openbox are the minimum set, but they aren't working.
#     init_exec="startlxde"
# elif [ "${desktop_environment}" == "openbox" ]; then
#     packages="${packages} openbox"
#     init_exec="openbox-session"
# elif [ "${desktop_environment}" == "None" ]; then
#     init_exec=false
# fi
# pacman -S --noconfirm $packages

# Configure packages
# $VBOX && \
#     systemctl enable vboxservice && \
#     systemctl start vboxservice

# ${init_exec} && \
#     echo "exec ${init_exec}" >> /etc/skel/.xinitrc && \
#     cp /etc/skel/.xinitrc /home/user/

# ${dm_service} && systemctl enable ${dm_service}
# amixer sset Master unmute



function add_executable(){
    echo "exec ${1}" >> /etc/skel/.xinitrc
    echo "exec ${1}" >> ~/.xinitrc
}

function install_xfce4(){
    install_desktop_environment "startxfce4" "xfce4 xfce4-goodies"
}

function install_lxde(){
    install_desktop_environment "startlxde" "lxde"
}

function install_openbox(){
    install_desktop_environment "openbox-session" "openbox"
}

install_xorg
install_desktop_environment "startlxde" "lxde"
# install_display_manager "lightdm.service" "lightdm"
