#!/bin/bash
# mon_coord.sh - Pick up monitoring data in an automated manner
#                co-ordinated with tests
#
# The only channel that is guaranteed to be open between any of the
# interesting hosts that can actually see each other is 22, ssh
#
# We don't have auto-login set up between them.
#
# The solution is to set up channels forwarded channels between them
# and to use minitest to remotely start monitors and return results.
#
# We use:
# -  on e2acer4 (our driver)
#    -  5000 - its own minitest
#    -  5001 - forwarded to mylo, for evisat1
#    -  5002 - forwarded to mylo, for eviskb1
#    -  5003 - forwarded to mylo, for kb-cmt-x86-1
#    -  5004 - forwarded to mylo, for kb-cmt-x86-2
#    -  potentially others forwarded to other machines, e.g. kb-cmt-sparc, seton
# - on mylo, the co-ordinater, the only machine that can see everything
#    -  5000 - forwarded to our own machine 5000
#    -  5001 - forwarded to evisat1 5000
#    -  5002 - forwarded to eviskb1 5000
#    -  5003 - forwarded to kb-cmt-x86-1 5000
#    -  5004 - forwarded to kb-cmt-x86-2 5000
# - on each of evisat1, eviskb1, cmt-kb-x86-1, cmt-kb-x86-2
#    -  5000 - its own minitest
#    -  5001 - forwarded to mylo 5000, and thus to our own machine 5000
#
# To set up the channels, from our own machine, we must execute:
#    ssh -f -n -L5001:127.0.0.1:5001  -L5002:127.0.0.1:5002  -L5003:127.0.0.1:5003  -L5004:127.0.0.1:5004  -R5000:127.0.0.1:5000 -N davide@mylo.mis.ed.ac.uk
# And on mylo, we must execute the following (this script, in fact)
while read host port
do
    ssh -f -n -L$port:127.0.0.1:5000 -R5001:127.0.0.1:5000 -N urouter@$host "minitest 5000" >/dev/null
done << EOF
evisat1 5001
eviskb1 5002
kb-cmt-x86-1 5003
kb-cmt-x86-2 5004
EOF
#
# Hopefully the connections established in this manner will survive logout.
#
exit

