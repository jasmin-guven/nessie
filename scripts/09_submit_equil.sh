#!/bin/bash

equil_dir=$1

sbatch --job-name=ligand_%a_1 --error=logs/%x.err --output=logs/%x.out --array=1-16 run_equil.sh 1 $equil_dir
sbatch --job-name=ligand_%a_2 --error=logs/%x.err --output=logs/%x.out --array=1-16 run_equil.sh 2 $equil_dir
sbatch --job-name=ligand_%a_3 --error=logs/%x.err --output=logs/%x.out --array=1-16 run_equil.sh 3 $equil_dir
