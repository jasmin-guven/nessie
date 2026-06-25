#!/bin/bash

# Resources
#SBATCH --time=24:00:00      # Walltime
#SBATCH --partition=grace    # Queue name
#SBATCH --nodes=3            # number of compute nodes
#SBATCH --ntasks-per-node=144  # number of tasks per node
#SBATCH --cpus-per-task=1

lig_i=$SLURM_ARRAY_TASK_ID
repeat=$1
equil_dir=$2

ligand="ligand_${lig_i}"

wd=$PWD
cd ${equil_dir}/${ligand}/repeat_${repeat}

bash ${wd}/minimise.sh $ligand

bash ${wd}/nvt.sh $ligand

bash ${wd}/npt.sh $ligand
