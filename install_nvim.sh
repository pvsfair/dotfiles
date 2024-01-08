#!/usr/bin/env bash

read -p "Do you want to proceed installing NVIM? (y/N) " yn
case $yn in
  [Yy]* ) echo "Proceeding with the instalation";;
  * ) echo "Exiting";
    exit;;
esac

if ! command -v nvim &> /dev/null; then
  echo 'Installing fuck'
  sudo snap install nvim --classic
fi
echo "nvim version $(nvim --version)"

if [ -z ${DOTFILES_PATH} ]; then
  DOTFILES_PATH=$PWD
fi

echo 'Configuring nvim and creating symlink'
# check if .config/nvim folder exists before creating symlink
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim{,.bkp}
fi

# check if .config/nvim still exists, if not create symlink
if [ ! -a ~/.config/nvim ]; then
  ln -s $DOTFILES_PATH/nvim $HOME/.config/nvim
fi
