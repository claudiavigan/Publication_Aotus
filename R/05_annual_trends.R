# ============================================================================
#  05_annual_trend.R
# ----------------------------------------------------------------------------
# Purpose:
#   - Read Aotus independent detections timeprocessed, phenology, and climate data
#   - Aggregate datasets to monthly time series and phenology to tree x month time series
#   - Plot annual trends of Aotus detections, phenology, and precipitation
#   - Save derived datasets that form the basis for figure 2
#
# How to run:
#   - Set working directory to the project root:
#       Aotus_arboreal_camera_traps/
#   - Run:
#       source("R/05_annual_trend.R")
#
# Dependencies:
#   - dplyr, lubridate, readr, ggplot2, tidyr, patchwork
# ============================================================================

# 0. Packages ----------------------------------------------------------------
required_pkgs <- c("dplyr", "lubridate", "readr", "ggplot2", "tidyr", "patchwork")

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required but not installed.", call. = FALSE)
  }
}

library(dplyr)
library(lubridate)
library(readr)
library(ggplot2)
library(tidyr)
library(patchwork)

# 1. Paths -------------------------------------------------------------------
raw_dir       <- file.path("data", "raw")
processed_dir <- file.path("data", "processed")
figures_dir   <- file.path("output", "figures")
logs_dir      <- file.path("output", "logs")

if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)
if (!dir.exists(figures_dir))   dir.create(figures_dir,   recursive = TRUE)
if (!dir.exists(logs_dir))      dir.create(logs_dir,      recursive = TRUE)

# Input files
file_aot   <- file.path(processed_dir, "Aotus_Ind_Det_timeprocessed_03.csv")
file_pheno <- file.path(raw_dir,       "pheno.csv")
file_clim  <- file.path(raw_dir,       "CLIM_98-25.csv")

# 2. Load csvs ---------------------------------------------------------------
# a) independent detections with adjusted timestamps
aot <- read.csv(file_aot, stringsAsFactors = FALSE)

# b) phenology dataset
pheno <- read.csv(file_pheno, stringsAsFactors = FALSE)

# c) climate dataset
clim <- read.csv(file_clim, stringsAsFactors = FALSE)

# 3. Define period used in figure -------------------------------------------
from <- ymd("2023-08-01")
to   <- ymd("2024-11-30")

# --- phenology: YY/MM/DD in separate columns --------------------------------
pheno_date <- pheno %>%
  mutate(date = make_date(YY, MM, DD)) %>%
  filter((date >= from & date <= to) | date == as.Date("2023-07-30")) # For later adjustment of H11 inclusion for the month of August

# Save phenology with new date column
write_csv(
  pheno_date,
  file.path(processed_dir, "Pheno_date_jul23_nov24.csv")
)

# --- climate: timestamp "YYYY-mm-dd HH:MM:SS" --------------------------------
clim_date <- clim %>%
  mutate(datetime = ymd_hms(datetime, tz = "UTC"),
         date     = as_date(datetime)) %>%
  filter(date >= from, date <= to)

# Save climate with Date column
write_csv(
  clim_date,
  file.path(processed_dir, "Climate_date_aug23_nov24.csv")
)

# 4. Ensure date columns -----------------------------------------------------
pheno_date <- pheno_date %>% mutate(date = as_date(date))
clim_date  <- clim_date  %>% mutate(date = as_date(date))
aot        <- aot        %>% mutate(date = ymd(Date))

# 5. Monthly summaries -------------------------------------------------------

# 5.1 Monthly detections from aot (exclude Empty)
det_mo <- aot %>%
  filter(!Empty, date >= from, date <= to) %>%
  mutate(month = floor_date(date, "month")) %>%
  count(month, name = "detections")

# 5.2a Monthly phenology (mean class value per month)
#      FB = Flower buds, OF = Open flowers
monitored_trees <- sort(unique(aot$TreeID))

ph_mo <- pheno_date %>%
  filter(date >= from, date <= to, ID %in% monitored_trees) %>%
  mutate(month = floor_date(date, "month")) %>%
  summarise(
    flower_buds  = mean(FB, na.rm = TRUE),
    open_flowers = mean(OF, na.rm = TRUE),
    .by = month
  )

# 5.2b Tree × month phenology (mean class value per tree per month)
#      FB = Flower buds, OF = Open flowers
from2 <- ymd("2023-07-30")

ph_tm <- pheno_date %>%
  filter(
    date >= from2,
    date <= to,  # keep the July record to later include H11
    ID %in% monitored_trees
  ) %>%
  mutate(
    month = floor_date(date, "month"),
    
    # move the specific survey of H11 from 30 July to August
    month = if_else(
      ID == "H11" & date == as.Date("2023-07-30"),
      as.Date("2023-08-01"),
      month
    )
  ) %>%
  summarise(
    flower_buds  = mean(FB, na.rm = TRUE),
    open_flowers = mean(OF, na.rm = TRUE),
    n_surveys    = dplyr::n(),
    .by = c(ID, month)
  ) %>%
  rename(TreeID = ID)

str(ph_tm)

# 5.3 Monthly precipitation (sum of interval PCP)
prcp_mo <- clim_date %>%
  filter(date >= from, date <= to) %>%
  mutate(month = floor_date(date, "month")) %>%
  summarise(
    precip_mm = sum(PCP, na.rm = TRUE),
    .by       = month
  )

# Save monthly summaries (derived data) --------------------------------------
write_csv(det_mo, file.path(processed_dir, "Aotus_monthly_detections.csv"))
write_csv(ph_mo,  file.path(processed_dir, "Pheno_monthly_FB_OF.csv"))
write_csv(prcp_mo,file.path(processed_dir, "Climate_monthly_precipitation.csv"))
write_csv(ph_tm, file.path(processed_dir, "Pheno_tm_FB_OF.csv"))

# 6. Plot settings -----------------------------------------------------------
band_df <- tibble::tibble(
  xmin = as.Date("2024-01-01"),
  xmax = as.Date("2024-04-30"),
  ymin = -Inf, ymax = Inf
)

cols <- c(
  "Aotus"            = "#D55E00",  # muted reddish orange
  "Monthly rainfall" = "#0072B2",  # dark blue
  "Flower buds"      = "#009E73",  # teal/green
  "Open flowers"     = "#CCB974",  # ochre
  "Infant presence"  = "#BEBEBE"   # grey (reserved)
)

x_scale <- scale_x_date(
  limits      = c(as.Date("2023-08-01"), as.Date("2024-11-30")),
  date_breaks = "2 months",
  date_labels = "%b %Y",
  expand      = expansion(mult = c(0.01, 0.03))
)

base_theme <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x      = element_text(
      angle  = 0,
      hjust  = 0.5,
      vjust  = 1,
      margin = margin(t = 3)
    )
  )

# 7. Panels ------------------------------------------------------------------

# 7.1 Aotus detections
p1 <- ggplot(det_mo, aes(month, detections)) +
  geom_vline(data = band_df, aes(xintercept = xmin),
             linetype = "longdash", colour = "black",
             linewidth = 0.7, inherit.aes = FALSE) +
  geom_vline(data = band_df, aes(xintercept = xmax),
             linetype = "longdash", colour = "black",
             linewidth = 0.7, inherit.aes = FALSE) +
  geom_point(aes(colour = "Aotus"), size = 1) +
  geom_smooth(aes(colour = "Aotus"),
              se = FALSE, method = "gam",
              formula = y ~ s(x, bs = "cs"), linewidth = 0.8) +
  x_scale +
  labs(y = "Detections (n)", x = NULL) +
  base_theme +
  theme(
    axis.text.x   = element_blank(),
    axis.ticks.x  = element_blank(),
    legend.position   = "right",
    legend.spacing.y  = unit(0.1, "cm"),
    legend.key.height = unit(0.3, "cm")
  ) +
  scale_colour_manual(values = cols, breaks = names(cols), name = NULL)

# 7.2 Phenology
ph_long <- ph_mo %>%
  pivot_longer(-month, names_to = "series", values_to = "value") %>%
  mutate(series = dplyr::recode(series,
                         flower_buds  = "Flower buds",
                         open_flowers = "Open flowers"))

p2 <- ggplot(ph_long, aes(month, value, colour = series)) +
  geom_point(size = 1) +
  geom_smooth(se = FALSE, method = "gam",
              formula = y ~ s(x, bs = "cs"), linewidth = 0.8) +
  x_scale +
  labs(y = "Phenology (class)", x = NULL, colour = NULL) +
  base_theme +
  theme(
    axis.text.x  = element_blank(),
    axis.ticks.x = element_blank()
  ) +
  scale_colour_manual(values = cols, breaks = names(cols), name = NULL)

# 7.3 Precipitation
p3 <- ggplot(prcp_mo, aes(month, precip_mm)) +
  geom_point(aes(colour = "Monthly rainfall"), size = 1) +
  geom_smooth(aes(colour = "Monthly rainfall"),
              se = FALSE, method = "gam",
              formula = y ~ s(x, bs = "cs"), linewidth = 0.8) +
  x_scale +
  labs(y = "Rainfall (mm)", x = NULL) +
  base_theme +
  scale_colour_manual(values = cols, breaks = names(cols), name = NULL)

# Frame panels
p1 <- p1 + theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))
p2 <- p2 + theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))
p3 <- p3 + theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))

# 8. Combine panels ----------------------------------------------------------
final_plot <- (p1 / p2 / p3) +
  plot_annotation(
    title = "Annual pattern: Detections, Phenology & Precipitation",
    theme = theme(plot.title = element_text(face = "bold", size = 12, hjust = 0))
  ) &
  theme(legend.position = "none")

print(final_plot)

# Version without title/legend for export
fig_tripanel <- (p1 / p2 / p3) +
  plot_annotation(title = NULL) &
  theme(legend.position = "none")

# 9. Save figures ------------------------------------------------------------ 
ggsave(
  filename = file.path(figures_dir, "Figure_2.pdf"),
  plot     = fig_tripanel,
  width    = 168,
  height   = 210,
  units    = "mm",
  device   = "pdf"
)

cat("Saved tripanel figure to:", figures_dir, "\n")

# 10. Session info -----------------------------------------------------------
sink(file.path(logs_dir, "sessionInfo_annual_trend.txt"))
sessionInfo()
sink()

citation("ggplot2")
packageVersion("ggplot2")
