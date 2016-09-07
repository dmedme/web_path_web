#!/bin/bash
export GDFONTPATH=/usr/share/fonts/type1/gsfonts
# *************************************************************************
# Graph vmstat output massaged by sarprep
#
do_sardsk_graphs() {
mc=$1
os=$2
#
# First the utilisation graph
#
{
set `head -2 sar_dsk.txt | tail -1`
beg_ts="$1 $2 $3 $4"
beg_us=$5
beg_s=$6
set `tail -1 sar_dsk.txt`
end_ts="$1 $2 $3 $4"
cat << EOF
set terminal png nocrop enhanced font a010015l 10 size 640,480
set output '../$mc.dskact.png'
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set y2tics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set title "$mc ($os)\\nDisk Activity" font  'a010015l,14'
set xdata time
set timefmt "%d %b %Y %H:%M:%S"
set xrange [ "$beg_ts" : "$end_ts" ] noreverse nowriteback
unset xtics
set autoscale y
set lmargin 9
set rmargin 9
set ylabel 'Disk Read+Writes/k' offset 1 font  'a010015l,12'
set multiplot
set bmargin 5
set size 1,1
set origin 0,0
set format x "%R"
set xtics border out scale 1,0.5 mirror rotate by -90  offset character 0, 0, 0
set xlabel 'Time' offset 1 font  'a010015l,12'
EOF
$PATH_AWK '{
    dsks= (NF -1)/2
    verb= "plot"
    for (i = 2; i < 1 + dsks; i++)
    {
        print verb " '\''-'\'' using 1:5 title \"" $i "\" with lines, \\"
        verb = ""
    }
    print verb " '\''-'\'' using 1:5 title \"" $i "\" with lines"
    exit
}' sar_dsk.txt
dsks=`awk '{ print (NF -1)/2; exit}' sar_dsk.txt`
i=0
while [ $i -lt $dsks ]
do
awk 'BEGIN {getline
dsk=5+'$i'
}
{ print $1 " " $2 " " $3 " " $4 " " $dsk}
END {print "e" }' sar_dsk.txt
i=`expr $i + 1`
done
} | tee fred1.log | gnuplot
#
# Now the response time graph
#
{
set `head -2 sar_dsk.txt | tail -1`
beg_ts="$1 $2 $3 $4"
beg_us=$5
beg_s=$6
set `tail -1 sar_dsk.txt`
end_ts="$1 $2 $3 $4"
cat << EOF
set terminal png nocrop enhanced font a010015l 10 size 640,480
set output '../$mc.dskresp.png'
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set y2tics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set title "$mc ($os)\\nDisk Response Times" font  'a010015l,14'
set xdata time
set timefmt "%d %b %Y %H:%M:%S"
set xrange [ "$beg_ts" : "$end_ts" ] noreverse nowriteback
unset xtics
set autoscale y
set lmargin 9
set rmargin 9
set ylabel 'Disk Response/ms' offset 1 font  'a010015l,12'
set multiplot
set bmargin 5
set size 1,1
set origin 0,0
set format x "%R"
set xtics border out scale 1,0.5 mirror rotate by -90  offset character 0, 0, 0
set xlabel 'Time' offset 1 font  'a010015l,12'
EOF
awk '{
    dsks= (NF -1)/2
    verb= "plot"
    for (i = 2; i < 1 + dsks; i++)
    {
        print verb " '\''-'\'' using 1:5 title \"" $i "\" with lines, \\"
        verb = ""
    }
    print verb " '\''-'\'' using 1:5 title \"" $i "\" with lines"
    exit
}' sar_dsk.txt
dsks=`awk '{ print (NF -1)/2; exit}' sar_dsk.txt`
i=0
while [ $i -lt $dsks ]
do
awk 'BEGIN {getline
dsk=5+'$i'+'$dsks'
}
{ print $1 " " $2 " " $3 " " $4 " " $dsk}
END {print "e" }' sar_dsk.txt
i=`expr $i + 1`
done
} | tee fred2.log |gnuplot
}
do_sardsk_graphs sit-db-01 Solaris
