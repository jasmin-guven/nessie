#!/bin/zsh

PROJECT_DIR="/Users/af25016/projects/kpc2-neq-fep-dnemd/"
transformation=$1
repeat=$2

lambda_array=(0.0000 1.0000)

transformation_dir=${PROJECT_DIR}/outputs/repeat_${repeat}/${transformation}

for stage in "bound" "unbound"
do
	stage_dir=${transformation_dir}/${stage}/
	cd $stage_dir
	for lambda in ${lambda_array[@]}
	do
		echo "min"
		cd ${stage_dir}/min/lambda_${lambda}/
		mv gromacs.mdp min.mdp
		mv gromacs.gro min_input.gro
		mv gromacs.top min.top
		rm -v gromacs.*
		rm -v gromacs_ref.*
		
		echo "nvt"
		cd ${stage_dir}/nvt/lambda_${lambda}/
		mv gromacs.mdp nvt.mdp
		mv gromacs.gro nvt.gro
		mv gromacs.top nvt.top
		rm -v gromacs.*
		rm -v gromacs_ref.*
		
		echo "npt"
		cd ${stage_dir}/npt/lambda_${lambda}/
		mv gromacs.mdp npt.mdp
		mv gromacs.gro npt.gro
		mv gromacs.top npt.top
		rm -v gromacs.*
		rm -v gromacs_ref.*
		
		echo "production"
		cd ${stage_dir}/lambda_${lambda}
		mv gromacs.mdp prod.mdp
		mv gromacs.gro prod.gro
		mv gromacs.top prod.top
		rm -v gromacs.*
		rm -v gromacs_ref.*
		
		cd $transformation_dir
	done
done
