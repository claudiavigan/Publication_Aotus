# ============================================================================
#  04_night_activity.R
# ----------------------------------------------------------------------------
# Purpose:
#   - Read dataset of independent detections (Aotus) with reclassified behavior
#   - Compute POSIX time fields and circular time (radians)
#   - Estimate nocturnal activity pattern using overlap (Ridout & Linkie, 2009)
#   - Plot night activity density with daytime shaded
#   - Save time-processed data and plot
#
# How to run:
#   - Set working directory to the project root:
#       Aotus_arboreal_camera_traps/
#   - Run:
#       source("R/04_night_activity.R")
#
# Dependencies:
#   - dplyr, lubridate, overlap
# ============================================================================

# 0. Packages ----------------------------------------------------------------
required_pkgs <- c("dplyr", "lubridate", "overlap")

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required but not installed.", call. = FALSE)
  }
}

library(dplyr)      # data manipulation
library(lubridate)  # date-time parsing and arithmetic
library(overlap)    # activity density estimation

# 1. Paths -------------------------------------------------------------------
# All paths are relative to the project root
clean_dir   <- file.path("data", "processed")
figures_dir <- file.path("output", "figures")
logs_dir    <- file.path("output", "logs")

if (!dir.exists(clean_dir))   dir.create(clean_dir,   recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)
if (!dir.exists(logs_dir))    dir.create(logs_dir,    recursive = TRUE)

# Input: reclassified detections (from 03_behavior.R)
data_file_in  <- file.path(clean_dir, "Aotus_Ind_Det_reclassified_02.csv")
# Output: time-processed detections
data_file_out <- file.path(clean_dir, "Aotus_Ind_Det_timeprocessed_03.csv")
# Output: activity pattern figure
fig_file_out  <- file.path(figures_dir, "Figure_3_night_activity_overlap.png")

# 2. Load independent detections with reclassified behaviors ----------------
aot_reclass <- read.csv(data_file_in, stringsAsFactors = FALSE)
str(aot_reclass)

if (!("DateTime" %in% names(aot_reclass))) {
  stop("Input file must contain a 'DateTime' column.")
}

# 3. Compute POSIX and correct problematic records --------------------------
aot_time <- aot_reclass %>%
  mutate(
    DateTime     = ymd_hms(DateTime),
    Hour         = hour(DateTime),
    Minute       = minute(DateTime),
    Time_numeric = Hour + Minute / 60,
    Time_radians = (Time_numeric / 24) * 2 * pi
  ) %>%
  mutate(
    DateTime = if_else(Hour > 6 & Hour < 18,
                       DateTime + hours(7),
                       DateTime),
    Hour         = hour(DateTime),
    Minute       = minute(DateTime),
    Time_numeric = Hour + Minute / 60,
    Time_radians = (Time_numeric / 24) * 2 * pi
  )

# Save cleaned time dataset --------------------------------------------------
write.csv(aot_time, data_file_out, row.names = FALSE)
cat("Saved time-corrected data to", data_file_out, "\n")

# 4. Night activity density plot using overlap -------------------------------
times_rad <- aot_time$Time_radians

# Bandwidth (for info)
bw <- overlap::getBandWidth(times_rad, kmax = 4)
cat("overlap bandwidth (k) =", bw, "\n")

# ---- 4a. Plot directly to RStudio preview ---------------------------------
par(mar = c(5, 6, 1.5, 2), cex.lab = 1.4, mgp = c(3, 1, 0))

dens_df <- overlap::densityPlot(
  A        = times_rad,
  xscale   = 24,
  xcenter  = "midnight",
  add      = FALSE,
  rug      = TRUE,
  extend   = NULL,
  n.grid   = 512,
  adjust   = 1,
  xlab     = "Time (hours)",
  ylab     = "Density of detections",
  main     = ""          # no title
)

# Shade daytime regions (left & right), keep night (center) white -----------
usr       <- par("usr")
shade_col <- rgb(0, 0, 0, alpha = 0.1)

# Daytime approx: -12 to -6 and 6.5 to 12 (on x-scale already in hours)
rect(usr[1], usr[3], -6,   usr[4], col = shade_col, border = NA)  # left day
rect( 6.5,   usr[3], usr[2], usr[4], col = shade_col, border = NA)  # right day

# Redraw the density line on top of shading
lines(dens_df, lwd = 1.4, col = "black")

# ---- 4b. Save the same plot as PNG ----------------------------------------
png(
  filename = fig_file_out,
  width    = 17.8,
  height   = 12.5,
  units    = "cm",
  res      = 600
)

par(mar = c(5, 6, 1.5, 2), cex.lab = 1.4, mgp = c(3, 1, 0))

dens_df <- overlap::densityPlot(
  A        = times_rad,
  xscale   = 24,
  xcenter  = "midnight",
  add      = FALSE,
  rug      = TRUE,
  extend   = NULL,
  n.grid   = 512,
  adjust   = 1,
  xlab     = "Time (hours)",
  ylab     = "Density of detections",
  main     = ""
)

usr       <- par("usr")
shade_col <- rgb(0, 0, 0, alpha = 0.1)
rect(usr[1], usr[3], -6,   usr[4], col = shade_col, border = NA)
rect( 6.5,   usr[3], usr[2], usr[4], col = shade_col, border = NA)
lines(dens_df, lwd = 1.4, col = "black")

dev.off()
cat("Saved night activity density plot to", fig_file_out, "\n")

# 5. Record session info for reproducibility --------------------------------
sink(file.path(logs_dir, "sessionInfo_night_activity.txt"))
sessionInfo()
sink()
