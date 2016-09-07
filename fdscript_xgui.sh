#!/bin/ksh
#!/bin/sh5
# fdscript_citrix.sh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
# Handle the X GUI script facilities. Called from fdpathweb.sh
# *********************************************************
# This version supports X, so will only be used on UNIX
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
# ****************************************************************************
# Function to wait for a window to appear
# ****************************************************************************
wait_for_window() {
    re="$1"
    until xwininfo -root -tree | grep -- "$re"
    do
        sleep 5
    done
    return
}
# ****************************************************************************
# Function to add timing points
# ****************************************************************************
e2sync() {
targ=$1
e2sync_seq=1
while :
do
narrative=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCRIPT:  Comment or terminate the script
PROMPT=Select Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
E2SYNC: Add a synchronisation and timing event to the script/E2SYNC:
EXIT:   Terminate script capture/EXIT:

HEAD=E2SYNC: Add script comment/timing point
PROMPT=Fill in the details and Press RETURN
COMMAND=E2SYNC:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Comments :

EOF
`
eval set -- $narrative
case $1 in
*E2SYNC:*)
shift
    while [ -f $targ.comment ]
    do
        sleep 1
    done
    cat << EOF | output_dispose "E2SYNC: Marking Match Area"
Click on the upper left and bottom left of your chosen match area
Click again to reset
Once you have clicked twice, Pressing ANY keyboard key will exit
EOF
    sync=`rubberx :2`
    case "$sync" in
    Sync*)
         ;;
    *)
         sync=
         ;;
    esac
    gawk 'BEGIN {
        seq = '$e2sync_seq'
        ev= substr("ABCDEGHIJKLMNOPQSUVWY", ((seq / 36) % 21) + 1,1) substr( "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", (seq % 36), 1)
        print "\\S" ev ":120:'"$*"' \\"
        if (length("'"$sync"'") > 0)
            print "'"$sync"'"
        print "\\T" ev ":\\"
}' /dev/null >$targ.comment
e2sync_seq=`expr $e2sync_seq + 1`
;;
*)
return
;;
esac
done
}
# ****************************************************************************
# Script Menu
# ****************************************************************************
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=SCRIPT:  Test Script Management $curr
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
SETUP:   Ensure necessary software is present and launch Xvnc, Xephyr and xterm/SETUP: 
RESTART: Restart everything if something has crashed/RESTART:
CAPTURE: Launch a script capture/CAPTURE:
REPLAY:  Re-run a captured script/REPLAY:
EDIT:    Manually Edit Test Scripts and related entities/EDIT:
VI:      Manually Edit Test Scripts and related entities with vi/VI:
DELETE:  Delete Test Scripts/DELETE:
HELP:    Help/HELP:
EXIT:    Exit/EXIT:

HEAD=HELP:  SCRIPT Management Help
PARENT=SCRIPT:
PROMPT=Press RETURN to return
SEL_YES/COMM_YES/MENU
SCROLL
SETUP:   Ensure necessary software is present and launch Xvnc, Xephyr and xterm/NULL:
    Check for presence of necessary software dependencies/NULL:
RESTART: Restart everything if something has crashed/RESTART:
    Restart Xephyr, Xvnc4, xterm as necessary./NULL:
CAPTURE:     Create a New Test Script/NULL:
    Create a brand new test script using recordx capture/NULL:
RUN:     Re-run a captured script/NULL:
EDIT:       Edit Test Script Programs/NULL:
    Select a number of test script component files to edit and edit them/NULL:
VI:         Edit Test Script Programs with vi/NULL:
    Select a number of test script component files to edit and edit them/NULL:
DELETE:     Delete Test Scripts/NULL:
    Select a number of test scripts to purge/NULL:
HELP:       Help/NULL:
    Display this message/NULL:

HEAD=CAPTURE: Capture a GUI script
PROMPT=Fill in the details and Press RETURN
COMMAND=CAPTURE:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Name :

EOF
`
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*SETUP:*|*RESTART:*)
    case "$choice" in
    *RESTART:*)
        killall Xvnc4
        ;;
    *)
        ;;
    esac
{
    if id | grep 'uid=0'
    then
        apt-get install vnc4server vncviewer xserver-xephyr xterm xfwm4
    else
cat << EOF
You are not root, so the script is unable to make sure that the packages
vnc4server vncviewer xserver-xephyr xterm xfwm4 are installed. Become root and restart
if it does not work.
EOF
    fi
# Xvnc4 (the command started by vncserver) is the X server used on the Cloud
# machines, so we need to capture our scripts on this.
    rm -f /home/$USER/.vnc/*.log /home/$USER/.vnc/*.pid
    vncserver :1
cat << EOF
vncserver may automatically start a window manager and xterm. If it does not,
you will not be able to move between and around the windows on the virtual
X server. So you will have to uncomment the some lines in fdscript_xgui.sh
#    xfwm4 --daemon --compositor=off --display=:1
#    DISPLAY=:1 xterm  >/dev/null 2>&1 &
EOF
#
# Each script will run on its on Xserver, Xephyr, that will will be hosted
# by Xvnc4. This command starts one.
    DISPLAY=:1 Xephyr -keybd ephyr,,,xkbmodel=evdev,xkblayout=gb -ac -reset -screen 800x600 :2 -name "Xephyr PATH Display" &
    DISPLAY=:1 wait_for_window Xephyr
#
# Now start up an xterm on the Xephyr We will run script capture and replay
# from there.
#
    DISPLAY=:2 xterm >/dev/null 2>&1 &
    DISPLAY=:2 wait_for_window xterm
cat << EOF
The virtual X server and nested X server should have started.
It is important that the Virtual X server has a Window Manager
and equally important that the nested X server does not have one.
Go to another terminal window, and run vncviewer localhost:5901
in order to see the action. Press on the Xephyr window to bring it
to the front, and type all commands into the xterm you will see there.
Because there is no Window Manager there, focus follows the mouse.
Thus, the mouse has to be somewhere in the xterm window when you type.
The sizes of these things are all default at present. They can be
easily changed if required.
EOF
} | output_dispose "$choice: Readying the environment"
;;
*CAPTURE:*)
# Process a script file capture
# *****************************************************************************
# This is really best thought of as a prototype. The merging of the timing
# points is done by writing them to a file, and having gawk look for the
# existence of the file once round the loop. It needs a steady stream of events
# to keep gawk moving, otherwise the file doesn't get picked up, and a
# subsequent timing point hangs. There is also nothing to prevent the file
# being read before the writing has finished.
# *****************************************************************************
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
        fname=$dir.msg
        rm -f $fname.comment
        (
            export DISPLAY=:2
            recordx -l | tee $fname.raw | gawk '{
                print $0
                done_flag = 0
                while((getline<"'$fname.comment'")>0)
                {
                    done_flag = 1
                    print $0
                }
                if (done_flag)
                {
                    close("'$fname.comment'")
                    system("rm '$fname.comment'")
                }
            }' | simplifyx - $fname
        ) &
        e2sync $fname
        killall recordx
    fi
    sname=$dir
    ;;
*REPLAY:*)
script_list=`find $PATH_HOME/scripts -type d -print 2>/dev/null | sed 's=.*/==
/^scripts$/d
/^\\./ d'`
    script_select "REPLAY: Pick scripts to Replay" "" "$script_list"
    if [ ! -z "$SCRIPT_LIST" ]
    then
        script_list=$SCRIPT_LIST
        for j in $script_list
        do
            cd $PATH_HOME/scripts/$j
            fname=$j.msg
            if [ ! -f "$fname" ]
            then
                export message_text="No such script $fname"
            else
                (
                export DISPLAY=:2
                recordx log$fname.1.0 $fname 1 0 $fname | tee $fname.raw |
                        gawk '{
                    print $0
                    done_flag = 0
                    while((getline<"'$fname.comment'")>0)
                    {
                        done_flag = 1
                        print $0
                    }
                    if (done_flag)
                    {
                        close("'$fname.comment'")
                        system("rm '$fname.comment'")
                    }
                    }' | simplifyx - $fname.replayed
                ) &
                e2sync $fname
                killall recordx
            fi
        done
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
esac
cd $PATH_HOME
if [ "$PATH_WKB" = tty -a -n "$message_text" ]
then
    echo "" $message_text "\c"
    sleep 5
fi
done
exit
