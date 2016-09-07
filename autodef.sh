#!/bin/sh
# Attempt to automatically extend the scope of an existing def file
# through the whole SQL script, looking for other occurrences already seen.
#
# Arguments: list of script names, without file extensions.
for i in $*
do
if [ -d $i -a -f $i/$i.$PATH_EXT -a -f $i/$i.def ]
then
$PATH_AWK  'BEGIN {
dname="'$i/$i.def'"
    FS="|"
    cnt = 0
    while ((getline<dname) > 0)
    {
        if (substr($0,1,1) == "#")
            continue
        targ[cnt] = $2
        tab[cnt] = $3
        seen[cnt] = 0
        col[cnt] = $4
#        print cnt " " targ[cnt] " " tab[cnt] " " col[cnt]
        cnt++
    }
}
!/^\\/{
    for (i = 0; i < cnt; i++)
    {
        if (index($0,targ[i]) > 0)
        {
            if (seen[i] == 0)
                print NR "|" targ[i] "|" tab[i] "|" col[i] "|F"
            else
                print NR "|" targ[i] "|" tab[i] "|" col[i] "|N"
            seen[i] = 1
        }
    }
}' $i/$i.$PATH_EXT > $i/$i.new
else
    echo $i is not a web script directory with a .def skeleton present
fi
done
