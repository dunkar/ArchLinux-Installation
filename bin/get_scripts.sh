#!/usr/bin/env bash

if [ -z $(which git) ]; then
    echo "Please install git before running this script."
    exit 1
fi

scripts_source="https://gitlab.com/jfdahl/myscripts.git"
mkdir -p ~/Git
git clone ${scripts_source} ~/Git/scripts
chmod -R +x ~/Git/scripts
