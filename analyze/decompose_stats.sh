#!/usr/bin/env bash
folder=$1
#tmpfile=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.out)
tmpfile=$(mktemp)
cd $folder
ls $folder | grep -v error | xargs -n 32 -P 8 cat $folder/ 2> /dev/null | awk 'NR==1 || NR%2==0' > $tmpfile
cd -
cat $tmpfile | ./decompose_stats.r
ret=$?
#cat $folder/* 2> /dev/null #| awk 'NR==1 || NR%2==0' | ./decompose_stats.r
rm $tmpfile
exit $ret
