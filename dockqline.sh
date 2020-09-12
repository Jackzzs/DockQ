#!/bin/bash
DOCKQ_HOME=$1
# *.dockq.native.pdb
native=$2
# *.pdb
file=$3
format=$4

filename="${file##*/}"
filename_noext="${filename%.*}"
nativename="${native##*/}"
nativename_noext="${nativename%.*.*.*}"
pdb_tidy $file | pdb_keepcoord | pdb_delhetatm | pdb_tidy > ${filename_noext}.dockq.pdb
outfile=${filename_noext}.${nativename_noext}.dockq.out
$DOCKQ_HOME/DockQ.py ${filename_noext}.dockq.pdb $native > $outfile
if [[ $? > 0 ]]; then
    echo "Warning: dockq failed for $file (native: $native). skipping." >&2
    rm $outfile ${filename_noext}.dockq.pdb
    exit
fi
decoy_name=${filename_noext}
native_name=${nativename_noext}
chains=($(awk '$1 == "Number"{print $7 "(" $8 ")"}' $outfile))
fnat=$(awk '$1 == "Fnat"{print $2}' $outfile)
natc=$(awk '$1 == "Fnat"{print $3}' $outfile)
corc=$(awk '$1 == "Fnat"{print $6}' $outfile)
irmsd=$(awk '$1 == "iRMS"{print $2}' $outfile)
lrmsd=$(awk '$1 == "LRMS"{print $2}' $outfile)
capri=$(awk '$1 == "CAPRI"{print $2}' $outfile)
dockq=$(awk '$1 == "DockQ_CAPRI"{print $2}' $outfile)
dockqs=$(awk '$1 == "DockQ"{print $2}' $outfile)
printf "$format" "$decoy_name" "$native_name" "${chains[0]}" "${chains[1]}" "$fnat" "$natc" "$corc" "$irmsd" "$lrmsd" "$capri" "$dockq" "$dockqs"
rm $outfile ${filename_noext}.dockq.pdb
exit 0
