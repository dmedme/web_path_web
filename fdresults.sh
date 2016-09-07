#!/bin/ksh
# Process the results for a Web test.
# - Create a directory for each host
# - Unpack the data into it; the runout file and the log files
# - For each log file, split out message return times and the event times.
# - Produce overall timout files from the concatenated log files
#
# The parameters are a list of compress results archives
# 
# The analysis is unpacked in a directory beneath
#
do_results() {
eid=$1
shift
if [ ! -d $eid ]
then
    mkdir $eid
fi
cd $eid
for ins in $*
do
#
# Get the host IP address
#
    hid=`echo $ins | sed 's=.*res\.\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\.tar.bz2=\1='`
#
# Create a corresponding directory
#
    if [ ! -d $hid ]
    then
        mkdir $hid
    fi
#
# Change to it
#
    cd $hid
#
# Extract the runout files and the log files
#
    bzip2 -d <../../$ins | miniarc x -
#
# Extract the run id from the first runout file name
#
    set -- `ls -1 runout*`
#    pid=`echo $1 | sed 's=runout\([^_][^_]*\).*=\1='`
    pid=`echo $1 | sed 's=runout=='`
    case "$pid" in
    *_?)
       pid=`echo $pid | sed 's/_.$//'`
       ;;
    esac
#
# Zero the two summary output files
#
    >comout.msr
    >comout.evt
#
# Loop - for each runout file
#
    step=""
    k=0
    while :
    do
    runout=runout$pid$step
    if [ ! -f $runout ]
    then
        break
    fi
#
# Process the runout file
#
    {
    read x
    read x
    read x
    i=1
    while read cnt script y
    do
#
# Loop - For each script in the runout file
#
        j=0
        while :
        do
#
# Loop - For each script user
#
            if [ ! -f log$pid$step.$i.$j ]
            then
                break
            fi
            if [ $j = 0 ]
            then
                $PATH_AWK -F: 'BEGIN {first_flag = 1}
                    $6 == "T" {
                    x = $0
                    do
                    {
                        if ((getline)<=0)
                            exit
                        if ($6 == "T")
                            x = $0
                    }
                    while ($6 == "T")
                    nf = split(x, arr, ":")
                    if (first_flag  == 1)
                    {
                        print arr[1] ":" arr[2] ":" arr[3] ":" (arr[4] - 1) ":" arr[5] ":A:TR:Send/Receive Pair">>"comout.msr"
                        first_flag = 0
                    }
                    if ($6 == "R")
                    {
                        print arr[1] ":" arr[2] ":" arr[3] ":" arr[4] ":" arr[5] ":TR:" ($5 - arr[5]) >>"comout.msr"
                        next
                    }
                }
                {
                    print $0>>"comout.evt"
                }' log$pid$step.$i.$j > /dev/null >/dev/null 2>&1
	    elif [ $j -lt $cnt ]
            then
                cat log$pid$step.$i.$j >>comout.evt
            fi
            j=`expr $j + 1`
        done
        i=`expr $i + 1`
    done
    } <runout$pid$step
    k=`expr $k + 1`
    step=_$k
    done
    fdreport -b -t -i95 comout.evt >timout.$pid.evt.txt
    fdreport -b -i95 -w "Test $pid $pid" comout.evt >timout.html
    fdreport -t comout.msr >timout.$pid.msr.txt
    cp $PATH_SOURCE/e2tiny.gif .
    cd ..
done
# *****************************************************************
# Produce an overall summary for all hosts
#
# - Get the run ID
#
    pid=`echo $eid | sed 's/\..*$//'`
    frst=`ls | head -1`
    cp $frst/runout$pid .
#
# Get the run end time
#
    etime=`tail -1 $frst/log$pid.1.0 | $PATH_AWK -F: '{print substr($5,1,10)}'` 
    btime=`head -1 $frst/log$pid.1.0 | $PATH_AWK -F: '{print substr($5,1,10)}'` 
#
# Produce the results
#
    fdreport -b -i95 -w "Test $pid (All)" -s $btime -e $etime */log* >timout.html
    cp $PATH_SOURCE/e2tiny.gif .
    return
}
