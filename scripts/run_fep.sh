#!/bin/bash                                 
#SBATCH --time=24:00:00                     
#SBATCH --partition=grace               
#SBATCH --nodes=3                                                                                                                                                                                                
#SBATCH --ntasks-per-node=144                                                                                                                                                                                    
#SBATCH --cpus-per-task=1                                                                                                                                                                                        
                                                                                                                                                                                                                 
module load PrgEnv-cray/8.5.0                                                                                                                                                                                    
                                                                                                                                                                                                                 
start=$(date +%s)                                                                                                                                                                                                
                                                                                                                                                                                                                 
stage_dir=$1
NSTEPS=$2                                                                                                                                                                                                        
LAMBDA_IDX=$3   

BATCH=$SLURM_ARRAY_TASK_ID

lambda_array=(0.0000 1.0000)                
lambda=${lambda_array[$LAMBDA_IDX]}     

lambda_dir="${stage_dir}/lambda_${lambda}"                                                                                                                                                                       
cd "$lambda_dir"
                                                                                                                                                                                                                 
if [[ $BATCH == 1 ]]; then
    input_cpt_file="${stage_dir}/npt/lambda_${lambda}/npt.cpt"
    gmx_mpi grompp -f prod.mdp -c "${stage_dir}/npt/lambda_${lambda}/npt.gro" -p prod.top -o prod.tpr -maxwarn 2
else                                        
    PREV_BATCH=$(( BATCH - 1 ))         
    input_cpt_file="${lambda_dir}/${PREV_BATCH}.cpt"                                                                                                                                                             
fi                                                                                                                                                                                                               
                                                                                                                                                                                                                 
gmx_mpi mdrun -s prod.tpr \
              -cpi "$input_cpt_file" \
              -deffnm "$BATCH" \
              -nsteps "$NSTEPS" \
              -cpt 1000
                                                                                                                                                                                                                 
end=$(date +%s) 
runtime=$((end - start))
echo "Finished in $runtime seconds, or $((runtime/60)) minutes"

