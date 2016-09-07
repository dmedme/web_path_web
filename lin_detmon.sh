#!/bin/ksh
# lin_detmon.sh - run system monitors appropriate for this system
# ************************************************
# Options to control the monitoring
if [ $# -gt 0 ]
then
    sleep_time=$1
    if [ $# -gt 1 ]
    then
        out_name=$2
        if [ $# -gt 2 ]
        then
            out_port=$3
        else
            out_port=
        fi
    else
        out_name=
        out_port=
    fi
else
    sleep_time=3600
    out_name=
    out_port=
fi
E2_HOME=.
export E2_HOME
export PATH=`pwd`:/sbin:/usr/sbin:$PATH
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
vmstat 60 > $save_dir/vmout &
vm_pid=$!
iostat -x -d -k 60 > $save_dir/ioout &
io_pid=$!
mpstat -P ALL 60 > $save_dir/mpout &
mp_pid=$!
ps -ef > $save_dir/ps_beg
linnetmon.sh eth0 60 >$save_dir/netout &
net_pid=$!
export vm_pid io_pid swap_pid mp_pid net_pid
return
}
# ************************************************
# Function to terminate the monitors
#
end_stats() {
kill -15 $io_pid $vm_pid $mp_pid $net_pid
sleep 5
kill -9 $io_pid $vm_pid $mp_pid $net_pid
ps -ef > $save_dir/ps_end
cp /var/log/pacct  $save_dir/pacct
return
}
# ****************************************************************************
# Main program starts here
#
runid=kb-cmt-x86-1
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
/bin/sleep $sleep_time
end_stats
tar cf s_$runid.$pid.tar save.$runid.$pid
rm -rf save.$runid.$pid
if [ -n "$out_name" ]
then
    bzip2 < s_$runid.$pid.tar >$out_name
    rm s_$runid.$pid.tar
    if [ -n "$out_port" ]
    then
#        minitest localhost $out_port EXEC "cat > $out_name" <$out_name
        uuencode $out_name
    fi
else
    rm -f s_$runid.$pid.tar.bz2
    bzip2 s_$runid.$pid.tar
fi
exit
