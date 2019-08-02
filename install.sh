#!/bin/bash
#
# This installs the LIMA system.
#
#
#       gnd @ gnd.sk, 2019
#
#######################################################################

# Some globals
WO=0					# Should we overwrite the directories when installing ?


# Check if this is run as root
ROOT=`whoami`
if [[ $ROOT != "root" ]]; then
    echo "Please run as root."
    exit
fi

# Ask for the ROOTDIR
read -p "Please provide the root directory for LIMA:"$'\n' ROOTDIR
if [ ! -d $ROOTDIR ]; then
	echo "Creating $ROOTDIR"
	mkdir $ROOTDIR
else
	read -p "The directory $ROOTDIR exists. Type 'yes' if you wish to continue:"$'\n' ANSWER
	if [ $ANSWER == "yes" ]; then
		echo "Will overwrite all data"
		$WO=1
	else
		echo "Please choose a directory that does not exist. Exiting."
		exit
	fi
fi

# Install prerequisities
apt-get install python git libvirt-clients libvirt-daemon libvirt-daemon-system net-tools

# Create directory structure
echo "Creating directory structure:"
if [ ! -d $ROOTDIR/pool ] || [ $WO ]; then
    echo "Creating $ROOTDIR/pool"
    mkdir -p $ROOTDIR/pool
else
    echo "Directory $ROOTDIR/pool exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/pool/vms ] || [ $WO ]; then
    echo "Creating $ROOTDIR/pool/vms"
    mkdir -p $ROOTDIR/pool/vms
else
    echo "Directory $ROOTDIR/pool/vms exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/pool/vms/default ] || [ $WO ]; then
    echo "Creating $ROOTDIR/pool/vms/default"
    mkdir -p $ROOTDIR/pool/vms/default
else
    echo "Directory $ROOTDIR/pool/vms/default exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/pool/vms/dynamic ] || [ $WO ]; then
    echo "Creating $ROOTDIR/pool/vms/dynamic"
    mkdir -p $ROOTDIR/pool/vms/dynamic
else
    echo "Directory $ROOTDIR/pool/vms/dynamic exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/pool/vms/static ] || [ $WO ]; then
    echo "Creating $ROOTDIR/pool/vms/static"
    mkdir -p $ROOTDIR/pool/vms/static
else
    echo "Directory $ROOTDIR/pool/vms/static exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/pool/networks ] || [ $WO ]; then
    echo "Creating $ROOTDIR/pool/networks"
    mkdir -p $ROOTDIR/pool/networks
else
    echo "Directory $ROOTDIR/pool/networks exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/backup ] || [ $WO ]; then
    echo "Creating $ROOTDIR/backup"
    mkdir -p $ROOTDIR/backup
else
    echo "Directory $ROOTDIR/backup exists. Exiting."
    exit
fi
if [ ! -d $ROOTDIR/backup/temp ] || [ $WO ]; then
    echo "Creating $ROOTDIR/backup/temp"
    mkdir -p $ROOTDIR/backup/temp
else
    echo "Directory $ROOTDIR/backup/temp exists. Exiting."
    exit
fi

# Checkout latest scripts from github
echo "Checking out LIMA from Github (https://github.com/gnd/lima)"
cd $ROOTDIR/pool
git init
git remote add origin https://github.com/gnd/lima.git
git fetch
git checkout origin/master -ft

# Add aliases to /root/.bashrc
echo "Adding aliases to .bashrc"
echo "
### Setting LIMA_ROOT
export LIMA_ROOT=$ROOTDIR

### Lima aliases
alias add-apache-vhost='$ROOTDIR/pool/add-apache-vhost.sh'
alias create-vm='$ROOTDIR/pool/create-vm.sh'
alias disable-nat='$ROOTDIR/pool/disable-nat.sh'
alias enable-nat='$ROOTDIR/pool/enable-nat.sh'
alias enable-vnc='$ROOTDIR/pool/enable-vnc.sh'
alias delete-vm='$ROOTDIR/pool/delete-vm.sh'
alias lima='$ROOTDIR/pool/show-commands.sh'
alias list-vm='$ROOTDIR/pool/list-vms.sh'
alias extend-disk='$ROOTDIR/pool/extend-disk.sh'
alias create-initial-snapshot='$ROOTDIR/pool/create-initial-snapshot.sh'
alias make-backup='$ROOTDIR/pool/make-backup.sh'
alias make-default='$ROOTDIR/pool/make-default.sh'
alias start-default='$ROOTDIR/pool/start-default.sh'
alias stop-default='$ROOTDIR/pool/stop-default.sh'
" >> /root/.bashrc

# Run the aliases as well
source /root/.bashrc

# Prepare for networking
virsh net-destroy default
virsh net-undefine default

# Create the dynamic network
echo "Creating lima-dynamic network"
echo "
<network>
  <name>lima-dynamic</name>
  <bridge name='dyn0' stp='on' delay='0'/>
  <forward mode='open'/>
  <ip address='10.10.20.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.20.11' end='10.10.20.99'/>
    </dhcp>
  </ip>
</network>
" > $ROOTDIR/pool/networks/dyn0.xml

# Create the static network
echo "Creating lima-static network"
echo "
<network>
  <name>lima-static</name>
  <bridge name='sta0' stp='on' delay='0'/>
  <forward mode='open'/>
  <ip address='10.10.10.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.10.11' end='10.10.10.99'/>
    </dhcp>
  </ip>
</network>
" > $ROOTDIR/pool/networks/sta0.xml

# Enable the network
echo "Enabling lima-dynamic"
virsh net-define $ROOTDIR/pool/networks/dyn0.xml
virsh net-autostart lima-dynamic
virsh net-start lima-dynamic
echo "Enabling lima-static"
virsh net-define $ROOTDIR/pool/networks/sta0.xml
virsh net-autostart lima-static
virsh net-start lima-static

# Extending the firewall
shopt -s extglob
echo "Please select the main external interface:"
ifs=`ip -br link|grep -v 'lo'|awk {'print $1;'}`
opts=`echo $ifs|sed 's/ /|/g'`
opts=`echo "+($opts)"`
select if in $ifs
do
        case $if in
        $opts)
                echo "Choosing: $if"
                break
                ;;
        *)
                echo "Invalid: $if"
                ;;
        esac
done
echo "Extending the firewall"
ext_ip=`ifconfig|grep $if -A 2|grep "inet "|awk {'print $2;'}`
echo "
#!/bin/sh
# Define variables
IPT=/sbin/iptables
EXT_IF=$if
VM_STA_IF=\"sta0\"
VM_DYN_IF=\"dyn0\"
EXT_IP=$ext_ip

# Create NAT - this is for all dyn0 VM's and some sta0 VM's
\$IPT -t nat -A POSTROUTING -o \$EXT_IF -j MASQUERADE

# Allow packets of established connections and those
#   which are related to established connections
\$IPT -A INPUT -i \$VM_STA_IF -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
\$IPT -A INPUT -i \$VM_DYN_IF -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow established and related for NAT connections
\$IPT -A FORWARD -i \$EXT_IF -o \$VM_STA_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
\$IPT -A FORWARD -i \$EXT_IF -o \$VM_DYN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT

##### ---- static bridge rules ---- #####
# Allow ICMP ECHO
\$IPT -A INPUT -i \$VM_STA_IF -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Allow DHCP requests
\$IPT -A INPUT -i \$VM_STA_IF -p udp -m udp --dport 67 -j ACCEPT
\$IPT -A INPUT -i \$VM_STA_IF -p tcp -m tcp --dport 67 -j ACCEPT

# Allow NAT - this is filtered with EBTABLES - check /etc/init.d/eb-firewall
\$IPT -A FORWARD -i \$VM_STA_IF -o \$EXT_IF -j ACCEPT

##### ---- dynamic bridge rules ---- #####
# Allow ICMP ECHO
\$IPT -A INPUT -i \$VM_DYN_IF -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Allow DHCP requests
\$IPT -A INPUT -i \$VM_DYN_IF -p udp -m udp --dport 67 -j ACCEPT
\$IPT -A INPUT -i \$VM_DYN_IF -p tcp -m tcp --dport 67 -j ACCEPT

# Allow NAT - this is filtered with EBTABLES - check /etc/init.d/eb-firewall
\$IPT -A FORWARD -i \$VM_DYN_IF -o \$EXT_IF -j ACCEPT

# Allow incoming ssh to VM's from internet
if [ -f /data/pool/vms/forwards ]; then
        IFS=$'\n'
        for LINE in \$(cat $ROOTDIR/pool/vms/forwards | grep ON); do
                EXT_PORT=\$(echo \$LINE|awk {'print \$1;'})
                VM_IP=\$(echo LINE|awk {'print \$2;'})

                echo \"Adding forward from \$EXT_IP:\$EXT_PORT to \$VM_IP:22\"
                \$IPT -t nat -A PREROUTING -p tcp -i \$EXT_IF --dport \$EXT_PORT -j DNAT --to-destination \$VM_IP:22
                \$IPT -A FORWARD -p tcp -d \$VM_IP --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
                \$IPT -A INPUT -i \$EXT_IF -p tcp -d \$EXT_IP --dport \$EXT_PORT -m state --state NEW -j ACCEPT
        done
fi
" > /etc/init.d/lima-firewall
chmod 700 /etc/init.d/lima-firewall
echo "Adding rules into iptables"
/etc/init.d/lima-firewall

# Create the EB firewall
echo "Creating the ebtables firewall"
echo "
#!/bin/bash

# Define variables
EBT=/sbin/ebtables
STA_IF=\"sta0\"
DYN_IF=\"dyn0\"
STA_WHITELIST=\"$ROOTDIR/pool/vms/static.allowed\"
DYN_BLACKLIST=\"$ROOTDIR/pool/vms/dynamic.banned\"

# Set default policy to DROP
\$EBT -P INPUT DROP
\$EBT -P OUTPUT DROP
\$EBT -P FORWARD DROP

# Flush old rules
\$EBT -F
\$EBT -Z
\$EBT -X

##### ---- static bridge rules ---- #####

# accept the ARP protocol
\$EBT -A INPUT -p 0x806 -j ACCEPT
\$EBT -A OUTPUT -p 0x806 -j ACCEPT

# accept internal SSH traffic to the VMs (note no interface specified)
\$EBT -A INPUT -p IPV4 --ip-proto TCP --ip-sport 22 -j ACCEPT
\$EBT -A OUTPUT -p IPV4 --ip-proto TCP --ip-dport 22 -j ACCEPT

# accept internal WEB traffic to the VMs
\$EBT -A INPUT -p IPV4 --ip-proto TCP --ip-sport 80 -j ACCEPT
\$EBT -A OUTPUT -p IPV4 --ip-proto TCP --ip-dport 80 -j ACCEPT

# ALLOW ALL TRAFFIC FROM LISTED STATIC IFs
if [ -f \$STA_WHITELIST ]; then
        for IF in \$(cat \$STA_WHITELIST); do \$EBT -A INPUT -i \$IF -j ACCEPT; \$EBT -A OUTPUT -o \$IF -j ACCEPT; done
fi

##### ---- dynamic bridge rules ---- #####

# DISALLOW TRAFFIC FROM BLACKLISTED DYNAMIC IFs
if [ -f \$DYN_BLACKLIST ]; then
        for IF in \$(cat \$DYN_BLACKLIST); do \$EBT -A INPUT -i \$IF -j DROP; \$EBT -A OUTPUT -o \$IF -j DROP; done
fi

# ALLOW TRAFFIC FROM ALL OTHER DYNAMIC IFs
\$EBT -A INPUT -i dyn+ -j ACCEPT
\$EBT -A OUTPUT -o dyn+ -j ACCEPT
" > /etc/init.d/lima-eb-firewall
chmod 700 /etc/init.d/lima-eb-firewall
echo "Adding rules into ebtables"
/etc/init.d/lima-eb-firewall

# Add firewall into startup script
echo "Adding firewalls into /etc/rc.local:"
echo "Do you wish to do this manually ?"
select opt in yes no
do
	case $opt in
		'yes')
			echo "Please add:
					- /etc/init.d/lima-eb-firewall
					- /etc/init.d/lima-firewall
				  To your preferred startu script."
			break
			;;
		'no')
			echo "/etc/init.d/lima-firewall &" >> /etc/rc.local
			echo "/etc/init.d/lima-eb-firewall &" >> /etc/rc.local
			echo "Done adding firewall scripts into /etc/rc.local"
			break
		;;
		*)
			echo "Please select 1 or 2"
		;;
	esac
done

# Create a config file
read -p "Please provide the server domain (eg. example.com):"$'\n' fqdn
echo "Creating config file"
echo "
### Directory settings
VM_DIR=$ROOTDIR'/pool/vms'							# where the vms reside
CONF_DIR=\$VM_DIR									# where the vmlist & conf files reside
SCRIPT_DIR=$ROOTDIR'/pool'							# where the scripts reside
VM_LIST=\$CONF_DIR'/vmlist'							# vmlist vm text database
FWD_LIST=\$CONF_DIR'/forwards'						# port forvards text database
PRX_LIST=\$CONF_DIR'/proxies.conf'					# apache proxy folders text database

### Netvork settings
EXT_IF='$if'										# this is the internet-facing interface
EXT_IP='$ext_ip'									# IP of the external interface
SERVER_FQDN='$fqdn'									# server domain name
SERVER_URL='$fqdn'									# server URL
IPFW='/etc/init.d/lima-firewall'					# location of the iptables firevall script
EBFW='/etc/init.d/lima-eb-firewall'					# location of the ebtables firevall script
APACHE_VHOST_DIR='/etc/apache2/sites-available/'	# location of apache2 vhost definitions (sites-available)
APACHE_ERRORLOG='/var/log/apache2/error_log'		# apache2 error log
DEFAULT_IP='10.10.10.10'							# IP of the default VM

### Backup settings
BUP_DIR=''                                          # where the backups are stored
DEL_RETENTION="30"                                  # how many days to keep deleted vms
CONF_RETENTION="30"                                 # how many days to keep configuration backups
DEFAULT_RETENTION="30"                              # how many days to keep default vm backups
DYN_DAILY_RETENTION="1"                             # how many days to keep dynamic daily backups
DYN_WEEKLY_RETENTION="6"                            # how many days to keep dynamic weekly backups
DYN_MONTHLY_RETENTION="30"                          # how many days to keep dynamic monthly backups
STA_WEEKLY_RETENTION="6"                            # how many days to keep static weekly backups
STA_MONTHLY_RETENTION="30"                          # how many days to keep static monthly
" >> $ROOTDIR/pool/vms/settings

echo "Installation done. Run $ROOTDIR/pool/make-default.sh to create the first dummy VM."
