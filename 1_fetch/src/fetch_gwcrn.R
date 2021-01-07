unzip_and_read_shp <- function(zipfile, tmp_dir) {
  # Unzip the shapefile zip
  fns <- unzip(zipfile = zipfile, overwrite = TRUE, exdir = tmp_dir)
  
  # Read and return an sf object of the shapefile
  st_read(fns[grep(".shp", fns)])
}

extract_crn_sites <- function(gwcrn_sf) {
  # The site ids are read in as factors in st_read
  gwcrn_sf %>% pull(SITEID) %>% levels()
}
