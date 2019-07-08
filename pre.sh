#!/bin/sh
MOUNT_POINT=/mnt
ROOT_PARTITION=/dev/sdX
ROOT_PWD=topsecret
HOSTNAME=dumbbox
LANG=en_US.UTF-8
LOCALE='en_US.UTF-8 UTF-8'
TIMEZONE=/usr/share/zoneinfo/Asia/Kolkata
USERNAME=username
USER_PWD=secret
SWAP_PARTITION=/dev/sdX#
BOOT_PARTITION=/dev/sda#
IS_UFI=true


# Refreshing Keyring
pacman -S archlinux-keyring --needed --noconfirm

# Enable swap support
swapon $SWAP_PARTITION

# Installing core
pacstrap $MOUNT_POINT base base-devel dialog vim git networkmanager

# Generating Fstab
genfstab -U $MOUNT_POINT > $MOUNT_POINT/etc/fstab

# Localization
arch-chroot $MOUNT_POINT /bin/bash -c "sed -i \"s|$(echo "#\($LOCALE\)")|\1|g\" /etc/locale.gen"
arch-chroot $MOUNT_POINT /bin/bash -c "locale-gen"
arch-chroot $MOUNT_POINT /bin/bash -c "echo -e 'LC_ALL=\nLANG=$LANG' > /etc/locale.conf"

# Timezone
arch-chroot $MOUNT_POINT /bin/bash -c "rm /etc/localtime"
arch-chroot $MOUNT_POINT /bin/bash -c "ln -sf $TIMEZONE /etc/localtime"
arch-chroot $MOUNT_POINT /bin/bash -c "hwclock --systohc"

# Set ROOT password
arch-chroot $MOUNT_POINT /bin/bash -c "echo -e '$ROOT_PWD\n$ROOT_PWD' | passwd"

# Install bootloader  
if [ $IS_UFI == 'true' ] ; then
	arch-chroot $MOUNT_POINT /bin/bash -c "mkdir /boot/EFI"
	arch-chroot $MOUNT_POINT /bin/bash -c "mount $BOOT_PARTITION /boot/EFI"
	arch-chroot $MOUNT_POINT /bin/bash -c "pacman -S grub efibootmgr dosfstools os-prober mtools --noconfirm"
	arch-chroot $MOUNT_POINT /bin/bash -c "grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --recheck"
else 
	arch-chroot $MOUNT_POINT /bin/bash -c "pacman -S grub --needed --noconfirm"
	arch-chroot $MOUNT_POINT /bin/bash -c "grub-install --target=i386-pc $ROOT_PARTITION"
fi

# hibernation support
if [ $(cat /etc/default/grub | grep resume | wc -l) == 0 ] ; then
    arch-chroot $MOUNT_POINT /bin/bash -c "sed -i -e $(grep -n 'GRUB_CMDLINE_LINUX_DEFAULT' /etc/default/grub | cut -d: -f 1)s'|.$| resume=$SWAP_PARTITION\"|' /etc/default/grub "
fi

# build boot config file
arch-chroot $MOUNT_POINT /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# Create new user
arch-chroot $MOUNT_POINT /bin/bash -c "useradd -m -g users -G wheel,storage,power -s /bin/bash $USERNAME"

# Set USER password
arch-chroot $MOUNT_POINT /bin/bash -c "echo -e '$USER_PWD\n$USER_PWD' | passwd $USERNAME"

# Enable Sudo access
arch-chroot $MOUNT_POINT /bin/bash -c "sed -i 's|#\(%wheel ALL=(ALL) ALL\)|\1|g' /etc/sudoers"

# Set Hostname
arch-chroot $MOUNT_POINT /bin/bash -c "echo $HOSTNAME > /etc/hostname"

# TODO test add resume in initframs & generate new kernel image
if [ $(cat $MOUNT_POINT/etc/mkinitcpio.conf | grep resume | wc -l) == 0 ] ; then
	arch-chroot $MOUNT_POINT /bin/bash -c "sed -i -e $(grep -n 'resume' /etc/mkinitcpio.conf | cut -d: -f 1)s'|.$| resume\"|' /etc/mkinitcpio.conf"
fi
arch-chroot $MOUNT_POINT /bin/bash -c "mkinitcpio -p linux"

# fetch post script and config files in user home directory
arch-chroot $MOUNT_POINT /bin/bash -c "cd /home/$USERNAME \
	&& git clone https://github.com/sanchit-saini/ArchInstaller.git \
	&& git clone https://github.com/sanchit-saini/dotfiles.git"

umount -a
reboot
