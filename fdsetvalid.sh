#!/bin/sh
# fdsetvalid.sh - check the directory structure, and create missing
# directories as needed.
if [ -z "$PATH_SOURCE" ]
then
    echo PATH_HOME and PATH_SOURCE must be set before this script runs
    sleep 3
    exit
fi
. $PATH_SOURCE/fdvars.sh
#
# Directories for the binaries for different operating systems 
#
if [ ! -d $PATH_HOME/config ]
then
cat << EOF
There is no config directory. I will create a skeleton, but remote distribution
depends on finding various binaries in directories corresponding to the
different target operating systems.

Each such directory has:
- A directory containing distribution components (dist)
- A file containing the name of self-extracting executable (extractor)
- A file containing the name of the default remote execution directory (def_dir)
- A file containing the name of the default remote distribution (distname)
- A file containing the name of the post-extraction setup command (setup)

This script creates plausible defaults for windows, linux and solaris, and
identifies the expected binary components, but obviously doesn't provide them

The UNIX-like operating systems are much the same; Windows is a bit different.
EOF
    mkdir $PATH_HOME/config
    for os in linux32 linux64 android solaris
    do
        mkdir $PATH_HOME/config/$os
        echo /opt/e2webtst > $PATH_HOME/config/$os/def_dir
        mkdir $PATH_HOME/config/$os/dist
        echo  $PATH_HOME/config/$os/dist should contain:
        echo  e2selfex,$PATH_DRIVER,miniarc,minitest,pathenv.sh,setup.sh,client.pem,mempat,fhunt,logmon
        echo e2webtest > $PATH_HOME/config/$os/distname
        echo e2selfex > $PATH_HOME/config/$os/extractor
        echo ./setup.sh > $PATH_HOME/config/$os/setup
    done
    mkdir $PATH_HOME/config/windows
    echo c:\\e2webtst > $PATH_HOME/config/windows/def_dir
    mkdir $PATH_HOME/config/windows/dist
    echo  $PATH_HOME/config/windows/dist should contain:
    echo bzip2.exe,client.pem,e2nettst.exe,e2rless.exe,e2selfex.exe,libeay32.dll,libssl32.dll,Microsoft.VC90.CRT.manifest,miniarc.exe,minitest.exe,msvcm90.dll,msvcp90.dll,msvcr90.dll,pathenv.sh,$PATH_DRIVER,ssleay32.dll,mempat.exe,fhunt.exe
    echo e2path.exe > $PATH_HOME/config/windows/distname
    echo e2selfex.exe > $PATH_HOME/config/windows/extractor
    echo e2nettst.exe > $PATH_HOME/config/windows/setup
fi
#
# Create the top level directories
# - data      - extracted data that is merged with scripts to produce echo files
# - rules     - the home for extract scripts
# - scenes    - Scenario definitions
# - hosts     - directories corresponding to participating hosts
# - scripts   - directories correspondiong to available scripts
# - bothways  - directories containg original captures
# - se        - scenario execution control directories
# - work      - base for local agent test activity and multi-agent co-ordination
# - results   - base for analysis of the results
# - csscripts - common script elements, eg. the login sequence
#
for i in data hosts rules scenes scripts se work results csscripts bothways sessions
do
    if [ ! -d $PATH_HOME/$i ]
    then
        echo Directory $i does not exist ... creating
        mkdir $PATH_HOME/$i
    fi
done
cp $PATH_HOME/web_path_web/project.html $PATH_HOME/data/project.html
echo All expected directories are now present
exit
