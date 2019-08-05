#!/bin/bash
#
# This deletes a NAT masquerade for a static VM
# 	or bans a dynamic VM from the Internet
#
#	See also enable-nat.sh
#
#	gnd @ gnd.sk, 2017 - 2019
#
####################################################################

usage() {
        printf "\n"
        printf "Usage: \n"
        printf "$0 <iface IFACE |name NAME |ip IP |def> \n\n"
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
		NAME=$2
		LINS=`cat $VM_LIST | awk {'print $2;'}|grep $NAME|wc -l`
		if [[ $LINS -lt 1 ]]; then
			echo "No such name $NAME found"
			exit
		fi
		if [[ $LINS -gt 1 ]]; then
			echo "More names found, please be specific:"
			cat $VM_LIST | awk {'print $2;'}|grep $NAME
			exit
		fi
		IFACE=`cat $VM_LIST | awk {'print $1" "$2;'}|grep $NAME|awk {'print $1;'}`
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

### Disable traffic from given IFACE
TYPE=`echo $IFACE|sed 's/-.*//g'`

# Dynamic
if [[ "$TYPE" == "dyn" ]]; then
	LINS=`cat $VM_DIR/dynamic.banned|grep $IFACE|wc -l`
	if [[ $LINS -lt 1 ]]; then
		echo "Banning dynamic interface $IFACE"
		echo $IFACE >> $VM_DIR/dynamic.banned
		$EBFW
		exit
	else
		echo "Dynamic interface $IFACE already banned"
		exit
	fi
fi

# Static
if [[ "$TYPE" == "sta" ]]; then
	LINS=`cat $VM_DIR/static.allowed|grep $IFACE|wc -l`
	if [[ $LINS -lt 1 ]]; then
		echo "Static interfaces are banned by default."
		exit
	else
		echo "Disabling static interface $IFACE"
		sed -i "/$IFACE/d" $VM_DIR/static.allowed
		$EBFW
		exit
	fi
fi
