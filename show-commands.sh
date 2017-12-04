#!/bin/bash
#
# This shows all available commands to control the VM pool
#
#       gnd @ gnd.sk, 2017
#
####################################################################
clear
echo ""
echo "
 ___        __     ___      ___       __      
|\"  |      |\" \   |\"  \    /\"  |     /\"\"\     
||  |      ||  |   \   \  //   |    /    \    
|:  |      |:  |   /\\\  \/.    |   /' /\  \   
 \  |___   |.  |  |: \.        |  //  __'  \  
( \_|:  \  /\  |\ |.  \    /:  | /   /  \\\  \ 
 \_______)(__\_|_)|___|\__/|___|(___/    \___)
"
                                              
echo "LIMA is a bunch of bash scripts used to easily create,"
echo "modify and maintain KVM virtual machines using libvirt and virsh"
echo "gnd@gnd.sk, 2017"
echo ""
echo -e "\033[1mAvailable commands: \033[0m"
echo ""

echo -e "\033[1madd-apache-vhost \033[0m"
echo "- adds a apache proxy (folder or separate vhost) for a given VM"
echo "usage: add_apache_vhost new <VM_IP>"
echo ""

echo -e "\033[1mcreate-initial-snapshot \033[0m"
echo "- creates a initial snapshot of a VM and stores it into /data/backup/snapshots"
echo "usage: create-initial-snapshot <name>"
echo ""

echo -e "\033[1mcreate-vm \033[0m"
echo "- creates a new VM"
echo "usage: create-vm"
echo ""

echo -e "\033[1mdelete-vm \033[0m"
echo "- deletes a given VM from disk and removes it from the firewall and apache"
echo "usage: delete-vm <name NAME>"
echo ""

echo -e "\033[1mdisable-nat \033[0m"
echo "- disables internet connection for a given VM"
echo "usage: disable-nat <iface IFACE |name NAME |ip IP>"
echo ""

echo -e "\033[1menable-nat \033[0m"
echo "- enables internet connection for a given VM"
echo "usage: enable-nat <iface IFACE |name NAME |ip IP>"
echo ""

echo -e "\033[1menable-vnc \033[0m"
echo "- enables VNC connections from Internet for a given VM"
echo "usage: enable-vnc <port PORT |name NAME |ip IP |iface IFACE>"
echo ""

echo -e "\033[1mextend-disk \033[0m"
echo "- extends disk space for a given VM"
echo "usage: extend-disk <name> <size (GB)>"
echo ""

echo -e "\033[1mlima \033[0m"
echo "- shows available commands to manage VMs"
echo "usage: lima"
echo ""

echo -e "\033[1mlist-vm \033[0m"
echo "- shows vms contained in vmlist"
echo "usage: list-vm"
echo ""

echo -e "\033[1mmake-backup \033[0m"
echo "- a backup script for the VMs. Usually run from /etc/crontab"
echo "usage: make-backup [daily | weekly | monthly]"
echo ""

echo -e "\033[1mstart-default \033[0m"
echo "- Starts the default VM"
echo "usage: start-default"
echo ""

echo -e "\033[1mstop-default \033[0m"
echo "- Stops the default VM"
echo "usage: stop-default"
echo ""
