#!/bin/bash
# Make it as painless as possible to conduct a 6400 public + 1000 professionl user
# controlled test lasting about 1 hour. The scenario is called, 6400pub1000prof.
#
# Run this and put it in the background with the output re-directed to a file.
# e.g.
#     /home/bench/fluline/path_web/autoallrun.sh >/home/bench/fluline/autoallrun.log 2>&1 &
#
# Overview
# ========
# 1. Clear out the work area, removing echo, log, dump and results files
# 2. Remove the existing 'scenario execution' 6400pub1000prof.
# 3. Re-extract or reset the data that will be re-used
#    -  MALE and FEMALE
#    -  Combine them
# 4. Create a new 'scenario execution' for 6400pub1000prof, and assign it to
#    172.23.23.66, 172.23.23.67, 172.23.23.68, 172.23.23.69.
# 5. Distribute the new scenario.
# 6. Execute the scenario. Once this has started, ps should show:
#    -  multiple minitest processes
#    -  multiple racdrive processes (one for each group of pseudo-users).
#    racdrive processes run until they run out of input, or they are terminated
#    The child minitest controls the run. It exits at the end of the hour.
# 7. When the scenario has finished:
#      -  Dump files /home/bench/fluline/work/dump*.0 are the best indicators as to how
#         well things have worked. Tell-tale signs of problems are presence of
#         Error aspx redirect pages.
#      -  Response times are summarised in files timout.html files, eg.
#         /home/bench/fluline/work/6400pub1000prof.1/timout.html
# 8. If it is desired to look further at the collected data, I suggest it be
#    moved or copied to a convenient location. I have been using
#    sub-directories under /home/bench/fluline/results for this purpose. Note that the
#    response time data are actually deleted by the next run of this
#    script.
# *****************************************************************************
multi_scene=6400pub1000prof
export multi_scene
set -x
. /home/bench/fluline/path_web/fdvars.sh
. $PATH_SOURCE/fdrunini.sh
. $PATH_SOURCE/fdwebscale.sh
. $PATH_SOURCE/fdtrafdist.sh
# *****************************************************************************
#
# Check we have minitests everywhere
#
for i in 66 67 68 69
do
if minitest 172.23.23.$i $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT SLEW" </dev/null
then
    :
else
cat << EOF
On $i, we need a minitest running, and it isn't. Proceed as follows.
-   log in as e2 on $i with ssh
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
for i in 66 67 68
do
minitest 172.23.23.$i $E2_HOME_PORT EXEC "rm -rf $PATH_HOME/work/echo$multi_scene* $PATH_HOME/work/log$multi_scene* $PATH_HOME/work/dump$multi_scene* $PATH_HOME/work/res*.bz2 $PATH_HOME/work/dist$multi_scene*" </dev/null
done
#
# Make sure we have the correct load balance configuration
#
for i in 66 67 68 69
do
minitest 172.23.23.$i $E2_HOME_PORT EXEC "cp patch_16.sh patch_nlb.sh" </dev/null
done
# *****************************************************************************
# Re-extract the data that needs to be refreshed.
# 
cd $PATH_HOME/data
tidydata.sh 150000 MALE FEMALE
tail -45000 FEMALE.db >> MIXED.db
tail -45000 MALE.db >> MIXED.db
head -105000 FEMALE.db >FEMALE.tmp
mv FEMALE.tmp FEMALE.db
head -105000 MALE.db >MALE.tmp
mv MALE.tmp MALE.db
cd $PATH_HOME
#
# *****************************************************************************
# Create a new Scenario execution and allocate it to 172.23.23.66,67,68,69
# This code is lifted from fdexecute.sh, but is simplified.
# *****************************************************************************
# Create a scenario execution and set up the environment variables
#
run_ini $multi_scene
PATH_SE=$multi_scene.$seq
export PATH_SE
PATH_SCENE=$multi_scene
export PATH_SCENE
HOST_LIST="172.23.23.66 172.23.23.67 172.23.23.68 172.23.23.69"
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
# Wait for the distribution to finish. We are the last host, so when we have
# finished, they should all have finished.
#
while ps -ef | grep "patch_[n]lb"
do
sleep 60
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
