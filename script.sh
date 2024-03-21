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
ANSIBLE_PLAYBOOK_SOURCE="cp /mnt/ansible/main_playbook.yaml $ROOT_MOUNT/root/ansible-playbook.yaml"

read -p $"Do you want a separate home partition? (y/n)" -n 1 has_home_partition
echo ""

read -p "Enter the boot partition (e.g. /dev/sda1):" boot_partition
echo "\nFormatting boot partition"
mkfs.fat -F32 $boot_partition
read -p "Enter the swap partition (e.g. /dev/sda2):" swap_partition
echo "\nFormatting swap partition"
mkswap $swap_partition
read -p "Enter the root partition (e.g. /dev/sda3):" root_partition
echo "\nFormatting root partition"
mkfs.ext4 $root_partition


if [ "$has_home_partition" = "y" ]; then
    read -p "Enter the home partition (e.g. /dev/sda2):" home_partition
    echo "\nFormatting home partition"
    mkfs.ext4 $home_partition
fi

echo "Mounting the partitions"
mkdir -p $ROOT_MOUNT
mount $root_partition $ROOT_MOUNT
mkdir "$ROOT_MOUNT/boot"
mount $boot_partition "$ROOT_MOUNT/boot"
swapon $swap_partition
if [ "$has_home_partition" = "y" ]; then
    echo "Mounting home partition"
    mkdir "$ROOT_MOUNT/home"
    mount $home_partition "$ROOT_MOUNT/home"
fi
echo "Done mounting partitions"

echo "Installing arch on the new system"

pacstrap -K $ROOT_MOUNT base linux linux-firmware

echo "Generating fstab"
genfstab -U $ROOT_MOUNT >> $ROOT_MOUNT/etc/fstab
echo "Done generating fstab"

echo "Installing ansible on the new system"
arch-chroot $ROOT_MOUNT /bin/bash -c "pacman -Sy ansible --noconfirm"

echo "Retrieving the ansible playbook from the source"
eval $ANSIBLE_PLAYBOOK_SOURCE

echo "Running the ansible playbook"
# arch-chroot /mnt /bin/bash -c "ansible-playbook /root/ansible-playbook.yaml"
