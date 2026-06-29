#!/bin/bash

project_directory=$1

repeats=3

workdir=$PWD
for lig in "$project_directory"/ligand-structures/ligand_*
do
    base="${lig##*/}"

    echo "$base"
    cd "$project_directory"/equilibration/
    if [[ ! -d $base ]]; then
	mkdir $base
    fi
    
    for i in {1..3}
    do
	repeat_dir="$base/repeat_$i"
	if [[ ! -d $repeat_dir ]]; then
        	mkdir -p "$repeat_dir" 
    	fi
    
    	cp ${workdir}/*.mdp $repeat_dir/
	cp "$project_directory"/protein/posre.itp $repeat_dir/
	cp "$project_directory"/ligand-structures/"${base}"/"${base}"_solv_ions.gro $repeat_dir/
	cp "$project_directory"/ligand-structures/"${base}"/"${base}".top $repeat_dir/
	cp -r "$project_directory"/ligand-structures/"${base}"/"${base}".acpype $repeat_dir/
    done
done
