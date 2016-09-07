#!/bin/ksh
# Script that uses the JSVI Javascript Vi implementation to edit
# files.
#
PATH_EDITOR=fdvi
export PATH_EDITOR
fdvi() {
fname=$1
{
#
# Logic for files of different types
#
ext=`echo $fname | sed 's/.*\.//'`
case "$ext" in
def)
    rel=`echo $fname | sed "s=$PATH_HOME/=="`
    wbrowse -c "LINE|TARGET|TABLE|COLUMN|ACTION" $rel
;;
db)
    rel=`echo $fname | sed "s=$PATH_HOME/=="`
    wbrowse $rel
;;
sh)
    rel=`echo $fname | sed "s=$PATH_HOME/=="`
    wbrowse -c "NAME|VALUE" -d $PATH_HOME/web_path_web/path_dict.txt -p -t= $rel
;;
*)
echo "$html_head"
cat - $fname <<EOF
<script src="web_path_web/jsvi.js"></script>
<link rel="stylesheet" type="text/css" href="web_path_web/jsvi.css" />
<form>
<textarea name="body" onfocus="editor(this, '$fname.tmp');" rows=25 cols=110>
EOF
echo "</textarea>"
echo "</form>"
echo $html_foot
;;
esac
}  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
if [ -s $fname.tmp ]
then
    mv $fname.tmp $fname
fi
return
}
