#!/bin/bash
# dotnet_script_decrypt.sh - Decrypt all the encrypted blocks
# We make use of the fact that the only encrypted stuff occurs
# at the end of our blocks.
#
if [ -z "$PATH_HOME" ]
then
    echo Must dot fdvars.sh before running this
    exit 1
fi
#if [ $# -lt 3 ]
#then
#cat << EOF
#Provide the name of a file containing the binary session key
#the name of a file containing the binary session IV, and
#the name of the file to be processed. The output appears
#on stdout
#EOF
#    exit
#fi
if [ $# -lt 3 ]
then
cat << EOF
Provide the hexadecimal session key, the hexadecimal session IV, and
the name of the file to be processed. The output appears on stdout
EOF
    exit
fi
keyf=$1
iv=$2
cipher=$3
$PATH_AWK 'BEGIN {
   keyf="'$keyf'"
   iv="'$iv'"
}
function get_first_line(ln) {
    nf = split(ln, arr, "000002")
    begcryp = arr[nf]
    print substr(ln,1,length(ln) - length(begcryp)) "'\''\\"
    return "'\''" begcryp   
}
function do_decrypt(cipher1) {
    http_blk = get_first_line(cipher1)
    for (;;)
    {
        if ((getline)<1)
            next
        if ($0 ~ /^\\D:E/)
            break
        http_blk = http_blk "\n" $0
    }
#    comm = "ascbin -e | dec_aes -f " keyf " " iv " | ascbin -d"
    comm = "ascbin -e | dec_aes -x " keyf " " iv " | ascbin -d"
#    print "Cipher Text:"
#    print http_blk
#    print "=========== Clear ==========="
    print substr(http_blk,1,length(http_blk)-5) "'\''\\\n" |comm
    close(comm)
    print "'\''0B'\''\\\n\n\\D:E\\"
    return
}
/^\\D:B:/ {
#    print "Seen Block Begin"
    http_blk = $0
    comms= ""
    getline
    while ($0 !~ /^\\D:E/)
    {
        if ($0 ~ /^1Cas.CasFramework.MidTier.Types.EncryptedLogonArgs/ )
        {
            print http_blk "\n" $0
            getline 
            do_decrypt($0)
            next
        }
        else
        if ($0 ~ /^8Cas.CasFramework.MidTier.Types.EncryptedGetNewTicketArgs/ )
        {
            while ($0 !~ /^\)Cas.CasFramework.MidTier.Types.LanguageId/ )
            {
                http_blk = http_blk "\n" $0
                if ((getline)<1)
                    next
            }
            while ($0 !~ /^value/)
            {
                http_blk = http_blk "\n" $0
                if ((getline)<1)
                    next
            }
            print http_blk 
            do_decrypt($0)
            next
        }
        http_blk = http_blk "\n" $0
        if ((getline)<1)
            next
    }
    print http_blk
}
{ print }' $cipher
