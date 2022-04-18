#!/bin/bash
#
# This enables SSH forwarding to the Vm on the firewall
#
#	gnd @ gnd.sk, 2017 - 2022
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
        LINS=`cat $VM_LIST | awk {'print $1;'} | grep $IFACE | wc -l`
        if [[ $LINS -lt 1 ]]; then
            echo "No such interface $IFACE found"
            exit
        fi
        if [[ $LINS -gt 1 ]]; then
            echo "More interfaces found, please be specific:"
            cat $VM_LIST | awk {'print $1;'} | grep $IFACE
            exit
        fi

        VM_IP=`cat $VM_LIST | awk {'print $1" "$3;'} | grep "$IFACE " | awk {'print $2;'}`
    ;;
    'name')
        VM_NAME=$2
        LINS=`cat $VM_LIST | awk {'print $2;'} | grep "^$VM_NAME$" | wc -l`
        if [[ $LINS -lt 1 ]]; then
            printf "\n$0: No such name $VM_NAME found\n\n"
            exit
        fi
        if [[ $LINS -gt 1 ]]; then
            printf "\n$0: More names like '$VM_NAME' found, please be specific:\n"
            cat $VM_LIST | awk {'print $2;'} | grep "^$VM_NAME$"
            printf "\n"
            exit
        fi

        VM_IP=`cat $VM_LIST | awk {'print $2" "$3;'} | grep "$VM_NAME$ " | awk {'print $2;'}`
    ;;
    'ip')
        IP=$2
        LINS=`cat $VM_LIST | awk {'print $3;'} | grep $IP | wc -l`
        if [[ $LINS -lt 1 ]]; then
            echo "No such ip $IP found"
            exit
        fi
        if [[ $LINS -gt 1 ]]; then
            echo "More ips found, please be specific:"
            cat $VM_LIST | awk {'print $3;'} | grep $IP
            exit
        fi

        # we already have the IP
        VM_IP=$IP
    ;;
    *)
        usage
        exit
    ;;
esac

# Determine external port
VM_SUBNET=`echo $VM_IP | cut -d '.' -f 3`
VM_INDEX=`echo $VM_IP | cut -d '.' -f 4`
EXT_PORT=$VM_SUBNET$VM_INDEX

# Check if forwarding not already enabled
if [[ -f $VM_DIR/ssh-forwards ]]; then
    LINS=`cat $VM_DIR/ssh-forwards | grep $VM_IP | wc -l`
    if [[ $LINS -gt 0 ]]; then
        echo "Forward for IP $VM_IP already existing."
        exit
    fi
fi

# Enable SSH forwarding
iptables -t nat -A PREROUTING -p tcp -i $EXT_IF --dport $EXT_PORT -j DNAT --to-destination $VM_IP:22
iptables -A FORWARD -p tcp -d $VM_IP --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i $EXT_IF -p tcp -d $EXT_IP --dport $EXT_PORT -m state --state NEW -j ACCEPT
echo "$EXT_PORT $VM_IP ON" >> $VM_DIR/ssh-forwards
echo "Enabling external port $EXT_PORT forwarding to $VM_IP:22 .."
