# ============================================================================
#  06_model_nb_glmm.R
# ----------------------------------------------------------------------------
# Purpose:
#   - Read monthly Aotus detections, phenology, and precipitation (from 05_annual_trend)
#   - Build a monthly summary table with circular month terms 
#   - Construct TreeID × Month dataset for NB-GLMM
#   - Fit NB-GLMM with AICc model selection (glmmTMB + MuMIn)
#   - Run diagnostics (DHARMa, collinearity, R²)
#   - Export key results and create:
#       - Table S5: Descriptive statistics
#       - Table S6: Spearman correlations
#       - Table S7: AICc model-selection results
#       - Figure S2: DHARMa diagnostic plots
#       - Figure 5: Observed detections vs. sine/cosine seasonal predictors
#
# How to run:
#   - Set working directory to the project root:
#       Aotus_arboreal_camera_traps/
#   - Run:
#       source("R/06_model_nb_glmm.R")
#
# Dependencies:
#   - dplyr, lubridate, readr, tidyr
#   - glmmTMB, DHARMa, MuMIn, performance
#   - broom, broom.mixed, reshape2, ggplot2, writexl, knitr
# ============================================================================


# 0. Packages ----------------------------------------------------------------
required_pkgs <- c(
  "dplyr", "lubridate", "readr", "tidyr",
  "glmmTMB", "DHARMa", "MuMIn", "performance",
  "broom", "broom.mixed", "reshape2",
  "ggplot2", "writexl", "knitr"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required but not installed.", call. = FALSE)
  }
}

library(dplyr)
library(lubridate)
library(readr)
library(tidyr)
library(glmmTMB)
library(DHARMa)
library(MuMIn)
library(performance)
library(broom)
library(broom.mixed)
library(reshape2)
library(ggplot2)
library(writexl)
library(knitr)

options(na.action = "na.fail")   # required for MuMIn::dredge()

# 1. Paths -------------------------------------------------------------------
raw_dir       <- file.path("data", "raw")
processed_dir <- file.path("data", "processed")
figures_dir   <- file.path("output", "figures")
tables_dir    <- file.path("output", "tables")
logs_dir      <- file.path("output", "logs")

if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)
if (!dir.exists(figures_dir))   dir.create(figures_dir,   recursive = TRUE)
if (!dir.exists(tables_dir))    dir.create(tables_dir,    recursive = TRUE)
if (!dir.exists(logs_dir))      dir.create(logs_dir,      recursive = TRUE)

# Input files (from previous scripts)
file_aot      <- file.path(processed_dir, "Aotus_Ind_Det_timeprocessed_03.csv")
file_det_mo   <- file.path(processed_dir, "Aotus_monthly_detections.csv")
file_ph_mo    <- file.path(processed_dir, "Pheno_monthly_FB_OF.csv")
file_prcp_mo  <- file.path(processed_dir, "Climate_monthly_precipitation.csv")
file_ph_tm    <- file.path(processed_dir, "Pheno_tm_FB_OF.csv")

# 2. Load csvs ---------------------------------------------------------------

# a) Independent detections (tree × detection events)
aot <- read.csv(
  file_aot,
  stringsAsFactors = FALSE
)
str(aot)

# b) MONTHLY Aotus detections ------------------------------------------------
det_mo <- read.csv(
  file_det_mo,
  stringsAsFactors = FALSE
)
str(det_mo)

# c1) Phenology MONTHLY -------------------------------------------------------
ph_mo <- read.csv(
  file_ph_mo,
  stringsAsFactors = FALSE
)
str(ph_mo)

# c2) Phenology TREE X MONTH -------------------------------------------------------
ph_tm <- read.csv(
  file_ph_tm,
  stringsAsFactors = FALSE
)
str(ph_tm)

# d) Climate MONTHLY ---------------------------------------------------------
prcp_mo <- read.csv(
  file_prcp_mo,
  stringsAsFactors = FALSE
)
str(prcp_mo)

# Quick structure check 
str(aot)
str(det_mo)
str(ph_mo)
str(ph_tm)
str(prcp_mo)

# 3. Build monthly descriptive dataset  -------------------------------------------
# Make sure 'month' is in Date format
det_mo  <- det_mo  %>% mutate(month = as.Date(month))
ph_mo   <- ph_mo   %>% mutate(month = as.Date(month))
prcp_mo <- prcp_mo %>% mutate(month = as.Date(month))
ph_tm   <- ph_tm   %>% mutate(month = as.Date(month))

# Merge monthly series
monthly_df <- det_mo %>%
  full_join(ph_mo, by = "month") %>%
  full_join(prcp_mo, by = "month") %>%
  arrange(month) %>%
  rename(
    Count = detections,
    FB    = flower_buds,
    OF    = open_flowers,
    PCP   = precip_mm
  )

str(monthly_df)
summary(monthly_df)

# # 4. Build TreeID × Month dataset for NB-GLMM -------------------------------
# Aotus detections: build tree × month counts from the event-level dataset
aot_tm <- aot %>%
  mutate(
    DateTime = ymd_hms(DateTime),
    Date     = as.Date(DateTime),
    Month    = floor_date(Date, "month")
  ) %>%
  filter(
    Date >= as.Date("2023-08-01"),
    Date <= as.Date("2024-11-30")
  ) %>%
  count(TreeID, Month, name = "Count")

# Complete all tree × month combinations (zeros where no detections)
all_months <- seq(as.Date("2023-08-01"), as.Date("2024-11-01"), by = "1 month")
all_trees  <- sort(unique(aot$TreeID))

aot_tm <- aot_tm %>%
  complete(
    TreeID = all_trees,
    Month  = all_months,
    fill   = list(Count = 0)
  )

# Join tree × month phenology and monthly precipitation
model_df <- aot_tm %>%
  left_join(
    ph_tm %>%
      select(TreeID, month, FB = flower_buds, OF = open_flowers, n_surveys),
    by = c("TreeID", "Month" = "month")
  ) %>%
  left_join(
    prcp_mo %>%
      rename(Month = month, PCP = precip_mm),
    by = "Month"
  ) %>%
  mutate(
    MonthNum = month(Month),
    sinM     = sin(2 * pi * MonthNum / 12),
    cosM     = cos(2 * pi * MonthNum / 12)
  ) %>%
  arrange(TreeID, Month)

str(model_df)
summary(model_df)
print(model_df, n = 20)

# =============================================================================
# 5. Exploratory Descriptive Statistics, Spearman correlations & VIF
# =============================================================================

# ---- Descriptive statistics (ECOLOGICAL VARIABLES ONLY) ----
vars_desc <- c("Count", "FB", "OF", "PCP")

desc_stats <- monthly_df %>%
  select(all_of(vars_desc)) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Value") %>%
  group_by(Variable) %>%
  dplyr::summarize(
    Mean   = round(mean(Value, na.rm = TRUE), 2),
    Median = round(median(Value, na.rm = TRUE), 2),
    SD     = round(sd(Value, na.rm = TRUE), 2),
    Min    = round(min(Value, na.rm = TRUE), 2),
    Max    = round(max(Value, na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  mutate(
    Variable = dplyr::recode(
      Variable,
      Count = "Aotus detections (count/month)",
      FB    = "Flower buds (mean class/month)",
      OF    = "Open flowers (mean class/month)",
      PCP   = "Precipitation (mm/month)"
    )
  )

desc_stats

# ---- Save Table S5 ----
write_csv(
  desc_stats,
  file.path(tables_dir, "Table_S5_Descriptive_statistics.csv")
)

kable(
  desc_stats,
  caption = "Table S5. Descriptive statistics for ecological variables used in NB-GLMM."
)

# ---- Spearman correlations (NO OF here: just covariates for model included) --
vars_cor <- c("FB", "PCP", "sinM", "cosM")

cor_res <- Hmisc::rcorr(as.matrix(model_df[vars_cor]), type = "spearman")

rho <- cor_res$r

rho_long <- reshape2::melt(
  rho,
  varnames = c("Variable1", "Variable2"),
  value.name = "Spearman_rho"
)

spearman_table <- rho_long %>%
  filter(Variable1 != Variable2) %>%
  filter(!duplicated(t(apply(.[, c("Variable1", "Variable2")], 1, sort)))) %>%
  arrange(desc(abs(Spearman_rho))) %>%
  mutate(
    Spearman_rho = round(Spearman_rho, 2)
  )

spearman_table

# ---- Spearman correlation Table S6 ----
write_csv(
  spearman_table,
  file.path(tables_dir, "Table_S6_Spearman_correlations.csv")
)

kable(
  spearman_table,
  caption = "Table S6. Spearman’s rank correlation coefficients (ρ) among covariates used in NB-GLMMs."
)

# ---- VIF (NO OF here: just covariates for model included) --
library(car)

vif_model <- lm(Count ~ FB + PCP + sinM + cosM, data = model_df)
vif_values <- car::vif(vif_model)

vif_values

# =============================================================================
# 6. Tree × Month NB-GLMM with AICc model selection
# =============================================================================

aot_tm_clean <- aot_tm %>%
  select(Count, sinM, cosM, PCP, FB, InfantPresent, TreeID) %>%
  tidyr::drop_na()

# ---- Overdispersion check: variance / mean  ----
mean_count <- mean(aot_tm_clean$Count)
var_count  <- var(aot_tm_clean$Count)
disp_ratio <- var_count / mean_count

cat("Mean Count:", round(mean_count, 2), "\n")
cat("Variance of Count:", round(var_count, 2), "\n")
cat("Variance/Mean ratio:", round(disp_ratio, 2), "\n")

# Global model
global_nb <- glmmTMB(
  Count ~ sinM + cosM + PCP + FB + InfantPresent + (1 | TreeID),
  family  = nbinom2,
  data    = aot_tm_clean,
  control = glmmTMBControl(optCtrl = list(iter.max = 1e5, eval.max = 1e5))
)

# Model selection
dredge_nb <- MuMIn::dredge(global_nb, rank = "AICc")
print(head(dredge_nb, 10))

# Best model (lowest AICc)
best_nb <- MuMIn::get.models(dredge_nb, 1)[[1]]
summary(best_nb)

# =============================================================================
# 7. Diagnostics & validation
# =============================================================================

sim_nb <- simulateResiduals(best_nb, n = 1000)

# ---- DHARMa plots on screen ----
plot(sim_nb)
testDispersion(sim_nb)
testZeroInflation(sim_nb)

# ---- Save DHARMa diagnostic Figure S2 ----
png(
  filename = file.path(figures_dir, "Figure_S2_DHARMa_diagnostics.png"),
  width    = 7.5,   # more horizontal room
  height   = 4.5,   # a bit shorter vertically
  units    = "in",
  res      = 300
)

par(mar = c(4.5, 4.5, 2, 1), oma = c(0, 0, 2, 0))  # tighter right margin

plot(sim_nb)

dev.off()

# Collinearity from the global model
check_collinearity(global_nb)

# R² for best model
r2(best_nb)

# =============================================================================
# 8. Effect sizes & predictor significance
# =============================================================================

fixef_nb <- broom.mixed::tidy(
  best_nb,
  effects     = "fixed",
  conf.int    = TRUE,
  conf.method = "Wald",
  conf.level  = 0.95
) %>%
  mutate(
    RateRatio = exp(estimate),
    CI_low    = exp(conf.low),
    CI_high   = exp(conf.high)
  ) %>%
  select(
    term, estimate, std.error, statistic, p.value,
    RateRatio, CI_low, CI_high
  )

print(fixef_nb)

# Likelihood-ratio tests
lrt_nb <- drop1(best_nb, test = "Chisq")
print(lrt_nb)

# ---- Best-model table (Table 3) ----
table_best <- fixef_nb %>%
  mutate(
    Term = dplyr::recode(
      term,
      "(Intercept)" = "(Intercept)",
      "FB"          = "FB",
      "sinM"        = "sinM"
    ),
    RR      = round(RateRatio, 2),
    CI_low  = round(CI_low, 2),
    CI_high = round(CI_high, 2),
    # NEW: nice p-value formatting (no scientific notation)
    p_value = ifelse(
      p.value < 0.001,
      "< 0.001",
      format(round(p.value, 3), nsmall = 3)
    )
  ) %>%
  select(Term, RR, CI_low, CI_high, p_value)

write_csv(
  table_best,
  file.path(tables_dir, "Table_3_Best_NB_GLMM.csv")
)

kable(
  table_best,
  caption = "Table 3. Fixed-effect estimates of the most parsimonious NB-GLMM predicting monthly Aotus vociferans independent detections. Results are expressed as rate ratios (RR) with 95% Wald confidence intervals and associated p-values."
)

# ---- Save all key tables to one Excel workbook ----
model_selection_df <- as.data.frame(dredge_nb)

# ---- Table S7: clean AICc model-selection table ----
extract_terms <- function(df_row) {
  nm <- names(df_row)
  # Coefficient columns for the conditional model (exclude intercept)
  term_cols <- nm[grepl("^cond\\(", nm) & nm != "cond((Int))"]
  included  <- term_cols[!is.na(df_row[term_cols])]
  if (length(included) == 0) return("(Intercept-only)")
  clean <- gsub("^cond\\(|\\)$", "", included)
  clean <- sort(clean)  # keep a consistent order
  paste(clean, collapse = " + ")
}

model_selection_df$Model_terms <- vapply(
  seq_len(nrow(model_selection_df)),
  function(i) extract_terms(model_selection_df[i, , drop = FALSE]),
  FUN.VALUE = character(1)
)

table_s7 <- model_selection_df %>%
  mutate(
    logLik    = round(logLik, 2),
    AICc      = round(AICc, 2),
    DeltaAICc = round(delta, 2),
    weight    = round(weight, 3)
  ) %>%
  select(Model_terms, df, logLik, AICc, DeltaAICc, weight) %>%
  arrange(AICc)

write_csv(
  table_s7,
  file.path(tables_dir, "Table_S7_AICc_model_selection.csv")
)

kable(
  table_s7,
  caption = "Table S7. AICc model selection summary for NB-GLMM."
)

lrt_df <- as.data.frame(lrt_nb)

write_xlsx(
  list(
    Descriptive_statistics = desc_stats,
    Spearman_correlations  = spearman_table,
    Model_selection        = model_selection_df,
    Best_model             = table_best,
    Likelihood_ratio       = lrt_df
  ),
  path = file.path(tables_dir, "NB_GLMM_tables_all.xlsx")
)

print(model_selection_df)
print(table_best)
print(lrt_df)

# =============================================================================
# 9. Plot observed detections vs sine/cosine seasonal pattern (Figure 5)
# =============================================================================

## 1. Collapse tree-level data to monthly totals -----------------------------
plot_df <- aot_tm %>%
  filter(Month >= as.Date("2023-08-01")) %>%
  group_by(Month) %>%
  summarise(
    Observed = sum(Count, na.rm = TRUE),
    sinM     = unique(sinM),
    cosM     = unique(cosM),
    .groups  = "drop"
  ) %>%
  mutate(
    sinM_scaled = scales::rescale(sinM, to = range(Observed, na.rm = TRUE)),
    cosM_scaled = scales::rescale(cosM, to = range(Observed, na.rm = TRUE))
  )

## 2. Long format for ggplot ------------------------------------------------
plot_long <- plot_df %>%
  select(Month, Observed, sinM_scaled, cosM_scaled) %>%
  tidyr::pivot_longer(
    cols      = c(Observed, sinM_scaled, cosM_scaled),
    names_to  = "Curve",
    values_to = "Value"
  ) %>%
  mutate(
    Curve = dplyr::recode(
      Curve,
      "Observed"    = "Aotus detections",
      "sinM_scaled" = "Sine wave",
      "cosM_scaled" = "Cosine wave"
    )
  )

## 3. Plot – single legend, smooth sin/cos, no grid ------------------------
custom_breaks <- as.Date(c("2023-09-01", "2024-01-01", "2024-05-01", "2024-09-01"))

p <- ggplot(
  plot_long,
  aes(x = Month, y = Value, colour = Curve, linetype = Curve, group = Curve)
) +
  geom_smooth(se = FALSE, span = 0.7, linewidth = 1) +
  scale_color_manual(
    name   = NULL,
    values = c(
      "Aotus detections" = "#D55E00",
      "Sine wave"        = "black",
      "Cosine wave"      = "grey50"
    )
  ) +
  scale_linetype_manual(
    name   = NULL,
    values = c(
      "Aotus detections" = "solid",
      "Sine wave"        = "solid",
      "Cosine wave"      = "dotted"
    )
  ) +
  scale_x_date(
    breaks      = custom_breaks,
    date_labels = "%b %Y",
    expand      = expansion(mult = c(0.01, 0.03))
  ) +
  labs(
    x = "Month",
    y = "Total monthly observed detections"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border     = element_rect(colour = "black", fill = NA, linewidth = 0.5),
    axis.line        = element_blank(),
    axis.text.x      = element_text(angle = 0, hjust = 0.5),
    legend.position  = "right",
    legend.background = element_rect(fill = "white", colour = NA),
    plot.margin      = margin(5, 5, 5, 15)
  )

print(p)

ggsave(
  filename = file.path(figures_dir, "Figure_5_sin_Aot_cos_NEW.png"),
  plot     = p,
  width    = 6.5,
  height   = 4,
  units    = "in",
  dpi      = 300
)
