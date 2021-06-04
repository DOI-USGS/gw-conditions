# Per gage, calc quantiles using historic groundwater level data (no seasonality)
calculate_historic_quantiles <- function(target_name, historic_gw_data_fn, quantiles_to_calc) {
  
  read_csv(historic_gw_data_fn, col_types = 'cDn') %>% 
    split(.$site_no) %>% 
    map_dfr(., function(.x) {
      quants <- quantile(.x$GWL, quantiles_to_calc, na.rm = TRUE)
      names(quants) <- NULL # Otherwise, carries unnecessary metadata
      tibble(quantile_nm = quantiles_to_calc*100, quantile_va = quants)
    }, .id = "site_no") %>% 
    bind_rows() %>% 
    write_csv(target_name)
  
}

# Restrict the number of years
apply_min_years_filter <- function(target_name, historic_gw_data_fn, min_years) {
  
  historic_gw_data <- read_csv(historic_gw_data_fn, col_types = 'cDn') 
  
  sites_meet_min_yrs <- historic_gw_data %>%  
    group_by(site_no) %>% 
    summarize(n_days = n()) %>% 
    # Check that the number of days of data is at least 3 full years worth
    filter(n_days >= 365*min_years) %>% 
    pull(site_no)
  
  historic_gw_data %>% 
    filter(site_no %in% sites_meet_min_yrs) %>% 
    write_csv(target_name)
}
