#!/bin/bash
# linnetmon.sh - Periodically check the network interface to compute
# running traffic totals
if [ $# -lt 2 ]
then
    echo Provide an interface "(e.g. eth0)" and an interval in seconds
    exit
fi
PATH_AWK=${PATH_AWK:-gawk}
export PATH_AWK
iface=$1
int=$2
#
# Check input parameters
#
if ifconfig "$iface"
then
    :
else
    echo $iface is not a valid network interface
    exit 1
fi
if [ "$int" -lt 1 ]
then
    echo $int is not a valid interval in seconds
    exit 1
fi
trap "echo Abort command received; exit" 0 1 15
set -- `$PATH_AWK -F"[ :][ :]*" '$2 == "'$iface'" { print $3 " " $4 " " $11 " " $12}' /proc/net/dev`
if [ $# -ne 4 ]
then
    echo No statistics available for $iface "; perhaps it is an alias?"
    exit 1
fi
bytes_rec=$1
packs_rec=$2
bytes_sent=$3
packs_sent=$4
echo "Timestamp|bytes_rec|packs_rec|bytes_sent|packs_sent"
#
# Loop until terminated
#
while :
do
    sleep $int
    set -- `$PATH_AWK -F"[ :][ :]*" '$2 == "'$iface'" { print $3 " " $4 " " $11 " " $12 " " ($3 -'$bytes_rec') " " ($4 -'$packs_rec') " " ($11 -'$bytes_sent') " " ($12 -'$packs_sent')}' /proc/net/dev`
    if [ $# -ne 8 ]
    then
        echo "Screw up; couldn't read statistics"
    fi
    dt=`date +"%d-%m-%Y %T"`
    echo "$dt|$5|$6|$7|$8"
    bytes_rec=$1
    packs_rec=$2
    bytes_sent=$3
    packs_sent=$4
done
