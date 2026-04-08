suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
})

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

crime <- readr::read_csv("data/raw/Major_Crime_Indicators.csv", show_col_types = FALSE)
weather <- readr::read_csv("data/processed/weather_daily.csv", show_col_types = FALSE)

names_lower <- tolower(names(crime))
pick_col <- function(patterns) {
  idx <- which(Reduce(`|`, lapply(patterns, function(p) grepl(p, names_lower))))
  if (length(idx) == 0) return(NA_character_)
  names(crime)[idx[1]]
}

date_col <- pick_col(c("date", "reported", "occurrence"))
type_col <- pick_col(c("mci", "offence", "crime", "category", "type"))
lat_col <- pick_col(c("^lat", "latitude"))
lon_col <- pick_col(c("^long", "longitude", "lon"))
loc_col <- pick_col(c("neigh", "hood", "division", "premise", "area"))

if (is.na(date_col) || is.na(type_col)) {
  stop("Could not detect required date/type columns.")
}

crime <- crime %>%
  mutate(
    event_date = suppressWarnings(as.Date(.data[[date_col]])),
    event_date = if_else(is.na(event_date), suppressWarnings(mdy(.data[[date_col]])), event_date),
    event_date = if_else(is.na(event_date), as.Date(suppressWarnings(ymd_hms(.data[[date_col]]))), event_date),
    crime_type = as.factor(as.character(.data[[type_col]])),
    latitude = if (!is.na(lat_col)) as.numeric(.data[[lat_col]]) else NA_real_,
    longitude = if (!is.na(lon_col)) as.numeric(.data[[lon_col]]) else NA_real_,
    location_area = if (!is.na(loc_col)) as.character(.data[[loc_col]]) else "Unknown"
  ) %>%
  filter(!is.na(event_date), !is.na(crime_type))

crime <- crime %>%
  mutate(
    year = year(event_date),
    month = month(event_date),
    day = day(event_date),
    day_of_week = wday(event_date, label = TRUE),
    season = case_when(
      month %in% c(12, 1, 2) ~ "Winter",
      month %in% c(3, 4, 5) ~ "Spring",
      month %in% c(6, 7, 8) ~ "Summer",
      TRUE ~ "Fall"
    )
  )

# Simple geospatial imputation using Toronto center if missing.
crime <- crime %>%
  mutate(
    latitude = if_else(is.na(latitude), 43.6532, latitude),
    longitude = if_else(is.na(longitude), -79.3832, longitude)
  )

weather <- weather %>% mutate(weather_date = as.Date(weather_date))
crime_enriched <- crime %>%
  left_join(weather, by = c("event_date" = "weather_date")) %>%
  mutate(
    temp_mean = if_else(is.na(temp_mean), median(temp_mean, na.rm = TRUE), temp_mean),
    precip_sum = if_else(is.na(precip_sum), 0, precip_sum)
  )

cleaned <- crime_enriched %>%
  select(event_date, crime_type, location_area, latitude, longitude, everything())

features <- crime_enriched %>%
  transmute(
    event_date,
    crime_type,
    location_area,
    latitude,
    longitude,
    year,
    month,
    day,
    day_of_week = as.factor(day_of_week),
    season = as.factor(season),
    temp_mean,
    precip_sum
  )

write_csv(cleaned, "data/processed/crime_cleaned.csv")
write_csv(features, "data/processed/crime_features.csv")

message("02_preprocess.R completed.")
