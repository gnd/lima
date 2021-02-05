#!/bin/bash
#
# This creates a apache vhost for a given VM
#
#       gnd @ gnd.sk, 2017 - 2019
#
####################################################################

usage() {
	printf "\n"
	printf "Creates a Apache vhost for a given VM\n"
	printf "Usage: \n"
	printf "$0 new <VM_IP> \n\n"
}

# Check if LIMA_ROOT set
if [ -z $LIMA_ROOT ]; then
	echo "Cant find LIMA. Please check if the install finished correctly."
	echo "Exiting. Reason: LIMA_ROOT not set."
	exit
fi

#  SOME INPUT VAR
if [[ -z $2 ]]; then
	usage
	exit
else
	VM_IP=$2
fi

# Define globals
source $LIMA_ROOT/vms/settings
DATUM=`date +%D|sed 's/\//_/g'`
FOLDER=0
SUBDOMAIN="0"
ALIASES="0"
ALIAS=""

# Verify the IP
LINS=`cat $VM_LIST | awk {'print $3;'}|grep $VM_IP|wc -l`
if [[ $LINS -lt 1 ]]; then
	echo "No such ip $IP found"
	exit
fi
if [[ $LINS -gt 1 ]]; then
	echo "More ips found, please be specific:"
	cat $VM_LIST | awk {'print $3;'}|grep $IP
	exit
fi

# Check if already has a proxy
VM_PROXY=`cat $VM_LIST | awk {'print $3" "$6;'}|grep $VM_IP|awk {'print $2;'}`
if [[ $VM_PROXY == "both" ]]; then
	echo "This machine already has a vhost and a folder proxy. Exiting."
	exit
fi
if [[ $VM_PROXY == "folder" ]] || [[ $VM_PROXY == "vhost" ]]; then
	read -p "This machine already has a proxy (type: $VM_PROXY). Do you wish to proceed ? [y/n]: " ANS
	if [[ ! $ANS == "y" ]]; then
		echo "No proxy created. Exiting."
		exit
	fi
fi

# Is this a domain ?
read -p "Should this machine be accessible via a separate [d]omain or a [f]older on Arthost ? [d/f]: " ANS
if [[ "$ANS" == "d" ]]; then

	if [[ $VM_PROXY == "vhost" ]]; then
		echo "This machine already has a vhost, please update it manually. Exiting."
		exit
	fi

	FOLDER=2

	# Read domain name
	echo "Input domain name (eg.: [SUB.]DOMAIN.TLD):"
	read DOMAIN

	# Aliases
	echo "Do you wish any other aliases ? [y/n]"
	read IN
	case $IN in
		[Yy]* )
			echo "Provide space-separated aliases for $DOMAIN. wwww.$DOMAIN is the default alias"
			read ALIAS
			ALIASES="1"
		;;
		[Nn]* )
			echo "Ok"
		;;
		*)
		       	echo "Please answer y/n. Exiting"
	       	;;
	esac

	# Create domain in apache conf
	# // TODO remplace with mktemp everywhere
	RND=`openssl rand -hex 2`
	TMPFILE="/tmp/dmn_"$RND
	touch $TMPFILE
        chmod 600 $TMPFILE
	echo "### $DOMAIN" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "<VirtualHost $EXT_IP:80>" > $TMPFILE
	echo "" >> $TMPFILE
	echo "	ServerName $DOMAIN" >> $TMPFILE
	if [[ "$SUBDOMAIN" == "0" ]]; then
		if [[ "$ALIASES" == "1" ]]; then
			echo "	ServerAlias www.$DOMAIN $ALIAS" >> $TMPFILE
		else
			echo "	ServerAlias www.$DOMAIN" >> $TMPFILE
		fi
	fi
	echo "	ErrorLog "$APACHE_ERRORLOG >> $TMPFILE
	echo "" >> $TMPFILE
	echo -e "\tProxyRequests Off" >> $TMPFILE
	echo -e "\tProxyPreserveHost on" >> $TMPFILE
	echo -e "\tProxyPass / http://$VM_IP:80/" >> $TMPFILE
	echo -e "\tProxyPassReverse / http://$VM_IP:80/" >> $TMPFILE
	echo "" >> $TMPFILE
	echo "</VirtualHost>" >> $TMPFILE

	# Check config
	clear
	cat $TMPFILE
	echo ""
	echo "Is this config ok? [y/n]:"

	# Confirm & submit config
	read ANSWER
	if [[ "$ANSWER"  == "y" ]]; then
		# deal with existing config
		if [ -f $APACHE_VHOST_DIR"/"$DOMAIN".conf" ]; then
			echo "Domain exists already:"
			ls -la $APACHE_VHOST_DIR"/"$DOMAIN".conf"
			echo "Will not overwrite. Sorry. Exiting.."
			exit 1
		fi

		# Commit new domain to apache conf
		cat $TMPFILE >> $APACHE_VHOST_DIR"/"$DOMAIN".conf"
		rm $TMPFILE
		a2ensite $DOMAIN
		echo "Restarting apache"
		/usr/sbin/apache2ctl restart
	else
		echo "Create config manually"
	fi

	echo "Domain creation done"
	echo "If u wish to update $DOMAIN apache config do: vi "$APACHE_VHOST_DIR"/"$DOMAIN".conf"
fi

### This is a folder
if [[ "$ANS" == "f" ]]; then

	if [[ "$VM_PROXY" == "folder" ]]; then
		echo "This machine already has a proxy folder, please update it manually. Exiting."
		exit
	fi

	FOLDER="1"
	read -p "What should the folder be named ? : " FOLDER_NAME

	# Check if exists
	LINS=`cat $PRX_LIST|grep "ProxyPass /$FOLDER_NAME "`
	if [[ ! -z $LINS ]]; then
		echo "Folder $FOLDER_NAME is already set-up as a proxy. Please use a different name. Exiting."
		exit
	fi

	echo "" >> $PRX_LIST
	echo "### Proxy for $VM_IP" >> $PRX_LIST
	echo "ProxyPass /$FOLDER_NAME http://$VM_IP:80/" >> $PRX_LIST
	echo "ProxyPassReverse /$FOLDER_NAME http://$VM_IP:80/" >> $PRX_LIST

	echo "Restarting apache"
	apachectl restart

	echo "Created a proxy for "$VM_IP" at "$SERVER_URL"/"$FOLDER_NAME
fi

### Add info into vmlist
if [[ ! $FOLDER == "0" ]]; then
	VM_PROXY=`cat $VM_LIST | awk {'print $3" "$6;'}|grep $VM_IP|awk {'print $2;'}`

	# If new proxy added
	if [[ $VM_PROXY == "none" ]]; then
		if [[ $FOLDER == "1" ]]; then
			sed -i "s/\(.* $VM_IP .*\)none/\1folder/g" $VM_LIST
		fi
		if [[ $FOLDER == "2" ]]; then
			sed -i "s/\(.* $VM_IP .*\)none/\1vhost/g" $VM_LIST
		fi
	fi

	# Otherwise this machine already has a proxy
	if [[ $VM_PROXY == "folder" ]]; then
		if [[ $FOLDER == "2" ]]; then
			sed -i "s/\(.* $VM_IP .*\)folder/\1both/g" $VM_LIST
		fi
	fi
	if [[ $VM_PROXY == "vhost" ]]; then
		if [[ $FOLDER == "1" ]]; then
			sed -i "s/\(.* $VM_IP .*\)vhost/\1both/g" $VM_LIST
		fi
	fi
fi
