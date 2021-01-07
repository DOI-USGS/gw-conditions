
add_site_info <- function(gw_data, gw_site_info) {
  gw_data %>% 
    left_join(gw_site_info) %>% 
    left_join(select(stateCd, -STATENS), by = c("state_cd" = "STATE")) %>% 
    rename(state = STUSAB)
}

calc_pct_change <- function(new_val, old_val) {
  (new_val - old_val)/old_val * 100
}

# Based on Twitter request: calculate change over certain time period
calc_change_over_time <- function(gw_data_fn, current_date, n_days) {
  date_to_compare <- current_date - n_days
  
  readRDS(gw_data_fn) %>% 
    
    # Keep only the GWL on the two dates to compare
    filter(Date %in% c(date_to_compare, current_date)) %>% 
    
    # Change dates to string: "Now", "Then"
    mutate(Date = ifelse(
      Date == date_to_compare, "Then", 
      ifelse(Date == current_date, "Now", NA))) %>% 
    
    # Make a Now and Then column that contains the correct gwl value
    pivot_wider(id_cols = site_no, names_from = Date, values_from = GWL) %>% 
    
    # Calculate the percent change between these two values
    mutate(pct_change = calc_pct_change(Now, Then))
     
}

convert_to_spatial_obj <- function(gw_site_info, proj_str) {
  st_as_sf(gw_site_info, 
           coords = c("dec_long_va", "dec_lat_va"), 
           crs = 4326) %>% 
    st_transform(proj_str)
}

join_to_spatial_obj <- function(gw_site_sf, gw_data) {
  gw_site_sf %>% left_join(gw_data)
}
