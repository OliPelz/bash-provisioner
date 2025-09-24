# bash-provisioner

variables to control

YQ_VERSION="${YQ_VERSION:-4.45.1}"
UPDATE_ALLOW_REBOOT defaults to true, which will automatically reboot after important updates
NEOVIM_VERSION="v${NEOVIM_VERSION:-0.10.2}"
DISABLE_IPV6
DISABLE_IPV6=true|1    Force IPv4:
USE_PROXY=true         Enable proxy usage (uses HTTPS_PROXY value).
HTTPS_PROXY=<url>      Proxy URL (e.g., http://user:pass@host:port).
CERT_BASE64_STRING     Base64-encoded CA cert for proxy TLS; written to a temp file and 

example

```bash
DISABLE_IPV6=true
USE_PROXY=true
HTTPS_PROXY=http://campus-proxy.rz.bankenit.de:8080
CERT_BASE64_STRING=LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUV4VENDQTYyZ0F3SUJBZ0lMQWZoNE5xRUg4RDZ0bzlBd0RRWUpLb1pJaHZjTkFRRUxCUUF3WGpFTE1Ba0cKQTFVRUJoTUNSRVV4SERBYUJnTlZCQW9NRTBaSlJGVkRTVUVnSmlCSFFVUWdTVlFnUVVjeEVUQVBCZ05WQkFzTQpDRlpTSUVsRVJVNVVNUjR3SEFZRFZRUUREQlZXVWlCSlJFVk9WQ0JTVDA5VUlFTkJJREl3TVRZd0hoY05NVFl4Ck1qRTBNVEF4TnpRMFdoY05Nell4TWpNeE1qSTFPVFU1V2pCZE1Rc3dDUVlEVlFRR0V3SkVSVEVjTUJvR0ExVUUKQ2d3VFJrbEVWVU5KUVNBbUlFZEJSQ0JKVkNCQlJ6RVJNQThHQTFVRUN3d0lWbElnU1VSRlRsUXhIVEFiQmdOVgpCQU1NRkZaU0lFbEVSVTVVSUZOVlFpQkRRU0F5TURFMk1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBCk1JSUJDZ0tDQVFFQXVieERwL0hZcm1PMkFWb3YyTnNNZldSWDQ2am83dUZwcnJVUEkxZ0VMeU04MTFqN0xLL1oKQ1owM3JJUlhTMXNtTnc2NTZ4L1Z3bFR1NVkxTytJdnJ6L2xOWTBzcmlrNk1tMis3WVJoOVRUL0VjV1RsOHJ0YgpMZm5zN21Ld2RQWjZTQjBJSGlCemNSSE90MVFjNDlQbHpRMXJmQmVjTXBma2x3SmdyTisxc1N2YlVHZmp5cVFYCkVjWVFPeXVPOXUyUnNMMi9rS0NXeElpZERZUjQwL3hmV3BVZ3VJWm9ETkxZbG1xT2Vxa3BRY3g2UnpRNHJBNjkKMW0vaWxLYkMzcmhQWUJmdkFEaVdxaEdEbDJWOWFneDNYZlpKWVRKUUV6MmlYSEpRQW85MFdVTmpzeVJoUzBBOQp6L0JWT0NzcUUwMUhvUDIwb1FOWFhNWjlYbHJ4UDc2Z0N3SURBUUFCbzRJQmd6Q0NBWDh3Z1lVR0NDc0dBUVVGCkJ3RUJCSGt3ZHpCMUJnZ3JCZ0VGQlFjd0FZWnBhSFIwY0RvdkwyOWpjM0F1ZG5JdGFXUmxiblF1WkdVdlozUnUKYjJOemNDOVBRMU5RVW1WemNHOXVaR1Z5TDBaSlJGVkRTVUVsTWpBbE1qWWxNakJIUVVRbE1qQkpWQ1V5TUVGSApMMVpTSlRJd1NVUkZUbFFsTWpCU1QwOVVKVEl3UTBFbE1qQXlNREUyTUM0R0ExVWRJd1FuTUNXQUkxQlNUMFF1ClIxUk9MbFpTVWs5UFZFTkJMbE5KUjBkRlRsSlRMakF3TURBek56QXdNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHcKZHdZRFZSMGZCSEF3YmpCc29HcWdhSVptYUhSMGNEb3ZMM2QzZHk1MmNpMXBaR1Z1ZEM1a1pTOW5kRzVqY213dgpRMUpNVW1WemNHOXVaR1Z5TDBaSlJGVkRTVUVsTWpBbE1qWWxNakJIUVVRbE1qQkpWQ1V5TUVGSEwxWlNKVEl3ClNVUkZUbFFsTWpCU1QwOVVKVEl3UTBFbE1qQXlNREUyTUE0R0ExVWREd0VCL3dRRUF3SUJoakFyQmdOVkhRNEUKSkFRaVVGSlBSQzVIVkU0dVZsSlRWVUpEUVM1VFNVZEhSVTVTVXk0d01EQXdNemN3TURBTkJna3Foa2lHOXcwQgpBUXNGQUFPQ0FRRUFVVXZUTkM2SklBUkhjRGdjU0lwTlpvbHZOdW5WaTJ3bkNwSkFTMVZveHVxSS8zRDhTMUpMCjJ3cmMvU1hPbHVPRHJzMklUYnppU2ZYOGpJbG1OZHAzRzcvVUxVRXNYVXgxRlVSZlM4L0x2R2ZaS2hCckN2WDQKWGJLaTRnbldQVUVUa2pWaWp5L0FKY3RNUi92aTVJTHpCbjVZckFHZkpXL0g5cUthMlBQRGphQVNkNmN4Q0NhcApqZm5pTXhzMmdxcGJJWTV1bVlxbFpYUkFRT04xWVlVK3Q1cEZVM054ZUZldmU1anJ6SUJ2R0Y5c0lkVTBKdVd4CjdwU1l1UjBmc3ZReGRZSk1zRGZMYkE1M3FydlFVM0NKRDVPVUtxdHFkdXFjVFFZQXNxdXJ4cDljcmhjcUNiUzcKNytxOTRXUHZNK2ZjT1haUHcxbzFuNFR1bjNMcHZLejRlQT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K

```

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


