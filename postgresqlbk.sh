#! /bin/bash

# postgresqlbk.sh
# by JD Trout 
# Created for postgresql 9 on Solaris 11

DUMPALL="/usr/local/pgsql/bin/pg_dumpall"
PGDUMP="/usr/local/pgsql/bin/pg_dump"
PSQL="/usr/local/pgsql/bin/psql"
LOG="/usr/local/pgsql/data/pg_bklog"

# directory to save backups in, must be rwx by postgres user
BASE_DIR="/backup/databases"
YMD=$(date "+%Y-%m-%d")
DIR="$BASE_DIR/$YMD"
mkdir -p $DIR

# get list of databases in system , exclude the tempate dbs
DBS=$($PSQL -l -t | egrep -v 'template[01]' | egrep '\n' | awk '{print $1}')

# first dump entire postgres database, including pg_shadow etc.

echo "Starting backup on $(date "+%Y-%m-%d at %H:%M:%S")" 2>&1 >> $LOG 
echo "<$(date "+%H:%M:%S")> dumping all databases" 2>&1 >> $LOG 
$DUMPALL > $DIR/db.all

echo "<$(date "+%H:%M:%S")> dumping globals" 2>&1 >> $LOG 
# next dump globals (roles and tablespaces) only
$DUMPALL -g > $DIR/db.globals

#echo "<$(date "+%H:%M:%S")> dumping data-only" 2>&1 >> $LOG - not needed
# last dump data-only (no schema)
#$DUMPALL -a > $DIR/db.data

# now loop through each individual database and backup the schema and data separately
for database in $DBS; do
    SCHEMA=$DIR/$database.schema
    DATA=$DIR/$database.data

	echo "<$(date "+%H:%M:%S")> dumping $database schema" 2>&1 >> $LOG 
    # export data from postgres databases to plain text
    $PGDUMP -C -s $database > $SCHEMA

	echo "<$(date "+%H:%M:%S")> dumping $database data-only" 2>&1 >> $LOG 
    # dump data
    $PGDUMP -a $database > $DATA
done

echo "Finished backup on $(date "+%Y-%m-%d at %H:%M:%S")" 2>&1 >> $LOG 

# delete backup files older than 30 days
##OLD=$(find $BASE_DIR -type d -mtime +30)
##if [ -n "$OLD" ] ; then
##        echo deleting old backup files: $OLD
##       echo $OLD | xargs rm -rfv
##fi