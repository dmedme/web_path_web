#!/bin/sh
#
# autodefC.sh automates the generation of a *.def file for a path script
# A *.def file must exist with possible substition values in the second col
# of each row (i.e. in the format of a def file but other than the second
# column the values can be null and are in any case ignored.
# Thus a current *.def file could be used.
#
# This script handles multiple substitutions on the same line of an *.msg file.
#
# The script basedefC.sh can be used to create a suitable *.def based on 
# values in one or more *.db files stored within the data directory.
#
# Following generation the *.def file will need to be edited to facilitate
# use of the F directive in the 5th column.
#
# The new *.def will be named *.new.  The original *.def will be maintained.
#
for i in $*
do
#
#if [ -d $i  -a -f $i/$i.def ]
#
#then
# 
# not a def file so use *.db
#
# fi
#
#
if [ -d $i  -a -f $i/$i.msg -a -f $i/$i.def ]
then
#
whichawk="$PATH_AWK"
echo "PATH_AWK= " $whichawk
if [ -z "$whichawk" ] 
then
echo "No awk specified in PATH_AWK. Possibly need to run fdvars.sh"
exit 1
fi
#
# First create deduped def file
sort -t"|" -k2,2 $i/$i.def > $i/$i.de1
#
$whichawk 'BEGIN {
FS="|"
currentval=""
}
currentval!=$2 {
print $0 > "'$i/$i.de2'"
currentval=$2
}' $i/$i.de1 
#
# delete temp file *.de1
rm $i/$i.de1
# Now create *.new with events and subs
#
$whichawk 'function findstring(thestring,theline) {
nooftimes=split(theline,thearray,thestring)
nooftimes--
return
}
BEGIN {
print "------- START of '$i' -------"
FS="|"
# Set counts for script
#
eventscount=0
msglinenum=0
noofsubs=0
# loop used to count no of subs within each loop
loopx=0
loop[loopx]=0
#First read def file and store in an array
deffile="'$i/$i.de2'"
deflinenum=0
while(( getline < deffile) >0) {
if(NF==5) {
deflinenum++
for(y=1;y<6;y++) {
def[deflinenum,y]=$y
}
}
for(x=1;x<=deflinenum;x++) {
# print def[x,1] "|" def[x,2] "|" def[x,3] "|" def[x,4] "|" def[x,5]
}
}
}
{
notpath="Y"
msglinenum++
}
/^\\S[A-Z][A-Z,0-9]:*/ {
# The path e2sync (S) events
notpath="N"
eventscount++
print "      " $0 > "'$i/$i'.new"
if($0~"LOOP") {
loopx++
loop[loopx]=0
}
}
/^\\T[A-Z][A-Z,0-9]:\\/ {
# The path e2sync end (T) events
notpath="N"
}
/^\\W*\\/ {
# The path wait event
notpath="N"
}
notpath=="Y" {
# process script line
for(x=1;x<=deflinenum;x++) {
findstring(def[x,2],$0)
while(nooftimes>0) {
print msglinenum "|" def[x,2] "|" def[x,3] "|" def[x,4] "|N" > "'$i/$i'.new"
nooftimes--
loop[loopx]++
noofsubs++
}
}
}
END {
print "Lines in '$i' = " msglinenum
print "Events in '$i' = " eventscount
# print loop info
print "Total no. of substitutions = " noofsubs
if(loopx>0) {
for(x=0;x<=loopx;x++) {
print "Loop " x " - subs = " loop[x] 
}
}
print "-------- END of '$i' --------"
}' $i/$i.msg
# delete temp file *.de2
rm $i/$i.de2
else
echo "not a script directory"
fi
done
