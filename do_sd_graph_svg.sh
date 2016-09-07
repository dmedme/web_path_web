#!/bin/bash
# Process disk data to give SVG graphs
set -- `$PATH_AWK 'BEGIN {
    getline
    dsks = (NF - 1)/2
    top_io = 0
    top_resp = 0
    for (i = 0; i < dsks; i++)
        dname[i] = $(i+2)
}
{
    c = 5
    for (i = 0; i < dsks; i++)
    {
        io[i] += $c
        if ($c > top_io)
            top_io = $c
        if ($(c + dsks) > top_resp)
            top_resp = $(c + dsks)
        c++
    }
}
END {
   for (i = 0; i < dsks; i++)
       dsk[i] = i
   for (i = 0; i < dsks - 1; i++)
       for (j = dsks - 1; j > i; j--)
           if (io[dsk[i]] < io[dsk[j]])
           {
               x = dsk[i]
               dsk[i] = dsk[j]
               dsk[j] = x
           }
    print top_io
    print top_resp
    for(i = 0; i < dsks && i < 10; i++)
    {
        print dsk[i]
        print dname[dsk[i]]
    }
}' sar_dsk.txt`
top_io=$1
shift
top_resp=$1
shift
all_disks=$*
dsk_cnt=`expr $# / 2`
set `head -2 sar_dsk.txt | tail -1`
beg_ts="$1 $2 $3 $4"
set `tail -1 sar_dsk.txt`
end_ts="$1 $2 $3 $4"
for pass in 0 1
do
set -- $all_disks
dsk_cnt=$#
case $pass in
0)
    desc=Activity
    outp=act
    top_rng=$top_io
    ylbl="Transfers/s"
    ;;
1)
    desc=Response
    outp=resp
    top_rng=$top_resp
    ylbl="Response/ms"
    ;;
esac
cat << EOF
set terminal svg noenhanced font "sans" fsize 8 size 640 480
set output 'disk_$outp.svg'
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set title "eh-mbt-t-fin02 (App Server)\\nTop 10 Disks $desc" font  'sans,14'
set xdata time
set timefmt "%d %b %Y %H:%M:%S"
set xrange [ "$beg_ts" : "$end_ts" ] noreverse nowriteback
set yrange [ 0.0000 : $top_rng ] noreverse nowriteback
set lmargin 9
set rmargin 9
set bmargin
set ylabel '$ylbl' offset 1 font  'sans,12'
set format x "%R"
set xtics border out scale 1,0.5 nomirror rotate by -90  offset character 0, 0, 0
set xlabel 'Time' offset 1 font  'sans,12'
set size 1, 1
set origin 0, 0
EOF
set -- $all_disks
echo "plot '-' using 1:5 title '$2' with lines \\"
shift
shift
while [ $# -gt 0 ]
do
    echo  ",   '-' using 1:5 title '$2' with lines \\"
    shift
    shift
done
echo "#"
    set -- $all_disks
    while [ $# -gt 0 ]
    do
    dpos=$1
    $PATH_AWK 'BEGIN {
        getline
        dsks = (NF - 1)/2
        dpos = '$dpos'
        pass = '$pass'
        dname = $(dpos + 2)
        dind = 5 + dpos + pass * dsks
#        print dname
    }
    {
        print $1 " " $2 " " $3 " " $4 " " $dind
    }
    END {
        print "e"
    }' sar_dsk.txt
    shift
    shift
    done
    echo set output
done |  gnuplot
#gqview disk_act.svg disk_resp.svg &
