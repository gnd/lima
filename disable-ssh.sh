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

# Check if forwarding not already disabled
if [[ -f $VM_DIR/ssh-forwards ]]; then
    LINS=`cat $VM_DIR/ssh-forwards | grep $VM_IP | wc -l`
    if [[ $LINS -lt 1 ]]; then
        echo "Forward for IP $VM_IP not found."
        exit
    fi

    # Disable SSH forwarding
    echo "Disabling SSH forwarding to $VM_IP:22 .."
    sed -i '/$VM_IP/d' $VM_DIR/ssh-forwards

    # Reload the system firewall
    if [ ! -z $OSFW ]; then
    	$OSFW
    fi

    # Reload the lima firewall
    $IPFW
fi
