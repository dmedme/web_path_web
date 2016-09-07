#!/bin/sh
# dotnetscriptify.sh - create a .NET script from a snoop file
#
# Parameters:
# 1  -  snoop file to process. This is assumed to be from a single client
# 2  -  root output file name
# 3 ... extra arguments needed by dotnetdump (e.g. -s (snap headers present))
#
# In addition, E2_DOTNET_PORTS needs to be set in the environment to the .NET
# remoting port(s)
#
# Create a directory to correspond to the root output file name, set up
# the appropriate environment variables, and then process the snoop file with
# dotnetdump. Process the dotnetdump output so that:
# -  We get a script ready for dotnetdrive
# -  We get runout file fragments, named by host (make this a separate
#    function, since we may want to redo this automatically?).
#
# We will see a single runout fragments.
# - The client (actor 0). A line would be:
#    - number of users (default 10)
#    - the script name (as provided)
#    - the number of transactions (default 10)
#    - think time (default 10)
#    - actor ID (must be 0)
#    - 3 more rubbish values
#
set -x
if [ $# -lt 3 ]
then
    echo "Provide a snoop file name, a script name, the client IP address"
    echo "and any extra arguments needed by dotnetdump"
    exit
fi
if [ ! -f "$1" ]
then
     echo snoop file \'$1\' does not exist
     exit
fi
snp=$1
shift
dir=$1
shift
if [ ! -d "$dir" ]
then
    if mkdir "$dir"
    then
        :
    else
        echo Script name does not correspond to a directory
        exit
    fi
fi
script=`basename $dir`
#
# Passed host addresses
#
E2_USER_HOST=$1
export E2_USER_HOST
shift
#
# Extra arguments for dotnetdump
#
extra_args=$*
PATH_AWK=${PATH_AWK:-gawk}
export PATH_AWK
E2DOTNETDUMP=${E2DOTNETDUMP:-dotnetdump}
export E2DOTNETDUMP
E2_DOTNET_PORTS=${E2_DOTNET_PORTS:-"65051 65052 65053 65008 65022"}
export E2_DOTNET_PORTS
PATH_EXT=${PATH_EXT:-msg}
export PATH_EXT
echo E2_USER_HOST=$E2_USER_HOST >$dir/capset.sh
echo E2_DOTNET_PORTS=\"$E2_DOTNET_PORTS\" >>$dir/capset.sh
# ******************************************************************* 
# Process the snoop file with dotnetdump
#
#dotnetdump $extra_args $snp 2>/dev/null 
$E2DOTNETDUMP $extra_args $snp 2>/dev/null
#env | grep E2
#ls -l $snp dotnet_script.msg
#echo Press return to continue
#read x
#
# Get rid of spurious 'M' commands following 'X' commands
# and construct End Point records.
#
# Eliminate gaps between POST and the POST data
#
# Eliminate bogus sessions starting with an L port combination.
#
$PATH_AWK -F ":" 'BEGIN {
# These three variables all include the 0x0B Serialization End Marker
handshake="<RSAKeyValue><Modulus>19OEuRlZLaAKj0IzLbI2WXd5mOFA3/CBTCznaNh9GSbqxULsW4KopYUBn6TYqEfyndFv9QZyR68QY5ydsVqr8u9oJLhaYUEVxcL3231N1IAUJF+RMv3sSJhAU84YqFafKgu+9dKCi/vRxFrE9PQwg5ZxOy0+/59NaZbZ2nHg89s=</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>'\''0B'\''\\"
login_clear = "EncryptedObject+encryptedBytes'\''07020500000009060000000F060000008001000002'\''\\\n'\''0001000000FFFFFFFF01000000000000000C02000000'\''\\\nSCasMidTierTypes, Version=12.1.4.0, Culture=neutral, PublicKeyToken=d78d271c321\\\ne78ea'\''0501000000'\''\\\n(Cas.CasFramework.MidTier.Types.LogonArgs'\''04000000'\''\\\n\tlogonName'\''08'\''\\\npassword\nclientType'\''0E'\''\\\nexternalUserId'\''01010401'\''\\\n)Cas.CasFramework.MidTier.Types.ClientType'\''02000000020000000603000000'\''\\\n\radministrator'\''060400000007'\''\\\nsydney1'\''05FBFFFFFF'\''\\\n)Cas.CasFramework.MidTier.Types.ClientType'\''0100000007'\''\\\nvalue__'\''000802000000010000000606000000'\''\\\n\tdan.white'\''0B0C0C0C0C0C0C0C0C0C0C0C0C0B'\''\\"
tick_clear = "'\''0001000000FFFFFFFF01000000000000000C02000000'\''\\\nSCasMidTierTypes, Version=12.1.4.0, Culture=neutral, PublicKeyToken=d78d271c321\\\ne78ea'\''0501000000'\''\\\n/Cas.CasFramework.MidTier.Types.GetNewTicketArgs'\''02000000'\''\\\n\tsessionId'\''08'\''\\\nticketId'\''0404'\''\\\n(Cas.CasFramework.MidTier.Types.SessionId'\''02000000'\''\\\n'\''Cas.CasFramework.MidTier.Types.TicketId'\''0200000002000000090300000009040000000503000000'\''\\\n(Cas.CasFramework.MidTier.Types.SessionId'\''0200000006'\''\\\nisNull'\''05'\''\\\nvalue'\''00000108020000000082015D000504000000'\''\\\n'\''Cas.CasFramework.MidTier.Types.TicketId'\''0200000006'\''\\\nisNull'\''05'\''\\\nvalue'\''0003010B'\''\\\nSystem.Guid'\''020000000004FBFFFFFF0B'\''\\\nSystem.Guid'\''0B000000025F61025F62025F63025F64025F65025F66025F67025F68025F'\''\\\n'\''69025F6A025F6B000000000000000000000008070702020202020202024A'\''\\\n'\''00DC7986CA13478873095A4AAE541B0B0606060606060B'\''\\"
}
/^\\X:/ {
    a = $2
    b = substr($3,1,length($3) - 1)
    if (ep[ a ] == "" || ep[ b ] == "" || ep[ a ] ~ /L\\$/)
        next
    print
    getline
#    if ($1 == "\\\\M" && ((a == $2 && b ==  substr($3,1,length($3) - 1)) || (a ==  substr($3,1,length($3) - 1) && b == $2)))
    if ($1 == "\\M" && ((a == $2 && b ==  substr($3,1,length($3) - 1)) || (a ==  substr($3,1,length($3) - 1) && b == $2)))
        next
}
/^\\D:B:/ {
#    print "Seen Block Begin"
    http_blk = $0
    comms= ""
    getline
    out_flag = 1
    while ($0 !~ /^\\D:E/)
    {
        if ($0 ~ /^<RSAKeyValue>/ )
        {
            http_blk = http_blk "\n" handshake
            for (;;)
            {
                if ((getline)<1)
                    next
                if (NF == 0)
                    break
            }
        }
#        else
#        if ($0 ~ /^1Cas.CasFramework.MidTier.Types.EncryptedLogonArgs/ )
#        {
#            http_blk = http_blk "\n" $0 "\n" login_clear
#            for (;;)
#            {
#                if ((getline)<1)
#                    next
#                if (NF == 0)
#                    break
#            }
#        }
#        else
#        if ($0 ~ /^8Cas.CasFramework.MidTier.Types.EncryptedGetNewTicketArgs/ )
#        {
#
#            while ($0 !~ /^\)Cas.CasFramework.MidTier.Types.LanguageId/ )
#            {
#                http_blk = http_blk "\n" $0
#                if ((getline)<1)
#                    next
#            }
#            while ($0 !~ /^value/)
#            {
#                http_blk = http_blk "\n" $0
#                if ((getline)<1)
#                    next
#            }
#            http_blk = http_blk "\nvalue'\''000001080400000000010000000F0800000020020000020'\''\\\n" tick_clear
#            for (;;)
#            {
#                if ((getline)<1)
#                    next
#                if (NF == 0)
#                    break
#            }
#        }
        else
        if ($0 ~ /^\\M:/ )
            do_eps( $2, substr($3,1,length($3) - 1))
        if ($0 ~ /^\\X:/ || $0 ~ /^\\C/ || $0 ~  /^\\M:/ )
        {
            if (comms == "")
                comms = $0
            else
                comms = comms "\n" $0
            if ($0 ~ /^\\Corruption/)
                print "At input line " NR " " substr($0,2,length($0) - 2) >"'$dir/errs.txt'"
        }
        else
        if ($0 ~ /^\\D:B/)
        {
# I don'\''t think this should happen with .NET. It would happen if the server
# responds with a TCP Reset, and we have re-sent using a different socket.
# So log a message
#            print "*** Missing \\\\D:E\\\\? ***"
            print "*** Missing \\D:E\\? ***"
            if (comms != "")
            {
                print comms
                comms = ""
            }
            http_blk = ""
            out_flag = 1
        }
        if (http_blk != "")
            http_blk = http_blk "\n" $0
        else
            http_blk = $0
        getline
    }
    http_blk = http_blk "\n" $0
    if (out_flag == 1)
    {
        print http_blk
#        print "Printed Block"
    }
    if (comms != "")
    {
        print comms
#        print "Moved Directives"
    }
    next
}
/\|Session Summary\|.*\|UDP\|/ { next }
/^\\Corruption/ { print "At input line " NR " " substr($0,2,length($0) - 2) >"'$dir/errs.txt'"
    next
}
function do_eps(a, b) {
    if (ep[a] == "")
    {
        split(a, arr, ";")
        ep[a] = "\\E:" arr[1] ":" arr[2] ":" arr[1] ":" arr[2] ":C\\"
#        ep[a] = "\\\\E:" arr[1] ":" arr[2] ":" arr[1] ":" arr[2] ":C\\\\"
        print ep[a]
    }
    else
    if (ep[ a ] ~ /L\\$/)
        return
    if (ep[b] == "")
    {
        split(b, arr, ";")
#        ep[b] = "\\\\E:" arr[1] ":" arr[2] ":" arr[1] ":" arr[2] ":L\\\\"
        ep[b] = "\\E:" arr[1] ":" arr[2] ":" arr[1] ":" arr[2] ":L\\"
        print ep[b]
    }
    return;
}
/^\\M:/ {
    do_eps( $2, substr($3,1,length($3) - 1))
}
{ print }' dotnet_script.msg > tmp$$.log
if [ -s tmp$$.log ]
then
echo "\\W5\\" >$dir/$script.$PATH_EXT
grep  '^\\E:.*:[LC]\\$' tmp$$.log >>$dir/$script.$PATH_EXT
grep -v '^\\E:.*:[LC]\\$' tmp$$.log >>$dir/$script.$PATH_EXT
echo "\\D:R\\" >>$dir/$script.$PATH_EXT
fi
# ****************************************************************************
# Attempt to decrypt the encrypted stuff
#
set -- `fhunt -u "@SessionKey" $snp`
if [ $# -eq 6 ]
then
    key_off=`expr $6 + 28`
    mempat -l 32 $key_off $snp >$dir/SessionKey.bin
    set -- `fhunt -u "@SessionIv" $snp`
    if [ $# -eq 6 ]
    then
        iv_off=`expr $6 + 26`
        mempat -l 16 $key_off $snp >$dir/SessionIv.bin
        dotnet_script_decrypt.sh $dir/SessionKey.bin $dir/SessionIv.bin $dir/$script.$PATH_EXT >$dir/$script.$PATH_EXT.decrypt
#
# Finally, attempt to automatically introduce some events
#
        if [ ! -z "$E2_BOTH" ]
        then
            unset E2_BOTH
            autoscript -p ":H:sessionid1:3:SessionId:SessionId:value:14:4:1:0C07A200:0:4:H:ticketid01:2:System.Guid:System.Guid:70:16:1:ED183F94FBF90041B30D2D767DE9C6DD:0:16:H:userid1:3:Types.UserId:Types.UserId:value:14:4:1:E2280000:0:4\\" $dir/$script.$PATH_EXT.decrypt $dir/$script.$PATH_EXT.auto
        fi
    fi
fi
# ****************************************************************************
# Produce the runout entry
# - The client. A line would be:
#    - number of users (default 10)
#    - the script name (as provided)
#    - the number of transactions (default 20)
#    - think time (default 5)
#    - 4 more rubbish values (needed by fdreport)
#
    echo 10 $script 20 ${PATH_THINK:-5} there must be four >$dir/client.run
