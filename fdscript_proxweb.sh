#!/bin/ksh
#!/bin/sh5
# fdscript.sh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
# Handle the script facilities. Called from fdpathweb.sh
# *********************************************************
# This version uses the new proxy capability
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
if [ ! -d $dir/../../bothways/$script ]
then
    if mkdir $dir/../../bothways/$script
    then
        :
    else
        echo Script name does not correspond to a directory
        return 1
    fi
fi
#
# Passed host addresses
#
E2_USER_HOST=$E2_HOME_HOST
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
PATH_EXT=${PATH_EXT:-msg}
export PATH_EXT
echo E2_USER_HOST=$E2_USER_HOST >$dir/capset.sh
echo E2_WEB_PORTS=\"$E2_WEB_PORTS\" >>$dir/capset.sh
echo E2_ORA_TUNNEL_PORTS=\"$E2_ORA_TUNNEL_PORTS\" >>$dir/capset.sh
    echo 10 $script 20 ${PATH_THINK:-5} there must be four >$dir/client.run
cp $dir/capset.sh $dir/client.run $dir/../../bothways/$script
return 0
}
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
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCRIPT:  Test Script Management $curr
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
SUMMARY:    View a summary of each of the scripts/SUMMARY:
CAPTURE:    Capture a New Test Script/CAPTURE:
RESTORE:    Reprocess a script/RESTORE:
VISUALISE:  View a script in a structured manner/VISUALISE:
EDIT:       Manually Edit Test Scripts and related entities/EDIT:
VI:         Manually Edit Test Scripts and related entities with vi/VI:
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
    Create a brand new test script using proxy capture/NULL:
RESTORE:     Reprocess a captured network trace/NULL:
    Reset a test script to default values/NULL:
VISUALISE:  View a script in a structured manner/NULL:
    View bothways scripts colour coded, and potentially with responses rendered as HTML rather than text./NULL:
EDIT:       Edit Test Script Programs/NULL:
    Select a number of test script component files to edit and edit them/NULL:
VI:         Edit Test Script Programs with vi/NULL:
    Select a number of test script component files to edit and edit them/NULL:
SINGLE:     Single Step Test Script Programs/NULL:
    Select a number of test script component files to run and single step them/NULL:
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

HEAD=RESTORE:    Reprocess a captured trace/RESTORE:
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
Script Name :
File Name :

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
    if [ $# -lt 2 ]
    then
        message_text="Insufficent details supplied"
        export message_text
    else
    cd $PATH_HOME/scripts
    dir=$1
    src=$2
    if ready_script $dir
    then
        cd $dir
        (
        unset E2_BOTH E2_VERBOSE
        ungz $src $dir.$PATH_EXT
        )
        cd ../../bothways/$dir
        ungz $src $dir.$PATH_EXT
    fi
    fi
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
    if [ $# -lt 1 ]
    then
        message_text="Insufficent details supplied"
        export message_text
    else
    inuse=`netstat -n -a | egrep "tcp.*:($E2SINGLE_PORT|$E2_PROXY_PORT)"`
    if [ -n "$inuse" ]
    then
        message_text="Script Capture Ports $inuse still in use"
        export message_text
    else
    dir=$1
    cd $PATH_HOME/scripts
    if ready_script $dir
    then
        cd $PATH_HOME/bothways/$dir
        $PATH_DRIVER -p "$E2_PROXY_PORT" -s "$E2SINGLE_PORT" $dir.$PATH_EXT &
        script_pid=$!
{
echo "$html_head"
cat << EOF
<h1>CAPTURE: Capture $dir using the in-built proxy</h1>
<iframe src="http://$E2_USER_HOST:$E2SINGLE_PORT" width=100% height=100%>
<p>Unable to embed the capture UI</p>.
</iframe>
<p>If the above iframe is empty, we probably haven't given the driver long enough to start.</p>
<p>You can wait and retry or you can create a new browser tab to access the driver directly, via "http://$E2_USER_HOST:$E2SINGLE_PORT".</p>
<p>In either case, click on the logo above when you have finished the script.</p>
<p>For the capture to work, you must have manually set the HTTP proxy to $E2_USER_HOST port $E2_PROXY_PORT and selected 'Do not use proxy for ' and provided $E2_USER_HOST.</p>
EOF
    echo "$html_tail"
} | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "Capture script $dir via proxy $E2_PROXY_PORT ..."
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
echo 1>&2 "... script $dir capture finished"
        kill -15 $script_pid
        while ps -p $script_pid
        do
            sleep 1
        done
        cd $PATH_HOME/scripts/$dir
        (
        unset E2_BOTH E2_VERBOSE
        ungz ../../bothways/$dir/$dir.$PATH_EXT $dir.$PATH_EXT
        )
    fi
    sname=$dir
    fi
    fi
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
        unset E2_BOTH E2_VERBOSE
        ungz ../../bothways/$i/$i.$PATH_EXT $i.$PATH_EXT
        )
    done
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
<iframe src="http://$E2_USER_HOST:$E2SINGLE_PORT" width=100% height=100%>
<p>Unable to embed the single step UI</p>.
</iframe>
<p>If the above iframe is empty, we probably haven't given the driver long enough to reach the first step.</p>
<p>You can wait and retry or you can create a new browser tab to access the driver directly, via "http://$E2_USER_HOST:$E2SINGLE_PORT".
<p>In either case, click on the logo above when you or the script have finished.
EOF
    echo "$html_tail"
} | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "single step script $j ..."
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
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
