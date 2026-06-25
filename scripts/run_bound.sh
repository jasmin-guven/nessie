#!/bin/bash
#SBATCH -n 1
#SBATCH --gres=gpu:1
#SBATCH --partition gpu,mwvdk
#SBATCH --account=chem037584
#SBATCH --time=14-00:00:0


start=`date +%s`

PROJECT_DIR=$1
transformation=$2

lambda_array=(0.0000 1.0000)

N_REPEATS=3

id=$SLURM_ARRAY_TASK_ID
lambda=${lambda_array[$id]}

transformation_dir=${PROJECT_DIR}/outputs/${transformation}

stage="bound"

for (( i=1; i<=$N_REPEATS; i++))
do
    stage_dir=${transformation_dir}/repeat_${i}/${stage}/
    cd $stage_dir
    
    echo "min"
    cd ${stage_dir}/min/lambda_${lambda}/
    gmx_mpi grompp -f min.mdp -c min_input.gro -p min.top -o min.tpr
    gmx_mpi mdrun -deffnm min

    echo "nvt"
    cd ${stage_dir}/nvt/lambda_${lambda}/
    gmx_mpi grompp -f nvt.mdp -c ${stage_dir}/min/lambda_${lambda}/min.gro -p nvt.top -o nvt.tpr
    gmx_mpi mdrun  -deffnm nvt
    
    echo "npt"
    cd ${stage_dir}/npt/lambda_${lambda}/
    gmx_mpi grompp -f npt.mdp -c ${stage_dir}/nvt/lambda_${lambda}/nvt.gro -p npt.top -t ${stage_dir}/nvt/lambda_${lambda}/nvt.cpt -o npt.tpr
    gmx_mpi mdrun  -deffnm npt

    echo "production"
    cd ${stage_dir}/lambda_${lambda}
    gmx_mpi grompp -f prod.mdp -c ${stage_dir}/npt/lambda_${lambda}/npt.gro -p prod.top -t ${stage_dir}/npt/lambda_${lambda}/npt.cpt -o prod.tpr
    gmx_mpi mdrun  -deffnm prod 

    cd $transformation_dir
done


end=`date +%s`
runtime=$((end - start))

echo "Finished in $runtime seconds, or $((runtime/60)) minutes"



