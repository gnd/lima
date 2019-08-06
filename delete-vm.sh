#!/bin/bash
#
# This deletes a VM from the whole system. Use carefully
#
#       gnd @ gnd.sk, 2017 - 2019
#
#######################################################################

usage() {
	printf "\n"
	printf "This deletes a VM completely from the system & disk \n"
	printf "Usage: \n"
	printf "$0 <name VM_NAME> \n\n"
}

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings
DATUM=`/bin/date +%D|sed 's/\//_/g'`

### VM specified
case "$1" in
	'name')
		VM_NAME=$2
		LINS=`cat $VM_LIST | awk {'print $2;'}|grep $VM_NAME|wc -l`
		if [[ $LINS -lt 1 ]]; then
			echo "No such name $VM_NAME found"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			echo "More names found, please be specific:"
			cat $VM_LIST | awk {'print $2;'}|grep $VM_NAME
			exit
		fi
		VM_PORT=`cat $VM_LIST | awk {'print $2" "$4;'}|grep $VM_NAME|awk {'print $2;'}`
		VM_TYPE=`cat $VM_LIST | awk {'print $2" "$5;'}|grep $VM_NAME|awk {'print $2;'}`
		VM_IP=`cat $VM_LIST | awk {'print $2" "$3;'}|grep $VM_NAME|awk {'print $2;'}`
		PROXY=`cat $VM_LIST | awk {'print $2" "$6;'}|grep $VM_NAME|awk {'print $2;'}`
	;;
	*)
		usage
		exit
	;;
esac

### Delete VM from all files
read -p "This will delete all the data for the VM $VM_NAME. Do you wish to proceed ? [y/n]: " ANS
if [[ $ANS == "y" ]]; then

	# create conf file backup
	tar -cf /data/backup/temp/conf_$DATUM.tar $VM_DIR/vmlist $VM_DIR/static.allowed $VM_DIR/dynamic.banned $VM_DIR/proxies.conf $VM_DIR/forwards

	# destroy from libvirtd
	virsh destroy $VM_NAME

	# remove from pool
	if [[ $VM_TYPE == "dyn" ]]; then
		echo "Deleting dynamic VM $VM_NAME from disk"
		mv $VM_DIR/dynamic/$VM_NAME /data/backup/temp/vms/dynamic/

	fi
	if [[ $VM_TYPE == "sta" ]]; then
		echo "Deleting static VM $VM_NAME from disk"
	        mv $VM_DIR/static/$VM_NAME /data/backup/temp/vms/static/
	fi

	# remove from firewalls
	echo "Removing VM $VM_NAME from firewalls"
	if [[ $VM_TYPE == "dyn" ]]; then
		$SCRIPT_DIR/enable-nat.sh name $VM_NAME
	fi
	if [[ $VM_TYPE == "sta" ]]; then
		$SCRIPT_DIR/disable-nat.sh name $VM_NAME
	fi

	# remove from SSH forwards
	if [[ -f $VM_DIR/ssh-forwards ]]; then
		echo "Removing SSH forwards for VM $VM_NAME"
		sed -i "/$VM_IP/d" $VM_DIR/ssh-forwards
		# Reload the system firewall
		if [ ! -z $OSFW ]; then
			$OSFW
		fi
		# Reload the lima firewall
		$IPFW
	fi

	# remove from proxies
	RED='\033[0;31m'
	NC='\033[0m'
	if [[ $PROXY == "folder" ]]; then
		echo "Removing Apache proxy for VM $VM_NAME from proxies.conf"
        	sed -i "/$VM_IP/d" $VM_DIR/proxies.conf
	fi
	if [[ $PROXY == "vhost" ]]; then
		FILE=`grep -l $VM_IP $APACHE_VHOST_DIR/*|tail -1`
		if [[ ! -z $FILE ]]; then
			printf "${RED}This VM has a separate apache vhost: $FILE. Please remove manually.${NC}\n"
		else
			printf "${RED}This VM might have a separate apache vhost. Please check & remove manually.${NC}\n"
		fi
        fi
	if [[ $PROXY == "both" ]]; then
		echo "Removing Apache proxy for VM $VM_NAME from proxies.conf"
		sed -i "/$VM_IP/d" $VM_DIR/proxies.conf
		FILE=`grep -l $VM_IP $APACHE_VHOST_DIR/*|tail -1`
		if [[ ! -z $FILE ]]; then
			printf "${RED}This VM has a separate apache vhost: $FILE. Please remove manually.${NC}\n"
		else
			printf "${RED}This VM might have a separate apache vhost. Please check & remove manually.${NC}\n"
		fi
        fi

	echo "Removing Apache proxy for VM $VM_NAME"
	sed -i "/$VM_IP/d" $VM_DIR/proxies.conf
	apachectl restart

	# remove from the vmlist
        LINE="$VM_NAME $VM_IP $VM_PORT $VM_TYPE"
        echo "Removing VM $VM_NAME from vmlist"
        sed -i "/$LINE/d" $VM_LIST

	# Done
	echo "VM $VM_NAME deleted"
else
	echo "Exiting .."
	exit
fi
