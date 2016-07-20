#!/usr/bin/env bash

func_extract () {
    if [ -z "$2" ] ; then
	sep="[[:space:]][[:space:]][[:space:]]*"
    else
	sep=$2
    fi
    grep "$1" $tmpfile | awk -F "$sep" '{print $2}'  | awk -F ' ' '{print $1; exit}' | tr -d '[:space:]'

}
