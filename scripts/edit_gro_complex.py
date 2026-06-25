import sys

project_dir = sys.argv[1]
ligand = sys.argv[2]

protein_gro_file = f"{project_dir}/protein/kpc2.prepared.gro"

ligand_file = f"{project_dir}/ligand-structures/{ligand}/{ligand}.acpype/{ligand}_GMX.gro"

with open(protein_gro_file, "r") as ifile:
    protein_lines = ifile.readlines()

n_atoms_protein = int(protein_lines[1])

fixed_protein_lines = protein_lines[2:-1]

last_line = protein_lines[-1]

with open(ligand_file, "r") as ifile:
    ligand_lines = ifile.readlines()

n_ligand_atoms = int(ligand_lines[1])

fixed_ligand_lines = ligand_lines[2:-1]

n_total = n_atoms_protein + n_ligand_atoms

with open(f"{project_dir}/ligand-structures/{ligand}/kpc2_{ligand}_complex.gro", "w") as ofile:
    ofile.write(f"kpc2 {ligand} complex \n")
    ofile.write(f" {str(n_total)}\n")
    ofile.writelines(fixed_protein_lines)
    ofile.writelines(fixed_ligand_lines)
    ofile.write(last_line)
