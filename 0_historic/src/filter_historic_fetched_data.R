filter_historic_fetched_data <- function(target_name, historic_gw_data_fn, min_years, allowed_site_types) {
  
  historic_gw_data <- read_csv(historic_gw_data_fn, col_types = 'cDn') 
  
  sites_meet_min_yrs <- historic_gw_data %>%  
    group_by(site_no) %>% 
    summarize(n_days = n()) %>% 
    # Check that the number of days of data is at least 3 full years worth
    filter(n_days >= 365*min_years) %>% 
    pull(site_no)
  
  site_nums <- unique(historic_gw_data$site_no)
  sites_meet_site_tp <- readNWISsite(site_nums) %>% 
    select(site_no, site_tp_cd) %>% 
    filter(site_tp_cd %in% allowed_site_types) %>% 
    pull(site_no)
  
  # Actually restrict the data based on these criteria
  historic_gw_data %>% 
    filter(site_no %in% sites_meet_min_yrs) %>% 
    filter(site_no %in% sites_meet_site_tp) %>%
    write_csv(file=target_name) 
}

gather_metadata_of_sites_used <- function(target_name, site_data_filtered_fn, site_data_service_to_pull, site_metadata) {
  
  sites_actually_used <- read_csv(site_data_filtered_fn) %>% pull(site_no) %>% unique()
  
  site_data_service_to_pull %>% 
    left_join(site_metadata, by = "site_no") %>% 
    filter(site_no %in% sites_actually_used) %>% 
    saveRDS(target_name)
}
