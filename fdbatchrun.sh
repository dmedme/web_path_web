#!/bin/ksh
# Run a scenario when detached from the terminal
#
if [ $# -lt 1 ]
then
    echo Provide a scenario execution ID
    exit
fi
if [ "$PATH_SOURCE" = "" ]
then
    echo PATH_SOURCE must be set in the environment
    exit
fi
test_id=$1
. $PATH_SOURCE/fdvars.sh
. fdtrafrun.sh
env
set -x
#
# Kick off monitors
#
where_it_is=`pwd`
#run_mons.sh 4000 &
rm -f $PATH_HOME/work/res*bz2
trafrun $test_id
#
# Wait for the monitors to finish, if they are still running
#
#while ps -e | grep uudecode
#do
#sleep 10
#done
#
# Merge in the system performance metrics
#
#cd $PATH_HOME/work/$test_id
#mv $where_it_is/mon*.tar.bz2 .
#rep_euclid.sh
#rm results.zip
#zip -9 results.zip timout.html *.gif *.png
#echo The results.zip file is what gets sent to all and sundry
exit
