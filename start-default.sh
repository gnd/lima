#!/bin/bash
#
# This starts the default template
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

## Make sure the default instance is not running
CHECK=`virsh list --all|grep default`
if [[ ! -z $CHECK ]]; then
        echo "Default instance is already running."
else
	### Start the default machine
	echo "Starting the default virtual machine"
	virsh create $VM_DIR/default/default.xml

	### Wait for the VM to come up
	connect-ssh $DEFAULT_IP default

	### Print connection data
	echo "To connect use 'ssh $DEFAULT_IP'"
fi
