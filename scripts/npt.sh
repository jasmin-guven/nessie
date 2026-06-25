#!/bin/bash

ligand=$1

gmx_mpi grompp \
	-f npt.mdp \
	-c ${ligand}_nvt.gro \
	-r ${ligand}_nvt.gro \
	-p ${ligand}.top \
	-o ${ligand}_npt.tpr

gmx_mpi mdrun -v -s ${ligand}_npt.tpr -deffnm ${ligand}_npt
