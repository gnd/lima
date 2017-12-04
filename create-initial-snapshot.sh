#!/bin/bash
#
# This creates an initial snapshot of a installed VM
#
#       gnd @ gnd.sk, 2017
#
#############################################################

usage() {
	printf "\n"
	printf "Creates encrypted initial snapshot of a VM\n"
	printf "Usage: \n"
	printf "$0 <name>\n\n"
}

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings
DATUM=`/bin/date +%D|sed 's/\//_/g'`

# Check for inputs
if [[ -z $1 ]]; then
	usage
	exit
fi

# Identify machine
VM_NAME=$1
LINS=`cat $VM_LIST | awk {'print $2;'}|grep $VM_NAME|wc -l`
if [[ $LINS -lt 1 ]]; then
	echo "No such name $VM_NAME found"
	exit
fi
if [[ $LINS -gt 1 ]]; then
	echo "More names found, please be specific:"
	cat $VM_LIST | awk {'print $2;'}|grep $VM_NAME
	exit
fi

# Identify VM type
VM_TYPE=`cat $VM_LIST | awk {'print $2" "$5;'}|grep $VM_NAME|awk {'print $2;'}`
if [[ $VM_TYPE == "sta" ]]; then
	VM_TYPE="static"
fi
if [[ $VM_TYPE == "dyn" ]]; then
	VM_TYPE="dynamic"
fi

# Create initial snapshot
echo "Creating initial snapshot of the $VM_NAME VM.."
TARNAME=$BUP_DIR"/snapshots/"$VM_NAME"_initial_"$DATUM".tar"
GPGNAME=$BUP_DIR"/snapshots/"$VM_NAME"_initial_"$DATUM".gpg"
nice tar -cf $TARNAME $VM_DIR"/"$VM_TYPE"/"$VM_NAME
nice gpg -r "lima backup" --output $GPGNAME --encrypt $TARNAME
chmod 600 $GPGNAME
rm $TARNAME

echo "Initial snapshot done"
