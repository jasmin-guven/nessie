#!/bin/bash
#SBATCH --time=24:00:00      # Walltime
#SBATCH --partition=grace    # Queue name
#SBATCH --nodes=3            # number of compute nodes
#SBATCH --ntasks-per-node=144  # number of tasks per node
#SBATCH --cpus-per-task=1     # the number of CPUs to devote to each task


module load PrgEnv-cray/8.5.0


gmx_mpi mdrun -s NE.tpr \
	      -cpi LAST_CPT \
	      -deffnm BATCH \
	      -nsteps NSTEPS \
	      -cpt 1000
