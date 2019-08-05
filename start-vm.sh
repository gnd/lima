#!/bin/bash
#
# This starts the given VM
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

### waits until conection to new VM established
connect-ssh() {
	local ip=${1}
	local hostname=${2}
	con=0
	tries=0

	draw_tries() { for ((i=0; i<try; i=i+1)); do printf "▇"; done }
	clean_line() { printf "\r"; }

	while [[ "$con" == "0" ]]; do
		check=`ssh -q -o ConnectTimeout=1 -o StrictHostKeyChecking=no $ip hostname`
		if [[ ! "$check" == "$hostname" ]]; then
			clean_line
			tries=$((tries+1))
			for (( try=1; try<=tries; try=try+1 )); do
				printf "Waiting for VM: "$tries"s "; draw_tries
				clean_line
			done
		else
			con=1
			printf "\n\nVM up ! "
		fi
	done
}

usage() {
        printf "\n"
        printf "This starts the given VM\n"
        printf "Usage: \n"
        printf "$0 <name NAME> [quiet] \n\n"
}

### Check if VM_NAME is unique and existing, otherwise exit
case "$1" in
	'name')
		VM_NAME=$2
        if [[ $VM_NAME == "dummy" ]]; then
            printf "\n$0: Cant start dummy\n\n"
			exit
        fi
		LINS=`cat $VM_LIST | awk {'print $2;'}|grep -wF "$VM_NAME"|wc -l`
		if [[ $LINS -lt 1 ]]; then
			printf "\n$0: No such name $VM_NAME found\n\n"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			printf "\n$0: More names like '$VM_NAME' found, please be specific:\n"
			cat $VM_LIST | awk {'print $2;'}|grep -wF "$VM_NAME"
            printf "\n"
			exit
		fi
	;;
    *)
		usage
		exit
	;;
esac

### Make sure the VM is not running
CHECK=`virsh list --all|grep $VM_NAME`
if [[ ! -z $CHECK ]]; then
    printf "\n$0: $VM_NAME is already running.\n"
else
    ### Determine VM parameters
    VM_TYPE=`cat $VM_LIST | awk {'print $2" "$5;'}|grep -wF "$VM_NAME"|awk {'print $2;'}`
    VM_IP=`cat $VM_LIST | awk {'print $2" "$3;'}|grep -wF "$VM_NAME"|awk {'print $2;'}`
    if [[ $VM_TYPE == "dyn" ]]; then
        VM_TYPE_DIR="dynamic"
    fi
    if [[ $VM_TYPE == "sta" ]]; then
        VM_TYPE_DIR="static"
    fi

    ### Start the VM
    echo "Starting $VM_NAME"
    virsh create $VM_DIR/$VM_TYPE_DIR/$VM_NAME/vm.xml

    ### Wait for the VM to come up
    if [[ $3 != "quiet" ]]; then
        connect-ssh $VM_IP $VM_NAME
    else
        sleep 1
    fi

    ### Print VM is up
    echo "$VM_NAME is up."
fi
