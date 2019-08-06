#!/bin/bash
#
# This starts the default template
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
		sleep 1
		if [[ ! "$check" == "$hostname" ]]; then
			clean_line
            tries=$((tries+1))
			draw_tries=$((tries % 100))
            for (( try=1; try<=draw_tries; try=try+1 )); do
                printf "Waiting for VM: "$tries"s "; draw_tries
                clean_line
            done
		else
			con=1
			printf "\n\nVM up ! "
		fi
	done
}

# Ask what default VM to use
shopt -s extglob
echo "Please select what default VM to start:"
vms=`ls $VM_DIR/default/`
opts=`echo $vms|sed 's/ /|/g'`
opts=`echo "+($opts)"`
select vm in $vms
do
        case $vm in
        $vms)
                echo "Choosing: $vm"
                break
                ;;
        *)
                echo "Invalid: $vm"
                ;;
        esac
done
DEF_VM=$vm

## Make sure the default instance is not running
CHECK=`virsh list --all|grep default`
if [[ ! -z $CHECK ]]; then
        echo "Default instance is already running."
		echo "Exiting."
else
	### Start the default machine
	echo "Starting the $DEF_VM virtual machine"
	virsh create $VM_DIR/default/$DEF_VM/vm.xml

	### Wait for the VM to come up
	connect-ssh $DEFAULT_IP default

	### Print connection data
	echo "To connect use 'ssh $DEFAULT_IP'"
fi
