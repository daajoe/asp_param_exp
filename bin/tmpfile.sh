#!/usr/bin/env bash

tmpfile=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.out)
tmpfile_uncompressed=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.lp)
tmpfile_ground=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.lparse)

function cleanup {
    #echo 'Cleaning up tempfiles'
    rm $tmpfile
    rm $tmpfile_uncompressed
    rm $tmpfile_ground
    #echo 'Done.'
}
trap cleanup EXIT