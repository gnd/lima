#!/bin/bash
#
# This creates a encrypted backup of all the VMs in vmlist
#
#       gnd @ gnd.sk, 2017 - 2019
#
#############################################################
#TODO: setup the backup key in settings
#TODO: check for backup key first
#TODO: create backup directories in install
#TODO: create backup key in install
#TODO: check for backp directories first

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

# Define globals
source $LIMA_ROOT/vms/settings
DATUM=`/bin/date +%D|sed 's/\//_/g'`

usage() {
	printf "\n"
	printf "Creates encrypted backups of VMs in vmlist\n"
	printf "Usage: \n"
	printf "$0 [daily | weekly | monthly]\n\n"
}

backup() {
	VM_NAME=$1
	VM_TYPE=$2
	BU_TYPE=$3

	echo "Creating $BU_TYPE backup of $VM_NAME.."
	TARNAME=$BUP_DIR"/"$VM_TYPE"_"$BU_TYPE"_"$VM_NAME"_"$DATUM".tar"
	nice tar -cf $TARNAME $VM_DIR"/"$VM_TYPE"/"$VM_NAME
	chmod 600 $TARNAME

	echo "Encrypting $BU_TYPE backup of $VM_NAME.."
	GPGNAME=$BUP_DIR"/"$VM_TYPE"_"$BU_TYPE"_"$VM_NAME"_"$DATUM".gpg"
	nice gpg -r "lima backup" --output $GPGNAME --encrypt $TARNAME
	chmod 600 $GPGNAME

	echo "Deleting plaintext for $VM_NAME.."
	rm $TARNAME
}

backup_conf() {
	echo "Backing up the configuration files.."
	TARNAME=$BUP_DIR"/conf_"$DATUM".tar"
	GPGNAME=$BUP_DIR"/conf_"$DATUM".gpg"
	nice tar -cf $TARNAME $VM_DIR/vmlist $VM_DIR/proxies.conf $VM_DIR/static.allowed $VM_DIR/dynamic.banned $VM_DIR/ssh-forwards
	nice gpg -r "lima backup" --output $GPGNAME --encrypt $TARNAME
	chmod 600 $GPGNAME
	rm $TARNAME
}

backup_default() {
	echo "Backing up the default VM.."
	TARNAME=$BUP_DIR"/default_"$DATUM".tar"
	GPGNAME=$BUP_DIR"/default_"$DATUM".gpg"
	nice tar -cf $TARNAME $VM_DIR/default
	nice gpg -r "lima backup" --output $GPGNAME --encrypt $TARNAME
	chmod 600 $GPGNAME
	rm $TARNAME
}

clean_conf() {
	# Delete all files named conf_*.gpg older then CONF_RETENTION days
	echo "Cleaning up configuration backups older than $CONF_RETENTION days.."
	find $BUP_DIR -type f -name "conf_*.gpg" -mtime +$CONF_RETENTION -exec rm {} \;
}

clean_default() {
	# Delete all files named default_*.gpg older then CONF_RETENTION days
	echo "Cleaning up default VM backups older than $CONF_RETENTION days.."
	find $BUP_DIR -type f -name "default_*.gpg" -mtime +$DEFAULT_RETENTION -exec rm {} \;
}

clean_deleted() {
	# Delete all drectories then DEL_RETENTION days
	echo "Cleaning up deleted VMs older than $DEL_RETENTION days.."
	find $BUP_DIR"/temp/" -type f -name "conf_*.tar" -mtime +$DEL_RETENTION -exec rm {} \;
	find $BUP_DIR"/temp/vms/dynamic/" -type d -mtime +$DEL_RETENTION -exec rm -rf {} \;
	find $BUP_DIR"/temp/vms/static/" -type d -mtime +$DEL_RETENTION -exec rm -rf {} \;
}

clean_dynamic() {
	# Delete all files named dynamic_daily_*.gpg older than DYN_DAILY_RETENTION days
	echo "Cleaning up dynamic VM daily backups older than $DYN_DAILY_RETENTION days.."
	find $BUP_DIR -type f -name "dynamic_daily_*.gpg" -mtime +$DYN_DAILY_RETENTION -exec rm {} \;

	# Delete all files named dynamic_weekly_*.gpg older than DYN_WEEKLY_RETENTION days
	echo "Cleaning up dynamic VM weekly backups older than $DYN_WEEKLY_RETENTION days.."
	find $BUP_DIR -type f -name "dynamic_weekly_*.gpg" -mtime +$DYN_WEEKLY_RETENTION -exec rm {} \;

	# Delete all files named dynamic_monthly_*.gpg older than DYN_MONTHLY_RETENTION days
	echo "Cleaning up dynamic VM monthly backups older than $DYN_MONTHLY_RETENTION days.."
	find $BUP_DIR -type f -name "dynamic_monthly_*.gpg" -mtime +$DYN_MONTHLY_RETENTION -exec rm {} \;
}

clean_static() {
	# Delete all files named static_weekly_*.gpg older than STA_WEEKLY_RETENTION days
	echo "Cleaning up static VM weekly backups older than $STA_WEEKLY_RETENTION days.."
	find $BUP_DIR -type f -name "static_weekly_*.gpg" -mtime +$STA_WEEKLY_RETENTION -exec rm {} \;

	# Delete all files named static_monthly_*.gpg older than STA_MONTHLY_RETENTION days
	echo "Cleaning up static VM monthly backups older than $STA_MONTHLY_RETENTION days.."
	find $BUP_DIR -type f -name "static_monthly_*.gpg" -mtime +$STA_MONTHLY_RETENTION -exec rm {} \;
}

# Run backups into dated files
case "$1" in
	'daily')
		BU_TYPE="daily"

		# First do some cleanup
		clean_conf
		clean_default
		clean_deleted
		clean_dynamic
		clean_static

		# Configuration backup
		backup_conf

		# Dynamic daily backup
		IFS=$'\n'
		for LINE in `cat $VM_LIST|grep -v dummy`
		do
			VM_NAME=`echo $LINE|awk {'print $2;'}`
			VM_TYPE=`echo $LINE|awk {'print $5;'}`
			if [[ $VM_TYPE == "dyn" ]]; then
				VM_TYPE="dynamic"
				backup $VM_NAME $VM_TYPE $BU_TYPE
			fi
		done
	;;
	'weekly')
		BU_TYPE="weekly"

		# First do some cleanup
		clean_default
		clean_dynamic
		clean_static

		# Default VM backup
		backup_default

		# Dynamic & static weekly backup
		IFS=$'\n'
		for LINE in `cat $VM_LIST|grep -v dummy`
		do
			VM_NAME=`echo $LINE|awk {'print $2;'}`
			VM_TYPE=`echo $LINE|awk {'print $5;'}`
			if [[ $VM_TYPE == "dyn" ]]; then
				VM_TYPE="dynamic"
			fi
			if [[ $VM_TYPE == "sta" ]]; then
				VM_TYPE="static"
			fi
			backup $VM_NAME $VM_TYPE $BU_TYPE
	done
	;;
	'monthly')
		BU_TYPE="monthly"

		# First do some cleanup
		clean_dynamic
		clean_static

		# Dynamic & static monthly backup
		IFS=$'\n'
		for LINE in `cat $VM_LIST|grep -v dummy`
		do
			VM_NAME=`echo $LINE|awk {'print $2;'}`
			VM_TYPE=`echo $LINE|awk {'print $5;'}`
			if [[ $VM_TYPE == "dyn" ]]; then
				VM_TYPE="dynamic"
			fi
			if [[ $VM_TYPE == "sta" ]]; then
				VM_TYPE="static"
			fi
			backup $VM_NAME $VM_TYPE $BU_TYPE
		done
	;;
	*)
		usage
	;;
esac
