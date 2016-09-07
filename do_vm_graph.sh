#!/bin/ksh
#
# Example gnuplot graphing script
#
start_time=1220009764
/home/e2soft/perfdb/sarprep -t 20 -s $start_time -v vm20.log
export GDFONTPATH=/usr/share/fonts/type1/gsfonts
{
set `head -2 vmout.txt | tail -1`
beg_ts="$1 $2 $3 $4"
beg_us=$5
beg_s=$6
set `tail -1 vmout.txt`
end_ts="$1 $2 $3 $4"
cat << EOF
set terminal png nocrop enhanced font a010015l size 640,480
set output 'vmstat.png'
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set y2tics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set title "euclid-test-2 (V490)\\nCPU Load and Submission Response Times"
set xdata time
set timefmt "%d %b %Y %H:%M:%S"
set xrange [ "$beg_ts" : "$end_ts" ] noreverse nowriteback
unset xtics
set yrange [ 0.0000 : 100.000 ] noreverse nowriteback
set lmargin 9
set rmargin 9
set ylabel 'CPU Percentage' offset 1
set y2label 'Run Queue' offset 1
set multiplot
set bmargin 0
set size 1, 0.5
set origin 0, 0.5
plot '-' using 1:5 title "User+System CPU %" with lines, \
     '-' using 1:5 title "System CPU %" with lines,      \
     '-' using 1:5 title "Run Queue" axes x1y2 with lines
EOF
$PATH_AWK 'BEGIN {getline}
{ print $1 " " $2 " " $3 " " $4 " " ($5 + $6)}
END {print "e" }' vmout.txt
$PATH_AWK 'BEGIN {getline}
{ print $1 " " $2 " " $3 " " $4 " " $6}
END {print "e" }' vmout.txt
$PATH_AWK 'BEGIN {getline}
{ print $1 " " $2 " " $3 " " $4 " " $5}
END {print "e" }' vmrunq.txt
rdgs=`$PATH_AWK -F: 'BEGIN {x = 0} NF == 7 && $6 == "B3" {x++} END { print x}' comout.evt`
cat << EOF
unset title
unset y2label
unset y2tics
unset yrange
set autoscale y
set format x "%R"
set xtics border out scale 1,0.5 mirror norotate  offset character 0, 0, 0
set xlabel 'Time ($rdgs readings)' offset 1
set size 1, 0.5
set origin 0, 0
set tmargin 0
set ylabel 'Response/seconds'
set bmargin
plot '-' using 1:5 notitle with points
EOF
$PATH_AWK -F: 'NF == 7 && $6 == "B3" { print (substr($5,1,10) -3600) " " $7/100}
END {print "e"}' comout.evt | while read x y
do
   if [ "$x" = "e" ]
   then
       echo $x
   else
       echo `/home/e2soft/e2common/todate $x` $y
   fi
done | sed 's/-/ /g'
} | tee fred.log | gnuplot
gqview vmstat.png &
