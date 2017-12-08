#!/bin/bash
#
# This starts the all the VMs listed in vmlist 
#
#       gnd @ gnd.sk, 2017
#
####################################################################

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

usage() {
        printf "\n"
        printf "This starts all VMs listed in vmlist\n"
        printf "Usage: \n"
        printf "$0 [quiet] \n\n"
}

### Start all VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}|grep -v dummy`
do
    if [[ $1 == "quiet" ]]; then 
        $SCRIPT_DIR/start-vm.sh name $VM_NAME quiet
    else 
        $SCRIPT_DIR/start-vm.sh name $VM_NAME
    fi
done