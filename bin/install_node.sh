#!/usr/bin/env bash

# sudo pacman -S --noconfirm nodejs npm
# sudo ln -s /usr/bin/nodejs /usr/bin/node

# Determine which file to install and where
pattern=linux-x64.tar.gz
install_location=${HOME}/.local/share

# Determine the latest version number, file name, and installation folder name.
remote_file_location=https://nodejs.org/dist/latest/
remote_file_name=$(wget -q -O- ${remote_file_location} | grep $pattern | cut -f2 -d\")
local_file_location=/tmp/${remote_file_name}
local_install_folder=$(echo "${remote_file_name}" | sed 's/\(node.*\).tar.gz/\1/')

# Get and install the package.
wget -O ${local_file_location} "${remote_file_location}/${remote_file_name}" && \
mkdir -p ${install_location} && \
tar -xzf ${local_file_location} -C ${install_location}

# Add links
if [ "$?" == "0" ]; then
    ln -fs ${install_location}/${local_install_folder}/bin/node ~/bin/node
    ln -fs ${install_location}/${local_install_folder}/bin/npm ~/bin/npm
    rm ${local_file_location}
fi
