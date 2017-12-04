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
#	gnd @ gnd.sk, 2017
#
####################################################################

usage() {
        printf "\n"
        printf "Usage: \n"
        printf "$0 <iface IFACE |name NAME |ip IP> \n\n"
}

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

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
