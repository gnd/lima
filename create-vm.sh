#!/bin/bash
#
# This creates a new VM instance from the default template
#
#       gnd @ gnd.sk, 2017 - 2019
#
####################################################################

# we leave cmd args for later ..
# move all into functions and make a main()
# address reuse

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
WAIT="30"			# how long to wait before first connection
VM_TYPE="static"		# default directory holding the vm dir
VM_BRIDGE="sta0"		# default bridge is static
TYPE_OK=0
NAME_OK=0
USER="livmusr"
USER_USED=0
PORT_FWD_USED=0
VM_PROXY="none"
SSH_OPTS="-o StrictHostKeyChecking=no"					# needed since we use several default VMs
source $LIMA_ROOT/vms/settings

### If input arguments provided
if [[ ! -z "$1" ]]; then
	if [[ ! "$1" == "sta" ]] && [[ ! "$1" == "dyn" ]]; then
		echo "Please provide either 'sta' (as static) or 'dyn' (as dynamic)"
		echo "Usage $0 <dyn|sta> <name>"
		echo "Exiting."
		exit
	else
		VM_TYPE=$1
		TYPE_OK=1
	fi
fi
if [[ ! -z "$2" ]]; then
	# would be nice having some sanity check here
	VM_NAME=$2
	NAME_OK=1
fi

### waits until conection to new VM established
connect-ssh() {
	local ip=${1}
	local hostname=${2}
	con=0
	tries=0

	draw_tries() { for ((i=0; i<try; i=i+1)); do printf "▇"; done }
	clean_line() { printf "\r"; }

	while [[ "$con" == "0" ]]; do
		check=`ssh -q -o ConnectTimeout=1 -o StrictHostKeyChecking=no $ip hostname`
		sleep 1
		if [[ ! "$check" == "$hostname" ]]; then
			clean_line
            tries=$((tries+1))
			draw_tries=$((tries % 100))
            for (( try=1; try<=draw_tries; try=try+1 )); do
                printf "Waiting for VM: "$tries"s "; draw_tries
                clean_line
            done
		else
			con=1
			printf "\n\nVM up ! "
		fi
	done
}

### Verify initial conditions
if [[ ! `whoami` == "root" ]]; then
	echo "Not running as root. Exiting".
	exit
fi

## Make sure the default instance is not running
CHECK=`virsh list --all|grep default`
if [[ ! -z $CHECK ]]; then
	echo "Default instance is running."
	echo "Run this script again after default is off."
	exit
fi

### Ask for VM type if not provided
if [[ "$TYPE_OK" == "0" ]]; then
	read -p "Is this a static or dynamic VM? [sta/dyn] " VM_TYPE
	if [[ ! "$VM_TYPE" == "sta" ]] && [[ ! "$VM_TYPE" == "dyn" ]]; then
	        echo "Please provide either 'sta' (as static) or 'dyn' (as dynamic)"
	        echo "Exiting."
	        exit
	fi
fi
if [[ "$VM_TYPE" == "dyn" ]]; then
	VM_TYPE="dynamic"
	VM_TYPE_ABR="dyn"
	VM_BRIDGE="dyn0"
fi
if [[ "$VM_TYPE" == "sta" ]]; then
    VM_TYPE="static"
	VM_TYPE_ABR="sta"
    VM_BRIDGE="sta0"
fi

### Ask for VM name
if [[ "$NAME_OK" == "0" ]]; then
	read -p "Please provide instance name: " VM_NAME
fi

# Ask what default VM to use
shopt -s extglob
echo "Please select what default VM to use as template:"
vms=`ls $VM_DIR/default/`
opts=`echo $vms|sed 's/ /|/g'`
opts=`echo "+($opts)"`
select vm in $vms
do
	DEF_VM=$vm
	break
done
echo "Using $DEF_VM as default Vm."

### Check if VM already exists
CHECK=`virsh list --all|grep " $VM_NAME "`
if [[ ! -z $CHECK ]]; then
	read -p "VM $VM_NAME already running, do you wish to overwrite? [y/n]" ANS
	if [[ ! "$ANS" == "y" ]]; then
                echo "Exiting .."
                exit
	else
		WAIT="20"
		echo "Shutting down previous $VM_NAME"
		virsh destroy $VM_NAME
		mkdir -p $VM_DIR/$VM_TYPE/$VM_NAME
		echo "Copying files .."
		cp -pr $VM_DIR/default/$DEF_VM/default.xml $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
		cp -pr $VM_DIR/default/$DEF_VM/disk-a.img $VM_DIR/$VM_TYPE/$VM_NAME/disk-a.img
    fi
else
	if [[ -d $VM_DIR/$VM_TYPE/$VM_NAME ]]; then
		read -p "Directory $VM_DIR/$VM_TYPE/$VM_NAME exists, do you wish to overwrite? [y/n]: " ANS
		if [[ ! "$ANS" == "y" ]]; then
			echo "Exiting .."
			exit
		fi
		mkdir -p $VM_DIR/$VM_TYPE/$VM_NAME
    echo "Copying files .."
    cp -pr $VM_DIR/default/$DEF_VM/default.xml $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
    cp -pr $VM_DIR/default/$DEF_VM/disk-a.img $VM_DIR/$VM_TYPE/$VM_NAME/disk-a.img
	else
		echo "Creating directory $VM_DIR/$VM_TYPE/$VM_NAME"
		mkdir $VM_DIR/$VM_TYPE/$VM_NAME
		echo "Copying files .."
		cp -pr $VM_DIR/default/$DEF_VM/default.xml $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
		cp -pr $VM_DIR/default/$DEF_VM/disk-a.img $VM_DIR/$VM_TYPE/$VM_NAME/disk-a.img
	fi
fi

### Determine VM parameters
if [[ -f $VM_LIST ]]; then
	LINES=$(cat $VM_LIST | grep $VM_TYPE_ABR|wc -l)
	if [[ $LINES -gt 0 ]]; then
		VM_SUBNET=`cat $VM_LIST | grep $VM_TYPE_ABR | tail -1 | awk {'print $1;'} | sed "s/$VM_TYPE_ABR-//g" |  sed 's/-.*$//g'`
	else
		# This is the first VM of this type
		if [[ $VM_TYPE == "static" ]]; then
			VM_SUBNET='10'
		else
			VM_SUBNET='20'
		fi
	fi
	VM_INDEX=`$SCRIPT_DIR"/ipgen.py" $VM_TYPE $VM_LIST`
	VM_VNC=`$SCRIPT_DIR"/vncgen.py" $VM_LIST`
else
	# Obviously we are starting with a first VM, so lets use default parameters
	if [[ $VM_TYPE == "static" ]]; then
		VM_SUBNET='10'
	else
		VM_SUBNET='20'
	fi
	VM_INDEX='100'
	VM_VNC='11231'
fi

# If IP/INDEX overflowing from 100-200 range, increase SUBNET
# Increasing subnet might need adding another bridge ...
if [[ $VM_INDEX -gt "199" ]]; then
	VM_SUBNET=$((VM_SUBNET+1))
	VM_INDEX=100
fi

# Sanity check if our range not full (might never happen)
if [[ $VM_TYPE_ABR == "sta" ]] && [[ $VM_SUBNET -gt "19" ]]; then
	echo "Static address range full. Please contact the admin."
	exit
fi
if [[ $VM_TYPE_ABR == "dyn" ]] && [[ $VM_SUBNET -gt "29" ]]; then
        echo "Dynamic address range full. Please contact the admin."
        exit
fi

VM_MAC=`$SCRIPT_DIR"/macgen.py"`
VM_IFACE="$VM_TYPE_ABR-$VM_SUBNET-$VM_INDEX"
VM_IP="10.10.$VM_SUBNET.$VM_INDEX"
VM_GATEWAY="10.10.$VM_SUBNET.1"
VM_EXTIF="0.0.0.0"

### SED the parameters
sed -i "s~VM_DIR~$VM_DIR~g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
sed -i "s/VM_TYPE/$VM_TYPE/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
sed -i "s/VM_NAME/$VM_NAME/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
sed -i "s/VM_MAC/$VM_MAC/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
sed -i "s/VM_IFACE/$VM_IFACE/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
sed -i "s/VM_VNC/$VM_VNC/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
sed -i "s/VM_EXTIF/$VM_EXTIF/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
# sed black magick (remove cdrom from the VM)
sed -z 's/\(<disk type="file" device="cdrom">.*<\/disk>\)/<!-- \1 -->/g' -i $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml

### Try spin up the new instance
# This command may fail, see this for solution:
# https://superuser.com/questions/298426/kvm-image-failed-to-start-with-virsh-permission-denied
RES=`virsh create $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml 2>&1`
if [[ $RES =~ "Failed" ]]; then
	echo $RES
	echo "Reverting changes & destroying the new VM."
	virsh destroy $VM_NAME
	rm -rf $VM_DIR/$VM_TYPE/$VM_NAME
	sed -i "/.*$VM_NAME.*/d" $VM_LIST
	exit
else
	echo $RES
fi

### Wait for the VM to come up
$IPFW
connect-ssh $DEFAULT_IP default

### Add index into vmlist
echo "$VM_IFACE $VM_NAME $VM_IP $VM_VNC $VM_TYPE_ABR $VM_PROXY" >> $VM_LIST

### Change VM parameters
echo "Changing VM parameters .."
ssh $SSH_OPTS $DEFAULT_IP "sed -i 's/address.*/address $VM_IP\/24/g' /etc/network/interfaces"
ssh $SSH_OPTS $DEFAULT_IP "sed -i 's/gateway.*/gateway $VM_GATEWAY/g' /etc/network/interfaces"
ssh $SSH_OPTS $DEFAULT_IP "hostname '$VM_NAME'"
ssh $SSH_OPTS $DEFAULT_IP "echo '$VM_NAME' > /etc/hostname"
ssh $SSH_OPTS $DEFAULT_IP "sed -i 's/$DEFAULT_IP.*/$VM_IP    $VM_NAME.$SERVER_FQDN/g' /etc/hosts"
# one of these two is bound to fail, which is OK
ssh $SSH_OPTS $DEFAULT_IP "sed -i 's/default/$VM_NAME/g' /data/www/localhost/index.php"
ssh $SSH_OPTS $DEFAULT_IP "sed -i 's/default/$VM_NAME/g' /data/www/localhost/index.html"
ssh $SSH_OPTS $DEFAULT_IP "rm /root/.bash_history"

### Add a custom RSA / EC key
read -p "Do you wish to add a specific RSA / EC pubkey to the VM ? [y/n]: " ANS
if [[ "$ANS" == "y" ]]; then
        read -p $'Please paste the key below: \x0a' SSH_KEY
        if [[ ! -z $SSH_KEY ]]; then
                ssh $SSH_OPTS $DEFAULT_IP "echo $SSH_KEY >> /root/.ssh/authorized_keys"
                echo "Key added."
        fi
fi

### Change bridge if dynamic
if [[ $VM_TYPE_ABR == "dyn" ]]; then
	# dynamically change bridge via virsh
	RND=`openssl rand -hex 2`
	TMPFILE="/tmp/brg_"$RND
	touch $TMPFILE
        chmod 600 $TMPFILE
	cp $SCRIPT_DIR/networks/change-bridge.xml $TMPFILE
	sed -i "s/VM_BRIDGE/$VM_BRIDGE/g" $TMPFILE
	sed -i "s/VM_MAC/$VM_MAC/g" $TMPFILE
	sed -i "s/VM_IFACE/$VM_IFACE/g" $TMPFILE
	virsh update-device $VM_NAME $TMPFILE
	rm $TMPFILE

	# also change the bridge in the VM definition
	sed -i "s/sta0/$VM_BRIDGE/g" $VM_DIR/$VM_TYPE/$VM_NAME/vm.xml
fi

### Create a port forward
read -p "Enable SSH forwarding to the machine ? [y/n]: " ANS
if [[ "$ANS" == "y" ]]; then
	EXT_PORT=$VM_SUBNET$VM_INDEX
	iptables -t nat -A PREROUTING -p tcp -i $EXT_IF --dport $EXT_PORT -j DNAT --to-destination $VM_IP:22
	iptables -A FORWARD -p tcp -d $VM_IP --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -i $EXT_IF -p tcp -d $EXT_IP --dport $EXT_PORT -m state --state NEW -j ACCEPT
	echo "$VM_SUBNET$VM_INDEX $VM_IP ON" >> $VM_DIR/ssh-forwards
	echo "Enabling external port $EXT_PORT forwarding to $VM_IP:22 .."
	PORT_FWD_USED=1
fi

### Create a Apache proxy
read -p "Create a Apache proxy for the machine ? [y/n]: " ANS
if [[ "$ANS" == "y" ]]; then
	$SCRIPT_DIR/add-apache-vhost.sh new $VM_IP
fi

# Reload the system firewall
if [ ! -z $OSFW ]; then
	$OSFW
fi
# Reload the lima firewall
$IPFW

### Final reboot
virsh reboot $VM_NAME
connect-ssh $VM_IP $VM_NAME
echo ""
echo "---------------------------------------------------------------------"
echo "$VM_NAME is ready locally at $VM_IP."
echo "For VNC use ./enable-vnc.sh port $VM_VNC"
if [[ $PORT_FWD_USED == "1" ]]; then
		echo "For SSH from outside use 'ssh $EXT_IP -p $EXT_PORT -l root' (you have to have a RSA key added to the VM)"
fi
echo "---------------------------------------------------------------------"
