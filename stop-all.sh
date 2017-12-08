#!/bin/bash
#
# This stops the all running vms
#
#       gnd @ gnd.sk, 2017
#
####################################################################

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

usage() {
        printf "\n"
        printf "This stops all VMs listed in vmlist\n"
        printf "Usage: \n"
        printf "$0 \n\n"
}

### Stop all running VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}|grep -v dummy`
do
    $SCRIPT_DIR/stop-vm.sh name $VM_NAME
done