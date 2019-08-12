# ArchInstaller
**Disclaimer: These scripts are for me, but might be useful for you too.**

**⚠ Warning  : This script wipes whole device.**


ArchInstaller is a set of bash script that autoinstalls and autoconfigures fully functional DE/WM, By default ArchInstaller script install i3wm and uses my [dotfiles](https://github.com/sanchit-saini/dotfiles).

## Customization
If you don't want to use default [dotfiles](https://github.com/sanchit-saini/dotfiles), then these functions should be updated accordingly along with `packages.csv` file & `DOTFIlES` in config file
```
post.sh :
    install_and_configure_git_repos()
    configure()
    clean()
```
The script is written in a functional way for easier readability, everything should be self-explanatory.
If in a case you are still facing any problem you know what to do create an issue!
[![](media/issues.png)]()

## How ArchInstaller Source is Structured?
### Pre Script
  - Format device 
  - Create partition
  - Mount partition
  - Enable Swap support
  - Install system base
  - Configure genfstab
  - Configure timezone
  - Configure locale
  - Install grub bootloader
  - Enable hibernation
  - Configure grub
  - Set root passwd
  - Create user
  - Set user passwd
  - Enable sudo privilege for the user
  - Set hostname
  - Copy script into the user home
  - Enable Network Service
  - reboot

### Post Script
  - Refresh keys
  - Install AUR helper
  - Install all packages which are in packages.csv file 
  - Install & configure git repos
  - Configure installed packages
  - Cleaning up

### Packages file
Contain list of packages to be installed, Depending on your use case, packages can be added and removed.
The list is divided into three columns:
- **Package/Url** : name of the package
- **Tag** : A(AUR),P(Official repo) and G(Git repo)
- **Purpose** : Description of package


### Config file
Contain list of variables for configuring installation.

## Prerequisite
- [Arch Linux Installation Media](https://www.archlinux.org/download/)
- Logged in as 'root'
- [Working internet connection](https://wiki.archlinux.org/index.php/Installation_guide#Connect_to_the_internet)

## Installation
1. Get the script :```wget cutt.ly/arch -O - | tar xz``` or ```wget https://github.com/sanchit-saini/ArchInstaller/tarball/master -O - | tar xz```
2. Go to the project folder:```cd <dir>```
3. Edit config and change values with your preferences:```vim config```
4. Install system base: ```./pre.sh```
5. After Successful Installation of system base, The system should reboot automatically
6. Connect to the Internet using ```nmtui```
7. Go to the project folder:```cd <dir>```
8. If you want to install all packages and configuration run: ```./post.sh```

## Reference 
- [Arch Wiki](https://wiki.archlinux.org/)

## Inspiration
- [LARBS](https://github.com/LukeSmithxyz/LARBS)
- [aflit](https://github.com/awalgarg/aflit)