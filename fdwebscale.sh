#!/bin/ksh
# %W %D% %T% %E% %U%
# Copyright (c) E2 Systems Limited, 2001
# ***************************************************************************
# Function to generate the echo files for a particular client host
#
# Parameters:
# 1 - Scenario ID
# 2 ... n Role/Role Host pairs (not used)
#
# The current working directory should be the one where generation is to take
# place.
# *****************************************************************************
# No longer used
#. fdwebclone.sh
webscale() {
if [ $# -lt 1 ]
then
#    echo webscale requires a runout file ID
    return
fi
set -x
pid=$1
if [ ! -f runout$pid ] 
then
#    echo webscale: runout file runout$pid does not exist
    return
fi
j=1
i=""
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
# Parameters for clone_script (no longer used)
# 1 - Name of seed script
# 2 - The PID
# 3 - The bundle
# 4 - Number of users
# 5 - Number of transactions each will do
# 6 - Think Time
# 7 - The substitution place-holders
#    clone_script $tran $pid$i $bundle $nusers $ntrans $think $seed "$subst"
# *************************************************************************
# Parameters for fastclone
# 1 -5 as above
# 6 - Whether unequal length substitutions are allowed
# 7 - Think Time
# 8 - Whether data can be reused (in which case the records are returned to
#     the end of the data files)
    fastclone $tran $pid$i $bundle $nusers $ntrans N $think N

    bundle=`expr $bundle + 1`
done
) < runout$pid$i
    i=_$j
    j=`expr $j + 1`
done
#
# Make sure each script has a unique user (capture via E2TEST2 is assumed)
#user_patch.sh
return
}
