# bash-provisioner

variables to control

YQ_VERSION="${YQ_VERSION:-4.45.1}"
UPDATE_ALLOW_REBOOT defaults to true, which will automatically reboot after important updates
NEOVIM_VERSION="v${NEOVIM_VERSION:-0.10.2}"


my bash provisioner to provision my machines!
contains:

* system provisioner - to do basic linux distribution provisioning
* dotenv provisioner - to manage dotfiles on your system

heavily based on `https://github.com/ThePrimeagen/dev` but with more options explained below.


## system provisioner

features:

* possible to provise different linux distributions
* more reliable execution order so we can intercept for different environments

basic principles:

* convention over configuration.
* this is provisioning for private computers, no enterprise ready or (multiple) server solution
* this is < 30 min ready provisioning, no bash utils sourcing or other complicated stuff

Quote from The Primagean: "This is just a really dumb script runner"


* run `provision.sh` on any new arch system

* there are more options like:

```bash

Usage: ./provision.sh [-d|--dry-run] [-l|--linux-distro <arch|debian|redhat>] [-f|--filter filterword]

```

* dry-run         - default is no, dry-run == dont run for real, only show what would happen
* linux-distro    - arch is default|debian|redhat, run specific provisioning scripts, distribution depenant
                    script files need to have `_specific_distro_<distro>` in the filename_
* filter          - default is not filter, filter defines the pattern to only execute scripts with


provisioning scripts live in `provisions` and must be valid executable scripts and can contain anything you want to install.

```bash
├── provisions
│   ├── 0020_update_system_packages.sh
│   ├── 0030_base_tools.sh
│   ├── 0031_dev_tools.sh
│   ├── 0050_neovim.sh

```

if you want to make different provision pathes for different distributions, create subdir with name of distribution under `./provisions`

e.g. if you have very different scripts to install vscode on arch, debian or redhat you can do the following

```bash

├── provisions
│   ├── 0050_neovim.sh
│   └── 0099_install_vscode
│       ├── arch
│       ├── debian
│       └── redhat

``` 

and then use the `--linux-distro` parameter, to only execute and install your flavor script


## dotenv provisioning

Manage your dotfiles, also heavily based on ThePrimagean's `dev` repo but with some additions:
 
features:

* better convention over configuration, drop any dotfile target in the `dotenvs` directory to get automatically installed
* has also clean option

`dotenvs` folder structure:

```bash

dotenvs
├── bashrc
│   ├── .basedir
│   └── .bashrc
├── neovim
│   ├── .basedir
│   └── neovim
│       └── config.lua
└── tmux
    ├── .basedir
    └── tmux
        ├── tmux.conf
        └── tmux.conf.basic

```
explanation of `dotenvs` folder structure:

* first level of directories below `dotenvs` contain the dotfile name
* in it you will find a `.basedir` name, this is the path where the dotfile should be installed to as a base
* any other file or subfolder will be installed at that location defined in `.basedir`

Usage: ./dotenv [-d|--dry-run] [-f|--filter filterword] [-c|--clean]

Note: this approach is not using symbolic links, so you need to manage your dotfiles state in this repo folder. Everytime you want to update/distribute your latest state of dotfiles in your actual system, you need to run `dotenv` command


