#!/usr/bin/env bash
folder=$1
#tmpfile=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.out)
tmpfile=$(mktemp)
cd $folder
ls $folder | grep -v error | xargs -n 32 -P 8 cat $folder/ 2> /dev/null | awk 'NR==1 || NR%2==0' > $tmpfile
cd -

folder=$2
tmpfile2=$(mktemp)
cd $folder
ls $folder | grep -v error | xargs -n 32 -P 8 cat $folder/ 2> /dev/null | awk 'NR==1 || NR%2==0' > $tmpfile2
cd -

./decompose_stats.r $tmpfile $tmpfile2
ret=$?

rm $tmpfile
rm $tmpfile2
exit $ret
