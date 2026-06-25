#!/bin/bash
#SBATCH --time=24:00:00      # Walltime
#SBATCH --partition=grace    # Queue name
#SBATCH --nodes=3            # number of compute nodes
#SBATCH --ntasks-per-node=144  # number of tasks per node
#SBATCH --cpus-per-task=1     # the number of CPUs to devote to each task

module load PrgEnv-cray/8.5.0

start=`date +%s`
stage_dir=$1

NSTEPS=$2
BATCH=$3
last_cpt=$4

lambda_array=(0.0000 1.0000)

id=$SLURM_ARRAY_TASK_ID
lambda=${lambda_array[$id]}

lambda_dir=${stage_dir}/lambda_${lambda}

if [[ $BATCH == 1 ]]; then
	input_cpt_file="${stage_dir}/npt/lambda_${lambda}/npt.cpt" 
	gmx_mpi grompp -f prod.mdp -c "${stage_dir}"/npt/lambda_${lambda}/npt.gro -p prod.top -o prod.tpr -maxwarn 2
else
	input_cpt_file=$last_cpt

gmx_mpi mdrun -s prod.tpr \
	      -cpi $input_cpt_file \
	      -deffnm $BATCH \
	      -nsteps $NSTEPS \
	      -cpt 1000

end=`date +%s`
runtime=$((end - start))

echo "Finished in $runtime seconds, or $((runtime/60)) minutes"
