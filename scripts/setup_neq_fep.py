import BioSimSpace as bss
import os
import sys 

project_dir = "/group/chem/oliveira2t/af25016/kpc2-neq-fep-dnemd/"
# ligand_1_name = sys.argv[1]
# ligand_2_name = sys.argv[2]
# repeat = sys.argv[3]


ligand_1_name = "ligand_1"
ligand_2_name = "ligand_4"
repeat = 1

stage = "bound"

input_directory = f"{project_dir}/equilibration/"
outputs = f"{project_dir}/outputs/repeat_{repeat}/{ligand_1_name}~{ligand_2_name}/{stage}"

n_lambdas=3

min_protocol = bss.Protocol.FreeEnergyMinimisation(num_lam=n_lambdas)

nvt_protocol = bss.Protocol.FreeEnergyEquilibration(
    num_lam=n_lambdas, 
    pressure=None, 
    temperature=300*bss.Units.Temperature.kelvin,
    runtime=1*bss.Units.Time.nanosecond
)

npt_protocol = bss.Protocol.FreeEnergyEquilibration(
    num_lam=n_lambdas, 
    pressure=1*bss.Units.Pressure.atm,
    runtime=1*bss.Units.Time.nanosecond
)

rbfe_protocol = bss.Protocol.FreeEnergyProduction(
    num_lam=n_lambdas,
    runtime=500*bss.Units.Time.nanosecond,
    temperature=300*bss.Units.Temperature.kelvin
)

ligand_1_system = bss.IO.readMolecules([f"{input_directory}/{ligand_1_name}/repeat_{repeat}/{ligand_1_name}_npt.gro",
                                        f"{input_directory}/{ligand_1_name}/repeat_{repeat}/{ligand_1_name}.top"])


ligand_2_system = bss.IO.readMolecules([f"{input_directory}/{ligand_2_name}/repeat_{repeat}//{ligand_2_name}_npt.gro",
                                        f"{input_directory}/{ligand_2_name}/repeat_{repeat}//{ligand_2_name}.top"])

ligand_1 = None

for mol1 in ligand_1_system.getMolecules():
    residue = mol1.getResidues()[0]
    resname = residue.name()
    if resname == "UNL":
        ligand_1 = mol1
        break

ligand_2 = None

for mol2 in ligand_2_system.getMolecules():
    residue = mol2.getResidues()[0]
    resname = residue.name()
    if resname == "UNL":
        ligand_2 = mol2
        break

if not ligand_1 or not ligand_2:
    raise RuntimeError("could not set ligands") 

print("creating mapping")
mapping = bss.Align.matchAtoms(
    ligand_1, ligand_2
)

inverse_mapping = {v: k for k, v in mapping.items()}

print("aligning")
aligned_2 = bss.Align.rmsdAlign(
    ligand_2, ligand_1, inverse_mapping
)

print("merging")
merged_ligands = bss.Align.merge(
    ligand_1, aligned_2, mapping
)
ligand_1_system.removeMolecules(ligand_1)
ligand_1_system.addMolecules(merged_ligands)

bound_system = ligand_1_system

print("setting up bound RBFE")

bss.FreeEnergy.Relative(
    system=bound_system,
    protocol=min_protocol,
    engine="GROMACS",
    work_dir=outputs + "/bound/min/",
    setup_only=True
)

bss.FreeEnergy.Relative(
    system=bound_system,
    protocol=nvt_protocol,
    engine="GROMACS",
    work_dir=outputs + "/bound/nvt/",
    setup_only=True
)

bss.FreeEnergy.Relative(
    system=bound_system,
    protocol=npt_protocol,
    engine="GROMACS",
    work_dir=outputs + "/bound/npt/",
    setup_only=True
)

bss.FreeEnergy.Relative(
    system=bound_system,
    protocol=rbfe_protocol,
    engine="GROMACS",
    work_dir=outputs + "/bound/",
    setup_only=True
)
