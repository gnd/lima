#!/bin/bash
#
# This stops a given vm
#
#       gnd @ gnd.sk, 2017
#
####################################################################

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

usage() {
        printf "\n"
        printf "This stops the given VM\n"
        printf "Usage: \n"
        printf "$0 <name NAME> \n\n"
}

### Check if VM_NAME is unique and existing, otherwise exit
case "$1" in
	'name')
		VM_NAME=$2
		LINS=`cat $VM_LIST | awk {'print $2;'}|grep $VM_NAME|wc -l`
		if [[ $LINS -lt 1 ]]; then
			printf "\n$0: No such name $VM_NAME found\n\n"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			printf "\n$0: More names like '$VM_NAME' found, please be specific:\n"
			cat $VM_LIST | awk {'print $2;'}|grep $VM_NAME
            printf "\n"
			exit
		fi
	;;
    *)
		usage
		exit
	;;
esac

### Check if the VM runs first
CHECK=`virsh list --all|grep $VM_NAME`
if [[ -z $CHECK ]]; then
    echo "Warning: $VM_NAME not running."
else
    ### Stop the VM
    printf "\n\nStoping $VM_NAME\n"
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