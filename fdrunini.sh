# ***************************************************************************
# run_ini
#
# @(#) $Name$ $Id$
# Copyright (c) 1993, 2001 E2 Systems Limited
# Initialise a scenario for running:
# - Create the directories
# - Create the master runout files
# - Assign the hosts
# Parameters: 
# - The run identifier
#
# Selecting the scenario for execution leads to the creation of
# a new directory in se, named scenario_name.sequence. Within this
# sub-directory, further sub-directories are created:
# -  A sub-directory for the client, and one sub-directory for each supporting
#    role (eg. app_server, db_server)
# -  The supporting role subdirectories contain a runout file, constructed
#    by concatenating the role.run files for the participating scripts
# -  The client sub-directory also contains runout files, one per step,
#    generated from the scenario control file.
run_ini () {
set -x
pid=$1
#
# Create the base directory
#
cd $PATH_HOME/se
seq=1
until [ ! -d $pid.$seq ]
do
    seq=`expr $seq + 1`
done
mkdir $pid.$seq
cd $pid.$seq
#
# Read the scenario control file and create the necessary sub_directories
#
{
read x
read step_cnt
read x
read script x
sstr="../../scripts/$script/*.run"
while :
do
read script x || break 
sstr=$sstr" ../../scripts/$script/*.run"
done
} < ../../scenes/$pid/ctl.txt
mkdir `eval ls -1 $sstr | sed 's=.*/\\([^/.]*\\)\\.run=\\1=' | sort | uniq`
#
# Now create the runout files
# 
roles=*
for role in $roles
do
    echo E2 Systems Network Benchmark Control Script `date` >$role/runout$pid
    if [ $role = client ]
    then
#
# Write the header lines (there must be three in total)
#
        echo "Users Script Transactions Think Actor Unused_1 Unused_2 Unused_3">>client/runout$pid
        echo "===== ====== ============ ===== ===== ======== ======== ========">>client/runout$pid
        j=1
        while [ $j -lt $step_cnt ]
        do
            echo E2 Systems Network Benchmark Control Script `date` >$role/runout${pid}_$j
            echo "Users Script Transactions Think Actor Unused_1 Unused_2 Unused_3">>client/runout${pid}_$j
            echo "===== ====== ============ ===== ===== ======== ======== ========">>client/runout${pid}_$j
            j=`expr $j + 1`
        done
        {
        read x
        read x
        read x
        while read script x
        do
            set -- $x
#
# - The client (actor 0). A line would be:
#    - number of users (default 10)
#    - the script name (as provided)
#    - the number of transactions (default 10)
#    - think time (default 10)
#    - actor ID (must be 0)
#    - 3 more rubbish values
#
            echo $1 $script $2 $3 0 must be present >>$role/runout$pid
            shift 3
            j=1
            while [ $# -gt 2 ]
            do
                echo $1 $script $2 $3 0 must be present >>$role/runout${pid}_$j
                j=`expr $j + 1`
                shift 3
            done
        done
        } <../../scenes/$pid/ctl.txt
    else
#
# Write the header lines (there must be three in total)
#
        echo "Users Script Transactions Think Actor_count Actor_1 Actor_2 Actor_3">>$role/runout$pid
        echo "===== ====== ============ ===== =========== ======= ======= =======">>$role/runout$pid
        {
        read x
        read x
        read x
# - The application server, web server and database servers would have
#    - number of users (1 if this script needs this role, 0 otherwise)
#    - the script name (as provided)
#    - the number of transactions (not used, actually)
#    - think time (not used here, actually)
#    - actor count (1, 2 or 3)
#    - Up to 3 actor values, padded out with rubbish values to give 3 in all
#
        while read script x
        do
            if [ -f ../../scripts/$script/$role.run ]
            then
                cat ../../scripts/$script/$role.run  >>$role/runout$pid
            else
#
# Placeholder so that the bundles are the same in all the scenario runout
# files
#
                echo 0 $script 0 0 1 must be present >>$role/runout$pid
            fi
        done
        } <../../scenes/$pid/ctl.txt
    fi
done
export pid seq
return
}
