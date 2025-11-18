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
    │   ├── 02_activity_patterns.R  # (add later)
    │   ├── 03_flower_visitation.R  # (add later)
    │   ├── 04_Model.R  # (add later)
    │   └── ...
    │
    ├── data/
    │   ├── raw/                    # Raw, unchanged input data
    │   │   └── Trees_Reconyx.csv
    │   ├── processed/              # Cleaned / derived data
    │   └── metadata/               # ??? data descriptions
    │
    ├── output/
    │   ├── tables/                 # Tables for main text + supplement
    │   ├── figures/                # Manuscript figures
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

To install required packages:

    install.packages(c("geosphere", "sf"))

Additional packages here:

    # - dplyr
    # - ggplot2
    # - lubridate
    # - tidyr

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

### 3.3. Script 02 — Activity patterns  
*(Add details here once the script is created)*

Suggested structure to follow:

- Purpose of the script  
- Input data  
- Output files (tables/figures)  
- Run command:  
      source("R/02_activity_patterns.R")

---

### 3.4. Script 03 — Flower visitation  
*(Add details when ready)*

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
