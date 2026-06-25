#!/bin/bash
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=144
#SBATCH --cpus-per-task=1
#SBATCH --partition=grace
#SBATCH --time=24:00:0

module load PrgEnv-cray/8.5.0

start=`date +%s`

PROJECT_DIR=$1
transformation=$2
i=$3

lambda_array=(0.0000 1.0000)

id=$SLURM_ARRAY_TASK_ID
lambda=${lambda_array[$id]}

transformation_dir=${PROJECT_DIR}/outputs/repeat_${i}/${transformation}

stage="bound"

stage_dir=${transformation_dir}/${stage}/
cd $stage_dir

echo "min"
cd ${stage_dir}/min/lambda_${lambda}/
gmx_mpi grompp -f min.mdp -c min_input.gro -p min.top -o min.tpr -maxwarn 2
gmx_mpi mdrun -deffnm min

echo "nvt"
cd ${stage_dir}/nvt/lambda_${lambda}/
gmx_mpi grompp -f nvt.mdp -c ${stage_dir}/min/lambda_${lambda}/min.gro -p nvt.top -o nvt.tpr -maxwarn 2
gmx_mpi mdrun  -deffnm nvt

echo "npt"
cd ${stage_dir}/npt/lambda_${lambda}/
gmx_mpi grompp -f npt.mdp -c ${stage_dir}/nvt/lambda_${lambda}/nvt.gro -p npt.top -t ${stage_dir}/nvt/lambda_${lambda}/nvt.cpt -o npt.tpr -maxwarn 2
gmx_mpi mdrun  -deffnm npt

cd $transformation_dir

end=`date +%s`
runtime=$((end - start))

echo "Finished in $runtime seconds, or $((runtime/60)) minutes"



