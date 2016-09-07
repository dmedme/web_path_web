#!/bin/bash
# Count authorisations between two time stamps
#
if [ $# -lt 2 ]
then
#
# Get the default times from the first log file
#
    end_time=`tail -1 172*6/log*.1.0 | $PATH_AWK -F: '{print substr($5,1,10)}'` 
    start_time=`expr $end_time - 3600`
else
start_time=$1
end_time=$2
fi
$PATH_AWK -F":" 'BEGIN {
    st = "'$start_time'00" 
    et = "'$end_time'00" 
    try = 0
    succeed = 0
    duplicate = 0
    unknown = 0
}
/:A:A[6P]:[^ ]* \(Type 4/ {
    line = $0
    if ($5 <st || $5 > et)
        next
    try++ 
    getline
    if ($6 == "G")
        succeed++
    else
    if ($6 == "Z") {
        print "__________"
        print line
        print $0
        duplicate++
    }
    else
    {
        unknown++
        print FILENAME "|" FNR "|Failed!"
    }
}
END {
    print "Try: " try " Succeed: " succeed " Duplicate: " duplicate " Unknown: " unknown
}' 172*/log*
