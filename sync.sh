#!/bin/bash
######################################################
#
# sync.sh
# Perform file system copy/sncing of data across multipul folders.
# This script is designed for DirectTV and needs to be adjusted for other clients.
# However, this process should be simple as it has to do with source and target.
#
#
# JD Trout 
# 12/12/2012 v.0.1
#
# Known Issues
# * 
#
#
######################################################

#Default Globals


threadThrottle()
{
	while [ `jobs -r | grep -c .` -ge 5 ] 
	do
		sleep 20
	done
}

for (( i=1; i<=20; i++))
do
	# if the number of running jobs exceeds the max, wait until one job is done
	threadThrottle

	echo  $i
done