#!/bin/bash
#
# This creates a new default template
#
#       gnd @ gnd.sk, 2017 - 2019
#
####################################################################

read -p "This is work in progress, proceed on your own risk [y/n]: " ANS
if [[ ! $ANS == "y" ]]; then
	exit
fi

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings
DEFAULT_SIZE=10						# Default size of the new disk image in GB
ISO_DIR=$VM_DIR/iso					# Location where the installer .iso images should reside

# Check if we have some installers first
read -p "Please type yes if $ISO_DIR exists and contains some .iso installers:"$'\n' ANSWER
if [ $ANSWER != "yes" ]; then
	echo "Please download some installers first. Exiting"
	exit
fi

# Set a name for the default VM
echo "Please name the new default template. This should ideally be a name describing the OS used, eg: debian64"
read -p "Please provide a name:"$'\n' NAME

# Check if default directory exists
if [[ ! -d $VM_DIR/default ]]; then
	echo "Creating directory for default VMs"
	mkdir $VM_DIR/default
fi

# Check if name unique
if [[ -d $VM_DIR/default/default_$NAME ]]; then
	echo "A template called $NAME already exists. Exiting"
	exit
else
	VM_NAME="default_"$NAME
fi

# Copy default to new dir
echo "Creating directory $VM_DIR/default/$VM_NAME"
mkdir $VM_DIR/default/$VM_NAME
echo "Copying files .."
cp -pr $VM_DIR/default.xml $VM_DIR/default/$VM_NAME/vm.xml

# Overwrite the disk file
/usr/bin/qemu-img create -f qcow2 $VM_DIR/default/$VM_NAME/disk-a.img $DEFAULT_SIZE"G"

# Choose iso to use
shopt -s extglob
echo "Please select the iso to use:"
isos=`ls $ISO_DIR`
opts=`echo $isos|sed 's/ /|/g'`
opts=`echo "+($opts)"`
select iso in $isos
do
        case $iso in
        $opts)
                echo "Choosing: $iso"
                break
                ;;
        *)
                echo "Invalid: $iso"
                ;;
        esac
done

### Set Default VM parameters
VM_ISO=$iso
VM_TYPE="default"
VM_SUBNET="10.10.10.255"
VM_INDEX="0"
VM_VNC="11230"
VM_MAC=`$SCRIPT_DIR"/macgen.py"`
VM_IFACE="sta-def"
VM_IP="10.10.10.10"
VM_GATEWAY="10.10.10.1"

### SED the parameters
sed -i "s~VM_DIR~$VM_DIR~g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s/VM_TYPE/$VM_TYPE/g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s/VM_NAME/$VM_NAME/g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s/VM_MAC/$VM_MAC/g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s/VM_IFACE/$VM_IFACE/g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s/VM_VNC/$VM_VNC/g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s/VM_EXTIF/$VM_EXTIF/g" $VM_DIR/default/$VM_NAME/vm.xml
sed -i "s~VM_ISO~$ISO_DIR/$VM_ISO~g" $VM_DIR/default/$VM_NAME/vm.xml

# Make sure the default instance is not running
CHECK=`virsh list --all|grep default`
if [[ ! -z $CHECK ]]; then
	echo "A default instance is running."
	echo "Run this script again after that default is off."
        echo "Reverting changes."
        rm -rf $VM_DIR/default/$VM_NAME
        exit
fi

# Start the default VM
virsh create $VM_DIR/default/$VM_NAME/vm.xml

# Connect & install
echo "Connect to the VM via VNC and finish the install"
