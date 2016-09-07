#!/bin/ksh
# @(#) $Name$ $Id$
# Copyright (c) 1993, 2001 E2 Systems Limited
#
# Handle the configuration of the test environment. Called from fdpathweb.sh.
#
# The config directory tree contains binaries and configuration information
# needed to construct self-extracting executables for remote distribution on
# different operating systems.
#
# The hosts directory tree contains information on the hosts that are going
# to participate in the tests. Much of this information comes from the config
# entries for the operating system.
#
# Facilities are provided for maintaining the list of available hosts.
#
#
# Read in the required functions
. $PATH_SOURCE/fdvars.sh
. $PATH_SOURCE/fdhostsel.sh
#
# Function to set or change the operating system for a host
#
os_update() {
    head=$1
    host=$2
    set -- $PATH_HOME/config/*
    if [ "$1" = "$PATH_HOME/config/*" ]
    then
        OS=""
    else
    OS=`(
echo HEAD=$head
echo PROMPT=Select Operating System, and Press RETURN
echo SEL_YES/COMM_NO/MENU
echo SCROLL
for j in \` ls -1d $PATH_HOME/config/* | sed 's=.*/==' \`
do
echo $j
echo /$j
done | sed 's.[/=#]. .g
N
s=\n= =g'
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
set -- $OS
eval OS=$1
        if [ "$OS" = " " -o "$OS" = "EXIT:" ]
        then
            OS=""
	else
            eval set -- $OS
	    OS=$@
        fi
        if [ ! -z "$host" -a ! -z "$OS" ]
        then
            if [ ! -d  $PATH_HOME/hosts/$host ]
            then
                mkdir $PATH_HOME/hosts/$host
            fi
            echo $OS > $PATH_HOME/hosts/$host/OS
            echo unknown > $PATH_HOME/hosts/$host/status
        fi
    fi
    return
}
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=CONFIG: Configure the Test Environment
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
ENVIRONMENT: Configuration Values/ENVIRONMENT:
VALIDATE:    Check the test directory environment, supplying missing elements/VALIDATE:
ADD:         Add hosts to the available list/ADD:
CHECK:       Check host status/CHECK:
AMEND:       Amend host details/AMEND:
VIEW:        View host details in a list/VIEW:
REMOVE:      Remove host details/DELETE:
EXIT:        Exit/EXIT:

HEAD=ENVIRONMENT: Configure the Test Environment
PARENT=CONFIG:
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
SETUP:       Set Configuration Values/SETUP:
EXTEND:      Extend Configuration Values/EXTEND:
KNOWN:       Lists Possible Configuration Values/KNOWN:

HEAD=ADD: Make a host available
PARENT=CONFIG:
PROMPT=Identify an available host
COMMAND=ADD:
SEL_NO/COMM_NO/SYSTEM
SCROLL
IP Address or Name :

EOF
`
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*SETUP:*)
    if [ "$PATH_WKB" = web ]
    then
    wbrowse -d web_path_web/path_dict.txt -c "NAME|VALUE" -p -t= web_path_web/pathenv.sh  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "edit pathenv.sh ..."
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
echo 1>&2 "... setup pathenv.sh finished"
    else
        echo If you are not using the Web interface you must edit pathenv.sh by hand
        sleep 5
    fi 
    ;;
*EXTEND:*)
    if [ "$PATH_WKB" = web ]
    then
    wbrowse -d web_path_web/path_dict.txt -c "Name|Value" -t= web_path_web/pathenv.sh  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "edit pathenv.sh ..."
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
echo 1>&2 "... extend pathenv.sh finished"
    else
        echo If you are not using the Web interface you must edit pathenv.sh by hand
        sleep 5
    fi 
    ;;
*KNOWN:*)
    if [ "$PATH_WKB" = web ]
    then
    wbrowse -r -d web_path_web/path_dict.txt -c "Name|Brief Description|Long Description" web_path_web/path_dict.txt  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "known pathenv.sh ..."
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
echo 1>&2 "... known pathenv.sh finished"
    else
        echo If you are not using the Web interface you must edit pathenv.sh by hand
        sleep 5
    fi 
    ;;
*ADD:*)
    shift
    if [ $# -gt 0 ]
    then
        host=$1
        os_update "ADD1: Specify the operating system for $host" $host
    else
        message_text="No Hosts Specified"
        export message_text
    fi
;;
*AMEND:*)
#
#  Accept a list of hosts
#
    host_sel "AMEND1: Choose the hosts you want to amend"
    if [ -z "$HOST_LIST" ]
    then
        message_text="No Hosts Selected"
        export message_text
    else
#
# Prompt for new operating systems
#
        for host in $HOST_LIST
        do
            os_update "AMEND1: Specify the operating system for $host" $host
        done
    fi
;;
*CHECK:*)
#
# Check whether hosts are alive or not
#
    host_sel "CHECK1: Choose the hosts you want to check"
    if [ -z "$HOST_LIST" ]
    then
        message_text="No hosts selected for checking"
    else
        message_text="Clock discrepancy: "`hostcheck.sh $HOST_LIST`
    fi
    export message_text
;;
*VALIDATE:*)
    if [ "$PATH_WKB" = tty ]
    then
    fdsetvalid.sh
    else
    {
    fdsetvalid.sh
#    link_missing.sh
    } | output_dispose
    fi
;;
*VIEW:*)
      (
echo HEAD=VIEW:       View a list of host details
echo PROMPT=Press RETURN when ready
echo SEL_YES/COMM_YES/MENU
echo SCROLL
for j in ` ls -1d $PATH_HOME/hosts/* `
do
host=`echo $j | sed "s=.*/==" `
OS=`cat $j/OS`
status=`cat $j/status`
echo $host $OS $status /NULL:
done
echo
) | natmenu 3<&0 4>/dev/null </dev/tty >/dev/tty
;;
*REMOVE:*)
#
# Delete an existing host
#
    host_sel "REMOVE1: Choose the hosts you want to remove"
    if [ -z "$HOST_LIST" ]
    then
        message_text="No hosts selected for removal"
        export message_text
    else
        for host in $HOST_LIST
        do
            rm -rf $PATH_HOME/hosts/$host
        done
    fi
;;
esac
if [ "$PATH_WKB" = tty -a -n "$message_text" ]
then
    echo "" $message_text "\c"
    sleep 5
fi
done
exit
