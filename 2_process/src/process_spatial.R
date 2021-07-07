
convert_to_spatial_obj <- function(gw_site_info, proj_str) {
  gw_site_info %>% 
    st_as_sf(coords = c("dec_long_va", "dec_lat_va"), 
             crs = 4326) %>% 
    st_transform(proj_str)
}
