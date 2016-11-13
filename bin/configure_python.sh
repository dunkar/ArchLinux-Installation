#!/usr/bin/env bash

pacman -S --noconfirm python-pip && pip install virtualenvwrapper

cat << EOF >> /usr/bin/env.sh
# Python and VirtualEnv Settings:
VIRTUALENVWRAPPER_PYTHON=\$(which python)
WORKON_HOME=\${HOME}/VEs && \
[ -d \$WORKON_HOME ] || \
mkdir -p \$WORKON_HOME
PROJECT_HOME=\${HOME}/Projects && \
[ -d \$PROJECT_HOME ] || \
mkdir -p \$PROJECT_HOME
script_loc=\$(which virtualenvwrapper.sh) && \
[ -f \${script_loc} ] && \
source \${script_loc}
EOF
