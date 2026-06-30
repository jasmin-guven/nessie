from nessie.pipeline import Pipeline
from pathlib import Path

DATA_PATH = Path(__file__).parent / "data" / "protein_ligand_mutation" 

if __name__ == "__main__":

    protein_ligand_pipeline = Pipeline(
        project_directory=str(DATA_PATH),
        ligand_path=str(DATA_PATH / "ligands"),
        protein_path=str(DATA_PATH / "protein")
    )

    protein_ligand_pipeline.prepare_ligands(
        net_charge=-1,
        atom_type="gaff2",
        ligand_file_search_pattern="*.pdb"
    )