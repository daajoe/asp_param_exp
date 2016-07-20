#!/usr/bin/env bash
kill_child_processes() {
    for childPid in $(jobs -p); do 
        pkill -9 -P $childPid
        kill -9 $childPid
    done
}

trap "kill_child_processes 1 $$; echo 'Caught signal' >&2; echo 'exiting...' >&2;" SIGINT SIGTERM

path=$(realpath $1)
set=$(echo $1 | awk -F '/' '{ print $(NF-1)}')

pid=$(echo $$)
tmpfile=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.out)
tmpfile_runtm=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.runtm)
tmpfile_uncompressed=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.lp)
tmpfile_ground=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.lparse)
tmpfile_ground_runtm=$(mktemp /dev/shm/tmp.XXXXXXXXXXX.runtm)


func_extract () {
    if [ -z "$2" ] ; then
	sep="[[:space:]][[:space:]][[:space:]]*"
    else
	sep=$2
    fi
    grep "$2" $tmpfile | awk -F "$sep" '{print $2}'  | awk -F ' ' '{print $1; exit}' | tr -d '[:space:]'
}

hash=$(sha256sum $path | awk '{print $1'})

bzcat -f $path > $tmpfile_uncompressed
if [[ $path == *"lparse"* ]]
then 
    cat $tmpfile_uncompressed | sed -r "s/-([0-9])/\1/g" > $tmpfile_ground
    #cp $tmpfile_uncompressed $tmpfile_ground
    ground_runtm="NA"
    ground_cpu="NA"
    ground_mem="NA"
else
    grounder=$(gringo --version | head -n 1)
    (gnutime -v gringo $path $tmpfile_uncompressed 1> $tmpfile_ground) 2>> $tmpfile_ground_runtm
    ground_runtm=$(grep 'Elapsed (wall clock) ' $tmpfile_ground_runtm | awk -F ': ' '{print $2}')
    ground_cpu=$(grep 'Percent of CPU' $tmpfile_ground_runtm | awk -F ': ' '{print $2}')
    ground_mem=$(grep 'Maximum resident' $tmpfile_ground_runtm | awk -F ': ' '{print $2}')
fi

#echo "FILE_OUT:"
#cat $tmpfile_ground

hash_ground=$(sha256sum $tmpfile_ground | awk '{print $1'})
solver='dynasp'
solver_version=$(dynasp -v | head -n 1)

(gnutime -v dynasp -d -bb $tmpfile_ground -s $2 1> $tmpfile ) 2>> $tmpfile_runtm &
for job in $(jobs -p); do
    wait $job
done
solved=$?

models=$(func_extract "SOLUTION COUNT" ": ")
width=$(func_extract "TREEWIDTH" ": ")
opt_weight=$(func_extract "OPTIMAL WEIGHT" ": ")

runtm=$(grep 'User time ' $tmpfile_runtm | awk -F ': ' '{print $2}')
runtm_sys=$(grep 'System time ' $tmpfile_runtm | awk -F ': ' '{print $2}')
cpu=$(grep 'Percent of CPU' $tmpfile_runtm | awk -F ': ' '{print $2}')
mem=$(grep 'Maximum resident' $tmpfile_runtm | awk -F ': ' '{print $2}')

parse_time=$(grep 'parsing time' $tmpfile | /mnt/lion/home/fichte/.local/bin/csvcut -d ',' -c 3)
hyper_time=$(grep 'hypergraph conversion time' $tmpfile | /mnt/lion/home/fichte/.local/bin/csvcut -d ',' -c 3)
decomp_time=$(grep 'tree decomposition time' $tmpfile | /mnt/lion/home/fichte/.local/bin/csvcut -d ',' -c 3)
solver_time=$(grep 'solving time' $tmpfile | /mnt/lion/home/fichte/.local/bin/csvcut -d ',' -c 3)
solextract_time=$(grep 'solution extraction time' $tmpfile | /mnt/lion/home/fichte/.local/bin/csvcut -d ',' -c 3)

printf 'solver;solver_version;set;instance;hash;hash_ground;grounder;vars;clauses;parse_tm;hyper_time;decomp_time;seed;width\n'
printf '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n' "$solver" "$solver_version" "$set" "$path" "$hash" "$hash_ground" "$grounder" "$vars" "$clauses" "$parse_time" "$hyper_time" "$decomp_time" "$2" "$width"

cat $tmpfile >&2
echo '-----------------------------------' >&2
cat $tmpfile_runtm | sed -e 's/^[ \t]*//' >&2

rm $tmpfile
rm $tmpfile_runtm
rm $tmpfile_uncompressed
rm $tmpfile_ground
rm $tmpfile_ground_runtm

exit 0
