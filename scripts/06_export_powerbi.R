suppressPackageStartupMessages({
  library(tidyverse)
})

dir.create("outputs/powerbi", recursive = TRUE, showWarnings = FALSE)

features <- readr::read_csv("data/processed/crime_features.csv", show_col_types = FALSE)
clusters <- readr::read_csv("data/processed/crime_clustered.csv", show_col_types = FALSE)

# Existing exports
monthly <- features %>%
  count(year, month, crime_type, name = "crime_count")

hotspots <- clusters %>%
  count(cluster, location_area, name = "cluster_count")

# NEW: point-level cluster table for scatter/R visual
cluster_points <- clusters %>%
  select(longitude, latitude, cluster, crime_type, location_area, year, month) %>%
  filter(!is.na(longitude), !is.na(latitude), !is.na(cluster))

write_csv(features, "outputs/powerbi/powerbi_features.csv")
write_csv(monthly, "outputs/powerbi/powerbi_monthly_trends.csv")
write_csv(hotspots, "outputs/powerbi/powerbi_hotspots.csv")
write_csv(cluster_points, "outputs/powerbi/powerbi_cluster_points.csv")

message("06_export_powerbi.R completed.")