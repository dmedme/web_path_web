#!/bin/bash
# autoungz - Decompress gzip content in bothways scripts
#
if [ $# != 2 ]
then
    echo Provide a bothways script file with gzip contents and an output file
    exit
fi
if [ ! -n "$PATH_HOME" ]
then
    echo PATH_HOME etc. need to be set in your environment
    exit 1
fi
$PATH_AWK '/^\\A/ {
    print $0
    zip_flag = 0
    for (;;)
    {
        if ((getline)< 1)
            exit
        if ( $0 ~ /^\\A/)
        {
            if (zip_flag == 2)
            {
                print to_decomp|"ascbin -e | gzip -d"
                close("ascbin -e | gzip -d")
            }
            print $0
            zip_flag = 0
            next
        }
        if (zip_flag == 2)
            to_decomp = to_decomp "\n" $0
        else
        if ($0 ~ /^[Cc]ontent-[Ee]ncoding: gzip/ )
        {
            zip_flag = 1
            print $0
        }
        else
        if (zip_flag == 1 && $0 ~ /^'\''1F8B0800000000000/)
        {
            zip_flag = 2
            to_decomp = $0
        }
        else
            print $0
    }
}
{ print $0 }' $1 > $2 2>/dev/null
