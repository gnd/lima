#!/bin/bash
#
# This creates a NAT masquearde for a VM on sta0 (static bridge)
#	or re-enables a dynamic VM to access Internet
#
# 	static VM's should not have a outbound connection by default.
#	It should be enabled only on a case by case basis and added
#	to the firewall
#
#	The inbound connections are served through a proxy server
#	like Nginx or Apache
#
#	gnd @ gnd.sk, 2017 - 2019
#
####################################################################

usage() {
        printf "\n"
        printf "Usage: \n"
        printf "$0 <iface IFACE |name NAME |ip IP> \n\n"
}

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings

### VM specified
case "$1" in
    'iface')
		IFACE=$2
		LINS=`cat $VM_LIST | awk {'print $1;'}|grep $IFACE|wc -l`
		if [[ $LINS -lt 1 ]]; then
			echo "No such interface $IFACE found"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			echo "More interfaces found, please be specific:"
			cat $VM_LIST | awk {'print $1;'}|grep $IFACE
			exit
		fi
		IFACE=`cat $VM_LIST | awk {'print $1";'}|grep $IFACE`
	;;
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
		IFACE=`cat $VM_LIST | awk {'print $1" "$2;'}|grep " $VM_NAME$"|awk {'print $1;'}`
	;;
	'ip')
		IP=$2
		LINS=`cat $VM_LIST | awk {'print $3;'}|grep $IP|wc -l`
		if [[ $LINS -lt 1 ]]; then
			echo "No such ip $IP found"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			echo "More ips found, please be specific:"
			cat $VM_LIST | awk {'print $3;'}|grep $IP
			exit
		fi
		IFACE=`cat $VM_LIST | awk {'print $1" "$3;'}|grep $IP|awk {'print $1;'}`
	;;
    'def')
        IFACE='sta-def'
    ;;
	*)
		usage
		exit
	;;
esac

### Enable traffic from given IFACE
TYPE=`echo $IFACE|sed 's/-.*//g'`

# Dynamic
if [[ "$TYPE" == "dyn" ]]; then
	LINS=`cat $VM_DIR/dynamic.banned|grep $IFACE|wc -l`
	if [[ $LINS -lt 1 ]]; then
		echo "Dynamic interface $IFACE is allowed by default"
		exit
	else
		echo "Enabling banned interface $IFACE"
		sed -i "/$IFACE/d" $VM_DIR/dynamic.banned
		$EBFW
		exit
	fi
fi

# Static
if [[ "$TYPE" == "sta" ]]; then
        LINS=`cat $VM_DIR/static.allowed|grep $IFACE|wc -l`
        if [[ $LINS -lt 1 ]]; then
		echo "Enabling static interface $IFACE"
		echo $IFACE >> $VM_DIR/static.allowed
		$EBFW
		exit
        else
	echo "Static interface $IFACE already allowed"
		exit
        fi
fi
