# **********************************************************************
# Function to allow a user to select from a list of hosts
# Arguments:
# 1 - The Selection Header
#
# The Current PATH_SCENE 
#
# Returns:
# Hosts in HOST_LIST
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993, 2001
#
host_sel () {
    head=$1
    set -- $PATH_HOME/hosts/*
    if [ "$1" = "$PATH_HOME/hosts/*" ]
    then
        HOST_LIST=""
    else
        HOST_LIST=`(
echo HEAD=$head
echo PROMPT=Select Hosts, and Press RETURN
echo SEL_YES/COMM_NO/SYSTEM
echo SCROLL
for j in \` ls -1d $PATH_HOME/hosts/* | sed 's=.*/==' \`
do
echo $j
echo /$j
done | sed 's.[/=#]. .g
N
s=\n= =g'
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
eval set -- $HOST_LIST
        if [ "$1" = " " -o "$HOST_LIST" = "EXIT:" ]
        then
            HOST_LIST=""
        else
            HOST_LIST=$@
        fi
    fi
export HOST_LIST
return 0
}
