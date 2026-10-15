<h1 align="center">R Spatial Data: Buffer, Spatial Join, Overlay</h1>

<p align="center">
  <img src="https://img.shields.io/badge/R-4.6.1-276DC3?logo=r&logoColor=white" alt="R">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Data-Simulation-green.svg" alt="Data Type">
  <img src="https://img.shields.io/github/repo-size/Attaftazayn/r-spatial-data-buffer-spatial-join-overlay" alt="Repo Size">
</p>

## Overview

Week 6 exercises covering vector data analysis and spatial visualization with R: sf import/export, CRS transformation, attribute manipulation, buffer, centroid, convex hull, spatial predicates, spatial join, overlay, distance, and thematic mapping with ggplot2.

## Tools & Technologies

- **R** (>= 4.1.0)
- **RStudio**
- **Git & GitHub**

## R Packages

| Package | Purpose |
|---------|---------|
| `sf` | Simple Features — vector spatial data |
| `dplyr` | Data manipulation |
| `ggplot2` | Visualization with geom_sf |
| `units` | Measurement units handling |

## Project Structure

```
├── data/
│   ├── batas_demo.gpkg            # Zone boundaries (polygon)
│   ├── fasilitas_demo.gpkg        # Health facilities (point)
│   ├── fasilitas_koordinat.csv    # Facility coordinates
│   ├── fasilitas_demo.geojson     # Facilities (GeoJSON)
│   ├── sumber_demo.gpkg           # Source points
│   └── jalan_demo.gpkg            # Road network (line)
├── output/
│   ├── peta_vektor.png            # Facility and zone map
│   ├── peta_proporsi_zona.png     # Zone proportion map
│   ├── ringkasan_wilayah.gpkg     # District summary
│   ├── fasilitas_wilayah.gpkg     # Facilities + district
│   ├── fasilitas_dalam_zona.gpkg  # Facilities in zone
│   ├── zona_buffer.gpkg           # Combined buffer zone
│   ├── irisan_wilayah.gpkg        # Intersection result
│   ├── jalan_dalam_zona.gpkg      # Roads in zone
│   ├── wilayah_di_luar_zona.gpkg  # Area outside zone
│   ├── convex_hull.gpkg           # Facility convex hull
│   ├── luas_irisan.csv            # Intersection area
│   └── jarak_fasilitas.csv        # Facility distance
├── Minggu6_Vektor_R.R             # Main analysis script
└── README.md
```

## Output

| File | Format | Description |
|------|--------|-------------|
| `peta_vektor.png` | PNG | Facility and analysis zone map |
| `peta_proporsi_zona.png` | PNG | Zone proportion per district |
| `ringkasan_wilayah.gpkg` | GeoPackage | District summary |
| `luas_irisan.csv` | CSV | Intersection area |
| `jarak_fasilitas.csv` | CSV | Distance to nearest source |

## Installation

```r
install.packages(c("sf", "dplyr", "ggplot2", "units"))
```

## Usage

```r
source("Minggu6_Vektor_R.R")
```

## Workflow

1. Create simulated data (zones, facilities, sources, roads) in UTM 49S
2. Import and inspect sf objects with st_read()
3. Transform CRS and validate geometries
4. Calculate area, density, filter, and select attributes
5. Create buffer, centroid, and convex hull
6. Spatial predicates (intersects, within, touches)
7. Spatial join to assign district labels
8. Overlay (intersection, difference, crop)
9. Distance matrix to nearest source
10. Thematic maps with ggplot2
11. Export GeoPackage, CSV, and GeoJSON

## License

Data: simulated for learning. Code: MIT License.

## Contact

Maintained by [Attaftazayn](https://github.com/Attaftazayn)
