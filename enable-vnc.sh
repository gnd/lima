#!/bin/bash
#
# This enables VNC connections from outside to the external IP and PORT
#
#       After 3 minutes the rule gets disabled. This results
#	in open connections remaining, but disables new
#	connections to be made
#
#       gnd @ gnd.sk, 2017
#
#######################################################################

usage() {
	printf "\n"
	printf "Usage: \n"
	printf "$0 <port PORT |name NAME |ip IP |iface IFACE> \n\n"
}

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

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
		PORT=`cat $VM_LIST | awk {'print $4;'}|grep $PORT|tail -1`
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
		PORT=`cat $VM_LIST | awk {'print $1" "$4;'}|grep $IFACE|awk {'print $2;'}`
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
		PORT=`cat $VM_LIST | awk {'print $2" "$4;'}|grep $NAME|awk {'print $2;'}`
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
		PORT=`cat $VM_LIST | awk {'print $3" "$4;'}|grep $IP|awk {'print $2;'}`
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

### Disable in 3m
RND=`openssl rand -hex 2`
CMD="/sbin/iptables -D INPUT -i $EXT_IF -p tcp -d $EXT_IP --dport $PORT -m state --state NEW -j ACCEPT"
echo $CMD > /tmp/job_$RND
chmod 700 /tmp/job_$RND
at now + 3 min < /tmp/job_$RND

### Notice
echo "VNC connection to port $PORT enabled !"
echo "This will auto-disable in 3 minutes"
echo "!! DONT FORGET TO LOG OFF BEFORE CLOSING CONNECTION !!"
echo ""
