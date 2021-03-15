
compare_to_historic <- function(target_name, historic_quantile_fn, current_data_fn) {
  
  current_data <- read_csv(current_data_fn, col_types = 'cDn')
  gw_sites <- unique(current_data$site_no)
  historic_quantiles <- read_csv(historic_quantile_fn, col_types = 'ccn') %>% 
    # Filter to only sites that exist in our current data
    filter(site_no %in% gw_sites) %>% 
    # Remove any missing quantiles
    filter(!is.na(quantile_va))
  
  # For each site, use the historic quantile data to figure out how each daily value compares. Using
  #   linear interpolation (approx), return the appropriate quantile that corresponds to the daily val.
  daily_quantiles <- purrr::map(gw_sites, function(site, current_data, historic_quantiles) {

    site_quantiles <- historic_quantiles %>% filter(site_no == site) 
    
    if(nrow(site_quantiles) == 0) {
      message(sprintf("Quantiles not available for %s, returning NA.", site))
    } 
    
    site_current <- current_data %>% 
      filter(site_no == site) %>% 
      # Figure out the corresponding quantile for each daily value
      # If there are no non-NA quantiles available, return NA
      mutate(daily_quant = ifelse(
        nrow(site_quantiles) > 0, 
        yes = approx(x = site_quantiles$quantile_va, y = site_quantiles$quantile_nm, xout = GWL)$y,
        no = NA))
    
    # TODO: Handle any new max or new min values when using dates outside of dates used to calculate historic vals
    
    return(site_current)
  }, current_data, historic_quantiles) %>% 
    bind_rows() %>% 
    write_csv(target_name)
}
