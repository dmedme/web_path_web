#!/bin/bash
$PATH_AWK -v offset=$1 -F\| '{
 x = ($1 + offset) ""
for (i = 2; i<=NF; i++)
 x = x "\|" $i
print x
}'
exit
