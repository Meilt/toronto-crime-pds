import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]

scripts = [
    "scripts/01_acquire.R",
    "scripts/02_preprocess.R",
    "scripts/03_eda.R",
    "scripts/04_model_classification.R",
    "scripts/05_model_clustering.R",
    "scripts/06_export_powerbi.R",
]

for s in scripts:
    print(f"Running {s} ...")
    subprocess.run(["Rscript", s], cwd=str(BASE), check=True)

print("Pipeline completed.")