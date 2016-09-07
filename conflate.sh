#!/bin/bash
# conflate.sh - Give all events with the same description the same ID.
rm -rf conflated
mkdir conflated
for i in $*
do
    if [ ! -f $i ]
    then
        echo No such file $i
        continue
    else
        j=`echo $i | sed 's=.*/=='`
        gawk -F: '{
    if (NF < 7)
    {
        print $0
        next
    }
    else
    if ($6 == "A" || $6 == "Z")
        id = $2 "." $7
    else
        id = $2 "." $6
    if (id == "")
    {
        print $0
        next
    }
    trn = lookupid[id]
    if (trn == "")
    {
        if ($6 != "A")
        {
            print $0
            next
        }
        desc = $9
        trn = lookupdesc[desc]
        if (trn == "")
        {
            lookupdesc[desc] = id
            lookupid[id] = id
            trn = id
        }
        else
            lookupid[id] = trn
    }
    rec = $1 ":" $2 ":" $3 ":" $4 ":" $5
    split(trn, arr, ".")
    if ($6 == "A" || $6 == "Z")
    {
        rec = rec ":" $6 ":" arr[2]
        i = 8
    }
    else
    {
        rec = rec ":" arr[2]
        i = 7
    }
    for (;i <= NF;i++)
        rec = rec ":" $i
    print rec
}' $i >conflated/$j
    fi
done
