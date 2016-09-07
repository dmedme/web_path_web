#!/bin/ksh
# Make it as painless as possible to conduct a 70 user controlled test lasting
# about 2 hours. The scenario is called, two_hours.
#
# Run this and put it in the background with the output re-directed to a file.
# e.g.
#     /u01/e2/autorun.sh >/u01/e2/autorun.log 2>&1 &
#
# Overview
# ========
# 1. Make sure that everything necessary that cannot be controlled
#    from this script is running. This script is run as user wsadmin.
#    -  On cobra (ie. this machine) we have a root-owned process, rootmon.sh
#       that has to be kicked off by root or equivalent.
#       -   cd /u01/e2/unix
#       -   nohup /u01/e2/path_web/rootmon.sh two_hours >rootmon.log 2>&1
#    -  On piranha, we need a minitest running
#       -   log in as oracle
#       -   cd /u01/oracle/e2/perfdb
#       -   nohup ./setup.sh >minilog 2>&1 &
#    If something isn't running, emit a helpful error message and exit.
# 2. Clear out the work area, removing echo, log, dump and results files
# 3. Re-extract or reset the data that will be re-used
#    -  Reset everything that is read-only
#    -  Re-extract the SPOTS and the National SPOTS
#    There is loads of data for Spot Moves, there are few of them in the
#    work mix, and it takes hours to extract them, so we just let these
#    dribble away. There should be sufficent CALL_ID's and JVMID's forever.
# 4. Create a new 'scenario execution' for two_hours, and assign it to
#    150.135.2.77. If you run out of data, there will be 'divide by zero'
#    messages at this point.
# 5. Distribute the new scenario. This should start the local minitest if it
#    isn't running. After this step, there should be 71 files
#    /u01/e2/work/echotwo_hours* and a /u01/e2/work/runouttwo_hours
# 6. Execute the scenario. This will trigger the rootmon.sh procedure on
#    cobra (150.135.2.77) and the e2monitor.sh and detmon.sh scripts on
#    piranha (150.135.2.78). Once this has started, ps should show:
#    -  multiple minitest processes
#    -  multiple rootmon.sh processes
#    -  multiple t3drive processes (one for each pseudo-user).
#    t3drive processes run until they run out of input, or they are terminated
#    The child minitest controls the run. It exists at the end of the two hours.
# 7. When the scenario has finished:
#    - On cobra
#      -  Dump files /u01/e2/work/dump*.0 are the best indicators as to how
#         well things have worked. Tell-tale signs of problems are:
#         -   The strings Start: which should correspond to the timing points
#             keep going back to the beginning. The session has crashed. Study
#             the data returned for clues
#         -   The presence of 'EJB Exception' in the dump. This indicates a
#             'Call Stellar HelpDesk' message. The accompanying narrative
#             usually indicates what has happened. These are supposed to be
#             logged in all dump files, not just the verbose ones (dump*.0)
#             but I am not convinced that this driver feature works.
#      -  Response times are summarised in files named
#         /u01/e2/work/*/150.135.2.77/timout*evt*. These files are processed
#         by our Excel macros to produce the percentile graphs that you have
#         seen.
#      -  System monitor output is in /u01/e2/unix/save.two_hours.*
#         The files excel.txt code instructions for our Excel macros.
#    - On piranha
#      -  Standard monitor data is in /u01/oracle/e2/perfdb/STPROD1.*
#      -  Detailed data is in /u01/oracle/e2/perfdb/STPROD1.*/save.two_hours.1
#         The files excel.txt code instructions for our Excel macros.
# 8. If it is desired to look further at the collected data, I suggest it be
#    moved or copied to a convenient location. I have been using
#    sub-directories under /u01/e2/results for this purpose. Note that the
#    response time data are actually deleted by the next run of this
#    script.
# *****************************************************************************
set -x
. /u01/e2/path_web/fdvars.sh
. $PATH_SOURCE/fdrunini.sh
. $PATH_SOURCE/fdwebscale.sh
. $PATH_SOURCE/fdtrafdist.sh
# *****************************************************************************
# Check rootmon.sh is running
if ps -ef | grep '[r]ootmon.sh'
then
    :
else
cat << EOF
On cobra (ie. this machine) we have a root-owned process, rootmon.sh
that has to be kicked off by root or equivalent. It isn't running.
To start it, proceed as follows:
-  Become root (or equivalent)
-  cd /u01/e2/unix
-   nohup /u01/e2/path_web/rootmon.sh two_hours >rootmon.log 2>&1 &
EOF
    exit 1
fi
#
# Check we have a minitest on piranha
#
if minitest 150.135.2.78 $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT SLEW" </dev/null
then
    :
else
cat << EOF
On piranha, we need a minitest running, and it isn't. Proceed as follows.
-   log in as oracle on piranha
-   cd /u01/oracle/e2/perfdb
-   nohup ./setup.sh >minilog 2>&1 &
EOF
    exit 1
fi
#
# *****************************************************************************
# Clear out the work area, removing echo, log, dump and results files
#
rm  -rf $PATH_HOME/work/echotwo_hours* $PATH_HOME/work/logtwo_hours* $PATH_HOME/work/dumptwo_hours* $PATH_HOME/work/res*.bz2 $PATH_HOME/work/disttwo_hours*
#
# *****************************************************************************
# Re-extract the data that needs to be refreshed.
# 
cd $PATH_HOME/data
renew.sh AVAILABILITY BREAKS CAMPAIGN EPISODES OPEN PRODUCT 
cd $PATH_HOME/rules
./SPOTS.sh >/dev/null 2>&1
./NSPOTS.sh >/dev/null 2>&1
cd $PATH_HOME
#
# *****************************************************************************
# Create a new Scenario execution and allocate it to 150.135.2.77
# This code is lifted from fdexecute.sh, but is simplified.
# *****************************************************************************
# Create a scenario execution and set up the environment variables
#
run_ini two_hours
PATH_SE=two_hours.$seq
export PATH_SE
PATH_SCENE=two_hours
export PATH_SCENE
HOST_LIST=150.135.2.77
export HOST_LIST
#
# Get some candidate role hosts
#
first_script=`$PATH_AWK 'NR == 4 { print $2 ; exit }' $PATH_HOME/se/$PATH_SE/client/runout$PATH_SCENE`
. $PATH_HOME/scripts/$first_script/capset.sh
#
#  For this client
#
host=$HOST_LIST
#
# Create a directory for the host in the client sub-directory
#
if [ ! -d $PATH_HOME/se/$PATH_SE/client/$host ]
then
    mkdir $PATH_HOME/se/$PATH_SE/client/$host
fi
#
# Create runout files in it, copying/adjusting the files in the client
# sub-directory above
#
cp  $PATH_HOME/se/$PATH_SE/client/runout${PATH_SCENE}* $PATH_HOME/se/$PATH_SE/client/$host
#
# Generate the scripts, editing the End Points as appropriate
#
(
    cd $PATH_HOME/se/$PATH_SE/client/$host
    webscale $PATH_SCENE ""
)
#
# *****************************************************************************
# Distribute the scripts to the desired host
#
trafdist D $PATH_SE
#
# *****************************************************************************
# Execute the scenario
#
fdbatchrun.sh $PATH_SE
#
# *****************************************************************************
# Finish
#
exit
