#!/bin/bash
#
# This enables VNC connections from outside to the external IP and PORT
#
#   After 3 minutes the rule gets disabled. This results
#	in open connections remaining, but disables new
#	connections to be made
#
#       gnd @ gnd.sk, 2017 - 2019
#
#######################################################################

usage() {
	printf "\n"
	printf "Usage: \n"
	printf "$0 <port PORT |name NAME |ip IP |iface IFACE | def> \n\n"
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
	'port')
		PORT=$2
		LINS=`cat $VM_LIST | awk {'print $4;'}|grep $PORT|wc -l`
		if [[ $LINS -lt 1 ]]; then
			echo "No such port $PORT found"
			exit
		fi
		if [[ $LINS -gt 1 ]] && [[ ! $PORT == "5900" ]]; then
			echo "More ports found, please be specific:"
			cat $VM_LIST | awk {'print $4;'}|grep $PORT
			exit
		fi
		VM_IP=`cat $VM_LIST | awk {'print $4" "$3;'}|grep $PORT|awk {'print $2;'}`
		PORT=$2
	;;
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
		VM_IP=`cat $VM_LIST | awk {'print $1" "$3;'}|grep $IFACE|awk {'print $2;'}`
		PORT=`cat $VM_LIST | awk {'print $1" "$4;'}|grep $IFACE|awk {'print $2;'}`
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
		VM_IP=`cat $VM_LIST | awk {'print $2" "$3;'}|grep "^$VM_NAME "|awk {'print $2;'}`
		PORT=`cat $VM_LIST | awk {'print $2" "$4;'}|grep "^$VM_NAME "|awk {'print $2;'}`
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
		VM_IP=$IP
		PORT=`cat $VM_LIST | awk {'print $3" "$4;'}|grep $IP|awk {'print $2;'}`
	;;
	'def')
		PORT=11230
	;;
	*)
		usage
		exit
	;;
esac

### Check if enabled already
LINS=`/sbin/iptables -nL|grep ACCEPT|grep $EXT_IP|grep $PORT|wc -l`
if [[ $LINS -gt 0 ]]; then
	echo "Already enabled."
	exit
fi

### Enable VNC connections
/sbin/iptables -A INPUT -i $EXT_IF -p tcp -d $EXT_IP --dport $PORT -m state --state NEW -j ACCEPT

### Disable in 1m
RND=`openssl rand -hex 2`
# TODO deleting from post/prerouting needs to be done differently
CMD="/sbin/iptables -D INPUT -i $EXT_IF -p tcp -d $EXT_IP --dport $PORT -m state --state NEW -j ACCEPT"
echo $CMD > /tmp/job_$RND
chmod 700 /tmp/job_$RND
at now + 1 min < /tmp/job_$RND

### Notice
echo "VNC connection to port $EXT_PORT enabled !"
echo "This will auto-disable in 1 minutes"
echo "!! DONT FORGET TO LOG OFF BEFORE CLOSING CONNECTION !!"
echo ""
