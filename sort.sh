#!/bin/bash
# Requirements:
# pdb-tools - http://www.bonvinlab.org/pdb-tools/
if [[ $# -gt 1 ]]; then
    if [[ -f $1 ]]; then
        tempdir="$(mktemp -d -t cleanpdb.XXXXXX)"
        dest="$(readlink -f "$2")"
        file="$(readlink -f "$1")"
        filename="$(basename -- "$file")"
        filename="${filename%.*}"
        cd "$tempdir"
        cat "$file" | pdb_tidy | pdb_delhetatm | pdb_occ | pdb_keepcoord | pdb_tidy > "${filename}.pdb"
        pdb_splitmodel "${filename}.pdb"
        if [[ -f "${filename}_1.pdb" ]]; then
            sgm="${filename}_1.pdb"
        else
            sgm="${filename}.pdb"
        fi
        cat "$sgm" | pdb_tidy | pdb_sort | pdb_tidy | pdb_uniqname | pdb_reres | pdb_reatom | pdb_tidy > "$dest"
        rm -R "$tempdir"
        exit 0
    else
        echo "The file $1 is not existing."
        exit 1
    fi
fi
echo "Usage: ./sort.sh <pdb> <destination>"
