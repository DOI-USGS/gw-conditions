
convert_to_spatial_obj <- function(gw_site_info, proj_str, gw_anomaly_data) {
  gw_site_info %>% 
    filter(site_no %in% gw_anomaly_data$site_no) %>% ## only add sites with data during time range
    st_as_sf(coords = c("dec_long_va", "dec_lat_va"), 
             crs = 4326) %>% 
    st_transform(proj_str)
}

open_highres_spatial_zip <- function(out_file, in_zip, tmp_dir) {
  if(!dir.exists(tmp_dir)) dir.create(tmp_dir)
  
  # Unzip the file
  files_tmp <- unzip(in_zip, exdir = tmp_dir)
  
  # Copy to the out location and name based on what was passed in to `out_file`
  current_name_pattern <- unique(tools::file_path_sans_ext(files_tmp))
  out_name_pattern <- tools::file_path_sans_ext(out_file)
  files_out <- gsub(current_name_pattern, out_name_pattern, files_tmp)
  file.copy(files_tmp, files_out)
  
  # Find and return the specific `.shp` file from the unzipped folder
  files_out_shp <- files_out[grepl(".shp", files_out)]
  return(files_out_shp)
}
