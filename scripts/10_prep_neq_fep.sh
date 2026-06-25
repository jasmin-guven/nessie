#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/fep_network.csv"

tail -n +2 "$CSV" | while IFS=',' read -r idx ligand_a index_a ligand_b index_b rest; do
    for repeat in 1 2 3; do
        echo "Setting up ${ligand_a}~${ligand_b} repeat ${repeat}"
        python "${SCRIPT_DIR}/setup_neq_fep.py" "$ligand_a" "$ligand_b" "$repeat"
        python "${SCRIPT_DIR}/fix_mdp.py" "$ligand_a" "$ligand_b" "$repeat"
        zsh "${SCRIPT_DIR}/rename_input_files.sh" "$ligand_a~$ligand_b" "$repeat"
    done
done
