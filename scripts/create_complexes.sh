#!/bin/bash

directory=$1


workdir=$PWD
for lig in "$directory"/ligand_*.sdf 
do
    base="${lig##*/}"     # ligand_1.sdf
    base="${base%.*}"     # ligand_1

    echo "$base"
    cd $directory 	
    cat ../protein/kpc2.prepared.pdb ${base}.pdb ../protein/wat.pdb > kpc2_${base}.pdb
    pdb4amber -i kpc2_${base}.pdb -o kpc2_${base}.prepared.pdb 
    cd $workdir
done
