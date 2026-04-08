# Urban Crime Pattern Analysis and Prediction (Toronto)

This project implements an end-to-end R pipeline for:
- Data acquisition from local CSV
- API enrichment (Open-Meteo + authenticated OpenWeather call)
- Data cleaning and feature engineering
- EDA and visualizations
- Classification and clustering models
- Power BI-ready exports
- Docker reproducibility

## 1) Prerequisites

- R and RStudio installed
- Git installed
- Docker Desktop installed
- Power BI Desktop installed

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

## 6) Power BI (Beginner)

1. Open Power BI Desktop.
2. Get Data -> Text/CSV.
3. Load:
   - `outputs/powerbi/powerbi_features.csv`
   - `outputs/powerbi/powerbi_monthly_trends.csv`
   - `outputs/powerbi/powerbi_hotspots.csv`
4. Create slicers for `year`, `crime_type`, and `cluster`.
5. Add 2 R visuals:
   - Monthly trend chart
   - Cluster hotspot scatter chart

## 7) Docker Run

In PowerShell:

```powershell
docker compose build
docker compose up
```

## 8) GitHub (Minimum Requirement)

```powershell
git init
git checkout -b main
git checkout -b development
git add .
git commit -m "Initial project structure and pipeline scripts"
```

Create GitHub repository in browser, then:

```powershell
git remote add origin <your_repo_url>
git push -u origin main
git checkout development
git push -u origin development
```

Make at least 10 meaningful commits while improving each stage.
