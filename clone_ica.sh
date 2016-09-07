#!/bin/bash
>c:/e2/data/USEREDITS.dat
for tmplt in ukwarctxtest0?.ica ukwarctx20.ica
do
i=1
bn=`echo $tmplt | sed 's/\.ica//'`
while [ "$i" -lt 21 ]
do
pat=`printf "%02d" $i`
sed 's/Connect ica.emr.com "netperf" /Connect ica.emr.com "nettest'$pat'" /
s/N3tworkP3rformance/Password'$i'/' $tmplt >${bn}_nettest$pat.ica
echo 'Connect ica.emr.com "nettest'$pat'" c:\e2\work\'$bn'_nettest'$pat.ica >>c:/e2/data/USEREDITS.dat
i=`expr $i + 1`
done
done
cp ukwarctx*_nettest??.ica c:/e2/work
exit
