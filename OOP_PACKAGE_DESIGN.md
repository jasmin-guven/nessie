# pyNES: OOP Package Design Suggestion

## Overview

The scripts implement a **Non-Equilibrium Switching (NEQ) Free Energy Perturbation** pipeline for computing relative binding free energies (RBFE) of ligands to a protein target. The workflow uses GROMACS for MD, BioSimSpace for hybrid topology creation, and SLURM for HPC job submission.

The numbered scripts `01`–`11` define the canonical pipeline:

```
01 SDF → mol2/pdb        (obabel)
02 Parameterise ligands   (acpype / GAFF2)
03 Create complex .top    (sed + include patching)
04 Fix topology includes  (fix_topology_line.py)
05 Merge protein+ligand   (edit_gro_complex.py)
06 Solvate                (gmx editconf + solvate)
07 Add ions               (gmx grompp + genion)
08 Setup equilibration    (mkdir + file copy)
09 Submit equilibration   (sbatch arrays)
10 Prep NEQ FEP           (setup_neq_fep.py + fix_mdp.py + rename)
11 Rename inputs          (rename_input_files.sh)
```

The existing `FEP_Setup.py` (pmx-based) covers a parallel, older variant of the same concepts and is a useful reference for the class model.

---

## Suggested Package Layout

```
pynes/
├── __init__.py
├── pipeline.py            # Top-level orchestrator
├── config.py              # Dataclasses for simulation parameters
├── io/
│   ├── __init__.py
│   ├── fep_network.py     # FEPNetwork — reads fep_network.csv
│   └── file_utils.py      # Path helpers, file copy/move utilities
├── preparation/
│   ├── __init__.py
│   ├── ligand.py          # Ligand
│   ├── protein.py         # Protein
│   └── complex.py         # ProteinLigandComplex
├── simulation/
│   ├── __init__.py
│   ├── gromacs.py         # GromacsRunner
│   └── mdp.py             # MdpFile
├── fep/
│   ├── __init__.py
│   ├── transformation.py  # Transformation (one edge of the network)
│   └── setup.py           # NEQFEPSetup (BioSimSpace-based)
├── equilibration/
│   ├── __init__.py
│   └── equilibrator.py    # EquilibrationSetup
└── cluster/
    ├── __init__.py
    └── slurm.py           # SlurmSubmitter
```

---

## Class Designs

### `config.py`

Pure data — both are dataclasses with sensible defaults so they can be constructed from YAML/TOML.

```python
from dataclasses import dataclass, field

@dataclass
class SimulationConfig:
    n_repeats: int = 3
    n_lambdas: int = 16
    box_type: str = "cubic"
    box_d: float = 1.0
    water_model: str = "spc216.gro"
    ion_conc: float = 0.15
    pname: str = "NA"
    nname: str = "CL"
    temperature: float = 300.0   # K
    pressure: float = 1.0        # atm

@dataclass
class SlurmConfig:
    partition: str = "grace"
    walltime: str = "24:00:00"
    nodes: int = 3
    ntasks_per_node: int = 144
    cpus_per_task: int = 1
    modules: list[str] = field(default_factory=list)
```

---

### `preparation/ligand.py` — `Ligand`

Wraps scripts `01`, `02`, `04` and the `fix_topology_line.py` logic.
`base_dir` is resolved to `base_dir / name` in `__post_init__` so the caller passes the parent directory.

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Ligand:
    """A small molecule with associated file paths and parameterisation state."""
    name: str
    base_dir: Path

    def __post_init__(self):
        self.base_dir = self.base_dir / self.name

    # --- derived paths ---
    @property
    def sdf_file(self) -> Path: ...
    @property
    def mol2_file(self) -> Path: ...
    @property
    def pdb_file(self) -> Path: ...
    @property
    def acpype_dir(self) -> Path: ...
    @property
    def itp_file(self) -> Path: ...
    @property
    def gro_file(self) -> Path: ...
    @property
    def top_file(self) -> Path: ...

    # --- pipeline steps ---
    def convert_from_sdf(self) -> None:
        """Run obabel to produce mol2 + pdb. Corresponds to script 01."""

    def parameterise(self, charge: int = -1, force_field: str = "gaff2") -> None:
        """Run acpype. Corresponds to script 02."""

    def fix_topology_include(self) -> None:
        """Ensure the #include path in .top is quoted. Corresponds to script 04
        and the logic in fix_topology_line.py."""
```

---

### `preparation/protein.py` — `Protein`

Simple data holder for the pre-prepared protein input.

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Protein:
    """Pre-prepared protein structure + GROMACS topology."""
    project_dir: Path
    name: str = "protein"

    @property
    def gro_file(self) -> Path: ...
    @property
    def top_file(self) -> Path: ...    # topol.top
    @property
    def posre_file(self) -> Path: ...  # posre.itp
```

---

### `preparation/complex.py` — `ProteinLigandComplex`

Wraps scripts `03`, `05`, `06`, `07` and the logic in `edit_gro_complex.py`.

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class ProteinLigandComplex:
    """Protein + ligand system ready for MD."""
    protein: Protein
    ligand: Ligand

    @property
    def output_dir(self) -> Path: ...
    @property
    def complex_gro(self) -> Path: ...
    @property
    def complex_top(self) -> Path: ...

    def assemble_gro(self) -> None:
        """Merge protein and ligand GRO files. Corresponds to script 05 /
        edit_gro_complex.py."""

    def create_topology(self) -> None:
        """Insert ligand #include into protein topology. Corresponds to script 03."""

    def solvate(self, gmx: "GromacsRunner", box_type: str = "cubic", d: float = 1.0) -> None:
        """editconf + solvate. Corresponds to script 06."""

    def add_ions(self, gmx: "GromacsRunner", ions_mdp: Path, config: SimulationConfig) -> None:
        """grompp + genion. Corresponds to script 07."""
```

---

### `simulation/mdp.py` — `MdpFile`

Encapsulates reading, editing, and writing `.mdp` files. Replaces the procedural logic in `fix_mdp.py`.
`params` defaults to an empty dict; use `from_file` to load an existing file.

```python
from dataclasses import dataclass, field
from pathlib import Path

@dataclass
class MdpFile:
    """GROMACS MDP parameter file."""
    params: dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_file(cls, path: Path) -> "MdpFile":
        """Parse key = value lines."""

    def update(self, overrides: dict) -> None:
        """Merge overrides into params."""

    def remove(self, *keys: str) -> None:
        """Delete parameters by key."""

    def write(self, path: Path) -> None:
        """Write key = value lines."""
```

---

### `simulation/gromacs.py` — `GromacsRunner`

Thin, testable wrapper around `gmx_mpi` CLI calls. Replaces the scattered `subprocess.Popen` and `os.system('gmx ...')` calls throughout the scripts.

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class GromacsRunner:
    """Runs GROMACS commands via subprocess."""
    gmx_executable: str = "gmx_mpi"
    maxwarn: int = 2

    def editconf(self, input_gro: Path, output_gro: Path,
                 box_type: str = "cubic", d: float = 1.0) -> None: ...

    def solvate(self, input_gro: Path, output_gro: Path,
                cs: str = "spc216.gro", topology: Path = None) -> None: ...

    def grompp(self, mdp: Path, gro: Path, top: Path,
               output_tpr: Path, extra_flags: str = "") -> None: ...

    def genion(self, tpr: Path, topology: Path, output_gro: Path,
               pname: str = "NA", nname: str = "CL",
               conc: float = 0.15, neutral: bool = True) -> None: ...

    def mdrun(self, tpr: Path, output_prefix: str,
              n_steps: int = None, cpt: Path = None) -> None: ...
```

---

### `io/fep_network.py` — `FEPNetwork`

Reads `fep_network.csv` and provides access to `Transformation` objects.

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class FEPNetwork:
    """The set of ligand-pair transformations defined in fep_network.csv."""
    transformations: list["Transformation"]

    @classmethod
    def from_csv(cls, path: Path) -> "FEPNetwork": ...

    def get(self, ligand_a: str, ligand_b: str) -> "Transformation": ...

    def __iter__(self): ...
    def __len__(self): ...
```

---

### `fep/transformation.py` — `Transformation`

Represents a single edge in the perturbation network.
`name` is derived from its two ligands so it is a property rather than a stored field.

```python
from dataclasses import dataclass

@dataclass
class Transformation:
    """One ligand-pair perturbation edge."""
    ligand_a: Ligand
    ligand_b: Ligand
    score: float
    n_windows: int
    lambdas: list[float]

    @property
    def name(self) -> str:
        return f"{self.ligand_a.name}~{self.ligand_b.name}"
```

---

### `fep/setup.py` — `NEQFEPSetup`

Wraps BioSimSpace calls from `setup_neq_fep.py` and the MDP patching from `fix_mdp.py`. One instance per (transformation × repeat × stage).

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class NEQFEPSetup:
    """Sets up one NEQ FEP leg using BioSimSpace."""
    transformation: Transformation
    repeat: int
    stage: str           # "bound" or "unbound"
    project_dir: Path
    config: SimulationConfig

    @property
    def output_dir(self) -> Path: ...

    def load_systems(self) -> tuple:
        """Read equilibrated GRO + TOP for ligand_a and ligand_b."""

    def create_mapping(self): ...         # bss.Align.matchAtoms
    def align_and_merge(self): ...        # bss.Align.rmsdAlign + merge

    def setup_protocols(self) -> None:
        """Create min / nvt / npt / production BioSimSpace protocols and write
        GROMACS input for each lambda window."""

    def fix_mdp_files(self) -> None:
        """Patch cutoffs, thermostat, and output frequency in each lambda
        directory. Corresponds to fix_mdp.py."""

    def rename_inputs(self) -> None:
        """Rename gromacs.* → min.* / nvt.* / npt.* / prod.*.
        Corresponds to rename_input_files.sh."""

    def setup(self) -> None:
        """Run the full setup: load → map → merge → protocols → fix → rename."""
```

---

### `equilibration/equilibrator.py` — `EquilibrationSetup`

Manages the directory structure and file staging for equilibration (scripts `08`, `09`).

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class EquilibrationSetup:
    """Creates per-ligand, per-repeat equilibration directories."""
    project_dir: Path
    config: SimulationConfig
    scripts_dir: Path

    @property
    def equil_dir(self) -> Path: ...

    def setup_directories(self, ligands: list[Ligand]) -> None:
        """Create dirs and copy mdp/topology/posre/gro files. Script 08."""

    def submit(self, slurm: "SlurmSubmitter", n_ligands: int) -> list[str]:
        """Submit SLURM array jobs for all repeats. Script 09.
        Returns list of submitted job IDs."""
```

---

### `cluster/slurm.py` — `SlurmSubmitter`

Generates and submits SLURM job scripts, replacing the hardcoded `sbatch` calls.

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class SlurmSubmitter:
    """Creates and submits SLURM job scripts."""
    config: SlurmConfig
    scripts_dir: Path

    def submit_equilibration(self, equil_dir: Path,
                             n_repeats: int, array_range: str) -> list[str]:
        """sbatch arrays for run_equil.sh. Corresponds to script 09."""

    def submit_fep_production(self, stage_dir: Path,
                              n_steps: int, lambda_idx: int) -> str:
        """sbatch for run_fep.sh."""

    def _write_jobscript(self, path: Path, commands: list[str],
                         job_name: str, array: str = None) -> None: ...
```

---

### `pipeline.py` — `Pipeline`

Top-level orchestrator. Mirrors the numbered script sequence and gives users a single entry point.
`gmx` and `slurm` are derived from the other fields in `__post_init__`.

```python
from dataclasses import dataclass, field
from pathlib import Path

@dataclass
class Pipeline:
    """Orchestrates the full pyNES NEQ FEP workflow."""
    project_dir: Path
    network: FEPNetwork
    sim_config: SimulationConfig
    slurm_config: SlurmConfig
    gmx: GromacsRunner = field(init=False)
    slurm: SlurmSubmitter = field(init=False)

    def __post_init__(self):
        self.gmx = GromacsRunner()
        self.slurm = SlurmSubmitter(self.slurm_config, self.project_dir / "scripts")

    # --- step methods (can be called individually or via run_all) ---

    def prepare_ligands(self, ligand_dir: Path) -> list[Ligand]:
        """Scripts 01 + 02 + 04: SDF → mol2/pdb → acpype → fix topology."""

    def assemble_complexes(self, ligands: list[Ligand],
                           protein: Protein) -> list[ProteinLigandComplex]:
        """Scripts 03 + 05 + 06 + 07: merge GROs, create topology, solvate, ionise."""

    def setup_equilibration(self, ligands: list[Ligand]) -> EquilibrationSetup:
        """Script 08: create equilibration directories."""

    def submit_equilibration(self, equil_setup: EquilibrationSetup,
                             n_ligands: int) -> None:
        """Script 09: submit SLURM equilibration jobs."""

    def setup_fep(self) -> None:
        """Script 10: run NEQFEPSetup for all transformations × repeats."""

    def run_all(self, ligand_dir: Path, protein: Protein) -> None:
        """Execute the full pipeline end-to-end."""
```

---

## Data Flow Diagram

```
fep_network.csv ──► FEPNetwork ──► [Transformation, ...]
                                         │
ligand_*.sdf ──► Ligand ─────────────────┤
                   │ (prepare)           │
                   ▼                     │
              Ligand (parameterised)     │
                   │                    │
Protein ──────────►│                    │
                   ▼                    │
         ProteinLigandComplex           │
           (solvated + ionised)         │
                   │                    │
                   ▼                    │
         EquilibrationSetup ──► SLURM   │
                   │                    │
                   ▼                    ▼
              NEQFEPSetup (BioSimSpace + MdpFile)
                   │
                   ▼
              SLURM FEP production jobs
```

---

## Design Notes

- **Dataclasses are used for all classes** whose primary role is holding structured data (`Ligand`, `Protein`, `Transformation`, `MdpFile`, `GromacsRunner`, `FEPNetwork`, `NEQFEPSetup`, `EquilibrationSetup`, `SlurmSubmitter`, `Pipeline`). They give free `__repr__`, `__eq__`, and a consistent constructor signature, and make it straightforward to load configs from YAML/TOML via `dacite` or `cattrs`.
- **`__post_init__` for derived state**: `Ligand` resolves its working directory, and `Pipeline` constructs its injected `GromacsRunner` and `SlurmSubmitter` instances, so callers only supply the four declarative fields.
- **`field(init=False)`** on `Pipeline.gmx` and `Pipeline.slurm` signals that these are not constructor arguments — they are internal implementation details built from the other fields.
- **`name` stays a `@property`** on `Transformation` rather than a stored field: it is always derivable from `ligand_a` and `ligand_b`, so storing it separately would risk the two going out of sync.
- **Separation of concerns**: each class owns exactly one concept (file IO, GROMACS calls, BioSimSpace setup). The `Pipeline` composes them — it does not re-implement their logic.
- **`GromacsRunner` is injectable**: pass it to `ProteinLigandComplex`, `EquilibrationSetup`, etc., so tests can substitute a mock without spawning real GROMACS processes.
- **`MdpFile` replaces `fix_mdp.py`**: the procedural script has stage-specific conditionals that map cleanly to `update()` calls — one per stage type (`min`, `nvt`, `npt`, production).
- **`NEQFEPSetup` is per (transformation × repeat × stage)**: keeping it fine-grained makes it easy to parallelise or restart individual legs.
- **`FEPNetwork` is the single source of truth for edges**: the CSV columns (`score`, `n_windows`, `lambdas`) map directly onto `Transformation` fields, so downstream code never hard-codes lambda schedules.
