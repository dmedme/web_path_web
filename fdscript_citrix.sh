#!/bin/ksh
#!/bin/sh5
# fdscript_citrix.sh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
# Handle the script facilities. Called from fdpathweb.sh
# *********************************************************
# This version supports Citrix, so will only be used on Windows
# *********************************************************
# Read in the required functions
# set -x
. $PATH_SOURCE/fdvars.sh
. $PATH_SOURCE/fdscrisel.sh
. $PATH_SOURCE/e2sync.sh
. $PATH_SOURCE/fdvi.sh
# *********************************************************
# Function to set up the ancilliary stuff to do with a script
ready_script() {
dir=$1
shift
if [ ! -d "$dir" ]
then
    if mkdir "$dir"
    then
        :
    else
        echo Script name does not correspond to a directory
        return 1
    fi
fi
script=`basename $dir`
#
# Passed host addresses
#
E2_USER_HOST=127.0.0.1
export E2_USER_HOST
E2_WEB_PORTS=${E2_WEB_PORTS:-"80 87 88 50000"}
export E2_WEB_PORTS
# E2_ORA_WEB_PORTS should only be set if the Forms Servlet isn't in use
#E2_ORA_WEB_PORTS=${E2_ORA_WEB_PORTS:-7777}
#export E2_ORA_WEB_PORTS
E2_ORA_TUNNEL_PORTS=${E2_ORA_TUNNEL_PORTS:-7777}
export E2_ORA_TUNNEL_PORTS
#E2_T3_WEB_PORTS=${E2_T3_WEB_PORTS:-8001}
#export E2_T3_WEB_PORTS
PATH_EXT=${PATH_EXT:-rec}
export PATH_EXT
echo E2_USER_HOST=$E2_USER_HOST >$dir/capset.sh
echo E2_WEB_PORTS=\"$E2_WEB_PORTS\" >>$dir/capset.sh
echo E2_ORA_TUNNEL_PORTS=\"$E2_ORA_TUNNEL_PORTS\" >>$dir/capset.sh
    echo 10 $script 20 ${PATH_THINK:-5} there must be four >$dir/client.run
return 0
}
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCRIPT:  Test Script Management $curr
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
CAPTURE:    Capture a New Test Script/CAPTURE:
EDIT:       Manually Edit Test Scripts and related entities/EDIT:
VI:         Manually Edit Test Scripts and related entities with vi/VI:
LAUNCH:     Simply Launch ATLIco, the Citrix Driver/LAUNCH:
DELETE:     Delete Test Scripts/DELETE:
HELP:       Help/HELP:
EXIT:       Exit/EXIT:

HEAD=HELP:  SCRIPT Management Help
PARENT=SCRIPT:
PROMPT=Press RETURN to return
SEL_YES/COMM_YES/MENU
SCROLL
CAPTURE:     Create a New Test Script/NULL:
    Create a brand new test script using proxy capture/NULL:
EDIT:       Edit Test Script Programs/NULL:
    Select a number of test script component files to edit and edit them/NULL:
VI:         Edit Test Script Programs with vi/NULL:
    Select a number of test script component files to edit and edit them/NULL:
LAUNCH:     Simply Launch ATLIco, the Citrix Driver/NULL:
    Launch the Citrix Driver for test run or other purposes/NULL:
DELETE:     Delete Test Scripts/NULL:
    Select a number of test scripts to purge/NULL:
HELP:       Help/NULL:
    Display this message/NULL:

HEAD=CAPTURE: Create a new System Test Script
PARENT=SCRIPT:
PROMPT=Fill in the details and Press RETURN
COMMAND=CAPTURE:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Capture Name :

EOF
`
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*CAPTURE:*)
# Process a script file creation
#
    shift
    if [ $# -lt 1 ]
    then
        message_text="Insufficent details supplied"
        export message_text
        break
    fi
    dir=$1
    cd $PATH_HOME/scripts
    if ready_script $dir
    then
        cd $PATH_HOME/scripts/$dir
	cp $PATH_HOME/ica/healthcare@home.ica $dir.ica
	export E2_SCRIPT=$PATH_HOME/scripts/$dir/$dir.$PATH_EXT
	export E2_BROWSER=172.23.23.172
	export E2_USERNAME=load.test1
	export E2_ICAFILE=$PATH_HOME/scripts/$dir/$dir.ica
        ATLIco
#
	mv $PATH_HOME/*.bmp .
{
	echo "$html_head"
	sed "1,53 d
s=//c:/e2/=scripts/$dir/=g" $dir.$PATH_EXT.html 
} | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
	ex $dir.$PATH_EXT.html << EOF
g=//c:/e2/=s===g
w
q
EOF
    fi
    sname=$dir
;;
*LAUNCH:*)
	export E2_BROWSER=172.23.23.172
	export E2_USERNAME=load.test1
	ATLIco
;;
*EDIT:*)
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^scripts$/d
/^\\./ d'`
    script_select "EDIT: Pick scripts to Manually edit" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
    script_list=$SCRIPT_LIST
    for j in $script_list
    do
        cd $PATH_HOME/scripts/$j
        script_select "EDIT: Pick files to manually edit" "" *
        if [ ! -z "$SCRIPT_LIST" ]
        then
            for i in $SCRIPT_LIST
            do
                $PATH_EDITOR $PATH_HOME/scripts/$j/$i
            done
        else
            message_text="No files selected"
            export message_text
        fi
    done
    else
        message_text="No script supplied"
        export message_text
    fi
;;
*VI:*)
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^scripts$/d
/^\\./ d'`
    script_select "VI: Pick scripts to Manually edit with vi" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
    script_list=$SCRIPT_LIST
    for j in $script_list
    do
        cd $PATH_HOME/scripts/$j
        script_select "VI: Pick files to manually edit with vi" "" *
        if [ ! -z "$SCRIPT_LIST" ]
        then
            gvim $SCRIPT_LIST &
        else
            message_text="No files selected"
            export message_text
        fi
    done
    else
        message_text="No script supplied"
        export message_text
    fi
;;
*DELETE:*)
#
# Delete script files
#
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^\\./ d
/^scripts$/ d'`
    
    script_select "DELETE: Pick scripts to delete" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
    for i in $SCRIPT_LIST
    do
        rm -rf $PATH_HOME/scripts/$i
        rm -rf $PATH_HOME/bothways/$i
    done
    else
        message_text="No script supplied"
        export message_text
    fi
;;
esac
cd $PATH_HOME
if [ "$PATH_WKB" = tty -a -n "$message_text" ]
then
    echo "" $message_text "\c"
    sleep 5
fi
done
exit
