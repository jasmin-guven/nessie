#!/bin/bash

ligand=$1

gmx_mpi grompp \
	-f nvt.mdp \
	-c ${ligand}_em.gro \
	-r ${ligand}_em.gro \
	-p ${ligand}.top \
	-o ${ligand}_nvt.tpr

gmx_mpi mdrun -v -s ${ligand}_nvt.tpr -deffnm ${ligand}_nvt

