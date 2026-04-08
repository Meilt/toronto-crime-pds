suppressPackageStartupMessages({
  library(tidyverse)
  library(cluster)
})

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/metrics", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

set.seed(42)

message("[1/7] Loading data...")
df <- readr::read_csv("data/processed/crime_features.csv", show_col_types = FALSE)

needed <- c("latitude", "longitude", "month", "day", "temp_mean", "precip_sum")
missing_cols <- setdiff(needed, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

message("[2/7] Building numeric matrix...")
x_df <- df %>%
  select(all_of(needed)) %>%
  mutate(across(everything(), ~ suppressWarnings(as.numeric(.x))))

# Impute NAs safely
for (col in names(x_df)) {
  med <- suppressWarnings(median(x_df[[col]], na.rm = TRUE))
  if (!is.finite(med)) med <- 0
  x_df[[col]][is.na(x_df[[col]])] <- med
}

# Replace any Inf/-Inf
x_df <- x_df %>%
  mutate(across(everything(), ~ ifelse(is.finite(.x), .x, 0)))

# Remove zero-variance columns before scaling (prevents NaN)
keep_cols <- names(x_df)[sapply(x_df, function(v) sd(v, na.rm = TRUE) > 0)]
if (length(keep_cols) < 2) {
  stop("Not enough varying numeric columns for clustering.")
}
x_df <- x_df %>% select(all_of(keep_cols))

# Scale and final cleanup
x <- scale(as.matrix(x_df))
x[!is.finite(x)] <- 0

if (nrow(x) < 10) stop("Too few rows for clustering.")
if (any(!is.finite(x))) stop("Non-finite values remain in clustering matrix.")

message("[3/7] Selecting k with silhouette...")
ks <- 2:8
max_k <- min(max(ks), nrow(x) - 1)
ks <- ks[ks <= max_k]
if (length(ks) == 0) stop("Dataset too small for k >= 2 clustering.")

# Optional speed control for large datasets (silhouette uses dist matrix)
sil_sample_size <- min(4000, nrow(x))
sil_idx <- sample(seq_len(nrow(x)), sil_sample_size)
x_sil <- x[sil_idx, , drop = FALSE]

sil_scores <- purrr::map_dbl(ks, function(k) {
  km <- kmeans(x_sil, centers = k, nstart = 20, iter.max = 100)
  ss <- silhouette(km$cluster, dist(x_sil))
  mean(ss[, 3], na.rm = TRUE)
})

best_k <- ks[which.max(sil_scores)]
message("[4/7] Best k selected: ", best_k)

message("[5/7] Training final k-means on full data...")
best_km <- kmeans(x, centers = best_k, nstart = 30, iter.max = 100)

clustered <- df %>% mutate(cluster = as.factor(best_km$cluster))
readr::write_csv(clustered, "data/processed/crime_clustered.csv")

message("[6/7] Writing metrics...")
sil_tbl <- tibble(k = ks, silhouette = sil_scores)
readr::write_csv(sil_tbl, "outputs/metrics/clustering_silhouette_by_k.csv")
readr::write_csv(
  tibble(metric = c("best_k", "best_silhouette"), value = c(best_k, max(sil_scores, na.rm = TRUE))),
  "outputs/metrics/clustering_metrics.csv"
)

message("[7/7] Saving plots...")
p1 <- sil_tbl %>%
  ggplot(aes(k, silhouette)) +
  geom_line() +
  geom_point() +
  labs(title = "Silhouette score by k", x = "k", y = "Silhouette")
ggsave("outputs/figures/07_silhouette_by_k.png", p1, width = 8, height = 5)

p2 <- clustered %>%
  ggplot(aes(longitude, latitude, color = cluster)) +
  geom_point(alpha = 0.35, size = 0.9) +
  labs(title = "Crime hotspots (k-means clusters)")
ggsave("outputs/figures/08_hotspot_clusters.png", p2, width = 9, height = 6)

message("05_model_clustering.R completed successfully.")