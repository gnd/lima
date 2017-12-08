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

### Start all running VMS from vmlist
for VM_NAME in `cat $VM_LIST | awk {'print $2;'}|grep -v dummy`
do
    ### Make sure the VM is not running
    CHECK=`virsh list --all|grep $VM_NAME`
    if [[ ! -z $CHECK ]]; then
        echo "$VM_NAME is already running."
    else
        ### Determine VM parameters
        VM_TYPE=`cat $VM_LIST | awk {'print $2" "$5;'}|grep $VM_NAME|awk {'print $2;'}`
		VM_IP=`cat $VM_LIST | awk {'print $2" "$3;'}|grep $VM_NAME|awk {'print $2;'}`
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
        connect-ssh $VM_IP $VM_NAME

        ### Print VM is up
        echo "$VM_NAME is up."
    fi
done
