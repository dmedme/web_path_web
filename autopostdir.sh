#!/bin/bash
# autopostdir.sh - Create a set of directives to deal with all the
# POST variables.
# First copy the POST block(s) in question.
# Then pipe the data in (e.g. from within vi), to get back a set of
# directives, one per line 
# Empty ones are ignored.
#
ascbin -e | $PATH_AWK '{
    nv = split($0, vars, "&")
    for (i = 1; i <= nv; i++)
    {
        ne = split(vars[i], p, "=")
        if (ne > 1 && p[2] != "")
        {
            vname= p[1]
            gsub("%23","#", vname)
            gsub("%25","%", vname)
            unesc_vname = vname
            gsub("\\.","_",vname)
            vname = tolower(vname)
            printf "U:%s:1:=\"%s\" value=:%d:0:1:&%s=:%d:0\n", vname, unesc_vname, length(unesc_vname)+10, p[1], length(p[1]) + 2
        }
    }
}' | sort | uniq
