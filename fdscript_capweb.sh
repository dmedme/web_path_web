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
. $PATH_SOURCE/e2sync.sh
. $PATH_SOURCE/fdvi.sh
# *********************************************************
# Function to visualise a JSON script representation
visualise() {
jsonify json bothways/$1/$1.$PATH_EXT
echo "Content-type: text/html

<HTML>
<HEAD>
<TITLE>PATH Web Interface</TITLE>
<link rel=\"stylesheet\" type=\"text/css\" href=\"web_path_web/visualise.css\" />
<script src=\"web_path_web/visualise.js\" defer=\"false\"> 
</script>
<script>
function drawform() {
get_script(\"json.1\");
return true;
}
</script>
</HEAD>
<BODY bgcolor=\"#ffffff\" onLoad=\"drawform()\">
<CENTER>
<TABLE WIDTH=\"98%\" CELLSPACING=1 CELLPADDING=4 BORDER=1>
<TR><TD BGCOLOR=\"#50ffc0\">
<TABLE><TR><TD><A HREF=\"/\"><img src=\"web_path_web/e2tiny.gif\" alt=\"PATH\"></A>
</TD><TD>
<h3>Welcome to PATH 2016!</h3>
</TD>
</TR>
</TABLE>
<HR/>
</BODY>
</HTML>" |
        e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "visualise script ..."
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
echo 1>&2 "... visualise finished"
return
}
set -x
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCRIPT:  Test Script Management $curr
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
SUMMARY:    View a summary of each of the scripts/SUMMARY:
CAPTURE:    Capture a New Test Script/CAPTURE:
RESTORE:    Reprocess a captured network trace/RESTORE:
ONEWAYISE:  Prepare Scripts for Running/ONEWAYISE:
VISUALISE:  View a script in a structured manner/VISUALISE:
EDIT:       Manually Edit Test Scripts and related entities/EDIT:
E2SYNC:     Manually comment script/E2SYNC:
SINGLE:     Single Step Test Script Programs/SINGLE:
DELETE:     Delete Test Scripts/DELETE:
HELP:       Help/HELP:
EXIT:       Exit/EXIT:

HEAD=HELP:  SCRIPT Management Help
PARENT=SCRIPT:
PROMPT=Press RETURN to return
SEL_YES/COMM_YES/MENU
SCROLL
SUMMARY:     View a summary of each of the scripts/NULL:
CAPTURE:     Create a New Test Script/NULL:
    Create a brand new test script with network capture/NULL:
RESTORE:     Reprocess a captured network trace/NULL:
    Either reset a test script to default values, or use an pre-existing/NULL:
    network trace to create a new script./NULL:
ONEWAYISE:  Prepare Scripts for Running/NULL:
    Strip the responses out of a script to make it more manageable./NULL:
    The original is accessible in bothways./NULL:
VISUALISE:  View a script in a structured manner/NULL:
    View bothways scripts colour coded, and potentially with responses rendered as HTML rather than text./NULL:
EDIT:       Edit Test Script Programs/NULL:
    Select a number of test script component files to edit and edit them/NULL:
SINGLE:     Single Step Test Script Programs/NULL:
    Select a number of test script component files to run and single step them/NULL:
E2SYNC:     Comment a script/NULL:
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
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*IMPORT:*)
# Process an existing network file
#
    shift
    if [ $# -lt 6 ]
    then
        message_text="Insufficent details supplied"
        export message_text
    fi
    cd $PATH_HOME/scripts
    webscriptify.sh $* $E2_TRAFMUL_EXTRA
;;
*SUMMARY:*)
{
    echo "$html_head"
    (
    unset html_tail
    unset html_head
    for i in `find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^\\./ d
/^scripts$/ d
s=^scripts/=='`
    do
        echo "<h1>$i</h1>"
        sed -n '/^\\S/ {
s/^.[^:]*:120:\([^\\]*\)\\$/\1/
p
}' $PATH_HOME/scripts/$i/$i.msg | wbrowse -l "" -c "Script Step" -r -
    done
    )
    echo "$html_tail"
} | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
;;
*CAPTURE:*)
# Process a script file creation
#
    shift
    if [ $# -lt 2 ]
    then
        message_text="Insufficent details supplied"
        export message_text
        break
    fi
    sname=$1
    E2_USER_HOST=$2
    export E2_USER_HOST
    port_com="and '(' port 7"
    shift 2
    dir=$PATH_HOME/scripts/$sname
    if [ ! -d "$dir" ]
    then
        if mkdir "$dir"
        then
            :
        else
            echo Illegal script name | output_dispose "CAPTURE: Capture Script From Network"
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
    port_com=${port_com}" ')'"
    set -x
#    if [ "$PATH_OS" = SOLAR ]
#    then
#       sudo snoop -o $sname.snp host "$E2_USER_HOST" $port_com  and not port 23 and not port 22
#        sudo snoop -o $sname.snp host "$E2_USER_HOST" $port_com  and not port 23 and not port 22
#    elif [ "$PATH_OS" = NT4 ]
#    then
#        eval ntsnoop -f  \'host "$E2_USER_HOST" $port_com and not port 23\' $sname.snp
#    else
#
# Man-in-the-middle capture with stunnel4
#
#        /usr/sbin/tcpdump -i lo -s 0 -w $sname.trc port 7 or port 7100 &
eval   /usr/sbin/tcpdump -i $E2_CAP_IFACE -s 0 -w $sname.trc host "$E2_USER_HOST" $port_com and not port 23 and not port 22 &
tcpd_pid=$!
#    fi
    e2sync
    kill -15 $tcpd_pid
    aixdump2snp -o $sname.snp $sname.trc
#   rm $sname.trc
    webscriptify.sh $sname.snp ../$sname $E2_USER_HOST $E2_TRAFMUL_EXTRA
;;
*REGENERATE:*)
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
        message_text="No script supplied"
        export message_text
    fi
;;
*ONEWAYISE:*)
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^scripts$/d
/^\\./ d'`
    script_select "ONEWAYISE: Pick scripts to strip the responses from" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
        onewayise.sh $SCRIPT_LIST
        message_text="Scripts $SCRIPT_LIST onewayised"
        export message_text
    else
        message_text="No script supplied"
        export message_text
    fi
;;
*VISUALISE:*)
script_list=`find $PATH_HOME/bothways -type d -print 2>/dev/null | sed 's=.*/==
/^bothways$/d
/^\\./ d'`
    script_select "VISUALISE: Pick bothways scripts to visualise" "" "$script_list"
    cd $PATH_HOME
    if [ ! -z "$SCRIPT_LIST" ]
    then
        script_list=$SCRIPT_LIST
        for j in $script_list
        do
            visualise $j
        done
    else
        message_text="No script supplied"
        export message_text
    fi
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
*SINGLE:*)
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^scripts$/d
/^\\./ d'`
    script_select "SINGLE: Pick scripts to step through" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
    script_list=$SCRIPT_LIST
    for j in $script_list
    do
        cd $PATH_HOME/scripts/$j
        $PATH_DRIVER -m1 -s "$E2SINGLE_PORT" single 1 1 1 $j.$PATH_EXT &
        script_pid=$!
#
# Wait for the think time before attempting to access the browser
# 
        think_time=`head -1 $j.$PATH_EXT | sed 's=^..==
s=.$=='`
        think_time=`expr $think_time + $think_time`
        sleep $think_time
{
echo "$html_head"
cat << EOF
<h1>SINGLE: Single Step Script $j</h1>
<iframe src="http://127.0.0.1:$E2SINGLE_PORT" width=100% height=100%>
<p>Unable to embed the single step UI</p>.
</iframe>
<p>If the above iframe is empty, we probably haven't given the driver long enough to reach the first step.</p>
<p>You can wait and retry or you can create a new browser tab to access the driver directly, via "http://127.0.0.1:$E2SINGLE_PORT".
<p>In either case, click on the logo above when you or the script have finished.
EOF
    echo "$html_tail"
} >$PATH_HOME/script_out_fifo.$E2_WEB_PID
echo 1>&2 "single step script $j ..."
cat 1>&2 $PATH_HOME/script_in_fifo.$E2_WEB_PID
echo 1>&2 "... single step script $j finished"
        kill -15 $script_pid
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
    done
    else
        message_text="No script supplied"
        export message_text
    fi
;;
*E2SYNC:*)
    e2sync
;;
esac
cd $PATH_HOME
done
exit
