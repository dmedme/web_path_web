#!/bin/ksh
#!/bin/sh5
# fddata.sh
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
# Handle the test data facilities. Called from fdpathweb.sh
# Read in the required functions
# set -x
. $PATH_SOURCE/fdvars.sh
. $PATH_SOURCE/fddatsel.sh
while :
do
choice=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=DATA:  Test Data Management $curr
PROMPT=Select Menu Option and Press RETURN
SEL_YES/COMM_YES/MENU
SCROLL
DUMP:       Dump out all the data in a schema/DUMP:
EDIT:       Manually Edit Test Data/EDIT:
VI:         Manually Edit Test Data with vi/VI:
DELETE:     Delete Test Data Filess/DELETE:
HELP:       Help/HELP:
EXIT:       Exit/EXIT:

HEAD=HELP:  DATA Management Help
PARENT=DATA:
PROMPT=Press RETURN to return
SEL_YES/COMM_YES/MENU
SCROLL
DUMP:       Dump out all the data in a schema/NULL:
    Create a collection of flat files from a database/NULL:
    The file names are formed from a concatenation/NULL:
    of an input prefix and the SQL table name/NULL:
EDIT:       Edit Test Data/NULL:
    Select a number of test data files and edit them/NULL:
VI:       Edit Test Data/NULL:
    Select a number of test data files and edit them with vi/NULL:
DELETE:     Delete Test Data Filess/NULL:
    Select a number of test data files to purge/NULL:
HELP:       Help/NULL:
    Display this message/NULL:

HEAD=DUMP: Dump all the Data in a schema to flat files
PARENT=DATA:
PROMPT=Fill in the details and Press RETURN
COMMAND=CAPTURE:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Dump Id (becomes file name prefix) :
Database connection string :

EOF
`
message_text=
export message_text
eval set -- $choice
case $1 in
*EXIT:*)
break
;;
*DUMP:*)
# Process an existing network file
#
    shift
    if [ $# -lt 2 ]
    then
        message_text="Insufficent details supplied"
        export message_text
    fi
    cd $PATH_HOME/data
    dumpschema.sh $*
;;
*EDIT:*)
#
# Edit test data files
#
data_list=`find $PATH_HOME/data -type f -name "*.db"  -print 2>/dev/null | sed 's=.*/==
/^\\./ d'`
    
    data_select "EDIT: Pick data files to edit" "" "$data_list"
    cd $PATH_HOME
    if [ ! -z "$DATA_LIST" ]
    then
    for i in $DATA_LIST
    do
        {
        wbrowse data/$i
        }  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
    done
    else
        message_text="No data file supplied"
        export message_text
    fi
;;
*VI:*)
#
# Edit test data files
#
data_list=`find $PATH_HOME/data -type f -name "*.db"  -print 2>/dev/null | sed 's=.*/==
/^\\./ d'`
    
    data_select "VI: Pick data files to edit" "" "$data_list"
    cd $PATH_HOME/data
    if [ ! -z "$DATA_LIST" ]
    then
        gvim $DATA_LIST &
    else
        message_text="No data file supplied"
        export message_text
    fi
;;
*DELETE:*)
#
# Delete test data files
#
data_list=`find $PATH_HOME/data -type f -name "*.db"  -print 2>/dev/null | sed 's=.*/==
/^\\./ d'`
    
    data_select "DELETE: Pick data files to delete" "" "$data_list"
    if [ ! -z "$DATA_LIST" ]
    then
    for i in $DATA_LIST
    do
        rm -rf $PATH_HOME/data/$i
    done
    else
        message_text="No data file supplied"
        export message_text
    fi
;;
esac
cd $PATH_HOME
done
exit
