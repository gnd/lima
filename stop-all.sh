#!/bin/bash
#
# This stops the all running vms
#
#       gnd @ gnd.sk, 2017 - 2019
#
####################################################################

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings

usage() {
        printf "\n"
        printf "This stops all VMs listed in vmlist\n"
        printf "Usage: \n"
        printf "$0 \n\n"
}

# Warn the user
clear
echo "This will stop all machines at once"
echo "It might take a few minutes for all VMs to stop. Check list-vm to see what machines are still running"
sleep 5

### Stop all running VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}`
do
    $SCRIPT_DIR/stop-vm.sh name $VM_NAME &
done
