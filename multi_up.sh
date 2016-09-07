#!/bin/bash
# multi-up scripts; produce scaled up versions
# Should pass in the iterations required and a list of scripts to do ...
#
if [ $# -lt 2 ]
then
    echo Provide a scale-up count and a list of scripts to scale up
    exit
fi
mult=$1
shift
for i in $*
do
#
# Create the new directory
#
if [ ! -f $i/$i.msg ]
then
    echo Script $i does not exist
    continue
fi
mkdir ${i}$mult
cp ${i}/* ${i}$mult
mv ${i}${mult}/$i.msg  ${i}${mult}/${i}${mult}.msg 
mv ${i}${mult}/$i.def  ${i}${mult}/${i}${mult}.def
#
# Clone the script
#
j=1
while [ $j -lt $mult ]
do
cat $i/$i.msg >> ${i}${mult}/${i}${mult}.msg 
j=`expr $j + 1`
done
#
# Count the lines
#
set -- `wc -l $i/$i.msg`
lines=$1
#
# Clone the def entries
#
$PATH_AWK -F"|" 'BEGIN {
    lines='$lines'
    clone_lim='$mult' - 1
    seq = 1
}
NF == 5 { line[seq] = $0
    seq++
}
END {
    cur_offset = lines
    for (clones = 0; clones < clone_lim; clones++)
    {
    split(line[1], arr, "|")
    print (arr[1] + cur_offset) "|" arr[2] "|" arr[3] "|" arr[4] "|F"
    for (i = 2; i < seq; i++)
    {
        split(line[i], arr, "|")
        print (arr[1] + cur_offset) "|" arr[2] "|" arr[3] "|" arr[4] "|" arr[5]
    }
    cur_offset += lines
    }
}' $i/$i.def  >> ${i}${mult}/${i}${mult}.def
done
exit
