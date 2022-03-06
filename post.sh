#!/usr/bin/env bash
#
# This script install packages specified in packages.csv file 
# and to handle post install configuration for installed packages
#
# If default dotfiles are not used, then these functions should be updated accordingly
#   install_and_configure_git_repos()
#   configure()
#   clean()

set -e

source config

# Reading packages from csv file
PACKAGES=$(awk -F ',' 'FNR > 1 {print $1,$2}' packages.csv \
          | grep 'P' \
          | awk '{print $1}' \
          | xargs)
AUR_PACKAGES=$(awk -F ',' 'FNR > 1 {print $1,$2}' packages.csv \
          | grep 'A' \
          | awk '{print $1}' \
          | xargs)
GIT_REPOS=$(awk -F ',' 'FNR > 1 {print $1,$2}' packages.csv \
          | grep 'G' \
          | awk '{print $1}')


#######################################
# Build and Install AUR Helper from src
# Globals:
#   AUR_HELPER
#######################################
function aur_install() {
  git clone --depth 1 https://aur.archlinux.org/"$AUR_HELPER".git
  cd "$AUR_HELPER" && makepkg -si --noconfirm &&
  cd .. && rm -rf "$AUR_HELPER"
}


#######################################
# Install packages 
# Globals:
#   PACKAGES
#   AUR_PACKAGES
#######################################
function install_packages() {
  sudo pacman -S --noconfirm $PACKAGES
  yay -S --noconfirm $AUR_PACKAGES
}


#######################################
# for configuring packages
#######################################
function configure() {
  rm -rf ~/dotfiles/.git
  cp -r ~/dotfiles/. ~/
  mkdir ~/Screenshots ~/Desktop ~/Workspace
}


#######################################
# update kernel to linux-lts
#######################################
function change_kernel() {
  sudo pacman -S --noconfirm linux-lts linux-lts-headers
  sudo pacman -Rddcuns --noconfirm linux
  sudo grub-mkconfig -o /boot/grub/grub.cfg
}


#######################################
# install dwm, dwmblocks, and st
#######################################
function install_suckless_tools() {
    git clone --depth 1 https://github.com/sanchit-saini/dwm.git
    git clone --depth 1 https://github.com/sanchit-saini/dwmblocks.git
    git clone --depth 1 https://github.com/sanchit-saini/st.git
    cd dwm
    ./install.sh
    cd ../dwmblocks/
    ./install.sh
    cd ../st/
    ./install.sh
}

#######################################
# remove unnecessary files
#######################################
function clean() {
  rm -rf ~/dotfiles ~/sanchit-saini-ArchInstaller-*
}


#######################################
# Entry point function
#######################################
function main() {
  aur_install
  install_packages
  configure
  install_suckless_tools
  change_kernel
  clean
}

main
