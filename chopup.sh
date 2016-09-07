#!/bin/bash
if [ $# -lt 1 ]
then
    echo Provide a dump file to chop into pieces
    exit
fi
PATH=/home/e2soft/e2common:$PATH
export PATH
gawk 'BEGIN { name_cnt = 0 }
/^Host: / { 
    targ = "https://" $2 "/"
}
/^\(Client: 1\) In<====/ || /^\\A:B/ {
cmd="ascbin -e | sed '\''s}[Ss][Rr][Cc] *= *['\'\\\\\'\''\"]}&" targ "}g\n\
s}url *( *}&" targ "}g\n\
s}open *( *['\'\\\\\'\''\"]}&" targ "}g\n\
s}[Hh][Rr][Ee][Ff] *= *['\'\\\\\'\''\"]}&" targ "}g'\'' >fred" name_cnt "."
name_cnt++
ext = "html"
while ($0 != "\r")
{
    if ($1 == "Content-Type:")
    {
        if ($2 ~ "png")
            ext = "png"
        else
        if ($2 ~ "css")
            ext = "css"
        else
        if ($2 ~ "javascript")
            ext = "js"
        else
        if ($2 ~ "gif")
            ext = "gif"
        else
        if ($2 ~ "x-icon")
            ext = "ico"
        else
        if ($2 ~ "woff2")
            ext = "wof"
        else
        if ($2 ~ "jpeg")
            ext = "jpg"
        else
        if ($2 ~ "json")
            ext = "json"
    }
    getline
}
cmd = cmd ext
for (;;)
{
    if ((getline)<1)
        break
    if (($0 ~ /^\(Client:/) || ($0 == "\\A:E\\"))
        break
    print $0 | cmd
}
close(cmd)
}' $1
