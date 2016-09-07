#!/bin/sh
# edconv.sh - attempt to adapt the scripts captured at Edinburgh University
# so that they can run elsewhere
for i in scripts/*/*.msg
do
ex $i << EOF
g/:129.215.180.82/s//:13.22.37.88/g
g/:129.215.240.40/s//:10.8.21.5/g
g/:5080:/s//:80:/g
g/:9550:/s//:9500:/g
g/;5080/s//;80/g
g/;9550/s//;9500/g
g/[ 0-3][0-9] Jul 2002/s//26 Sep 2002/
g=/e22live/efinlive.htm=s==/efintest/efintest.htm=g
g=/e22live=s==/efintest=g
g/brodie.mis.ed.ac.uk:5080/s//10.8.21.5:80/g
g=e22live=s==efinluht=g
w
q
EOF
done
