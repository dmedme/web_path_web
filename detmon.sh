#!/bin/ksh
# detmon.sh - run system monitors appropriate for this system
# ************************************************
E2_HOME=.
export E2_HOME
# ************************************************
# Functions to manage the monitoring
# ************************************************
# Start
begin_stats() {
runref=$1
pid=$2
export pid
save_dir=$E2_HOME/save.$runref.$pid
export save_dir
mkdir $save_dir
chmod 0777 $save_dir
/usr/lib/sa/sadc 60 120 $save_dir/sad &
sad_pid=$!
vmstat 60 > $save_dir/vmout &
vm_pid=$!
iostat -xct 60 > $save_dir/ioout &
io_pid=$!
mpstat 60 > $save_dir/mpout &
mp_pid=$!
ps -ef > $save_dir/ps_beg
while :
do
    /usr/sbin/swap -s
    sleep 60
done > $save_dir/swap_stats &
swap_pid=$!
netstat -k > $save_dir/kstat_beg
netstat -m > $save_dir/strstat_beg
netstat -i -I bge1 60 >$save_dir/netout &
net_pid=$!
#su - oracle -c $E2_HOME/monscripts/perfdb/e2monitor.sh >/dev/null 2>&1 &
export sad_pid vm_pid io_pid swap_pid mp_pid net_pid
return
}
# ************************************************
# Function to terminate the monitors
#
end_stats() {
kill -15 $sad_pid $io_pid $vm_pid $swap_pid $mp_pid $net_pid $cap_pid $lock_pid
sleep 1
kill -9 $sad_pid $io_pid $vm_pid $swap_pid $mp_pid $net_pid $cap_pid $lock_pid
ps -ef > $save_dir/ps_end
cp /var/adm/pacct  $save_dir/pacct
netstat -k > $save_dir/kstat_end
netstat -m > $save_dir/strstat_end
return
}
# ****************************************************************************
# Main program starts here
#
runid=evision-v490
pid=1
while :
do
    if [ -d $E2_HOME/save.$runid.$pid ]
    then
        pid=`expr $pid + 1`
    else
        break
    fi
done
export runid
begin_stats $runid $pid
sleep 1800
end_stats
exit
