suppressPackageStartupMessages({
  library(tidyverse)
  library(randomForest)
})

dir.create("outputs/metrics", recursive = TRUE, showWarnings = FALSE)
set.seed(42)

message("[1/8] Loading data...")
df <- readr::read_csv("data/processed/crime_features.csv", show_col_types = FALSE)

required_cols <- c(
  "crime_type", "location_area", "day_of_week", "season",
  "latitude", "longitude", "year", "month", "day", "temp_mean", "precip_sum"
)

missing_required <- setdiff(required_cols, names(df))
if (length(missing_required) > 0) {
  stop("Missing required columns: ", paste(missing_required, collapse = ", "))
}

message("[2/8] Selecting and cleaning columns...")
features <- df %>%
  select(all_of(required_cols)) %>%
  mutate(
    crime_type = as.character(crime_type),
    location_area = as.character(location_area),
    day_of_week = as.character(day_of_week),
    season = as.character(season)
  )

# Numeric imputation
num_cols <- c("latitude", "longitude", "year", "month", "day", "temp_mean", "precip_sum")
for (col in num_cols) {
  med <- suppressWarnings(median(features[[col]], na.rm = TRUE))
  if (!is.finite(med)) med <- 0
  features[[col]][is.na(features[[col]])] <- med
}

# Categorical imputation
cat_cols <- c("crime_type", "location_area", "day_of_week", "season")
for (col in cat_cols) {
  features[[col]][is.na(features[[col]]) | features[[col]] == ""] <- "Unknown"
}

message("[3/8] Reducing classes for stable training...")
# Keep top 8 crime classes
top_types <- features %>%
  count(crime_type, sort = TRUE) %>%
  slice_head(n = 8) %>%
  pull(crime_type)

features <- features %>% filter(crime_type %in% top_types)

# Keep classes with at least 20 rows
valid_classes <- features %>%
  count(crime_type) %>%
  filter(n >= 20) %>%
  pull(crime_type)

features <- features %>% filter(crime_type %in% valid_classes)

n_classes <- dplyr::n_distinct(features$crime_type)
if (n_classes < 2) {
  stop("Not enough target classes after filtering (<2). Check preprocessing.")
}

# Reduce very high-cardinality location levels to speed model
top_locations <- features %>%
  count(location_area, sort = TRUE) %>%
  slice_head(n = 30) %>%
  pull(location_area)

features <- features %>%
  mutate(location_area = if_else(location_area %in% top_locations, location_area, "Other"))

features <- features %>%
  mutate(
    crime_type = factor(crime_type),
    location_area = factor(location_area),
    day_of_week = factor(day_of_week),
    season = factor(season)
  )

message("[4/8] Stratified train/test split...")
row_map <- features %>%
  mutate(row_id = row_number()) %>%
  group_by(crime_type) %>%
  summarise(ids = list(row_id), .groups = "drop")

train_ids <- purrr::map(row_map$ids, function(v) {
  n <- length(v)
  k <- max(1, floor(0.8 * n))
  sample(v, size = k)
}) %>% unlist(use.names = FALSE)

train <- features[train_ids, , drop = FALSE]
test  <- features[-train_ids, , drop = FALSE]

if (nrow(test) == 0) stop("Test set is empty.")
if (dplyr::n_distinct(train$crime_type) < 2) stop("Train set has <2 classes.")

message("[5/8] Aligning factor levels...")
for (col in c("location_area", "day_of_week", "season")) {
  test[[col]] <- factor(test[[col]], levels = levels(train[[col]]))
  mode_level <- names(sort(table(train[[col]]), decreasing = TRUE))[1]
  test[[col]][is.na(test[[col]])] <- mode_level
  test[[col]] <- factor(test[[col]], levels = levels(train[[col]]))
}

message("[6/8] Training random forest...")
fit <- randomForest(
  crime_type ~ latitude + longitude + year + month + day + temp_mean + precip_sum +
    day_of_week + season + location_area,
  data = train,
  ntree = 120   # reduced from 200 for faster stable runtime
)

message("[7/8] Predicting + evaluating...")
pred <- predict(fit, newdata = test)
cm <- table(Prediction = pred, Reference = test$crime_type)
acc <- sum(diag(cm)) / sum(cm)

classes <- union(rownames(cm), colnames(cm))
f1_by_class <- purrr::map_dbl(classes, function(cl) {
  tp <- if (cl %in% rownames(cm) && cl %in% colnames(cm)) cm[cl, cl] else 0
  fp <- if (cl %in% rownames(cm)) sum(cm[cl, ]) - tp else 0
  fn <- if (cl %in% colnames(cm)) sum(cm[, cl]) - tp else 0
  precision <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
  recall <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
  if (is.na(precision) || is.na(recall) || (precision + recall) == 0) return(NA_real_)
  2 * precision * recall / (precision + recall)
})

f1 <- mean(f1_by_class, na.rm = TRUE)

metrics <- tibble(
  metric = c("accuracy", "macro_f1", "n_train", "n_test", "n_classes"),
  value = c(acc, f1, nrow(train), nrow(test), n_classes)
)

message("[8/8] Saving outputs...")
write_csv(metrics, "outputs/metrics/classification_metrics.csv")
as.data.frame(cm) %>% write_csv("outputs/metrics/classification_confusion_matrix.csv")
saveRDS(fit, "outputs/metrics/classification_model.rds")

message("04_model_classification.R completed successfully.")