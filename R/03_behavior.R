# ============================================================================
#  03_behavior.R
# ----------------------------------------------------------------------------
# Purpose:
#   - Clean independent detections (Aotus) → useful columns & unified behaviors
#   - Reclassify behaviors and flag infant presence
#   - Create behavior summary table for Supplementary Table S4
#   - Create behavior proportion figure (Figure 3)
#
# How to run:
#   - Set working directory to the project root
#   - Run:
#       source("R/03_behavior.R")
#
# Dependencies:
#   - dplyr, stringr, ggplot2, viridis, writexl, forcats
# ============================================================================

# 0. Packages ----------------------------------------------------------------
required_pkgs <- c("dplyr", "stringr", "ggplot2", "viridis", "writexl", "forcats")

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required but not installed.", call. = FALSE)
  }
}

library(dplyr)      # data manipulation
library(stringr)    # string detection/recode
library(ggplot2)    # plotting
library(viridis)    # palette for plots
library(writexl)    # write Excel files
library(forcats)    # factor reordering

# 1. Paths -------------------------------------------------------------------
# All paths are relative to the project root
data_file   <- file.path("data", "raw", "Aotus_Independent_Detections_01.csv")

clean_dir   <- file.path("data", "processed")
tables_dir  <- file.path("output", "tables")
figures_dir <- file.path("output", "figures")
logs_dir    <- file.path("output", "logs")

if (!dir.exists(clean_dir))   dir.create(clean_dir,   recursive = TRUE)
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)
if (!dir.exists(logs_dir))    dir.create(logs_dir,    recursive = TRUE)

# 2. Read independent detections --------------------------------------------
aot_raw <- read.csv(data_file, stringsAsFactors = FALSE)

# Check required columns are present
if (!all(c("Behaviour", "Comment") %in% names(aot_raw))) {
  stop("Input file must contain columns: Behaviour, Comment")
}

# 3. Reclassify behaviors and flag infants ----------------------------------
aot_reclassified <- aot_raw %>%
  mutate(
    Behaviour = case_when(
      # Specific rows corrected to "Social"
      row_number() %in% c(145, 150) ~ "Social",
      # Any comment mentioning "insect" → Insectivory
      str_detect(Comment, regex("insect", ignore_case = TRUE)) ~ "Insectivory",
      TRUE ~ Behaviour
    ),
    # Mark infants: comments containing "baby" or "cub"
    infant = if_else(
      str_detect(Comment, regex("baby|cub", ignore_case = TRUE)),
      1L,
      0L
    )
  )

# 4. Save reclassified dataset ----------------------------------------------
clean_behavior <- file.path(clean_dir, "Aotus_Ind_Det_reclassified_02.csv")

write.csv(
  aot_reclassified,
  clean_behavior,
  row.names = FALSE
)

cat("Saved reclassified detections to:", clean_behavior, "\n")

# 5. Behavior counts and percentages ----------------------------------------
beh_summary <- aot_reclassified %>%
  count(Behaviour) %>%
  arrange(desc(n)) %>%
  mutate(Percent = n / sum(n) * 100)

# 6. Recode behaviors into summary categories -------------------------------
category_summary <- aot_reclassified %>%
  mutate(
    Category = case_when(
      Behaviour == "Wandering"                           ~ "Locomotion",
      Behaviour == "Inspecting"                          ~ "Inspection",
      Behaviour %in% c("Herbivory", "Insectivory",
                       "Frugivory")                      ~ "Foraging",
      Behaviour %in% c("Florivory", "Nectivory")         ~ "Florivory",
      Behaviour %in% c("Other", "Social")                ~ "Other",
      TRUE                                               ~ "Other"
    )
  ) %>%
  count(Category) %>%
  arrange(desc(n)) %>%
  mutate(Percent = n / sum(n) * 100)

# 7. Plot category proportions (Figure 2) -----------------------------------
cat_plot <- category_summary %>%
  mutate(Category = fct_reorder(Category, Percent, .desc = TRUE))

Behavior_graph_AOT <- ggplot(cat_plot, aes(x = Category, y = Percent, fill = Category)) +
  geom_col(color = "black", linewidth = 0.3) +
  geom_text(
    aes(label = paste0(round(Percent, 1), "%")),
    vjust = -0.35,
    size  = 4
  ) +
  scale_y_continuous(
    limits = c(0, max(cat_plot$Percent) * 1.12),     # headroom for labels
    expand = expansion(mult = c(0, 0.03))
  ) +
  scale_fill_viridis_d(option = "cividis") +
  coord_cartesian(clip = "off") +
  labs(
    x = "Behavior Category",
    y = "Percentage of Observations"
  ) +
  theme_minimal(base_size = 14, base_family = "Times") +
  theme(
    legend.position  = "none",
    panel.border     = element_rect(color = "black", fill = NA, linewidth = 0.3),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks.x     = element_blank(),
    plot.title       = element_blank(),
    plot.margin      = margin(5.5, 12, 5.5, 5.5),
    axis.title.x     = element_text(
      face   = "bold",
      size   = 14,
      margin = margin(t = 12)
    ),
    axis.title.y     = element_text(
      face   = "bold",
      size   = 14,
      margin = margin(r = 12)
    )
  )

# 8. Print and save plot ----------------------------------------------------
print(Behavior_graph_AOT)

ggsave(
  filename = file.path(figures_dir, "Figure_3.pdf"),
  plot     = Behavior_graph_AOT,
  device   = pdf,
  width    = 168,
  height   = 110,
  units    = "mm"
)

# 9. Export summaries to Excel ----------------------------------------------
out_xlsx <- file.path(tables_dir, "Table_S4.xlsx")

write_xlsx(
  x = list(
    Behaviour_Counts = beh_summary,
    Category_Summary = category_summary
  ),
  path = out_xlsx
)

cat("Saved behavior summaries to", tables_dir,
    "and plot to", figures_dir, "\n")

# 10. Record session info for reproducibility -------------------------------
sink(file.path(logs_dir, "sessionInfo_behavior.txt"))
sessionInfo()
sink()
