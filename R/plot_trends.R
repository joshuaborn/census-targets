# Reads the published census_targets.csv / census_targets_adults.csv
# and writes trend-line PNGs to R/plots/.
#
# Every plot below filters to exactly one RaceScheme before summing Population.
# race2/race3/race4/race6 rows all describe the SAME underlying population at
# different levels of race detail, so summing Population across rows that mix
# RaceScheme values would count real people more than once.
#
# Every plot that collapses across HispanicOrigin sums over it rather than
# filtering one value out. From 1980 on, a cell has two rows (Hispanic and
# NonHispanic) that together equal the cell's total; before 1980, a cell already
# has exactly one row (HispanicOrigin = NA). Summing across HispanicOrigin gives
# the correct total either way, with no double-count and no dropped years.

library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(here)

plots_dir <- here("R", "plots")
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)

by_age <- read_csv(here("output", "census_targets.csv"), show_col_types = FALSE)
adults_by_age <- read_csv(here("output", "census_targets_adults.csv"), show_col_types = FALSE)

age_group_order <- c(
  "Under 5", "5 to 9", "10 to 14", "15 to 19", "20 to 24", "25 to 29",
  "30 to 34", "35 to 39", "40 to 44", "45 to 49", "50 to 54", "55 to 59",
  "60 to 64", "65 to 69", "70 to 74", "75 to 79", "80 to 84",
  "85 years and over", "75 years and over"
)

theme_set(theme_minimal())

save_trend_plot <- function(plot, filename) {
  ggsave(file.path(plots_dir, filename), plot, width = 8, height = 5, dpi = 150)
}

# 1. Total US resident population, all ages, 1900-2025.
trend_total_allages <- by_age |>
  filter(RaceScheme == "race2") |>
  group_by(Year) |>
  summarize(Population = sum(Population), .groups = "drop")

save_trend_plot(
  ggplot(trend_total_allages, aes(x = Year, y = Population)) +
    geom_line() +
    geom_point(size = 0.5) +
    scale_y_continuous(labels = comma) +
    labs(title = "Total U.S. Resident Population, 1900-2025", y = "Population (all ages)"),
  "trend_total_allages.png"
)

# 2. Total US resident population, ages 18+, 1900-2025.
trend_total_adults <- adults_by_age |>
  filter(RaceScheme == "race2") |>
  group_by(Year) |>
  summarize(Population = sum(Population), .groups = "drop")

save_trend_plot(
  ggplot(trend_total_adults, aes(x = Year, y = Population)) +
    geom_line() +
    geom_point(size = 0.5) +
    scale_y_continuous(labels = comma) +
    labs(title = "Total U.S. Adult (18+) Resident Population, 1900-2025", y = "Population (ages 18+)"),
  "trend_total_adults.png"
)

# 3. By Sex, all ages, 1900-2025.
trend_by_sex <- by_age |>
  filter(RaceScheme == "race2") |>
  group_by(Year, Sex) |>
  summarize(Population = sum(Population), .groups = "drop")

save_trend_plot(
  ggplot(trend_by_sex, aes(x = Year, y = Population, color = Sex)) +
    geom_line() +
    geom_point(size = 0.5) +
    scale_y_continuous(labels = comma) +
    labs(title = "U.S. Resident Population by Sex, 1900-2025", y = "Population (all ages)"),
  "trend_by_sex.png"
)

# 4-7. By Race, one plot per RaceScheme. The four schemes' Race levels aren't
# comparable on one legend, so each gets its own plot rather than one combined
# plot with an inconsistent set of categories across years.
plot_by_race <- function(scheme, title) {
  trend <- by_age |>
    filter(RaceScheme == scheme) |>
    group_by(Year, Race) |>
    summarize(Population = sum(Population), .groups = "drop")

  save_trend_plot(
    ggplot(trend, aes(x = Year, y = Population, color = Race)) +
      geom_line() +
      geom_point(size = 0.5) +
      scale_y_continuous(labels = comma) +
      labs(title = title, y = "Population (all ages)"),
    paste0("trend_by_race_", scheme, ".png")
  )
}

plot_by_race("race2", "U.S. Resident Population by Race (2-category scheme), 1900-2025")
plot_by_race("race3", "U.S. Resident Population by Race (3-category scheme), 1960-2025")
plot_by_race("race4", "U.S. Resident Population by Race (4-category scheme), 1980-1999")
plot_by_race("race6", "U.S. Resident Population by Race (6-category scheme), 2000-2025")

# 8. By Hispanic origin, 1980-2025 (the only years HispanicOrigin is populated).
trend_by_hispanic <- by_age |>
  filter(RaceScheme == "race2", !is.na(HispanicOrigin)) |>
  group_by(Year, HispanicOrigin) |>
  summarize(Population = sum(Population), .groups = "drop")

save_trend_plot(
  ggplot(trend_by_hispanic, aes(x = Year, y = Population, color = HispanicOrigin)) +
    geom_line() +
    geom_point(size = 0.5) +
    scale_y_continuous(labels = comma) +
    labs(title = "U.S. Resident Population by Hispanic Origin, 1980-2025", y = "Population (all ages)"),
  "trend_by_hispanic.png"
)

# 9. By AgeGroup, all ages, 1900-2025.
trend_by_agegroup <- by_age |>
  filter(RaceScheme == "race2") |>
  group_by(Year, AgeGroup) |>
  summarize(Population = sum(Population), .groups = "drop") |>
  mutate(AgeGroup = factor(AgeGroup, levels = age_group_order))

save_trend_plot(
  ggplot(trend_by_agegroup, aes(x = Year, y = Population, color = AgeGroup)) +
    geom_line() +
    geom_point(size = 0.5) +
    scale_y_continuous(labels = comma) +
    labs(title = "U.S. Resident Population by Age Group, 1900-2025", y = "Population"),
  "trend_by_agegroup.png"
)

cat("Wrote 9 trend plots to", plots_dir, "\n")
