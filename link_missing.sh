#!/bin/bash
# link_missing.sh - create symbolic links for the missing scripts
# ***************************************************************************
# Most of the scripts include shell functions by specifying PATH_SOURCE
#
# There is thus a need to provide links to the scripts (and other objects) in
# the parallel path_web directory that don't have web-specific versions.
#
# This script sets them up.
#
if [ -z "$PATH_SOURCE" ]
then
    echo You must set PATH_SOURCE to the target directory before running this
    exit
elif [ ! -d $PATH_SOURCE -a ! -f $PATH_SOURCE/webpath.sh ]
then
    echo PATH_SOURCE "($PATH_SOURCE)" is not a directory containing webpath.sh
    exit
fi
# To begin with, get rid of any existing links
find $PATH_SOURCE -type l -exec rm \{\} \;
for ext in sh jpeg png gif
do
    for i in $PATH_SOURCE/../path_web/*.$ext
    do
        j=$PATH_SOURCE/`echo $i | sed 's=.*/=='`
        if [ -f "$i" -a ! -f "$j" ]
        then
            ln -s $i $j
        fi
    done
done
