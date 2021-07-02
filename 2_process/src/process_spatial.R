
convert_to_spatial_obj <- function(gw_site_info_fn, proj_str) {
  read_csv(gw_site_info_fn) %>% 
    st_as_sf(coords = c("dec_long_va", "dec_lat_va"), 
             crs = 4326) %>% 
    st_transform(proj_str)
}
