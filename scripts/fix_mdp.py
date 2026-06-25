import os
import glob
import sys
import shutil


ligand_1_name=sys.argv[1]
ligand_2_name=sys.argv[2]
repeat = sys.argv[3]


project_directory = "/Users/af25016/projects/kpc2-neq-fep-dnemd/"

transformation_directory = os.path.join(
    project_directory, 
    "outputs", 
    f"repeat_{repeat}",
    f"{ligand_1_name}~{ligand_2_name}"
)

steps = ["min", "nvt", "npt", ""]
stages = ["unbound", "bound"]

for step in steps:
    for stage in stages:

        stage_dir = os.path.join(
            transformation_directory,
            stage
        )

        step_dir = os.path.join(
            stage_dir, 
            step
        )

        lambda_directories = sorted(glob.glob(f"{step_dir}/lambda_*"))
        if len(lambda_directories) == 0:
            continue
        for dir in lambda_directories:
            if "lambda_0.5000" in dir:
                shutil.rmtree(dir)
                print(f"Removed directory: {dir}") 
                continue
            print(dir)
            mdp_file = os.path.join(dir, "gromacs.mdp")
            mdp = {}
            with open(mdp_file, "r") as ifile:
                for line in ifile:
                    (key, value) = line.split("=")
                    mdp[key.strip()] = value.strip()
            
            mdp.update({
                "nstlist": 20,
                "rlist": 1.2,
                "rvdw": 1.2,
                "rcoulomb": 1.2
            }
            )

            if step == "min":
                mdp["emtol"] = 1000

            elif step == "nvt":
                mdp["ref-t"] = 300.0
                mdp["gen-temp"] = 300.0
                mdp["tcoupl"] = "v-rescale"
                mdp["tc-grps"] = "system"

            elif step == "npt" or step == "":
                mdp["ref-t"] = 300.0
                mdp["gen-vel"] = "no"
                mdp["gen-temp"] = 300.0
                mdp["continuation"] = "yes"
                mdp["tcoupl"] = "v-rescale"
                mdp["tc-grps"] = "system"


            if step == "":
                mdp["nstlog"] = 10000
                mdp["nstenergy"] = 10000
                mdp["nstxout-compressed"] = 10000
                mdp["nstcalcenergy"] = 10000
                mdp["nstdhdl"] = 10000
                mdp["nstcheckpoint"] = 10000
            elif step == "npt" or step == "nvt":
                mdp["nstlog"] = 500
                mdp["nstenergy"] = 500
                mdp["nstxout-compressed"] = 500
                mdp["nstcalcenergy"] = 500
                mdp["nstdhdl"] = 500
                mdp["nstcheckpoint"] = 500
            
            if "init-lambda-state" in mdp.keys():
                del mdp["init-lambda-state"]
            if "fep-lambdas" in mdp.keys():
                del mdp["fep-lambdas"]

            if "calc-lambda-neighbors" in mdp.keys():
                del mdp["calc-lambda-neighbors"]

            if "lambda_0.0000" in dir:
                mdp["init-lambda"] = 0
            elif "lambda_1.0000" in dir:
                mdp["init-lambda"] = 1

            lines = [f"{key} = {value}\n" for key, value in mdp.items()]

            with open(mdp_file, "w") as ofile:
                ofile.writelines(lines)

