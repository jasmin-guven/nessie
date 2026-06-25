import sys

project_dir = sys.argv[1]
ligand = sys.argv[2]

ligand_file = f"{project_dir}/ligand-structures/{ligand}/{ligand}.top"

with open(ligand_file, "r") as ifile:
    ligand_lines = ifile.readlines()

include_line = [line for line in ligand_lines if "#include" in line and "ligand" in line][0]

ligand_top = include_line.strip().split()[1]

ligand_top_in_quotes = f'"{ligand_top}"' 

fixed_ligand_lines = []
first_include = 0
for line in ligand_lines:
    if line == include_line and first_include == 0:
        new_line = line.replace(ligand_top, ligand_top_in_quotes)
        first_include = 1
    elif line == include_line and first_include == 1:
        new_line = "\n"
    else:
        new_line = line
    fixed_ligand_lines.append(new_line)

with open(ligand_file, "w") as ofile:
    ofile.writelines(fixed_ligand_lines)
