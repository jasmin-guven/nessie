#!/bin/bash                                 
                                                                                                                                                                                                                 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/fep_network.csv"                                                                                                                                                                              
                                                                                                                                                                                                                 
projdir="/home/u35ac/jjguven.u35ac/kpc2-neq-fep-dnemd/"                                                                                                                                                          
workdir=$PWD                                                                                                                                                                                                     
                
TOTAL_NS=500                                                                                                                                                                                                     
BATCH_NS=5
DT_FS=2                                                                                                                                                                                                          
                
NUM_BATCHES=$((TOTAL_NS / BATCH_NS))        
STEPS_PER_BATCH=$(( BATCH_NS * 1000000 / DT_FS ))

stage="bound"                                                                                                                                                                                                    
 
tail -n +2 "$CSV" | while IFS=',' read -r idx ligand_a index_a ligand_b index_b rest; do                                                                                                                         
    transformation="${ligand_a}~${ligand_b}"
    for rep in {1..3}; do
        for lambda in 0 1; do                                                                                                                                                                                    
            stage_dir="${projdir}/outputs/repeat_${rep}/${transformation}/${stage}"
                                                                                                                                                                                                                 
            sbatch \
                --job-name="${transformation}_rep${rep}_l${lambda}" \
                --array=1-${NUM_BATCHES}%1 \
                --output="${projdir}/logs/bound-eq-prod-${rep}-%x-%a.out" \
                --error="${projdir}/logs/bound-eq-prod-${rep}-%x-%a.err" \
                ${workdir}/run_fep.sh "$stage_dir" "$STEPS_PER_BATCH" "$lambda"
        done                                
    done                                                                                                                                                                                                         
done
