# Urban Crime Pattern Analysis and Prediction (Toronto)

This project implements an end-to-end R pipeline for:
- Data acquisition from local CSV
- API enrichment (Open-Meteo + authenticated OpenWeather call)
- Data cleaning and feature engineering
- EDA and visualizations
- Classification and clustering models
- Power BI integration via a **Python Web API** (no manual CSV import in Desktop)
- Docker reproducibility

- Docker reproducibility

## 1) Prerequisites

- R and RStudio installed
- Git installed
- Docker Desktop installed
- Power BI Desktop installed
- **Python 3** and `pip` (for the Power BI logic layer)

## 2) Project Setup (Windows)

Open PowerShell in this folder:

`c:\Users\meilita\Downloads\PDS\PDS_Proj`

Create `.env`:

```env
OPENWEATHER_API_KEY=your_real_openweather_key
```

Put dataset file here:

`data/raw/Major_Crime_Indicators.csv`

If your file is still at `../data/raw/`, script `01_acquire.R` will copy it automatically.

## 3) Install R Packages (one time)

Run in RStudio console:

```r
install.packages(c(
  "tidyverse","lubridate","httr","jsonlite","dotenv",
  "randomForest","cluster","corrplot"
))
```

## 4) Run Full Pipeline (Local)

Run these commands in PowerShell (inside project folder):

```powershell
Rscript scripts/01_acquire.R
Rscript scripts/02_preprocess.R
Rscript scripts/03_eda.R
Rscript scripts/04_model_classification.R
Rscript scripts/05_model_clustering.R
Rscript scripts/06_export_powerbi.R
```

## 5) Output Files

- Processed data:
  - `data/processed/crime_cleaned.csv`
  - `data/processed/crime_features.csv`
  - `data/processed/crime_clustered.csv`
- Figures:
  - `outputs/figures/*.png`
- Metrics:
  - `outputs/metrics/*.csv`
- Power BI export tables:
  - `outputs/powerbi/*.csv`

## 6) Power BI via Web API (logic layer)

Power BI Desktop connects to a **local HTTP API** that reads the CSV files produced by `06_export_powerbi.R`. You do **not** use Get Data → Text/CSV for the main workflow (avoids manual file upload each time). After you refresh data in R, start the API and click **Refresh** in Power BI.

### 6.1 Install Python packages (one time)

In PowerShell (from the project folder):

```powershell
pip install fastapi uvicorn pandas
```

### 6.2 Generate Power BI tables (R)
```
Rscript scripts/01_acquire.R
Rscript scripts/02_preprocess.R
Rscript scripts/03_eda.R
Rscript scripts/04_model_classification.R
Rscript scripts/05_model_clustering.R
Rscript scripts/06_export_powerbi.R
```
Or use the orchestrator (if you use it):
```
python logic_layer/run_pipeline.py
```
### 6.3 Start the API (local)
From project root:
```
uvicorn logic_layer.app:app --host 127.0.0.1 --port 8000
```
Verify in a browser:
```
http://127.0.0.1:8000/health
http://127.0.0.1:8000/monthly (JSON array of rows)
```
Keep this terminal open while working in Power BI Desktop.


### 6.5 Connect Power BI Desktop (no login)

1. Open Power BI Desktop. 

2. If sign-in appears, choose Skip / work offline.

3. Home → Get data → Web.

Add each data source (repeat for each table):
Table in Power BI	Local URL	Ngrok URL (example)
features	http://127.0.0.1:8000/features	https://YOUR-NGROK-URL/features
monthly	http://127.0.0.1:8000/monthly	https://YOUR-NGROK-URL/monthly
hotspots	http://127.0.0.1:8000/hotspots	https://YOUR-NGROK-URL/hotspots
cluster_points	http://127.0.0.1:8000/cluster_points	https://YOUR-NGROK-URL/cluster_points

4. Power Query may show a List or single Record. Convert to a table:
- Transform → To Table (if needed)
- Expand columns so you see fields like year, month, crime_type, crime_count, cluster, longitude, latitude, etc.
5. Set column types (Transform → Detect Data Type or set Decimal for lat/lon, Whole number for counts where appropriate).
5. Close & Apply.
Refresh: Home → Refresh (re-runs R + restart API if files changed).


## 7) Docker Run

In PowerShell:

```powershell
docker compose build
docker compose up
```
