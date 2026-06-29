from dataclasses import dataclass, field
from typing import Optional
import os
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
class Ligand:
    name: str
    filepath: str
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

    def parameterise(self):

        if self.fileformat != "pdb":
