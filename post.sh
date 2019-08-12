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
# Arguments:
#   None
# Returns:
#   None
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
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_packages() {
  sudo pacman -S --noconfirm $PACKAGES
  yay -S --noconfirm $AUR_PACKAGES
}


#######################################
# build, install and configure from 
# github repository
# Globals:
#   GIT_REPOS
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_and_configure_git_repos() {
  echo "$GIT_REPOS" | sed "s|https|\nhttps|g" | xargs -n 1 git clone
  cp ~/dotfiles/st/config.h ~/dotfiles/st/st-copyout st/
  cd st && sudo make -j4 install
}


#######################################
# for configuring packages
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function configure() {
  rm -rf ~/dotfiles/.git
  cp -r ~/dotfiles/. ~/
}


#######################################
# remove unnecessary files
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function clean() {
  rm -rf ~/dotfiles ~/ArchInstaller st/
}


#######################################
# Entry point function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function main() {
  aur_install
  install_packages
  install_and_configure_git_repos
  configure
  clean
}

main