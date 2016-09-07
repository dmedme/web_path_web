#!/bin/bash
# Initialise an Android PATH directory tree
#
dirname=e2
export dirname
mkdir /opt/NVPACK/local/$dirname
#
# Copy over the scripts
#
    find web_path_web \( -name "*.ico" -o -name "*.png" -o -name "*.sh" -o -name "*.jpg" -o -name "*.gif" -o -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.txt" \) -print | cpio -pmd /opt/NVPACK/local/"$dirname"
#
# Copy over the binaries
#
cd  /opt/NVPACK/local/"$dirname"
mkdir androidarm7
mkdir bothways
mkdir config
mkdir config/linux32
mkdir config/linux32/dist
echo /home/webtest >config/linux32/def_dir
echo e2webtst >config/linux32/distname
echo e2selfex >config/linux32/extractor
echo setup.sh >config/linux32/setup
mkdir config/linux64
mkdir config/linux64/dist
echo /home/webtest >config/linux64/def_dir
echo e2webtst >config/linux64/distname
echo e2selfex >config/linux64/extractor
echo setup.sh >config/linux64/setup
mkdir config/solaris
mkdir config/solaris/dist
echo /home/webtest >config/solaris/def_dir
echo e2webtst >config/solaris/distname
echo e2selfex >config/solaris/extractor
echo setup.sh >config/solaris/setup
mkdir config/windows
mkdir config/windows/dist
echo c:/e2 >config/windows/def_dir
echo e2webtst.exe >config/windows/distname
echo e2selfex.exe >config/windows/extractor
echo e2nettst.exe >config/windows/setup
mkdir config/android
mkdir config/android/dist
echo /data/local/e2 >config/android/def_dir
echo e2webtst >config/android/distname
echo e2selfex >config/android/extractor
echo setup.sh >config/android/setup
#
# These files should be present
#
#./config/linux32/dist/fhunt
#./config/linux32/dist/logmon
#./config/linux32/dist/mempat
#./config/linux32/dist/miniarc
#./config/linux32/dist/minitest
#./config/linux32/dist/pathenv.sh
#./config/linux32/dist/setup.sh
#./config/linux32/dist/t3drive
#./config/linux64/dist/fhunt
#./config/linux64/dist/logmon
#./config/linux64/dist/mempat
#./config/linux64/dist/miniarc
#./config/linux64/dist/minitest
#./config/linux64/dist/pathenv.sh
#./config/linux64/dist/ptydrive
#./config/linux64/dist/setup.sh
#./config/linux64/dist/t3drive
#./config/windows/dist/ATLIco.exe
#./config/windows/dist/bzip2.exe
#./config/windows/dist/e2nettst.exe
#./config/windows/dist/fhunt.exe
#./config/windows/dist/logmon.exe
#./config/windows/dist/mempat.exe
#./config/windows/dist/miniarc.exe
#./config/windows/dist/minitest.exe
#./config/windows/dist/pathenv.sh
#./config/windows/dist/rubber.dll
#./config/windows/dist/t3drive.exe
mkdir csscripts
mkdir data
mkdir hosts
mkdir lin32bin
#./lin32bin/aixdump2snp
#./lin32bin/ascbin
#./lin32bin/autoscript
#./lin32bin/e2fifin
#./lin32bin/e2fifout
#./lin32bin/e2join
#./lin32bin/e2selfex
#./lin32bin/e2sort
#./lin32bin/fastclone
#./lin32bin/fdreport
#./lin32bin/fhunt
#./lin32bin/genconv
#./lin32bin/increp
#./lin32bin/ipdanal
#./lin32bin/ipdrive
#./lin32bin/IRindgen
#./lin32bin/IRsearch
#./lin32bin/jsonify
#./lin32bin/logmon
#./lin32bin/mempat
#./lin32bin/miniarc
#./lin32bin/minitest
#./lin32bin/ptydrive
#./lin32bin/setup.sh
#./lin32bin/snoopfix
#./lin32bin/t3drive
#./lin32bin/todate
#./lin32bin/tosecs
#./lin32bin/trafmul
#./lin32bin/udpecho
#./lin32bin/ungz
#./lin32bin/unquote
#./lin32bin/wbrowse
#./lin32bin/webdump
mkdir lin64bin
#./lin64bin/aixdump2snp
#./lin64bin/ascbin
#./lin64bin/autoscript
#./lin64bin/e2fifin
#./lin64bin/e2fifout
#./lin64bin/e2join
#./lin64bin/e2selfex
#./lin64bin/e2sort
#./lin64bin/fastclone
#./lin64bin/fdreport
#./lin64bin/fhunt
#./lin64bin/genconv
#./lin64bin/increp
#./lin64bin/ipdanal
#./lin64bin/ipdrive
#./lin64bin/IRindgen
#./lin64bin/IRsearch
#./lin64bin/jsonify
#./lin64bin/logmon
#./lin64bin/mempat
#./lin64bin/miniarc
#./lin64bin/minitest
#./lin64bin/ptydrive
#./lin64bin/setup.sh
#./lin64bin/snoopfix
#./lin64bin/t3drive
#./lin64bin/todate
#./lin64bin/tosecs
#./lin64bin/trafmul
#./lin64bin/udpecho
#./lin64bin/ungz
#./lin64bin/unquote
#./lin64bin/wbrowse
#./lin64bin/webdump
mkdir results
mkdir rules
mkdir scenes
mkdir scripts
mkdir se
mkdir winbin
#./winbin/ascbin.exe
#./winbin/ATLIco.exe
#./winbin/autoscript.exe
#./winbin/bzip2.exe
#./winbin/bzip2recover.exe
#./winbin/e2fifin.exe
#./winbin/e2fifout.exe
#./winbin/e2join.exe
#./winbin/e2nettst.exe
#./winbin/e2rless.exe
#./winbin/e2selfex.exe
#./winbin/e2sort.exe
#./winbin/fastclone.exe
#./winbin/fdreport.exe
#./winbin/fhunt.exe
#./winbin/firefox.bat
#./winbin/increp.bat
#./winbin/IRindgen.exe
#./winbin/IRsearch.exe
#./winbin/jsonify.exe
#./winbin/logmon.exe
#./winbin/mempat.exe
#./winbin/miniarc.exe
#./winbin/minitest.exe
#./winbin/rubber.dll
#./winbin/t3drive.exe
#./winbin/todate.exe
#./winbin/tosecs.exe
#./winbin/ungz.exe
#./winbin/unquote.exe
#./winbin/wbrowse.exe
#./winbin/webpath.bat
#./wintoys/rubber.dll
mkdir work
#./work/ATLIco.exe
#./work/e2nettst.exe
#./work/echoesri.1.0
#./work/echoesri.1.1
#./work/echoesri.1.2
#./work/echoesri.1.3
#./work/echoesri.1.4
#./work/fdreport.exe
#./work/fhunt.exe
#./work/increp.bat
#./work/logmon.exe
#./work/mempat.exe
#./work/minitest.exe
#./work/pathenv.sh
#./work/rubber.dll
cd /opt/NVPACK
#
# Process a list of binary files and where they come from
#
    for i in miniarc e2selfex
    do
        cp bzip2/$i /opt/NVPACK/local/"$dirname"/androidarm7
    done
#
# Linux version of e2sync, and a useful utility
#
    for i in udpecho relay tcptrigger
    do
        cp random/$i /opt/NVPACK/local/"$dirname"/androidarm7
    done
#
# Program to keep a terminal live, for the benefit of shell scripts serving
# the web
#
    cp path/ptydrive /opt/NVPACK/local/"$dirname"/androidarm7
#
# The report/monitoring output utility
#
# Test manager, snoop file processor, snoop file report utilities, libpcap-to-
# snoop format conversion, snoop-format-to-ipdanal format conversion, file
# output tracker (for interval-based real-time output support).
#
#    for i in webdump genconv snoopfix aixdump2snp trafmul ipdanal logmon
    for i in logmon
    do 
        cp e2net/$i /opt/NVPACK/local/"$dirname"/androidarm7
    done
#
# Generic utilities; menu processor, seconds-since-1970, date from seconds-
# since-1970, general file format conversion (in particular, conversion to and
# from the E2 standard ASCII representation of binary files), a Solaris SPARC
# pacct file reader, portable sort and join utilities, a memory patcher and a Boyes-Moore pattern search utility
#
#    for i in natmenu tosecs todate unquote ascbin solhisps e2sort e2join mempat fhunt
    for i in natmenu tosecs todate unquote ascbin e2sort e2join mempat fhunt
    do 
        cp e2common/$i /opt/NVPACK/local/"$dirname"/androidarm7
    done
# Fast data/script merge utility
    for i in fastclone wbrowse fdreport
    do
        cp fastclone/$i /opt/NVPACK/local/"$dirname"/androidarm7
    done
#
# Multi-threaded HTTP-only version of the script driver data/script merge
# utility
#
    for i in t3drive autoscript jsonify ungz dec_aes rawinflate rawdeflate
    do
        cp e2prox/$i /opt/NVPACK/local/"$dirname"/androidarm7/$i
    done
#
# Utility that provides the HTTP interface to the shell scripts
#
    for i in minitest e2fifin e2fifout
    do
        cp webtest/$i /opt/NVPACK/local/"$dirname"/androidarm7
    done
#
# Utilities for ORACLE database dumping and fast schema comparison
#
#    for i in tabdiff e2schem_cmp
#    do
#        cp schema/$i /opt/NVPACK/local/"$dirname"/androidarm7
#    done
#
# Utilities for ORACLE SQL tracking and performance monitor output manipulation
#
#    for i in badsort sarprep sqlize.sh lockcheck.sh
#    do
#        cp perfdb/$i /opt/NVPACK/local/"$dirname"/androidarm7
#    done
#
# Patch pathenv.sh
#
    cd /opt/NVPACK/local/"$dirname"/web_path_web
    ex fdbase.sh << EOF
g=/opt/NVPACK/local/fluline=s==/data/local/$dirname=g
w
q
EOF
    mkdir ../work
    cp setup.sh pathenv.sh ../work
    cd ../androidarm7
    cp t3drive minitest miniarc e2selfex logmon fhunt mempat ../work
    cd ..
