#!/bin/bash
# fdweedrun.sh - Weed out the log files that did not complete
#
. /home/bench/euclid/path_web/fdvars.sh
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
# Create the directories to separate the files into
#
mkdir complete incomplete
#
#set -x
globusers=`$PATH_AWK  '!/end_time/ { if(NR>3) print $1}' runout$piid`
set -- $globusers
bundle=$#
bundle=` expr $bundle + 1 `
j=1
#
# Loop through checking that the log files are complete.
# - If they are, move the files to the complete directory
# - If they are not, move the files to the incomplete directory
#
while [ $j -lt $bundle ]
do
i=0
trans=`$PATH_AWK '{ if (NR == (3 + '$j')) print 2 * $3 }' runout$piid`
ev=`tail echo$piid.$j.0 | $PATH_AWK '/^\\\\T/ { print substr($1,3,2) ; exit}'`
set -- $globusers
nusers=$1
shift
globusers="$*" 
outfile=log$piid.$j
while [ $i -lt $nusers ]
do
infile=echo$piid.$j.$i
dumpfile=dump$piid.$j.$i
fincnt=`grep -c :$ev: $outfile.$i`
if [ "$fincnt" = "$trans" ]
then
    mv $infile $outfile.$i $dumpfile complete
else
    mv $infile $outfile.$i $dumpfile incomplete
fi
 i=`expr $i + 1`
done
 j=`expr $j + 1`
done
