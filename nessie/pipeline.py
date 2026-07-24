from dataclasses import dataclass, field
import os
from typing import Optional, List, Literal, Union
from nessie.building_blocks.ligand import Ligand
from nessie.building_blocks.protein import Protein
import glob
from nessie.utils import utils

log = utils._initialise_logger()

# Pipeline requires project_directory (mandatory), protein_path, ligand_path, ligands and initialise everything
@dataclass
class Pipeline:
    project_directory: str
    protein_path: Optional[str] = field(default=None)
    ligand_path: Optional[str] = field(default=None)
    ligands: Optional[List[Ligand]] = field(default=None)

    # if self.project_directory is given, checks if exist
    def __post_init__(self):
        if not os.path.isdir(self.project_directory):
            raise FileNotFoundError(f"'project_directory' does not exist: {self.project_directory}")
        # if self.protein_path is not given, try to build it from project_directory
        if not self.protein_path:
            try_protein_path = os.path.join(self.project_directory, "protein")
            log.info(f"'protein_path' not set. Trying: {try_protein_path}.")        
            if not os.path.isdir(try_protein_path):
                raise FileNotFoundError(f"{try_protein_path} does not exist. You can set it manually with the 'protein_path' attribute.")
            self.protein_path = try_protein_path

        log.info(f"'protein_path' set to: {self.protein_path}")

        if len(os.listdir(self.protein_path)) == 0:
            raise RuntimeError(f"'protein_path' should contain at least one protein structure file")

        if not self.ligand_path:
            try_ligand_path = os.path.join(self.project_directory, "ligands")
            log.info(f"'ligand_path' not set. Trying: {try_ligand_path}.")        
            if not os.path.isdir(try_ligand_path):
                raise FileNotFoundError(f"{try_ligand_path} does not exist. You can set it manually with the 'ligand_path' attribute.")
            self.ligand_path = try_ligand_path
        
        log.info(f"'ligand_path' set to: {self.ligand_path}")

        if len(os.listdir(self.ligand_path)) == 0:
            raise RuntimeError(f"'ligand_path' should contain at least one ligand structure file")
        
    def prepare_ligands(
            self, 
            net_charge: int = 0,
            atom_type: Literal["gaff", "gaff2", "amber", "amber2"] = "gaff2",
            ligand_file_search_pattern: Optional[str] = "*.pdb",
            names: Optional[List[str]] = None,
            ligand_files: Optional[List[str]] = None,
    ):
        if not ligand_files:
            log.info(f"Reading ligand files from: {self.ligand_path}/{ligand_file_search_pattern}")
            ligand_files = sorted(glob.glob(f"{self.ligand_path}/{ligand_file_search_pattern}"))
        
            if not ligand_files:
                raise RuntimeError(f"Could not find any ligand files in {self.ligand_path} matching the string '{ligand_file_search_pattern}'")
            
        if not names:
            log.info(f"Taking ligand names from filenames.")
            names = [os.path.basename(file).split(".")[0] for file in ligand_files]


        if len(names) != len(ligand_files):
            raise RuntimeError(f"The number of names ({len(names)}) must match ({len(ligand_files)}).")

        ligands = [Ligand(
            name=name, filepath=file, net_charge=net_charge, atom_type=atom_type
        ) for name, file in zip(names, ligand_files)]
        
        parameterised_ligands = [ligand.parameterise() for ligand in ligands]

    # define prepare_protein method, that uses Protein.parametrise function 
    def prepare_protein(
            self, 
            protein_structure_file: str,
            force_field: Literal[
                "amber03", "amber19sb", "amber14sb", "amber94", "amber96", "amber99", 
                "amber99sb-ildn", "amber99sb", "amberGS", "charmm27", "gromos43a1", "gromos43a2", 
                "gromos43a3", "gromos43a5", "gromos43a6", "gromos43a7", "oplsaa"
            ] = "amber14sb",
            water_model: Literal[
                "tip3p", "tip4p", "opc", 
                "opc3", "spc", "spce", 
                "none", "tip4pew", "tip5p", "tips3p"
            ] = "tip3p",            
    ):

        protein = Protein(
            filepath=protein_structure_file,
            force_field=force_field, 
            water_model=water_model
        )
        
        parameterised_protein = protein.parameterise()

        return parameterised_protein

        


