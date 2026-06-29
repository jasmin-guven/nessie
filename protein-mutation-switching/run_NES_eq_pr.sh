#!/bin/bash

#SBATCH --job-name NES_eq
#SBATCH --array=0-3
#SBATCH -o logs/NES_eq_%A_%a.out
#SBATCH -e logs/NES_eq_%A_%a.err
#SBATCH --account=chem021482
#SBATCH --time=3-00:00:00     # Walltime
#SBATCH --partition=gpu,mwvdk       # Queueu name
#SBATCH --gres=gpu:1
#SBATCH --nodes=1             # number of compute nodes
#SBATCH --ntasks-per-node=4  # number of tasks per node
#SBATCH --cpus-per-task=1     # the number of CPUs to devote to each task
#SBATCH --mem=8GB

module load openmpi
module load gromacs

set -euo pipefail

start=$(date +%s)

PROJECT_DIR="/group/chem/oliveira2t/vi24769/dnemd-nes-pipeline"
MDP="${PROJECT_DIR}/inputs/mdps"

# Array index maps to one (system, state, lambda) combination
# 4 jobs run in parallel via --array=0-3
systems=("bound"   "bound"   "unbound" "unbound")
states=( "A"       "B"       "A"       "B")
lambdas=("0.0000"  "1.0000"  "0.0000"  "1.0000")

id=$SLURM_ARRAY_TASK_ID
SYS=${systems[$id]}
ST=${states[$id]}
LAM=${lambdas[$id]}
LDIR="lambda_${LAM}"
INDEX="${PROJECT_DIR}/${SYS}/state_${ST}"
echo "=== Starting: ${SYS} state_${ST} ${LDIR} ==="

for rep in 1 2 3; do
    BASE="${PROJECT_DIR}/${SYS}/state_${ST}/rep_${rep}"
    echo "--- rep_${rep} ---"

    echo "min"
    gmx_mpi grompp -f ${MDP}/em_s${ST}.mdp \
                   -c ${BASE}/min/${LDIR}/gromacs.gro \
                   -p ${BASE}/min/${LDIR}/gromacs.top \
                   -o ${BASE}/min/${LDIR}/min.tpr \
                   -maxwarn 2
    gmx_mpi mdrun -s ${BASE}/min/${LDIR}/min.tpr \
                  -deffnm ${BASE}/min/${LDIR}/min

    echo "nvt1"
    gmx_mpi grompp -f ${MDP}/nvt1_s${ST}.mdp \
                   -c ${BASE}/min/${LDIR}/min.gro \
                   -r ${BASE}/min/${LDIR}/min.gro \
		   -n ${INDEX}/index.ndx \
                  -p ${BASE}/nvt1/${LDIR}/gromacs.top \
                  -o ${BASE}/nvt1/${LDIR}/nvt1.tpr \
                   -maxwarn 2
    gmx_mpi mdrun -s ${BASE}/nvt1/${LDIR}/nvt1.tpr \
                  -deffnm ${BASE}/nvt1/${LDIR}/nvt1

    echo "nvt2"
    gmx_mpi grompp -f ${MDP}/nvt2_s${ST}.mdp \
                   -c ${BASE}/nvt1/${LDIR}/nvt1.gro \
                   -r ${BASE}/nvt1/${LDIR}/nvt1.gro \
		   -n ${INDEX}/index.ndx \
                  -p ${BASE}/nvt2/${LDIR}/gromacs.top \
                   -t ${BASE}/nvt1/${LDIR}/nvt1.cpt \
                   -o ${BASE}/nvt2/${LDIR}/nvt2.tpr \
                   -maxwarn 2
    gmx_mpi mdrun -s ${BASE}/nvt2/${LDIR}/nvt2.tpr \
                  -deffnm ${BASE}/nvt2/${LDIR}/nvt2

    echo "npt1"
    gmx_mpi grompp -f ${MDP}/npt1_s${ST}.mdp \
                   -c ${BASE}/nvt2/${LDIR}/nvt2.gro \
                   -r ${BASE}/nvt2/${LDIR}/nvt2.gro \
		   -n ${INDEX}/index.ndx \
                   -p ${BASE}/npt1/${LDIR}/gromacs.top \
                   -t ${BASE}/nvt2/${LDIR}/nvt2.cpt \
                   -o ${BASE}/npt1/${LDIR}/npt1.tpr \
                   -maxwarn 2
    gmx_mpi mdrun -s ${BASE}/npt1/${LDIR}/npt1.tpr \
                  -deffnm ${BASE}/npt1/${LDIR}/npt1

    echo "npt2"
    gmx_mpi grompp -f ${MDP}/npt2_s${ST}.mdp \
                   -c ${BASE}/npt1/${LDIR}/npt1.gro \
		   -n ${INDEX}/index.ndx \
                   -p ${BASE}/npt2/${LDIR}/gromacs.top \
                   -t ${BASE}/npt1/${LDIR}/npt1.cpt \
                   -o ${BASE}/npt2/${LDIR}/npt2.tpr \
                   -maxwarn 2
    gmx_mpi mdrun -s ${BASE}/npt2/${LDIR}/npt2.tpr \
                  -deffnm ${BASE}/npt2/${LDIR}/npt2

    echo "eq"
    gmx_mpi grompp -f ${MDP}/eq_s${ST}.mdp \
                   -c ${BASE}/npt2/${LDIR}/npt2.gro \
		   -n ${INDEX}/index.ndx \
                   -p ${BASE}/${LDIR}/gromacs.top \
                   -t ${BASE}/npt2/${LDIR}/npt2.cpt \
                   -o ${BASE}/${LDIR}/eq.tpr \
                   -maxwarn 2
    gmx_mpi mdrun -s ${BASE}/${LDIR}/eq.tpr \
                  -deffnm ${BASE}/${LDIR}/eq

done

end=$(date +%s)
echo "=== Finished ${SYS} state_${ST} ${LDIR} in $(( (end - start) / 60 )) minutes ==="
