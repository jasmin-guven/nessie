from dataclasses import dataclass, field
import os
from typing import Optional, List, Literal
from nessie.system_preparation.ligand import Ligand
import glob

import logging
from rich.logging import RichHandler
from rich.console import Console

console = Console(force_terminal=True, color_system="truecolor")

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(console=console, rich_tracebacks=True, markup=True)],
    force=True,
)

log = logging.getLogger("rich")


@dataclass
class Pipeline:
    project_directory: str
    protein_path: Optional[str] = field(default=None)
    ligand_path: Optional[str] = field(default=None)

    def __post_init__(self):
        if not os.path.isdir(self.project_directory):
            raise FileNotFoundError(f"'project_directory' does not exist: {self.project_directory}")

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



