#!/bin/bash
CORES=10
__DIR__="$(dirname $(readlink -f "$0"))"
DOCKQ_HOME="$__DIR__"
LINE="$__DIR__/dockqline.sh"

if [[ ! -f ${LINE} ]]; then
    echo "Error: missing 'dockqline.sh'." >&2
    exit 1
else
    chmod +x ${LINE}
fi
if [[ ! -f ${DOCKQ_HOME}/fnat ]]; then
    echo "Error: dockq is not compiled. Go to 'lib/analy/dockq' and run 'make'." >&2
    exit 1
fi
if ! command -v pdb_tidy &> /dev/null; then
    echo "Error: pdb-tools is not installed. Install with 'pip install pdb-tools'." >&2
    exit 1
fi
if [[ $# = 0 ]]; then
    echo "Usage: ./dockq.sh <native> <decoy1> <decoy2>" >&2
    echo "    or ./dockq.sh <native>"
    exit 0
fi
if [[ $# > 1 ]]; then
    native=$1
    shift
    files=($@)
else
    native=$1
    files=($(ls *.pdb | tr "\n" " "))
fi

set -m
if [[ -f $native ]]; then
    format="%-17s %-17s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s \n"
    printf "$format" "decoy" "native" "chain(1)" "chain(2)" "fnat" "natc" "corc" "irmsd" "lrmsd" "CAPRI" "DockQ" "DockQScore"
    nativename="${native##*/}"
    nativename_noext="${nativename%.*}"
    native_tidy=${nativename_noext}.dockq.native.pdb
    pdb_tidy $native | pdb_keepcoord | pdb_delhetatm | pdb_tidy > $native_tidy
    for file in ${files[@]}; do
        joblist=($(jobs -p))
        while [[ ${#joblist[*]} -ge $CORES ]]; do
            sleep 0.3
            joblist=($(jobs -p))
        done
        if [[ -f $file ]]; then
            ${LINE} "$DOCKQ_HOME" "$native_tidy" "$file" "$format" &
        else
            echo "Warning: decoy '$file' doesn't exist." >&2
        fi
    done
    wait
    rm $native_tidy
else
    echo "Error: native '$native' doesn't exist." >&2
fi

    
    