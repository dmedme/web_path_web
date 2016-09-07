#!/bin/bash
export PATH=/home/bench/lonmet/lin64bin:/home/bench/lonmet/web_path_web:$PATH
export PATH_HOME=/home/bench/lonmet
export PATH_SOURCE=$PATH_HOME/web_path_web
export NAMED_PIPE_PREFIX=$PATH_HOME/sessions/
killall sslserv ptydrive t3drive
cd $PATH_HOME
rm -f $NAMED_PIPE_PREFIX/*
while netstat -n -a | grep 7000
do
sleep 1
done
sslserv -d 4 -p 7000 -c 1:/home/e2soft/e2prox/server.pem:password >webpath.log 2>&1 &
