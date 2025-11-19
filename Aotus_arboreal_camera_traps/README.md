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
    │   ├── 04_night.R              # (add later)
    │   └── ...
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

### 3.1. Clone or download the repository

    git clone https://github.com/<your-username>/publications.git
    cd publications/Aotus_arboreal_camera_traps

Then open **R/RStudio** and set the working directory to this folder.

---

### 3.2. Script 01 — Tree distance analyses (Table S2)

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

### 3.3. Script 02 — Camera deployment periods & CTNs (Camera Trap Nights)

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

### 3.4. Script 03 — Behavior classification & proportions

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

## 4. Output Files

Outputs created by scripts are saved in:

    output/
    ├── tables/
    └── figures/

Optional logs:

    output/logs/

---

## 5. Reproducibility Notes

- All scripts use **relative paths** for portability  
- Raw data remain unchanged  
- Generated files go to `data/processed/` or `output/`  
- `sessionInfo()` recommended for version tracking  

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
