#!/bin/ksh
# @(#) $Name$ $Id$
# Copyright (c) 1993, 2001 E2 Systems Limited
#
# Handle the scenario facilities. Called from fdpathnet.sh
#
# Scenarios live in sub-directories of the scenes directory, one per
# scenario. A scenario at the highest level consists of a list of scripts.
# Each script implies the need for client, app_server, db_server etc. (see
# below). The scenario assigns numbers of users, numbers of transactions,
# numbers of steps, step duration and work intensity for the script clients
# that it is proposed will participate in the scenario, and identifies the
# hosts for the supporting roles. At the top level, the clients are identified
# 'en masse'; they then need to be shared out amongst participating client
# hosts. So the scenes directory contains, for each scenario, a control file
# that indicates:
#  - A scenario description
#  - The number of steps and the step duration
#  - For each script
#    -  The script name
#    -  Once for each step
#       - The number of users
#       - The numbers of transactions
#       - The think times
#
# Read in the required functions
. $PATH_SOURCE/fdvars.sh
. $PATH_SOURCE/fdscrisel.sh
. $PATH_SOURCE/fdtestsel.sh
. $PATH_SOURCE/fdchoice.sh
. $PATH_SOURCE/fdrunini.sh
set -x
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCENARIO: Administer Test Scenarios
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
CREATE:     Create a New System Test Scenario/CREATE1:
AMEND:      Change the Constituent Tests for a Scenario/AMEND:
SCRIPT:     Maintain Scripts/SCRIPT:
DELETE:     Delete Scenario Altogether/DELETE:
EXIT:       Exit/EXIT:

HEAD=CREATE1: Create a new System Test Scenario
PARENT=SCRIPT:
PROMPT=Give your scenario an identifier and description
COMMAND=CREATE:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Name :
Number of steps :
Step duration :
Description :

EOF
`
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*SCRIPT:*)
    fdscript.sh
;;
*CREATE1:*)
shift
PATH_SCENE=""
export PATH_SCENE
if [  $# -lt 3  ]
then
    message_text="Insufficient values supplied"
    export message_text
else
pid=$1 
step_cnt=$2
step_len=$3
shift 3
desc=$@
script_select "CREATE2: Select Scripts to run for test $pid" Y
if [ -z "$SCRIPT_LIST" ]
then
    message_text="No scripts selected"
    export message_text
else
mkdir $PATH_HOME/scenes/$pid
echo "$desc" > $PATH_HOME/scenes/$pid/ctl.txt
echo "$step_cnt" >> $PATH_HOME/scenes/$pid/ctl.txt
echo "$step_len" >> $PATH_HOME/scenes/$pid/ctl.txt
for i in $SCRIPT_LIST
do
users=`(
echo HEAD=CREATE3: Enter Users, Transactions and Think Times for $i
echo PROMPT=Select Scripts, and Press RETURN
echo SEL_NO/COMM_NO/SYSTEM
echo SCROLL
j=0
while [ "$j" -lt $step_cnt ]
do
     echo "Step $j User Count:"
     echo "Step $j Transaction Count:"
     echo "Step $j Think Time:"
     j=\`expr $j + 1\`
done
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
    eval set -- $users
    shift
    echo $i $* >> $PATH_HOME/scenes/$pid/ctl.txt
done
set -x
get_yes_or_no "CREATE4: Do you want to generate an execution skeleton now?"
if [ "$CHOICE" = "YES:" ]
then
    run_ini "$pid"
fi
fi
fi
PATH_SCENE="$pid"
export PATH_SCENE
;;
*AMEND:*)
#
# Alter the scripts that are part of a test
#
    test_select "AMEND1: Select Scenarios to Amend" ""
    if [ -z "$TEST_LIST" ]
    then
        message_text="No scenarios selected"
        export message_text
    else
        for pid in $TEST_LIST
        do
        {
            read desc
            read step_cnt
            read step_len
        } < $PATH_HOME/scenes/$pid/ctl.txt
     x=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=AMEND1: Amend Scenario $pid
PROMPT=Give your scenario an identifier and description
COMMAND=AMEND:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Number of steps :/$step_cnt
Step duration :/$step_len
Description :/$desc

EOF
`
eval set -- $x
shift
step_cnt=$1
step_len=$2
shift 2
desc=$@
script_select "AMEND2: Select Scripts to run for test $pid" "Y"
if [ -z "$SCRIPT_LIST" ]
then
    message_text="No scripts selected"
    export message_text
else
    echo "$desc" > $PATH_HOME/scenes/$pid/ctl.txt
    echo "$step_cnt" >> $PATH_HOME/scenes/$pid/ctl.txt
    echo "$step_len" >> $PATH_HOME/scenes/$pid/ctl.txt
    for i in $SCRIPT_LIST
    do
users=`(
echo HEAD=AMEND3: Enter Users, Transactions and Think Times for $i
echo PROMPT=Select Scripts, and Press RETURN
echo SEL_NO/COMM_NO/SYSTEM
echo SCROLL
j=0
while [ "$j" -lt $step_cnt ]
do
     echo "Step $j User Count:"
     echo "Step $j Transaction Count:"
     echo "Step $j Think Time:"
     j=\`expr $j + 1\`
done
echo
) | natmenu 3<&0 4>&1 </dev/tty >/dev/tty`
    eval set -- $users
        echo $i $@ >> $PATH_HOME/scenes/$pid/ctl.txt
    done
    get_yes_or_no "AMEND4: Do you want to generate an execution skeleton now?"
    if [ "$CHOICE" = "YES:" ]
    then
        run_ini "$pid"
    fi
fi
    done
fi
;;
*DELETE:*)
#
# Delete an existing scenario
#
    test_select "DELETE: Select Scenarios to Delete" ""
    if [ -z "$TEST_LIST" ]
    then
        message_text="No scenarios selected"
        export message_text
    else
        for pid in $TEST_LIST
        do
            rm -rf $PATH_HOME/scenes/$pid $PATH_HOME/se/$pid.*
        done
    fi
    PATH_SCENE=""
    export PATH_SCENE
;;
esac
done
exit
