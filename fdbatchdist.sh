#!/bin/ksh
# Distribute scenarios detached from the terminal
#
# Parameters:
# 1 - (F)ull binary (including executables) or (R)emote copy
# 2 ...  The scenario incarnations to distribute
if [ $# -lt 2 ]
then
    echo Provide "(F)"ull or scripts, for the distribution approach desired
    exit
fi
full_ind=$1
shift
ses=$*
. $PATH_SOURCE/fdvars.sh
. fdtrafdist.sh
set -x
for i in $ses
do
trafdist $full_ind $i
done
