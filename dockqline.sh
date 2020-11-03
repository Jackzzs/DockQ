#!/bin/bash
DOCKQ_HOME=$1
# *.dockq.native.pdb
native=$2
# *.pdb
file=$3
format=$4
tempdir=$5
sort=$6

filename="${file##*/}"
filename_noext="${filename%.*}"
nativename="${native##*/}"
nativename_noext="${nativename%.*.*.*}"
${sort} $file $tempdir/${filename_noext}.dockq.pdb
outfile=${filename_noext}.${nativename_noext}.dockq.out
errfile=${filename_noext}.${nativename_noext}.dockq.err
$DOCKQ_HOME/DockQ.py $tempdir/${filename_noext}.dockq.pdb $native 1>$tempdir/$outfile 2>$tempdir/$errfile
if [[ -n $(cat $tempdir/$errfile) ]]; then
    echo "Warning: dockq warnning: $(cat $tempdir/$errfile)" >&2
fi
if [[ $? > 0 ]]; then
    echo "Warning: dockq failed for $file (native: $native). skipping." >&2
    exit
fi
decoy_name=${filename_noext}
native_name=${nativename_noext}
chains=($(awk '$1 == "Number"{print $7 "(" $8 ")"}' $tempdir/$outfile))
fnat=$(awk '$1 == "Fnat"{print $2}' $tempdir/$outfile)
natc=$(awk '$1 == "Fnat"{print $3}' $tempdir/$outfile)
corc=$(awk '$1 == "Fnat"{print $6}' $tempdir/$outfile)
irmsd=$(awk '$1 == "iRMS"{print $2}' $tempdir/$outfile)
lrmsd=$(awk '$1 == "LRMS"{print $2}' $tempdir/$outfile)
capri=$(awk '$1 == "CAPRI"{print $2}' $tempdir/$outfile)
dockq=$(awk '$1 == "DockQ_CAPRI"{print $2}' $tempdir/$outfile)
dockqs=$(awk '$1 == "DockQ"{print $2}' $tempdir/$outfile)
printf "$format" "$decoy_name" "$native_name" "${chains[0]}" "${chains[1]}" "$fnat" "$natc" "$corc" "$irmsd" "$lrmsd" "$capri" "$dockq" "$dockqs"
exit 0
