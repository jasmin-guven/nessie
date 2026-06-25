#!/bin/bash

directory=$1

for lig in "$directory"/ligand_*; do
	cd $lig
	base="${lig##*/}"	
	acpype -i "$base".mol2 -n -1 -a gaff2 

done
