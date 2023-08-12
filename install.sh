#!/usr/bin/env bash

function addstuff(){
    echo "
if [ -f \$DOTFILES_PATH/$1 ]; then
    . \$DOTFILES_PATH/$1
fi" >> ~/.bashrc
}

# add this folder path to a var
echo "export DOTFILES_PATH=$PWD" >> ~/.bashrc

# add source of files on bashrc

addstuff .bashaliasrc
addstuff .bashexportsrc
addstuff .bashrc

source ~/.bashrc