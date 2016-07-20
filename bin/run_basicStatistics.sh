#!/usr/bin/env bash
my_dir="$(dirname "$0")"

source "$my_dir/trap.sh"
source "$my_dir/extract.sh"
source "$my_dir/ground.sh"
source "$my_dir/tmpfile.sh"


path=$(realpath $1)
set=$(echo $1 | awk -F '/' '{ print $(NF-1)}')
pid=$(echo $$)

hash=$(sha256sum $path | awk '{print $1'})

ground_instance $path $tmpfile_uncompressed $tmpfile_ground

hash_ground=$(sha256sum $tmpfile_ground | awk '{print $1'})
solver='clasp'
solver_version=$(dynasp -v | head -n 1)

run_w_aborttrap "clasp --stats=2 --solve-limit=1"
solved=$?

#cat $tmpfile | grep -A 40 'OPTIMUM\|UNKNOWN\|TIME\ LIMIT' | unbuffer #| tee $tmpfile >/dev/null 
#|grep -B 33 'Tester Stats'

atoms=$(func_extract "Atoms" ": ")
rules=$(func_extract "Rules" ": ")
bodies=$(func_extract "Bodies" ": ")
equiv=$(func_extract "Equivalences" ": ")
tight=$(func_extract "Tight" ": ")
variables=$(func_extract "Variables" ": ")
constraints=$(func_extract "Constraints" ": ")

printf 'solver;solver_version;set;instance;hash;atoms;rules;bodies;equiv;tight;variables;constraints\n'
printf '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n' "$solver" "$solver_version" "$set" "$path" "$hash" "$atoms" "$rules" "$bodies" "$equiv" "$tight" "$variables" "$constraints"

#cat $tmpfile >&2
#echo '-----------------------------------' >&2
#cat $tmpfile_runtm | sed -e 's/^[ \t]*//' >&2

exit 0


