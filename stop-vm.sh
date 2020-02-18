#!/bin/bash
#
# This stops a given vm
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
        printf "This stops the given VM\n"
        printf "Usage: \n"
        printf "$0 <name NAME> \n\n"
}

### Check if VM_NAME is unique and existing, otherwise exit
case "$1" in
	'name')
		VM_NAME=$2
		LINS=`cat $VM_LIST | awk {'print $2;'}|grep "^$VM_NAME$"|wc -l`
		if [[ $LINS -lt 1 ]]; then
			printf "\n$0: No such name $VM_NAME found\n\n"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			printf "\n$0: More names like '$VM_NAME' found, please be specific:\n"
			cat $VM_LIST | awk {'print $2;'}|grep "^$VM_NAME$"
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
CHECK=`virsh list --all|grep " $VM_NAME "`
if [[ -z $CHECK ]]; then
    printf "\n$0: Warning: $VM_NAME not running.\n"
else
    ### Stop the VM
    printf "Stoping $VM_NAME\n"
    virsh destroy $VM_NAME

    ### Sleep for a while
    sleep 1 # this is so arbitrary

    ### Check if successfull
    CHECK=`virsh list --all|grep " $VM_NAME "`
    if [[ ! -z $CHECK ]]; then
        printf "$0: Warning: $VM_NAME still running.\n\n"
    fi
fi
