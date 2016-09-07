#!/bin/ksh
# @(#) $Name$ $Id$
# Copyright (c) 1993,2001 E2 Systems Limited
#
# Handle scenario executions. Called from fdpathnet.sh
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
#   -  The runout file names conform to the PATH standard, that is
#      runout$scenario_id, runout${scenario_id}_1, runout${scenario_id}_2 etc..
#   -  The generated script names to conform to the PATH standard, that is
#      echo$scenario_id.$bundle.0
# - Scenario distribution
#   -  To minimise the software that is installed on each client, and to
#      simplify management, distribution is managed from the centre. There
#      are two options:
#      -  uploading a bzip2-compressed archive of the runout file and echo
#         files using the minitest running on the client. There will be
#         an option that goes through all the host sub-directories and tries
#         to gets the data transfered over, uncompressed and unpacked.
#      -  using a self-extracting executable containing everything; the
#         executable programs, and the scripts. The generation process has to
#         be aware of the target hardware architecture and operating system of
#         the hosts so targetted; physical distribution can be achieved by
#         E-mail, CD-ROM or floppy disk.
# - Scenario running
#   -  A new results directory is created for each run
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
#   (or maybe K-Office, Star-Office, or whatever; look into this)
# - Can use minitest again to pull across results
# - minitest needs to be locked down somewhat. Currently it allows any action
#   its user ID (which may well be root!) permits, to be triggered by anyone
#   who knows its command syntax and listening port.
#
# Read in the required functions
. $PATH_SOURCE/fdvars.sh
. $PATH_SOURCE/fdseselect.sh
. $PATH_SOURCE/fdtestsel.sh
. $PATH_SOURCE/fdhostsel.sh
. $PATH_SOURCE/fdrunini.sh
. $PATH_SOURCE/fdchoice.sh
. $PATH_SOURCE/fdreccount.sh
. $PATH_SOURCE/fdwebscale.sh
. $PATH_SOURCE/fdtrafdist.sh
. $PATH_SOURCE/fdtrafrun.sh
. $PATH_SOURCE/fdresults.sh
. $PATH_SOURCE/fdsereview.sh
. $PATH_SOURCE/fdmonitor.sh
#set -x
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=EXECUTE: Administer Scenario Execution Incarnations
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
CREATE:      Create a New Scenario Execution Incarnation/CREATE:
ASSIGN:      Assign hosts and Generate scripts for them/ASSIGN:
STARTUP:     Start the local test server/STARTUP:
DISTRIBUTE:  Distribute files to designated hosts/DISTRIBUTE:
EXECUTE:     Execute a Scenario Execution Incarnation/RUN:
TRIGGER:     Trigger a Scenario Execution Asynchronously/TRIGGER:
MONITOR:     Monitor a Scenario Execution Incarnation/MONITOR:
ABORT:       Abort a Scenario Execution Incarnation/ABORT:
REVIEW:      Review the output of a Previous Run/REVIEW:
PURGE:       Remove Prior Run Data/PURGE:
SCENARIO:    Maintain Scenarios/SCENARIO:
DELETE:      Delete Scenario Execution Incarnation Altogether/DELETE:
EXIT:        Exit/EXIT:

HEAD=MONITOR: Monitor Scenario Execution
PARENT=EXECUTE:
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
START:       Start Monitoring a Scenario Execution Incarnation/START:
STOP:        Stop All Monitors/STOP:
EXIT:        Exit/EXIT:

EOF
`
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*STARTUP:*)
    if ps -ef | grep "m[i]nitest $E2_HOME_PORT"
    then
        message_text="Test Server is Already Running"
        export message_text
    else
    (
        cd $PATH_HOME/work
        PATH=$PATH:$PATH_HOME/work
        export PATH
        minitest $E2_HOME_PORT > minilog 2>&1 </dev/null &
    )
    fi
;;
*SCENARIO:*)
    fdscene.sh
;;
*CREATE:*)
shift
PATH_SE=""
export PATH_SE
    test_select "CREATE: Select Base Scenarios to set up" ""
    if [ -z "$TEST_LIST" ]
    then
        message_text="No scenarios selected"
        export message_text
    else
#
# The Scenario Execution Incarnation Identifier
#
        for pid in $TEST_LIST
        do
            run_ini $pid
        done
    fi
;;
*REVIEW:*)
#
# Have look at some results
#
    se_select "REVIEW: Select Results to Review"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for PATH_SE in $SE_LIST
        do
            export PATH_SE
            scn=`echo $PATH_SE | sed 's/\..*//'`
            desc=`head -1 $PATH_HOME/scenes/$scn/ctl.txt`
            sereview $PATH_SE $desc
        done
    fi
;;
*ASSIGN:*)
# ****************************************************************************
# Assign hosts to the scenario execution
# - Accept a list of scenario executions
# - For each scenario execution
#   - Choose whether to 'clone' or 'share' the clients amongst the hosts
#   - Accept a list of clients
#   - For each client:
#     -  Assign hosts to the other roles (using actual values recorded with the
#        script for the first script in the runout file as the default for the
#        first client, and the values for the prior client as the default for
#        the next client)
#     -  Create a directory for the host in the client sub-directory
#     -  Create runout files in it, copying/adjusting the files in the client
#        sub-directory above
#     -  Generate the scripts, editing the End Points as appropriate
#     -  Cycle through the other roles:
#        -  If a directory for the role host does not already exist
#           -  Create a sub-directory for this role host
#           -  Copy the echo files from the client sub-directory
#           -  Copy the runout files from the directory above (ie. the role
#              sub-directory)
#        The above procedure will ensure that:
#        -  All necessary role host sub-directories will get populated
#        -  The role host sub-directories will only have files for the
#           first step, which is correct
# ****************************************************************************
# Accept a list of scenario executions
#
    se_select "ASSIGN1: Pick Scenario Execution Incarnations to Assign Hosts To"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
#
# For each scenario execution
#
        for PATH_SE in $SE_LIST
        do
            export PATH_SE
#
# Choose whether to 'clone' or 'share' the clients amongst the hosts
#
share_clone=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=ASSIGN2: Do you want to share or clone client users for $PATH_SE?
PROMPT=Select Share or Clone and press RETURN
SEL_YES/COMM_NO/MENU
SCROLL
CLONE: Give each client the total ration of users/C:
SHARE: Share the users equally amongst the clients/S:

EOF
` 
set -- $share_clone
eval share_clone=$1
#
#  Accept a list of clients
#
    set -x
    host_sel "ASSIGN3: Choose the clients you want to use for $PATH_SE"
    if [ -z "$HOST_LIST" ]
    then
        message_text="No Clients Selected"
        export message_text
    else
#
# Get the scenario ID
#
        PATH_SCENE=`echo $PATH_SE | sed 's/\..*$//'`
#
# Get the share factor
#
        if [ "$share_clone" = "S:" ]
        then
            set -- $HOST_LIST
            clnt_cnt=$#
            if [ $clnt_cnt = 1 ]
            then
                share_clone=C:
            fi
	else
             clnt_cnt=1
        fi
#
# Get the list of other roles
#
        roles=`ls -1d $PATH_HOME/se/$PATH_SE/* | sed 's=.*/==
/client/ d'`
#
# Get some candidate role hosts
#
        first_script=`$PATH_AWK 'NR == 4 { print $2 ; exit }' $PATH_HOME/se/$PATH_SE/client/runout$PATH_SCENE`
        . $PATH_HOME/scripts/$first_script/capset.sh
#
#  For each client:
#
        host_list=$HOST_LIST
        host_cnt=`echo $host_list | wc -w`
        first_host=1
        for host in $host_list
        do
#
# Create a directory for the host in the client sub-directory
#
            if [ ! -d $PATH_HOME/se/$PATH_SE/client/$host ]
            then
                mkdir $PATH_HOME/se/$PATH_SE/client/$host
                role_host_list=""
            elif [ -f $PATH_HOME/se/$PATH_SE/client/$host/role_host_list ]
            then
                role_host_list=`cat $PATH_HOME/se/$PATH_SE/client/$host/role_host_list `
                if [ -n "$role_host_list" ]
                then
                get_yes_or_no "Do you want $role_host_list ?"
                if [ $CHOICE != "YES:" ]
                then
                    role_host_list=""
                fi
                fi
            else
                role_host_list=""
            fi
#
# Create runout files in it, copying/adjusting the files in the client
# sub-directory above
#
            if [ "$share_clone" = "C:" ]
            then
                cp  $PATH_HOME/se/$PATH_SE/client/runout${PATH_SCENE}* $PATH_HOME/se/$PATH_SE/client/$host
            else
            for rn in $PATH_HOME/se/$PATH_SE/client/runout${PATH_SCENE}*  
            do
                brn=`echo $rn | sed 's=.*/=='`
                $PATH_AWK 'NR < 4 {
                    print
                    next
                }
                {
                    n = int($1/'$clnt_cnt')
                    if (n < 1)
                        n = 1
                    print n " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8
                }' $rn  > $PATH_HOME/se/$PATH_SE/client/$host/$brn
            done
            fi
#
# Assign hosts to the other roles (suggesting actual values recorded with the
# script for the first script in the runout file as the default for the
# first client, and the values for the prior client as the default for
# the next client)
#
            if [ -z "$role_host_list" ]
            then
            for role in $roles
            do
                HOST_LIST=""
                while [ -z "$HOST_LIST" ]
                do
                    if [ $role = app_server ]
                    then
                        host_sel "ASSIGN4: Choose an app_server host for $host in $PATH_SE eg. $E2_APP_SERVER"
                    elif [ $role = db_server ]
                    then
                        host_sel "ASSIGN4: Choose a db_server host for $host in $PATH_SE eg. $E2_DB_SERVER"
                    else
                        host_sel "ASSIGN4: Choose the $role host for $host in $PATH_SE"
                    fi
                done
                set -- $HOST_LIST
                role_host_list=$role_host_list" $role $1"
            done
            echo $role_host_list > $PATH_HOME/se/$PATH_SE/client/$host/role_host_list
            fi
#
# Generate the scripts, editing the End Points as appropriate
#
            cd $PATH_HOME/se/$PATH_SE/client/$host
            if [ $first_host = 1 ]
            then
                (
                echo "$html_head"
                unset html_head
                sav_tail="$html_tail"
                unset html_tail
                rec_count $PATH_SCENE errs.lis $host_cnt |
                wbrowse -r -l "ASSIGN5: Checking scenario for sufficient data" -
                $PATH_AWK '{print "<p>" $0 "</p>"}' errs.lis
                echo "$sav_tail"
                )  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
                e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
                get_yes_or_no "ASSIGN6: Do you want to proceed with generation for $host_list?"
                if [ $CHOICE = "YES:" ]
                then
                    :
                else
                    cd $PATH_HOME
                    break
                fi
            fi
            webscale $PATH_SCENE $role_host_list
            cd $PATH_HOME
#
# Cycle through the other roles:
#
            set -- $role_host_list
            while [ $# -gt 0 ]
            do
                role=$1
                role_host=$2
                shift 2
#
# If a directory for the role host does not already exist
#
                if [ ! -d $PATH_HOME/se/$PATH_SE/$role/$role_host ]
                then
#
# Create a sub-directory for this role host
#
                    mkdir $PATH_HOME/se/$PATH_SE/$role/$role_host
#
# Copy the echo files from the client sub-directory
#
                    cp $PATH_HOME/se/$PATH_SE/client/$host/echo$PATH_SCENE.*.0 $PATH_HOME/se/$PATH_SE/$role/$role_host
#
# Copy the runout file from the directory above (ie. the role sub-directory)
#
                    cp $PATH_HOME/se/$PATH_SE/$role/runout$PATH_SCENE $PATH_HOME/se/$PATH_SE/$role/$role_host
#
# Copy over if the scripts appear to have been updated; only tests the first
# script!
#
                elif cmp -s $PATH_HOME/se/$PATH_SE/client/$host/echo$PATH_SCENE.1.0 $PATH_HOME/se/$PATH_SE/$role/$role_host/echo$PATH_SCENE.1.0 
                then
                    :
                else
                    cp $PATH_HOME/se/$PATH_SE/client/$host/echo$PATH_SCENE.*.0 $PATH_HOME/se/$PATH_SE/$role/$role_host
                fi
            done
#
# The above processing should ensure that:
# - All necessary role host sub-directories will get populated
# - The role host sub-directories will only have files for the first step,
#   which is correct.
            first_host=0
        done
        if [ $CHOICE = "YES:" ]
        then
            echo Echo regeneration complete for $pid | output_dispose
        fi
    fi
# End of loop through selected scenario invocations
    done
# End of branch where there was at least one
    fi
;;
*RUN:*)
#
# Run an existing scenario execution
#
    se_select "EXECUTE: Select Scenario Execution Incarnations to Run"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for PATH_SE in $SE_LIST
        do
            export PATH_SE
            trafrun $PATH_SE
        done
    fi
;;
*TRIGGER:*)
#
# Run an existing scenario execution
#
    se_select "EXECUTE: Select Scenario Execution Incarnations to Run"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for PATH_SE in $SE_LIST
        do
            export PATH_SE
            fdbatchrun.sh $PATH_SE >$PATH_HOME/work/$PATH_SE.log 2>&1 &
        done
    fi
;;
*DISTRIBUTE:*)
#
# Run an existing scenario execution
#
    se_select "DISTRIBUTE: Select Scenario Execution Incarnations to Distribute"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for PATH_SE in $SE_LIST
        do
            export PATH_SE
full_dist=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=DISTRIBUTE2: Scripts only or a full distribution?
PROMPT=Select Full or Scripts Only and press RETURN
SEL_YES/COMM_NO/MENU
SCROLL
FULL: Combine programs with scripts in a self-extracting executable/F:
DATA: Distribute scripts only/D:

EOF
` 
eval set -- $full_dist
full_dist=$1
            if  [ "$full_dist" = "F:" ] 
            then
                full_dist=F
            else
                full_dist=D
            fi
            trafdist $full_dist $PATH_SE
        done
    fi
;;
*DELETE:*)
#
# Delete an existing Scenario Execution Incarnation
#
    se_select "DELETE: Select Scenario Execution Incarnations to Delete"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for pid in $SE_LIST
        do
            rm -rf $PATH_HOME/se/$pid $PATH_HOME/work/$pid
        done
    fi
    PATH_SE=""
    export PATH_SE
;;
*ABORT:*)
#
# Abort a running Scenario Execution Incarnation
#
    se_select "ABORT: Select Scenario Execution Incarnations to Abort"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for runid in $SE_LIST
        do
#
# Identify the clients
#
            targs=`ls -1d $PATH_HOME/se/$runid/client/*`
            if [ ! -z "$targs" ]
            then
                for d in $targs
                do
                    if [ -d $d ]
                    then
                        host_ip=`echo $d | sed 's=.*/=='`
                        minitest $host_ip $E2_HOME_PORT ABORT </dev/null &
                    fi
                done
            fi
        done
    fi
    PATH_SE=""
    export PATH_SE
;;
*START:*)
    if [ "$PATH_WKB" = tty ]
    then
        echo Realtime monitoring is only supported through the Web interface
        sleep 5
    else
#
# Start monitoring in realtime
#
        se_select "MONITOR1: Pick Scenario Execution to Monitor"
        if [ -z "$SE_LIST" ]
        then
            message_text="No Scenario Execution Incarnations selected"
            export message_text
        else
#
# For each scenario execution
#
            for PATH_SE in $SE_LIST
            do
                export PATH_SE
#
#  Accept a list of clients
#
                host_sel "MONITOR2: Choose the driver machines to monitor"
                if [ -z "$HOST_LIST" ]
                then
                    message_text="No Clients Selected"
                    export message_text
                else
#
# Get the scenario ID
#
                    PATH_SCENE=`echo $PATH_SE | sed 's/\..*$//'`
#
#  For each client:
#
                    host_list=$HOST_LIST
                    for host in $host_list
                    do
#
# Create a directory for the host in the client sub-directory
#
                        if [ -d $PATH_HOME/se/$PATH_SE/client/$host ]
                        then
                            launch_monitor $host $PATH_SCENE se/$PATH_SE/client/$host 
                        fi
                    done
                fi
            done
        fi
    fi
;;
*STOP:*)
#
# Stop monitoring in realtime
#
    if [ "$PATH_WKB" = tty ]
    then
        echo Realtime monitoring is only supported through the Web interface
        sleep 5
    else
{
    echo "$html_head"
    echo "<script>
/*
 * Stop the monitors
 */
var req = null;
function handleresp()
{
    return;
}
function get_script(script_url) {
    return;
}
/*
 * Mozilla and WebKit
 */
function drawform() {
/*
 * Mozilla and WebKit
 */
    if (window.XMLHttpRequest)
        req = new XMLHttpRequest();
    else
    if (window.ActiveXObject)
    {
/*
 * Internet Explorer (new and old)
 */
        try
        {
           req = new ActiveXObject('Msxml2.XMLHTTP');
        }
        catch (e)
        {
           try
           {
               req = new ActiveXObject('Microsoft.XMLHTTP');
           }
           catch (e)
           {}
        }
    }
    try {
    req.open('GET', '/zap', true);
    req.onreadystatechange = handleresp;
    req.send(null);
    }
    catch(e) {
       alert('Monitor shutdown failed:' + e);
    }
    return;
}
</script>
<h1>Monitors shutdown</h1>"
    echo "$html_tail"
} | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
fi
;;
*PURGE:*)
#
# Remove the detritus from a scenario execution
#
    se_select "PURGE: Select Scenario Execution Results to Purge"
    if [ -z "$SE_LIST" ]
    then
        message_text="No Scenario Execution Incarnations selected"
        export message_text
    else
        for pid in $SE_LIST
        do
            rm -rf $PATH_HOME/work/$pid
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
