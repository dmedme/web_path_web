#!/bin/sh
i=0
while :
do
    while [ -f test.$i.snp ]
    do
        i=`expr $i + 1`
    done
    snoop -o test.$i.snp host 172.17.177.171 >/dev/null 2>&1
    i=`expr $i + 1`
done
