#!/bin/sh
# This script is the entry point for the ansible playbook
# It will follow the initial few steps after partitioning the disk
# in the arch linux installation process
#
# Then it will create the filesystems, mount, then install and run ansible
# It will install any prerequisites for ansible, then run the playbook

# Format the partitions
# Check if there should be a home partition
ROOT_MOUNT="/mnt/root"
# XXX: Replace this with pulling the ansible repo via curl or smth
ANSIBLE_PLAYBOOK_SOURCE="mkdir -p $ROOT_MOUNT/root/ansible-playbook && cp -r /mnt/ansible/* $ROOT_MOUNT/root/ansible-playbook/"

function format_partitions() {
  # NOTE: Can be made more intilligent by checking the partiton type and formatting accordingly
  # A task for another day
  read -p $"Do you want a separate home partition? (y/n)" -n 1 has_home_partition
  echo ""

  read -p "Enter the boot partition (e.g. /dev/sda1):" boot_partition
  boot_partition=${boot_partition:-"/dev/sda1"}
  if ! file -sL $boot_partition | grep -q "FAT"; then
    echo "\nFormatting boot partition"
    mkfs.fat -F32 $boot_partition
  else
    echo "Boot partition is already formatted"
  fi

  read -p "Enter the swap partition (e.g. /dev/sda2):" swap_partition
  swap_partition=${swap_partition:-"/dev/sda2"}
  if ! file -sL $swap_partition | grep -q "swap"; then
    echo "\nFormatting swap partition"
    mkswap $swap_partition
  else
    echo "Swap partition is already formatted"
  fi
  read -p "Enter the root partition (e.g. /dev/sda3):" root_partition
  root_partition=${root_partition:-"/dev/sda3"}
  if ! file -sL $root_partition | grep -q "ext4"; then
    echo "\nFormatting root partition"
    mkfs.ext4 $root_partition
  else
    echo "Root partition is already formatted"
  fi


  if [ "$has_home_partition" = "y" ]; then
    read -p "Enter the home partition (e.g. /dev/sda4):" home_partition
    home_partition=${home_partition:-"/dev/sda4"}
    if ! file -sL $home_partition | grep -q "ext4"; then
      echo "\nFormatting home partition"
      mkfs.ext4 $home_partition
    else
      echo "Home partition is already formatted"
    fi
  fi

  # This is safe because we checked if the partitions are already mounted
  echo "Mounting the partitions"
  mkdir -p $ROOT_MOUNT
  echo "Monuting root partition"
  mount $root_partition $ROOT_MOUNT
  mkdir "$ROOT_MOUNT/boot"
  echo "Mounting boot partition"
  mount $boot_partition "$ROOT_MOUNT/boot"
  echo "Enabling swap"
  swapon $swap_partition
  if [ "$has_home_partition" = "y" ]; then
    echo "Mounting home partition"
    mkdir "$ROOT_MOUNT/home"
    mount $home_partition "$ROOT_MOUNT/home"
  fi
  echo "Done mounting partitions"
}

function install_arch() {
  echo "Installing arch on the new system"

  pacstrap -K $ROOT_MOUNT base linux linux-firmware

  echo "Generating fstab"
  genfstab -U $ROOT_MOUNT >> $ROOT_MOUNT/etc/fstab
  echo "Done generating fstab"
}

function install_ansible() {
  echo "Installing ansible on the new system"
  arch-chroot $ROOT_MOUNT /bin/bash -c "pacman -Sy ansible --noconfirm"

}

echo checking if partitions are already formatted
# Check if partitions are already formatted and mounted
if  ! findmnt $ROOT_MOUNT  ; then
  format_partitions
fi

if ! arch-chroot $ROOT_MOUNT /bin/bash -c "echo arch already installed"; then
  install_arch
fi

if  ! arch-chroot $ROOT_MOUNT /bin/bash -c "which ansible-playbook" ; then
  install_ansible
fi

echo "Retrieving the ansible playbook from the source"
eval $ANSIBLE_PLAYBOOK_SOURCE

if [ -f $ROOT_MOUNT/root/ansible-playbook/pass ]; then
  echo "Vault password already exists"
else
  read -p "Enter the vault password:" -s vault_password
  echo $vault_password > $ROOT_MOUNT/root/ansible-playbook/pass
fi

echo "Running the ansible playbook"
arch-chroot $ROOT_MOUNT /bin/bash -c "ansible-playbook /root/ansible-playbook/main_playbook.yaml --vault-password-file=/root/ansible-playbook/pass -e @/root/ansible-playbook/vars.yaml -e @/root/ansible-playbook/secrets.yaml"

