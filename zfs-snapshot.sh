#!/bin/sh
######################################################
#
# zfs-snapshot.sh
# Takes ZFS snapshots of all ZFS filesystems rolling off
# the oldest each time it runs.
#
# Jeff Higham - jeffhigham at gmail dot com
# 11/27/2007
# 
# Updated by JD Trout
# 12/28/2011
######################################################
PATH=$PATH:/usr/sbin/zfs
export PATH

# how many snapshots to retain.
RS=60

# current time
NOW=`date +%Y%m%d%H%M%S`

# ZFS filesystems to snapshot set by stdin
FS=$1
if [ -z "${FS}" ] ; then
	FS=`zfs list -t filesystem | awk '/^[a-z0-9]+\//{ print $1}'`
fi

for I in $FS; do
	NS=`zfs list -t snapshot | grep "${I}@" | wc -l | tr -d " "`
	echo "Running: zfs snapshot ${I}@$NOW . . . \c"
	zfs snapshot ${I}@$NOW >/dev/null 2>/tmp/error.$$
	if [ $? = 0 ]; then
		echo "success!"
		else
			echo "failed ($?)!"
			cat /tmp/error.$$
			rm /tmp/error.$$ > /dev/null 2>&1
		fi

		if [ $NS -ge $RS ]; then
			LAST=`zfs list -t snapshot | grep "${I}@" | head -1 | awk '{ print $1}'`
			echo "Running: zfs destroy  $LAST . . . \c"
			zfs destroy $LAST >/dev/null 2>/tmp/error.$$
			
			if [ $? = 0 ]; then
				echo "success!"
			else
				echo "failed ($?)!"
				cat /tmp/error.$$
				rm /tmp/error.$$ > /dev/null 2>&1
			fi
		fi
done

echo
echo "Current snapthots:"
zfs list -t snapshot
echo