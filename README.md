# Aotus arboreal camera traps  

This folder contains the data and code used to reproduce the analyses and figures for the manuscript:

## Flower feeding and reproductive timing in Spix’s night monkey (*Aotus vociferans*): evidence from arboreal camera traps

submitted to *Ecology & Evolution Nature Notes*.

[![DOI](https://zenodo.org/badge/1072125404.svg)](https://doi.org/10.5281/zenodo.17669413)

Citation:
Viganò, C. (2026). Flower feeding and reproductive timing in Spix’s night monkey (*Aotus vociferans*): evidence from arboreal camera traps. Zenodo. <a href="https://doi.org/10.5281/zenodo.17669413"><img src="https://zenodo.org/badge/1072125404.svg" alt="DOI"></a>


---

## 1. Folder Structure

    Aotus_arboreal_camera_traps/
    │
    ├── R/                          # Analysis scripts (numbered)
    │   ├── 01_tree_distances_MCP.R # Creates distance matrices (Table S2) and calculates Minimum Convex Polygon (MCP)
    │   ├── 02_camera_placement.R   # Calculates cameras activity periods (Table S3, Figure S1)
    │   ├── 03_behavior.R           # Calculates behavior proportions (Table S4, Figure 3)
    │   ├── 04_night_activiy.R      # Calulates the night activity pattern of Aotus (Figure 4)
    │   ├── 05_annual_trends.R      # Plot annual trends of Aotus detections, infant presence, phenology and precipitation (Figure 2)
    │   ├── 06_model.R              # Runs the model and generates (Figures: 5 and S2 ; Tables: 3 and S5, S6, S7)
    │
    ├── data/
    │   ├── raw/                    # Raw, unchanged input data
    │   ├── processed/              # Cleaned / derived data
    │
    ├── output/
    │   ├── tables/                 # Tables for main text + Supplementary Information
    │   ├── figures/                # Tables for main text + Supplementary Information
    │   └── logs/                   # sessionInfo etc.
    │
    ├── scripts_to_reproduce_figures/
    │   └── (optional) Rmd or R scripts generating figures
    │
    ├── LICENSE
    ├── CITATION.cff
    └── README.md

---

## 2. Software and Dependencies

All analyses use **R** (version 4.5.1).

To install required packages, run this line at the beginning of each script:

    install.packages(c("package1", "package2", "package..."))
---

## 3. How to Reproduce the Analyses

### 3.0. Clone or download the repository

    git clone https://github.com/<your-username>/publications.git
    cd publications/Aotus_arboreal_camera_traps

Then open **R/RStudio** and set the working directory to this folder.

---

### 3.1. Script 01 — Tree distance and study area analyses (Table S2)

Script: `R/01_tree_distances_MCP.R`

This script:

- Reads tree coordinates from `data/raw/Trees_Reconyx.csv`
- Calculates all pairwise distances (Haversine)
- Calculates the Minimum Convex Polygon (MCP) defined by the trees 
- Exports:
    - `data/processed/Trees_distance_matrix_long.csv`
    - `output/tables/Table_S2_tree_distances.csv`
- Prints summary statistics
- Writes session information to `output/logs/`

Run:

    source("R/01_tree_distances_MCP.R")

---

### 3.2. Script 02 — Camera deployment periods & CTNs (Camera Trap Nights)

Script: `R/02_camera_placement.R`

This script:

- Reads summarised camera deployment data from  
  `data/raw/CameraTrapDates.csv`
- Computes:
  - Camera Trap Nights (CTNs) for each deployment interval  
  - Total CTNs across all cameras  
  - Total number of active days between the first and last deployment
- Exports:  
  -`output/tables/Table_S3.csv`  
  -`output/figures/Figure_S1.png`
- Writes session information for reproducibility:  
  `output/logs/sessionInfo_camera_placement.txt`

Run:

    source("R/02_camera_placement.R")

---

### 3.3. Script 03 — Behavior classification & proportions

Script: `R/03_behavior.R`

This script:

- Reads independent Aotus detections from  
  `data/raw/Aotus_Independent_Detections_01.csv`
- Cleans and reclassifies behaviors
- Flags infant presence 
- Computes:
  - Behavioral counts and percentages
  - Summary behavior categories 
- Exports:
  - Dataset of Aotus independent detections with reclassified behaviors  → `data/processed/Ind_Det_Aotus_reclassified_02.csv`
  - `output/tables/Table_S4.xlsx`
  - `output/figures/Figure_3.pdf`
- Writes session information for reproducibility to:  
  `output/logs/sessionInfo_behavior.txt`

Run:

    source("R/03_behavior.R")

---

### 3.4. Script 04 — Night activity patterns

Script: `R/04_night_activity.R`

This script:

- Reads independent Aotus detections with reclassified behavior from  
  `data/processed/Aotus_Ind_Det_reclassified_02.csv`
- Converts detection timestamps to POSIX time and circular time (radians)
- Estimates nocturnal activity pattern using kernel density estimation on circular time with the **overlap** package
- Exports:
  - Dataset of Aotus independent detections with timestamps → `data/processed/Aotus_Ind_Det_timeprocessed_03.csv`
  - `output/figures/Figure_4.png`
- Writes session information for reproducibility to:  
  `output/logs/sessionInfo_night_activity.txt`

Run:

    source("R/04_night_activity.R")

---

### 3.5. Script 05 — Annual trend: Aotus independent detections, phenology & precipitation  

**Script:** `R/05_annual_trend.R`

This script:

- Reads:
  - Time-processed Aotus independent detections  
    → `data/processed/Aotus_Ind_Det_timeprocessed_03.csv`
  - Phenology dataset (2022-2024)
    → `data/raw/pheno.csv`
  - Climate dataset (1998-2025)
    → `data/raw/CLIM_98-25.csv`

- Generates date-corrected versions of the phenology and climate datasets:
  - `data/processed/Pheno_date_jul23_nov24.csv`
  - `data/processed/Climate_date_aug23_nov24.csv`

- Aggregates all datasets to a **monthly time series** (August 2023 → November 2024):
  - Monthly Aotus detections  
  - Monthly mean intensity of flowering phases (flower buds, open flowers)  
  - Monthly precipitation
 
- Aggregates phenology dataset to **tree x month time series** (August 2023 → November 2024):
    
- Saves the derived monthly datasets:
  - `data/processed/Aotus_monthly_detections.csv`  
  - `data/processed/Pheno_monthly_FB_OF.csv`  
  - `data/processed/Climate_monthly_precipitation.csv`
  - `data/processed/Pheno_tm_FB_OF.csv` 

- Creates the base for **Figure 2** combining:
  - monthly Aotus detections
  - monthly mean phenology of flower buds and open flowers
  - monthly precipitation
  - a highlighted time window corresponding to the observed infant presence period (Jan–Apr 2024)

- Exports the base for Figure 2:
  - `output/figures/Figure_2.pdf`

- Writes session information for reproducibility to:  
  `output/logs/sessionInfo_annual_trend.txt`


Run:

    source("R/05_annual_trend.R")

---

### 3.6. Script 06 — Negative-Binomial GLMM: seasonal drivers of *Aotus vociferans*' detections  

**Script:** `R/06_model.R`

This script:

- Reads:
  - Monthly Aotus detections  
    → `data/processed/Aotus_monthly_detections.csv`
  - Monthly phenology (flower buds, open flowers)  
    → `data/processed/Pheno_monthly_FB_OF.csv`
  - Tree x Month phenology (flower buds, open flowers)  
    → `data/processed/Pheno_tm_FB_OF.csv`
  - Monthly precipitation  
    → `data/processed/Climate_monthly_precipitation.csv`
  - Tree-level independent detections  
    → `data/processed/Aotus_Ind_Det_timeprocessed_03.csv`

- Builds datasets required for modelling

- Computes exploratory summaries and exports:
  - **Table S5** — Descriptive statistics  
    → `output/tables/Table_S5_Descriptive_statistics.csv`
  - **Table S6** — Spearman correlations  
    → `output/tables/Table_S6_Spearman_correlations.csv`
  - Variance Inflation Factors (VIF)  

- Fits a negative-binomial GLMM (glmmTMB):
  - Identifies the top-ranked model (lowest AICc)
  - Defines a confidence set of models (ΔAICc ≤ 2)
  - Performs model averaging across the confidence set
  - Exports **Table 3** (model-averaged coefficients)
    → output/tables/Table_3_Model_averaged_coefficients.csv

- Generates diagnostics:
  - DHARMa residual **Figure S2**  
    → `output/figures/Figure_S2_DHARMa_diagnostics.png`
  - Collinearity diagnostics (Spearman correlations, VIF)

- Produces **Figure 5**:
  - Observed monthly detections vs. sine and cosine seasonal predictors  
    → `output/figures/Figure_5_sin_Aot_cos.png`

- Writes session information for reproducibility to:  
  `output/logs/sessionInfo_model.txt`

Run:

    source("R/06_model.R")

---

## 4. Output Files

Outputs created by scripts are saved in:

    output/
    ├── tables/
    └── figures/

Output logs in:

    output/logs/

---

## 5. Reproducibility Notes

- All scripts use **relative paths** for portability  
- Raw data remain unchanged  
- Generated files go to `data/processed/` or `output/`  
- `sessionInfo()` allows for version tracking  

