#!/bin/bash
#
# This shows lists all VMs in vmlist and their info
#
#
#       gnd @ gnd.sk, 2017 - 2019
#
####################################################################

usage() {
	printf "\n"
	printf "Usage: \n"
	printf "$0 \n\n"
}

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings

# Print VM info
IFS=$'\n'
RND=`openssl rand -hex 2`
TMPFILE="/tmp/lvm_"$RND
touch $TMPFILE
chmod 600 $TMPFILE
echo -e "Name,Type,IP,Interface,VNC port,SSH port,URL,Internet,VM state,Location in /data/pool/vms,Last backup" > $TMPFILE
for LINE in `cat $VM_LIST|grep -v dummy`
do
	# Parse VM data
	VM_IFACE=`echo $LINE|awk {'print $1;'}`
	VM_NAME=`echo $LINE|awk {'print $2;'}`
	VM_IP=`echo $LINE|awk {'print $3;'}`
	VM_VNC=`echo $LINE|awk {'print $4;'}`
	VM_TYPE=`echo $LINE|awk {'print $5;'}`
	VM_PROXY=`echo $LINE|awk {'print $6;'}`
	if [[ $VM_TYPE == "sta" ]]; then
		VM_TYPE="static"
	fi
	if [[ $VM_TYPE == "dyn" ]]; then
	VM_TYPE="dynamic"
        fi

	# Get port forwards for the VM
	if [[ -f $FWD_LIST ]]; then
		FWD_LINS=`cat $FWD_LIST|grep " $VM_IP "|wc -l`
		if [[ $FWD_LINS == "1" ]]; then
			FWD_PORT=`cat $FWD_LIST|grep " $VM_IP "|awk {'print $1;'}`
			FWD_ON=`cat $FWD_LIST|grep " $VM_IP "|awk {'print $3;'}`
		fi
	fi

	# Get Apache proxies for the VM
	if [[ $VM_PROXY == "folder" ]]; then
		PRX_DIR=`cat $PRX_LIST|grep "$VM_IP:80"|grep ProxyPassReverse|awk {'print $2;'}|sed 's/\///g'`
	fi
	if [[ $VM_PROXY == "vhost" ]]; then
		FILE=`grep -l $VM_IP $APACHE_VHOST_DIR/*|tail -1`
		if [[ ! -z $FILE ]]; then
			PRX_VHOST=`cat $FILE|grep ServerName|awk {'print $2;'}`
		else
			PRX_VHOST="error"
		fi
	fi
	if [[ $VM_PROXY == "both" ]]; then
		PRX_DIR=`cat $PRX_LIST|grep "$VM_IP:80"|grep ProxyPassReverse|awk {'print $2;'}|sed 's/\///g'`
		FILE=`grep -l $VM_IP $APACHE_VHOST_DIR/*|tail -1`
		if [[ ! -z $FILE ]]; then
			PRX_VHOST=`cat $FILE|grep ServerName|awk {'print $2;'}`
		else
			PRX_VHOST="error"
		fi
	fi

	# Get FW rules for the VM
	if [[ "$VM_TYPE" == "static" ]]; then
		STA_LINS=`cat $VM_DIR"/static.allowed"|grep $VM_IFACE|wc -l`
	fi
	if [[ "$VM_TYPE" == "dynamic" ]]; then
		DYN_LINS=`cat $VM_DIR"/dynamic.banned"|grep $VM_IFACE|wc -l`
	fi

	# Check if VM is running
	VIR_LINS=`virsh list|grep " $VM_NAME "|wc  -l`

	# Check if VM is on disk
	VM_ONDISK=0
	if [[ -d $VM_DIR"/"$VM_TYPE"/"$VM_NAME ]]; then
		VM_ONDISK=1
	fi

	# Check for last backup
	if [[ "$VM_TYPE" == "static" ]]; then
		VM_BACKUP=`find $BUP_DIR -type f -name "static_[weekly|monthly]*"$VM_NAME"*.gpg" -exec ls -l --time-style="+%d.%m.%Y" {} \;|tail -1|awk {'print $6;'}`
	fi
	if [[ "$VM_TYPE" == "dynamic" ]]; then
		VM_BACKUP=`find $BUP_DIR -type f -name "dynamic_[daily|weekly|monthly]*"$VM_NAME"*.gpg" -exec ls -l --time-style="+%d.%m.%Y" {} \;|tail -1|awk {'print $6;'}`
	fi
	if [[ -z "$VM_BACKUP" ]]; then
		VM_BACKUP="!!! none !!!"
	fi

	# Now print allo
	VM_NAME_SHORT=$(echo $VM_NAME|cut -c -15)
	echo -n "$VM_NAME_SHORT"...",$VM_TYPE,$VM_IP,$VM_IFACE,$VM_VNC," >> $TMPFILE

	# Print data about SSH port forwards
	if [[ $FWD_LINS -lt "1" ]]; then
		echo -n "none," >> $TMPFILE
	fi
	if [[ $FWD_LINS == "1" ]]; then
		if [[ $FWD_ON == "ON" ]]; then
			echo -n "$FWD_PORT," >> $TMPFILE
		fi
		if [[ $FWD_ON == "OFF" ]]; then
			echo -n "off," >> $TMPFILE
		fi
	fi
	if [[ $FWD_LINS -gt "1" ]]; then
		echo -n "more," >> $TMPFILE
	fi

	# Print data about Apache proxies
	if [[ $VM_PROXY == "none" ]]; then
		echo -n "none," >> $TMPFILE
	fi
	if [[ $VM_PROXY == "folder" ]]; then
		echo -n $SERVER_URL/$PRX_DIR, >> $TMPFILE
	fi
	if [[ $VM_PROXY == "vhost" ]]; then
		PRX_VHOST_SHORT=$(echo $PRX_VHOST|cut -c 15)
		echo -n "http://$PRX_VHOST_SHORT..," >> $TMPFILE
	fi
	if [[ $VM_PROXY == "both" ]]; then
		echo -n "http://$PRX_VHOST & $SERVER_URL/$PRX_DIR," >> $TMPFILE
	fi

	# Print data about the FW rules for the VM
	if [[ "$VM_TYPE" == "static" ]]; then
		if [[ $STA_LINS -gt 0 ]]; then
			echo -n "allowed," >> $TMPFILE
		else
			echo -n "banned," >> $TMPFILE
		fi
	fi
	if [[ "$VM_TYPE" == "dynamic" ]]; then
		if [[ $DYN_LINS -gt 0 ]]; then
			echo -n "banned," >> $TMPFILE
		else
			echo -n "allowed," >> $TMPFILE
		fi
	fi

	# Print running state
	if [[ $VIR_LINS -gt 0 ]]; then
		echo -n "running," >> $TMPFILE
	else
		echo -n "off," >> $TMPFILE
	fi

	# Print disk state
	if [[ $VM_ONDISK -gt 0 ]]; then
		echo -n $VM_TYPE"/"$VM_NAME"/," >> $TMPFILE
	else
		echo -n "missing," >> $TMPFILE
	fi

	# Print last backup
	echo $VM_BACKUP >> $TMPFILE
done

# Print all to console
column -s"," -t $TMPFILE

# Remove the TEMPFILE
rm $TMPFILE
