from dataclasses import dataclass, field
from typing import Optional, Union, List
import os
from nessie.utils import utils

log = utils._initialise_logger()

@dataclass
class Protein:
    filepath: Union[str, List[str]]
    force_field: str = "amber14sb"
    water_model: str = "tip3p"
    group_name: Optional[str] = "nessie_complex"
    directory: Optional[str] = field(default=None, init=False)

    def __post_init__(self):

        if not isinstance(self.filepath, list):
            self.filepath = [self.filepath]
        
        for file in self.filepath:
            if not os.path.isfile(file):
                raise FileNotFoundError(f"Protein file not found: {file}")
        
        log.info(f"Loaded protein file(s): {self.filepath}")

        if not self.directory:
            log.info(f"Directory not set. Implying from input file: {self.filepath[0]}")
            self.directory = os.path.dirname(self.filepath[0])
            log.info(f"Directory set to: {self.directory}")


    def parameterise(
            self, 
            gmx_executable: str = "gmx",
            ignore_hyrdorgens: bool = False
    ):
        
        output_structure_file = os.path.join(self.directory, f"{self.group_name}.gro")
        topology_file = os.path.join(self.directory, "topol.top")
        if ignore_hyrdorgens:
            ignh = "-ignh"
        else:
            ignh = "-noignh"
        pdb2gmx_command = f"{gmx_executable} pdb2gmx -f {self.filepath} \
                                -o {output_structure_file} \
                                -p {topology_file} \
                                -ff {self.force_field} \
                                -water {self.water_model} {ignh}"
        log.info(f"Running {gmx_executable} pdb2gmx with command:\n{pdb2gmx_command}")
        os.system(pdb2gmx_command)
        if not os.path.isfile(output_structure_file) or not os.path.isfile(topology_file):
            raise RuntimeError(f"Could not find pdb2gmx output gro or top file.\n The pdb2gmx command likely failed.")





