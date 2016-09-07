# fdbase.sh - Global variables for PATH
# @(#) $Name$ $Id$
# Copyright (c) E2 Systems Limited 1993
#
ulimit -n 1024
PATH_IG=${PATH_IG:-}
PATH_SCENE=${PATH_SCENE:-}
# Establish directory where PATH is run
PATH_HOME=${PATH_HOME:-/c/e2}
# O/S type for establishing executables directory (PATH_SOURCE) and text editor
# (PATH_EDITOR)
PATH_OS=${PATH_OS:-NT4}
PATH_SOURCE=${PATH_SOURCE:-/c/e2/web_path_web}
PATH_EDITOR=${PATH_EDITOR:-vi}
# path and name of ./rules directory
PATH_RULE_BASE=$PATH_HOME/rules
pid=$$
export PATH_OS TERM PATH_RULE_BASE PATH_HOME PATH_EDITOR PATH_IG PATH_SCENE PATH_SOURCE pid
# path and name of directory for saved scripts
#
# The file extension of the script files
#
PATH_USER=${PATH_USER:-}
E2_HOME_PORT=${E2_HOME_PORT:-5000}
E2_HOME_HOST=${E2_HOME_HOST:-127.0.0.1}
PATH_DRIVER=${PATH_DRIVER:-t3drive}
#PATH_DRIVER=${PATH_DRIVER:-webdrive}
PATH_STAGGER=${PATH_STAGGER:-3}
E2_SCENE_LEN=${E2_SCENE_LEN:-3600}
E2_TEST_ID=${E2_TEST_ID:-ESALES}
E2_TEST_LEN=${E2_TEST_LEN:-86400}
E2_WEB_PORTS=${E2_WEB_PORTS:-3128}
#E2_ORA_WEB_PORTS=${E2_ORA_WEB_PORTS:-"9000 9500"}
#E2_T3_WEB_PORTS=${E2_ORA_WEB_PORTS:-"15001"}
# ************************************************************************
# Optional features
# E2_BOTH makes webdump show both in and out
# E2_VERBOSE makes webdump provide a human-readable decode of the 
# ORACLE Web traffic
#
E2_BOTH=1
#E2_VERBOSE=1
export E2_BOTH E2_VERBOSE
PATH_THINK=${PATH_THINK:-5}
if [ $PATH_OS = NT4 -o $PATH_OS = LINUX ]
then
PATH_AWK=${PATH_AWK:-gawk}
else
PATH_AWK=${PATH_AWK:-nawk}
fi
# Application Redraw String
export PATH_THINK PATH_OS PATH_DRIVER PATH_AWK PATH_STAGGER E2_SCENE_LEN E2_TEST_ID E2_TEST_LEN PATH_EXT E2_WEB_PORTS E2_ORA_WEB_PORTS
if [ ! "$PATH_OS" = NT4 ]
then
case $PATH in
*$PATH_SOURCE*)
     ;;
*)
    PATH=$PATH_SOURCE:$PATH
    export PATH
    ;;
esac
fi
#
# Pick up portable configuration data
#
. pathenv.sh
export E2_CLIENT_LOCATION
export E2_TEST_LEN
export PATH_EXT
export E2_TEST_ID
export E2_SCENE_LEN
export PATH_STAGGER
export PATH_EXTRA_ARGS0
export PATH_DRIVER
export PATH_REMOTE
export PATH_TIMEOUT
export E2_HOME_HOST
export E2_HOME_PORT
export E2_ORA_TUNNEL_PORTS
export PATH_DEGENERATE
export PATH_SINGLE_THREAD
if [ -n "$E2_DEFAULT_SEP_EXP" ]
then
export E2_DEFAULT_SEP_EXP
fi
if [ -n "$E2_PROXY_PORT" ]
then
export E2_PROXY_PORT
fi
#
# Pick the correct script to control script capture
# 
# The choices are Citrix (Windows only), and then between capture via the
# in-built proxy, and capture from the network.
#
if [ "$PATH_EXT" = "rec" ]
then
export FDSCRIPT=fdscript_citrix.sh
elif [ "$PATH_WKB" = tty ]
then
export FDSCRIPT=fdscript_captty.sh
elif [ "$PATH_DRIVER" = dotnetdrive ]
then
export FDSCRIPT=fdscript_capweb.sh
else
export FDSCRIPT=fdscript_proxweb.sh
fi
#E2_ORA_WEB_PORTS="9000 9500"
#E2_T3_WEB_PORTS="15001"
E2_TRAFMUL_EXTRA=
export E2_TRAFMUL_EXTRA
unset PATH_REMOTE
#
# Set up SQL*Plus access to the databasE, eg. as here
#
#ORACLE_HOME=/opt/oracle/product/10.1.0/db_1
#export ORACLE_HOME
#ORACLE_SID=STUAT3
#ORACLE_SID=e2acer
#export ORACLE_SID
#case $PATH in
#*$ORACLE_HOME/bin*)
#    ;;
#*)
#    PATH=$PATH:$ORACLE_HOME/bin
#    LD_LIBRARY_PATH=$ORACLE_HOME/lib
#    export PATH LD_LIBRARY_PATH
#esac
export E2_CLIENT_LOCATION E2_HOME_PORT E2_HOME_HOST PATH_DRIVER PATH_STAGGER E2_SCENE_LEN E2_TEST_ID E2_TEST_LEN E2_ORA_WEB_PORTS E2_T3_WEB_PORTS
