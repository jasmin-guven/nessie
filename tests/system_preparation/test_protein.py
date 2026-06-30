import pytest
from pathlib import Path
from unittest.mock import patch
from nessie.system_preparation.protein import Protein

DATA = Path(__file__).parent.parent / "data" / "protein"

def test_load_single_pdb():
    protein = Protein(
        filepath=str(DATA / "kpc2.prepared.pdb"),
    )
    assert isinstance(protein.filepath, list)
    assert len(protein.filepath) == 1
    assert protein.filepath[0] == str(DATA / "kpc2.prepared.pdb")

def test_load_topology_and_structure_load(tmp_path):
    topology = tmp_path / "topology.top"
    topology.write_text("dummy")
    protein = Protein(
        filepath=[str(DATA / "kpc2.prepared.pdb"),
                  str(topology)],
    )
    assert isinstance(protein.filepath, list)
    assert len(protein.filepath) == 2
    assert protein.filepath[0] == str(DATA / "kpc2.prepared.pdb")
    assert protein.filepath[1] == str(topology)


def test_too_many_files_raise():
    with pytest.raises(RuntimeError):
        Protein(
            filepath=[
                "/dummy/file1.pdb",
                "/dummy/file2.pdb",
                "/dummy/file3.pdb"
            ]
        )

def test_missing_topology():
    with pytest.raises(RuntimeError):
        Protein(
            filepath=[
                "/dummy/file1.pdb",
                "/dummy/file2.pdb"
            ]            
        )

def test_missing_structure():
    with pytest.raises(RuntimeError):
        Protein(
            filepath=[
                "/dummy/file1.top",
                "/dummy/file2.top"
            ]            
        )

def test_single_file_not_found():
    with pytest.raises(FileNotFoundError):
        Protein(
            filepath="/nonexistent/file.pdb"
        )

def test_topology_file_not_found():
    with pytest.raises(FileNotFoundError):
        Protein(
            filepath=[
                str(DATA / "kpc2.prepared.pdb"),
                "/nonexistent/topology.top"
                ]
        )

def test_directory_inferred():
    ligand = Protein(
        filepath=str(DATA / "kpc2.prepared.pdb"),
    )
    assert ligand.directory == str(DATA)

def test_pdb2gmx_failure_raise():
    protein = Protein(
        filepath=str(DATA / "kpc2.prepared.pdb"),
    )
    with patch("os.system") as mock_sys, patch("os.path.isfile", return_value=False):
        with pytest.raises(RuntimeError):
            protein.parameterise()
        mock_sys.assert_called_once()