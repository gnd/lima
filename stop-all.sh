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

### Stop all running VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}`
do
    ### Check if the VM runs first
    CHECK=`virsh list --all|grep $VM_NAME`
    if [[ -z $CHECK ]]; then
        echo "Warning: $VM_NAME listed but not running."
    else
        ### Stop the VM
        echo "Stoping $VM_NAME"
        virsh destroy $VM_NAME
        
        ### Sleep for a while
        sleep 1 # this is so arbitrary

        ### Check if successfull
        CHECK=`virsh list --all|grep $VM_NAME`
        if [[ -z $CHECK ]]; then
            echo "$VM_NAME has been stopped."
        else
            echo "Warning: $VM_NAME still running."
        fi
    fi
done