#!/bin/bash

project_directory=$1

workdir=$PWD
for lig in "$project_directory"/ligand-structures/ligand_* 
do
    base="${lig##*/}"  

    echo "$base"

    python edit_gro_complex.py $project_directory $base

    cd $workdir
done
