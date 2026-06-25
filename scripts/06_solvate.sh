#!/bin/bash

project_directory=$1

workdir=$PWD
for lig in "$project_directory"/ligand-structures/ligand_* 
do
    base="${lig##*/}"  

    echo "$base"

    cd "$project_directory"/ligand-structures/"$base"
    
    gmx_mpi editconf -f "kpc2_${base}_complex.gro" -o "${base}_newbox.gro" -bt cubic -d 1.0 -c 
    gmx_mpi solvate -cp "${base}_newbox.gro" -cs spc216.gro -p "${base}.top" -o "${base}_solv.gro"

    cd $workdir
done
