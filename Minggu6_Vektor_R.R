AUTO_INSTALL <- TRUE
RUN_TMAP <- FALSE
RUN_LEAFLET <- FALSE
RUN_WEB_API <- FALSE
BUFFER_M <- 1000
PROJECT_DIR <- "C:/Users/user/Downloads/semester 5/Pemspa/Weekly_code/Week_6"
CRAN_MIRROR <- "https://cloud.r-project.org"
if (getRversion() < "4.1.0") {
  stop("Gunakan R 4.1 atau lebih baru untuk operator pipe |>.")
}
options(timeout = max(300, getOption("timeout")))
siapkan_paket <- function(paket) {
  tersedia <- vapply(paket, requireNamespace, logical(1), quietly = TRUE)
  belum <- paket[!tersedia]
  if (length(belum) && AUTO_INSTALL) {
    message("Menginstal paket: ", paste(belum, collapse = ", "))
    install.packages(belum, repos = CRAN_MIRROR, dependencies = NA)
  }
  tersedia <- vapply(paket, requireNamespace, logical(1), quietly = TRUE)
  if (!all(tersedia)) {
    stop(
      "Paket belum tersedia: ", paste(paket[!tersedia], collapse = ", "),
      ". Instal paket tersebut, lalu jalankan ulang. ",
      "Pada Linux, sf juga memerlukan library sistem GDAL, GEOS, dan PROJ.",
      call. = FALSE
    )
  }
}
siapkan_paket(c("sf", "dplyr", "ggplot2", "units"))
suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(ggplot2)
})
if (RUN_TMAP) siapkan_paket("tmap")
if (RUN_LEAFLET) siapkan_paket(c("leaflet", "htmlwidgets"))
if (RUN_WEB_API) siapkan_paket("httr2")
DATA_DIR <- file.path(PROJECT_DIR, "data")
OUT_DIR <- file.path(PROJECT_DIR, "output")
dir.create(DATA_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
PROJECT_DIR <- normalizePath(PROJECT_DIR, winslash = "/", mustWork = TRUE)
bagian <- function(judul) {
  cat("\n", strrep("=", 72), "\n", judul, "\n", sep = "")
}
simpan_gpkg <- function(x, nama, layer) {
  sf::st_write(x, nama, layer = layer, delete_layer = TRUE, quiet = TRUE)
}
bagian("02. Data simulasi: wilayah, fasilitas, titik sumber, dan jalan")
kotak <- sf::st_bbox(
  c(xmin = 690000, ymin = 9190000, xmax = 698000, ymax = 9198000),
  crs = sf::st_crs(32749)
)
grid <- sf::st_make_grid(sf::st_as_sfc(kotak), n = c(2, 2))
batas_demo <- sf::st_sf(
  kecamatan = paste0("Zona ", LETTERS[1:4]),
  populasi = c(8000, 12000, 6000, 10000),
  geometry = grid
)
fasilitas_csv <- data.frame(
  nama = paste0("Fasilitas ", 1:6),
  jenis = c("Sekolah", "Puskesmas", "Sekolah", "Puskesmas", "Sekolah", "Sekolah"),
  x = c(691000, 693000, 695000, 697000, 691500, 696000),
  y = c(9191000, 9193000, 9192000, 9196000, 9196500, 9197000)
)
write.csv(fasilitas_csv, file.path(DATA_DIR, "fasilitas_koordinat.csv"),
          row.names = FALSE)
fasilitas_demo <- sf::st_as_sf(fasilitas_csv,
  coords = c("x", "y"), crs = 32749)
titik_sumber <- sf::st_as_sf(
  data.frame(id_sumber = 1:2,
    x = c(691200, 696800), y = c(9191200, 9196100)),
  coords = c("x", "y"), crs = 32749
)
jalan <- sf::st_sf(
  nama_jalan = c("Jalan A", "Jalan B"),
  geometry = sf::st_sfc(
    sf::st_linestring(matrix(
      c(690000, 9191200, 698000, 9191200), ncol = 2, byrow = TRUE)),
    sf::st_linestring(matrix(
      c(690000, 9196100, 698000, 9196100), ncol = 2, byrow = TRUE)),
    crs = 32749
  )
)
simpan_gpkg(batas_demo, file.path(DATA_DIR, "batas_demo.gpkg"), "batas")
simpan_gpkg(fasilitas_demo, file.path(DATA_DIR, "fasilitas_demo.gpkg"), "fasilitas")
simpan_gpkg(titik_sumber, file.path(DATA_DIR, "sumber_demo.gpkg"), "sumber")
simpan_gpkg(jalan, file.path(DATA_DIR, "jalan_demo.gpkg"), "jalan")
bagian("03. Impor data dan anatomi sf")
batas <- sf::st_read(file.path(DATA_DIR, "batas_demo.gpkg"), quiet = TRUE)
fasilitas <- sf::st_read(file.path(DATA_DIR, "fasilitas_demo.gpkg"), quiet = TRUE)
csv_titik <- read.csv(file.path(DATA_DIR, "fasilitas_koordinat.csv"),
                      stringsAsFactors = FALSE)
titik_dari_csv <- sf::st_as_sf(csv_titik, coords = c("x", "y"), crs = 32749)
print(names(batas))
print(sf::st_geometry_type(batas))
print(sf::st_crs(batas))
print(sf::st_drop_geometry(fasilitas))
stopifnot(nrow(batas) == 4L, nrow(fasilitas) == 6L,
          nrow(titik_dari_csv) == nrow(fasilitas))
bagian("04. Transformasi CRS dan pemeriksaan geometri")
fasilitas_ll <- sf::st_transform(fasilitas, 4326)
fasilitas_utm <- sf::st_transform(fasilitas_ll, sf::st_crs(batas))
print(sf::st_coordinates(fasilitas_ll))
stopifnot(sf::st_crs(fasilitas_utm) == sf::st_crs(batas))
batas <- sf::st_make_valid(batas)
batas <- batas[!sf::st_is_empty(batas), ]
stopifnot(all(sf::st_is_valid(batas)), !sf::st_is_longlat(batas),
          sf::st_crs(batas) == sf::st_crs(fasilitas))
bagian("05. Luas, kepadatan, filter, dan select")
batas$area_km2 <- as.numeric(sf::st_area(batas)) / 1e6
batas <- batas |>
  dplyr::mutate(kepadatan = populasi / area_km2)
prioritas <- batas |>
  dplyr::filter(kepadatan > 500) |>
  dplyr::select(kecamatan, kepadatan)
tabel_prioritas <- sf::st_drop_geometry(prioritas)
print(sf::st_drop_geometry(batas))
print(tabel_prioritas)
stopifnot(all(abs(batas$area_km2 - 16) < 1e-6))
bagian("06. Buffer dan modifikasi geometri")
buffer_sumber <- sf::st_buffer(titik_sumber, dist = BUFFER_M)
zona <- sf::st_sf(id_zona = 1L,
                  geometry = sf::st_union(sf::st_geometry(buffer_sumber)))
pusat <- sf::st_sf(kecamatan = batas$kecamatan,
                   geometry = sf::st_centroid(sf::st_geometry(batas)))
titik_dalam <- sf::st_sf(kecamatan = batas$kecamatan,
  geometry = sf::st_point_on_surface(sf::st_geometry(batas)))
hull <- sf::st_sf(id = 1L,
  geometry = sf::st_convex_hull(sf::st_union(sf::st_geometry(fasilitas))))
print(sf::st_area(zona))
bagian("07. Predikat spasial dan fasilitas dalam zona")
relasi <- sf::st_intersects(fasilitas, zona)
matriks_relasi <- sf::st_intersects(fasilitas, zona, sparse = FALSE)
fasilitas$terpapar <- lengths(relasi) > 0L
fasilitas_terpilih <- fasilitas |>
  dplyr::filter(terpapar)
print(matriks_relasi)
print(table(fasilitas$terpapar))
print(sf::st_drop_geometry(fasilitas_terpilih))
print(sf::st_within(fasilitas, batas, sparse = FALSE))
print(sf::st_touches(batas, batas, sparse = FALSE))
if (BUFFER_M == 1000) {
  stopifnot(setequal(fasilitas_terpilih$nama,
                    c("Fasilitas 1", "Fasilitas 4")))
}
bagian("08. Menambahkan kecamatan berdasarkan lokasi")
fasilitas_wilayah <- sf::st_join(
  fasilitas, batas["kecamatan"], join = sf::st_within, left = TRUE
)
print(sf::st_drop_geometry(fasilitas_wilayah))
stopifnot(nrow(fasilitas_wilayah) == nrow(fasilitas),
          !anyNA(fasilitas_wilayah$kecamatan))
jumlah_fasilitas <- fasilitas_wilayah |>
  sf::st_drop_geometry() |>
  dplyr::group_by(kecamatan) |>
  dplyr::summarise(n_fasilitas = dplyr::n(),
                  n_dalam_zona = sum(terpapar), .groups = "drop")
bagian("09. Intersection, difference, crop, dan ringkasan wilayah")
irisan <- sf::st_intersection(batas["kecamatan"], zona)
irisan$luas_zona_km2 <- as.numeric(sf::st_area(irisan)) / 1e6
ringkasan_irisan <- irisan |>
  sf::st_drop_geometry() |>
  dplyr::group_by(kecamatan) |>
  dplyr::summarise(luas_zona_km2 = sum(luas_zona_km2), .groups = "drop")
hasil <- batas |>
  dplyr::left_join(ringkasan_irisan, by = "kecamatan") |>
  dplyr::left_join(jumlah_fasilitas, by = "kecamatan") |>
  dplyr::mutate(
    luas_zona_km2 = dplyr::coalesce(luas_zona_km2, 0),
    proporsi_zona_persen = 100 * luas_zona_km2 / area_km2
  )
stopifnot(all(hasil$proporsi_zona_persen >= 0),
          all(hasil$proporsi_zona_persen <= 100 + 1e-6))
print(sf::st_drop_geometry(hasil))
wilayah_di_luar_zona <- sf::st_difference(batas, sf::st_geometry(zona))
jalan_dalam_zona <- sf::st_intersection(jalan, zona)
kotak_potong <- sf::st_bbox(
  c(xmin = 690000, ymin = 9190000, xmax = 694000, ymax = 9198000),
  crs = sf::st_crs(batas)
)
batas_crop <- sf::st_crop(batas, kotak_potong)
bagian("10. Matriks jarak dan jarak minimum")
mat_jarak <- sf::st_distance(fasilitas, titik_sumber)
print(mat_jarak)
mat_jarak_m <- units::drop_units(mat_jarak)
fasilitas$jarak_min_m <- apply(mat_jarak_m, 1, min)
tabel_jarak <- fasilitas |>
  sf::st_drop_geometry() |>
  dplyr::select(nama, terpapar, jarak_min_m)
print(tabel_jarak)
bagian("11. Peta dan ekspor PNG")
p <- ggplot2::ggplot() +
  ggplot2::geom_sf(data = batas,
    ggplot2::aes(fill = kepadatan), color = "white", linewidth = 0.6) +
  ggplot2::geom_sf(data = jalan, color = "grey50", linewidth = 0.5) +
  ggplot2::geom_sf(data = zona, fill = NA,
    color = "firebrick", linewidth = 0.9) +
  ggplot2::geom_sf(data = fasilitas,
    ggplot2::aes(shape = terpapar), size = 3, color = "navy") +
  ggplot2::geom_sf_text(data = titik_dalam,
    ggplot2::aes(label = kecamatan), size = 4, check_overlap = TRUE) +
  ggplot2::scale_fill_viridis_c(name = "Jiwa/km2") +
  ggplot2::scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 17),
    labels = c("Di luar zona", "Di dalam zona"), name = "Posisi fasilitas") +
  ggplot2::labs(
    title = "Fasilitas dan zona analisis",
    subtitle = paste("Buffer", BUFFER_M, "m dalam UTM zona 49S"),
    caption = "Data simulasi untuk pembelajaran. Bukan peta bahaya."
  ) +
  ggplot2::theme_minimal(base_size = 12)
if (interactive()) print(p)
ggplot2::ggsave(file.path(OUT_DIR, "peta_vektor.png"), plot = p,
                width = 10, height = 7, units = "in", dpi = 300)
p_proporsi <- ggplot2::ggplot(hasil) +
  ggplot2::geom_sf(ggplot2::aes(fill = proporsi_zona_persen), color = "white") +
  ggplot2::scale_fill_viridis_c(name = "Persen") +
  ggplot2::labs(title = "Proporsi wilayah dalam zona analisis",
    caption = "Data simulasi. Persen = luas irisan / luas wilayah x 100.") +
  ggplot2::theme_minimal(base_size = 12)
if (interactive()) print(p_proporsi)
ggplot2::ggsave(file.path(OUT_DIR, "peta_proporsi_zona.png"), plot = p_proporsi,
                width = 10, height = 7, units = "in", dpi = 300)
bagian("12. Ekspor hasil GeoPackage dan CSV")
simpan_gpkg(hasil, file.path(OUT_DIR, "ringkasan_wilayah.gpkg"), "ringkasan")
simpan_gpkg(fasilitas_wilayah,
             file.path(OUT_DIR, "fasilitas_wilayah.gpkg"), "fasilitas")
simpan_gpkg(fasilitas_terpilih,
             file.path(OUT_DIR, "fasilitas_dalam_zona.gpkg"), "fasilitas")
simpan_gpkg(zona, file.path(OUT_DIR, "zona_buffer.gpkg"), "zona")
simpan_gpkg(irisan, file.path(OUT_DIR, "irisan_wilayah.gpkg"), "irisan")
simpan_gpkg(jalan_dalam_zona,
             file.path(OUT_DIR, "jalan_dalam_zona.gpkg"), "jalan")
simpan_gpkg(wilayah_di_luar_zona,
             file.path(OUT_DIR, "wilayah_di_luar_zona.gpkg"), "wilayah")
simpan_gpkg(hull, file.path(OUT_DIR, "convex_hull.gpkg"), "hull")
write.csv(sf::st_drop_geometry(hasil), file.path(OUT_DIR, "luas_irisan.csv"),
          row.names = FALSE)
write.csv(tabel_jarak, file.path(OUT_DIR, "jarak_fasilitas.csv"), row.names = FALSE)
bagian("13. Ekspor dan impor GeoJSON lokal")
geojson_file <- file.path(DATA_DIR, "fasilitas_demo.geojson")
sf::st_write(sf::st_transform(fasilitas, 4326), geojson_file,
             driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
fasilitas_geojson <- sf::st_read(geojson_file, quiet = TRUE)
stopifnot(nrow(fasilitas_geojson) == nrow(fasilitas))
print(sf::st_crs(fasilitas_geojson))
if (RUN_TMAP) {
  bagian("14. tmap: peta statis dan interaktif")
  tmap::tmap_mode("plot")
  if (utils::packageVersion("tmap") >= "4.0.0") {
    tm <- tmap::tm_shape(batas) + tmap::tm_polygons(fill = "kepadatan")
  } else {
    tm <- tmap::tm_shape(batas) + tmap::tm_polygons("kepadatan")
  }
  tmap::tmap_save(tm, filename = file.path(OUT_DIR, "peta_tmap.png"))
  tmap::tmap_mode("view")
  tmap::tmap_save(tm, filename = file.path(OUT_DIR, "peta_tmap.html"),
                 selfcontained = FALSE)
  tmap::tmap_mode("plot")
}
if (RUN_LEAFLET) {
  bagian("15. leaflet: peta dengan popup")
  web <- leaflet::leaflet(sf::st_transform(fasilitas, 4326)) |>
    leaflet::addProviderTiles("OpenStreetMap") |>
    leaflet::addCircleMarkers(radius = 5, popup = ~nama)
  htmlwidgets::saveWidget(web, file.path(OUT_DIR, "peta_leaflet.html"),
                          selfcontained = FALSE)
  if (interactive()) print(web)
}
if (RUN_WEB_API) {
  bagian("16. Permintaan GET dan membaca GeoJSON USGS")
  tryCatch({
    endpoint <- paste0("https://earthquake.usgs.gov/earthquakes/feed/",
                        "v1.0/summary/all_day.geojson")
    resp <- httr2::request(endpoint) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()
    cat("Status HTTP:", httr2::resp_status(resp), "\n")
    data_list <- httr2::resp_body_json(resp)
    cat("Jumlah fitur dalam respons:", length(data_list$features), "\n")
    api_file <- file.path(DATA_DIR, "usgs_gempa_harian.geojson")
    writeBin(httr2::resp_body_raw(resp), api_file)
    gempa <- sf::st_read(api_file, quiet = TRUE)
    gempa <- sf::st_zm(gempa, drop = TRUE, what = "ZM")
    write.csv(sf::st_drop_geometry(gempa),
      file.path(OUT_DIR, "usgs_gempa_harian.csv"), row.names = FALSE)
    if (nrow(gempa) > 0L) {
      p_gempa <- ggplot2::ggplot(gempa) +
        ggplot2::geom_sf(ggplot2::aes(color = mag), size = 2) +
        ggplot2::scale_color_viridis_c(name = "Magnitudo", na.value = "grey50") +
        ggplot2::labs(title = "Gempabumi: feed harian USGS",
          caption = paste("Sumber USGS. Waktu akses:", format(Sys.time(), tz = "UTC"))) +
        ggplot2::theme_minimal()
      ggplot2::ggsave(file.path(OUT_DIR, "peta_gempa_usgs.png"), p_gempa,
                      width = 10, height = 7, dpi = 300)
    }
  }, error = function(e) {
    pesan <- paste("Demonstrasi API belum berhasil:", conditionMessage(e))
    message(pesan)
    writeLines(pesan, file.path(OUT_DIR, "api_error.txt"), useBytes = TRUE)
  })
}
writeLines(capture.output(sessionInfo()), file.path(OUT_DIR, "sessionInfo.txt"))
writeLines(c(
  "Minggu 6: seluruh data utama merupakan simulasi.",
  paste("CRS analisis: EPSG 32749. Buffer:", BUFFER_M, "m."),
  paste("Fasilitas di dalam zona:", nrow(fasilitas_terpilih)),
  "Centroid, spatial join, overlay, luas, dan jarak diperiksa dalam skrip.",
  "Satuan kepadatan: jiwa/km2. Proporsi zona: persen.",
  "Tambahan tmap, leaflet, dan API diaktifkan melalui pengaturan awal."
), file.path(OUT_DIR, "catatan_analisis.txt"))
bagian("SELESAI: MINGGU 6")
cat("Folder hasil:", normalizePath(OUT_DIR, winslash = "/"), "\n")
cat("Fasilitas dalam zona:", paste(fasilitas_terpilih$nama, collapse = ", "), "\n")
cat("File output:\n")
print(list.files(OUT_DIR))
