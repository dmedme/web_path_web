#!/bin/bash
. /home/bench/fluline/path_web/fdvars.sh
cd $PATH_HOME
i=1
while :
do
    auto4800pub1500prof.sh >auto4800pub1500prof.log 2>&1
    mv $PATH_HOME/work/4800pub1500prof.1 $PATH_HOME/results/4800pub1500prof.seq$i
    if [ -d  $PATH_HOME/results/4800pub1500prof.seq$i ]
    then
        cd  $PATH_HOME/results/4800pub1500prof.seq$i
        rm */comout*
        find_failed.sh >stats.log
        bzip2 */log* &
        cd $PATH_HOME
    fi
    i=`expr $i + 1`
done
