#!/bin/bash

ligand=$1

gmx_mpi grompp \
	-f em.mdp \
	-c ${ligand}_solv_ions.gro \
	-p ${ligand}.top \
	-o ${ligand}_em.tpr

gmx_mpi mdrun -v -s ${ligand}_em.tpr -deffnm ${ligand}_em
