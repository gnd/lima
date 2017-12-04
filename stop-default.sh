#!/bin/bash
#
# This stops the default template
#
#       gnd @ gnd.sk, 2017
#
####################################################################

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

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
