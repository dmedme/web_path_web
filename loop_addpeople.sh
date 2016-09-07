#!/bin/bash
. /home/bench/nhs_direct_dotnet/path_web/fdvars.sh
cd $PATH_HOME
i=1
while [ $i -lt 10 ]
do
    autoaddpeoplerun.sh >autoaddpeoplerun.log 2>&1
    mv $PATH_HOME/work/addpeople.1 $PATH_HOME/results/addpeople.seq$i
    if [ -d  $PATH_HOME/results/addpeople.seq$i ]
    then
        cd  $PATH_HOME/results/addpeople.seq$i
        rm */comout*
        bzip2 */log* &
        cd $PATH_HOME
    fi
    i=`expr $i + 1`
done
