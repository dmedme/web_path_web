#!/bin/bash
# Make it as painless as possible to conduct a controlled test lasting
# about 1/2 hour. The scenario is called, scenCthird.
#
# Run this and put it in the background with the output re-directed to a file.
# e.g.
#     /home/bench/euclid/autoprofrun.sh >/home/bench/euclid/autoprofrun.log 2>&1 &
#
# Overview
# ========
# 1. Clear out the work area, removing echo, log, dump and results files
# 2. Remove the existing 'scenario execution' scenCthird.
# 3. Re-extract or reset the data that will be re-used
#    -  extract for transactions
#    -  reset for enquiries
# 4. Create a new 'scenario execution' for scenCthird, and assign it to
#    129.215.254.166 (not using 129.215.254.129 129.215.254.130)
# 5. Distribute the new scenario.
# 6. Execute the scenario. Once this has started, ps should show:
#    -  multiple minitest processes
#    -  multiple racdrive processes (one for each pseudo-user).
#    racdrive processes run until they run out of input, or they are terminated
#    The child minitest controls the run. It exits at the end of the test.
# 7. When the scenario has finished:
#      -  Dump files /home/bench/euclid/work/dump*.0 are the best indicators as to how
#         well things have worked. Tell-tale signs of problems are presence of
#         error aspx redirect pages.
#      -  Response times are summarised in files timout.html files, eg.
#         /home/bench/euclid/work/scenCthird.1/timout.html
# 8. If it is desired to look further at the collected data, I suggest it be
#    moved or copied to a convenient location. I have been using
#    sub-directories under /home/bench/euclid/results for this purpose. Note that the
#    response time data are actually deleted by the next run of this
#    script.
# *****************************************************************************
multi_scene=scenCthird
export multi_scene
set -x
. /home/bench/euclid/path_web/fdvars.sh
. $PATH_SOURCE/fdrunini.sh
. $PATH_SOURCE/fdwebscale.sh
. $PATH_SOURCE/fdtrafdist.sh
# *****************************************************************************
#
# Check we have minitests everywhere
#
#for i in 166 129 130
for i in 129 166
do
if minitest 129.215.254.$i $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT SLEW" </dev/null
then
    :
else
cat << EOF
On $i, we need a minitest running, and it isn't. Proceed as follows.
-   log in as dme on $i with ssh
-   cd $PATH_HOME/work
-   sudo bash
-   nohup ./setup.sh >minilog 2>&1 &
EOF
    exit 1
fi
done
# *****************************************************************************
# Clear out any existing scenario executions
#
rm -rf $PATH_HOME/se/$multi_scene.*
# *****************************************************************************
# Clear out the work area, removing echo, log, dump and results files
#
rm -rf $PATH_HOME/work/echo$multi_scene* $PATH_HOME/work/log$multi_scene* $PATH_HOME/work/dump$multi_scene* $PATH_HOME/work/res*.bz2 $PATH_HOME/work/dist$multi_scene*
for i in 129 166
do
minitest 129.215.254.$i $E2_HOME_PORT EXEC "rm -rf $PATH_HOME/work/echo$multi_scene* $PATH_HOME/work/log$multi_scene* $PATH_HOME/work/dump$multi_scene* $PATH_HOME/work/res*.bz2 $PATH_HOME/work/dist$multi_scene*" </dev/null
done
#
# Make sure we have the correct load balance configuration
#
for i in 129 166
do
minitest 129.215.254.$i $E2_HOME_PORT EXEC "cp patch_2.sh patch_nlb.sh" </dev/null
done
#
# *****************************************************************************
# Re-extract the data that needs to be refreshed.
# 
cd $PATH_HOME/rules
./getdata.sh
cd $PATH_HOME/data
./restoreUGPGHUBqry.sh
cd $PATH_HOME
#
# *****************************************************************************
# Create a new Scenario execution and allocate it to 129.215.254.166,129,130
# This code is lifted from fdexecute.sh, but is simplified.
# *****************************************************************************
# Create a scenario execution and set up the environment variables
#
run_ini $multi_scene
PATH_SE=$multi_scene.$seq
export PATH_SE
PATH_SCENE=$multi_scene
export PATH_SCENE
#HOST_LIST="129.215.254.166 129.215.254.129 129.215.254.130"
HOST_LIST="129.215.254.129 129.215.254.166"
export HOST_LIST
#
# Get some candidate role hosts
#
first_script=`$PATH_AWK 'NR == 4 { print $2 ; exit }' $PATH_HOME/se/$PATH_SE/client/runout$PATH_SCENE`
. $PATH_HOME/scripts/$first_script/capset.sh
#
#  For this client
#
for host in $HOST_LIST
do
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
done
#
# *****************************************************************************
# Distribute the scripts to the desired hosts
#
trafdist D $PATH_SE
# *****************************************************************************
# Wait for the distribution to finish
#
while ps -ef | grep "patch_[n]lb"
do
sleep 10
done
# *****************************************************************************
# Execute the scenario
#
fdbatchrun.sh $PATH_SE
#
# *****************************************************************************
# Finish
#
exit
