#!/bin/ksh
e2sync() {
e2sync_seq=1
while :
do
E2SYNC_HOST=${E2SYNC_HOST:-$E2_USER_HOST}
narrative=`natmenu 3<<EOF 4>&1 </dev/tty >/dev/tty
HEAD=E2SYNC: Comment a script via UDP ECHO to host ($E2SYNC_HOST)
PROMPT=Fill in the details and Press RETURN
COMMAND=E2SYNC:
SEL_NO/COMM_NO/SYSTEM
SCROLL
Comments :

EOF
`
eval set -- $narrative
case $1 in
*E2SYNC:*)
shift
#udpecho evisat1t 7 "$e2sync_seq. $*"
#udpecho eviskb1t 7 "$e2sync_seq. $*"
udpecho "$E2SYNC_HOST" 7 "$e2sync_seq. $*"
e2sync_seq=`expr $e2sync_seq + 1`
;;
*)
return
;;
esac
done
}
