#!/bin/bash
#
# This starts the all the VMs listed in vmlist
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
        printf "This starts all VMs listed in vmlist\n"
        printf "Usage: \n"
        printf "$0 [quiet] \n\n"
}

### Start all VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}`
do
    if [[ $1 == "quiet" ]]; then
        $SCRIPT_DIR/start-vm.sh name $VM_NAME quiet
    else
        $SCRIPT_DIR/start-vm.sh name $VM_NAME
    fi
done
