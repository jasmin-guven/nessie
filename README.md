# nessie: python package for non-equilibrium switching (NES) and dynamical non-equilibrium molecular dynamics (D-NEMD)

# Requirements

1. nessie needs [Gromacs](https://www.gromacs.org) to be able to run non-equilibrium switching simulations
2. You will need either [mamba](https://mamba.readthedocs.io/en/latest/) (**recommended**) or [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) installed to install nessie.

# Installation instructions for developers

Download the `dev-environment.yml` file:
```
curl --output dev-environment.yml https://raw.githubusercontent.com/jasmin-guven/nessie/refs/heads/main/dev-environment.yml
```

Create and activate the environment:
```
mamba env create -f dev-environment.yml
mamba activate nessie-dev
```


# Notes:
## Setup 

1) Ligand mutation:
- need list of ligand files
- pre-prepared protein file
- then the script will parameterise + create all protein+ligand complexes
- solvation
- equilibration
- EQ production
- NEQ switching
- Analysis with pmx/BAR

2) Protein mutation: 
- ligand file
- pre-prepared protein file of state A (e.g. WT) and state B (e.g. mutant)
- then the script will parameterise + create protein+ligand complexes for both states
- solvation
- equilibration
- EQ production
- NEQ switching
- Analysis with pmx/BAR

## General questions 
- Should we create the hybrid topology before equilibration or just before EQ production? 
