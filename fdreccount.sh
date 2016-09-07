#!/bin/ksh
# %W %D% %T% %E% %U%
# Copyright (c) E2 Systems Limited, 2001
# ***************************************************************************
# Function to count the records needed for a test
#
# Parameters:
# 1 - Scenario ID
# 2 - Error file
# 3 - Count of hosts
#
# The current working directory should be the one where generation is to take
# place.
# *****************************************************************************
rec_count() {
set -x
if [ $# -lt 3 ]
then
    echo rec_count requires a runout file ID, an error file name and a host count
    return
fi
pid=$1
errfile=$2
hosts=$3
if [ ! -f runout$pid ] 
then
    echo rec_count: runout file runout$pid does not exist
    return
fi
j=1
#
# Loop through all the runout files using fastclone to count the records needed
#
i=""
#
# Clear errors
#
>$errfile
while :
do
    if [ ! -f runout$pid$i ]
    then
        break
    fi
(
# Runout file layout
# 3 junk lines
# Lines consisting of space separated:
#    nusers tran ntrans think  + 5 further parameters. fdreport needs them.
#
# Skip the first three lines
#
read l
read l
read l
bundle=1
while :
do
    read nusers tran ntrans think cps seed subst || break
    if [ "$ntrans" = "start_time" -o "$ntrans" = "" ]
    then
        continue
    fi
# *************************************************************************
# Parameters fastclone
# 1 - Name of seed script
# 2 - The PID
# 3 - The bundle
# 4 - Number of users
# 5 - Number of transactions each will do
# 6 - Whether unequal length substitutions are allowed
# 7 - Think Time
# 8 - Whether data can be reused (in which case the records are returned to
#     the end of the data files)
    if fastclone -c  $tran $pid $bundle $nusers $ntrans N $think N 2>>$errfile
    then
        :
    else
        echo fastclone found problems with id=$pid bundle=$bundle script=$tran >>$errfile 
    fi
    bundle=`expr $bundle + 1`
done
) < runout$pid$i
    i=_$j
    j=`expr $j + 1`
done | sort | $PATH_AWK -F"|" 'BEGIN { l = ""
hosts='$hosts'
print "Data File|Needed|Available Records"
}
function cnt_file(fn)
{
    n = -1
    while((getline<fn) > 0)
        n++
    close(fn)
    return n
}
{
    m = $1
    c = $2
    if (l != $1)
    {
        if (l != "")
        {
            tot = cnt_file(l)
            print l "|" (cnt * hosts) "|" tot
            if (tot < (cnt*hosts))
               print "Too few records in " l " want " (cnt*hosts) " but only have " tot >"'$errfile'"
        }
        l = m
        cnt = c
    }
    else
        cnt += c
}
END {
    if (l != "")
    {
        tot = cnt_file(l)
        print l "|" (cnt*hosts) "|" tot
        if (tot < (cnt*hosts))
            print "Too few records in " l " want " (cnt*hosts) " but only have " tot >"'$errfile'"
    }
}'
return
}
