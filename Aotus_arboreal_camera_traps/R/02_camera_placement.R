# ============================================================================
#  02_camera_placement.R
# ----------------------------------------------------------------------------
# Purpose:
#   - Compute camera-trap nights (CTNs) per deployment
#   - Create a supplementary table with CTNs and total days of deployment
#       -> output/tables/CameraTrapDays_CTNs.csv
#   - Produce a figure of camera recording periods by tree
#       -> output/figures/Fig_camera_recording_periods.png
#   - Record sessionInfo() for reproducibility
#       -> output/logs/sessionInfo_camera_placement.txt
#
# How to run:
#   - Open an R session with the working directory set to the project root:
#       Aotus_arboreal_camera_traps/
#   - Run:
#       source("R/02_camera_placement.R")
#
# Dependencies:
#   - ggplot2    (plotting)
#   - dplyr      (data manipulation)
#   - lubridate  (date handling)
#   - viridis    (color palettes)
# ============================================================================

# 0. Packages ----------------------------------------------------------------
required_pkgs <- c("ggplot2", "dplyr", "lubridate", "viridis")

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required but not installed.", call. = FALSE)
  }
}

library(ggplot2)
library(dplyr)
library(lubridate)
library(viridis)

# 1. Paths -------------------------------------------------------------------
# All paths are relative to the project root
data_file   <- file.path("data", "raw", "CameraTrapDates.csv")

tables_dir  <- file.path("output", "tables")
figures_dir <- file.path("output", "figures")
logs_dir    <- file.path("output", "logs")

if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)
if (!dir.exists(logs_dir))    dir.create(logs_dir,    recursive = TRUE)

# 2. Read summarised camera dates -------------------------------------------
cam_dates <- read.csv(data_file, stringsAsFactors = FALSE) %>%
  mutate(
    StartDate = as.Date(StartDate),
    EndDate   = as.Date(EndDate)
  )

# 3. CTNs per deployment ----------------------------------------------------
# CTNs = EndDate - StartDate + 1 (inclusive of both start and end days)
cam_dates_CTN <- cam_dates %>%
  mutate(
    CTNs = as.numeric(EndDate - StartDate + 1)
  )

total_CTNs <- sum(cam_dates_CTN$CTNs, na.rm = TRUE)
cat("Total CTNs from deployment intervals (sum of CTNs):", total_CTNs, "\n")
cat("Deployment-level table with CTNs:\n")
print(cam_dates_CTN)

# 4. Build supplementary table with summary row -----------------------------
# Total number of days from first to last deployment
total_days <- as.numeric(
  max(cam_dates_CTN$EndDate, na.rm = TRUE) -
    min(cam_dates_CTN$StartDate, na.rm = TRUE) + 1
)

# Summary row for supplementary table
summary_row <- data.frame(
  CameraID  = "Total number of days",
  TreeID    = NA_character_,
  StartDate = as.character(total_days),  # e.g. "478"
  EndDate   = NA_character_,
  CTNs      = total_CTNs,                # e.g. 2183
  stringsAsFactors = FALSE
)

# Convert dates to character for a clean, human-readable table
cam_dates_table_FINAL <- cam_dates_CTN %>%
  mutate(
    StartDate = as.character(StartDate),
    EndDate   = as.character(EndDate)
  ) %>%
  bind_rows(summary_row)

cat("Final supplementary table (with summary row):\n")
print(cam_dates_table_FINAL)

# Export supplementary table
write.csv(
  cam_dates_table_FINAL,
  file = file.path(tables_dir, "CameraTrapDays_CTNs.csv"),
  row.names = FALSE
)

# 5. Total nights from first to last deployment -----------------------------
all_start <- min(cam_dates$StartDate, na.rm = TRUE)
all_end   <- max(cam_dates$EndDate,   na.rm = TRUE)
total_nights <- as.numeric(all_end - all_start + 1)

cat(sprintf("Total nights from %s to %s: %d\n",
            all_start, all_end, total_nights))
# Should match `total_days` above (e.g. 478)

# 6. Data for plotting (no duplicate date columns) --------------------------
cam_dates_plot <- cam_dates %>%
  mutate(
    Start = as.POSIXct(StartDate),
    End   = as.POSIXct(EndDate)
    # If you prefer full-day coverage for End:
    # End = as.POSIXct(EndDate) + days(1) - seconds(1)
  )

# Axis range and monthly ticks
t_start       <- as.POSIXct(all_start)
t_end         <- as.POSIXct(all_end)
t_start_month <- floor_date(t_start, unit = "month")
t_end_month   <- ceiling_date(t_end, unit = "month")

monthly_ticks <- seq(from = t_start_month, to = t_end_month, by = "1 month")

# Color mapping by TreeID
tree_ids <- sort(unique(cam_dates_plot$TreeID))
colors   <- setNames(viridis(length(tree_ids)), tree_ids)

# Optional shaded period (e.g. period of interest)
shade_start <- as.POSIXct("2023-11-14 00:00:00")
shade_end   <- as.POSIXct("2024-11-26 23:59:59")

# 7. Plot camera recording periods ------------------------------------------
Campertree <- ggplot() +
  geom_rect(aes(xmin = shade_start, xmax = shade_end, ymin = -Inf, ymax = Inf),
            fill = "grey80", alpha = 0.5) +
  geom_errorbarh(
    data  = cam_dates_plot,
    aes(y = CameraID, xmin = Start, xmax = End, color = TreeID),
    height = 0.4,
    size   = 1.2,
    alpha  = 0.8
  ) +
  scale_color_manual(values = colors) +
  scale_x_datetime(
    breaks = monthly_ticks,
    labels = format(monthly_ticks, "%b %Y"),
    limits = c(t_start_month, t_end_month)
  ) +
  geom_vline(xintercept = as.numeric(monthly_ticks),
             linetype = "dashed",
             color    = "gray50",
             size     = 0.3) +
  labs(
    title = "Camera recording periods by tree",
    x     = "Time",
    y     = "Camera ID",
    color = "Tree ID"
  ) +
  theme_minimal() +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    panel.background = element_rect(fill = "white"),
    plot.background  = element_rect(fill = "white")
  )

print(Campertree)

# Save figure to output/figures/
ggsave(
  filename = file.path(figures_dir, "Fig_camera_recording_periods.png"),
  plot     = Campertree,
  width    = 8,
  height   = 5,
  dpi      = 300
)

# 8. Record session info for reproducibility ---------------------
sink(file.path(logs_dir, "sessionInfo_camera_placement.txt"))
sessionInfo()
sink()
