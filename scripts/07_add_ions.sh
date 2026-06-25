#!/bin/bash

project_directory=$1

workdir=$PWD
for lig in "$project_directory"/ligand-structures/ligand_* 
do
    base="${lig##*/}"  

    echo "$base"

    cd "$project_directory"/ligand-structures/"$base"
    
    gmx_mpi grompp -f "${project_directory}/scripts/ions.mdp" -c "${base}_solv.gro" -p "${base}.top" -o "${base}_ions.tpr" -maxwarn 2
    gmx_mpi genion -s "${base}_ions.tpr" -o "${base}_solv_ions.gro" -p "${base}.top" -pname NA -nname CL -neutral << EOF
15
EOF
    cd $workdir
done
