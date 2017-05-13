#!/usr/bin/env bash

python_exec=python
main_python_interpreter=$(which ${python_exec})

[[ $(which pip) ]] || \
pacman -S --noconfirm ${python_exec}-pip && \
pip install virtualenvwrapper

cat << EOF >> /usr/bin/env.sh
# Python and VirtualEnv Settings:
VIRTUALENVWRAPPER_PYTHON=\$(which ${python_exec})

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
