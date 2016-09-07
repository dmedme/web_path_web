#!/bin/ksh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 2001
#
# Function to distribute scripts ready for execution
#
# Parameters:
# 1 - The scenario incarnation
#
. $PATH_SOURCE/fdresults.sh
trafrun() {
set -x
    runid=$1
    pid=`echo $runid | sed 's/\..*$//'`
# *************************************************************************
# We really want to use worldrun here. For now, make sure that minitest is
# running locally.
#
if [ ! "$PATH_OS" = NT4 ]
then
if ps -ef | grep "[m]initest $E2_HOME_PORT"
then 
:
else
(
    cd $PATH_HOME/work
    PATH=$PATH:$PATH_HOME/work
    export PATH
    nohup ./setup.sh >minilog 2>&1 &
) &
fi
fi
#
# Get the number of steps, and the step length
#
    {
    read x
    read step_cnt
    read step_len
    } <$PATH_HOME/scenes/$pid/ctl.txt
    set -- $step_len
    i=0
    tot_len=0
    while [ "$i" -lt "$step_cnt" ]
    do
        tot_len=`expr $tot_len + $1`
        if [ "$#" -gt 1 ]
        then
            shift
        fi
        export $tot_len
        i=`expr $i + 1`
    done
#
# Work out how long the non-client servers need to run for
#
    for i in $PATH_HOME/se/$runid/client/*/runout$pid*
    do
        {
        read x
        read x
        read x
        while read users x
        do
            tot_len=`expr $tot_len + $PATH_STAGGER \* $users`
        done
        } < $i
    done
#
# Kick off the non-client servers
#
    targs=`ls -1d $PATH_HOME/se/$runid/*/* | grep -v '/client/'`
    if [ ! -z "$targs" ]
    then
        for d in $targs
        do
            if [ -d $d ]
            then
                cd $d
                host_ip=`echo $d | sed 's=.*/=='`
                if minitest $host_ip $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT SLEW" </dev/null
                then
                    echo alive > $PATH_HOME/hosts/$host_ip/status
                    minitest $host_ip $E2_HOME_PORT SCENE $pid $tot_len </dev/null &
                else
                    echo dead > $PATH_HOME/hosts/$host_ip/status
                fi
            fi
        done
    fi
#
# Now kick off the client servers
#
    targs=`ls -1d $PATH_HOME/se/$runid/client/*`
    if [ ! -z "$targs" ]
    then
#       slave_cnt=0
        for d in $targs
        do
            if [ -d $d ]
            then
                cd $d
                host_ip=`echo $d | sed 's=.*/=='`
                if minitest $host_ip $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT SLEW" </dev/null
                then
                    echo alive > $PATH_HOME/hosts/$host_ip/status
                    minitest $host_ip $E2_HOME_PORT EXEC "rm -f res*bz2" </dev/null
                    minitest $host_ip $E2_HOME_PORT SCENE $pid $step_len </dev/null &
                else
                    echo dead > $PATH_HOME/hosts/$host_ip/status
                fi
            fi
#           slave_cnt=`expr $slave_cnt + 1`
#           if [ $slave_cnt = 3 ]
#           then
#               sleep 600
#           else
#               sleep 100
#           fi
        sleep 31
        done
#
# Long stop shutdown for when racdrives don't exit properly
#
        long_stop=`expr $tot_len + 1050`
        sleep  $long_stop
        if [ "$PATH_OS" = LINUX ]
        then
            killall $PATH_DRIVER
            ps -ef | $PATH_AWK '/[S]CENE/ {
                for (i = 1; i < NF; i++)
                {
                    if ($i == "minitest")
                    {
                        i++
                        print "minitest " $i " '$E2_HOME_PORT' EXEC \"killall '$PATH_DRIVER'\" </dev/null" 
                        system("minitest " $i " '$E2_HOME_PORT' EXEC \"killall '$PATH_DRIVER'\" </dev/null") 
                        break
                    }
                }
            }'
            sleep 31
            killall -9 $PATH_DRIVER
            ps -ef | $PATH_AWK '/[S]CENE/ {
                for (i = 1; i < NF; i++)
                {
                    if ($i == "minitest")
                    {
                        i++
                        print "minitest " $i " '$E2_HOME_PORT' EXEC \"killall -9 '$PATH_DRIVER'\" </dev/null" 
                        system("minitest " $i " '$E2_HOME_PORT' EXEC \"killall -9 '$PATH_DRIVER'\" </dev/null") 
                        break
                    }
                }
            }'
        fi
    fi
#
# Wait for the minitests to finish (they should all time out)
#
    wait
#
# Copy back and process the results
#
    cd $PATH_HOME/work
#
# Merge the output files in a sensible way, one host at a time, and squirrel
# away the results. ipdanal doesn't work the way I imagined it when I first
# wrote this...
#
    if [ ! -d $runid ]
    then
        mkdir $runid
    fi
    targs=`ls -1d $PATH_HOME/se/$runid/*/*`
    to_process=""
    if [ ! -z "$targs" ]
    then
        for d in $targs
        do
            if [ -d $d ]
            then
                host_ip=`echo $d | sed 's=.*/=='`
                rm -f res.$host_ip.tar.bz2
                if minitest $host_ip $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT COPY res.$host_ip.tar.bz2 res$pid.tar.bz2" </dev/null
                then
                    echo alive > $PATH_HOME/hosts/$host_ip/status
                    to_process=$to_process" res.$host_ip.tar.bz2"
                else
                    echo dead > $PATH_HOME/hosts/$host_ip/status
                fi
            fi
        done
    fi
# ********************************************************************
# Produce the reports. There are two families, one based on the events,
# and the other on the transmission/receive pairs
#
    cd $PATH_HOME/work
    do_results $runid $to_process
    return
}
