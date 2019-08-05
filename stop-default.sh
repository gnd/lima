#!/bin/bash
#
# This stops the default template
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

## Make sure the default instance is running
CHECK=`virsh list --all|grep default`
if [[ -z $CHECK ]]; then
        echo "Default instance is not running."
else
	### Stop the default machine
	echo "Stoping the default virtual machine"
	virsh destroy default

	echo "Default instance has been stopped."
fi
