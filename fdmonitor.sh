#!/bin/ksh
#!/bin/sh5
# @(#) $Name$ $Id$
# Copyright (c) 1993,2001 E2 Systems Limited
#
# Handle monitor launch executions. Called from fdexecute.sh
# **************************************************************************
# Construct and display a Web Page that refreshes a monitor periodically
launch_monitor() {
host=$1
run=$2
dir=$3
{
    echo "$html_head"
    echo "<script>
/*
 * Launch a monitor
 */
var new_win = null;
function drawform() {
    try {
    if (new_win && !new_win.closed)
        new_win.close();
    new_win = window.open('/monitor/$host/$run?dir=$dir', 'Response Time Monitor For $host:$run', 'width=1024,height=768,scrollbars=yes,resizeable=1,toolbar=0,menubar=0');
        new_win.focus();
    }
    catch(e) {
       alert('Monitor $host:$run load failed: ' + e);
    }
    window.setTimeout('drawform()',60000);
    return;
}
</script>
<h1>Refresh the new window to update the display</h1>"
    echo "$html_tail"
}  | e2fifout ${NAMED_PIPE_PREFIX}script_out_fifo.$E2_WEB_PID
e2fifin 1>&2 ${NAMED_PIPE_PREFIX}script_in_fifo.$E2_WEB_PID
    return
}
