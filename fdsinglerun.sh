#!/bin/bash
# fdsingle.sh - run a sizing one script at a time
#
. /home/bench/euclid/path_web/fdvars.sh
cd $PATH_HOME/work
trap '' 1
if [ $# -lt 1 ]
then
    echo Provide a runout file id
    exit 1
fi
piid=$1
if [ ! -f runout$piid ]
then
    echo Provide a valid runout file id
    exit 1
fi
#
globusers=`$PATH_AWK  '!/end_time/ { if(NR>3) print $1}' runout$piid`
set -- $globusers
bundle=$#
bundle=` expr $bundle + 1 `
j=1
#
# Loop through running the scripts one after the other, but still creating
# the log files in the usual way
#
while [ $j -lt $bundle ]
do
i=0
verbose=-v4
set -- $globusers
nusers=$1
shift
globusers="$*" 
outfile=log$piid.$j
while [ $i -lt $nusers ]
do
infile=echo$piid.$j.$i
dumpfile=dump$piid.$j.$i
#
# Run the driver
#
racdrive -m 1 $verbose $outfile $piid $j $i $infile >$dumpfile 2>&1
#
 verbose=
 i=`expr $i + 1`
done
 j=`expr $j + 1`
done
    fdreport -b -t -i95 log$piid.* >timout.$piid.evt.txt
    fdreport -b -i95 -w "" log$piid.* >timout.html
