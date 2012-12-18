#!/usr/bin/env bash
#
# StorenextInstallOSX.sh installs stornext on Mac Clients.
#
# Created by JD Trout (5/26/11)
#
# Properity of IMT
#
# Version 0.6


#
# Globals
#
XPATH="/Library/Filesystems/Xsan/config/"
FSNAME="fsnameservers"
PCONF="config.plist"
AUTOMNT="automount.plist"
SYSSERIAL="/etc/systemserialnumbers"
SYSSERIAL_FILE="/etc/systemserialnumbers/xsan"
LAUNCH="/System/Library/LaunchDaemons/com.apple.xsan.plist"
XCONF="xsan.conf"
INSTALL_FILE="installconfig.plist"
UMASK_FILE="/etc/launchd-user.conf"
HOST=$(echo $HOSTNAME | cut -d'.' -f1)
#IP - need to figure out best way to find IP

# check is user is root
if [ $EUID != 0 ]; then
	echo "You need to be root to run this script."
	echo "Please type -sudo bash- to become root and run the script again."
	exit
fi

# check if XSan is installed and install it if it is not
if [ ! -e "$LAUNCH" ]; then
    echo "XSan is not installed, do you wish to install? [Y/N]"
	read ANS
	if [ $ANS = "Y" ] || [ $ANS = "y" ]; then
		echo "Installing XSan..."
		/usr/sbin/installer -file $INSTALL_FILE
		# Determin verion of OS
		VER=$(sw_vers -productVersion | cut -d'.' -f2)
		# install proper version of update
		if [ $VER = 6 ]; then
			echo "Installing XSan 2.2.1 update for Snow Leopard"
			/usr/sbin/installer -pkg XsanFilesystemUpdateSnowLeo.mpkg -target /
		elif [ $VER = 5 ]; then
			echo "Installing XSan 2.2.1 update for Leopard"
			/usr/sbin/installer -pkg XsanFilesystemUpdateLeopard.mpkg -target /
		else
			echo "Unknown version of OS X"
			echo "Exiting install script"
			exit
		fi
	else
		echo "Exiting install script"
		exit
	fi
fi

# check if the license was previously linstalled

#FOR TESTING ONLY PLEASE REMOVE BEFORE DEPLOMENT
#rm -rf $SYSSERIAL_FILE

if [ -e "$SYSSERIAL_FILE" ]; then
	echo ""
	echo "XSAN serial already exists on machine!"
	echo ""
	echo "S/N:"
	cat "$SYSSERIAL_FILE"
	echo ""
	echo "If you wish to install XSan with a new serial number or write over existing config files please remove $SYSSERIAL_FILE"
	exit
fi

# check if xsan.conf file exists

if [ ! -e "$XCONF" ]; then
    echo "xsan.conf file does not exists, please create it"
	exit
fi


# set variables for config.plist file 
SERIAL=$(grep -iw $HOST $XCONF | awk '{print $3;}')
MDNET_IP=$(grep "metanet:" $XCONF | awk '{print $2;}' | cut -d'/' -f1)
MDNET_SUB=$(grep "metanet:" $XCONF | awk '{print $2;}' | cut -d'/' -f2)
SANNAME=$(grep "name:" $XCONF | awk '{print $2;}')
VOLUME=$(grep "vol:" $XCONF | awk '{print $2;}')

if [ -z "$SERIAL" ]; then
	echo "Can't find hostname in config file, check xsan.conf file"
	exit
fi

# setup fsnameserver 
echo "Creating fsnameservers file"

grep mdc: $XCONF | awk '{print $2;}' > $XPATH$FSNAME

if [ ! -e "$XPATH$FSNAME" ]; then
    echo "Failed to create fsnameservers file"
	exit
fi

echo "Copy fsnamservers file created"

# check to see if /etc/systemserialnumbers dir exists and add serial number to XSan file
echo "Creating serial number files"
if [ ! -d "$SYSSERIAL" ]; then
    mkdir $SYSSERIAL
fi
echo $SERIAL > $SYSSERIAL_FILE

if [ ! -e "$SYSSERIAL_FILE" ]; then
    echo "Failed to create $SYSSERIAL_FILE file"
	exit
fi

# generate plist file

# add metadata network, SAN name and Serial number
sed -e 's/MDNET/'$MDNET_IP"\/"$MDNET_SUB'/; s/SANNAME/'$SANNAME'/; s/InsertSerial/'$SERIAL'/' $PCONF > $XPATH$PCONF

if [ ! -e "$XPATH$PCONF" ]; then
    echo "Failed to create $XPATH$PCONF file"
	exit
fi

echo "Serial number files created"

# setup automount 
echo "Creating automount.plist file"

sed -e 's/VOLNAME/'$VOLUME'/' $AUTOMNT > $XPATH$AUTOMNT

if [ ! -s "$XPATH$AUTOMNT" ]; then
    echo "Failed to create automount.plist file"
	exit
fi

echo "Copy automount.plist file completed"

# remove auth_secert file
echo "Removing legacy .auth_seceret if it exists"
if [ -e "$XPATH.auth_seceret" ]; then
	rm -f $XPATH.auth_seceret
fi

echo "Registering Serial number"
# register server
RegisterSeRV 2>&1

if [ $? != 0 ]; then
	echo "RegisterSeRV failed with error code $?"
	echo "Exiting install script"
	exit
fi

# set umask

UMASK=$(grep "umask:" $XCONF | awk '{print $2;}')

if [ -n "$UMASK" ]; then
	UNUM=$(expr $UMASK : '.*')
	
	if [ $UNUM -ge 5 -o $UNUM -le 2 -o $UMASK -ge 8 ]; then
		echo ""
		echo "UMASK format is not correct. All numbers need to be between 0-7 and there can be no less than three or more than four digits"
		echo "skping umask"
		echo ""
		UMASK=""
	fi
fi
	
if [ -n "$UMASK" ]; then

	echo "Setting UMASK $UMASK"
	umask $UMASK
	echo "umask $UMASK" > $UMASK_FILE
fi

echo "Restarting XSan client"
# restart XSan
launchctl unload $LAUNCH

launchctl load $LAUNCH

echo "XSan restarted"