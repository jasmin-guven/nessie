#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/fep_network.csv"

projdir="/home/u35ac/jjguven.u35ac/kpc2-neq-fep-dnemd/"

tail -n +2 "$CSV" | while IFS=',' read -r idx ligand_a index_a ligand_b index_b rest; do
    for repeat in 1 2 3; do
        echo "Submitting ${ligand_a}~${ligand_b} repeat ${repeat} bound equilibration"
	sbatch --job-name="${ligand_a}~${ligand_b}" --array=0,1 --output="$projdir/logs/bound-equil-${repeat}-%x-%a.out" --error="$projdir/logs/bound-equil-${repeat}-%x-%a.err" bound_neq_fep_equil.sh $projdir "${ligand_a}~${ligand_b}" $repeat
        echo "Submitting ${ligand_a}~${ligand_b} repeat ${repeat} unbound equilibration"
	sbatch --job-name="${ligand_a}~${ligand_b}" --array=0,1 --output="$projdir/logs/unbound-equil-${repeat}-%x-%a.out" --error="$projdir/logs/unbound-equil-${repeat}-%x-%a.err" unbound_neq_fep_equil.sh $projdir "${ligand_a}~${ligand_b}" $repeat
	
    done
done
