#!/bin/bash

directory=$1

for lig in "$directory"/ligand_*.sdf; do
    base="${lig##*/}"     # ligand_1.sdf
    base="${base%.*}"     # ligand_1

    echo "$base"
    if [[ ! -d "$directory"/"$base" ]]; then
    	mkdir -p "$directory"/"$base"
    fi
    cd "$directory"/"$base"
    mv "$directory"/"$base".sdf .
    obabel -i sdf "$base".sdf -o mol2 -O "$base.mol2"
    obabel -i sdf "$base".sdf -o pdb -O "$base.pdb"
done
