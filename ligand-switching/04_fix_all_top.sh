#!/bin/bash

project_directory=$1

workdir=$PWD
for lig in "$project_directory"/ligand-structures/ligand_* 
do
    base="${lig##*/}"  

    echo "$base"

    python fix_topology_line.py $project_directory $base

    cd $workdir
done
