from fastapi import FastAPI, HTTPException
import pandas as pd
from pathlib import Path

app = FastAPI(title="PDS Crime Logic Layer")

BASE = Path(__file__).resolve().parents[1]
PBI_DIR = BASE / "outputs" / "powerbi"

def load_csv(name: str) -> pd.DataFrame:
    p = PBI_DIR / name
    if not p.exists():
        raise HTTPException(status_code=404, detail=f"{name} not found. Run R pipeline first.")
    return pd.read_csv(p)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/features")
def features():
    df = load_csv("powerbi_features.csv")
    return df.to_dict(orient="records")

@app.get("/monthly")
def monthly():
    df = load_csv("powerbi_monthly_trends.csv")
    return df.to_dict(orient="records")

@app.get("/hotspots")
def hotspots():
    df = load_csv("powerbi_hotspots.csv")
    return df.to_dict(orient="records")

@app.get("/cluster_points")
def cluster_points():
    df = load_csv("powerbi_cluster_points.csv")
    return df.to_dict(orient="records")