#!/bin/bash
. /home/bench/euclid/path_web/fdvars.sh
cd $PATH_HOME
i=35
while [ $i -lt 36 ]
do
    run_mons.sh 4500 &
    autoeuclid.sh >autoeuclid.log 2>&1
    mv $PATH_HOME/work/scenCthird.1 $PATH_HOME/results/scenCthird.seq$i
    if [ -d  $PATH_HOME/results/scenCthird.seq$i ]
    then
        cd  $PATH_HOME/results/scenCthird.seq$i
        rm */comout*
        mv ../../mon_*.tar.bz2 .
        rep_euclid.sh
        rm -f */pacct*
        bzip2 */log* &
        cd $PATH_HOME
    fi
    i=`expr $i + 1`
#    sleep 2700
done
