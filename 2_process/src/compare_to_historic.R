
compare_to_historic <- function(target_name, historic_quantile_fn, current_data_fn, inverse_sites) {
  
  current_data <- read_csv(current_data_fn, col_types = 'cDn')
  gw_sites <- unique(current_data$site_no)
  historic_quantiles <- read_csv(historic_quantile_fn, col_types = 'ccn') %>% 
    # Filter to only sites that exist in our current data
    filter(site_no %in% gw_sites) %>% 
    # Remove any missing quantiles
    filter(!is.na(quantile_va))
  
  # For each site, use the historic quantile data to figure out how each daily value compares. Using
  #   linear interpolation (approx), return the appropriate quantile that corresponds to the daily val.
  # If the gage reports "depth below", then we need to negate the values so that 
  # low percentiles line up with less water and high percentiles with more water. 
  # See this comment on GitHub for more detail/background: 
  #   https://github.com/USGS-VIZLAB/gw-conditions/issues/9#issuecomment-854115170
  daily_quantiles <- purrr::map(gw_sites, function(site, current_data, historic_quantiles, inverse_sites) {

    site_quantiles <- historic_quantiles %>% filter(site_no == site) 
    
    if(nrow(site_quantiles) == 0) {
      message(sprintf("Quantiles not available for %s, returning NA.", site))
    } 
    
    site_current <- current_data %>% 
      filter(site_no == site) %>% 
      # Add flag for whether an inverse of the GWL value should be used
      mutate(is_inverse = site_no %in% inverse_sites) %>% 
      # Figure out the corresponding quantile for each daily value
      # If there are no non-NA quantiles available, return NA
      rowwise() %>% 
      mutate(daily_quant = ifelse(
        nrow(site_quantiles) > 0, 
        yes = approx(x = site_quantiles$quantile_va, y = site_quantiles$quantile_nm, 
                     xout = GWL*ifelse(is_inverse, -1, 1))$y,
        no = NA)) %>% 
      ungroup() %>% 
      select(-is_inverse)
    
    # TODO: Handle any new max or new min values when using dates outside of dates used to calculate historic vals
    
    return(site_current)
  }, current_data, historic_quantiles, inverse_sites) %>% 
    bind_rows() %>% 
    write_csv(target_name)
}
