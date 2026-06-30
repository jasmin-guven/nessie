from dataclasses import dataclass, field
from typing import Optional, Literal
import os

from nessie.utils import utils

log = utils._initialise_logger()

@dataclass
class Ligand:
    name: str
    filepath: str
    net_charge: int = 0
    atom_type: Literal["gaff", "gaff2", "amber", "amber2"] = "gaff2"
    directory: Optional[str] = field(default=None, init=False)
    resname: Optional[str] = field(default=None, init=False)
    fileformat: Optional[str] = field(default=None, init=False)

    def __post_init__(self):
        if not os.path.isfile(self.filepath):
            raise FileNotFoundError(f"Ligand file not found: {self.filepath}")
        log.info(f"Loaded ligand file: {self.filepath}")

        _, file_extension = os.path.splitext(self.filepath)
        self.fileformat = file_extension.strip(".").lower()
        
        if not self.directory:
            log.info(f"Directory not set. Implying from input file: {self.filepath}")
            self.directory = os.path.dirname(self.filepath)
            log.info(f"Directory set to: {self.directory}")

        allowed_formats = ["sdf", "pdb"]
        if self.fileformat not in allowed_formats:
            raise NotImplementedError(f"Fileformat {self.fileformat} not supported.\nMust be one of {allowed_formats}.")
        
        log.info(f"fileformat set to {self.fileformat}")

    def _run_obabel(self):
        pdb_file = os.path.join(self.directory, f"{self.name}.pdb")
        obabel_command = f"obabel -i {self.fileformat} {self.filepath} -o pdb -O {pdb_file}"
        log.info(f"Converting input file from format {self.fileformat} to pdb:\n{obabel_command}")
        os.system(obabel_command)
        if not os.path.isfile(pdb_file):
            raise RuntimeError(f"File {pdb_file} not found, openbabel command likely failed.")
        log.info(f"Converted file to pdb format.")
        self.filepath = pdb_file
        

    def parameterise(self):

        if self.fileformat != "pdb":
            self._run_obabel()
        
        acpype_basename = os.path.join(self.directory, self.name)
        acpype_command = f"acpype -i {self.filepath} -n {self.net_charge} -a {self.atom_type} -b {acpype_basename}"
        log.info(f"Running acpype with command:\n{acpype_command}")
        os.system(acpype_command)
        if not os.path.isdir(acpype_basename):
            raise RuntimeError(f"Could not find acpype output directory: {acpype_basename}.\nThe acpype command likely failed.")
        
        