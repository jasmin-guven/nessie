from dataclasses import dataclass, field
import os
from typing import Optional

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
    protein_path: Optional[str] = field(default=None, init=False)
    ligand_path: Optional[str] = field(default=None, init=False)

    def __post_init__(self):
        if not os.path.isdir():
            raise FileNotFoundError(f"'project_directory' does not exist: {self.project_directory}")

        if not self.protein_path:
            try_protein_path = os.path.join(self.project_directory, "protein")
            log.info(f"'protein_path' not set. Trying: {try_protein_path}.")        
            if not os.path.isdir(try_protein_path):
                raise FileNotFoundError(f"{try_protein_path} does not exist. You can set it manually with the 'protein_path' attribute.")
                
