#!/usr/bin/env bash
#
# Install arch linux

set -e

source config

BIOD_BOOTLOADER_PACKAGES="grub"
UEFI_BOOTLOADER_PACKAGES="grub efibootmgr dosfstools os-prober mtools"
BASE_INSTALL_PACKAGES="base base-devel dialog vim git networkmanager"
BOOT_PARTITION=""
ROOT_PARTITION=""
SWAP_PARTITION=""
HOME_PARTITION=""


#######################################
# Set partitions on the base of bios type 
# Globals:
#   DEVICE
#   BIOS_TYPE
#   DEVICE_TYPE
#   BOOT_PARTITION
#   ROOT_PARTITION
#   SWAP_PARTITION
#   HOME_PARTITION
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_partitions() {
if [[ $BIOS_TYPE == "UEFI" ]] ; then
  if [[ $DEVICE_TYPE == "SATA" ]]; then
    BOOT_PARTITION="${DEVICE}1"
    ROOT_PARTITION="${DEVICE}2"
    SWAP_PARTITION="${DEVICE}3"
    HOME_PARTITION="${DEVICE}4"
  fi

  if [[ $DEVICE_TYPE == "NVME" ]]; then
    BOOT_PARTITION="${DEVICE}p1"
    ROOT_PARTITION="${DEVICE}p2"
    SWAP_PARTITION="${DEVICE}p3"
    HOME_PARTITION="${DEVICE}p4"
  fi
fi

if [[ $BIOS_TYPE == "BIOS" ]] ; then
  if [[ $DEVICE_TYPE == "SATA" ]]; then
    ROOT_PARTITION="${DEVICE}1"
    SWAP_PARTITION="${DEVICE}2"
    HOME_PARTITION="${DEVICE}3"
  fi
  
  if [[ $DEVICE_TYPE == "NVME" ]]; then
    ROOT_PARTITION="${DEVICE}p1"
    SWAP_PARTITION="${DEVICE}p2"
    HOME_PARTITION="${DEVICE}p3"
  fi
fi
}


#######################################
# Wipe device and create partitions
# Globals:
#   DEVICE
#   BIOS_TYPE
#   DEVICE_TYPE
#   MOUNT_POINT
#   BOOT_PARTITION
#   ROOT_PARTITION
#   SWAP_PARTITION
#   HOME_PARTITION
#   BOOT_PARTITION_SIZE
#   ROOT_PARTITION_SIZE
#   SWAP_PARTITION_SIZE
#   HOME_PARTITION_SIZE
# Arguments:
#   None
# Returns:
#   None
#######################################
function make_partitions() {
  sgdisk --zap-all $DEVICE
  wipefs -a $DEVICE

  # TODO : Need more robust way to set start and end point and a way to handle conversion between MiB,GiB
  if [[ $BIOS_TYPE == "UEFI" ]] ; then
		local BOOT_START
    local BOOT_END
    local ROOT_START
    local ROOT_END
    local SWAP_START
    local SWAP_END
    local HOME_START
    local HOME_END

    # Initialize start and end point of different partitions
    BOOT_START=1MiB
    BOOT_END=$BOOT_PARTITION_SIZE
   
    ROOT_START=$BOOT_END
    # converting MiB to GiB for BOOT_END, striping GiB to do addition operation and appending GiB at end
    ROOT_END=$(echo 0."${BOOT_END::-3}" + ${ROOT_PARTITION_SIZE::-3}|bc)${ROOT_PARTITION_SIZE:(-3)}

    SWAP_START=$ROOT_END
    # striping GiB to do addition operation and appending GiB at end
    SWAP_END=$(echo "${ROOT_END::-3}" + ${SWAP_PARTITION_SIZE::-3}|bc)${SWAP_PARTITION_SIZE:(-3)}

    HOME_START=$SWAP_END
    HOME_END=$(echo "${SWAP_END::-3}" + ${HOME_PARTITION_SIZE::-3} - 0.01|bc)${HOME_PARTITION_SIZE:(-3)}

    parted -s "$DEVICE" mklabel gpt \
    mkpart primary fat32 "$BOOT_START" "$BOOT_END" set 1 boot on \
    mkpart primary ext4 "$ROOT_START" "$ROOT_END" \
    mkpart primary ext4 "$SWAP_START" "$SWAP_END" \
    mkpart primary ext4 "$HOME_START" "$HOME_END"
    
    set_partitions
    mkfs.fat -F32 $BOOT_PARTITION
    
  fi

  if [[ $BIOS_TYPE == "BIOS" ]] ; then

    ROOT_START=1MiB
    ROOT_END=$ROOT_PARTITION_SIZE
		
    SWAP_START=$ROOT_END
    # striping GiB to do addition operation and appending GiB at end
    SWAP_END=$(echo "${ROOT_END::-3}" + ${SWAP_PARTITION_SIZE::-3}|bc)${SWAP_PARTITION_SIZE:(-3)}

    HOME_START=$SWAP_END
    HOME_END=$(echo "${SWAP_END::-3}" + ${HOME_PARTITION_SIZE::-3} - 0.01|bc)${HOME_PARTITION_SIZE:(-3)}

    parted -s $DEVICE mklabel msdos \
    mkpart primary ext4 "$ROOT_START" "$ROOT_END" set 1 boot on \
    mkpart primary linux-swap "$SWAP_START" "$SWAP_END" \
    mkpart primary ext4 "$HOME_START" "$HOME_END"

    set_partitions
  fi
  mkfs.ext4 $ROOT_PARTITION
  mkfs.ext4 $HOME_PARTITION
  mkswap $SWAP_PARTITION
}


#######################################
# Mount partitions
# Globals:
#   BIOS_TYPE
#   MOUNT_POINT
#   BOOT_PARTITION
#   ROOT_PARTITION
#   SWAP_PARTITION
#   HOME_PARTITION
# Arguments:
#   None
# Returns:
#   None
#######################################
function mount_partitions() {	
  mount $ROOT_PARTITION $MOUNT_POINT
  mkdir $MOUNT_POINT/home
  mount $HOME_PARTITION $MOUNT_POINT/home

  if [[ $BIOS_TYPE == "UEFI" ]] ; then
    mkdir -p $MOUNT_POINT/boot/EFI
    mount $BOOT_PARTITION $MOUNT_POINT/boot/EFI
  fi
}


#######################################
# To enable the device for paging
# Globals:
#   SWAP_PARTITION
# Arguments:
#   Command
# Returns:
#   None
#######################################
function swap_on() {
  swapon $SWAP_PARTITION
}


#######################################
# Execute command in new sys env
# Globals:
#   MOUNT_POINT
# Arguments:
#   Command
# Returns:
#   None
#######################################
function arch_chroot_exec() {
  arch-chroot $MOUNT_POINT /bin/bash -c "$1"
}


#######################################
# Install base packages
# Globals:
#   MOUNT_POINT
#   BASE_INSTALL_PACKAGES
# Arguments:
#   None
# Returns:
#   None
#######################################
function base_install() {
  pacstrap $MOUNT_POINT $BASE_INSTALL_PACKAGES
}


#######################################
# Generate fstab file
# Globals:
#   MOUNT_POINT
# Arguments:
#   None
# Returns:
#   None
#######################################
function configure_genfstab() {
  sh -c "genfstab -U $MOUNT_POINT > $MOUNT_POINT/etc/fstab"
}


#######################################
# Link timezone file and sync hwclock
# Globals:
#   TIMEZONE
# Arguments:
#   None
# Returns:
#   None
#######################################
function configure_timezone() {
  arch_chroot_exec "rm /etc/localtime"
  arch_chroot_exec "ln -sf $TIMEZONE /etc/localtime"
  arch_chroot_exec "hwclock --systohc"
}


#######################################
# Generate Localization config
# Globals:
#   LANG
#   LOCALE
# Arguments:
#   None
# Returns:
#   None
#######################################
function configure_locale() {
  arch_chroot_exec "sed -i \" s|#\($LOCALE\)|\1|g \" /etc/locale.gen"
  arch_chroot_exec "locale-gen"
  arch_chroot_exec "echo -e 'LC_ALL=\nLANG=$LANG' > /etc/locale.conf"
}


#######################################
# Install grub bootloader
# Globals:
#   DEVICE
#   BIOS_TYPE
#   UEFI_BOOTLOADER_PACKAGES
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_grub_bootloader() {
  if [[ $BIOS_TYPE == "UEFI" ]] ; then	
    arch_chroot_exec "pacman -S $UEFI_BOOTLOADER_PACKAGES --needed --noconfirm"
    arch_chroot_exec "grub-install --target=x86_64-efi --recheck --bootloader-id=grub_uefi"
  fi
  if [[ $BIOS_TYPE == "BIOS" ]] ; then
    arch_chroot_exec "pacman -S $BIOD_BOOTLOADER_PACKAGES --needed --noconfirm"
    arch_chroot_exec "grub-install --target=i386-pc --recheck $DEVICE"
  fi
}


#######################################
# Enable hibernation by adding kernel 
# parameter resume in grub & resume hook 
# in initramfs
# Globals:
#   SWAP_PARTITION
# Arguments:
#   None
# Returns:
#   None
#######################################
function enable_swap_hibernation() {
  local GRUB_CONFIG_PATH
  GRUB_CONFIG_PATH=/etc/default/grub
  # Checking grub.cfg file doesn't contain resume kernel parameter
  if [[ $(grep -ic 'resume' $GRUB_CONFIG_PATH) == 0 ]] ; then

    # Locating line number which contains GRUB_CMDLINE_LINUX_DEFAULT
    local LINE_NUMBER
    LINE_NUMBER=$(grep -n 'GRUB_CMDLINE_LINUX_DEFAULT' $GRUB_CONFIG_PATH | head -c 1)

    # Adding resume parameter at the end of located line in grub.cfg file
    arch_chroot_exec "sed -i -e ""$LINE_NUMBER""s'|.$| resume=$SWAP_PARTITION\"|' $GRUB_CONFIG_PATH"
  fi

  local MKINIT_CONFIG_PATH=/etc/mkinitcpio.conf
  # Checking mkinitcpio.conf file doesn't contain resume kernel parameter
  if [[ $(grep -ic 'resume' $MKINIT_CONFIG_PATH) == 0 ]] ; then

    # Adding resume hook in mkinitcpio.conf file
    arch_chroot_exec "sed -i 's|keyboard|keyboard resume|g' $MKINIT_CONFIG_PATH"
    
    # Building images
    arch_chroot_exec "mkinitcpio -p linux"
  fi
}


#######################################
# Generate grub config file
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function configure_grub() {
  arch_chroot_exec "grub-mkconfig -o /boot/grub/grub.cfg"
}


#######################################
# Set root password
# Globals:
#   ROOT_PASSWD
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_root_passwd() {
  arch_chroot_exec "echo -e '$ROOT_PASSWD\n$ROOT_PASSWD' | passwd"
}


#######################################
# Create user
# Globals:
#   USERNAME
# Arguments:
#   None
# Returns:
#   None
#######################################
function create_user() {
  arch_chroot_exec "useradd -m -g users -G wheel,storage,power -s /bin/bash $USERNAME"
}


#######################################
# Set created user password
# Globals:
#   USERNAME
#   USER_PASSWD
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_user_passwd() {
  arch_chroot_exec "echo -e '$USER_PASSWD\n$USER_PASSWD' | passwd $USERNAME"
}


#######################################
# Uncomment wheel group in sudoers file
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function enable_sudo_privilege () {
  arch_chroot_exec "sed -i 's|# %wheel ALL=(ALL) ALL|%wheel ALL=(ALL) ALL|g' /etc/sudoers"
}


#######################################
# Set hostname
# Globals:
#   HOSTNAME
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_hostname() {
  arch_chroot_exec "echo $HOSTNAME > /etc/hostname"
}


#######################################
# Copy Installation script and dotfile
# in home & change ownership of files
# Globals:
#   USERNAME
#   DOTFIlES
#   MOUNT_POINT
# Arguments:
#   None
# Returns:
#   None
#######################################
function copy_script() {
  cp -r "$(pwd)" $MOUNT_POINT/home/$USERNAME
  arch_chroot_exec "cd /home/$USERNAME && git clone $DOTFIlES"
  arch_chroot_exec "cd /home/$USERNAME && chown -hR $USERNAME:users ."
}


#######################################
# Enable network serive
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function enable_network_manager() {
  arch_chroot_exec "systemctl enable NetworkManager"
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
  make_partitions
  mount_partitions
  swap_on
  base_install
  configure_genfstab
  configure_timezone
  configure_locale
  install_grub_bootloader
  enable_swap_hibernation
  configure_grub
  set_root_passwd
  create_user
  set_user_passwd
  enable_sudo_privilege
  set_hostname
  copy_script
  enable_network_manager
  reboot
}

main