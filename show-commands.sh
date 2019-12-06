#!/bin/bash
#
# This shows all available commands to control the VM pool
#
#       gnd @ gnd.sk, 2017 - 2019
#
####################################################################
clear
echo ""
echo " ___        __     ___      ___       __"
echo "|\"  |      |\" \   |\"  \    /\"  |     /\"\"\ "
echo "||  |      ||  |   \   \  //   |    /    \ "
echo "|:  |      |:  |   /\\\  \/.    |   /' /\  \ "
echo " \  |___   |.  |  |: \.        |  //  __'  \ "
echo "( \_|:  \  /\  |\ |.  \    /:  | /   /  \\\  \ "
echo " \_______)(__\_|_)|___|\__/|___|(___/    \___)"


echo ""
echo "LIMA is a bunch of bash scripts used to easily create,"
echo "modify and maintain KVM virtual machines using libvirt and virsh"
echo "gnd@gnd.sk, 2017"
echo ""

echo -e "\033[1mAvailable commands: \033[0m"

echo -e "\033[1madd-apache-vhost \033[0m- Adds a apache proxy (folder or separate vhost) for a given VM. Usage: add_apache_vhost new <VM_IP>"
echo ""

echo -e "\033[1mcreate-initial-snapshot \033[0m- Creates a initial snapshot of a VM and stores it into /data/backup/snapshots. Usage: create-initial-snapshot <name>"
echo ""

echo -e "\033[1mcreate-vm \033[0m- creates a new VM. Usage: create-vm"
echo ""

echo -e "\033[1mdelete-vm \033[0m- deletes a given VM from disk and removes it from the firewall and apache. Usage: delete-vm <name NAME>"
echo ""

echo -e "\033[1mdisable-nat \033[0m- disables internet connection for a given VM. Usage: disable-nat <iface IFACE |name NAME |ip IP>"
echo ""

echo -e "\033[1menable-nat \033[0m- enables internet connection for a given VM. Usage: enable-nat <iface IFACE |name NAME |ip IP>"
echo ""

echo -e "\033[1menable-vnc \033[0m- enables VNC connections from Internet for a given VM. Usage: enable-vnc <port PORT |name NAME |ip IP |iface IFACE>"
echo ""

echo -e "\033[1mextend-disk \033[0m- extends disk space for a given VM. Usage: extend-disk <name> <size (GB)>"
echo ""

echo -e "\033[1mlima \033[0m- shows available commands to manage VMs. Usage: lima"
echo ""

echo -e "\033[1mlist-vm \033[0m- shows vms contained in vmlist. Usage: list-vm"
echo ""

echo -e "\033[1mmake-backup \033[0m- a backup script for the VMs. Usually run from /etc/crontab. Usage: make-backup [daily | weekly | monthly]"
echo ""

echo -e "\033[1mrestart-vm \033[0m- Restarts the given VM. Usage: restart-vm <name NAME> [quiet]"
echo ""

echo -e "\033[1mstart-all-vm \033[0m- Starts all VMs listed in vmlist. Usage: start-all-vm [quiet]"
echo ""

echo -e "\033[1mstart-default \033[0m- Starts the default VM. Usage: start-default"
echo ""

echo -e "\033[1mstart-vm \033[0m- Starts the given VM. Usage: start-vm <name NAME> [quiet]"
echo ""

echo -e "\033[1mstop-all-vm \033[0m- Stops all VMs listed in vmlist. Usage: stop-all-vm"
echo ""

echo -e "\033[1mstop-default \033[0m- Stops the default VM. Usage: stop-default"
echo ""

echo -e "\033[1mstop-vm \033[0m- Stops the given VM. Usage: stop-vm <name NAME>"
echo ""

echo ""
echo ""
