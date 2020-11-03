#!/bin/bash
CORES=4
__DIR__="$(dirname "$(readlink -f "$0")")"
DOCKQ_HOME="$__DIR__"
LINE="$__DIR__/dockqline.sh"
SORT="$__DIR__/sort.sh"

if [[ ! -f ${LINE} ]]; then
    echo "Error: missing '${LINE}'." >&2
    exit 1
else
    chmod +x ${LINE}
fi
if [[ ! -f ${SORT} ]]; then
    echo "Error: missing '${SORT}'." >&2
    exit 1
else
    chmod +x ${LINE}
fi
if [[ ! -f ${DOCKQ_HOME}/fnat ]]; then
    echo "Warning: dockq is not compiled. Compiling..." >&2
    pushd ${DOCKQ_HOME} >/dev/null || echo "Error: dockq is broken, please check." && exit 1
    make >&2 || echo "Error: compile failed, please check." && exit 1
    popd >/dev/null
fi
if ! command -v pdb_tidy &> /dev/null; then
    echo "Error: pdb-tools is not installed. Install with 'pip install pdb-tools'." >&2
    exit 1
fi
if [[ $# = 0 ]]; then
    echo "Usage: ./dockq.sh <native> <decoy1> <decoy2>" >&2
    echo "    or ./dockq.sh <native> for using all pdb files in current dir"
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
    format="%-17s %-17s %-8s %-8s %-7s %-4s %-4s %-6s %-6s %-10s %-10s %-10s \n"
    printf "$format" "decoy" "native" "chain(1)" "chain(2)" "fnat" "natc" "corc" "irmsd" "lrmsd" "CAPRI" "DockQ" "DockQScore"
    nativename="${native##*/}"
    nativename_noext="${nativename%.*}"
    native_tidy=${nativename_noext}.dockq.native.pdb
    tempdir=$(mktemp -d -t dockq.XXXXXX)
    ${SORT} $native $tempdir/$native_tidy
    for file in ${files[@]}; do
        joblist=($(jobs -p))
        while [[ ${#joblist[*]} -ge $CORES ]]; do
            sleep 0.3
            joblist=($(jobs -p))
        done
        if [[ -f $file ]]; then
            ${LINE} "$DOCKQ_HOME" "$tempdir/$native_tidy" "$file" "$format" "$tempdir" "$SORT" "$ARGS" &
        else
            echo "Warning: decoy '$file' doesn't exist." >&2
        fi
    done
    wait
    rm -R $tempdir
else
    echo "Error: native '$native' doesn't exist." >&2
fi

    
    