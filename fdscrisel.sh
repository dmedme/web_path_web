# fdscrisel.sh
# **********************************************************************
# Include this file in a script from which it is to be used.
#
# Function to allow a user to select from a list of scripts
# Arguments:
# 1 - The Selection Header
# 2 - The list of scripts
#
# Returns:
# List of script ids in SCRIPT_LIST
#
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
script_select () {
head=$1
shift
extra=$1
shift
if [ "$1" = "" -a "$extra" = "" ]
then
SCRIPT_LIST=""
else
SCRIPT_LIST=`(
echo HEAD=$head
echo PROMPT=Select Scripts, and Press RETURN
echo SEL_YES/COMM_NO/SYSTEM
echo SCROLL
{
    if [ -z "$extra" ]
    then
        sel_str=
    else
        sel_str=\*
    fi
#
# Provide support for eg. an All selection
#
    for i in $*
    do
        echo  "$i/$sel_str$i"
    done
    if [ ! -z "$extra" ]
    then
    for i in \`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^\\./ d
/^scripts$/ d'\`
    do
        while :
        do
            for j in $*
            do
                if [ "$i" = "$j" ]
                then
                    break 2
                fi
            done
            echo "$i/$i"
            break
        done
    done
    fi
}
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
eval set -- $SCRIPT_LIST
if [ "$1" = " " -o "$1" = "EXIT:" ]
then
    SCRIPT_LIST=""
else
    SCRIPT_LIST=$@
fi
fi
export SCRIPT_LIST
return 0
}
