#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/fep_network.csv"

projdir="/home/u35ac/jjguven.u35ac/kpc2-neq-fep-dnemd/"

workdir=$PWD

TOTAL_NS=500
BATCH_NS=5
DT_FS=2  # 0.002 ps = 2 fs                                                                                                                                                                                       

NUM_BATCHES=$((TOTAL_NS / BATCH_NS))
STEPS_PER_BATCH=$(( BATCH_NS * 1000000 / DT_FS ))

stage="bound"

tail -n +2 "$CSV" | while IFS=',' read -r idx ligand_a index_a ligand_b index_b rest; do
	transformation="${ligand_a}~${ligand_b}"
	for rep in {1..3}; do

	    stage_dir="${projdir}/outputs/repeat_${rep}/${transformation}/${stage}" 
	    cd "$stage_dir" 

	    PREV_JOB_ID=""

	    for ((i=1;i<=NUM_BATCHES;i++)); do

		OUT_CPT="${BATCH}.cpt" 

		if [ -z "$PREV_JOB_ID" ]; then
		    JOB_ID=$(sbatch --parsable --output="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${BATCH}.out" --error="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${BATCH}.err"  --array=0,1 ${workdir}/run_eq_fep.sh $stage_dir ${STEPS_PER_BATCH} $i ${OUT_CPT})
		else
		    JOB_ID=$(sbatch --job-name="${transformation}" --array=0,1 --output="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${BATCH}.out" --error="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${BATCH}.err" --dependency=afterok:${PREV_JOB_ID} --parsable ${workdir}/run_eq_fep.sh $stage_dir ${STEPS_PER_BATCH} $i ${OUT_CPT})
		fi

		PREV_JOB_ID=$JOB_ID
		LAST_CPT=$OUT_CPT

	    done

	    cd "$projdir"

	done
done
