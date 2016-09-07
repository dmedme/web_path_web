#!/bin/bash
# *************************************************************************
# Graph ORACLE KPI data. The data is piped in
#
beg_ts=$1
end_ts=$2
boring=$3
shift
shift
shift
kpi="$*"
kpi_file=`echo $kpi | sed 's/ /_/g
s/:/./g
s=/=-=g'`
export GDFONTPATH=/usr/share/fonts/type1/gsfonts
{
cat << EOF
set terminal png nocrop enhanced font a010015l 10 size 640,480
set output '$kpi_file.png'
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set title "$kpi\\nEUCLID Database Server" font  'a010015l,14'
set xdata time
set timefmt "%s"
set xrange [ "$beg_ts" : "$end_ts" ] noreverse nowriteback
unset xtics
set lmargin 9
set rmargin 9
set bmargin 9
set size 1,1
set origin 0,0
set format x "%R"
set xtics border out scale 1,0.5 mirror rotate by -90  offset character 0, 0, 0
set xlabel 'Time' offset 1 font  'a010015l,12'
plot '-' using 1:2 title "$kpi" with lines
EOF
#
# The input stream
# } delimited
# - time/seconds since 1970
# - duration/seconds
# - the thing
# - the value
#
$PATH_AWK -F"}" 'BEGIN { flag = 0}
NF == 4 {
    print $1 " " $4/$2
    if ($4/$2 > 1 || $4/$2 < -1)
        flag = 1
}
END {
    print "e"
    if (flag == 0)
        print "'$kpi_file'.png" >>"'$boring'"
}'
} | gnuplot
exit
