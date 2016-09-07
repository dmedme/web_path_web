# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 2001
#
# Function to generate a user patch script. Run in the source directory
gen_patch_nlb() {
cnt=`ls echo* | wc -l`
$PATH_AWK 'NR <= '$cnt' { print $0>"used.lis" ; next }
{ print $0>"not_used.lis"}' $PATH_HOME/data/USEREDITS.dat
mv "not_used.lis"  $PATH_HOME/data/USEREDITS.dat
ls echo* |$PATH_AWK 'END {
printf "del res*.bz2\r\n"
}
{ targ = $0
getline<"used.lis"
l = length($0)
gsub("\"","\\\"",$0)
    lgn = $0
    cmd = "fhunt -a '\''Connect 172.23.23.172'\'' " targ
    while((cmd|getline)>0)
    {
        print "mempat -s \"" lgn "\" " ($NF+0) " " targ "\r"
        printf "mempat -x 0D0A23 %d %s\r\n",($NF + l),targ
    }
    close(cmd)
}' >patch_nlb.bat
return
}
#
# Function to distribute scripts ready for execution
#
# Parameters:
# 1 - (F)ull binary (including executables) or (R)emote copy
# 2 - The scenario incarnation
#
trafdist() {
    if [ "$1" = F ]
    then
        full=Y
    else
        full=n
    fi
    cp $PATH_HOME/data/USEREDITS.dat.sav $PATH_HOME/data/USEREDITS.dat
    runid=$2
    pid=`echo $runid | sed 's/\..*$//'`

    targs=`ls -1d $PATH_HOME/se/$runid/*/*`
    if [ ! -z "$targs" ]
    then
        for d in $targs
        do
            if [ -d $d ]
            then
                cd $d
		gen_patch_nlb
                host_ip=`echo $d | sed 's=.*/=='`
#
# minitest command invocations may be asynchronous, hence the naff sleeps
#
                sleep 5
                if [ $full = Y ]
                then
#
# Complete binary distribution; obtain the program components that are needed,
# and create a self-extracting executable using the instructions in the OS
# config directory
#
                    os=`cat $PATH_HOME/hosts/$host_ip/OS`
                    comps=`ls $PATH_HOME/config/$os/dist`
                    cp $PATH_HOME/config/$os/dist/* .
                    chmod +x $comps
                    oname=`cat $PATH_HOME/config/$os/distname`
                    rm -f $oname
                    miniarc m $oname $PATH_HOME/config/$os/dist/`cat $PATH_HOME/config/$os/extractor`  `cat $PATH_HOME/config/$os/def_dir`  `cat $PATH_HOME/config/$os/setup`  $comps runout$pid* echo$pid*
                    if minitest $host_ip $E2_HOME_PORT COPY $oname $oname </dev/null
                    then
                        echo alive > $PATH_HOME/hosts/$host_ip/status
                        if [ $os != windows ]
                        then
                            minitest $host_ip $E2_HOME_PORT EXEC chmod +x $oname </dev/null
                        fi
                        sleep 1
                        minitest $host_ip $E2_HOME_PORT EXEC $oname </dev/null
                    else
                        echo dead > $PATH_HOME/hosts/$host_ip/status
                    fi
                else
                    rm -f dist$pid.tar dist$pid.tar.bz2
                    if [ "$host_ip" = "$E2_HOME_HOST" ]
                    then
                        cp runout$pid* echo$pid* patch_nlb.bat $PATH_HOME/work
                        (
                           cd $PATH_HOME/work
#                           ./patch_nlb.sh
                        minitest $host_ip $E2_HOME_PORT EXEC "patch_nlb.bat" </dev/null &
                        ) &
                    else
#                        miniarc c - runout$pid* echo$pid* | gzip -1 | 
#                             minitest $host_ip $E2_HOME_PORT EXEC "gzip -d | miniarc x -"
#                        minitest $host_ip $E2_HOME_PORT EXEC "patch_nlb.sh" </dev/null &
                        miniarc c - runout$pid* echo$pid* patch_nlb.bat |
                             minitest $host_ip $E2_HOME_PORT EXEC "miniarc x -"
#                        minitest $host_ip $E2_HOME_PORT EXEC "patch_nlb.sh" </dev/null &
                        minitest $host_ip $E2_HOME_PORT EXEC "patch_nlb.bat" </dev/null &
                    fi
#                    miniarc c dist$pid.tar runout$pid* echo$pid*
#                   if [ "$host_ip" = "$E2_HOME_HOST" ]
#                   then
#                        minitest $host_ip $E2_HOME_PORT COPY dist$pid.tar dist$pid.tar </dev/null
#                        echo alive > $PATH_HOME/hosts/$host_ip/status
#                        minitest $host_ip $E2_HOME_PORT EXEC "miniarc x dist$pid.tar" </dev/null
#                        minitest $host_ip $E2_HOME_PORT EXEC "patch_nlb.sh" </dev/null &
#                   else
#                   bzip2 dist$pid.tar
#                   if minitest $host_ip $E2_HOME_PORT COPY dist$pid.tar.bz2 dist$pid.tar.bz2 </dev/null
#                   then
#                       echo alive > $PATH_HOME/hosts/$host_ip/status
#                       sleep 1
#                       minitest $host_ip $E2_HOME_PORT EXEC "bzip2 -d -f dist$pid.tar.bz2" </dev/null
#                       sleep 1
#                       minitest $host_ip $E2_HOME_PORT EXEC "miniarc x dist$pid.tar" </dev/null
#                   else
#                       echo dead > $PATH_HOME/hosts/$host_ip/status
#                   fi
#                   fi
                fi
            fi
        done
    fi
    return
}
