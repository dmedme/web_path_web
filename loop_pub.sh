#!/bin/bash
. /home/bench/fluline/path_web/fdvars.sh
cd $PATH_HOME
i=4
while [ $i -lt 5 ]
do
    autopub.sh >autopub.log 2>&1
    mv $PATH_HOME/work/3200users.1 $PATH_HOME/results/3200users.seq$i
    if [ -d  $PATH_HOME/results/3200users.seq$i ]
    then
        cd  $PATH_HOME/results/3200users.seq$i
        rm */comout*
        find_failed.sh >stats.log
        bzip2 */log* &
        cd $PATH_HOME
    fi
    i=`expr $i + 1`
done
