#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/fep_network.csv"

projdir="/home/u35ac/jjguven.u35ac/kpc2-neq-fep-dnemd/"

TOTAL_NS=500
BATCH_NS=5
DT=0.002

NUM_BATCHES=$((TOTAL_NS / BATCH_NS))
STEPS_PER_BATCH=$(( BATCH_NS * 1000 / DT ))

stage="bound"

tail -n +2 "$CSV" | while IFS=',' read -r idx ligand_a index_a ligand_b index_b rest; do
	transformation="${ligand_a}~${ligand_b}"
	for rep in {1..3}; do

	    stage_dir="${projdir}/outputs/repeat_${rep}/${transformation}/${stage}" 
	    cd "$stage_dir" 

	    PREV_JOB_ID=""
	    LAST_CPT="${stage_dir}/npt/npt.cpt" # CHANGE NAME

	    for ((i=1;i<=NUM_BATCHES;i++)); do

		TIME_NS=$((i * BATCH_NS))
		OUT_CPT="${TIME_NS}ns.cpt" 
		JOB_SCRIPT="batch_${i}_lig${lig}_rep${rep}.sh"

		sed -e "s/BATCH/${i}/g" \
		    -e "s/LIG/${lig}/g" \ # TRANSFORMATION
		    -e "s/REPEAT/${rep}/g" \
		    -e "s|LAST_CPT|${LAST_CPT}|g" \
		    -e "s/NSTEPS/${STEPS_PER_BATCH}/g" \
		    ../../slurmer.sh > "$JOB_SCRIPT"

		if [ -z "$PREV_JOB_ID" ]; then
		    JOB_ID=$(sbatch --parsable --output="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${TIME_NS}.out" --error="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${TIME_NS}.err"  "$JOB_SCRIPT")
		else
		    JOB_ID=$(sbatch --job-name="${transformation}" --array=0,1 --output="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${TIME_NS}.out" --error="$projdir/logs/bound-eq-prod-${rep}-%x-%a-${TIME_NS}.err" --dependency=afterok:${PREV_JOB_ID} --parsable "$JOB_SCRIPT")
		fi

		PREV_JOB_ID=$JOB_ID
		LAST_CPT=$OUT_CPT

	    done

	    cd "$projdir"

	done
done
