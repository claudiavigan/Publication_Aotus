# ============================================================================
#  01_tree_distances.R
# ----------------------------------------------------------------------------
# Purpose:
#   - Compute pairwise distances among Handroanthus trees and the
#     Minimum Convex Polygon (MCP) defined by the trees 
#   - Export:
#       (1) Long-format distance matrix (all pairs)
#           -> output/tables/Trees_distance_matrix_long.csv
#       (2) Symmetric table with row means + total mean distance (Table S2)
#           -> output/tables/Table_S2_tree_distances.csv
#       (3) SessionInfo() log
#           -> output/logs/sessionInfo_tree_distances.txt
#
# How to run:
#   - Open an R session with the working directory set to the project root:
#       Aotus_arboreal_camera_traps/
#   - Run:
#       source("R/01_tree_distances.R")
#
# Dependencies:
#   - geosphere (for distHaversine)
#   - sf        (for handling coordinates)
# ============================================================================

# 0. Packages ----------------------------------------------------------------
required_pkgs <- c("geosphere", "sf", "dplyr")

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required but not installed.", call. = FALSE)
  }
}
library(geosphere)
library(sf)
library(dplyr)

# 1. Paths -------------------------------------------------------------------
# All paths are relative to the project root
data_file  <- file.path("data", "raw", "Trees_Reconyx.csv")

processed_dir    <- file.path("data", "processed")   
tables_dir       <- file.path("output", "tables")
logs_dir         <- file.path("output", "logs")

if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)
if (!dir.exists(tables_dir))    dir.create(tables_dir,    recursive = TRUE)
if (!dir.exists(logs_dir))      dir.create(logs_dir,      recursive = TRUE)

# 2. Helper function ---------------------------------------------------------
# Computes pairwise distances, exports long-format CSV, and returns summary stats
compute_distance_matrix <- function(df, id_col, lon_col, lat_col, out_filename_long) {
  
  # Convert to sf and compute distances (meters)
  sf_obj <- st_as_sf(df, coords = c(lon_col, lat_col), crs = 4326)
  coords <- st_coordinates(sf_obj)
  mat    <- distm(coords, fun = distHaversine)
  
  rownames(mat) <- df[[id_col]]
  colnames(mat) <- df[[id_col]]
  
  # Long format
  df_long <- as.data.frame(as.table(mat))
  colnames(df_long) <- c("Tree1", "Tree2", "Distance_m")
  
  # Export long-format CSV to data/processed/
  write.csv(
    df_long,
    file = file.path(processed_dir, out_filename_long),
    row.names = FALSE
  )
  
  
  # Unique pairs (exclude self and duplicates)
  df_filtered <- df_long[df_long$Tree1 != df_long$Tree2, ]
  df_unique  <- df_filtered[!duplicated(t(apply(df_filtered[, 1:2], 1, sort))), ]
  
  mean_dist <- mean(df_unique$Distance_m)
  min_row   <- df_unique[which.min(df_unique$Distance_m), ]
  max_row   <- df_unique[which.max(df_unique$Distance_m), ]
  
  list(
    mat       = mat,
    long      = df_long,
    unique    = df_unique,
    mean_dist = mean_dist,
    min_pair  = min_row,
    max_pair  = max_row
  )
}

# 3. Read data ---------------------------------------------------------------
trees <- read.csv(data_file, stringsAsFactors = FALSE)

# 4. All trees distance matrix -----------------------------------------------
res_all <- compute_distance_matrix(
  df                = trees,
  id_col            = "TreeID",
  lon_col           = "Longitude",
  lat_col           = "Latitude",
  out_filename_long = "Trees_distance_matrix_long.csv"
)

cat(sprintf("All trees — mean distance: %.2f m\n", res_all$mean_dist))
cat(sprintf(
  "Min: %.2f m between %s and %s\n",
  res_all$min_pair$Distance_m,
  res_all$min_pair$Tree1,
  res_all$min_pair$Tree2
))
cat(sprintf(
  "Max: %.2f m between %s and %s\n",
  res_all$max_pair$Distance_m,
  res_all$max_pair$Tree1,
  res_all$max_pair$Tree2
))

# 5. Build publication-ready table (Table S2) --------------------------------
M       <- res_all$mat      # matrix in meters
M_round <- round(M / 1, 1)  # round to 0.1 m (values already in m)

# Mean distance for each tree (excluding self)
row_means <- sapply(1:nrow(M_round), function(i) {
  mean(M_round[i, -i])
})

tab <- as.data.frame(M_round, check.names = FALSE)
tab$Mean <- round(row_means, 2)

# Add Tree ID as first column
tab <- cbind(`Tree ID` = rownames(tab), tab)

# Add "Total mean distance" row
total_row <- tab[1, ]
total_row[1, ] <- NA
total_row$`Tree ID` <- "Total mean distance"
total_row$Mean      <- round(res_all$mean_dist, 2)

tab_pub <- rbind(tab, total_row)

# Export publication table to output/tables/
write.csv(
  tab_pub,
  file.path(tables_dir, "Table_S2_tree_distances.csv"),
  row.names = FALSE
)

# 6. Minimum Convex Polygon (MCP) ----------
# The MCP (convex hull) is computed from the camera-monitored trees and used to
# report the spatial extent of the focal sampling locations.

# ---- Create simple-feature points in WGS84 ----
# Let's R understand that the numbers are actually spatially located points 
# Converting a normal dataframe into a spatial point object
pts_wgs84 <- st_as_sf(trees, coords = c("Longitude", "Latitude"), crs = 4326)

# ---- Project to a metric CRS (Coordinate Reference System) for accurate area ----
# The site is around lon -79, lat -4 => UTM Zone 17S (WGS84) is appropriate
pts_utm <- st_transform(pts_wgs84, 32717)  # EPSG:32717 = WGS84 / UTM 17S

# ---- Compute MCP / convex hull ----
hull <- pts_utm %>%
  summarise(geometry = st_convex_hull(st_union(geometry))) %>%
  mutate(
    area_m2 = as.numeric(st_area(geometry)),
    area_ha = area_m2 / 10000
  )

# ---- Print results ----
print(hull %>% st_drop_geometry() %>% mutate(
  area_m2 = round(area_m2, 1),
  area_ha = round(area_ha, 3)
))

# 7. Record session info for reproducibility ----------------------
#Uncomment if you want the log written to output/logs/
# sink(file.path(logs_dir, "sessionInfo_tree_distances.txt"))
# sessionInfo()
# sink()
