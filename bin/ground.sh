#!/usr/bin/env bash

ground_instance () {
    path=$1
    tmpfile_uncompressed=$2
    tmpfile_ground=$3

    bzcat -f $path > $tmpfile_uncompressed
    if [[ $path == *"lparse"* ]]
    then 
	cat $tmpfile_uncompressed | sed -r "s/-([0-9])/\1/g" > $tmpfile_ground
    else
	grounder=$(gringo --version | head -n 1)
	gringo $path $tmpfile_uncompressed 1> $tmpfile_ground
    fi
}
