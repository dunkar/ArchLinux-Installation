#!/usr/bin/env bash

if [ -z $(which git) ]; then
    echo "Please install git before running this script."
    exit 1
fi

scripts_source="https://github.com/jfdahl/myscripts.git"
git clone ${scripts_source} ~/scripts
chmod -R +x ~/scripts
