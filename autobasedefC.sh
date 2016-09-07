#!/bin/sh
#
# Creates a base def file for use with autodefC.sh
# based on records extracted from *.db files stored in data
#
# First get script name
#
for i in $*
do
#
if [ -d $i -a -f $i/$i.msg ]
then
#
# if def file exists copy to *.defsaved
#
if [ -d $i -a -f $i/$i.def ]
then
	mv $i/$i.def $i/$i.defsaved
fi
#
whichawk="$PATH_AWK"
if [ -z "$whichawk" ]
then
echo "No awk specified in PATH_AWK. Possibly need to run fdvars.sh"
exit 1
fi
# Read db file info
#
echo "The following *.db files exist in data (wc -l *.db)"
echo "No of rows ... filename"
wc -l ../data/*.db
#
dbfile="something"
while [ "$dbfile" != "" ]
do
	echo "Enter *.db file name (e.g. invoices) - null to finish "
	echo "Do not include ext (eg. .db)"
	read dbfile
	if [ "$dbfile" != "" ]
	then
		rownum=1
		while [ "$rownum" -gt "0" ]
		do
			echo "*.db file entered: $dbfile"
			echo "Enter data row number - 0 to finish"
			echo "Ignore column headers - for 1st data row enter 1"
			read rownum
			if [ "$rownum" -gt "0" ]
			then
			# now awk to get data row
			$whichawk 'BEGIN {
			FS="|"
			rown='$rownum'
			getline < "'../data/$dbfile.db'"
			numofcols=split($0,colheads,"|")
			while(rown!=0) {
			getline < "'../data/$dbfile.db'"
			rown--
			}
			split($0,datafields,"|")
			for(x=1;x<=numofcols;x++) {
		print "|" datafields[x] "|'$dbfile'|" colheads[x] "|" >> "'$i/$i'.def"
			}
			}'
			fi
		done	
	fi
echo "We are done"
#
done
else
echo "Not a script directory"
fi
done
