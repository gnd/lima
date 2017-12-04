#!/bin/bash
#
# This extends the VM's disk by the given size
#
#       It works by adding an additional qcow2 image file
#       as a nev disk to the machine and using it to 
#       extend the machine's LVM. The disks can be added
#	until the letter z (disk vdz) is reached ;)
#
#       gnd @ gnd.sk, 2017
#
#######################################################################

usage() {
        printf "\n"
        printf "Usage: \n"
        printf "$0 <name> <size>\n\n"
}

# Define globals
CONF_DIR='/data/pool/vms'
source $CONF_DIR/settings

# Check if parameter given
if [[ -z $1 ]]; then
	usage
	exit
fi
if [[ -z $2 ]]; then
        usage
        exit
fi

# Check for the machine
NAME=$1
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
echo "Machine $NAME found"
VM_IP=`cat $VM_LIST | awk {'print $2" "$3;'}|grep $NAME|awk {'print $2;'}`
VM_TYPE=`cat $VM_LIST | awk {'print $2" "$5;'}|grep $NAME|awk {'print $2;'}`
if [[ $VM_TYPE == "sta" ]]; then
	VM_TYPE="static"
fi
if [[ $VM_TYPE == "dyn" ]]; then
	VM_TYPE="dynamic"
fi
VM_XML=$VM_DIR"/"$VM_TYPE"/"$NAME"/vm.xml"
VM_DIR=$VM_DIR"/"$VM_TYPE"/"$NAME

# Get current drive letter
echo "Determining the current last drive letter"
CURR=`cat $VM_XML |grep virtio|grep target|head -1|sed 's/.*<target dev="vd//g'`
CURR=${CURR:0:1}
echo "Last drive letter is $CURR"

# Determine next letter
echo "Setting the next drive letter"
if [[ ! $CURR == "z" ]]; then 
	NXT=`for k in {a..z}; do echo -n $k; done | sed "s/.*$CURR//g"` # LOL !
	NXT=${NXT:0:1}
	echo "Next drive letter is $NXT"
else
	echo "Last letter reached. Please contact the admin"
	exit
fi

# Create the disk file
SIZE=$2
echo "Creating the new disk image: "$VM_DIR"/disk-"$NXT".img"
/usr/bin/qemu-img create -f qcow2 $VM_DIR"/disk-"$NXT".img" $SIZE"G"

# Add the disk to the VM XML spec. sth like:
RND=`openssl rand -hex 2`
TMPFILE="/tmp/dsk_"$RND
touch $TMPFILE
chmod 600 $TMPFILE
echo '<disk type="file" device="disk">' > $TMPFILE
echo '<driver name="qemu" type="qcow2"/>' >> $TMPFILE
echo '<source file="'$VM_DIR'/disk-'$NXT'.img"/>' >> $TMPFILE
echo '<target dev="vd'$NXT'" bus="virtio"/>' >> $TMPFILE
echo '</disk>' >> $TMPFILE

echo "Modifying the VM definition file"
# hardcoded for now ;/
sed -i '0,/<disk type="file" device="disk">/s/<disk type="file" device="disk">/<disk type="file" device="disk">\n      <driver name="qemu" type="qcow2"\/>\n      <source file="\/data\/pool\/vms\/'$VM_TYPE'\/'$NAME'\/disk-'$NXT'.img"\/>\n      <target dev="vd'$NXT'" bus="virtio"\/>\n    <\/disk>\n    <disk type="file" device="disk">/g' $VM_XML

# Adding the new disk to the machine
virsh attach-device $NAME $TMPFILE
rm $TMPFILE

# The fdisk batch part
RND=`openssl rand -hex 2`
TMPFILE="/tmp/fd_"$RND
echo "#!/bin/bash" > $TMPFILE
echo -n 'echo "n
p
1


w
"' >> $TMPFILE
echo '|fdisk /dev/vd'$NXT >> $TMPFILE

# Transfer the fdisk script to the machine
scp $TMPFILE $VM_IP:/root/nxtd
rm $TMPFILE

# Run the script on the machine
echo "Creating a new partition"
ssh $VM_IP "chmod 700 /root/nxtd"
ssh $VM_IP "/root/nxtd"
ssh $VM_IP "rm /root/nxtd"

# The LVM batch part
echo "Extending the LVM"
ssh $VM_IP "pvcreate /dev/vd"$NXT"1"
ssh $VM_IP "vgextend default-vg /dev/vd"$NXT"1"
ssh $VM_IP "pvscan"
ssh $VM_IP "lvextend /dev/default-vg/root /dev/vd"$NXT"1"
ssh $VM_IP "resize2fs /dev/default-vg/root"
ssh $VM_IP "echo \"/dev/vd"$NXT"1\" >> /root/scripts/disks"
