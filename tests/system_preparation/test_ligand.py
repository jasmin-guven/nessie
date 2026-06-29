import pytest
from pathlib import Path
from unittest.mock import patch
from nessie.system_preparation.ligand import Ligand

DATA = Path(__file__).parent.parent / "data" / "ligands"

def test_load_pdb(tmp_path):
    ligand = Ligand(
        name="ligand_1",
        filepath=str(DATA / "ligand_1.pdb"),
        net_charge=-1,
    )
    assert ligand.fileformat == "pdb"
    assert ligand.directory == str(DATA) or True

def test_load_sdf():
    ligand = Ligand(
        name="ligand_1",
        filepath=str(DATA / "ligand_1.sdf"),
        net_charge=-1,
    )
    assert ligand.fileformat == "sdf"

def test_missing_file_raise():
    with pytest.raises(FileNotFoundError):
        Ligand(
            name="ligand",
            filepath="/nonexistent/file.pdb"
        )

def test_unsupported_format(tmp_path):
    file = tmp_path / "mol.mol2"
    file.write_text("dummy")
    with pytest.raises(NotImplementedError):
        Ligand(name="mol", filepath=str(file))
    
def test_directory_inferred():
    ligand = Ligand(
        name="ligand_1",
        filepath=str(DATA / "ligand_1.pdb"),
        net_charge=-1,
    )
    assert ligand.directory == str(DATA)

def test_openbabel_failure_raise(tmp_path):
    file = tmp_path / "lig.sdf"
    file.write_text("dummy")
    ligand = Ligand(name="lig", filepath=str(file))
    with patch("os.system"), patch("os.path.isfile", return_value=False):
        with pytest.raises(RuntimeError):
            ligand._run_obabel()

def test_parameterise_command(tmp_path):
    ligand = Ligand(
        name="ligand_1",
        filepath=str(DATA / "ligand_1.sdf"),
        net_charge=-1,
    )
    with patch("os.system") as mock_sys:
        ligand.parameterise()
    cmd = mock_sys.call_args[0][0]
    assert "-n -1" in cmd
    assert "-a gaff2" in cmd
