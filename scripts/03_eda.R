suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(corrplot)
})

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/metrics", recursive = TRUE, showWarnings = FALSE)

df <- readr::read_csv("data/processed/crime_features.csv", show_col_types = FALSE)

summary_tbl <- df %>%
  summarise(
    total_records = n(),
    unique_crime_types = n_distinct(crime_type),
    date_min = min(event_date, na.rm = TRUE),
    date_max = max(event_date, na.rm = TRUE),
    mean_temp = mean(temp_mean, na.rm = TRUE),
    mean_precip = mean(precip_sum, na.rm = TRUE)
  )
write_csv(summary_tbl, "outputs/metrics/eda_summary.csv")

p1 <- df %>%
  count(year) %>%
  ggplot(aes(year, n)) +
  geom_line() +
  geom_point() +
  labs(title = "Crime count by year", x = "Year", y = "Count")
ggsave("outputs/figures/01_crime_by_year.png", p1, width = 9, height = 5)

p2 <- df %>%
  count(month) %>%
  ggplot(aes(month, n)) +
  geom_col() +
  labs(title = "Crime count by month", x = "Month", y = "Count")
ggsave("outputs/figures/02_crime_by_month.png", p2, width = 9, height = 5)

p3 <- df %>%
  count(crime_type, sort = TRUE) %>%
  slice_head(n = 10) %>%
  ggplot(aes(reorder(crime_type, n), n)) +
  geom_col() +
  coord_flip() +
  labs(title = "Top 10 crime types", x = "Crime type", y = "Count")
ggsave("outputs/figures/03_top_crime_types.png", p3, width = 9, height = 6)

p4 <- ggplot(df, aes(longitude, latitude)) +
  geom_bin2d(bins = 50) +
  labs(title = "Spatial density of crime points")
ggsave("outputs/figures/04_spatial_density.png", p4, width = 9, height = 6)

p5 <- df %>%
  count(day_of_week) %>%
  ggplot(aes(day_of_week, n)) +
  geom_col() +
  labs(title = "Crime by day of week", x = "Day", y = "Count")
ggsave("outputs/figures/05_crime_dayofweek.png", p5, width = 9, height = 5)

num_df <- df %>% select(latitude, longitude, year, month, day, temp_mean, precip_sum)
cm <- cor(num_df, use = "pairwise.complete.obs")
png("outputs/figures/06_correlation_matrix.png", width = 900, height = 700)
corrplot(cm, method = "color", type = "upper", tl.cex = 0.8)
dev.off()

message("03_eda.R completed.")
