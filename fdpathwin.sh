#!/bin/ksh
# fdpathweb.sh - Menu of options for Path Web Application Testing.
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
# ***************************************************************************
# Parameters : None
#
# The directory structure is as follows
#
# The base for the tests is a directory, PATH_HOME.
#
# Below this are six sub-directories (seven if the PATH programs are placed in
# the same directory tree)
# - scripts
#   -  Contains the script directories, one per script (see below)
# - binaries
#   -  Contains the components needed for creating distributions for
#      different operating systems, one sub-directory per operating system.
# - hosts
#   -  Contains information about the hosts that are available
# - scenes
#   -  Contains scenario details (see below)
# - se
#   The base for executing multi-user tests.
# - work
#   The current directory for a test in progress (so there can only be one of
#   them active at a time). In addition, results from runs go in sub-directories
#   here.
#
# There are Scenarios, Scenario Executions, Runs, and Scripts.
# - Scenarios live in sub-directories of the scenes directory, one per
#   scenario. A scenario at the highest level consists of a list of scripts.
#   Each script implies the need for client, app_server, db_server etc. (see
#   below). The scenario assigns numbers of users, numbers of transactions,
#   numbers of steps, step duration and work intensity for the script clients
#   that it is proposed will participate in the scenario, and identifies the
#   hosts for the supporting roles. At the top level, the clients are identified
#   'en masse'; they then need to be shared out amongst participating client
#   hosts. So the scenes directory contains, for each scenario, a control file
#   that indicates:
#      - The number of steps and the step duration
#      - For each script
#        -  The script name
#        -  Once for each step
#           - The number of users
#           - The work intensity
# - Scripts live in sub-directories of the scripts directory, one per script
#   The sub-directory contains:
#   -  The raw network capture (usually scriptname.snp)
#   -  The actual script file (scriptname.msg)
#   -  The parameters for webscriptify.sh (capset.sh)
#   -  The narratives added with e2sync (narr.txt)
#   -  runout file fragments, needed for building scenarios that incorporate
#      the scripts (client.run, app_server.run, db_server.run or more generally
#      ipaddress.run; one per host needed to act out the script)
#
#   We are processing the file with webdump, so do not have narr.txt.
#   If we also processed it with ipscriptify.sh, we could then use ipdanal to
#   give us a second-by-second portrayal of the traffic between each identified
#   host. However, we would then have the hassle of keeping the two in step.
#
# Scenario Execution is based in the se directory. There are, broadly speaking,
# five phases that need to be gone through:
# - Selecting the scenario for execution, which leads to the creation of
#   a new directory in se, named scenario_name.sequence. Within this
#   sub-directory, further sub-directories are created:
#   -  A sub-directory for the client, and one sub-directory for each supporting
#      role (eg. app_server, db_server)
#   -  The supporting role subdirectories contain a runout file, constructed
#      by concatenating the role.run files for the participating scripts
#   -  The client sub-directory also contains runout files, one per step,
#      generated from the scenario control file.
# - Assigning hosts to roles
#   -  The hosts need to be allocated from the list of available hosts, whose
#      status might be managed by worldrun?
#   -  For the non-client roles, identifying the hosts is sufficient; a
#      sub-directory is created for each host so identified, that will be
#      used as a communication holding area, and the runout file will be
#      copied there from the directory above
#   -  For the clients, it is more complicated
#      -  Each client needs to be given a share of the total number of users
#         identified for each script for each stagger
#      -  The hosts that will be used for each subsidiary role have to be
#         identified as well, so that the script end points can be adjusted
#         when the scripts are generated
#      -  Some fast-track facilities, to share work equally, or set up a client
#         in exactly the same way as another client, are required
#      -  However, just as for the non-client roles, each host gets its own
#         directory
# - Scenario generation
#   -  This needs to be done once for each combination of non-client-roles
#      and hosts (so that the End Points are edited correctly); perhaps we
#      actually maintain the end points and the script body separately.
#   -  There needs to be an appropriate copy of pathenv.sh (which minitest
#      perhaps should re-read if available on scenario start-up, but it
#      doesn't at present; this means that the name of the script driver,
#      and the delay between starting new client processes, is fixed)
#   -  The runout file names need to conform to the PATH standard, that is
#      runout$scenario_id, runout${scenario_id}_1, runout${scenario_id}_2 etc..
#   -  The generated script names need to conform to the PATH standard, that is
#      echo$scenario_id.$bundle.0
# - Scenario distribution
#   -  To minimise the software that is installed on each client, and to
#      simplify management, distribution is managed from the centre. There
#      are two options:
#      -  uploading a bzip2-compressed archive of the runout file and echo
#         files using the minitest running on the client. There will be
#         an option that goes through all the host sub-directories and tries
#         to get the data transfered over, uncompressed and unpacked.
#      -  using a self-extracting executable containing everything; the
#         executable programs, and the scripts. The generation process has to
#         be aware of the target hardware architecture and operating system of
#         the hosts so targetted; physical distribution can be achieved by
#         E-mail, CD-ROM or floppy disk.
# - Scenario running
#   -  A new results directory is created for each run in the 'work' directory
#   -  The non-client hosts are targetted first. minitest will process the
#      scenario. The scenario run time for the non-client scenario executions
#      needs to be at least ((number of clients) * $PATH_STAGGER + (number of
#      steps) * (step length)).
#   -  The client hosts are then hit in turn. It suggests that $PATH_STAGGER
#      ought to take account of the number of such hosts.
#   -  minitest on each participating host processes the runout file and
#      manages the stagger
#   -  Some provision ought to be made for system monitoring?
#   -  At the end of the run, the clients are supposed to return their results
#      automatically.
#   -  A long stop process on the controlling host will attempt to get back
#      results from any clients that fail to deliver the results themselves
#   -  The raw results will have to be pre-processed by ipdanal (which does
#      interesting things with log files and runout files), fdreport and
#      sarprep (for any other monitoring output). This step will take place
#      automatically at the end of the run
#
# Result reporting
# - Formal reporting will be carried out using Microsoft Office Excel macros
#   or Web Pages using gnuplot and embedding the output in web pages
# - Can use minitest again to pull across results
# - minitest needs to be locked down further. Currently it allows any action
#   its user ID (which may well be root!) permits, to be triggered by anyone
#   who has access to a copy of it and knows its command syntax and listening
#   port and who can spoof one of the valid IP addresses.
#   
set -x
PATH_SOURCE=${PATH_SOURCE:-/c/e2/web_path_web}
export PATH_SOURCE
if [ ! -f $PATH_SOURCE/fdvars.sh ]
then
    echo "No PATH source files in designated PATH SOURCE directory"
    exit 1
fi
. $PATH_SOURCE/fdvars.sh
cd $PATH_HOME
port=${1:-$E2MENU_PORT}
# ****************************************************************************
# Function to render a runout file
# ****************************************************************************
# E2 Systems Network Benchmark Control Script Fri Sep 12 11:16:24 BST 2008
# Users Script Transactions Think Actor Unused_1 Unused_2 Unused_3
# ===== ====== ============ ===== ===== ======== ======== ========
# 50 post_grad_app 3 10 0 must be present
render_runout() {
run_file=$1

    $PATH_AWK 'BEGIN {
       run_file="'$run_file'"
       getline
       printf "<p onMouseOver=\"shoh('\''%s'\'')\"  onMouseOut=\"shoh('\''%s'\'')\">%s\r\n", run_file, run_file, $0
       getline
       getline
       printf "<table style=\"background-color:white;display:none;\" id=\"%s\" name=\"%s\" cellpadding='\''1'\'' cellspacing='\''1'\'' border='\''1'\''>\r\n",run_file,run_file
       printf "<tr><th>Script</th><th>Users</th><th>Cycles</th><th>Events</th><th>Think Time</th><th>Expected Run Time</th></tr>\r\n"
}
NF == 8 {
    script=$2
    users=$1
    trans=$3
    think=$4
    "grep -c '\''^\\\\S'\'' $PATH_HOME/scripts/" script "/" script ".$PATH_EXT"|getline
    ev_cnt = $0
    printf "<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td></tr>\r\n",script,users,trans,ev_cnt,think,(ev_cnt*think)
}
END {
    printf "</table></p>\r\n"
}' $run_file
    return
}
# ****************************************************************************
# Main Program Starts Here
# VVVVVVVVVVVVVVVVVVVVVVVV
if [ "$PATH_WKB" = web ]
then
    if [ ! "$PATH_OS" = NT4 ]
    then
        rm -f $PATH_HOME/script_in_fifo.$E2_WEB_PID $PATH_HOME/script_out_fifo.$E2_WEB_PID $PATH_HOME/web_fifo.$E2_WEB_PID
        mkfifo $PATH_HOME/script_out_fifo.$E2_WEB_PID
    fi
# *************************************************************************
# First thread; loop servicing HTTP Requests
# *************************************************************************
# minitest -w is a sub-minimal HTTP server ... Single threaded, no access
# controls, relies on named pipes to present it with things.
#
        set -x
#
# The output from each dynamic request is passed as an input line to
# script_in_fifo. There should be one incarnation of this per form.
#
        minitest -d 4 -w $port -i ${NAMED_PIPE_PREFIX}web_fifo.$E2_WEB_PID -o ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID > minitest.log 2>&1 &
        server_thread=$!
        if [ ! "$PATH_OS" = NT4 ]
        then
            until [ -p $PATH_HOME/web_fifo.$E2_WEB_PID -a -p $PATH_HOME/script_in_fifo.$E2_WEB_PID ]
            do
                sleep 1
            done
        fi
#
# Discard the first response from the webserver
#
        e2fifin ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
#
# Re-direct output from the shell scripts to a file, and pass the name of
# that file to the web server.
#
        while :
        do
            e2fifin ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID >$PATH_HOME/tmp$E2_WEB_PID.tmp
            echo $PATH_HOME/tmp$E2_WEB_PID.tmp
#
# Wait for the previous incarnation to be displayed
#
            while [ -f $PATH_HOME/tmp$E2_WEB_PID.tmp ]
            do
                sleep 1
            done
        done | e2fifout ${NAMED_PIPE_PREFIX}web_fifo.$E2_WEB_PID &
        web_thread=$!
else
# Settings for dumb terminal
stty intr \ susp \ quit \
trap "" 2 3
fi
#
# ***************************************************************************
# Main program - process user requests until exit
#
while :
do
NOW=`date`
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=MAIN:  Test Management at $NOW
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
CONFIGURE:    Manage Test Environment/CONFIGURE:
PROGRESS:     Track Project Progress/PROGRESS:
SCRIPT:       Manage Test Scripts/SCRIPT:
DATA:         Manage Test Data/DATA:
SCENARIO:     Manage Test Scenarios/SCENARIO:
EXECUTE:      Manage Test Scenario Execution/EXECUTE:
RESULTS:      Textual and Graphical Presentations/RESULTS:
HELP:         Help/HELP:
EXIT:         Exit/EXIT:

HEAD=HELP:  Test Management Help
PARENT=MAIN:
PROMPT=Press RETURN to return
SEL_YES/COMM_YES/MENU
SCROLL
CONFIGURE:  Manage Test Environment/NULL:
    Maintain participating hosts, etc./NULL:
PROGRESS:   Track Project Progress/NULL:
    Track the progress of the Load Test Exercise/NULL:
SCRIPT:     Maintain Test Scripts/NULL:
    Script capture and refinement/NULL:
DATA:       Manage Test Data/NULL:
    Dump SQL database data into flat files and/NULL:
    manage the resulting test data files/NULL:
SCENARIO:   Manage Test Scenarios/NULL:
    Create scenarios defined as numbers of users executing scripts/NULL:
EXECUTE:    Manage Scenario Execution/NULL:
    Anything to do with Execution of Scenarios/NULL:
    Assignment of hosts to the Scenario, generation, distribution, running/NULL:
RESULTS:      Textual and Graphical Presentations/NULL:
    Access to test results and performance monitor output/NULL:

EOF
`
message_text=
export message_text
case "$choice" in
*EXIT:*)
    break 2
;;
*CONFIGURE:*)
    fdconfig.sh
;;
*PROGRESS:*)
if [ "$PATH_WKB" = tty ]
then
    cat $PATH_SOURCE/benchmeth.txt
    echo Press RETURN to continue
    read x
else
{
    echo "Content-type: text/html
"
    cat $PATH_HOME/data/project.html
} | 
        e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
echo 1>&2 "Progress Check List Open ..."
        e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
    echo 1>&2 "Progress Check List finished"
fi
;;
*SCRIPT:*)
    $FDSCRIPT
;;
*DATA:*)
if [ "$PATH_WKB" = tty ]
then
    echo "Data browsing is only supported via the Web interface\c"
    sleep 5
else
    fddata.sh
fi
;;
*SCENARIO:*)
    fdscene.sh
;;
*EXECUTE:*)
    fdexecute.sh
;;
*RESULTS:*)
if [ "$PATH_WKB" = tty ]
then
    echo "Results review is only supported via the Web interface\c"
    sleep 5
else
{
echo "$html_head"
echo "<table><tr><th>Location</th><th>Script Makeup</th></tr>"
find results work -name timout.html -print | sort |
while read timout
do
echo '<tr><td><A HREF="'$timout'">'$timout'</A></td>'
echo "<td>"
dir=`echo $timout | sed 's?/timout.html$??'`
if [ -f $dir/runout* ]
then
    render_runout $dir/runout*
fi
echo "</td><tr>"
done
echo "</table>"
echo "$html_tail"
} | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
fi
;;
*)
message_text="Error: Invalid option : $choice"
        export message_text
;;
esac
if [ "$PATH_WKB" = tty -a -n "$message_text" ]
then
    echo "" $message_text "\c"
    sleep 5
fi
done
if [ "$PATH_WKB" = web ]
then
#******************************************************************************
# Closedown
{
echo "$html_head"
echo "<h3>Goodbye!</h3>"
echo $html_tail
}  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
sleep 5
rm -f $PATH_HOME/tmp$E2_WEB_PID.tmp
kill -15 $web_thread $server_thread
rm -f tmp$$.tmp
fi
exit 
