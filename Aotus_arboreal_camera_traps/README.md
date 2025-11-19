# Aotus arboreal camera traps  

This repository contains the data and code used to reproduce the analyses and figures for the manuscript:

> **Arboreal camera traps reveal new insights into flower feeding and reproductive timing in owl monkeys (*Aotus vociferans*)**

submitted to *Ecology & Evolution Nature Notes*.

---

## 1. Repository Structure

    Aotus_arboreal_camera_traps/
    │
    ├── R/                          # Analysis scripts (numbered)
    │   ├── 01_tree_distances.R     # Creates distance matrices (Table S2)
    │   ├── 02_camera_placement.R   # Calculates cameras activity periods (Table S3, Figure S1)
    │   ├── 03_behavior.R           # Calculates behavior proportions (Table S4, Figure 2)
    │   ├── 04_night_activiy.R      # Calulates the night activity pattern of Aotus (Figure 3)
    │   ├── 05_annual_trends.R      # Plot annual trends of Aotus detections, infant presence, phenology and precipitation (Figure 4)
    │
    ├── data/
    │   ├── raw/                    # Raw, unchanged input data
    │   ├── processed/              # Cleaned / derived data
    │   └── metadata/               # ??? data descriptions
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

### 3.1. Script 01 — Tree distance analyses (Table S2)

Script: `R/01_tree_distances.R`

This script:

- Reads tree coordinates from `data/raw/Trees_Reconyx.csv`
- Calculates all pairwise distances (Haversine)
- Exports:
    - `data/processed/Trees_distance_matrix_long.csv`
    - `output/tables/Table_S2_tree_distances.csv`
- Prints summary statistics
- Writes session information to `output/logs/`

Run:

    source("R/01_tree_distances.R")

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
  - `output/figures/Figure_2.pdf`
- Writes session information for reproducibility to:  
  `output/logs/sessionInfo_behavior.txt`

Run:

    source("R/03_behavior.R")

---

### 3.4. Script 04 — Night activity patterns (overlap)

Script: `R/04_night_activity.R`

This script:

- Reads independent Aotus detections with reclassified behavior from  
  `data/processed/Aotus_Ind_Det_reclassified_02.csv`
- Converts detection timestamps to POSIX time and circular time (radians)
- Estimates nocturnal activity pattern using kernel density estimation on circular time with the **overlap** package
- Exports:
  - Dataset of Aotus independent detections with timestamps → `data/processed/Aotus_Ind_Det_timeprocessed_03.csv`
  - `output/figures/Figure_3.png`
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
  - `data/processed/Pheno_date_aug23_nov24.csv`
  - `data/processed/Climate_date_aug23_nov24.csv`

- Aggregates all datasets to **monthly time series** (August 2023 → November 2024):
  - Monthly Aotus detections  
  - Mean monthly intensity of flowering phases (flower buds, open flowers)  
  - Monthly precipitation
    
- Saves the derived monthly datasets:
  - `data/processed/Aotus_monthly_detections.csv`  
  - `data/processed/Pheno_monthly_FB_OF.csv`  
  - `data/processed/Climate_monthly_precipitation.csv`

- Creates the base for **Figure 4** combining:
  - detections,
  - phenology intensity of flower buds and open flowers phases
  - precipitation
  - Period of infant presence in recordings (Jan–Apr 2024)

- Exports the base for Figure 4:
  - `output/figures/Figure_4_tripanel_annual_pattern.pdf`

- Writes session information for reproducibility to:  
  `output/logs/sessionInfo_annual_trend.txt`


Run:

    source("R/05_annual_trend.R")

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

---

## 6. License

This project is licensed under the terms described in the `LICENSE` file.

---

## 7. Citation

Citation metadata is provided in:

    CITATION.cff

Once published, please cite:

1. The peer-reviewed article  
2. The archived version of this repository (Zenodo DOI will be added here)

---

## 8. Contact

For questions:

**Claudia Viganò**  
<claudiaviga@me.com>
