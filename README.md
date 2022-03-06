# ArchInstaller
**Disclaimer: These scripts are for me, but might be useful for you too.**

**⚠ Warning  : This script wipes whole device.**


ArchInstaller is a set of bash script that autoinstalls and autoconfigures fully functional DE/WM, By default ArchInstaller script install dwm and uses my [dotfiles](https://github.com/sanchit-saini/dotfiles).

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
