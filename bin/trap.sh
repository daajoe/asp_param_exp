#!/usr/bin/env bash
kill_child_processes() {
    for childPid in $(jobs -p); do 
        pkill -9 -P $childPid
        kill -9 $childPid
    done
}

trap "kill_child_processes 1 $$; echo 'Caught signal' >&2; echo 'exiting...' >&2;" SIGINT SIGTERM

run_w_aborttrap(){
    $1 $tmpfile_ground 1> $tmpfile
    for job in $(jobs -p); do
	wait $job
    done
}