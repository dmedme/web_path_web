# fdse_select.sh
# **********************************************************************
# Function to allow a user to select from a list of scenario executions
# Arguments:
# 1 - The Selection Header
#
# The Current PATH_SCENE 
#
# Returns:
# Scenario Executions in SE_LIST
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
se_select () {
    head=$1
    set -- $PATH_HOME/se/*.*
    if [ "$1" = "$PATH_HOME/se/*.*" ]
    then
        SE_LIST=""
    else
        SE_LIST=`(
echo HEAD=$head
echo PROMPT=Select Scenario Executions, and Press RETURN
echo SEL_YES/COMM_NO/SYSTEM
echo SCROLL
for j in \` ls -1d $PATH_HOME/se/*.* | sed 's=.*/==' \`
do
echo $j/$j
done
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
        eval set -- $SE_LIST
        if [ "$1" = " " -o "$1" = "EXIT:" ]
        then
            SE_LIST=""
        else
	    SE_LIST=$@
        fi
    fi
export SE_LIST
return 0
}
