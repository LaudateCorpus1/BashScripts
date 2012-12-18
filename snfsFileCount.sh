#!/bin/sh
# Argument = -b beginning_stripe_group -e ending_string_group -f fs_mount_point -d output_dir_name -t num_threads

CURDATE=`date +"%m_%d_%Y-%H_%M_%S"`
SOURCEPATH=
SGSTART=4
SGEND=4
TCOUNT=3

usage()
{
cat << EOF
usage: $0 [-d output_dir_name] [-f fs_mount_point] [-b beginning_stripe_group] [-e ending_stripe_group] [-t num_threads]

OPTIONS:
   -d      Target Directory (must exists).  
   -f      File System Mount Point to Run report on
   -b      Beginning Stripe Group
   -e      Ending Stripe Group
   -t      num_threads
EOF
}

intro()
{
cat << EOF

Dumping file lists EspritProd, SG2-SG20.
Started at $CURDATE

EOF
}

threadThrottle()
{
	while [ `jobs -r | grep -c .` -ge $TCOUNT ] 
	do
		sleep 10
	done
}

#BEGIN SCRIPT EXECUTIION

DIR=/stornext/EspritCDN_MX/migration_reports/

# GETOPTS

while getopts “d:f:b:e:t:” OPTION
do
     case $OPTION in
         d)
             DIR=$OPTARG
             ;;
         f)
             SOURCEPATH=$OPTARG
             ;;
         b)
             SGSTART=$OPTARG
             ;;
         e)
             SGEND=$OPTARG
             ;;
         t)
             TCOUNT=$OPTARG
             ;;
     esac
done

if [[ -z $DIR ]]
then
    echo "Directory " $DIR " not specified."
    usage
    exit 1
fi

if ! [ -d $DIR ]
then
	echo "Directory " $DIR " does not exist"
	usage
	exit 1
fi

if [[ -z $SOURCEPATH ]]
then
    echo "Filesystem mount point not specified"
    usage
    exit 1
fi

if ! [ -d $SOURCEPATH ]
then
	echo "Directory " $SOURCEPATH " does not exist"
	usage
	exit 1
fi

# Print date & time started
intro

DIR=$DIR`date +"%m_%d_%Y-%H_%M_%S"`
# Make directory for current run
mkdir $DIR

if ! [ -d $DIR ]
then
    echo "Directory " $DIR " could not be created"
    exit 1
fi

for (( i=$SGSTART; i<=$SGEND; i++))
do
	# if the number of running jobs exceeds the max, wait until one job is done
	threadThrottle
	snfsdefrag -l -G $i -m 0 -r $SOURCEPATH > $DIR"/SG"$i".txt" &
done

wait;

echo "Finished at " `date +"%m_%d_%Y-%H_%M_%S"`