#!/bin/ksh
#!/bin/sh5
# fdscript.sh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
# Handle the script facilities. Called from fdpathweb.sh
# Read in the required functions
# set -x
. $PATH_SOURCE/fdvars.sh
. $PATH_SOURCE/fdscrisel.sh
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCRIPT:  Test Script Management $curr
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
CAPTURE:    Capture a New Test Script/CAPTURE:
RESTORE:    Reprocess a captured network trace/RESTORE:
EDIT:       Manually Edit Test Scripts and related entities/EDIT:
SHELL:      Escape to Shell/SHELL:
DELETE:     Delete Test Scripts/DELETE:
HELP:       Help/HELP:
EXIT:       Exit/EXIT:

HEAD=HELP:  SCRIPT Management Help
PARENT=SCRIPT:
PROMPT=Press RETURN to return
SEL_YES/COMM_YES/MENU
SCROLL
CAPTURE:     Create a New Test Script/NULL:
    Create a brand new test script with network capture/NULL:
RESTORE:     Reprocess a captured network trace/NULL:
    Either reset a test script to default values, or use an pre-existing/NULL:
    network trace to create a new script./NULL:
EDIT:       Edit Test Script Programs/NULL:
    Select a number of test script component files to edit/NULL:
SHELL:      Escape to The Shell/NULL: 
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
User IP :
Service Ports:

HEAD=RESTORE:    Reprocess a captured network trace/RESTORE:
PARENT=SCRIPT:
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
REGENERATE: Regenerate an existing script/REGENERATE:
IMPORT:     Generate from a pre-existing capture file/IMPORT:
EXIT:       Exit/EXIT:

HEAD=IMPORT: Create a new System Test Script from an Existing Network Trace
PARENT=RESTORE:
PROMPT=Fill in the details and Press RETURN
COMMAND=IMPORT:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Capture File Name :
Script Name :
User IP :

EOF
`
set -- $choice
case $1 in
EXIT:)
break
;;
IMPORT:)
# Process an existing network file
#
    shift
    if [ $# -lt 6 ]
    then
        echo  "Insufficent details supplied\c"
        sleep 1
    fi
    cd $PATH_HOME/scripts
    webscriptify.sh $* $E2_TRAFMUL_EXTRA
;;
CAPTURE:)
# Process a script file creation
#
    shift
    if [ $# -lt 2 ]
    then
        echo  "Insufficent details supplied\c"
        sleep 1
        break
    fi
    sname=$1
    E2_USER_HOST=$2
    port_com="and ( port 7"
    shift 2
    dir=$PATH_HOME/scripts/$sname
    if [ ! -d "$dir" ]
    then
        if mkdir "$dir"
        then
            :
        else
            echo Illegal script name
            exit
        fi
    fi
    cd $dir
    if [ -n "$*" ]
    then
        E2_WEB_PORTS=$E2_WEB_PORTS" $*"
        export E2_WEB_PORTS
    fi
#
# E2_ORA_WEB_PORTS may also be needed by webdump.
#
    port_com=$port_com`for i in $* $E2_WEB_PORTS $E2_ORA_WEB_PORTS
    do
        echo " or port $i"
    done`
    port_com=${port_com}" )"
    echo 'Capturing trace ... Type ^C when done'
    set -x
    if [ "$PATH_OS" = SOLAR ]
    then
#       sudo snoop -o $sname.snp host "$E2_USER_HOST" $port_com  and not port 23 and not port 22
        sudo snoop -o $sname.snp host "$E2_USER_HOST" $port_com  and not port 23 and not port 22
    elif [ "$PATH_OS" = NT4 ]
    then
        eval ntsnoop -f  \'host "$E2_USER_HOST" $port_com and not port 23\' $sname.snp
    else
#
# Man-in-the-middle capture with stunnel4
#
#        /usr/sbin/tcpdump -i lo -s 0 -w $sname.trc port 7 or port 7100
        /usr/sbin/tcpdump -i "$E2_CAP_IFACE" -s 0 -w $sname.trc host "$E2_USER_HOST" $port_com and not port 23 and not port 22
#        /usr/sbin/tcpdump -i "$E2_CAP_IFACE" -s 0 -w $sname.trc port 80 or port 7
        aixdump2snp -o $sname.snp $sname.trc
#        rm $sname.trc
    fi
    webscriptify.sh $sname.snp ../$sname $E2_USER_HOST $E2_TRAFMUL_EXTRA
    echo Press return to continue
    read x
;;
REGENERATE:)
# Restore a script to its default, just generated values
#
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^scripts$/d
/^\\./ d'`
    script_select "REGENERATE: Pick scripts to Regenerate" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
    for i in $SCRIPT_LIST
    do
        cd $PATH_HOME/scripts/$i
        (
        . ./capset.sh
        export E2_WEB_PORTS
        webscriptify.sh $i.snp ../$i $E2_USER_HOST $E2_TRAFMUL_EXTRA
        )
    done
    else
        echo  "No script supplied\c"
        sleep 1
    fi
;;
EDIT:)
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
        script_select "EDIT: Pick files to Manually edit" "" *
        if [ ! -z "$SCRIPT_LIST" ]
        then
        for i in $SCRIPT_LIST
        do
            $PATH_EDITOR $PATH_HOME/scripts/$j/$i
        done
        else
            echo  "No files selected\c"
            sleep 1
        fi
    done
    else
        echo  "No script supplied\c"
        sleep 1
    fi
;;
SHELL:)
clear
echo "Insert Shell Command and Press Return - Type exit to return to PATH" 
sh -
;;
DELETE:)
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
    done
    else
        echo  "No script supplied\c"
        sleep 1
    fi
;;
esac
cd $PATH_HOME
done
exit
