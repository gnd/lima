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
[ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finishe correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings
DEFAULT_SIZE=10						# Default size of the new disk image in GB
ISO_DIR=$VM_DIR/iso					# Location where the installer .iso images should reside

#1. place iso into /data/pool/iso
#2. meno novej default
#3. vytvorit folder a skopirovat staru default
#f. namountovat ziadane iso a nastartovat default
#5. instalacia systemu
#6. finalne nastavenie masiny:
#6.1 default IP
#6.2 ssh kluce
#6.3 monitoring a skripty
#6.f soft ktory tam uz musi byt



# Check if we have some installers first
read -p "Please type yes if there are some .iso installers in $ISO_DIR:"$'\n' ANSWER
if [ $ANSWER != "yes" ]; then
	echo "Please download some installers first. Exiting"
	exit
fi

# Set a name for the default VM
echo "Please name the new default template. This should ideally be a name describing the OS used, eg: debian64"
read -p "Please provide a name:"$'\n' NAME

# Check if name unique
if [[ -d $VM_DIR/default_$NAME ]]; then
	echo "A template called $NAME already exists. Exiting"
	exit
else
	VM_NAME="default_$NAME"
fi

# Copy default to new dir
echo "Creating directory $VM_DIR/$VM_NAME"
mkdir $VM_DIR/$VM_NAME
echo "Copying files .."
cp -pr $VM_DIR/default/vm.xml $VM_DIR/$VM_NAME/default.xml

# Overwrite the disk file
/usr/bin/qemu-img create -f qcow2 $VM_DIR/$VM_NAME/disk-a.img $DEFAULT_SIZE"G"

# Choose iso to use
echo ""
echo "Please provide the iso to use. These are the available iso files:"
for ISOFILE in `ls $ISO_DIR`
do
	printf "\t - $ISOFILE\n"
done
echo ""
read -p "Please enter iso name: " ISO

# Mount requested iso and start install
sed -i "s/iso\/.*iso/iso\/$ISO/g" $VM_DIR/$VM_NAME/default.xml
sed -i "s/default/$VM_NAME/g" $VM_DIR/$VM_NAME/default.xml

# Make sure the default instance is not running
CHECK=`virsh list --all|grep default`
if [[ ! -z $CHECK ]]; then
	echo "Default instance is running."
	echo "Run this script again after default is off."
        echo "Reverting changes."
        rm -rf $VM_DIR/$VM_NAME
        exit
fi

# Start the default VM
virsh create $VM_DIR/$VM_NAME/default.xml

# Connect & install
echo "Connect to the VM via VNC and finish the install"
