# fdtestsel.sh
# **********************************************************************
# Function to allow a user to select from a list of scenarios
# Arguments:
# 1 - The Selection Header
#
# Returns:
# System test definition files in TEST_LIST
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
test_select () {
head=$1
extra=$2
set -- $PATH_HOME/scenes/*
if [ "$1" = "$PATH_HOME/scenes/*" ]
then
TEST_LIST=""
else
TEST_LIST=`(
echo HEAD=$head
echo PROMPT=Select Scenarios, and Press RETURN
echo SEL_YES/COMM_NO/SYSTEM
echo SCROLL
{
if [ -z "$extra" ]
then
sel_str=
else
sel_str=\*
fi
    for j in \` ls -1d $PATH_HOME/scenes/* | sed 's=.*/==' \`
    do
        echo "$j" -
        head -1 $PATH_HOME/scenes/$j/ctl.txt
        echo /"$j"
    done
} | sed 'N
s.[/=#]. .g
N
s=\n= =g'
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
eval set -- $TEST_LIST
if [ "$1" = " " -o "$1" = "EXIT:" ]
then
    TEST_LIST=""
else
    TEST_LIST=$@
fi
fi
export TEST_LIST
return 0
}
