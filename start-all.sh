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

### Start all VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}|grep -v dummy`
do
    $SCRIPT_DIR/start-vm.sh name $VM_NAME
done