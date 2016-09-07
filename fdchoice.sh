# ***************************************************************************
# get_yes_or_no
#
# Obtain user confirmation
# Parameters: none
#
# fdchoice.sh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
get_yes_or_no () {
CHOICE=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=$1
PROMPT=Select Yes or No
SEL_YES/COMM_NO/MENU
SCROLL
YES: Confirm the action/YES:
NO:  Abort the action/NO:

EOF
` 
eval set -- $CHOICE
if [ "$1" != "YES:" ]
then
     CHOICE="NO:"
else
     CHOICE="YES:"
fi
export CHOICE
return
}
