# dotfiles

The idea of this repo is to auto setup a new distro with all the little things I wat to be on my linux machine

# Installing

In order to install the `install.sh` script has to be called as follow:

```bash 
chmod +x ./install.sh
./install.sh
```

#### *Deprecated behavior*
~~*If not called like this the source of the `~/.bashrc` file will not be called propperly and the changes will only be visible after restarting the terminal, or running `source` command manually*~~

After running the `install.sh` script, either restart the terminal or run the command below for the changes in the terminal to take effect

```bash
source ~/.bashrc
```

# List of apps installed 

- git
- net-tools
- fzf
- fuck
- JQ
- python3
- nvm
- node
- nvim

# List of files directly synced to this repo

- nvim config ($HOME/.config/nvim -> $DOTFILES_PATH/nvim)
- .bashaliasrc
- .bashrc
- .bashexportsrc

# How to setup

- Clone the repo
- Create `.env` file and input the data there 
  - Can be based on `.env-default` file
- Run `install.sh`
- Either:
  - Restart current terminal window
  - Run `source ~/.bashrc`

# TODO

## installs to add:

 - [ ] k9s
