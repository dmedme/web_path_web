# *************************************************************************
# sereview
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
# Function to look at test run output
# Parameters: 1 - The test run
#             2 ... description
#
sereview () {
set -x
runid=$1
shift
desc=$@
while :
do
opt=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=REVIEW: Review Outputs for $runid - $desc
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
BROWSE:    Review the Run Summary Report/INTBROWSE:
PRINT:     Print the Run Summary Report/INTPRINT:
EXIT:      Finish/EXIT:

EOF
` 
message_text=
export message_text
eval set -- $opt
#
# Review all the dump files
#
case "$1" in
*EXIT:*)
    break
;;
*INTPRINT:*)
    lpr $PATH_HOME/work/$runid/timout*
;;
*INTBROWSE:*)
    if [ "$PATH_WKB" = tty ]
    then
        cat $PATH_HOME/work/$runid/timout* | sed 's///' |   pg -p '(Screen %d (h for help))' -s
    else
        cat $PATH_HOME/work/$runid/timout* | output_dispose
    fi
;;
esac
done
return 0
}
