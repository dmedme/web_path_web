#!/bin/ksh
hosts_to_check=$*
. $PATH_SOURCE/fdvars.sh
for i in $hosts_to_check
do
minitest $i $E2_HOME_PORT EXEC "minitest $E2_HOME_HOST $E2_HOME_PORT SLEW" </dev/null &
mpid=$!
sleep 20
kill $mpid
done
