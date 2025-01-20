# Home PC Ansible setup

A collection of Ansible playbooks to set up my home PC in case it is formatted from scratch.

Make sure the boot, swap, and root partitions are formatted correctly first. You may use `cfdisk` or `fdisk` to format and prepare the partitions.

The script does not attempt to format the partitions to avoid any unintional data loss.

To start the setup, run the following command:

```bash
curl -sSL https://raw.githubusercontent.com/OZoneGuy/home-pc-ansible/master/setup.sh | bash
```
 
or

```bash
wget -qO- https://raw.githubusercontent.com/OZoneGuy/home-pc-ansible/master/setup.sh | bash
```
