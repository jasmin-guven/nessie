#!/bin/bash

directory=$1


workdir=$PWD
for lig in "$directory"/ligand_*; do
    base="${lig##*/}"     # ligand_1.sdf

    echo "$base"
    cd "$directory"/$base 	
    
    infile="../../protein/topol.top"
    outfile="${base}.top"
    newline="#include ${base}.acpype/${base}_GMX.itp"
    
#    echo $infile
#    echo $outfile
#    echo $newline
	
    sed "/^#include/a $newline" "$infile" > "$outfile"
 
    echo "UNL           1" >> "$outfile"
    
    sed -i "s/${base}/UNL/g" "${directory}"/"${base}"/"${base}".acpype/"${base}"_GMX.itp
    cd $workdir
done
