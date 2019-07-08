#!/bin/sh

# Installing Yay 
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd .. && rm -rf yay

# Reading Package list
PACKAGES=$(awk -F ',' 'FNR > 1 {print $1,$2}' packages.csv | grep 'P' | awk '{print $1}' | xargs)
AUR_PACKAGES=$(awk -F ',' 'FNR > 1 {print $1,$2}' packages.csv | grep 'A' | awk '{print $1}' | xargs)
GIT_REPOS=$(awk -F ',' 'FNR > 1 {print $1,$2}' packages.csv | grep 'G' | awk '{print $1}')

# Installing :)
sudo pacman -S --noconfirm $PACKAGES
echo yay -S --noconfirm $AUR_PACKAGES

echo $GIT_REPOS | sed "s|https|\nhttps|g" | xargs -n 1 git clone

cp ../dotfiles/config.h st/
cp ../dotfiles/st-copyout st/
cd st && make
sudo make install

rm -rf ../dotfiles/.git
cp -r ../dotfiles/ ~/

rm -rf ~/dotfiles ~/ArchInstaller
